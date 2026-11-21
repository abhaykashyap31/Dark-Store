import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/models/inventory_item.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/catalog_item_card.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../application/manager_repository.dart';

class ManagerInventoryScreen extends ConsumerStatefulWidget {
  const ManagerInventoryScreen({super.key});

  @override
  ConsumerState<ManagerInventoryScreen> createState() =>
      _ManagerInventoryScreenState();
}

class _ManagerInventoryScreenState
    extends ConsumerState<ManagerInventoryScreen> {
  Future<void> _editItem(InventoryItem item) async {
    final storeId = ref.read(managerStoreIdProvider);
    if (storeId == null) return;

    final price = TextEditingController(text: item.price.toStringAsFixed(0));
    final qty = TextEditingController(text: '${item.quantityOnHand}');
    final threshold =
        TextEditingController(text: '${item.lowStockThreshold}');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Store price'),
            ),
            TextField(
              controller: qty,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock qty'),
            ),
            TextField(
              controller: threshold,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Low-stock threshold'),
            ),
          ],
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

    final priceVal = double.tryParse(price.text.trim());
    final qtyVal = int.tryParse(qty.text.trim());
    final thresholdVal = int.tryParse(threshold.text.trim());
    price.dispose();
    qty.dispose();
    threshold.dispose();
    if (saved != true) return;

    try {
      await ref.read(managerRepositoryProvider).updateInventory(
            storeId: storeId,
            productId: item.productId,
            price: priceVal,
            stockQty: qtyVal,
            lowStockThreshold: thresholdVal,
          );
      ref.invalidate(managerInventoryProvider);
      ref.invalidate(managerAlertsProvider);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _addProduct() async {
    final storeId = ref.read(managerStoreIdProvider);
    if (storeId == null) return;

    List<Map<String, dynamic>> available = const [];
    try {
      available = await ref
          .read(managerRepositoryProvider)
          .fetchAvailableProducts(storeId);
    } catch (_) {
      available = const [];
    }

    String? selectedProductId =
        available.isNotEmpty ? available.first['id'] as String? : null;
    final customName = TextEditingController();
    final customSku = TextEditingController();
    final price = TextEditingController(
      text: available.isNotEmpty
          ? '${(available.first['basePrice'] as num?)?.toInt() ?? 0}'
          : '0',
    );
    final qty = TextEditingController(text: '20');
    final threshold = TextEditingController(text: '10');
    var useCustom = available.isEmpty;

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Add product to stock'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (available.isNotEmpty) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Create new product'),
                        value: useCustom,
                        onChanged: (value) =>
                            setLocal(() => useCustom = value),
                      ),
                      if (!useCustom)
                        DropdownButtonFormField<String>(
                          initialValue: selectedProductId,
                          decoration: const InputDecoration(
                            labelText: 'Catalog product',
                          ),
                          items: [
                            for (final product in available)
                              DropdownMenuItem(
                                value: product['id'] as String,
                                child: Text(
                                  '${product['name']} (${product['sku']})',
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            setLocal(() {
                              selectedProductId = value;
                              final match = available.firstWhere(
                                (p) => p['id'] == value,
                                orElse: () => available.first,
                              );
                              price.text =
                                  '${(match['basePrice'] as num?)?.toInt() ?? 0}';
                            });
                          },
                        ),
                    ],
                    if (useCustom || available.isEmpty) ...[
                      TextField(
                        controller: customName,
                        decoration:
                            const InputDecoration(labelText: 'Product name'),
                      ),
                      TextField(
                        controller: customSku,
                        decoration:
                            const InputDecoration(labelText: 'SKU (optional)'),
                      ),
                    ],
                    TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Store price'),
                    ),
                    TextField(
                      controller: qty,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Stock qty'),
                    ),
                    TextField(
                      controller: threshold,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Low-stock threshold',
                      ),
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
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    final nameVal = customName.text.trim();
    final skuVal = customSku.text.trim();
    final priceVal = double.tryParse(price.text.trim()) ?? 0;
    final qtyVal = int.tryParse(qty.text.trim()) ?? 0;
    final thresholdVal = int.tryParse(threshold.text.trim()) ?? 10;
    final productId = selectedProductId;
    final creatingCustom = useCustom || available.isEmpty;
    customName.dispose();
    customSku.dispose();
    price.dispose();
    qty.dispose();
    threshold.dispose();

    if (saved != true) return;
    if (creatingCustom && nameVal.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a product name')),
      );
      return;
    }

    try {
      await ref.read(managerRepositoryProvider).addInventoryItem(
            storeId: storeId,
            productId: creatingCustom ? null : productId,
            name: creatingCustom ? nameVal : null,
            sku: creatingCustom ? skuVal : null,
            price: priceVal,
            stockQty: qtyVal,
            lowStockThreshold: thresholdVal,
          );
      ref.invalidate(managerInventoryProvider);
      ref.invalidate(managerAlertsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added to stock'),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final add = GoRouterState.of(context).uri.queryParameters['add'];
      if (add == '1' && mounted) {
        _addProduct();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final storeId = ref.watch(managerStoreIdProvider);
    final inventoryAsync = ref.watch(managerInventoryProvider);

    return RoleShellScaffold(
      role: AppRole.manager,
      title: 'Stock & prices',
      actions: [
        HeaderActionButton(
          icon: Icons.home_outlined,
          label: 'Home',
          onPressed: () => context.go('/manager'),
        ),
        if (storeId != null)
          HeaderActionButton(
            icon: Icons.add,
            label: 'Add Product',
            onPressed: _addProduct,
          ),
      ],
      body: storeId == null
          ? const AppEmptyState(
              title: 'Missing storeId',
              subtitle: 'Inventory is scoped to your store mapping',
            )
          : inventoryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(managerInventoryProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppEmptyState(
                            title: 'No inventory rows',
                            subtitle: 'Add a product to start stocking',
                            icon: Icons.inventory_2_outlined,
                          ),
                          FilledButton.icon(
                            onPressed: _addProduct,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text(
                        'Editing applies only to store $storeId',
                        style: GoogleFonts.plusJakartaSans(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(managerInventoryProvider);
                          await ref.read(managerInventoryProvider.future);
                        },
                        child: CatalogCardGrid(
                          childAspectRatio: 0.72,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return CatalogItemCard(
                              title: item.name,
                              priceLabel: item.priceLabel,
                              subtitle:
                                  '${item.sku ?? item.productId} · qty ${item.quantityOnHand}',
                              badge:
                                  item.isLowStock ? 'LOW STOCK' : 'In stock',
                              badgeColor: item.isLowStock
                                  ? const Color(0xFFFFE0E0)
                                  : const Color(0xFFDFF5E5),
                              onTap: () => _editItem(item),
                              footer: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _editItem(item),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Edit'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
