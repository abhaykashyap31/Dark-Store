import '../core/constants/app_role.dart';
import 'mock_ids.dart';

/// Local mock for Auth & User Gateway paths (API_REFERENCE.md shapes).
///
/// Demo accounts:
/// - user@darkstore.com / password → CUSTOMER
/// - admin@darkstore.com / Admin@123 → ADMIN
/// - manager@darkstore.com / password → MANAGER (Koramangala store)
/// - rider@darkstore.com / password → RIDER (Koramangala store)
/// - inactive@darkstore.com / password → CUSTOMER DISABLED
class AuthApiMock {
  static final AuthApiMock instance = AuthApiMock._();

  AuthApiMock._() {
    _users.addAll(
      _seedUsers.map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
      ),
    );
  }

  factory AuthApiMock() => instance;

  static const _seedUsers = <String, Map<String, dynamic>>{
    'user@darkstore.com': {
      'id': MockIds.userCustomer,
      'email': 'user@darkstore.com',
      'fullName': 'Asha Customer',
      'phone': '9000000001',
      'role': 'CUSTOMER',
      'storeId': null,
      'status': 'ACTIVE',
    },
    'admin@darkstore.com': {
      'id': MockIds.userAdmin,
      'email': 'admin@darkstore.com',
      'fullName': 'Platform Admin',
      'phone': '9000000002',
      'role': 'ADMIN',
      'storeId': null,
      'status': 'ACTIVE',
    },
    'manager@darkstore.com': {
      'id': MockIds.userManager,
      'email': 'manager@darkstore.com',
      'fullName': 'Store Manager',
      'phone': '9000000010',
      'role': 'MANAGER',
      'storeId': MockIds.defaultStore,
      'status': 'ACTIVE',
    },
    'rider@darkstore.com': {
      'id': MockIds.userRider,
      'email': 'rider@darkstore.com',
      'fullName': 'Delivery Rider',
      'phone': '9000000020',
      'role': 'RIDER',
      'storeId': MockIds.defaultStore,
      'status': 'ACTIVE',
    },
    'inactive@darkstore.com': {
      'id': MockIds.userInactive,
      'email': 'inactive@darkstore.com',
      'fullName': 'Inactive User',
      'phone': '9000000099',
      'role': 'CUSTOMER',
      'storeId': null,
      'status': 'DISABLED',
    },
  };

  final Map<String, Map<String, dynamic>> _users = {};
  final Map<String, String> _passwords = {
    'user@darkstore.com': 'password',
    'admin@darkstore.com': 'Admin@123',
    'manager@darkstore.com': 'password',
    'rider@darkstore.com': 'password',
    'inactive@darkstore.com': 'password',
  };
  final Map<String, List<Map<String, dynamic>>> _addresses = {
    MockIds.userCustomer: [
      {
        'id': MockIds.addressHome,
        'label': 'Home',
        'line1': '12 MG Road',
        'line2': 'Near Metro',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'postalCode': '560001',
        'country': 'India',
        'defaultAddress': true,
      },
      {
        'id': MockIds.addressOffice,
        'label': 'Office',
        'line1': '42 Indiranagar 100 Feet Rd',
        'line2': '',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'postalCode': '560038',
        'country': 'India',
        'defaultAddress': false,
      },
    ],
  };

  Map<String, dynamic>? _currentUser;
  int _userSeq = 100;
  int _addressSeq = 10;

  String _nextUserId() =>
      '00000000-0000-4000-8000-${(_userSeq++).toString().padLeft(12, '0')}';

  String _nextAddressId() =>
      '00000000-0000-4000-a000-${(_addressSeq++).toString().padLeft(12, '0')}';

  /// Register returns a User only (no tokens). Mock accepts optional [role]
  /// so the Register tab can open Admin / Manager / Rider UIs; live Gateway
  /// still creates CUSTOMER only.
  Map<String, dynamic> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? role,
  }) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty || name.trim().isEmpty) {
      throw Exception('fullName, email, and password are required');
    }
    if (name.trim().length > 100) {
      throw Exception('fullName size must be between 1 and 100');
    }
    if (password.length < 8 || password.length > 72) {
      throw Exception('password size must be between 8 and 72');
    }
    if (_users.containsKey(normalized)) {
      throw Exception('Email is already registered');
    }

    final parsed = AppRole.fromApi((role ?? 'CUSTOMER').trim());
    final needsStore =
        parsed == AppRole.manager || parsed == AppRole.rider;

    final user = <String, dynamic>{
      'id': _nextUserId(),
      'email': normalized,
      'fullName': name.trim(),
      'phone': phone?.trim(),
      'role': parsed.apiValue,
      'storeId': needsStore ? MockIds.defaultStore : null,
      'status': 'ACTIVE',
    };

    _users[normalized] = user;
    _passwords[normalized] = password;
    return Map<String, dynamic>.from(user);
  }

  Map<String, dynamic> login({
    required String email,
    required String password,
  }) {
    final normalized = email.trim().toLowerCase();
    final user = _users[normalized];
    final expected = _passwords[normalized];

    if (user == null || expected == null || password != expected) {
      throw _coded('INVALID_CREDENTIALS', 'Invalid email or password');
    }
    if (user['status'] == 'DISABLED' || user['active'] == false) {
      throw _coded('ACCOUNT_DISABLED', 'Account is deactivated');
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
      throw _coded('TOKEN_INVALID', 'Invalid refresh token');
    }
    if (user['status'] == 'DISABLED') {
      throw _coded('ACCOUNT_DISABLED', 'Account is deactivated');
    }

    _currentUser = Map<String, dynamic>.from(user);
    return _sessionPayload(user, refreshed: true);
  }

  Map<String, dynamic> me({String? authorizationHeader}) {
    final user = _resolveUser(authorizationHeader: authorizationHeader) ??
        _currentUser;
    if (user == null) {
      throw _coded('TOKEN_INVALID', 'Unauthorized');
    }
    return Map<String, dynamic>.from(user);
  }

  Map<String, dynamic> updateMe({
    required Map<String, dynamic> body,
    String? authorizationHeader,
  }) {
    final user = me(authorizationHeader: authorizationHeader);
    final email = user['email'] as String;
    final name =
        '${body['fullName'] ?? body['name'] ?? ''}'.trim();
    if (name.isEmpty) {
      throw Exception('fullName is required');
    }
    user['fullName'] = name;
    // Omitting phone or null clears it (API_REFERENCE).
    if (!body.containsKey('phone') || body['phone'] == null) {
      user['phone'] = null;
    } else {
      user['phone'] = body['phone'].toString();
    }
    _users[email] = user;
    _currentUser = Map<String, dynamic>.from(user);
    return Map<String, dynamic>.from(user);
  }

  List<Map<String, dynamic>> listUsersForAdmin({String? role}) {
    var list = _users.values.map((u) => Map<String, dynamic>.from(u)).toList();
    if (role != null && role.trim().isNotEmpty) {
      final r = role.trim().toUpperCase();
      list = list.where((u) => u['role'] == r).toList();
    }
    list.sort((a, b) =>
        (a['email'] as String).compareTo(b['email'] as String));
    return list;
  }

  List<Map<String, dynamic>> listRidersForStore(Object storeId) {
    final sid = storeId.toString();
    return _users.values
        .where(
          (u) =>
              u['role'] == 'RIDER' &&
              '${u['storeId']}' == sid &&
              u['status'] == 'ACTIVE',
        )
        .map((u) => Map<String, dynamic>.from(u))
        .toList();
  }

  Map<String, dynamic> createStaffUser({
    required String email,
    required String password,
    required String name,
    required String role,
    required Object storeId,
    String? phone,
  }) {
    final normalized = email.trim().toLowerCase();
    final roleValue = role.trim().toUpperCase();
    if (roleValue != 'MANAGER' && roleValue != 'RIDER') {
      throw Exception('role must be MANAGER or RIDER');
    }
    if (normalized.isEmpty || password.isEmpty || name.trim().isEmpty) {
      throw Exception('fullName, email, and password are required');
    }
    if (_users.containsKey(normalized)) {
      throw Exception('Email is already registered');
    }

    final user = <String, dynamic>{
      'id': _nextUserId(),
      'email': normalized,
      'fullName': name.trim(),
      'phone': phone?.trim(),
      'role': roleValue,
      'storeId': storeId.toString(),
      'status': 'ACTIVE',
    };
    _users[normalized] = user;
    _passwords[normalized] = password;
    return Map<String, dynamic>.from(user);
  }

  Map<String, dynamic> setUserStatus({
    required String userId,
    required String status,
    String? actorUserId,
  }) {
    final target = _users.values
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (u) => '${u!['id']}' == userId,
          orElse: () => null,
        );
    if (target == null) {
      throw Exception('User not found');
    }
    if (actorUserId != null && '${target['id']}' == actorUserId) {
      throw Exception('An admin cannot change their own status');
    }
    final next = status.toUpperCase();
    if (next != 'ACTIVE' && next != 'DISABLED') {
      throw Exception('status must be ACTIVE or DISABLED');
    }
    target['status'] = next;
    if (_currentUser != null && '${_currentUser!['id']}' == userId) {
      _currentUser = Map<String, dynamic>.from(target);
    }
    return Map<String, dynamic>.from(target);
  }

  /// Legacy helper used by older mocks.
  Map<String, dynamic> setUserActive({
    required String userId,
    required bool active,
  }) {
    return setUserStatus(
      userId: userId,
      status: active ? 'ACTIVE' : 'DISABLED',
    );
  }

  List<Map<String, dynamic>> listAddresses({String? authorizationHeader}) {
    final user = me(authorizationHeader: authorizationHeader);
    final userId = '${user['id']}';
    return (_addresses[userId] ?? [])
        .map((a) => Map<String, dynamic>.from(a))
        .toList();
  }

  Map<String, dynamic> addAddress({
    required Map<String, dynamic> body,
    String? authorizationHeader,
  }) {
    final user = me(authorizationHeader: authorizationHeader);
    final userId = '${user['id']}';
    final list = _addresses.putIfAbsent(userId, () => []);
    final makeDefault =
        body['defaultAddress'] == true || body['isDefault'] == true || list.isEmpty;
    final address = <String, dynamic>{
      'id': _nextAddressId(),
      'label': body['label'] ?? 'Home',
      'line1': body['line1'] ?? '',
      'line2': body['line2'] ?? '',
      'city': body['city'] ?? '',
      'state': body['state'] ?? '',
      'postalCode':
          body['postalCode'] ?? body['postal_code'] ?? body['pincode'] ?? '',
      'country': body['country'] ?? 'India',
      'defaultAddress': makeDefault,
    };
    if (address['line1'].toString().trim().isEmpty ||
        address['city'].toString().trim().isEmpty ||
        address['postalCode'].toString().trim().isEmpty) {
      throw Exception('Address line1, city and postalCode are required');
    }
    if (makeDefault) {
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
    final userId = '${user['id']}';
    final list = _addresses.putIfAbsent(userId, () => []);
    final index = list.indexWhere((a) => '${a['id']}' == addressId);
    if (index < 0) {
      throw Exception('Address not found');
    }
    final existing = list[index];
    final wantDefault = body.containsKey('defaultAddress')
        ? body['defaultAddress'] == true
        : body.containsKey('isDefault')
            ? body['isDefault'] == true
            : existing['defaultAddress'] == true;
    final updated = <String, dynamic>{
      ...existing,
      'label': body['label'] ?? existing['label'],
      'line1': body['line1'] ?? existing['line1'],
      'line2': body['line2'] ?? existing['line2'],
      'city': body['city'] ?? existing['city'],
      'state': body['state'] ?? existing['state'],
      'postalCode': body['postalCode'] ??
          body['postal_code'] ??
          body['pincode'] ??
          existing['postalCode'],
      'country': body['country'] ?? existing['country'] ?? 'India',
      'defaultAddress': wantDefault,
    };
    if (updated['line1'].toString().trim().isEmpty ||
        updated['city'].toString().trim().isEmpty ||
        updated['postalCode'].toString().trim().isEmpty) {
      throw Exception('Address line1, city and postalCode are required');
    }
    if (wantDefault) {
      for (final item in list) {
        item['defaultAddress'] = '${item['id']}' == addressId;
      }
    }
    list[index] = updated;
    return Map<String, dynamic>.from(updated);
  }

  void deleteAddress({
    required String addressId,
    String? authorizationHeader,
  }) {
    final user = me(authorizationHeader: authorizationHeader);
    final userId = '${user['id']}';
    final list = _addresses[userId];
    if (list == null) throw Exception('Address not found');
    final before = list.length;
    list.removeWhere((a) => '${a['id']}' == addressId);
    if (list.length == before) throw Exception('Address not found');
  }

  void clear() => _currentUser = null;

  void resetForTests() {
    _currentUser = null;
    _userSeq = 100;
    _addressSeq = 10;
    _users
      ..clear()
      ..addAll(
        _seedUsers.map(
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
        ),
      );
    _passwords
      ..clear()
      ..addAll({
        'user@darkstore.com': 'password',
        'admin@darkstore.com': 'Admin@123',
        'manager@darkstore.com': 'password',
        'rider@darkstore.com': 'password',
        'inactive@darkstore.com': 'password',
      });
    _addresses
      ..clear()
      ..addAll({
        MockIds.userCustomer: [
          {
            'id': MockIds.addressHome,
            'label': 'Home',
            'line1': '12 MG Road',
            'line2': 'Near Metro',
            'city': 'Bengaluru',
            'state': 'Karnataka',
            'postalCode': '560001',
            'country': 'India',
            'defaultAddress': true,
          },
        ],
      });
  }

  Map<String, dynamic> _sessionPayload(
    Map<String, dynamic> user, {
    bool refreshed = false,
  }) {
    final role = AppRole.fromApi(user['role'] as String);
    final id = '${user['id']}';
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
        if ('${user['id']}' == userId) {
          return Map<String, dynamic>.from(user);
        }
      }
    }

    for (final user in _users.values) {
      final roleName = (user['role'] as String).toLowerCase();
      if (token.toLowerCase().contains(roleName) ||
          (roleName == 'customer' && token.toLowerCase().contains('user'))) {
        return Map<String, dynamic>.from(user);
      }
    }
    return null;
  }

  Exception _coded(String code, String message) =>
      Exception('$code::$message');

  static List<Map<String, String>> get demoAccounts => [
        {'email': 'user@darkstore.com', 'role': 'CUSTOMER', 'password': 'password'},
        {
          'email': 'admin@darkstore.com',
          'role': 'ADMIN',
          'password': 'Admin@123',
        },
        {
          'email': 'manager@darkstore.com',
          'role': 'MANAGER',
          'password': 'password',
        },
        {'email': 'rider@darkstore.com', 'role': 'RIDER', 'password': 'password'},
        {
          'email': 'inactive@darkstore.com',
          'role': 'CUSTOMER (disabled)',
          'password': 'password',
        },
      ];
}
