import 'package:darkstore/placeholders/auth_api_mock.dart';
import 'package:darkstore/placeholders/order_api_mock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late OrderApiMock orders;
  late AuthApiMock auth;

  setUp(() {
    orders = OrderApiMock()..resetForTests();
    auth = AuthApiMock()..resetForTests();
    auth.login(email: 'user@darkstore.com', password: 'password');
  });

  test('empty cart blocks place order', () {
    expect(
      () => orders.placeOrder(
        addressId: 'addr_001',
        addressSnapshot: const {
          'line1': '12 MG Road',
          'city': 'Bengaluru',
          'postalCode': '560001',
        },
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('cart CRUD and checkout create CONFIRMED order', () {
    orders.addCartItem(productId: 'p_100', quantity: 2, storeId: '1');
    final cart = orders.cart();
    expect((cart['items'] as List).length, 1);
    expect(cart['subtotal'], 110.0);

    orders.updateCartItem(
      itemId: (cart['items'] as List).first['id'] as String,
      quantity: 1,
    );
    expect(orders.cart()['subtotal'], 55.0);

    final addresses = auth.listAddresses();
    final address = addresses.first;

    final order = orders.placeOrder(
      addressId: '${address['id']}',
      addressSnapshot: address,
      paymentMethod: 'COD',
      user: auth.me(),
    );

    expect(order['status'], 'CONFIRMED');
    expect(
      (order['statusHistory'] as List).map((e) => e['toStatus']),
      containsAll(['CREATED', 'CONFIRMED']),
    );
    expect((orders.cart()['items'] as List), isEmpty);

    final loaded = orders.orderById(order['id'] as String);
    expect(loaded['orderNumber'], order['orderNumber']);
  });

  test('out of stock cannot be added', () {
    expect(
      () => orders.addCartItem(
        productId: 'p_102',
        quantity: 1,
        storeId: '1',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
