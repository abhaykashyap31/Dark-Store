import 'package:flutter/material.dart';

import 'auth_screen.dart';

/// Back-compat entry for login route helpers.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthScreen(initialTab: AuthTab.login);
  }
}
