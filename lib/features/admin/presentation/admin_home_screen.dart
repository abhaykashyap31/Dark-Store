import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_role.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../../auth/application/auth_controller.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return RoleShellScaffold(
      role: AppRole.admin,
      title: 'Admin',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome${user != null ? ', ${user.name}' : ''}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Manage stores, staff accounts, and the product catalogue.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _AdminNavCard(
            icon: Icons.store_mall_directory_outlined,
            title: 'Stores',
            subtitle: 'Create, edit, activate / deactivate stores',
            onTap: () => context.go('/admin/stores'),
          ),
          _AdminNavCard(
            icon: Icons.badge_outlined,
            title: 'Accounts',
            subtitle: 'Create managers & riders; activate / deactivate users',
            onTap: () => context.go('/admin/users'),
          ),
          _AdminNavCard(
            icon: Icons.inventory_2_outlined,
            title: 'Catalogue',
            subtitle: 'Products and categories',
            onTap: () => context.go('/admin/products'),
          ),
          _AdminNavCard(
            icon: Icons.person_outline,
            title: 'My profile',
            subtitle: 'GET /users/me',
            onTap: () => context.go('/admin/profile'),
          ),
        ],
      ),
    );
  }
}

class _AdminNavCard extends StatelessWidget {
  const _AdminNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
