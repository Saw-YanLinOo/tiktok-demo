import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF000000);
  static const surface = Color(0xFF111111);
  static const card = Color(0xFF1C1C1C);
  static const accent = Color(0xFFFE2C55);      // TikTok red-pink
  static const accentTeal = Color(0xFF69C9D0);  // TikTok teal (create btn left)
  static const white = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF888888);
  static const navInactive = Color(0xFF555555);
  static const liveBadge = Color(0xFFE8304A);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    // Nunito — rounded, bold sans-serif that matches TikTok's visual weight.
    final base = GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.accent,
        secondary: AppColors.accentTeal,
      ),
      textTheme: base.copyWith(
        bodyLarge: base.bodyLarge?.copyWith(color: AppColors.white, fontSize: 16),
        bodyMedium: base.bodyMedium?.copyWith(color: AppColors.white, fontSize: 14),
        bodySmall: base.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 12),
        titleLarge: base.titleLarge?.copyWith(color: AppColors.white, fontWeight: FontWeight.w800),
        titleMedium: base.titleMedium?.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.nunito(
          color: AppColors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.white,
        unselectedItemColor: AppColors.navInactive,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
