/// Order state machine used by USER tracking UI.
class OrderStatus {
  const OrderStatus._();

  static const created = 'CREATED';
  static const confirmed = 'CONFIRMED';
  static const picking = 'PICKING';
  static const packed = 'PACKED';
  static const assigned = 'ASSIGNED';
  static const outForDelivery = 'OUT_FOR_DELIVERY';
  static const delivered = 'DELIVERED';
  static const cancelled = 'CANCELLED';

  /// Happy-path progression (excluding CANCELLED).
  static const pipeline = <String>[
    created,
    confirmed,
    picking,
    packed,
    assigned,
    outForDelivery,
    delivered,
  ];

  static bool canUserCancel(String status) =>
      status == created || status == confirmed;

  /// Manager may advance: CONFIRMED → PICKING → PACKED.
  /// Rider assignment (PACKED → ASSIGNED) is a separate API.
  static String? managerNextStatus(String status) {
    switch (status) {
      case confirmed:
        return picking;
      case picking:
        return packed;
      default:
        return null;
    }
  }

  static bool canAssignRider(String status) => status == packed;

  /// Rider may advance: ASSIGNED → OUT_FOR_DELIVERY → DELIVERED.
  static String? riderNextStatus(String status) {
    switch (status) {
      case assigned:
        return outForDelivery;
      case outForDelivery:
        return delivered;
      default:
        return null;
    }
  }

  static String label(String status) {
    switch (status) {
      case created:
        return 'Created';
      case confirmed:
        return 'Confirmed';
      case picking:
        return 'Picking';
      case packed:
        return 'Packed';
      case assigned:
        return 'Assigned to rider';
      case outForDelivery:
        return 'Out for delivery';
      case delivered:
        return 'Delivered';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }
}
