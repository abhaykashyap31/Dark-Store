import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_home_screen.dart';
import '../../features/admin/presentation/admin_products_screen.dart';
import '../../features/admin/presentation/admin_stores_screen.dart';
import '../../features/admin/presentation/admin_users_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/manager/presentation/manager_alerts_screen.dart';
import '../../features/manager/presentation/manager_home_screen.dart';
import '../../features/manager/presentation/manager_inventory_screen.dart';
import '../../features/manager/presentation/manager_order_detail_screen.dart';
import '../../features/manager/presentation/manager_orders_screen.dart';
import '../../features/rider/presentation/rider_home_screen.dart';
import '../../features/rider/presentation/rider_order_detail_screen.dart';
import '../../features/user/presentation/cart_screen.dart';
import '../../features/user/presentation/checkout_screen.dart';
import '../../features/user/presentation/order_confirmation_screen.dart';
import '../../features/user/presentation/order_detail_screen.dart';
import '../../features/user/presentation/order_list_screen.dart';
import '../../features/user/presentation/product_detail_screen.dart';
import '../../features/user/presentation/product_list_screen.dart';
import '../../features/user/presentation/store_picker_screen.dart';
import '../../features/user/presentation/user_home_screen.dart';
import '../constants/app_role.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    refresh.value++;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      final status = auth.status;

      if (status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }

      if (status == AuthStatus.unauthenticated) {
        if (loc == '/login' || loc == '/register') return null;
        return '/login';
      }

      final role = auth.role;
      if (role == null) return '/login';

      final home = role.homePath;
      if (loc == '/splash' || loc == '/login' || loc == '/register') {
        return home;
      }

      if (!_isAllowed(role, loc)) return home;

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const AuthScreen(initialTab: AuthTab.login),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            const AuthScreen(initialTab: AuthTab.register),
      ),
      GoRoute(
        path: '/user',
        builder: (context, state) => const UserHomeScreen(),
      ),
      GoRoute(
        path: '/user/stores',
        builder: (context, state) => const StorePickerScreen(),
      ),
      GoRoute(
        path: '/user/products',
        builder: (context, state) => ProductListScreen(
          categoryId: state.uri.queryParameters['categoryId'],
          initialQuery: state.uri.queryParameters['q'],
        ),
      ),
      GoRoute(
        path: '/user/products/:productId',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['productId']!,
        ),
      ),
      GoRoute(
        path: '/user/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/user/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/user/orders',
        builder: (context, state) => const OrderListScreen(),
      ),
      GoRoute(
        path: '/user/orders/:orderId/confirmation',
        builder: (context, state) => OrderConfirmationScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '/user/orders/:orderId',
        builder: (context, state) => OrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '/user/profile',
        builder: (context, state) {
          try {
            return const ProfileScreen(role: AppRole.user);
          } catch (e, st) {
            debugPrint('ProfileScreen build failed: $e\n$st');
            return Scaffold(
              appBar: AppBar(title: const Text('Profile')),
              body: Center(child: Text('Failed to open profile: $e')),
            );
          }
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/admin/stores',
        builder: (context, state) => const AdminStoresScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: '/admin/profile',
        builder: (context, state) => const ProfileScreen(role: AppRole.admin),
      ),
      GoRoute(
        path: '/manager',
        builder: (context, state) => const ManagerHomeScreen(),
      ),
      GoRoute(
        path: '/manager/orders',
        builder: (context, state) => const ManagerOrdersScreen(),
      ),
      GoRoute(
        path: '/manager/orders/:orderId',
        builder: (context, state) => ManagerOrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '/manager/inventory',
        builder: (context, state) => const ManagerInventoryScreen(),
      ),
      GoRoute(
        path: '/manager/alerts',
        builder: (context, state) => const ManagerAlertsScreen(),
      ),
      GoRoute(
        path: '/manager/profile',
        builder: (context, state) =>
            const ProfileScreen(role: AppRole.manager),
      ),
      GoRoute(
        path: '/rider',
        builder: (context, state) => const RiderHomeScreen(),
      ),
      GoRoute(
        path: '/rider/orders/:orderId',
        builder: (context, state) => RiderOrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '/rider/profile',
        builder: (context, state) => const ProfileScreen(role: AppRole.rider),
      ),
    ],
  );
});

bool _isAllowed(AppRole role, String location) {
  switch (role) {
    case AppRole.user:
      return location.startsWith('/user');
    case AppRole.admin:
      return location.startsWith('/admin');
    case AppRole.manager:
      return location.startsWith('/manager');
    case AppRole.rider:
      return location.startsWith('/rider');
  }
}
