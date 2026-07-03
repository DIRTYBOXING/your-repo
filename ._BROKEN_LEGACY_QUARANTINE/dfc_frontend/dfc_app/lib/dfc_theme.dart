import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF05060A);
  static const Color surface = Color(0xFF0A0E17);
  static const Color border = Colors.white10;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white38;

  // HOLY FUK EDITION PALETTE
  static const Color accentCyan = Color(0xFF00E5FF); // Cyan Strike
  static const Color accentRed = Color(0xFFFF3B30); // Combat Red
  static const Color championGold = Color(0xFFFFD600); // Champion Gold
  static const Color accentBlue = Color(0xFF2979FF);
  static const Color accentPurple = Colors.purpleAccent;
  static const Color accentGreen = Colors.greenAccent;
}

ThemeData buildDfcTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentCyan,
      secondary: AppColors.accentBlue,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.accentCyan),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    ),
  );
}
