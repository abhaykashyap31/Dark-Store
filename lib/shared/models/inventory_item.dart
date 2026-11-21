class InventoryItem {
  const InventoryItem({
    required this.productId,
    required this.name,
    required this.quantityOnHand,
    required this.price,
    required this.lowStockThreshold,
    required this.isLowStock,
    this.sku,
    this.reservedQuantity = 0,
  });

  final String productId;
  final String name;
  final String? sku;
  final int quantityOnHand;
  final int reservedQuantity;
  final double price;
  final int lowStockThreshold;
  final bool isLowStock;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantityOnHand'] as num?)?.toInt() ?? 0;
    final threshold = (json['lowStockThreshold'] as num?)?.toInt() ?? 10;
    return InventoryItem(
      productId: json['productId'] as String,
      name: json['name'] as String? ?? json['productId'] as String,
      sku: json['sku'] as String?,
      quantityOnHand: qty,
      reservedQuantity: (json['reservedQuantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      lowStockThreshold: threshold,
      isLowStock: json['isLowStock'] as bool? ?? qty <= threshold,
    );
  }

  String get priceLabel =>
      '₹${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}';
}
