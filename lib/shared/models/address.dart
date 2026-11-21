class Address {
  const Address({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    required this.postalCode,
    this.line2,
    this.state,
    this.defaultAddress = false,
  });

  final String id;
  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String? state;
  final String postalCode;
  final bool defaultAddress;

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: '${json['id'] ?? ''}',
      label: '${json['label'] ?? 'Address'}',
      line1: '${json['line1'] ?? ''}',
      line2: json['line2']?.toString(),
      city: '${json['city'] ?? ''}',
      state: json['state']?.toString(),
      postalCode:
          '${json['postalCode'] ?? json['postal_code'] ?? ''}',
      defaultAddress: json['defaultAddress'] == true ||
          json['default_address'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'line1': line1,
        'line2': line2,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'defaultAddress': defaultAddress,
      };

  String get summary {
    final parts = [
      line1,
      if (line2 != null && line2!.trim().isNotEmpty) line2,
      city,
      if (state != null && state!.trim().isNotEmpty) state,
      postalCode,
    ].whereType<String>().where((p) => p.trim().isNotEmpty);
    return parts.join(', ');
  }
}
