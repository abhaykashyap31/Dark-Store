import '../core/constants/order_status.dart';
import 'catalog_api_mock.dart';

/// Mutable in-memory cart / orders mock for Order & Fulfillment paths.
class OrderApiMock {
  static final OrderApiMock instance = OrderApiMock._();

  OrderApiMock._() {
    _seedDemoOrders();
  }

  factory OrderApiMock() => instance;

  String? _cartStoreId;
  final List<Map<String, dynamic>> _cartItems = [];
  final Map<String, Map<String, dynamic>> _orders = {};
  int _orderSeq = 10030;

  void resetForTests() {
    _cartStoreId = null;
    _cartItems.clear();
    _orders.clear();
    _orderSeq = 10030;
    _seedDemoOrders();
  }

  void _seedDemoOrders() {
    _orders['o_500'] = {
      'id': 'o_500',
      'orderNumber': 'DS-10021',
      'status': OrderStatus.confirmed,
      'storeId': 's_001',
      'totalAmount': 320.0,
      'itemsCount': 4,
      'paymentMethod': 'COD',
      'paymentStatus': 'PENDING',
      'customerName': 'Asha Customer',
      'delivery': {
        'recipientName': 'Asha Customer',
        'phone': '9000000001',
        'addressText': '12 MG Road, Bengaluru 560001',
      },
      'items': [
        {
          'productId': 'p_100',
          'name': 'Milk 1L',
          'unitPrice': 55.0,
          'quantity': 2,
        },
        {
          'productId': 'p_104',
          'name': 'Potato Chips',
          'unitPrice': 30.0,
          'quantity': 2,
        },
      ],
      'statusHistory': [
        {
          'fromStatus': null,
          'toStatus': OrderStatus.created,
          'changedAt': '2026-11-19T10:00:00Z',
          'changedByRole': 'USER',
          'note': 'Order placed',
        },
        {
          'fromStatus': OrderStatus.created,
          'toStatus': OrderStatus.confirmed,
          'changedAt': '2026-11-19T10:01:00Z',
          'changedByRole': 'SYSTEM',
          'note': 'Auto-confirmed (mock)',
        },
      ],
      'createdAt': '2026-11-19T10:00:00Z',
    };

    _orders['o_510'] = {
      'id': 'o_510',
      'orderNumber': 'DS-10025',
      'status': OrderStatus.picking,
      'storeId': 's_001',
      'totalAmount': 210.0,
      'itemsCount': 3,
      'paymentMethod': 'COD',
      'paymentStatus': 'PENDING',
      'customerName': 'Asha Customer',
      'delivery': {
        'recipientName': 'Asha Customer',
        'phone': '9000000001',
        'addressText': '12 MG Road, Bengaluru 560001',
      },
      'items': [
        {
          'productId': 'p_101',
          'name': 'Whole Wheat Bread',
          'unitPrice': 45.0,
          'quantity': 2,
        },
        {
          'productId': 'p_105',
          'name': 'Cola 750ml',
          'unitPrice': 42.0,
          'quantity': 1,
        },
      ],
      'statusHistory': [
        {
          'fromStatus': null,
          'toStatus': OrderStatus.created,
          'changedAt': '2026-11-19T09:00:00Z',
          'changedByRole': 'USER',
        },
        {
          'fromStatus': OrderStatus.created,
          'toStatus': OrderStatus.confirmed,
          'changedAt': '2026-11-19T09:01:00Z',
          'changedByRole': 'SYSTEM',
        },
        {
          'fromStatus': OrderStatus.confirmed,
          'toStatus': OrderStatus.picking,
          'changedAt': '2026-11-19T09:15:00Z',
          'changedByRole': 'MANAGER',
          'note': 'Store started packing',
        },
      ],
      'createdAt': '2026-11-19T09:00:00Z',
    };

    _orders['o_520'] = {
      'id': 'o_520',
      'orderNumber': 'DS-10026',
      'status': OrderStatus.outForDelivery,
      'storeId': 's_001',
      'totalAmount': 150.0,
      'itemsCount': 2,
      'paymentMethod': 'MOCK_PAY',
      'paymentStatus': 'MOCK_PAID',
      'customerName': 'Asha Customer',
      'assignedRiderId': 'u_020',
      'assignedRiderName': 'Delivery Rider',
      'delivery': {
        'recipientName': 'Asha Customer',
        'phone': '9000000001',
        'addressText': '42 Indiranagar 100 Feet Rd, Bengaluru 560038',
      },
      'items': [
        {
          'productId': 'p_103',
          'name': 'Greek Yogurt 200g',
          'unitPrice': 65.0,
          'quantity': 2,
        },
      ],
      'statusHistory': [
        {
          'fromStatus': null,
          'toStatus': OrderStatus.created,
          'changedAt': '2026-11-18T14:00:00Z',
          'changedByRole': 'USER',
        },
        {
          'fromStatus': OrderStatus.created,
          'toStatus': OrderStatus.confirmed,
          'changedAt': '2026-11-18T14:01:00Z',
          'changedByRole': 'SYSTEM',
        },
        {
          'fromStatus': OrderStatus.confirmed,
          'toStatus': OrderStatus.picking,
          'changedAt': '2026-11-18T14:10:00Z',
          'changedByRole': 'MANAGER',
        },
        {
          'fromStatus': OrderStatus.picking,
          'toStatus': OrderStatus.packed,
          'changedAt': '2026-11-18T14:20:00Z',
          'changedByRole': 'MANAGER',
        },
        {
          'fromStatus': OrderStatus.packed,
          'toStatus': OrderStatus.assigned,
          'changedAt': '2026-11-18T14:25:00Z',
          'changedByRole': 'MANAGER',
        },
        {
          'fromStatus': OrderStatus.assigned,
          'toStatus': OrderStatus.outForDelivery,
          'changedAt': '2026-11-18T14:40:00Z',
          'changedByRole': 'RIDER',
        },
      ],
      'createdAt': '2026-11-18T14:00:00Z',
    };

    _orders['o_530'] = {
      'id': 'o_530',
      'orderNumber': 'DS-10028',
      'status': OrderStatus.assigned,
      'storeId': 's_001',
      'totalAmount': 275.0,
      'itemsCount': 3,
      'paymentMethod': 'COD',
      'paymentStatus': 'PENDING',
      'customerName': 'Asha Customer',
      'assignedRiderId': 'u_020',
      'assignedRiderName': 'Delivery Rider',
      'delivery': {
        'recipientName': 'Asha Customer',
        'phone': '9000000001',
        'addressText': '12 MG Road, Bengaluru 560001',
      },
      'items': [
        {
          'productId': 'p_100',
          'name': 'Milk 1L',
          'unitPrice': 55.0,
          'quantity': 1,
        },
        {
          'productId': 'p_101',
          'name': 'Whole Wheat Bread',
          'unitPrice': 45.0,
          'quantity': 2,
        },
        {
          'productId': 'p_105',
          'name': 'Cola 750ml',
          'unitPrice': 42.0,
          'quantity': 1,
        },
      ],
      'statusHistory': [
        {
          'fromStatus': null,
          'toStatus': OrderStatus.created,
          'changedAt': '2026-11-20T07:00:00Z',
          'changedByRole': 'USER',
        },
        {
          'fromStatus': OrderStatus.created,
          'toStatus': OrderStatus.confirmed,
          'changedAt': '2026-11-20T07:01:00Z',
          'changedByRole': 'SYSTEM',
        },
        {
          'fromStatus': OrderStatus.confirmed,
          'toStatus': OrderStatus.picking,
          'changedAt': '2026-11-20T07:10:00Z',
          'changedByRole': 'MANAGER',
        },
        {
          'fromStatus': OrderStatus.picking,
          'toStatus': OrderStatus.packed,
          'changedAt': '2026-11-20T07:20:00Z',
          'changedByRole': 'MANAGER',
        },
        {
          'fromStatus': OrderStatus.packed,
          'toStatus': OrderStatus.assigned,
          'changedAt': '2026-11-20T07:25:00Z',
          'changedByRole': 'MANAGER',
          'note': 'Assigned to Delivery Rider',
        },
      ],
      'createdAt': '2026-11-20T07:00:00Z',
    };
  }

  Map<String, dynamic> cart({String? storeId}) {
    if (storeId != null && storeId.isNotEmpty && _cartStoreId != storeId) {
      // Switching store clears cart in this mock.
      if (_cartStoreId != null && _cartItems.isNotEmpty) {
        _cartItems.clear();
      }
      _cartStoreId = storeId;
    }
    return _cartPayload();
  }

  Map<String, dynamic> addCartItem({
    required String productId,
    required int quantity,
    required String storeId,
  }) {
    if (quantity <= 0) {
      throw Exception('Quantity must be at least 1');
    }

    if (_cartStoreId != null &&
        _cartStoreId != storeId &&
        _cartItems.isNotEmpty) {
      throw Exception('Cart already has items from another store. Clear cart first.');
    }

    _cartStoreId = storeId;
    final product = CatalogApiMock().productById(
      id: productId,
      storeId: storeId,
    );
    if (product['inStock'] != true) {
      throw Exception('Product is out of stock');
    }

    final existingIndex =
        _cartItems.indexWhere((item) => item['productId'] == productId);
    if (existingIndex >= 0) {
      final current = _cartItems[existingIndex]['quantity'] as int;
      final nextQty = current + quantity;
      final stockQty = product['stockQty'] as int;
      if (nextQty > stockQty) {
        throw Exception('Only $stockQty available');
      }
      _cartItems[existingIndex]['quantity'] = nextQty;
      _cartItems[existingIndex]['unitPrice'] = product['price'];
      _cartItems[existingIndex]['productName'] = product['name'];
    } else {
      final stockQty = product['stockQty'] as int;
      if (quantity > stockQty) {
        throw Exception('Only $stockQty available');
      }
      _cartItems.add({
        'id': 'ci_${DateTime.now().millisecondsSinceEpoch}',
        'productId': productId,
        'productName': product['name'],
        'unitPrice': product['price'],
        'quantity': quantity,
      });
    }

    return _cartPayload();
  }

  Map<String, dynamic> updateCartItem({
    required String itemId,
    required int quantity,
  }) {
    final index = _cartItems.indexWhere((item) => item['id'] == itemId);
    if (index < 0) {
      throw Exception('Cart item not found');
    }
    if (quantity <= 0) {
      _cartItems.removeAt(index);
      return _cartPayload();
    }

    final productId = _cartItems[index]['productId'] as String;
    final product = CatalogApiMock().productById(
      id: productId,
      storeId: _cartStoreId ?? 's_001',
    );
    final stockQty = product['stockQty'] as int;
    if (quantity > stockQty) {
      throw Exception('Only $stockQty available');
    }
    _cartItems[index]['quantity'] = quantity;
    _cartItems[index]['unitPrice'] = product['price'];
    return _cartPayload();
  }

  Map<String, dynamic> removeCartItem({required String itemId}) {
    _cartItems.removeWhere((item) => item['id'] == itemId);
    return _cartPayload();
  }

  Map<String, dynamic> clearCart() {
    _cartItems.clear();
    return _cartPayload();
  }

  Map<String, dynamic> placeOrder({
    required String addressId,
    required Map<String, dynamic> addressSnapshot,
    String paymentMethod = 'COD',
    Map<String, dynamic>? user,
  }) {
    if (_cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }
    if (_cartStoreId == null || _cartStoreId!.isEmpty) {
      throw Exception('Store is required');
    }
    if (addressId.isEmpty) {
      throw Exception('Delivery address is required');
    }

    final orderId = 'o_${DateTime.now().millisecondsSinceEpoch}';
    final orderNumber = 'DS-${_orderSeq++}';
    final items = _cartItems
        .map(
          (item) => {
            'productId': item['productId'],
            'sku': '',
            'name': item['productName'],
            'unitPrice': item['unitPrice'],
            'quantity': item['quantity'],
          },
        )
        .toList();
    final subtotal = _subtotal();
    final total = subtotal;
    final now = DateTime.now().toUtc().toIso8601String();

    final order = <String, dynamic>{
      'id': orderId,
      'orderNumber': orderNumber,
      'status': 'CONFIRMED',
      'storeId': _cartStoreId,
      'userId': user?['id'],
      'customerName': user?['name'] ?? 'Customer',
      'itemsCount': items.fold<int>(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      ),
      'subtotal': subtotal,
      'totalAmount': total,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentMethod == 'COD' ? 'PENDING' : 'MOCK_PAID',
      'addressId': addressId,
      'delivery': {
        'recipientName': user?['name'] ?? 'Customer',
        'phone': user?['phone'],
        'label': addressSnapshot['label'],
        'line1': addressSnapshot['line1'],
        'line2': addressSnapshot['line2'],
        'city': addressSnapshot['city'],
        'state': addressSnapshot['state'],
        'postalCode':
            addressSnapshot['postalCode'] ?? addressSnapshot['postal_code'],
        'addressText': _formatAddress(addressSnapshot),
      },
      'items': items,
      'statusHistory': [
        {
          'fromStatus': null,
          'toStatus': 'CREATED',
          'changedAt': now,
          'changedByRole': 'USER',
          'note': 'Order placed',
        },
        {
          'fromStatus': 'CREATED',
          'toStatus': 'CONFIRMED',
          'changedAt': now,
          'changedByRole': 'SYSTEM',
          'note': 'Auto-confirmed (mock)',
        },
      ],
      'createdAt': now,
    };

    _orders[orderId] = order;
    _cartItems.clear();
    return Map<String, dynamic>.from(order);
  }

  Map<String, dynamic> orders() {
    final items = _orders.values
        .map(
          (order) => {
            'id': order['id'],
            'orderNumber': order['orderNumber'],
            'status': order['status'],
            'storeId': order['storeId'],
            'totalAmount': order['totalAmount'],
            'itemsCount': order['itemsCount'],
            'createdAt': order['createdAt'],
            'paymentMethod': order['paymentMethod'],
          },
        )
        .toList()
      ..sort(
        (a, b) =>
            (b['createdAt'] as String).compareTo(a['createdAt'] as String),
      );
    return {'items': items};
  }

  Map<String, dynamic> orderById(String id) {
    final order = _orders[id];
    if (order == null) {
      throw Exception('Order not found');
    }
    return Map<String, dynamic>.from(order)
      ..['items'] = (order['items'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
      ..['statusHistory'] = (order['statusHistory'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
      ..['delivery'] = Map<String, dynamic>.from(
        order['delivery'] as Map? ?? const {},
      );
  }

  Map<String, dynamic> cancelOrder(String id) {
    final order = _orders[id];
    if (order == null) {
      throw Exception('Order not found');
    }
    final status = order['status'] as String;
    if (!OrderStatus.canUserCancel(status)) {
      throw Exception(
        'Cannot cancel after packing starts (status: $status)',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final history = (order['statusHistory'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    history.add({
      'fromStatus': status,
      'toStatus': OrderStatus.cancelled,
      'changedAt': now,
      'changedByRole': 'USER',
      'note': 'Cancelled by customer before packing',
    });
    order['status'] = OrderStatus.cancelled;
    order['statusHistory'] = history;
    return orderById(id);
  }

  Map<String, dynamic> managerOrders({
    required String storeId,
    String? status,
  }) {
    if (storeId.isEmpty) {
      throw Exception('storeId is required');
    }
    var items = _orders.values
        .where((order) => order['storeId'] == storeId)
        .where(
          (order) =>
              order['status'] != OrderStatus.cancelled &&
              order['status'] != OrderStatus.delivered,
        )
        .map(
          (order) => {
            'id': order['id'],
            'orderNumber': order['orderNumber'],
            'status': order['status'],
            'storeId': order['storeId'],
            'customerName': order['customerName'],
            'itemsCount': order['itemsCount'],
            'totalAmount': order['totalAmount'],
            'createdAt': order['createdAt'],
            'assignedRiderId': order['assignedRiderId'],
            'assignedRiderName': order['assignedRiderName'],
          },
        )
        .toList();

    if (status != null && status.isNotEmpty) {
      items = items.where((o) => o['status'] == status).toList();
    }

    items.sort(
      (a, b) =>
          (b['createdAt'] as String).compareTo(a['createdAt'] as String),
    );
    return {'items': items, 'storeId': storeId};
  }

  Map<String, dynamic> patchManagerStatus({
    required String orderId,
    required String toStatus,
    required String storeId,
  }) {
    final order = _orders[orderId];
    if (order == null) throw Exception('Order not found');
    if (order['storeId'] != storeId) {
      throw Exception('Order does not belong to this store');
    }

    final current = order['status'] as String;
    final expected = OrderStatus.managerNextStatus(current);
    if (expected == null || expected != toStatus) {
      throw Exception(
        'Illegal transition from $current to $toStatus',
      );
    }

    return _appendStatus(
      order: order,
      toStatus: toStatus,
      changedByRole: 'MANAGER',
      note: 'Manager advanced status',
    );
  }

  Map<String, dynamic> assignRider({
    required String orderId,
    required String storeId,
    required String riderId,
    required String riderName,
  }) {
    final order = _orders[orderId];
    if (order == null) throw Exception('Order not found');
    if (order['storeId'] != storeId) {
      throw Exception('Order does not belong to this store');
    }
    final current = order['status'] as String;
    if (!OrderStatus.canAssignRider(current)) {
      throw Exception('Assign rider only when status is PACKED');
    }
    if (riderId.isEmpty) {
      throw Exception('riderId is required');
    }

    order['assignedRiderId'] = riderId;
    order['assignedRiderName'] = riderName;
    return _appendStatus(
      order: order,
      toStatus: OrderStatus.assigned,
      changedByRole: 'MANAGER',
      note: 'Assigned to $riderName',
    );
  }

  Map<String, dynamic> riderOrders({
    required String storeId,
    required String riderId,
  }) {
    if (storeId.isEmpty) {
      throw Exception('storeId is required');
    }
    if (riderId.isEmpty) {
      throw Exception('riderId is required');
    }

    final items = _orders.values.where(
      (order) =>
          order['storeId'] == storeId &&
          order['assignedRiderId'] == riderId &&
          (order['status'] == OrderStatus.assigned ||
              order['status'] == OrderStatus.outForDelivery),
    );

    return {
      'items': items
          .map(
            (order) => {
              'id': order['id'],
              'orderNumber': order['orderNumber'],
              'status': order['status'],
              'storeId': order['storeId'],
              'customerName': order['customerName'],
              'paymentMethod': order['paymentMethod'],
              'totalAmount': order['totalAmount'],
              'addressSummary':
                  (order['delivery'] as Map?)?['addressText'] ?? '',
              'itemsCount': order['itemsCount'],
              'codAmount': order['paymentMethod'] == 'COD'
                  ? order['totalAmount']
                  : 0,
              'assignedRiderId': order['assignedRiderId'],
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic> patchRiderStatus({
    required String orderId,
    required String toStatus,
    required String storeId,
    required String riderId,
  }) {
    final order = _orders[orderId];
    if (order == null) throw Exception('Order not found');
    if (order['storeId'] != storeId) {
      throw Exception('Order does not belong to this store');
    }
    if (order['assignedRiderId'] != riderId) {
      throw Exception('Order is not assigned to this rider');
    }

    final current = order['status'] as String;
    final expected = OrderStatus.riderNextStatus(current);
    if (expected == null || expected != toStatus) {
      throw Exception('Illegal rider transition from $current to $toStatus');
    }

    if (toStatus == OrderStatus.delivered && order['paymentMethod'] == 'COD') {
      order['paymentStatus'] = 'COLLECTED';
    }

    return _appendStatus(
      order: order,
      toStatus: toStatus,
      changedByRole: 'RIDER',
      note: 'Rider updated delivery status',
    );
  }

  Map<String, dynamic> _appendStatus({
    required Map<String, dynamic> order,
    required String toStatus,
    required String changedByRole,
    String? note,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    final fromStatus = order['status'] as String;
    final history = (order['statusHistory'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    history.add({
      'fromStatus': fromStatus,
      'toStatus': toStatus,
      'changedAt': now,
      'changedByRole': changedByRole,
      'note': ?note,
    });
    order['status'] = toStatus;
    order['statusHistory'] = history;
    return orderById(order['id'] as String);
  }

  Map<String, dynamic> _cartPayload() {
    return {
      'id': 'cart_current',
      'storeId': _cartStoreId,
      'items': _cartItems.map((e) => Map<String, dynamic>.from(e)).toList(),
      'subtotal': _subtotal(),
      'itemsCount': _cartItems.fold<int>(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      ),
    };
  }

  double _subtotal() {
    return _cartItems.fold<double>(0, (sum, item) {
      final price = (item['unitPrice'] as num).toDouble();
      final qty = item['quantity'] as int;
      return sum + (price * qty);
    });
  }

  String _formatAddress(Map<String, dynamic> address) {
    final parts = [
      address['line1'],
      address['line2'],
      address['city'],
      address['state'],
      address['postalCode'] ?? address['postal_code'],
    ].where((p) => p != null && p.toString().trim().isNotEmpty).join(', ');
    return parts;
  }
}
