import 'package:darkstore/placeholders/admin_api_mock.dart';
import 'package:darkstore/placeholders/auth_api_mock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AdminApiMock admin;
  late AuthApiMock auth;

  setUp(() {
    admin = AdminApiMock()..resetForTests();
    auth = AuthApiMock()..resetForTests();
  });

  test('creating MANAGER/RIDER requires storeId', () {
    expect(
      () => admin.createUser({
        'name': 'No Store Manager',
        'email': 'nostore@darkstore.com',
        'password': 'password',
        'role': 'MANAGER',
      }),
      throwsA(isA<Exception>()),
    );

    final created = admin.createUser({
      'name': 'New Manager',
      'email': 'new.manager@darkstore.com',
      'password': 'password',
      'role': 'MANAGER',
      'storeId': '1',
    });
    expect(created['role'], 'MANAGER');
    expect('${created['storeId']}', '1');
  });

  test('deactivated user cannot login', () {
    final user = auth.login(
      email: 'manager@darkstore.com',
      password: 'password',
    )['user'] as Map<String, dynamic>;
    auth.clear();

    admin.setUserActive('${user['id']}', false);

    expect(
      () => auth.login(
        email: 'manager@darkstore.com',
        password: 'password',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('admin can create store and product', () {
    final store = admin.createStore({
      'name': 'Whitefield Darkstore',
      'code': 'BLR-WFD',
      'city': 'Bengaluru',
    });
    expect(store['active'], isTrue);

    final product = admin.createProduct({
      'name': 'Butter 100g',
      'sku': 'BTR-100',
      'categoryId': 'c_01',
      'basePrice': 55,
    });
    expect(product['sku'], 'BTR-100');
  });
}
