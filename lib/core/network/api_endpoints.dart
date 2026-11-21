/// Gateway-relative API paths (under `AppConfig.apiBaseUrl`, which already
/// includes `/api/v1`).
///
/// Auth / Users / Stores / Admin paths follow [API_REFERENCE.md].
/// Catalog / cart / order / manager / rider paths are owned by other services
/// and remain as placeholders until those contracts land.
class ApiEndpoints {
  const ApiEndpoints._();

  // ── Auth (public) ─────────────────────────────────────────────────────
  static const authRegister = '/auth/register';
  static const authLogin = '/auth/login';
  static const authRefresh = '/auth/refresh';
  static const authLogout = '/auth/logout';

  // ── Profile (any logged-in role) ──────────────────────────────────────
  static const usersMe = '/users/me';

  // ── Addresses (CUSTOMER only) ─────────────────────────────────────────
  static const usersMeAddresses = '/users/me/addresses';
  static String userAddress(Object id) => '/users/me/addresses/$id';

  // ── Stores (GET any role; POST/PUT ADMIN) ─────────────────────────────
  static const stores = '/stores';
  static String store(Object id) => '/stores/$id';

  // ── Admin users ───────────────────────────────────────────────────────
  static const adminUsers = '/admin/users';
  static String adminUserStatus(Object id) => '/admin/users/$id/status';

  // ── Catalog placeholders (Inventory service) ──────────────────────────
  static const categories = '/categories';
  static const products = '/products';
  static String product(Object id) => '/products/$id';

  // ── Inventory placeholders (MANAGER) ──────────────────────────────────
  static const inventory = '/inventory';
  static String inventoryProduct(Object productId) =>
      '/inventory/$productId';
  static const inventoryAlerts = '/inventory/alerts';
  static const inventoryAvailableProducts = '/inventory/available-products';

  // ── Cart / orders placeholders (Order service) ────────────────────────
  static const cart = '/cart';
  static const cartItems = '/cart/items';
  static String cartItem(Object id) => '/cart/items/$id';
  static const orders = '/orders';
  static String order(Object id) => '/orders/$id';
  static String orderCancel(Object id) => '/orders/$id/cancel';

  // ── Admin catalogue placeholders (still used by Admin UI mocks) ───────
  static const adminProducts = '/admin/products';
  static String adminProduct(Object id) => '/admin/products/$id';
  static String adminProductActive(Object id) =>
      '/admin/products/$id/active';
  static const adminCategories = '/admin/categories';

  // ── Manager / Rider placeholders (Order service) ──────────────────────
  static const managerOrders = '/manager/orders';
  static String managerOrderStatus(Object id) =>
      '/manager/orders/$id/status';
  static String managerAssignRider(Object id) =>
      '/manager/orders/$id/assign-rider';
  static const managerRiders = '/manager/riders';
  static const riderOrders = '/rider/orders';
  static String riderOrderStatus(Object id) => '/rider/orders/$id/status';

  static const forbiddenInternalPrefix = '/internal';
}
