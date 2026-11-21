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

  test('login routes each role with storeId where required', () {
    final user = AuthSession.fromJson(
      auth.login(email: 'user@darkstore.com', password: 'password'),
    ).user;
    expect(user.role, AppRole.user);
    expect(user.storeId, isNull);

    final admin = AuthSession.fromJson(
      auth.login(email: 'admin@darkstore.com', password: 'password'),
    ).user;
    expect(admin.role, AppRole.admin);
    expect(admin.storeId, isNull);

    final manager = AuthSession.fromJson(
      auth.login(email: 'manager@darkstore.com', password: 'password'),
    ).user;
    expect(manager.role, AppRole.manager);
    expect(manager.storeId, 's_001');

    final rider = AuthSession.fromJson(
      auth.login(email: 'rider@darkstore.com', password: 'password'),
    ).user;
    expect(rider.role, AppRole.rider);
    expect(rider.storeId, 's_001');
  });

  test('inactive account cannot login', () {
    expect(
      () => auth.login(email: 'inactive@darkstore.com', password: 'password'),
      throwsA(isA<Exception>()),
    );
  });

  test('register creates USER only and returns session', () {
    final session = AuthSession.fromJson(
      auth.register(
        email: 'new.customer@example.com',
        password: 'secret12',
        name: 'New Customer',
        phone: '9111111111',
      ),
    );

    expect(session.user.role, AppRole.user);
    expect(session.user.storeId, isNull);
    expect(session.accessToken, contains('user'));
    expect(session.user.active, isTrue);

    final me = AppUser.fromJson(auth.me());
    expect(me.email, 'new.customer@example.com');
  });
}
