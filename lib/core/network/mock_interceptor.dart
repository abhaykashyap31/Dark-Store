import 'dart:convert';

import 'package:dio/dio.dart';

import '../../placeholders/admin_api_mock.dart';
import '../../placeholders/auth_api_mock.dart';
import '../../placeholders/catalog_api_mock.dart';
import '../../placeholders/order_api_mock.dart';

/// Intercepts Dio requests when [AppConfig.useMockApis] is true and returns
/// Gateway-shaped JSON from local placeholders.
///
/// Uses [QueuedInterceptor] so async `onRequest` cannot race ahead to the
/// network before `handler.resolve` runs (common Dio + web pitfall).
class MockInterceptor extends QueuedInterceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Light delay so UI can show loading states without racing the adapter.
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final path = _normalizePath(options);
    final method = options.method.toUpperCase();

    try {
      final payload =
          await _resolve(method: method, path: path, options: options);
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: payload,
        ),
      );
    } on DioException catch (e) {
      handler.reject(e);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 500,
            data: {
              'message': e.toString().replaceFirst('Exception: ', ''),
            },
          ),
          error: e,
        ),
      );
    }
  }

  Future<dynamic> _resolve({
    required String method,
    required String path,
    required RequestOptions options,
  }) async {
    final auth = AuthApiMock();
    final catalog = CatalogApiMock();
    final order = OrderApiMock();
    final admin = AdminApiMock();
    final authHeader = options.headers['Authorization']?.toString();
    final body = _asMap(options.data);

    if (method == 'POST' && path.endsWith('/auth/register')) {
      try {
        return auth.register(
          email: body['email'] as String? ?? '',
          password: body['password'] as String? ?? '',
          name: body['name'] as String? ?? '',
          phone: body['phone'] as String?,
        );
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    if (method == 'POST' && path.endsWith('/auth/login')) {
      try {
        return auth.login(
          email: body['email'] as String? ?? '',
          password: body['password'] as String? ?? '',
        );
      } catch (e) {
        throw _clientError(options, 401, e);
      }
    }

    if (method == 'POST' && path.endsWith('/auth/refresh')) {
      try {
        return auth.refresh(
          authorizationHeader: authHeader,
          refreshToken: body['refreshToken'] as String?,
        );
      } catch (e) {
        throw _clientError(options, 401, e);
      }
    }

    if (method == 'POST' && path.endsWith('/auth/logout')) {
      auth.clear();
      order.clearCart();
      return {'ok': true};
    }

    if (method == 'GET' && path.endsWith('/users/me/addresses')) {
      try {
        return auth.listAddresses(authorizationHeader: authHeader);
      } catch (e) {
        throw _clientError(options, 401, e);
      }
    }

    if (method == 'POST' && path.endsWith('/users/me/addresses')) {
      try {
        return auth.addAddress(
          body: body,
          authorizationHeader: authHeader,
        );
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    final addressMatch =
        RegExp(r'/users/me/addresses/([^/]+)$').firstMatch(path);
    if (method == 'PUT' && addressMatch != null) {
      try {
        return auth.updateAddress(
          addressId: addressMatch.group(1)!,
          body: body,
          authorizationHeader: authHeader,
        );
      } catch (e) {
        final message = e.toString();
        final status = message.contains('not found') ? 404 : 400;
        throw _clientError(options, status, e);
      }
    }

    if (method == 'GET' && path.endsWith('/users/me')) {
      try {
        return auth.me(authorizationHeader: authHeader);
      } catch (e) {
        throw _clientError(options, 401, e);
      }
    }

    if (method == 'GET' && path.endsWith('/stores')) {
      return catalog.stores();
    }

    if (method == 'GET' && path.endsWith('/categories')) {
      return catalog.categories();
    }

    final productMatch = RegExp(r'/products/([^/]+)$').firstMatch(path);
    if (method == 'GET' && productMatch != null) {
      try {
        return catalog.productById(
          id: productMatch.group(1)!,
          storeId: options.queryParameters['storeId'],
        );
      } catch (e) {
        throw _clientError(options, 404, e);
      }
    }

    if (method == 'GET' && path.endsWith('/products')) {
      return catalog.products(
        storeId: options.queryParameters['storeId'],
        categoryId: options.queryParameters['categoryId'],
        query: options.queryParameters['q'],
      );
    }

    if (method == 'GET' && path.endsWith('/inventory/alerts')) {
      final storeId = options.queryParameters['storeId'] ?? '';
      try {
        return catalog.inventoryAlerts(storeId: storeId);
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    final inventoryMatch = RegExp(r'/inventory/([^/]+)$').firstMatch(path);
    if (method == 'PUT' && inventoryMatch != null) {
      try {
        return catalog.updateInventory(
          storeId: body['storeId'] as String? ??
              options.queryParameters['storeId'] ??
              '',
          productId: inventoryMatch.group(1)!,
          price: (body['price'] as num?)?.toDouble(),
          stockQty: (body['stockQty'] as num?)?.toInt(),
          lowStockThreshold: (body['lowStockThreshold'] as num?)?.toInt(),
        );
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    if (method == 'GET' && path.endsWith('/inventory/available-products')) {
      return catalog.availableProductsForStore(
        storeId: options.queryParameters['storeId'] ?? '',
      );
    }

    if (method == 'POST' && path.endsWith('/inventory')) {
      try {
        return catalog.addInventoryItem(
          storeId: body['storeId'] as String? ?? '',
          productId: body['productId'] as String?,
          name: body['name'] as String?,
          sku: body['sku'] as String?,
          price: (body['price'] as num?)?.toDouble(),
          stockQty: (body['stockQty'] as num?)?.toInt(),
          lowStockThreshold: (body['lowStockThreshold'] as num?)?.toInt(),
        );
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    if (method == 'GET' && path.endsWith('/inventory')) {
      return catalog.inventory(
        storeId: options.queryParameters['storeId'],
      );
    }

    if (method == 'GET' && path.endsWith('/cart')) {
      return order.cart(storeId: options.queryParameters['storeId']);
    }

    if (method == 'POST' && path.endsWith('/cart/items')) {
      try {
        return order.addCartItem(
          productId: body['productId'] as String? ?? '',
          quantity: (body['quantity'] as num?)?.toInt() ?? 1,
          storeId: body['storeId'] as String? ?? '',
        );
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    final cartItemMatch = RegExp(r'/cart/items/([^/]+)$').firstMatch(path);
    if (cartItemMatch != null) {
      final itemId = cartItemMatch.group(1)!;
      try {
        if (method == 'PUT') {
          return order.updateCartItem(
            itemId: itemId,
            quantity: (body['quantity'] as num?)?.toInt() ?? 0,
          );
        }
        if (method == 'DELETE') {
          return order.removeCartItem(itemId: itemId);
        }
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    final cancelMatch = RegExp(r'/orders/([^/]+)/cancel$').firstMatch(path);
    if (method == 'POST' && cancelMatch != null) {
      try {
        return order.cancelOrder(cancelMatch.group(1)!);
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    if (method == 'POST' && path.endsWith('/orders')) {
      try {
        final user = auth.me(authorizationHeader: authHeader);
        final addressId = body['addressId'] as String? ?? '';
        final addresses =
            auth.listAddresses(authorizationHeader: authHeader)['items']
                as List<dynamic>;
        final match = addresses
            .cast<Map<String, dynamic>>()
            .where((a) => a['id'] == addressId);
        if (match.isEmpty) {
          throw Exception('Delivery address is required');
        }
        return order.placeOrder(
          addressId: addressId,
          addressSnapshot: match.first,
          paymentMethod: body['paymentMethod'] as String? ?? 'COD',
          user: user,
        );
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    final orderMatch = RegExp(r'/orders/([^/]+)$').firstMatch(path);
    if (method == 'GET' && orderMatch != null) {
      try {
        return order.orderById(orderMatch.group(1)!);
      } catch (e) {
        throw _clientError(options, 404, e);
      }
    }

    // Manager/rider routes must be matched BEFORE generic `/orders`
    // (`/manager/orders`.endsWith('/orders') is true).
    if (method == 'GET' && path.endsWith('/manager/riders')) {
      final storeId = options.queryParameters['storeId'] ?? '';
      return {'items': auth.listRidersForStore(storeId)};
    }

    if (method == 'GET' && path.endsWith('/manager/orders')) {
      try {
        final me = auth.me(authorizationHeader: authHeader);
        final storeId = options.queryParameters['storeId'] ??
            me['storeId'] as String? ??
            '';
        return order.managerOrders(
          storeId: storeId,
          status: options.queryParameters['status'],
        );
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    if (method == 'GET' && path.endsWith('/rider/orders')) {
      try {
        final me = auth.me(authorizationHeader: authHeader);
        return order.riderOrders(
          storeId: me['storeId'] as String? ?? '',
          riderId: me['id'] as String? ?? '',
        );
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    if (method == 'GET' && path.endsWith('/orders')) {
      return order.orders();
    }

    final managerStatusMatch =
        RegExp(r'/manager/orders/([^/]+)/status$').firstMatch(path);
    if (method == 'PATCH' && managerStatusMatch != null) {
      try {
        final me = auth.me(authorizationHeader: authHeader);
        final storeId =
            body['storeId'] as String? ?? me['storeId'] as String? ?? '';
        return order.patchManagerStatus(
          orderId: managerStatusMatch.group(1)!,
          toStatus: body['status'] as String? ?? '',
          storeId: storeId,
        );
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    final assignMatch =
        RegExp(r'/manager/orders/([^/]+)/assign-rider$').firstMatch(path);
    if (method == 'POST' && assignMatch != null) {
      try {
        final me = auth.me(authorizationHeader: authHeader);
        final storeId =
            body['storeId'] as String? ?? me['storeId'] as String? ?? '';
        final riderId = body['riderId'] as String? ?? '';
        final riders = auth.listRidersForStore(storeId);
        final rider = riders.where((r) => r['id'] == riderId);
        if (rider.isEmpty) {
          throw Exception('Rider not found for this store');
        }
        return order.assignRider(
          orderId: assignMatch.group(1)!,
          storeId: storeId,
          riderId: riderId,
          riderName: rider.first['name'] as String? ?? 'Rider',
        );
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    final riderStatusMatch =
        RegExp(r'/rider/orders/([^/]+)/status$').firstMatch(path);
    if (method == 'PATCH' && riderStatusMatch != null) {
      try {
        final me = auth.me(authorizationHeader: authHeader);
        return order.patchRiderStatus(
          orderId: riderStatusMatch.group(1)!,
          toStatus: body['status'] as String? ?? '',
          storeId: me['storeId'] as String? ?? '',
          riderId: me['id'] as String? ?? '',
        );
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    // Admin + shared category writes
    if (method == 'POST' && path.endsWith('/categories')) {
      try {
        return admin.createCategory(body);
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    if (path.contains('/admin/stores')) {
      try {
        if (method == 'GET' && path.endsWith('/admin/stores')) {
          return admin.listStores();
        }
        if (method == 'POST' && path.endsWith('/admin/stores')) {
          return admin.createStore(body);
        }
        final storeActive =
            RegExp(r'/admin/stores/([^/]+)/active$').firstMatch(path);
        if (method == 'PATCH' && storeActive != null) {
          return admin.setStoreActive(
            storeActive.group(1)!,
            body['active'] == true,
          );
        }
        final storeMatch = RegExp(r'/admin/stores/([^/]+)$').firstMatch(path);
        if (method == 'PUT' && storeMatch != null) {
          return admin.updateStore(storeMatch.group(1)!, body);
        }
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    if (path.contains('/admin/users')) {
      try {
        if (method == 'GET' && path.endsWith('/admin/users')) {
          return admin.listUsers(
            role: options.queryParameters['role'],
            active: options.queryParameters['active'] == null
                ? null
                : options.queryParameters['active'] == 'true',
          );
        }
        if (method == 'POST' && path.endsWith('/admin/users')) {
          return admin.createUser(body);
        }
        final userActive =
            RegExp(r'/admin/users/([^/]+)/active$').firstMatch(path);
        if (method == 'PATCH' && userActive != null) {
          return admin.setUserActive(
            userActive.group(1)!,
            body['active'] == true,
          );
        }
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    if (path.contains('/admin/products')) {
      try {
        if (method == 'GET' && path.endsWith('/admin/products')) {
          return admin.listProducts();
        }
        if (method == 'POST' && path.endsWith('/admin/products')) {
          return admin.createProduct(body);
        }
        final productActive =
            RegExp(r'/admin/products/([^/]+)/active$').firstMatch(path);
        if (method == 'PATCH' && productActive != null) {
          return admin.setProductActive(
            productActive.group(1)!,
            body['active'] == true,
          );
        }
        final productMatch =
            RegExp(r'/admin/products/([^/]+)$').firstMatch(path);
        if (method == 'PUT' && productMatch != null) {
          return admin.updateProduct(productMatch.group(1)!, body);
        }
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    if (method == 'GET' && path.endsWith('/admin/categories')) {
      return admin.listCategories();
    }

    throw DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: options,
        statusCode: 404,
        data: {
          'message': 'Mock route not found: $method $path',
        },
      ),
    );
  }

  DioException _clientError(RequestOptions options, int status, Object e) {
    return DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: options,
        statusCode: status,
        data: {
          'message': e.toString().replaceFirst('Exception: ', ''),
        },
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return {};
  }

  /// Prefer [RequestOptions.path] (what repositories pass) over [Uri.path],
  /// which can be empty/odd on some web request shapes.
  String _normalizePath(RequestOptions options) {
    final raw = options.path.trim();
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return Uri.parse(raw).path;
    }
    if (raw.startsWith('/')) return raw;
    if (raw.isNotEmpty) return '/$raw';
    final fromUri = options.uri.path;
    return fromUri.isEmpty ? '/' : fromUri;
  }
}
