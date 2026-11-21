class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  final String id;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  double get lineTotal => unitPrice * quantity;

  String get priceLabel =>
      '₹${unitPrice.toStringAsFixed(unitPrice.truncateToDouble() == unitPrice ? 0 : 2)}';
}

class Cart {
  const Cart({
    required this.id,
    required this.items,
    required this.subtotal,
    this.storeId,
    this.itemsCount = 0,
  });

  final String id;
  final String? storeId;
  final List<CartItem> items;
  final double subtotal;
  final int itemsCount;

  bool get isEmpty => items.isEmpty;

  CartItem? itemForProduct(String productId) {
    for (final item in items) {
      if (item.productId == productId) return item;
    }
    return null;
  }

  int quantityForProduct(String productId) =>
      itemForProduct(productId)?.quantity ?? 0;

  factory Cart.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(CartItem.fromJson)
        .toList();
    final subtotal = (json['subtotal'] as num?)?.toDouble() ??
        items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final itemsCount = (json['itemsCount'] as num?)?.toInt() ??
        items.fold<int>(0, (sum, item) => sum + item.quantity);
    return Cart(
      id: json['id'] as String? ?? 'cart',
      storeId: json['storeId'] as String?,
      items: items,
      subtotal: subtotal,
      itemsCount: itemsCount,
    );
  }

  String get subtotalLabel =>
      '₹${subtotal.toStringAsFixed(subtotal.truncateToDouble() == subtotal ? 0 : 2)}';
}
