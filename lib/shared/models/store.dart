class Store {
  const Store({
    required this.id,
    required this.name,
    required this.code,
    required this.city,
    required this.active,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String code;
  final String city;
  final bool active;
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      code: '${json['code'] ?? ''}',
      city: '${json['city'] ?? ''}',
      active: json['active'] as bool? ?? true,
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': int.tryParse(id) ?? id,
        'name': name,
        'code': code,
        'city': city,
        'active': active,
        'address': address,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
      };

  Map<String, dynamic> toRequestBody() => {
        'code': code,
        'name': name,
        'address': address,
        'city': city,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'active': active,
      };
}
