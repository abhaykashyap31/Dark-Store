import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

IconData catalogIconForName(String name) {
  final n = name.toLowerCase();
  if (n.contains('milk') || n.contains('yogurt')) {
    return Icons.local_drink_outlined;
  }
  if (n.contains('bread') || n.contains('egg')) {
    return Icons.bakery_dining_outlined;
  }
  if (n.contains('chip') || n.contains('peanut') || n.contains('snack')) {
    return Icons.cookie_outlined;
  }
  if (n.contains('water') || n.contains('cola') || n.contains('drink')) {
    return Icons.water_drop_outlined;
  }
  if (n.contains('banana') ||
      n.contains('tomato') ||
      n.contains('fruit') ||
      n.contains('veg')) {
    return Icons.eco_outlined;
  }
  return Icons.shopping_bag_outlined;
}

/// Visual product/catalog card used across USER / ADMIN / MANAGER UIs.
class CatalogItemCard extends StatelessWidget {
  const CatalogItemCard({
    super.key,
    required this.title,
    required this.priceLabel,
    this.subtitle,
    this.badge,
    this.badgeColor,
    this.trailing,
    this.onTap,
    this.footer,
    this.width,
    this.compact = false,
  });

  final String title;
  final String priceLabel;
  final String? subtitle;
  final String? badge;
  final Color? badgeColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? footer;
  final double? width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: compact ? 3 : 4,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.softGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          catalogIconForName(title),
                          size: compact ? 36 : 48,
                          color: AppColors.brandGreen,
                        ),
                      ),
                      if (badge != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor ?? AppColors.brandYellow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      if (trailing != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {}, // keep card onTap from stealing menu taps
                            child: trailing!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: compact ? 8 : 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 13 : 14,
                  height: 1.25,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                priceLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (footer != null) ...[
                const SizedBox(height: 8),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );

    if (width != null && width!.isFinite) {
      return SizedBox(width: width, child: card);
    }
    return card;
  }
}

int catalogGridCount(double width) {
  if (width > 1100) return 5;
  if (width > 850) return 4;
  if (width > 600) return 3;
  return 2;
}

class CatalogCardGrid extends StatelessWidget {
  const CatalogCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(16),
    this.childAspectRatio = 0.72,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = catalogGridCount(constraints.maxWidth);
        return GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
