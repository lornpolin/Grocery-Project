import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import '../core/auth/auth_state.dart';
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
        onRequest: (options, handler) {
          final token = AuthState.instance.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
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
    final isNet = e.type == DioExceptionType.connectionError ||
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

  // ---------------------------------------------------------------------------
  // Auth Endpoints
  // ---------------------------------------------------------------------------

  Future<void> login({
    required String email,
    required String password,
  }) async {
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

  Future<List<CartItem>> addToCart(
    String productId, {
    int quantity = 1,
  }) async {
    try {
      final res = await _dio.post(
        '/cart',
        data: {'product_id': int.tryParse(productId) ?? productId, 'quantity': quantity},
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
            (e) => Order.fromJson(
              e as Map<String, dynamic>,
              catalog: catalog,
            ),
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
      return Order.fromJson(
        res.data as Map<String, dynamic>,
        catalog: catalog,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Order> createOrder({
    required String address,
    String instructions = '',
    String paymentMethod = 'Cash',
    List<Product> catalog = const [],
  }) async {
    try {
      final res = await _dio.post(
        '/orders',
        data: {'address': address},
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
}

