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
}

final productsProvider = StateNotifierProvider<ProductsNotifier, List<Product>>(
  (ref) {
    return ProductsNotifier(ref);
  },
);

// Cart Provider
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []) {
    _load();
  }

  bool get _hasToken =>
      AuthState.instance.token != null && AuthState.instance.token!.isNotEmpty;

  Future<void> refresh() => _load();

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

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    final existingItemIndex = state.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingItemIndex >= 0) {
      final updatedItem = state[existingItemIndex].copyWith(
        quantity: state[existingItemIndex].quantity + quantity,
      );
      final newState = [...state];
      newState[existingItemIndex] = updatedItem;
      state = newState;
    } else {
      state = [
        ...state,
        CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: product,
          quantity: quantity,
        ),
      ];
    }
    _saveLocal();

    if (_hasToken) {
      try {
        final remoteCart = await ApiClient.instance.addToCart(
          product.id,
          quantity: quantity,
        );
        state = remoteCart;
        _saveLocal();
      } catch (_) {}
    }
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

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }
    final existingItemIndex = state.indexWhere(
      (item) => item.product.id == productId,
    );
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
      } catch (_) {}
    }
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
  return CartNotifier();
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
      } catch (_) {}
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
