class Store {
  const Store({
    required this.id,
    required this.name,
    required this.code,
    required this.city,
    required this.active,
  });

  final String id;
  final String name;
  final String code;
  final String city;
  final bool active;

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      code: '${json['code'] ?? ''}',
      city: '${json['city'] ?? ''}',
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'city': city,
        'active': active,
      };
}
