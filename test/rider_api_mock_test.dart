import 'package:darkstore/core/constants/order_status.dart';
import 'package:darkstore/placeholders/mock_ids.dart';
import 'package:darkstore/placeholders/order_api_mock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late OrderApiMock orders;

  setUp(() {
    orders = OrderApiMock()..resetForTests();
  });

  test('rider only sees orders assigned to them for their store', () {
    final mine = orders.riderOrders(
      storeId: MockIds.defaultStore,
      riderId: MockIds.userRider,
    );
    final items = (mine['items'] as List).cast<Map<String, dynamic>>();
    expect(items, isNotEmpty);
    expect(
      items.every((o) => o['assignedRiderId'] == MockIds.userRider),
      isTrue,
    );
    expect(
      items.every(
        (o) =>
            o['status'] == OrderStatus.assigned ||
            o['status'] == OrderStatus.outForDelivery,
      ),
      isTrue,
    );

    final other = orders.riderOrders(
      storeId: MockIds.defaultStore,
      riderId: '999',
    );
    expect((other['items'] as List), isEmpty);
  });

  test('missing storeId fails clearly', () {
    expect(
      () => orders.riderOrders(storeId: '', riderId: MockIds.userRider),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('storeId'),
        ),
      ),
    );
  });

  test('rider status transitions and COD amount on assigned order', () {
    final list = orders.riderOrders(
      storeId: MockIds.defaultStore,
      riderId: MockIds.userRider,
    );
    final assigned = (list['items'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((o) => o['status'] == OrderStatus.assigned);
    expect(assigned['codAmount'], greaterThan(0));

    final out = orders.patchRiderStatus(
      orderId: assigned['id'] as String,
      toStatus: OrderStatus.outForDelivery,
      storeId: MockIds.defaultStore,
      riderId: MockIds.userRider,
    );
    expect(out['status'], OrderStatus.outForDelivery);

    expect(
      () => orders.patchRiderStatus(
        orderId: assigned['id'] as String,
        toStatus: OrderStatus.assigned,
        storeId: MockIds.defaultStore,
        riderId: MockIds.userRider,
      ),
      throwsA(isA<Exception>()),
    );

    final delivered = orders.patchRiderStatus(
      orderId: assigned['id'] as String,
      toStatus: OrderStatus.delivered,
      storeId: MockIds.defaultStore,
      riderId: MockIds.userRider,
    );
    expect(delivered['status'], OrderStatus.delivered);
    expect(delivered['paymentStatus'], 'COLLECTED');
  });
}
