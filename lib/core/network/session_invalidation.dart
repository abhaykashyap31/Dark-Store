import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented when Dio decides the session is dead (failed refresh).
/// [authControllerProvider] listens and forces logout UI state.
final sessionInvalidationProvider = StateProvider<int>((ref) => 0);
