class AdminProduct {
  const AdminProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.basePrice,
    required this.active,
    this.categoryId,
    this.description,
  });

  final String id;
  final String sku;
  final String name;
  final double basePrice;
  final bool active;
  final String? categoryId;
  final String? description;

  factory AdminProduct.fromJson(Map<String, dynamic> json) {
    return AdminProduct(
      id: json['id'] as String,
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      active: json['active'] as bool? ?? true,
      categoryId: json['categoryId'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sku': sku,
        'name': name,
        'basePrice': basePrice,
        'active': active,
        'categoryId': categoryId,
        'description': description,
      };

  String get priceLabel =>
      '₹${basePrice.toStringAsFixed(basePrice.truncateToDouble() == basePrice ? 0 : 2)}';
}
