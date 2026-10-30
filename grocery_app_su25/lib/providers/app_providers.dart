import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/auth/auth_state.dart';
import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/api_client.dart';

const String _kCartKey = 'cart_items';
const String _kFavoritesKey = 'favorite_ids';
const String _kAddressesKey = 'saved_addresses';

/// Flat fees applied at checkout.
const double kDeliveryFee = 0.5;
const double kServiceFee = 0.15;

// Categories Provider
class CategoriesNotifier extends StateNotifier<List<Category>> {
  CategoriesNotifier() : super(const []) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final remote = await ApiClient.instance.fetchCategories();
      state = remote;
    } catch (_) {}
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>((ref) {
      return CategoriesNotifier();
    });

// Products Provider

class ProductsNotifier extends StateNotifier<List<Product>> {
  final Ref _ref;

  ProductsNotifier(this._ref) : super(const []) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final remote = await ApiClient.instance.fetchProducts();
      state = remote;
      final favIds = remote
          .where((p) => p.isFavorite)
          .map((p) => p.id)
          .toList();
      if (favIds.isNotEmpty) {
        _ref.read(favoriteProvider.notifier).mergeRemoteFavorites(favIds);
      }
    } catch (_) {}
  }

  Future<Product?> refreshProduct(String id) async {
    try {
      final fresh = await ApiClient.instance.fetchProduct(id);
      final idx = state.indexWhere((p) => p.id == id);
      if (idx >= 0) {
        final next = [...state];
        next[idx] = fresh;
        state = next;
      } else {
        state = [fresh, ...state];
      }
      return fresh;
    } catch (_) {
      return null;
    }
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, List<Product>>(
  (ref) {
    return ProductsNotifier(ref);
  },
);

// Cart Provider
class CartNotifier extends StateNotifier<List<CartItem>> {
  final Ref _ref;

  CartNotifier(this._ref) : super(const []) {
    _load();
  }

  bool get _hasToken =>
      AuthState.instance.token != null && AuthState.instance.token!.isNotEmpty;

  Future<void> refresh() => _load();

  Product? _findCatalogProduct(String productId) {
    for (final p in _ref.read(productsProvider)) {
      if (p.id == productId) return p;
    }
    return null;
  }

  Future<void> _load() async {
    if (_hasToken) {
      try {
        final remoteCart = await ApiClient.instance.fetchCart();
        state = remoteCart;
        await _saveLocal();
        return;
      } catch (_) {}
    }
    await _loadLocal();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCartKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final restored = decoded
            .whereType<Map<String, dynamic>>()
            .map(CartItem.fromJson)
            .where((item) => item.quantity > 0)
            .toList();
        state = restored;
      }
    } catch (_) {
      await prefs.remove(_kCartKey);
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCartKey,
      jsonEncode([for (final item in state) item.toJson()]),
    );
  }

  /// Adds [quantity] of [product] to the cart.
  /// Returns `null` on success, or an error message if out of stock / exceeds stock.
  Future<String?> addToCart(Product product, {int quantity = 1}) async {
    final liveProduct = _findCatalogProduct(product.id) ?? product;
    if (liveProduct.isOutOfStock) {
      _ref.read(productsProvider.notifier).refreshProduct(liveProduct.id);
      return '${liveProduct.name} is currently out of stock';
    }

    final existingItemIndex = state.indexWhere(
      (item) => item.product.id == liveProduct.id,
    );
    final currentQty =
        existingItemIndex >= 0 ? state[existingItemIndex].quantity : 0;
    if (currentQty + quantity > liveProduct.stockQuantity) {
      return 'Only ${liveProduct.stockQuantity} left in stock for ${liveProduct.name}';
    }

    final previousState = state;
    if (existingItemIndex >= 0) {
      final updatedItem = state[existingItemIndex].copyWith(
        product: liveProduct,
        quantity: currentQty + quantity,
      );
      final newState = [...state];
      newState[existingItemIndex] = updatedItem;
      state = newState;
    } else {
      state = [
        ...state,
        CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: liveProduct,
          quantity: quantity,
        ),
      ];
    }
    _saveLocal();

    if (_hasToken) {
      try {
        final remoteCart = await ApiClient.instance.addToCart(
          liveProduct.id,
          quantity: quantity,
        );
        state = remoteCart;
        _saveLocal();
      } on ApiException catch (e) {
        if (!e.isNetworkError) {
          state = previousState;
          _saveLocal();
          _ref.read(productsProvider.notifier).refresh();
          _load();
          return e.message;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> removeFromCart(String productId) async {
    state = state.where((item) => item.product.id != productId).toList();
    _saveLocal();

    if (_hasToken) {
      try {
        final remoteCart = await ApiClient.instance.removeCartItem(productId);
        state = remoteCart;
        _saveLocal();
      } catch (_) {}
    }
  }

  /// Updates [productId] quantity in the cart.
  /// Returns `null` on success, or an error message if out of stock / exceeds stock.
  Future<String?> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return null;
    }
    final existingItemIndex = state.indexWhere(
      (item) => item.product.id == productId,
    );
    final currentQty =
        existingItemIndex >= 0 ? state[existingItemIndex].quantity : 0;
    final liveProduct = _findCatalogProduct(productId) ??
        (existingItemIndex >= 0 ? state[existingItemIndex].product : null);

    if (quantity > currentQty && liveProduct != null) {
      if (liveProduct.isOutOfStock) {
        _ref.read(productsProvider.notifier).refreshProduct(productId);
        return '${liveProduct.name} is currently out of stock';
      }
      if (quantity > liveProduct.stockQuantity) {
        return 'Only ${liveProduct.stockQuantity} left in stock for ${liveProduct.name}';
      }
    }

    final previousState = state;
    if (existingItemIndex >= 0) {
      final updatedItem = state[existingItemIndex].copyWith(quantity: quantity);
      final newState = [...state];
      newState[existingItemIndex] = updatedItem;
      state = newState;
      _saveLocal();
    }

    if (_hasToken) {
      try {
        final remoteCart = await ApiClient.instance.updateCartItem(
          productId,
          quantity,
        );
        state = remoteCart;
        _saveLocal();
      } on ApiException catch (e) {
        if (!e.isNetworkError) {
          state = previousState;
          _saveLocal();
          _ref.read(productsProvider.notifier).refresh();
          _load();
          return e.message;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> clearCart() async {
    state = const [];
    _saveLocal();

    if (_hasToken) {
      try {
        await ApiClient.instance.clearCart();
      } catch (_) {}
    }
  }

  double get totalAmount {
    return state.fold(0, (sum, item) => sum + item.subtotal);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(ref);
});

/// Reactive cart total; rebuilds watchers whenever the cart changes.
final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold<double>(0, (sum, item) => sum + item.subtotal);
});

// Favorites Provider

class FavoriteNotifier extends StateNotifier<List<String>> {
  FavoriteNotifier() : super(const []) {
    _load();
  }

  bool get _hasToken =>
      AuthState.instance.token != null && AuthState.instance.token!.isNotEmpty;

  Future<void> refresh() => _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_kFavoritesKey) ?? const [];
    state = {...saved, ...state}.toList();

    if (_hasToken) {
      try {
        final remoteFavs = await ApiClient.instance.fetchFavorites();
        state = remoteFavs.map((p) => p.id).toList();
        await _save();
      } catch (_) {}
    }
  }

  void mergeRemoteFavorites(List<String> ids) {
    state = {...state, ...ids}.toList();
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFavoritesKey, state);
  }

  Future<void> toggleFavorite(String productId) async {
    if (state.contains(productId)) {
      state = state.where((id) => id != productId).toList();
    } else {
      state = [...state, productId];
    }
    _save();

    if (_hasToken) {
      try {
        final isFav = await ApiClient.instance.toggleFavorite(productId);
        if (isFav && !state.contains(productId)) {
          state = [...state, productId];
        } else if (!isFav && state.contains(productId)) {
          state = state.where((id) => id != productId).toList();
        }
        _save();
      } catch (_) {}
    }
  }

  bool isFavorite(String productId) {
    return state.contains(productId);
  }
}

final favoriteProvider = StateNotifierProvider<FavoriteNotifier, List<String>>((
  ref,
) {
  return FavoriteNotifier();
});

// Orders Provider

class OrdersNotifier extends StateNotifier<List<Order>> {
  final Ref _ref;

  OrdersNotifier(this._ref) : super(const []) {
    refresh();
  }

  bool get _hasToken =>
      AuthState.instance.token != null && AuthState.instance.token!.isNotEmpty;

  Future<void> refresh() async {
    if (!_hasToken) return;
    try {
      final catalog = _ref.read(productsProvider);
      final remoteOrders = await ApiClient.instance.fetchOrders(
        catalog: catalog,
      );
      state = remoteOrders;
    } catch (_) {}
  }

  Future<Order?> refreshOrder(String id) async {
    if (!_hasToken) return null;
    try {
      final catalog = _ref.read(productsProvider);
      final updated = await ApiClient.instance.fetchOrder(id, catalog: catalog);
      final idx = state.indexWhere((o) => o.id == id);
      if (idx >= 0) {
        final next = [...state];
        next[idx] = updated;
        state = next;
      } else {
        state = [updated, ...state];
      }
      return updated;
    } catch (_) {
      return null;
    }
  }

  void add(Order order) => state = [order, ...state];

  Future<Order> placeOrder({
    required List<CartItem> items,
    required double subtotal,
    required String address,
    String? addressId,
    required String instructions,
    required String paymentMethod,
  }) async {
    if (_hasToken) {
      try {
        final catalog = _ref.read(productsProvider);
        final created = await ApiClient.instance.createOrder(
          address: address,
          addressId: addressId,
          instructions: instructions,
          paymentMethod: paymentMethod,
          catalog: catalog,
        );
        state = [created, ...state];
        _ref.read(addressesProvider.notifier).refresh();
        return created;
      } on ApiException catch (e) {
        if (!e.isNetworkError) {
          _ref.read(productsProvider.notifier).refresh();
          _ref.read(cartProvider.notifier).refresh();
          rethrow;
        }
      } catch (_) {}
    }

    await _ref.read(productsProvider.notifier).refresh();
    final latestCatalog = _ref.read(productsProvider);
    for (final item in items) {
      for (final p in latestCatalog) {
        if (p.id == item.product.id) {
          if (p.isOutOfStock) {
            throw ApiException(
              '${p.name} is currently out of stock',
              statusCode: 422,
            );
          }
          if (item.quantity > p.stockQuantity) {
            throw ApiException(
              'Only ${p.stockQuantity} left in stock for ${p.name}',
              statusCode: 422,
            );
          }
          break;
        }
      }
    }

    final fallback = Order(
      id: (DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(
        6,
        '0',
      ),
      items: items,
      subtotal: subtotal,
      deliveryFee: kDeliveryFee,
      serviceFee: kServiceFee,
      address: address,
      instructions: instructions,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );
    state = [fallback, ...state];
    return fallback;
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>((
  ref,
) {
  return OrdersNotifier(ref);
});

// Addresses Provider

final shouldPromptAddAddressProvider = StateProvider<bool>((ref) => false);

class AddressesNotifier extends StateNotifier<List<SavedAddress>> {
  final Ref _ref;

  AddressesNotifier(this._ref) : super(const []) {
    _load();
  }

  bool get _hasToken =>
      AuthState.instance.token != null && AuthState.instance.token!.isNotEmpty;

  Future<void> refresh() => _load();

  Future<void> clear() async {
    state = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAddressesKey);
  }

  Future<void> _load() async {
    if (_hasToken) {
      try {
        final remote = await ApiClient.instance.fetchAddresses();
        state = remote;
        await _saveLocal();
        if (remote.isEmpty && AuthState.instance.value) {
          _ref.read(shouldPromptAddAddressProvider.notifier).state = true;
        }
        return;
      } catch (_) {}
    }
    await _loadLocal();
    if (state.isEmpty && AuthState.instance.value) {
      _ref.read(shouldPromptAddAddressProvider.notifier).state = true;
    }
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAddressesKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        state = decoded
            .whereType<Map<String, dynamic>>()
            .map(SavedAddress.fromJson)
            .toList();
      }
    } catch (_) {
      await prefs.remove(_kAddressesKey);
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kAddressesKey,
      jsonEncode([for (final a in state) a.toJson()]),
    );
  }

  Future<SavedAddress> addAddress({
    required String label,
    String? recipientName,
    String? phone,
    required String address,
    String? city,
    bool isDefault = false,
  }) async {
    final shouldBeDefault = isDefault || state.isEmpty;
    if (_hasToken) {
      try {
        final created = await ApiClient.instance.createAddress(
          label: label,
          recipientName: recipientName,
          phone: phone,
          address: address,
          city: city,
          isDefault: shouldBeDefault,
        );
        final updatedList = [
          created,
          for (final a in state)
            shouldBeDefault ? a.copyWith(isDefault: false) : a,
        ];
        state = updatedList;
        await _saveLocal();
        return created;
      } catch (_) {}
    }

    final local = SavedAddress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label.trim().isEmpty ? 'Home' : label.trim(),
      recipientName: recipientName?.trim().isEmpty == true
          ? AuthState.instance.userName
          : recipientName?.trim(),
      phone: phone?.trim(),
      address: address.trim(),
      city: city?.trim().isEmpty == true ? 'Phnom Penh' : city?.trim(),
      isDefault: shouldBeDefault,
    );
    state = [
      local,
      for (final a in state) shouldBeDefault ? a.copyWith(isDefault: false) : a,
    ];
    await _saveLocal();
    return local;
  }

  Future<void> updateAddress(
    String id, {
    required String label,
    String? recipientName,
    String? phone,
    required String address,
    String? city,
    required bool isDefault,
  }) async {
    if (_hasToken) {
      try {
        final updated = await ApiClient.instance.updateAddress(
          id,
          label: label,
          recipientName: recipientName,
          phone: phone,
          address: address,
          city: city,
          isDefault: isDefault,
        );
        state = [
          for (final a in state)
            if (a.id == id)
              updated
            else if (isDefault)
              a.copyWith(isDefault: false)
            else
              a,
        ];
        await _saveLocal();
        return;
      } catch (_) {}
    }

    state = [
      for (final a in state)
        if (a.id == id)
          a.copyWith(
            label: label.trim(),
            recipientName: recipientName?.trim(),
            phone: phone?.trim(),
            address: address.trim(),
            city: city?.trim(),
            isDefault: isDefault,
          )
        else if (isDefault)
          a.copyWith(isDefault: false)
        else
          a,
    ];
    await _saveLocal();
  }

  Future<void> setDefault(String id) async {
    state = [
      for (final a in state) a.copyWith(isDefault: a.id == id),
    ];
    await _saveLocal();

    if (_hasToken) {
      try {
        await ApiClient.instance.updateAddress(id, isDefault: true);
        final remote = await ApiClient.instance.fetchAddresses();
        state = remote;
        await _saveLocal();
      } catch (_) {}
    }
  }

  Future<void> removeAddress(String id) async {
    state = state.where((a) => a.id != id).toList();
    if (state.isNotEmpty && !state.any((a) => a.isDefault)) {
      state = [
        state.first.copyWith(isDefault: true),
        ...state.skip(1),
      ];
    }
    await _saveLocal();

    if (_hasToken) {
      try {
        final remote = await ApiClient.instance.deleteAddress(id);
        state = remote;
        await _saveLocal();
      } catch (_) {}
    }
  }
}

final addressesProvider =
    StateNotifierProvider<AddressesNotifier, List<SavedAddress>>((ref) {
  return AddressesNotifier(ref);
});

final selectedAddressProvider = Provider<SavedAddress?>((ref) {
  final list = ref.watch(addressesProvider);
  if (list.isEmpty) return null;
  for (final a in list) {
    if (a.isDefault) return a;
  }
  return list.first;
});
