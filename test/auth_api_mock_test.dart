import 'package:darkstore/core/constants/app_role.dart';
import 'package:darkstore/placeholders/auth_api_mock.dart';
import 'package:darkstore/shared/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuthApiMock auth;

  setUp(() {
    auth = AuthApiMock();
    auth.resetForTests();
  });

  test('customer login returns CUSTOMER session', () {
    final session = AuthSession.fromJson(
      auth.login(email: 'user@darkstore.com', password: 'password'),
    );
    expect(session.user.role, AppRole.user);
    expect(session.user.role.apiValue, 'CUSTOMER');
    expect(session.expiresIn, 900);
  });

  test('admin demo uses Admin@123', () {
    final session = AuthSession.fromJson(
      auth.login(email: 'admin@darkstore.com', password: 'Admin@123'),
    );
    expect(session.user.role, AppRole.admin);
  });

  test('manager and rider carry integer storeId', () {
    final manager = AuthSession.fromJson(
      auth.login(email: 'manager@darkstore.com', password: 'password'),
    ).user;
    expect(manager.role, AppRole.manager);
    expect(manager.storeId, '1');

    final rider = AuthSession.fromJson(
      auth.login(email: 'rider@darkstore.com', password: 'password'),
    ).user;
    expect(rider.role, AppRole.rider);
    expect(rider.storeId, '1');
  });

  test('disabled account cannot login', () {
    expect(
      () => auth.login(email: 'inactive@darkstore.com', password: 'password'),
      throwsA(isA<Exception>()),
    );
  });

  test('register returns User only then login works', () {
    final user = AppUser.fromJson(
      auth.register(
        email: 'new.customer@example.com',
        password: 'Secret@12',
        name: 'New Customer',
        phone: '9111111111',
      ),
    );

    expect(user.role, AppRole.user);
    expect(user.storeId, isNull);
    expect(user.status, 'ACTIVE');

    final session = AuthSession.fromJson(
      auth.login(email: 'new.customer@example.com', password: 'Secret@12'),
    );
    expect(session.user.email, 'new.customer@example.com');
  });

  test('admin can create MANAGER with storeId', () {
    final created = AppUser.fromJson(
      auth.createStaffUser(
        email: 'new.manager@example.com',
        password: 'Manager@12',
        name: 'New Manager',
        role: 'MANAGER',
        storeId: 1,
      ),
    );
    expect(created.role, AppRole.manager);
    expect(created.storeId, '1');
  });
}
