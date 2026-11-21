import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/address.dart';
import '../../../shared/models/app_user.dart';
import '../../user/application/order_repository.dart';
import '../../user/presentation/widgets/address_editor_dialog.dart';
import '../application/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.role});

  final AppRole role;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  List<Address> _addresses = const [];
  bool _loadingAddresses = false;
  String? _addressError;

  @override
  void initState() {
    super.initState();
    if (widget.role == AppRole.user) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAddresses();
      });
    }
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _loadingAddresses = true;
      _addressError = null;
    });
    try {
      final items = await ref.read(orderRepositoryProvider).fetchAddresses();
      if (!mounted) return;
      setState(() => _addresses = items);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _addressError = e is ApiException ? e.message : e.toString();
      });
    } finally {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  Future<void> _addAddress() async {
    final draft = await showAddressEditorDialog(context);
    if (draft == null || !mounted) return;
    try {
      await ref.read(orderRepositoryProvider).addAddress(draft);
      await _loadAddresses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address saved'),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is ApiException ? e.message : e.toString()),
        ),
      );
    }
  }

  Future<void> _editAddress(Address address) async {
    final draft = await showAddressEditorDialog(context, initial: address);
    if (draft == null || !mounted) return;
    try {
      await ref.read(orderRepositoryProvider).updateAddress(draft);
      await _loadAddresses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address updated'),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is ApiException ? e.message : e.toString()),
        ),
      );
    }
  }

  void _goHome() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(widget.role.homePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF3FAF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goHome,
        ),
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
            child: const Text('Sign out'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: user == null
          ? const Center(child: Text('No profile loaded. Please sign in again.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _UserHeader(user: user, roleLabel: widget.role.label),
                const SizedBox(height: 12),
                _InfoCard(user: user),
                if (widget.role == AppRole.user) ...[
                  const SizedBox(height: 12),
                  _AddressesCard(
                    addresses: _addresses,
                    loading: _loadingAddresses,
                    error: _addressError,
                    onRetry: _loadAddresses,
                    onAdd: _addAddress,
                    onEdit: _editAddress,
                  ),
                ],
                if (AppConfig.useMockApis) ...[
                  const SizedBox(height: 12),
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.cloud_outlined,
                          color: AppColors.brandGreen),
                      title: Text('Session source'),
                      subtitle: Text('Loaded via GET /users/me (mock)'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user, required this.roleLabel});

  final AppUser user;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.brandGreen.withValues(alpha: 0.12),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandGreen,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(user.email),
                  const SizedBox(height: 4),
                  Text(
                    '$roleLabel · ${user.role.apiValue} · ${user.active ? 'Active' : 'Deactivated'}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading:
                const Icon(Icons.email_outlined, color: AppColors.brandGreen),
            title: const Text('Email'),
            subtitle: Text(user.email),
          ),
          const Divider(height: 1),
          ListTile(
            leading:
                const Icon(Icons.badge_outlined, color: AppColors.brandGreen),
            title: const Text('Role'),
            subtitle: Text(user.role.apiValue),
          ),
          const Divider(height: 1),
          ListTile(
            leading:
                const Icon(Icons.phone_outlined, color: AppColors.brandGreen),
            title: const Text('Phone'),
            subtitle: Text(
              (user.phone != null && user.phone!.isNotEmpty)
                  ? user.phone!
                  : 'Not set',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.store_mall_directory_outlined,
                color: AppColors.brandGreen),
            title: const Text('Store ID'),
            subtitle: Text(user.storeId ?? 'None (not store-scoped)'),
          ),
          const Divider(height: 1),
          ListTile(
            leading:
                const Icon(Icons.fingerprint, color: AppColors.brandGreen),
            title: const Text('User ID'),
            subtitle: Text(user.id),
          ),
        ],
      ),
    );
  }
}

class _AddressesCard extends StatelessWidget {
  const _AddressesCard({
    required this.addresses,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onAdd,
    required this.onEdit,
  });

  final List<Address> addresses;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onAdd;
  final void Function(Address address) onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Saved addresses',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                // Avoid FilledButton under loose width (infinite min width crash).
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: const Text('Add Address'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              Column(
                children: [
                  Text(error!, textAlign: TextAlign.center),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              )
            else if (addresses.isEmpty)
              const Text(
                'No saved addresses yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              )
            else
              for (final address in addresses)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.brandGreen,
                  ),
                  title: Text(
                    address.defaultAddress
                        ? '${address.label} (Default)'
                        : address.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(address.summary),
                  trailing: TextButton(
                    onPressed: () => onEdit(address),
                    child: const Text('Edit'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
