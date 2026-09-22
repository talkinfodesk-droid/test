import 'package:flutter/material.dart';

/// Colour tokens lifted from the reference recording: near-black canvas,
/// soft charcoal cards and a single vivid green accent for "done / live".
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B0C0E);
  static const Color surface = Color(0xFF15171A);
  static const Color card = Color(0xFF1C1F23);
  static const Color cardRaised = Color(0xFF24272C);
  static const Color divider = Color(0xFF2B2F35);

  static const Color textPrimary = Color(0xFFF4F5F7);
  static const Color textSecondary = Color(0xFF9AA0A8);
  static const Color textMuted = Color(0xFF5E646C);

  static const Color green = Color(0xFF34D058);
  static const Color greenDim = Color(0xFF0F2A17);
  static const Color greenRow = Color(0xFF10261A);
  static const Color purple = Color(0xFFB57BFF);
  static const Color blue = Color(0xFF3B6CF6);
  static const Color red = Color(0xFFE5484D);
  static const Color orange = Color(0xFFF5A524);
  static const Color yellow = Color(0xFFE9D24B);
  static const Color avatarBackground = Color(0xFF3B2A5C);
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.green,
      secondary: AppColors.purple,
      surface: AppColors.surface,
      error: AppColors.red,
      onPrimary: Colors.black,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.divider,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1,
        ),
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.textMuted),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }
}
