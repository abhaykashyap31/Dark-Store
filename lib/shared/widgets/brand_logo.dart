import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.fontSize = 28,
    this.onTap,
  });

  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'i',
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.brandYellow,
              letterSpacing: -0.8,
            ),
          ),
          TextSpan(
            text: 'DarkStore',
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.brandGreen,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(fontSize * 0.22),
          child: Image.asset(
            'assets/images/app_logo.png',
            width: fontSize,
            height: fontSize,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
          ),
        ),
        SizedBox(width: fontSize * 0.28),
        text,
      ],
    );

    if (onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: content),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/app_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

String get brandTitle => AppConfig.appName;
