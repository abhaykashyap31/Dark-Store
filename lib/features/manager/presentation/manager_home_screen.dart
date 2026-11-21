import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_role.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../../auth/application/auth_controller.dart';
import '../application/manager_repository.dart';

class ManagerHomeScreen extends ConsumerWidget {
  const ManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final storeId = ref.watch(managerStoreIdProvider);

    return RoleShellScaffold(
      role: AppRole.manager,
      title: 'Manager',
      body: storeId == null || storeId.isEmpty
          ? const AppEmptyState(
              title: 'Store mapping missing',
              subtitle: 'Your account has no storeId. Contact an admin.',
              icon: Icons.store_mall_directory_outlined,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Welcome${user != null ? ', ${user.name}' : ''}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: const Text('Your darkstore'),
                    subtitle: Text('storeId: $storeId'),
                  ),
                ),
                const SizedBox(height: 12),
                _NavCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Order queue',
                  subtitle: 'Pick, pack, and assign riders',
                  onTap: () => context.go('/manager/orders'),
                ),
                _NavCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Stock & prices',
                  subtitle: 'Update inventory for this store only',
                  onTap: () => context.go('/manager/inventory'),
                ),
                _NavCard(
                  icon: Icons.warning_amber_outlined,
                  title: 'Low-stock alerts',
                  subtitle: 'Items at or below threshold',
                  onTap: () => context.go('/manager/alerts'),
                ),
                _NavCard(
                  icon: Icons.person_outline,
                  title: 'My profile',
                  subtitle: 'Role MANAGER · store $storeId',
                  onTap: () => context.go('/manager/profile'),
                ),
              ],
            ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
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
