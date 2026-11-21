import '../../core/constants/order_status.dart';

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.sku,
  });

  final String productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? sku;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String? ?? '',
      name: json['name'] as String? ?? json['productName'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      sku: json['sku'] as String?,
    );
  }

  double get lineTotal => unitPrice * quantity;
}

class OrderStatusEvent {
  const OrderStatusEvent({
    required this.toStatus,
    required this.changedAt,
    this.fromStatus,
    this.changedByRole,
    this.note,
  });

  final String? fromStatus;
  final String toStatus;
  final String changedAt;
  final String? changedByRole;
  final String? note;

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return OrderStatusEvent(
      fromStatus: json['fromStatus'] as String?,
      toStatus: json['toStatus'] as String,
      changedAt: json['changedAt'] as String? ?? '',
      changedByRole: json['changedByRole'] as String?,
      note: json['note'] as String?,
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.storeId,
    required this.totalAmount,
    required this.itemsCount,
    required this.items,
    required this.statusHistory,
    this.paymentMethod,
    this.paymentStatus,
    this.customerName,
    this.deliveryAddressText,
    this.createdAt,
    this.codAmount,
    this.assignedRiderId,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String storeId;
  final double totalAmount;
  final int itemsCount;
  final List<OrderItem> items;
  final List<OrderStatusEvent> statusHistory;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? customerName;
  final String? deliveryAddressText;
  final String? createdAt;
  final double? codAmount;
  final String? assignedRiderId;

  factory Order.fromJson(Map<String, dynamic> json) {
    final delivery = json['delivery'] as Map<String, dynamic>?;
    final items = (json['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(OrderItem.fromJson)
        .toList();
    final history = (json['statusHistory'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(OrderStatusEvent.fromJson)
        .toList();
    final totalAmount = (json['totalAmount'] as num?)?.toDouble() ?? 0;
    final paymentMethod = json['paymentMethod'] as String?;
    final codFromJson = (json['codAmount'] as num?)?.toDouble();
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String? ?? json['id'] as String,
      status: json['status'] as String,
      storeId: json['storeId'] as String? ?? '',
      totalAmount: totalAmount,
      itemsCount: (json['itemsCount'] as num?)?.toInt() ??
          items.fold<int>(0, (sum, item) => sum + item.quantity),
      items: items,
      statusHistory: history,
      paymentMethod: paymentMethod,
      paymentStatus: json['paymentStatus'] as String?,
      customerName: json['customerName'] as String? ??
          delivery?['recipientName'] as String?,
      deliveryAddressText: delivery?['addressText'] as String? ??
          json['addressSummary'] as String?,
      createdAt: json['createdAt'] as String?,
      codAmount: codFromJson ??
          (paymentMethod == 'COD' ? totalAmount : null),
      assignedRiderId: json['assignedRiderId'] as String?,
    );
  }

  String get totalLabel =>
      '₹${totalAmount.toStringAsFixed(totalAmount.truncateToDouble() == totalAmount ? 0 : 2)}';

  String get statusLabel => OrderStatus.label(status);

  bool get canCancel => OrderStatus.canUserCancel(status);

  bool get isCancelled => status == OrderStatus.cancelled;

  bool get isCod =>
      paymentMethod == 'COD' || (codAmount != null && codAmount! > 0);

  String? get codLabel {
    final amount = codAmount;
    if (amount == null || amount <= 0) return null;
    return 'COD ₹${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }
}
