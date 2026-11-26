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
      final isNoContent = payload == null &&
          (method == 'DELETE' || path.endsWith('/auth/logout'));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: isNoContent ? 204 : 200,
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
        // 201 User only — no session (API_REFERENCE.md).
        return auth.register(
          email: body['email'] as String? ?? '',
          password: body['password'] as String? ?? '',
          name: '${body['fullName'] ?? body['name'] ?? ''}',
          phone: body['phone'] as String?,
          role: body['role'] as String?,
        );
      } catch (e) {
        final text = e.toString();
        final status = text.contains('already') ? 409 : 400;
        throw _clientError(options, status, e);
      }
    }

    if (method == 'POST' && path.endsWith('/auth/login')) {
      try {
        return auth.login(
          email: body['email'] as String? ?? '',
          password: body['password'] as String? ?? '',
        );
      } catch (e) {
        final code = _errorCode(e);
        final status = code == 'ACCOUNT_DISABLED' ? 403 : 401;
        throw _clientError(options, status, e);
      }
    }

    if (method == 'POST' && path.endsWith('/auth/refresh')) {
      try {
        return auth.refresh(
          authorizationHeader: authHeader,
          refreshToken: body['refreshToken'] as String?,
        );
      } catch (e) {
        final code = _errorCode(e);
        final status = code == 'ACCOUNT_DISABLED' ? 403 : 401;
        throw _clientError(options, status, e);
      }
    }

    if (method == 'POST' && path.endsWith('/auth/logout')) {
      auth.clear();
      order.clearCart();
      // Gateway returns 204 with empty body.
      return null;
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
    if (addressMatch != null) {
      try {
        if (method == 'PUT') {
          return auth.updateAddress(
            addressId: addressMatch.group(1)!,
            body: body,
            authorizationHeader: authHeader,
          );
        }
        if (method == 'DELETE') {
          auth.deleteAddress(
            addressId: addressMatch.group(1)!,
            authorizationHeader: authHeader,
          );
          return null;
        }
      } catch (e) {
        final message = e.toString();
        final status = message.contains('not found') ? 404 : 400;
        throw _clientError(options, status, e);
      }
    }

    if (method == 'PUT' && path.endsWith('/users/me')) {
      try {
        return auth.updateMe(
          body: body,
          authorizationHeader: authHeader,
        );
      } catch (e) {
        throw _clientError(options, 400, e);
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
      // Bare list (API_REFERENCE); parseObjectList also accepts {items}.
      return (catalog.stores()['items'] as List<dynamic>);
    }

    if (method == 'POST' && path.endsWith('/stores')) {
      try {
        return admin.createStore(body);
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    final storePut = RegExp(r'/stores/([^/]+)$').firstMatch(path);
    if (method == 'PUT' && storePut != null) {
      try {
        return admin.updateStore(storePut.group(1)!, body);
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    if (method == 'GET' && storePut != null) {
      try {
        final id = storePut.group(1)!;
        final items = catalog.stores()['items'] as List<dynamic>;
        final match = items.cast<Map>().firstWhere(
              (s) => '${s['id']}' == id,
              orElse: () => throw Exception('Store not found'),
            );
        return Map<String, dynamic>.from(match);
      } catch (e) {
        throw _clientError(options, 404, e);
      }
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
      final storeId = _asId(options.queryParameters['storeId']);
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
          storeId: _asId(
            body['storeId'] ?? options.queryParameters['storeId'],
          ),
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
        storeId: _asId(options.queryParameters['storeId']),
      );
    }

    if (method == 'POST' && path.endsWith('/inventory')) {
      try {
        return catalog.addInventoryItem(
          storeId: _asId(body['storeId']),
          productId: body['productId']?.toString(),
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
        storeId: _asId(options.queryParameters['storeId']),
      );
    }

    if (method == 'GET' && path.endsWith('/cart')) {
      return order.cart(storeId: _asId(options.queryParameters['storeId']));
    }

    if (method == 'POST' && path.endsWith('/cart/items')) {
      try {
        return order.addCartItem(
          productId: '${body['productId'] ?? ''}',
          quantity: (body['quantity'] as num?)?.toInt() ?? 1,
          storeId: _asId(body['storeId']),
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
        final addressId = '${body['addressId'] ?? ''}';
        final addresses =
            auth.listAddresses(authorizationHeader: authHeader);
        final match = addresses.where((a) => '${a['id']}' == addressId);
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
        final storeId = _asId(
          options.queryParameters['storeId'] ?? me['storeId'],
        );
        return order.managerOrders(
          storeId: storeId,
          status: options.queryParameters['status']?.toString(),
        );
      } catch (e) {
        throw _clientError(options, 400, e);
      }
    }

    if (method == 'GET' && path.endsWith('/rider/orders')) {
      try {
        final me = auth.me(authorizationHeader: authHeader);
        return order.riderOrders(
          storeId: _asId(me['storeId']),
          riderId: _asId(me['id']),
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
        final storeId = _asId(body['storeId'] ?? me['storeId']);
        return order.patchManagerStatus(
          orderId: managerStatusMatch.group(1)!,
          toStatus: '${body['status'] ?? ''}',
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
        final storeId = _asId(body['storeId'] ?? me['storeId']);
        final riderId = _asId(body['riderId']);
        final riders = auth.listRidersForStore(storeId);
        final rider = riders.where((r) => '${r['id']}' == riderId);
        if (rider.isEmpty) {
          throw Exception('Rider not found for this store');
        }
        return order.assignRider(
          orderId: assignMatch.group(1)!,
          storeId: storeId,
          riderId: riderId,
          riderName: '${rider.first['fullName'] ?? rider.first['name'] ?? 'Rider'}',
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
          toStatus: '${body['status'] ?? ''}',
          storeId: _asId(me['storeId']),
          riderId: _asId(me['id']),
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

    if (path.contains('/admin/users')) {
      try {
        if (method == 'GET' && path.endsWith('/admin/users')) {
          return auth.listUsersForAdmin(
            role: options.queryParameters['role']?.toString(),
          );
        }
        if (method == 'POST' && path.endsWith('/admin/users')) {
          return admin.createUser(body);
        }
        final userStatus =
            RegExp(r'/admin/users/([^/]+)/status$').firstMatch(path);
        if (method == 'PATCH' && userStatus != null) {
          final me = auth.me(authorizationHeader: authHeader);
          return auth.setUserStatus(
            userId: userStatus.group(1)!,
            status: '${body['status'] ?? ''}',
            actorUserId: '${me['id']}',
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
    final raw = e.toString().replaceFirst('Exception: ', '');
    final code = _errorCode(e);
    final message = code != null && raw.contains('::')
        ? raw.split('::').skip(1).join('::')
        : raw;
    return DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: options,
        statusCode: status,
        data: {
          'status': status,
          if (code != null) 'code': code,
          'message': message,
        },
      ),
    );
  }

  String? _errorCode(Object e) {
    final raw = e.toString().replaceFirst('Exception: ', '');
    if (raw.contains('::')) {
      return raw.split('::').first;
    }
    if (raw.toLowerCase().contains('already')) {
      return 'EMAIL_ALREADY_EXISTS';
    }
    return null;
  }

  /// Gateway ids are ints; mocks historically used strings — normalize both.
  String _asId(Object? value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return '';
    return text;
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
