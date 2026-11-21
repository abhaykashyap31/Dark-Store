class Address {
  const Address({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    required this.postalCode,
    this.line2,
    this.state,
    this.latitude,
    this.longitude,
    this.defaultAddress = false,
  });

  final String id;
  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String? state;

  /// Gateway field `pincode`.
  final String postalCode;
  final double? latitude;
  final double? longitude;

  /// Gateway field `isDefault`.
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
          '${json['pincode'] ?? json['postalCode'] ?? json['postal_code'] ?? ''}',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      defaultAddress: json['isDefault'] == true ||
          json['defaultAddress'] == true ||
          json['default_address'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': int.tryParse(id) ?? id,
        'label': label,
        'line1': line1,
        'line2': line2,
        'city': city,
        'pincode': postalCode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'isDefault': defaultAddress,
      };

  /// Body for POST/PUT (no id).
  Map<String, dynamic> toRequestBody() => {
        if (label.trim().isNotEmpty) 'label': label.trim(),
        'line1': line1.trim(),
        if (line2 != null && line2!.trim().isNotEmpty) 'line2': line2!.trim(),
        'city': city.trim(),
        'pincode': postalCode.trim(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'isDefault': defaultAddress,
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
