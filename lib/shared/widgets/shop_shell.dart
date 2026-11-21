import 'package:flutter/material.dart';

import 'brand_backdrop.dart';
import 'page_surface_card.dart';
import 'shop_web_header.dart';

/// Web shopping chrome: sticky header + gradient + page card.
class ShopShell extends StatelessWidget {
  const ShopShell({
    super.key,
    required this.body,
    this.initialQuery,
    this.onSearch,
    this.showSearch = true,
    this.maxContentWidth = 1480,
    this.wrapInCard = true,
    this.cardPadding = EdgeInsets.zero,
  });

  final Widget body;
  final String? initialQuery;
  final ValueChanged<String>? onSearch;
  final bool showSearch;
  final double maxContentWidth;
  final bool wrapInCard;
  final EdgeInsetsGeometry cardPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackdrop(
        child: Column(
          children: [
            ShopWebHeader(
              initialQuery: initialQuery,
              onSearch: onSearch,
              showSearch: showSearch,
            ),
            Expanded(
              child: wrapInCard
                  ? PageSurfaceCard(
                      maxWidth: maxContentWidth,
                      padding: cardPadding,
                      child: body,
                    )
                  : Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: body,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
