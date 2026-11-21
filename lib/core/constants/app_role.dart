enum AppRole {
  user,
  admin,
  manager,
  rider;

  String get apiValue => name.toUpperCase();

  static AppRole fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'USER':
        return AppRole.user;
      case 'ADMIN':
        return AppRole.admin;
      case 'MANAGER':
        return AppRole.manager;
      case 'RIDER':
        return AppRole.rider;
      default:
        throw ArgumentError('Unknown role: $value');
    }
  }

  String get homePath {
    switch (this) {
      case AppRole.user:
        return '/user';
      case AppRole.admin:
        return '/admin';
      case AppRole.manager:
        return '/manager';
      case AppRole.rider:
        return '/rider';
    }
  }

  String get label {
    switch (this) {
      case AppRole.user:
        return 'Customer';
      case AppRole.admin:
        return 'Admin';
      case AppRole.manager:
        return 'Manager';
      case AppRole.rider:
        return 'Rider';
    }
  }
}
