import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Large rectangular page surface used across the app.
class PageSurfaceCard extends StatelessWidget {
  const PageSurfaceCard({
    super.key,
    required this.child,
    this.maxWidth = 1480,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.fromLTRB(12, 12, 12, 16),
    this.expand = true,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : maxWidth;
          final width = maxW > maxWidth ? maxWidth : maxW;

          final card = Material(
            color: Colors.white,
            elevation: 6,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          );

          if (!expand || !constraints.hasBoundedHeight) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: card,
              ),
            );
          }

          final height = constraints.maxHeight;
          if (height <= 0 || !height.isFinite) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: card,
              ),
            );
          }

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              height: height,
              child: card,
            ),
          );
        },
      ),
    );
  }
}
