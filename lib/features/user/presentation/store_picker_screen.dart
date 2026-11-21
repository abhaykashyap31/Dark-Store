import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/shop_shell.dart';
import '../application/catalog_repository.dart';
import '../application/selected_store_controller.dart';

class StorePickerScreen extends ConsumerWidget {
  const StorePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesProvider);
    final selected = ref.watch(selectedStoreProvider);

    return ShopShell(
      showSearch: false,
      body: storesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(storesProvider),
        ),
        data: (stores) {
          if (stores.isEmpty) {
            return const AppEmptyState(
              title: 'No stores available',
              subtitle: 'Check back later',
              icon: Icons.store_mall_directory_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: stores.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose delivery location',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select a darkstore to browse products for that area.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                );
              }

              final store = stores[index - 1];
              final isSelected = selected?.id == store.id;

              return Material(
                color: isSelected
                    ? AppColors.brandGreen.withValues(alpha: 0.08)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected ? AppColors.brandGreen : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.softGrey,
                    child: Icon(
                      isSelected ? Icons.check : Icons.storefront_outlined,
                      color: AppColors.brandGreen,
                    ),
                  ),
                  title: Text(
                    store.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text('${store.city} · ${store.code}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref.read(selectedStoreProvider.notifier).select(store);
                    context.go('/user');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
