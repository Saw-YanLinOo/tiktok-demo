import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.background,
          primary: AppColors.accent,
          secondary: AppColors.accentTeal,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
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
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.white),
          bodyMedium: TextStyle(color: AppColors.white),
          bodySmall: TextStyle(color: AppColors.textSecondary),
        ),
      );
}
