import '../core/constants/app_role.dart';
import 'auth_api_mock.dart';
import 'catalog_api_mock.dart';

/// Mutable admin platform mock: stores, staff accounts, catalogue.
class AdminApiMock {
  static final AdminApiMock instance = AdminApiMock._();

  AdminApiMock._() {
    _seed();
  }

  factory AdminApiMock() => instance;

  final List<Map<String, dynamic>> _stores = [];
  final List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _categories = [];

  void resetForTests() {
    _stores.clear();
    _products.clear();
    _categories.clear();
    _seed();
  }

  void _seed() {
    _stores.addAll([
      {
        'id': 's_001',
        'name': 'Koramangala Darkstore',
        'code': 'BLR-KOR',
        'city': 'Bengaluru',
        'address': 'Koramangala 5th Block',
        'phone': '0804000001',
        'active': true,
      },
      {
        'id': 's_002',
        'name': 'Indiranagar Darkstore',
        'code': 'BLR-IND',
        'city': 'Bengaluru',
        'address': '100 Feet Road',
        'phone': '0804000002',
        'active': true,
      },
    ]);

    _categories.addAll([
      {'id': 'c_01', 'name': 'Dairy', 'parentId': null},
      {'id': 'c_02', 'name': 'Snacks', 'parentId': null},
      {'id': 'c_03', 'name': 'Beverages', 'parentId': null},
    ]);

    _products.addAll([
      {
        'id': 'p_100',
        'sku': 'MLK-1L',
        'name': 'Milk 1L',
        'categoryId': 'c_01',
        'description': 'Fresh toned milk, 1 litre pack.',
        'basePrice': 50.0,
        'active': true,
      },
      {
        'id': 'p_101',
        'sku': 'BRD-400',
        'name': 'Whole Wheat Bread',
        'categoryId': 'c_02',
        'description': 'Soft whole wheat loaf, 400g.',
        'basePrice': 40.0,
        'active': true,
      },
      {
        'id': 'p_102',
        'sku': 'WTR-1L',
        'name': 'Mineral Water 1L',
        'categoryId': 'c_03',
        'description': 'Packaged drinking water.',
        'basePrice': 20.0,
        'active': true,
      },
    ]);
  }

  List<Map<String, dynamic>> get storeRecords =>
      _stores.map((e) => Map<String, dynamic>.from(e)).toList();

  // --- Stores ---

  Map<String, dynamic> listStores() => {
        'items': storeRecords,
      };

  Map<String, dynamic> createStore(Map<String, dynamic> body) {
    final name = (body['name'] as String? ?? '').trim();
    final code = (body['code'] as String? ?? '').trim().toUpperCase();
    if (name.isEmpty || code.isEmpty) {
      throw Exception('Store name and code are required');
    }
    if (_stores.any((s) => s['code'] == code)) {
      throw Exception('Store code already exists');
    }
    final store = <String, dynamic>{
      'id': 's_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'code': code,
      'city': (body['city'] as String? ?? '').trim(),
      'address': (body['address'] as String? ?? '').trim(),
      'phone': (body['phone'] as String? ?? '').trim(),
      'active': true,
    };
    _stores.add(store);
    CatalogApiMock().upsertStore(store);
    return Map<String, dynamic>.from(store);
  }

  Map<String, dynamic> updateStore(String id, Map<String, dynamic> body) {
    final index = _stores.indexWhere((s) => s['id'] == id);
    if (index < 0) throw Exception('Store not found');
    final store = _stores[index];
    if (body['name'] != null) store['name'] = (body['name'] as String).trim();
    if (body['code'] != null) {
      final code = (body['code'] as String).trim().toUpperCase();
      if (_stores.any((s) => s['id'] != id && s['code'] == code)) {
        throw Exception('Store code already exists');
      }
      store['code'] = code;
    }
    if (body['city'] != null) store['city'] = (body['city'] as String).trim();
    if (body['address'] != null) {
      store['address'] = (body['address'] as String).trim();
    }
    if (body['phone'] != null) store['phone'] = (body['phone'] as String).trim();
    CatalogApiMock().upsertStore(store);
    return Map<String, dynamic>.from(store);
  }

  Map<String, dynamic> setStoreActive(String id, bool active) {
    final index = _stores.indexWhere((s) => s['id'] == id);
    if (index < 0) throw Exception('Store not found');
    _stores[index]['active'] = active;
    CatalogApiMock().upsertStore(_stores[index]);
    return Map<String, dynamic>.from(_stores[index]);
  }

  // --- Users / staff ---

  Map<String, dynamic> listUsers({String? role, bool? active}) {
    var items = AuthApiMock().listUsersForAdmin();
    if (role != null && role.isNotEmpty) {
      items = items.where((u) => u['role'] == role.toUpperCase()).toList();
    }
    if (active != null) {
      items = items.where((u) => u['active'] == active).toList();
    }
    return {'items': items};
  }

  Map<String, dynamic> createUser(Map<String, dynamic> body) {
    final role = (body['role'] as String? ?? '').toUpperCase();
    if (role != 'MANAGER' && role != 'RIDER') {
      throw Exception('Admin can only create MANAGER or RIDER accounts');
    }
    final storeId = body['storeId'] as String?;
    if (storeId == null || storeId.isEmpty) {
      throw Exception('storeId is required for MANAGER and RIDER');
    }
    if (!_stores.any((s) => s['id'] == storeId && s['active'] == true)) {
      throw Exception('Select an active store');
    }

    return AuthApiMock().createStaffUser(
      email: body['email'] as String? ?? '',
      password: body['password'] as String? ?? 'password',
      name: body['name'] as String? ?? '',
      phone: body['phone'] as String?,
      role: AppRole.fromApi(role),
      storeId: storeId,
    );
  }

  Map<String, dynamic> setUserActive(String id, bool active) {
    return AuthApiMock().setUserActive(userId: id, active: active);
  }

  // --- Catalogue ---

  Map<String, dynamic> listCategories() => {
        'items': _categories.map((e) => Map<String, dynamic>.from(e)).toList(),
      };

  Map<String, dynamic> createCategory(Map<String, dynamic> body) {
    final name = (body['name'] as String? ?? '').trim();
    if (name.isEmpty) throw Exception('Category name is required');
    final category = <String, dynamic>{
      'id': 'c_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'parentId': body['parentId'],
    };
    _categories.add(category);
    CatalogApiMock().upsertCategory(category);
    return Map<String, dynamic>.from(category);
  }

  Map<String, dynamic> listProducts() => {
        'items': _products.map((e) => Map<String, dynamic>.from(e)).toList(),
      };

  Map<String, dynamic> createProduct(Map<String, dynamic> body) {
    final name = (body['name'] as String? ?? '').trim();
    final sku = (body['sku'] as String? ?? '').trim().toUpperCase();
    if (name.isEmpty || sku.isEmpty) {
      throw Exception('Product name and SKU are required');
    }
    if (_products.any((p) => p['sku'] == sku)) {
      throw Exception('SKU already exists');
    }
    final product = <String, dynamic>{
      'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
      'sku': sku,
      'name': name,
      'categoryId': body['categoryId'],
      'description': body['description'] ?? '',
      'basePrice': (body['basePrice'] as num?)?.toDouble() ?? 0,
      'active': true,
    };
    _products.add(product);
    CatalogApiMock().upsertProduct(product);
    return Map<String, dynamic>.from(product);
  }

  Map<String, dynamic> updateProduct(String id, Map<String, dynamic> body) {
    final index = _products.indexWhere((p) => p['id'] == id);
    if (index < 0) throw Exception('Product not found');
    final product = _products[index];
    if (body['name'] != null) product['name'] = (body['name'] as String).trim();
    if (body['sku'] != null) {
      final sku = (body['sku'] as String).trim().toUpperCase();
      if (_products.any((p) => p['id'] != id && p['sku'] == sku)) {
        throw Exception('SKU already exists');
      }
      product['sku'] = sku;
    }
    if (body['categoryId'] != null) product['categoryId'] = body['categoryId'];
    if (body['description'] != null) {
      product['description'] = body['description'];
    }
    if (body['basePrice'] != null) {
      product['basePrice'] = (body['basePrice'] as num).toDouble();
    }
    CatalogApiMock().upsertProduct(product);
    return Map<String, dynamic>.from(product);
  }

  Map<String, dynamic> setProductActive(String id, bool active) {
    final index = _products.indexWhere((p) => p['id'] == id);
    if (index < 0) throw Exception('Product not found');
    _products[index]['active'] = active;
    CatalogApiMock().upsertProduct(_products[index]);
    return Map<String, dynamic>.from(_products[index]);
  }
}
