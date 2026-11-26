/// Stable UUID seeds shared by Auth / Catalog / Admin / Order mocks
/// (API_REFERENCE.md: ids are UUID strings).
abstract final class MockIds {
  static const storeKoramangala = '550e8400-e29b-41d4-a716-446655440002';
  static const storeIndiranagar = '550e8400-e29b-41d4-a716-446655440012';

  static const userCustomer = '550e8400-e29b-41d4-a716-446655440007';
  static const userAdmin = '550e8400-e29b-41d4-a716-446655440001';
  static const userManager = '550e8400-e29b-41d4-a716-446655440010';
  static const userRider = '550e8400-e29b-41d4-a716-446655440020';
  static const userInactive = '550e8400-e29b-41d4-a716-446655440099';

  static const addressHome = '550e8400-e29b-41d4-a716-446655440003';
  static const addressOffice = '550e8400-e29b-41d4-a716-446655440004';

  /// Default store for manager/rider demos and catalog fallbacks.
  static const defaultStore = storeKoramangala;
}
