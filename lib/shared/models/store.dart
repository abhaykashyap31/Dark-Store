class Store {
  const Store({
    required this.id,
    required this.name,
    required this.code,
    required this.city,
    required this.active,
    this.line1,
    this.state,
    this.postalCode,
    this.phone,
  });

  /// UUID string.
  final String id;
  final String name;
  final String code;
  final String city;
  final bool active;

  /// Street / locality (Gateway field `line1`).
  final String? line1;
  final String? state;
  final String? postalCode;
  final String? phone;

  /// Convenience for older UI that showed a single address line.
  String? get address => line1;

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      code: '${json['code'] ?? ''}',
      city: '${json['city'] ?? ''}',
      active: json['active'] as bool? ?? true,
      line1: json['line1']?.toString() ?? json['address']?.toString(),
      state: json['state']?.toString(),
      postalCode:
          json['postalCode']?.toString() ?? json['postal_code']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'city': city,
        'active': active,
        'line1': line1,
        'state': state,
        'postalCode': postalCode,
        'phone': phone,
      };

  Map<String, dynamic> toRequestBody() => {
        'code': code,
        'name': name,
        'line1': line1,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'phone': phone,
        'active': active,
      };
}
