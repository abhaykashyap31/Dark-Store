import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/store.dart';
import '../../auth/application/auth_controller.dart';

/// Holds the USER's selected darkstore for catalog, cart, and orders.
class SelectedStoreController extends StateNotifier<Store?> {
  SelectedStoreController() : super(null);

  void select(Store store) => state = store;

  void clear() => state = null;
}

final selectedStoreProvider =
    StateNotifierProvider<SelectedStoreController, Store?>((ref) {
  final controller = SelectedStoreController();
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    if (next.status == AuthStatus.unauthenticated) {
      controller.clear();
    }
  });
  return controller;
});
