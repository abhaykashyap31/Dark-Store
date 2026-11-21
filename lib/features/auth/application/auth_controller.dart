import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/session_invalidation.dart';
import '../../../shared/models/app_user.dart';
import 'auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.isBusy = false,
  });

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        user = null,
        errorMessage = null,
        isBusy = false;

  const AuthState.unauthenticated({this.errorMessage})
      : status = AuthStatus.unauthenticated,
        user = null,
        isBusy = false;

  const AuthState.authenticated(this.user)
      : status = AuthStatus.authenticated,
        errorMessage = null,
        isBusy = false;

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
  final bool isBusy;

  AppRole? get role => user?.role;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
    bool? isBusy,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isBusy: isBusy ?? this.isBusy,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.unknown()) {
    restore();
  }

  final AuthRepository _repository;

  Future<void> restore() async {
    state = const AuthState.unknown();
    final session = await _repository.restoreSession();
    if (session == null || !session.user.active) {
      if (session != null && !session.user.active) {
        await _repository.logout();
      }
      state = const AuthState.unauthenticated();
      return;
    }
    state = AuthState.authenticated(session.user);
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final session = await _repository.login(
        email: email,
        password: password,
      );
      if (!session.user.active) {
        await _repository.logout();
        state = const AuthState.unauthenticated(
          errorMessage: 'Account is deactivated',
        );
        return false;
      }
      state = AuthState.authenticated(session.user);
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(errorMessage: _message(e));
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final session = await _repository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      state = AuthState.authenticated(session.user);
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(errorMessage: _message(e));
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (state.status != AuthStatus.authenticated) return;
    try {
      final me = await _repository.fetchMe();
      if (!me.active) {
        await logout();
        state = const AuthState.unauthenticated(
          errorMessage: 'Account is deactivated',
        );
        return;
      }
      state = AuthState.authenticated(me);
    } catch (e) {
      state = state.copyWith(errorMessage: _message(e));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState.unauthenticated();
  }

  void forceUnauthenticated() {
    state = const AuthState.unauthenticated(
      errorMessage: 'Session expired. Please sign in again.',
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _message(Object e) {
    if (e is ApiException) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(ref.watch(authRepositoryProvider));
  ref.listen<int>(sessionInvalidationProvider, (previous, next) {
    if (previous != next) {
      controller.forceUnauthenticated();
    }
  });
  return controller;
});
