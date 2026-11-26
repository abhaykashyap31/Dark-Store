import 'mock_ids.dart';

/// Local mock for Catalog & Inventory Gateway paths.
class CatalogApiMock {
  static final CatalogApiMock instance = CatalogApiMock._();

  CatalogApiMock._() {
    _catalog.addAll(_seedCatalog);
    _categories.addAll(_seedCategories);
    _stores.addAll(_seedStores);
    _inventoryByStore.addAll(
      _seedInventory.map(
        (storeId, products) => MapEntry(
          storeId,
          {
            for (final entry in products.entries)
              entry.key: Map<String, dynamic>.from(entry.value),
          },
        ),
      ),
    );
  }

  factory CatalogApiMock() => instance;

  final List<Map<String, dynamic>> _catalog = [];
  final List<Map<String, dynamic>> _categories = [];
  final List<Map<String, dynamic>> _stores = [];
  final Map<String, Map<String, Map<String, dynamic>>> _inventoryByStore = {};

  static const _seedStores = <Map<String, dynamic>>[
    {
      'id': MockIds.storeKoramangala,
      'code': 'BLR-KOR',
      'name': 'Koramangala Darkstore',
      'line1': '80 Feet Road, Koramangala',
      'city': 'Bengaluru',
      'state': 'Karnataka',
      'postalCode': '560095',
      'phone': '08040000001',
      'active': true,
    },
    {
      'id': MockIds.storeIndiranagar,
      'code': 'BLR-IND',
      'name': 'Indiranagar Darkstore',
      'line1': '100 Feet Road, Indiranagar',
      'city': 'Bengaluru',
      'state': 'Karnataka',
      'postalCode': '560038',
      'phone': '08040000002',
      'active': true,
    },
  ];

  static const _seedCategories = <Map<String, dynamic>>[
    {'id': 'c_01', 'name': 'Dairy, Bread & Eggs', 'parentId': null},
    {'id': 'c_02', 'name': 'Snacks & Munchies', 'parentId': null},
    {'id': 'c_03', 'name': 'Cold Drinks & Juices', 'parentId': null},
    {'id': 'c_04', 'name': 'Fruits & Vegetables', 'parentId': null},
  ];

  static const _seedCatalog = <Map<String, dynamic>>[
    {
      'id': 'p_100',
      'sku': 'MLK-1L',
      'name': 'Farm Fresh Milk',
      'unit': '1 L',
      'categoryId': 'c_01',
      'description': 'Fresh toned milk, 1 litre pack.',
      'imageUrl': null,
      'basePrice': 50.0,
    },
    {
      'id': 'p_101',
      'sku': 'BRD-400',
      'name': 'Whole Wheat Bread',
      'unit': '400 g',
      'categoryId': 'c_01',
      'description': 'Soft whole wheat loaf, 400g.',
      'imageUrl': null,
      'basePrice': 40.0,
    },
    {
      'id': 'p_102',
      'sku': 'WTR-1L',
      'name': 'Mineral Water',
      'unit': '1 L',
      'categoryId': 'c_03',
      'description': 'Packaged drinking water.',
      'imageUrl': null,
      'basePrice': 20.0,
    },
    {
      'id': 'p_103',
      'sku': 'YGT-200',
      'name': 'Greek Yogurt',
      'unit': '200 g',
      'categoryId': 'c_01',
      'description': 'Thick Greek-style yogurt.',
      'imageUrl': null,
      'basePrice': 60.0,
    },
    {
      'id': 'p_104',
      'sku': 'CHS-100',
      'name': 'Potato Chips',
      'unit': '100 g',
      'categoryId': 'c_02',
      'description': 'Classic salted chips, 100g.',
      'imageUrl': null,
      'basePrice': 30.0,
    },
    {
      'id': 'p_105',
      'sku': 'COLA-750',
      'name': 'Cola',
      'unit': '750 ml',
      'categoryId': 'c_03',
      'description': 'Chilled soft drink bottle.',
      'imageUrl': null,
      'basePrice': 40.0,
    },
    {
      'id': 'p_106',
      'sku': 'EGG-6',
      'name': 'Farm Eggs',
      'unit': '6 pcs',
      'categoryId': 'c_01',
      'description': 'Fresh farm eggs tray.',
      'imageUrl': null,
      'basePrice': 48.0,
    },
    {
      'id': 'p_107',
      'sku': 'BAN-6',
      'name': 'Bananas',
      'unit': '6 pcs',
      'categoryId': 'c_04',
      'description': 'Ripe bananas.',
      'imageUrl': null,
      'basePrice': 35.0,
    },
    {
      'id': 'p_108',
      'sku': 'TMT-500',
      'name': 'Tomatoes',
      'unit': '500 g',
      'categoryId': 'c_04',
      'description': 'Fresh tomatoes.',
      'imageUrl': null,
      'basePrice': 28.0,
    },
    {
      'id': 'p_109',
      'sku': 'NUTS-80',
      'name': 'Roasted Peanuts',
      'unit': '80 g',
      'categoryId': 'c_02',
      'description': 'Crunchy salted peanuts.',
      'imageUrl': null,
      'basePrice': 35.0,
    },
  ];

  void upsertStore(Map<String, dynamic> store) {
    final id = store['id'] as String;
    final index = _stores.indexWhere((s) => '${s['id']}' == '$id');
    final copy = Map<String, dynamic>.from(store);
    if (index >= 0) {
      _stores[index] = copy;
    } else {
      _stores.add(copy);
    }
  }

  void upsertCategory(Map<String, dynamic> category) {
    final id = category['id'] as String;
    final index = _categories.indexWhere((c) => c['id'] == id);
    final copy = Map<String, dynamic>.from(category);
    if (index >= 0) {
      _categories[index] = copy;
    } else {
      _categories.add(copy);
    }
  }

  void upsertProduct(Map<String, dynamic> product) {
    final id = product['id'] as String;
    final index = _catalog.indexWhere((p) => p['id'] == id);
    final copy = Map<String, dynamic>.from(product)
      ..putIfAbsent('imageUrl', () => null);
    if (product['active'] == false) {
      if (index >= 0) _catalog.removeAt(index);
      return;
    }
    if (index >= 0) {
      _catalog[index] = copy;
    } else {
      _catalog.add(copy);
    }
  }

  /// Per-store stock + price overrides (seed).
  static const _seedInventory = <String, Map<String, Map<String, dynamic>>>{
    MockIds.storeKoramangala: {
      'p_100': {'price': 55.0, 'stockQty': 42, 'lowStockThreshold': 10},
      'p_101': {'price': 45.0, 'stockQty': 18, 'lowStockThreshold': 8},
      'p_102': {'price': 20.0, 'stockQty': 0, 'lowStockThreshold': 10},
      'p_103': {'price': 65.0, 'stockQty': 12, 'lowStockThreshold': 10},
      'p_104': {'price': 30.0, 'stockQty': 25, 'lowStockThreshold': 10},
      'p_105': {'price': 42.0, 'stockQty': 8, 'lowStockThreshold': 10},
      'p_106': {'price': 48.0, 'stockQty': 30, 'lowStockThreshold': 10},
      'p_107': {'price': 35.0, 'stockQty': 40, 'lowStockThreshold': 10},
      'p_108': {'price': 28.0, 'stockQty': 50, 'lowStockThreshold': 10},
      // p_109 left out so Manager can demo "Add product" into stock.
    },
    MockIds.storeIndiranagar: {
      'p_100': {'price': 58.0, 'stockQty': 10, 'lowStockThreshold': 10},
      'p_101': {'price': 48.0, 'stockQty': 0, 'lowStockThreshold': 8},
      'p_102': {'price': 18.0, 'stockQty': 60, 'lowStockThreshold': 10},
      'p_103': {'price': 70.0, 'stockQty': 4, 'lowStockThreshold': 10},
      'p_104': {'price': 28.0, 'stockQty': 15, 'lowStockThreshold': 10},
      'p_105': {'price': 40.0, 'stockQty': 0, 'lowStockThreshold': 10},
      'p_106': {'price': 50.0, 'stockQty': 12, 'lowStockThreshold': 10},
      'p_107': {'price': 32.0, 'stockQty': 20, 'lowStockThreshold': 10},
      'p_108': {'price': 26.0, 'stockQty': 35, 'lowStockThreshold': 10},
      'p_109': {'price': 34.0, 'stockQty': 10, 'lowStockThreshold': 10},
    },
  };

  /// Includes inactive stores (API_REFERENCE: filter on `active` in the app).
  Map<String, dynamic> stores() => {
        'items': _stores.map((s) => Map<String, dynamic>.from(s)).toList(),
      };

  Map<String, dynamic> categories() => {
        'items': _categories.map((c) => Map<String, dynamic>.from(c)).toList(),
      };

  Map<String, dynamic> products({
    String? storeId,
    String? categoryId,
    String? query,
  }) {
    final store = storeId ?? MockIds.defaultStore;
    final inventory = _inventoryByStore[store] ?? const {};
    var items = _catalog.map((product) {
      final stock = inventory[product['id'] as String];
      final stockQty = (stock?['stockQty'] as num?)?.toInt() ?? 0;
      final price =
          (stock?['price'] as num?)?.toDouble() ??
          (product['basePrice'] as num?)?.toDouble() ??
          0.0;
      return {
        'id': product['id'],
        'sku': product['sku'],
        'name': product['name'],
        'unit': product['unit'],
        'categoryId': product['categoryId'],
        'description': product['description'],
        'imageUrl': product['imageUrl'],
        'price': price,
        'currency': 'INR',
        'stockQty': stockQty,
        'inStock': stockQty > 0,
      };
    }).toList();

    if (categoryId != null && categoryId.isNotEmpty) {
      items = items.where((p) => p['categoryId'] == categoryId).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      items = items
          .where(
            (p) =>
                (p['name'] as String).toLowerCase().contains(q) ||
                (p['sku'] as String).toLowerCase().contains(q),
          )
          .toList();
    }

    return {
      'items': items,
      'page': 0,
      'total': items.length,
      'storeId': store,
    };
  }

  Map<String, dynamic> productById({
    required String id,
    String? storeId,
  }) {
    final list = products(storeId: storeId)['items'] as List<dynamic>;
    final match = list.cast<Map<String, dynamic>>().where((p) => p['id'] == id);
    if (match.isEmpty) {
      throw Exception('Product not found');
    }
    return match.first;
  }

  Map<String, dynamic> inventory({String? storeId}) {
    final store = storeId ?? MockIds.defaultStore;
    final inventory = _inventoryByStore[store] ?? {};
    final items = <Map<String, dynamic>>[];
    for (final product in _catalog) {
      final id = product['id'] as String;
      final stock = inventory[id];
      if (stock == null) continue;
      final threshold = (stock['lowStockThreshold'] as num?)?.toInt() ?? 10;
      final qty = (stock['stockQty'] as num?)?.toInt() ?? 0;
      items.add({
        'productId': id,
        'sku': product['sku'],
        'name': product['name'],
        'quantityOnHand': qty,
        'reservedQuantity': 0,
        'price': stock['price'],
        'lowStockThreshold': threshold,
        'isLowStock': qty <= threshold,
      });
    }
    return {'items': items, 'storeId': store};
  }

  Map<String, dynamic> updateInventory({
    required String storeId,
    required String productId,
    double? price,
    int? stockQty,
    int? lowStockThreshold,
  }) {
    if (storeId.isEmpty) throw Exception('storeId is required');
    final storeInv = _inventoryByStore.putIfAbsent(storeId, () => {});
    final current = storeInv.putIfAbsent(
      productId,
      () => {
        'price': 0.0,
        'stockQty': 0,
        'lowStockThreshold': 10,
      },
    );
    if (price != null) current['price'] = price;
    if (stockQty != null) {
      if (stockQty < 0) throw Exception('stockQty cannot be negative');
      current['stockQty'] = stockQty;
    }
    if (lowStockThreshold != null) {
      current['lowStockThreshold'] = lowStockThreshold;
    }

    Map<String, dynamic>? product;
    for (final p in _catalog) {
      if (p['id'] == productId) {
        product = p;
        break;
      }
    }
    final threshold = (current['lowStockThreshold'] as num?)?.toInt() ?? 10;
    final qty = (current['stockQty'] as num?)?.toInt() ?? 0;
    return {
      'productId': productId,
      'sku': product?['sku'],
      'name': product?['name'] ?? productId,
      'quantityOnHand': qty,
      'reservedQuantity': 0,
      'price': current['price'],
      'lowStockThreshold': threshold,
      'isLowStock': qty <= threshold,
      'storeId': storeId,
    };
  }

  Map<String, dynamic> inventoryAlerts({required String storeId}) {
    final all = inventory(storeId: storeId);
    final items = (all['items'] as List)
        .cast<Map<String, dynamic>>()
        .where((item) => item['isLowStock'] == true)
        .toList();
    return {'items': items, 'storeId': storeId};
  }

  /// Catalog products not yet stocked at this store.
  Map<String, dynamic> availableProductsForStore({required String storeId}) {
    final stocked = _inventoryByStore[storeId]?.keys.toSet() ?? {};
    final items = _catalog
        .where((p) => !stocked.contains(p['id']))
        .map(
          (p) => {
            'id': p['id'],
            'sku': p['sku'],
            'name': p['name'],
            'basePrice': p['basePrice'],
            'categoryId': p['categoryId'],
          },
        )
        .toList();
    return {'items': items, 'storeId': storeId};
  }

  /// Add a catalog product (or create a new SKU) to this store's inventory.
  Map<String, dynamic> addInventoryItem({
    required String storeId,
    String? productId,
    String? name,
    String? sku,
    double? price,
    int? stockQty,
    int? lowStockThreshold,
  }) {
    if (storeId.isEmpty) throw Exception('storeId is required');

    String resolvedProductId = productId?.trim() ?? '';
    if (resolvedProductId.isEmpty) {
      final trimmedName = (name ?? '').trim();
      if (trimmedName.isEmpty) {
        throw Exception('Select a product or enter a name');
      }
      resolvedProductId = 'p_${DateTime.now().millisecondsSinceEpoch}';
      _catalog.add({
        'id': resolvedProductId,
        'sku': (sku ?? '').trim().isEmpty
            ? 'SKU-${resolvedProductId.substring(resolvedProductId.length - 4)}'
            : sku!.trim().toUpperCase(),
        'name': trimmedName,
        'unit': '1 unit',
        'categoryId': _categories.isNotEmpty ? _categories.first['id'] : null,
        'description': '',
        'imageUrl': null,
        'basePrice': price ?? 0,
        'active': true,
      });
    } else {
      final exists = _catalog.any((p) => p['id'] == resolvedProductId);
      if (!exists) throw Exception('Product not found in catalog');
      final storeInv = _inventoryByStore[storeId] ?? {};
      if (storeInv.containsKey(resolvedProductId)) {
        throw Exception('Product is already in this store inventory');
      }
    }

    return updateInventory(
      storeId: storeId,
      productId: resolvedProductId,
      price: price ?? 0,
      stockQty: stockQty ?? 0,
      lowStockThreshold: lowStockThreshold ?? 10,
    );
  }
}
