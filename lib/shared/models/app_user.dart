import '../../core/constants/app_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.active,
    this.storeId,
    this.phone,
  });

  final String id;
  final String email;
  final String name;
  final AppRole role;
  final String? storeId;
  final String? phone;
  final bool active;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final roleRaw = '${json['role'] ?? 'USER'}';
    return AppUser(
      id: '${json['id'] ?? ''}',
      email: '${json['email'] ?? ''}',
      name: '${json['name'] ?? json['full_name'] ?? ''}',
      role: AppRole.fromApi(roleRaw),
      storeId: json['storeId']?.toString() ?? json['store_id']?.toString(),
      phone: json['phone']?.toString(),
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role.apiValue,
        'storeId': storeId,
        'phone': phone,
        'active': active,
      };

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    AppRole? role,
    String? storeId,
    String? phone,
    bool? active,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      storeId: storeId ?? this.storeId,
      phone: phone ?? this.phone,
      active: active ?? this.active,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AppUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int? ?? 900,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
