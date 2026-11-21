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
    this.status = 'ACTIVE',
  });

  final String id;
  final String email;
  final String name;
  final AppRole role;
  final String? storeId;
  final String? phone;

  /// Gateway `status`: `ACTIVE` | `DISABLED`.
  final String status;

  /// Convenience for UI; mirrors `status == ACTIVE`.
  final bool active;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final roleRaw = '${json['role'] ?? 'CUSTOMER'}';
    final statusRaw = '${json['status'] ?? ''}'.toUpperCase();
    final legacyActive = json['active'];
    final active = statusRaw == 'DISABLED'
        ? false
        : statusRaw == 'ACTIVE'
            ? true
            : legacyActive is bool
                ? legacyActive
                : true;
    final status = statusRaw.isNotEmpty
        ? statusRaw
        : (active ? 'ACTIVE' : 'DISABLED');

    return AppUser(
      id: '${json['id'] ?? ''}',
      email: '${json['email'] ?? ''}',
      name: '${json['name'] ?? json['full_name'] ?? ''}',
      role: AppRole.fromApi(roleRaw),
      storeId: json['storeId']?.toString() ?? json['store_id']?.toString(),
      phone: json['phone']?.toString(),
      status: status,
      active: active,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': int.tryParse(id) ?? id,
        'email': email,
        'name': name,
        'role': role.apiValue,
        'storeId': storeId == null ? null : (int.tryParse(storeId!) ?? storeId),
        'phone': phone,
        'status': status,
      };

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    AppRole? role,
    String? storeId,
    String? phone,
    String? status,
    bool? active,
  }) {
    final nextStatus = status ?? this.status;
    final nextActive = active ??
        (nextStatus == 'DISABLED'
            ? false
            : nextStatus == 'ACTIVE'
                ? true
                : this.active);
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      storeId: storeId ?? this.storeId,
      phone: phone ?? this.phone,
      status: nextStatus,
      active: nextActive,
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
      accessToken: '${json['accessToken'] ?? ''}',
      refreshToken: '${json['refreshToken'] ?? ''}',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 900,
      user: AppUser.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
    );
  }
}
