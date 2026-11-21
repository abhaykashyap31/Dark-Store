import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand_backdrop.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/page_surface_card.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackdrop(
        child: Center(
            child: PageSurfaceCard(
            maxWidth: 420,
            expand: false,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandLogo(fontSize: 28),
                SizedBox(height: 12),
                Text(
                  'Restoring session…',
                  style: TextStyle(color: AppColors.muted),
                ),
                SizedBox(height: 28),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.brandGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
