import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../placeholders/auth_api_mock.dart';
import '../../../shared/widgets/brand_backdrop.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../application/auth_controller.dart';

enum AuthTab { login, register }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialTab = AuthTab.login});

  final AuthTab initialTab;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController(text: 'password');

  final _name = TextEditingController();
  final _registerEmail = TextEditingController();
  final _phone = TextEditingController();
  final _registerPassword = TextEditingController();
  final _confirm = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == AuthTab.register ? 1 : 0,
    );
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        ref.read(authControllerProvider.notifier).clearError();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _name.dispose();
    _registerEmail.dispose();
    _phone.dispose();
    _registerPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await ref.read(authControllerProvider.notifier).login(
          email: _loginEmail.text.trim(),
          password: _loginPassword.text,
        );
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await ref.read(authControllerProvider.notifier).register(
          name: _name.text.trim(),
          email: _registerEmail.text.trim(),
          password: _registerPassword.text,
          phone: _phone.text.trim(),
        );
    if (mounted) setState(() => _submitting = false);
  }

  void _fillDemo(String email) {
    setState(() {
      _tabs.animateTo(0);
      _loginEmail.text = email;
      _loginPassword.text = 'password';
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width > 560 ? 440.0 : width - 32;

    return Scaffold(
      body: Stack(
        children: [
          const BrandBackdrop(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Material(
                  color: Colors.white,
                  elevation: 10,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BrandLogo(fontSize: 34),
                        const SizedBox(height: 8),
                        Text(
                          'Groceries & essentials in minutes',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.softGrey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabs,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            labelColor: AppColors.brandGreen,
                            unselectedLabelColor: AppColors.muted,
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                            tabs: const [
                              Tab(text: 'Login'),
                              Tab(text: 'Register'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          child: _tabs.index == 0
                              ? _LoginForm(
                                  formKey: _loginFormKey,
                                  emailController: _loginEmail,
                                  passwordController: _loginPassword,
                                  errorMessage: auth.errorMessage,
                                  submitting: _submitting,
                                  onSubmit: _login,
                                )
                              : _RegisterForm(
                                  formKey: _registerFormKey,
                                  nameController: _name,
                                  emailController: _registerEmail,
                                  phoneController: _phone,
                                  passwordController: _registerPassword,
                                  confirmController: _confirm,
                                  errorMessage: auth.errorMessage,
                                  submitting: _submitting,
                                  onSubmit: _register,
                                ),
                        ),
                        if (AppConfig.useMockApis && _tabs.index == 0) ...[
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Demo accounts',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final account in AuthApiMock.demoAccounts)
                                ActionChip(
                                  label: Text(account['role']!),
                                  onPressed: () =>
                                      _fillDemo(account['email']!),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.errorMessage,
    required this.submitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? errorMessage;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Email is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Password is required' : null,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: submitting ? null : onSubmit,
            child: submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmController,
    required this.errorMessage,
    required this.submitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final String? errorMessage;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          Text(
            'Create a customer account. Staff accounts are created by admin.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone (optional)',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) =>
                value == null || value.length < 6
                    ? 'Use at least 6 characters'
                    : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: confirmController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) => value != passwordController.text
                ? 'Passwords do not match'
                : null,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: submitting ? null : onSubmit,
            child: submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Create account'),
          ),
        ],
      ),
    );
  }
}
