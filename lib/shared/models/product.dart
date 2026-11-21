class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.currency,
    required this.inStock,
    required this.stockQty,
    this.description,
    this.imageUrl,
    this.unit,
  });

  final String id;
  final String sku;
  final String name;
  final String categoryId;
  final double price;
  final String currency;
  final bool inStock;
  final int stockQty;
  final String? description;
  final String? imageUrl;
  final String? unit;

  factory Product.fromJson(Map<String, dynamic> json) {
    final stockQty = (json['stockQty'] as num?)?.toInt() ?? 0;
    final inStock = json['inStock'] as bool? ?? stockQty > 0;
    return Product(
      id: '${json['id'] ?? ''}',
      sku: '${json['sku'] ?? ''}',
      name: '${json['name'] ?? ''}',
      categoryId: '${json['categoryId'] ?? json['category_id'] ?? ''}',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      inStock: inStock,
      stockQty: stockQty,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      unit: json['unit'] as String?,
    );
  }

  String get priceLabel => '₹${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}';
}
