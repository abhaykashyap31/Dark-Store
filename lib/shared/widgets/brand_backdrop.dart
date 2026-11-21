import 'package:flutter/material.dart';

/// Soft green–yellow gradient used on auth / shell surfaces.
///
/// Intentionally stack-free so scrollables/columns always get parent constraints.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8F6EC),
            Color(0xFFFFF8E1),
            Color(0xFFF3FAF5),
          ],
        ),
      ),
      child: child ?? const SizedBox.expand(),
    );
  }
}
