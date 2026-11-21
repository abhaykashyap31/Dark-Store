import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/store.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../application/admin_repository.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  Future<void> _createStaff() async {
    final stores = await ref.read(adminStoresProvider.future);
    final activeStores = stores.where((s) => s.active).toList();
    if (activeStores.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create an active store first')),
      );
      return;
    }

    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController(text: 'password');
    var role = 'MANAGER';
    var storeId = activeStores.first.id;

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Create manager / rider'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Full name'),
                    ),
                    TextField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: password,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(
                          value: 'MANAGER',
                          child: Text('MANAGER'),
                        ),
                        DropdownMenuItem(
                          value: 'RIDER',
                          child: Text('RIDER'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setLocal(() => role = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: storeId,
                      decoration: const InputDecoration(labelText: 'Store'),
                      items: [
                        for (final store in activeStores)
                          DropdownMenuItem(
                            value: store.id,
                            child: Text('${store.name} (${store.code})'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setLocal(() => storeId = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    try {
      await ref.read(adminRepositoryProvider).createStaffUser(
            name: name.text.trim(),
            email: email.text.trim(),
            password: password.text,
            role: role,
            storeId: storeId,
          );
      ref.invalidate(adminUsersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _toggleActive(AppUser user) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .setUserActive(user.id, !user.active);
      ref.invalidate(adminUsersProvider);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _storeLabel(List<Store> stores, String? storeId) {
    if (storeId == null) return 'No store';
    final match = stores.where((s) => s.id == storeId);
    if (match.isEmpty) return storeId;
    return match.first.code;
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final storesAsync = ref.watch(adminStoresProvider);

    return RoleShellScaffold(
      role: AppRole.admin,
      title: 'Accounts',
      actions: [
        HeaderActionButton(
          icon: Icons.home_outlined,
          label: 'Home',
          onPressed: () => context.go('/admin'),
        ),
        HeaderActionButton(
          icon: Icons.person_add_alt_1_outlined,
          label: 'Create Staff',
          onPressed: _createStaff,
        ),
      ],
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminUsersProvider),
        ),
        data: (users) {
          final stores = storesAsync.valueOrNull ?? const <Store>[];
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminUsersProvider);
              await ref.read(adminUsersProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(user.role.apiValue[0]),
                    ),
                    title: Text(user.name),
                    subtitle: Text(
                      [
                        user.email,
                        user.role.apiValue,
                        if (user.storeId != null)
                          _storeLabel(stores, user.storeId),
                        user.active ? 'Active' : 'Deactivated',
                      ].join(' · '),
                    ),
                    isThreeLine: true,
                    trailing: user.role == AppRole.admin
                        ? const Tooltip(
                            message: 'Admin cannot be deactivated here',
                            child: Icon(Icons.lock_outline),
                          )
                        : Switch(
                            value: user.active,
                            onChanged: (_) => _toggleActive(user),
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
