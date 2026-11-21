import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/models/store.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../application/admin_repository.dart';

class AdminStoresScreen extends ConsumerStatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  ConsumerState<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends ConsumerState<AdminStoresScreen> {
  Future<void> _upsertStore({Store? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final code = TextEditingController(text: existing?.code ?? '');
    final city = TextEditingController(text: existing?.city ?? 'Bengaluru');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Create store' : 'Edit store'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: code,
              decoration: const InputDecoration(labelText: 'Code'),
            ),
            TextField(
              controller: city,
              decoration: const InputDecoration(labelText: 'City'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;

    try {
      final body = {
        'name': name.text.trim(),
        'code': code.text.trim(),
        'city': city.text.trim(),
      };
      if (existing == null) {
        await ref.read(adminRepositoryProvider).createStore(body);
      } else {
        await ref.read(adminRepositoryProvider).updateStore(existing.id, body);
      }
      ref.invalidate(adminStoresProvider);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _toggleActive(Store store) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .setStoreActive(store.id, !store.active);
      ref.invalidate(adminStoresProvider);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(adminStoresProvider);

    return RoleShellScaffold(
      role: AppRole.admin,
      title: 'Stores',
      actions: [
        HeaderActionButton(
          icon: Icons.home_outlined,
          label: 'Home',
          onPressed: () => context.go('/admin'),
        ),
        HeaderActionButton(
          icon: Icons.add_business_outlined,
          label: 'Add Store',
          onPressed: () => _upsertStore(),
        ),
      ],
      body: storesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminStoresProvider),
        ),
        data: (stores) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminStoresProvider);
            await ref.read(adminStoresProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: stores.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final store = stores[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    store.active ? Icons.storefront : Icons.storefront_outlined,
                    color: store.active
                        ? null
                        : Theme.of(context).colorScheme.error,
                  ),
                  title: Text(store.name),
                  subtitle: Text(
                    '${store.code} · ${store.city} · ${store.active ? 'Active' : 'Inactive'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _upsertStore(existing: store);
                      if (value == 'toggle') _toggleActive(store);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(store.active ? 'Deactivate' : 'Activate'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
