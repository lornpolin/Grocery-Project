import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import '../core/auth/auth_state.dart';
import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/product.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  const ApiException(
    this.message, {
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _resolveBaseUrl(),
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          var token = AuthState.instance.token;
          if (token == null || token.isEmpty) {
            await AuthState.instance.load();
            token = AuthState.instance.token;
          }
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          final status = e.response?.statusCode;
          final path = e.requestOptions.path;
          final alreadyRetried = e.requestOptions.extra['_retried'] == true;
          final currentToken = AuthState.instance.token;

          if (status == 401 &&
              !alreadyRetried &&
              currentToken != null &&
              currentToken.isNotEmpty &&
              !path.startsWith('/auth/')) {
            final refreshed = await _tryRefreshToken(currentToken);
            if (refreshed) {
              final retryOpts = e.requestOptions;
              retryOpts.extra['_retried'] = true;
              retryOpts.headers['Authorization'] =
                  'Bearer ${AuthState.instance.token}';
              try {
                final retryResponse = await _dio.fetch(retryOpts);
                return handler.resolve(retryResponse);
              } on DioException catch (retryErr) {
                return handler.next(retryErr);
              }
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  bool _isRefreshing = false;

  Future<bool> _tryRefreshToken(String expiredToken) async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final res = await _dio.post(
        '/auth/refresh',
        options: Options(
          headers: {'Authorization': 'Bearer $expiredToken'},
          extra: const {'_retried': true},
        ),
      );
      final body = res.data as Map<String, dynamic>;
      final newToken = (body['token'] ?? '').toString();
      if (newToken.isEmpty) return false;
      final user = (body['user'] as Map<String, dynamic>?) ?? const {};
      await AuthState.instance.setAuthSession(
        token: newToken,
        id: (user['id'] ?? AuthState.instance.userId ?? '').toString(),
        name: (user['name'] ?? AuthState.instance.userName).toString(),
        email: (user['email'] ?? AuthState.instance.userEmail).toString(),
        phone: (user['phone'] ?? AuthState.instance.userPhone)?.toString(),
        avatarUrl:
            (user['avatarUrl'] ??
                    user['avatar_url'] ??
                    AuthState.instance.userAvatarUrl)
                ?.toString(),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String _resolveBaseUrl() {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  String get baseUrl => _dio.options.baseUrl;

  /// Resolves a relative storage path (e.g. `categories/icon.png`) or full URL.
  String resolveStorageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final root = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final clean = path.replaceFirst(RegExp(r'^/+'), '');
    if (clean.startsWith('storage/')) {
      return '$root/$clean';
    }
    return '$root/storage/$clean';
  }

  ApiException _mapDioError(DioException e) {
    final isNet =
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;

    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final firstVal = errors.values.first;
        if (firstVal is List && firstVal.isNotEmpty) {
          return ApiException(
            firstVal.first.toString(),
            statusCode: e.response?.statusCode,
          );
        }
      }
      if (data['message'] != null) {
        return ApiException(
          data['message'].toString(),
          statusCode: e.response?.statusCode,
        );
      }
    }

    return ApiException(
      isNet
          ? 'Cannot connect to backend server ($baseUrl)'
          : (e.message ?? 'Request failed'),
      statusCode: e.response?.statusCode,
      isNetworkError: isNet,
    );
  }

  // Auth Endpoints

  Future<void> login({required String email, required String password}) async {
    try {
      final res = await _dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final body = res.data as Map<String, dynamic>;
      final user = (body['user'] as Map<String, dynamic>?) ?? const {};
      await AuthState.instance.setAuthSession(
        token: (body['token'] ?? '').toString(),
        id: (user['id'] ?? '').toString(),
        name: (user['name'] ?? '').toString(),
        email: (user['email'] ?? email).toString(),
        phone: user['phone']?.toString(),
        avatarUrl: (user['avatarUrl'] ?? user['avatar_url'])?.toString(),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
      );
      final body = res.data as Map<String, dynamic>;
      final user = (body['user'] as Map<String, dynamic>?) ?? const {};
      await AuthState.instance.setAuthSession(
        token: (body['token'] ?? '').toString(),
        id: (user['id'] ?? '').toString(),
        name: (user['name'] ?? name).toString(),
        email: (user['email'] ?? email).toString(),
        phone: user['phone']?.toString(),
        avatarUrl: (user['avatarUrl'] ?? user['avatar_url'])?.toString(),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> fetchMe() async {
    try {
      final res = await _dio.get('/auth/me');
      final user = res.data as Map<String, dynamic>;
      await AuthState.instance.updateUserProfile(
        id: (user['id'] ?? '').toString(),
        name: (user['name'] ?? '').toString(),
        email: (user['email'] ?? '').toString(),
        phone: user['phone']?.toString(),
        avatarUrl: (user['avatarUrl'] ?? user['avatar_url'])?.toString(),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? phone,
    Uint8List? avatarBytes,
    String? avatarFileName,
    bool removeAvatar = false,
    String? currentPassword,
    String? newPassword,
  }) async {
    final token = AuthState.instance.token;
    if (token == null || token.isEmpty) {
      await AuthState.instance.updateUserProfile(
        id: AuthState.instance.userId ?? '',
        name: name.trim(),
        email: email.trim(),
        phone: phone?.trim(),
        avatarUrl: removeAvatar ? null : AuthState.instance.userAvatarUrl,
      );
      return;
    }

    try {
      final map = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone?.trim() ?? '',
        if (removeAvatar && avatarBytes == null) 'remove_avatar': '1',
        if (newPassword != null && newPassword.isNotEmpty) ...{
          'current_password': currentPassword ?? '',
          'new_password': newPassword,
        },
      };

      if (avatarBytes != null && avatarBytes.isNotEmpty) {
        final rawName = (avatarFileName ?? '').trim();
        final fileName = rawName.isNotEmpty ? rawName : 'avatar.jpg';
        map['avatar'] = MultipartFile.fromBytes(
          avatarBytes,
          filename: fileName,
        );
      }

      final res = await _dio.post(
        '/auth/profile',
        data: FormData.fromMap(map),
        options: Options(contentType: Headers.multipartFormDataContentType),
      );
      final user = res.data as Map<String, dynamic>;
      await AuthState.instance.updateUserProfile(
        id: (user['id'] ?? '').toString(),
        name: (user['name'] ?? name).toString(),
        email: (user['email'] ?? email).toString(),
        phone: user['phone']?.toString(),
        avatarUrl: (user['avatarUrl'] ?? user['avatar_url'])?.toString(),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      if (AuthState.instance.token != null) {
        await _dio.post('/auth/logout');
      }
    } catch (_) {
      // Ignore network errors when logging out locally.
    } finally {
      await AuthState.instance.clearSession();
    }
  }

  // ---------------------------------------------------------------------------
  // Catalog Endpoints
  // ---------------------------------------------------------------------------

  Future<List<Category>> fetchCategories() async {
    try {
      final res = await _dio.get('/categories');
      final list = res.data as List<dynamic>;
      return list
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<List<Product>> fetchProducts({
    String? categoryId,
    String? query,
  }) async {
    try {
      final res = await _dio.get(
        '/products',
        queryParameters: {
          if (categoryId != null && categoryId.isNotEmpty)
            'category': categoryId,
          if (query != null && query.isNotEmpty) 'q': query,
        },
      );
      final list = res.data as List<dynamic>;
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Product> fetchProduct(String id) async {
    try {
      final res = await _dio.get('/products/$id');
      return Product.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Cart Endpoints
  // ---------------------------------------------------------------------------

  Future<List<CartItem>> fetchCart() async {
    try {
      final res = await _dio.get('/cart');
      final list = res.data as List<dynamic>;
      return list
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<List<CartItem>> addToCart(String productId, {int quantity = 1}) async {
    try {
      final res = await _dio.post(
        '/cart',
        data: {
          'product_id': int.tryParse(productId) ?? productId,
          'quantity': quantity,
        },
      );
      final list = res.data as List<dynamic>;
      return list
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<List<CartItem>> updateCartItem(String productId, int quantity) async {
    try {
      final res = await _dio.put(
        '/cart/$productId',
        data: {'quantity': quantity},
      );
      final list = res.data as List<dynamic>;
      return list
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<List<CartItem>> removeCartItem(String productId) async {
    try {
      final res = await _dio.delete('/cart/$productId');
      final list = res.data as List<dynamic>;
      return list
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> clearCart() async {
    try {
      await _dio.delete('/cart');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Favorites Endpoints
  // ---------------------------------------------------------------------------

  Future<List<Product>> fetchFavorites() async {
    try {
      final res = await _dio.get('/favorites');
      final list = res.data as List<dynamic>;
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<bool> toggleFavorite(String productId) async {
    try {
      final res = await _dio.post('/favorites/$productId/toggle');
      final body = res.data as Map<String, dynamic>;
      return body['isFavorite'] == true;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Orders Endpoints
  // ---------------------------------------------------------------------------

  Future<List<Order>> fetchOrders({List<Product> catalog = const []}) async {
    try {
      final res = await _dio.get('/orders');
      final list = res.data as List<dynamic>;
      return list
          .map(
            (e) => Order.fromJson(e as Map<String, dynamic>, catalog: catalog),
          )
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Order> fetchOrder(
    String id, {
    List<Product> catalog = const [],
  }) async {
    try {
      final res = await _dio.get('/orders/$id');
      return Order.fromJson(res.data as Map<String, dynamic>, catalog: catalog);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Order> createOrder({
    required String address,
    String? addressId,
    String instructions = '',
    String paymentMethod = 'Cash',
    List<Product> catalog = const [],
  }) async {
    try {
      final parsedAddressId = addressId != null
          ? int.tryParse(addressId)
          : null;
      final res = await _dio.post(
        '/orders',
        data: {'address': address, 'address_id': ?parsedAddressId},
      );
      return Order.fromJson(
        res.data as Map<String, dynamic>,
        catalog: catalog,
        defaultInstructions: instructions,
        defaultPaymentMethod: paymentMethod,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Addresses Endpoints
  // ---------------------------------------------------------------------------

  Future<List<SavedAddress>> fetchAddresses() async {
    try {
      final res = await _dio.get('/addresses');
      final list = res.data as List<dynamic>;
      return list
          .map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<SavedAddress> createAddress({
    required String label,
    String? recipientName,
    String? phone,
    required String address,
    String? city,
    bool isDefault = false,
  }) async {
    try {
      final res = await _dio.post(
        '/addresses',
        data: {
          'label': label.trim().isEmpty ? 'Home' : label.trim(),
          if (recipientName != null && recipientName.trim().isNotEmpty)
            'recipient_name': recipientName.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          'address': address.trim(),
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
          'is_default': isDefault,
        },
      );
      return SavedAddress.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<SavedAddress> updateAddress(
    String id, {
    String? label,
    String? recipientName,
    String? phone,
    String? address,
    String? city,
    bool? isDefault,
  }) async {
    try {
      final res = await _dio.put(
        '/addresses/$id',
        data: {
          if (label != null) 'label': label.trim(),
          if (recipientName != null) 'recipient_name': recipientName.trim(),
          if (phone != null) 'phone': phone.trim(),
          if (address != null) 'address': address.trim(),
          if (city != null) 'city': city.trim(),
          'is_default': ?isDefault,
        },
      );
      return SavedAddress.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<List<SavedAddress>> deleteAddress(String id) async {
    try {
      final res = await _dio.delete('/addresses/$id');
      final list = res.data as List<dynamic>;
      return list
          .map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }
}
