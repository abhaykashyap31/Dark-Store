/// Gateway-relative API paths used by Dio repositories.
///
/// Flutter talks **only** to the API Gateway (`AppConfig.apiBaseUrl`).
/// Do **not** add any `/internal/**` paths here — those are service-to-service.
///
/// See [BACKEND_INTEGRATION.md](../../../BACKEND_INTEGRATION.md).
class ApiEndpoints {
  const ApiEndpoints._();

  // ── Auth ──────────────────────────────────────────────────────────────
  static const authRegister = '/auth/register';
  static const authLogin = '/auth/login';
  static const authRefresh = '/auth/refresh';
  static const authLogout = '/auth/logout';

  // ── Users / profile ───────────────────────────────────────────────────
  static const usersMe = '/users/me';
  static const usersMeAddresses = '/users/me/addresses';
  static String userAddress(String id) => '/users/me/addresses/$id';

  // ── Catalog (USER / shared) ───────────────────────────────────────────
  static const stores = '/stores';
  static String store(String id) => '/stores/$id';
  static const categories = '/categories';
  static const products = '/products';
  static String product(String id) => '/products/$id';

  // ── Inventory (MANAGER) ───────────────────────────────────────────────
  static const inventory = '/inventory';
  static String inventoryProduct(String productId) =>
      '/inventory/$productId';
  static const inventoryAlerts = '/inventory/alerts';
  static const inventoryAvailableProducts = '/inventory/available-products';

  // ── Cart / orders (USER) ──────────────────────────────────────────────
  static const cart = '/cart';
  static const cartItems = '/cart/items';
  static String cartItem(String id) => '/cart/items/$id';
  static const orders = '/orders';
  static String order(String id) => '/orders/$id';
  static String orderCancel(String id) => '/orders/$id/cancel';

  // ── Admin ─────────────────────────────────────────────────────────────
  static const adminStores = '/admin/stores';
  static String adminStore(String id) => '/admin/stores/$id';
  static String adminStoreActive(String id) => '/admin/stores/$id/active';
  static const adminUsers = '/admin/users';
  static String adminUserActive(String id) => '/admin/users/$id/active';
  static const adminProducts = '/admin/products';
  static String adminProduct(String id) => '/admin/products/$id';
  static String adminProductActive(String id) =>
      '/admin/products/$id/active';

  // ── Manager ───────────────────────────────────────────────────────────
  static const managerOrders = '/manager/orders';
  static String managerOrderStatus(String id) =>
      '/manager/orders/$id/status';
  static String managerAssignRider(String id) =>
      '/manager/orders/$id/assign-rider';
  static const managerRiders = '/manager/riders';

  // ── Rider ─────────────────────────────────────────────────────────────
  static const riderOrders = '/rider/orders';
  static String riderOrderStatus(String id) => '/rider/orders/$id/status';

  /// Paths that must never be called from Flutter.
  static const forbiddenInternalPrefix = '/internal';
}
