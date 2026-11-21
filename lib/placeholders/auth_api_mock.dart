import '../core/constants/app_role.dart';

/// Local mock for Auth & User Gateway paths.
///
/// Demo emails (password: `password`):
/// - user@darkstore.com → USER
/// - admin@darkstore.com → ADMIN
/// - manager@darkstore.com → MANAGER (store s_001)
/// - rider@darkstore.com → RIDER (store s_001)
/// - inactive@darkstore.com → USER but active: false
class AuthApiMock {
  static final AuthApiMock instance = AuthApiMock._();

  AuthApiMock._() {
    _users.addAll(_seedUsers);
  }

  factory AuthApiMock() => instance;

  static const _seedUsers = <String, Map<String, dynamic>>{
    'user@darkstore.com': {
      'id': 'u_001',
      'email': 'user@darkstore.com',
      'name': 'Asha Customer',
      'phone': '9000000001',
      'role': 'USER',
      'storeId': null,
      'active': true,
    },
    'admin@darkstore.com': {
      'id': 'u_002',
      'email': 'admin@darkstore.com',
      'name': 'Platform Admin',
      'phone': '9000000002',
      'role': 'ADMIN',
      'storeId': null,
      'active': true,
    },
    'manager@darkstore.com': {
      'id': 'u_010',
      'email': 'manager@darkstore.com',
      'name': 'Store Manager',
      'phone': '9000000010',
      'role': 'MANAGER',
      'storeId': 's_001',
      'active': true,
    },
    'rider@darkstore.com': {
      'id': 'u_020',
      'email': 'rider@darkstore.com',
      'name': 'Delivery Rider',
      'phone': '9000000020',
      'role': 'RIDER',
      'storeId': 's_001',
      'active': true,
    },
    'inactive@darkstore.com': {
      'id': 'u_099',
      'email': 'inactive@darkstore.com',
      'name': 'Inactive User',
      'phone': '9000000099',
      'role': 'USER',
      'storeId': null,
      'active': false,
    },
  };

  final Map<String, Map<String, dynamic>> _users = {};
  final Map<String, String> _passwords = {
    for (final email in _seedUsers.keys) email: 'password',
  };
  final Map<String, List<Map<String, dynamic>>> _addresses = {
    'u_001': [
      {
        'id': 'addr_001',
        'label': 'Home',
        'line1': '12 MG Road',
        'line2': 'Near Metro',
        'city': 'Bengaluru',
        'state': 'KA',
        'postalCode': '560001',
        'defaultAddress': true,
      },
      {
        'id': 'addr_002',
        'label': 'Office',
        'line1': '42 Indiranagar 100 Feet Rd',
        'line2': '',
        'city': 'Bengaluru',
        'state': 'KA',
        'postalCode': '560038',
        'defaultAddress': false,
      },
    ],
  };

  Map<String, dynamic>? _currentUser;

  Map<String, dynamic> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty || name.trim().isEmpty) {
      throw Exception('Name, email, and password are required');
    }
    if (_users.containsKey(normalized)) {
      throw Exception('Email is already registered');
    }

    final user = <String, dynamic>{
      'id': 'u_${DateTime.now().millisecondsSinceEpoch}',
      'email': normalized,
      'name': name.trim(),
      'phone': phone?.trim(),
      'role': 'USER',
      'storeId': null,
      'active': true,
    };

    _users[normalized] = user;
    _passwords[normalized] = password;
    _currentUser = Map<String, dynamic>.from(user);

    return _sessionPayload(user);
  }

  Map<String, dynamic> login({
    required String email,
    required String password,
  }) {
    final normalized = email.trim().toLowerCase();
    final user = _users[normalized];
    final expected = _passwords[normalized];

    if (user == null || expected == null || password != expected) {
      throw Exception('Invalid email or password');
    }
    if (user['active'] != true) {
      throw Exception('Account is deactivated');
    }

    _currentUser = Map<String, dynamic>.from(user);
    return _sessionPayload(user);
  }

  Map<String, dynamic> refresh({
    String? authorizationHeader,
    String? refreshToken,
  }) {
    final user = _resolveUser(
      authorizationHeader: authorizationHeader,
      refreshToken: refreshToken,
    );
    if (user == null) {
      throw Exception('Invalid refresh token');
    }
    if (user['active'] != true) {
      throw Exception('Account is deactivated');
    }

    _currentUser = Map<String, dynamic>.from(user);
    return _sessionPayload(user, refreshed: true);
  }

  Map<String, dynamic> me({String? authorizationHeader}) {
    final user = _resolveUser(authorizationHeader: authorizationHeader) ??
        _currentUser;
    if (user == null) {
      throw Exception('Unauthorized');
    }
    return Map<String, dynamic>.from(user);
  }

  List<Map<String, dynamic>> listUsersForAdmin() {
    return _users.values
        .map((u) => Map<String, dynamic>.from(u))
        .toList()
      ..sort((a, b) => (a['email'] as String).compareTo(b['email'] as String));
  }

  List<Map<String, dynamic>> listRidersForStore(String storeId) {
    return _users.values
        .where(
          (u) =>
              u['role'] == 'RIDER' &&
              u['storeId'] == storeId &&
              u['active'] == true,
        )
        .map((u) => Map<String, dynamic>.from(u))
        .toList();
  }

  Map<String, dynamic> createStaffUser({
    required String email,
    required String password,
    required String name,
    required AppRole role,
    required String storeId,
    String? phone,
  }) {
    if (role != AppRole.manager && role != AppRole.rider) {
      throw Exception('Only MANAGER or RIDER can be created by admin');
    }
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty || name.trim().isEmpty) {
      throw Exception('Name, email, and password are required');
    }
    if (_users.containsKey(normalized)) {
      throw Exception('Email is already registered');
    }

    final user = <String, dynamic>{
      'id': 'u_${DateTime.now().millisecondsSinceEpoch}',
      'email': normalized,
      'name': name.trim(),
      'phone': phone?.trim(),
      'role': role.apiValue,
      'storeId': storeId,
      'active': true,
    };
    _users[normalized] = user;
    _passwords[normalized] = password;
    return Map<String, dynamic>.from(user);
  }

  Map<String, dynamic> setUserActive({
    required String userId,
    required bool active,
  }) {
    final entry = _users.entries.where((e) => e.value['id'] == userId);
    if (entry.isEmpty) {
      throw Exception('User not found');
    }
    final user = entry.first.value;
    if (user['role'] == 'ADMIN' && !active) {
      throw Exception('Cannot deactivate the platform admin account');
    }
    user['active'] = active;
    if (!active && _currentUser?['id'] == userId) {
      _currentUser = null;
    }
    return Map<String, dynamic>.from(user);
  }

  Map<String, dynamic> listAddresses({String? authorizationHeader}) {
    final user = me(authorizationHeader: authorizationHeader);
    final userId = user['id'] as String;
    final items = (_addresses[userId] ?? [])
        .map((a) => Map<String, dynamic>.from(a))
        .toList();
    return {'items': items};
  }

  Map<String, dynamic> addAddress({
    required Map<String, dynamic> body,
    String? authorizationHeader,
  }) {
    final user = me(authorizationHeader: authorizationHeader);
    final userId = user['id'] as String;
    final list = _addresses.putIfAbsent(userId, () => []);
    final address = <String, dynamic>{
      'id': 'addr_${DateTime.now().millisecondsSinceEpoch}',
      'label': body['label'] ?? 'Home',
      'line1': body['line1'] ?? '',
      'line2': body['line2'] ?? '',
      'city': body['city'] ?? '',
      'state': body['state'] ?? '',
      'postalCode': body['postalCode'] ?? body['postal_code'] ?? '',
      'defaultAddress': body['defaultAddress'] == true || list.isEmpty,
    };
    if (address['line1'].toString().trim().isEmpty ||
        address['city'].toString().trim().isEmpty) {
      throw Exception('Address line1 and city are required');
    }
    if (address['defaultAddress'] == true) {
      for (final existing in list) {
        existing['defaultAddress'] = false;
      }
    }
    list.add(address);
    return Map<String, dynamic>.from(address);
  }

  Map<String, dynamic> updateAddress({
    required String addressId,
    required Map<String, dynamic> body,
    String? authorizationHeader,
  }) {
    final user = me(authorizationHeader: authorizationHeader);
    final userId = user['id'] as String;
    final list = _addresses.putIfAbsent(userId, () => []);
    final index = list.indexWhere((a) => a['id'] == addressId);
    if (index < 0) {
      throw Exception('Address not found');
    }
    final existing = list[index];
    final updated = <String, dynamic>{
      ...existing,
      'label': body['label'] ?? existing['label'],
      'line1': body['line1'] ?? existing['line1'],
      'line2': body['line2'] ?? existing['line2'],
      'city': body['city'] ?? existing['city'],
      'state': body['state'] ?? existing['state'],
      'postalCode':
          body['postalCode'] ?? body['postal_code'] ?? existing['postalCode'],
      'defaultAddress': body.containsKey('defaultAddress')
          ? body['defaultAddress'] == true
          : body.containsKey('default_address')
              ? body['default_address'] == true
              : existing['defaultAddress'] == true,
    };
    if (updated['line1'].toString().trim().isEmpty ||
        updated['city'].toString().trim().isEmpty) {
      throw Exception('Address line1 and city are required');
    }
    if (updated['defaultAddress'] == true) {
      for (final item in list) {
        item['defaultAddress'] = item['id'] == addressId;
      }
    }
    list[index] = updated;
    return Map<String, dynamic>.from(updated);
  }

  void clear() => _currentUser = null;

  /// Test helper: restore seed users and clear session.
  void resetForTests() {
    _currentUser = null;
    _users
      ..clear()
      ..addAll(
        _seedUsers.map(
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
        ),
      );
    _passwords
      ..clear()
      ..addAll({for (final email in _seedUsers.keys) email: 'password'});
    _addresses
      ..clear()
      ..addAll({
        'u_001': [
          {
            'id': 'addr_001',
            'label': 'Home',
            'line1': '12 MG Road',
            'line2': 'Near Metro',
            'city': 'Bengaluru',
            'state': 'KA',
            'postalCode': '560001',
            'defaultAddress': true,
          },
          {
            'id': 'addr_002',
            'label': 'Office',
            'line1': '42 Indiranagar 100 Feet Rd',
            'line2': '',
            'city': 'Bengaluru',
            'state': 'KA',
            'postalCode': '560038',
            'defaultAddress': false,
          },
        ],
      });
  }

  Map<String, dynamic> _sessionPayload(
    Map<String, dynamic> user, {
    bool refreshed = false,
  }) {
    final role = AppRole.fromApi(user['role'] as String);
    final id = user['id'] as String;
    final suffix = refreshed ? '-refreshed' : '';
    return {
      'accessToken': 'mock-access|${role.name}|$id$suffix',
      'refreshToken': 'mock-refresh|${role.name}|$id',
      'expiresIn': 900,
      'user': Map<String, dynamic>.from(user),
    };
  }

  Map<String, dynamic>? _resolveUser({
    String? authorizationHeader,
    String? refreshToken,
  }) {
    if (_currentUser != null) {
      return Map<String, dynamic>.from(_currentUser!);
    }

    final token = refreshToken ??
        authorizationHeader?.replaceFirst(RegExp(r'^Bearer\s+'), '');
    if (token == null || token.isEmpty) return null;

    final parts = token.split('|');
    if (parts.length >= 3) {
      final userId = parts[2].replaceAll('-refreshed', '');
      for (final user in _users.values) {
        if (user['id'] == userId) {
          return Map<String, dynamic>.from(user);
        }
      }
    }

    // Backward-compatible: older mock tokens contained role name only.
    for (final user in _users.values) {
      final roleName = (user['role'] as String).toLowerCase();
      if (token.toLowerCase().contains(roleName)) {
        return Map<String, dynamic>.from(user);
      }
    }
    return null;
  }

  static List<Map<String, String>> get demoAccounts => [
        {'email': 'user@darkstore.com', 'role': 'USER'},
        {'email': 'admin@darkstore.com', 'role': 'ADMIN'},
        {'email': 'manager@darkstore.com', 'role': 'MANAGER'},
        {'email': 'rider@darkstore.com', 'role': 'RIDER'},
        {'email': 'inactive@darkstore.com', 'role': 'USER (inactive)'},
      ];
}
