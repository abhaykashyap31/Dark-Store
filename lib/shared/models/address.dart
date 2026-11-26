class Address {
  const Address({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    required this.postalCode,
    this.line2,
    this.state,
    this.country = 'India',
    this.defaultAddress = false,
  });

  /// UUID string.
  final String id;
  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String? state;

  /// Gateway field `postalCode`.
  final String postalCode;
  final String country;

  /// Gateway field `defaultAddress`.
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
          '${json['postalCode'] ?? json['postal_code'] ?? json['pincode'] ?? ''}',
      country: '${json['country'] ?? 'India'}',
      defaultAddress: json['defaultAddress'] == true ||
          json['default_address'] == true ||
          json['isDefault'] == true,
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
        'country': country,
        'defaultAddress': defaultAddress,
      };

  /// Body for POST/PUT (no id).
  Map<String, dynamic> toRequestBody() => {
        if (label.trim().isNotEmpty) 'label': label.trim(),
        'line1': line1.trim(),
        if (line2 != null && line2!.trim().isNotEmpty) 'line2': line2!.trim(),
        'city': city.trim(),
        if (state != null && state!.trim().isNotEmpty) 'state': state!.trim(),
        'postalCode': postalCode.trim(),
        'country': country.trim().isEmpty ? 'India' : country.trim(),
        'defaultAddress': defaultAddress,
      };

  String get summary {
    final parts = [
      line1,
      if (line2 != null && line2!.trim().isNotEmpty) line2,
      city,
      if (state != null && state!.trim().isNotEmpty) state,
      postalCode,
      if (country.trim().isNotEmpty) country,
    ].whereType<String>().where((p) => p.trim().isNotEmpty);
    return parts.join(', ');
  }
}
