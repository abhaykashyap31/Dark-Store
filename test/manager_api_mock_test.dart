import 'package:darkstore/core/constants/order_status.dart';
import 'package:darkstore/placeholders/auth_api_mock.dart';
import 'package:darkstore/placeholders/catalog_api_mock.dart';
import 'package:darkstore/placeholders/order_api_mock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late OrderApiMock orders;
  late CatalogApiMock catalog;
  late AuthApiMock auth;

  setUp(() {
    orders = OrderApiMock()..resetForTests();
    catalog = CatalogApiMock();
    auth = AuthApiMock()..resetForTests();
  });

  test('manager queue is scoped by storeId', () {
    final s1 = orders.managerOrders(storeId: 's_001');
    expect((s1['items'] as List), isNotEmpty);

    final s2 = orders.managerOrders(storeId: 's_002');
    expect((s2['items'] as List), isEmpty);
  });

  test('manager status transitions and assign rider', () {
    final picking = orders.patchManagerStatus(
      orderId: 'o_500',
      toStatus: OrderStatus.picking,
      storeId: 's_001',
    );
    expect(picking['status'], OrderStatus.picking);

    final packed = orders.patchManagerStatus(
      orderId: 'o_500',
      toStatus: OrderStatus.packed,
      storeId: 's_001',
    );
    expect(packed['status'], OrderStatus.packed);

    expect(
      () => orders.patchManagerStatus(
        orderId: 'o_500',
        toStatus: OrderStatus.delivered,
        storeId: 's_001',
      ),
      throwsA(isA<Exception>()),
    );

    final rider = auth.listRidersForStore('s_001').first;
    final assigned = orders.assignRider(
      orderId: 'o_500',
      storeId: 's_001',
      riderId: rider['id'] as String,
      riderName: rider['name'] as String,
    );
    expect(assigned['status'], OrderStatus.assigned);
    expect(assigned['assignedRiderId'], rider['id']);
  });

  test('inventory update is store-scoped and drives alerts', () {
    catalog.updateInventory(
      storeId: 's_001',
      productId: 'p_100',
      stockQty: 2,
      price: 60,
    );
    final alerts = catalog.inventoryAlerts(storeId: 's_001');
    final items = (alerts['items'] as List).cast<Map<String, dynamic>>();
    expect(items.any((i) => i['productId'] == 'p_100'), isTrue);
  });
}
