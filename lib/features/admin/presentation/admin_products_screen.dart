import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/admin_product.dart';
import '../../../shared/models/category.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/catalog_item_card.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../application/admin_repository.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  Future<void> _addCategory() async {
    final name = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add category'),
        content: TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final value = name.text.trim();
    name.dispose();
    if (saved != true || value.isEmpty) return;
    try {
      await ref.read(adminRepositoryProvider).createCategory(name: value);
      ref.invalidate(adminCategoriesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category added'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _upsertProduct({AdminProduct? existing}) async {
    var categories = await ref.read(adminCategoriesProvider.future);
    if (categories.isEmpty) {
      if (!mounted) return;
      final create = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('No categories yet'),
          content: const Text('Add a category before creating products.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Add category'),
            ),
          ],
        ),
      );
      if (create == true) {
        await _addCategory();
        categories = await ref.read(adminCategoriesProvider.future);
      }
      if (categories.isEmpty) return;
    }

    final name = TextEditingController(text: existing?.name ?? '');
    final sku = TextEditingController(text: existing?.sku ?? '');
    final price = TextEditingController(
      text: existing?.basePrice.toStringAsFixed(0) ?? '0',
    );
    final description =
        TextEditingController(text: existing?.description ?? '');
    var categoryId = existing?.categoryId ?? categories.first.id;

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(existing == null ? 'Create product' : 'Edit product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: sku,
                      decoration: const InputDecoration(labelText: 'SKU'),
                    ),
                    TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Base price'),
                    ),
                    TextField(
                      controller: description,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final category in categories)
                          DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setLocal(() => categoryId = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    final body = {
      'name': name.text.trim(),
      'sku': sku.text.trim(),
      'basePrice': double.tryParse(price.text.trim()) ?? 0,
      'description': description.text.trim(),
      'categoryId': categoryId,
    };
    name.dispose();
    sku.dispose();
    price.dispose();
    description.dispose();

    if (saved != true) return;

    try {
      if (existing == null) {
        await ref.read(adminRepositoryProvider).createProduct(body);
      } else {
        await ref
            .read(adminRepositoryProvider)
            .updateProduct(existing.id, body);
      }
      ref.invalidate(adminProductsProvider);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _toggleActive(AdminProduct product) async {
    final nextActive = !product.active;
    try {
      await ref
          .read(adminRepositoryProvider)
          .setProductActive(product.id, nextActive);
      ref.invalidate(adminProductsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextActive
                ? '${product.name} activated'
                : '${product.name} deactivated',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _categoryName(List<Category> categories, String? id) {
    if (id == null) return 'Uncategorized';
    final match = categories.where((c) => c.id == id);
    return match.isEmpty ? id : match.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return RoleShellScaffold(
      role: AppRole.admin,
      title: 'Catalogue',
      actions: [
        HeaderActionButton(
          icon: Icons.home_outlined,
          label: 'Home',
          onPressed: () => context.go('/admin'),
        ),
        HeaderActionButton(
          icon: Icons.add,
          label: 'Add Product',
          onPressed: () => _upsertProduct(),
        ),
      ],
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminProductsProvider),
        ),
        data: (products) {
          final categories = categoriesAsync.valueOrNull ?? const <Category>[];
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminProductsProvider);
              ref.invalidate(adminCategoriesProvider);
              await ref.read(adminProductsProvider.future);
            },
            child: CatalogCardGrid(
              padding: const EdgeInsets.all(16),
              childAspectRatio: 0.72,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return CatalogItemCard(
                  title: product.name,
                  priceLabel: product.priceLabel,
                  subtitle: [
                    product.sku,
                    _categoryName(categories, product.categoryId),
                  ].join(' · '),
                  badge: product.active ? 'Active' : 'Inactive',
                  badgeColor: product.active
                      ? const Color(0xFFDFF5E5)
                      : const Color(0xFFFFE0E0),
                  onTap: () => _upsertProduct(existing: product),
                  trailing: Material(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    child: PopupMenuButton<String>(
                      tooltip: 'Actions',
                      onSelected: (value) {
                        if (value == 'edit') {
                          _upsertProduct(existing: product);
                        }
                        if (value == 'toggle') _toggleActive(product);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                            product.active ? 'Deactivate' : 'Activate',
                          ),
                        ),
                      ],
                    ),
                  ),
                  footer: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        product.description?.isNotEmpty == true
                            ? product.description!
                            : 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      // Absorb card InkWell so deactivate always works.
                      GestureDetector(
                        onTap: () {},
                        child: OutlinedButton(
                          onPressed: () => _toggleActive(product),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: product.active
                                ? Colors.redAccent
                                : AppColors.brandGreen,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: const Size(0, 36),
                          ),
                          child: Text(
                            product.active ? 'Deactivate' : 'Activate',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
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
