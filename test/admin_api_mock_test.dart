import 'package:darkstore/placeholders/admin_api_mock.dart';
import 'package:darkstore/placeholders/auth_api_mock.dart';
import 'package:darkstore/placeholders/mock_ids.dart';
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
        'fullName': 'No Store Manager',
        'email': 'nostore@darkstore.com',
        'password': 'password',
        'role': 'MANAGER',
      }),
      throwsA(isA<Exception>()),
    );

    final created = admin.createUser({
      'fullName': 'New Manager',
      'email': 'new.manager@darkstore.com',
      'password': 'password',
      'role': 'MANAGER',
      'storeId': MockIds.defaultStore,
    });
    expect(created['role'], 'MANAGER');
    expect('${created['storeId']}', MockIds.defaultStore);
    expect(created['fullName'], 'New Manager');
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
      'line1': 'ITPL Main Road',
      'city': 'Bengaluru',
      'state': 'Karnataka',
      'postalCode': '560066',
      'phone': '0804000099',
    });
    expect(store['active'], isTrue);
    expect(store['line1'], 'ITPL Main Road');
    expect(store['postalCode'], '560066');

    final product = admin.createProduct({
      'name': 'Butter 100g',
      'sku': 'BTR-100',
      'categoryId': 'c_01',
      'basePrice': 55,
    });
    expect(product['sku'], 'BTR-100');
  });
}
