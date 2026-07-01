import 'package:flutter/material.dart';
import '../constants/theme_mode.dart';
import 'app_colors.dart';

/// Dynamic Theme Controller for Fight Camp Phases
/// Provides live theme switching based on fighter's current training phase
class ThemeController {
  ThemeController._();

  /// Current theme mode notifier for reactive UI updates
  static final ValueNotifier<DfcThemeMode> mode = ValueNotifier(
    DfcThemeMode.classic,
  );

  /// Set the current theme mode
  static void setMode(DfcThemeMode newMode) {
    mode.value = newMode;
  }

  /// Get the accent color for current mode
  static Color get accent {
    switch (mode.value) {
      case DfcThemeMode.classic:
        return AppColors.neonCyan;
      case DfcThemeMode.baseCamp:
        return AppColors.neonSky;
      case DfcThemeMode.fightCamp:
        return AppColors.neonGreen;
      case DfcThemeMode.fightWeek:
        return AppColors.neonRed;
      case DfcThemeMode.fightDay:
        return AppColors.neonAmber;
      case DfcThemeMode.recovery:
        return AppColors.neonPurple;
    }
  }

  /// Get the label for current mode
  static String get label {
    switch (mode.value) {
      case DfcThemeMode.classic:
        return 'CLASSIC';
      case DfcThemeMode.baseCamp:
        return 'BASE CAMP';
      case DfcThemeMode.fightCamp:
        return 'FIGHT CAMP';
      case DfcThemeMode.fightWeek:
        return 'FIGHT WEEK';
      case DfcThemeMode.fightDay:
        return 'FIGHT DAY';
      case DfcThemeMode.recovery:
        return 'RECOVERY';
    }
  }

  /// Get the gradient for current mode
  static LinearGradient get gradient {
    switch (mode.value) {
      case DfcThemeMode.classic:
        return AppColors.primaryGradient;
      case DfcThemeMode.baseCamp:
        return const LinearGradient(
          colors: [AppColors.neonSky, AppColors.neonBlue],
        );
      case DfcThemeMode.fightCamp:
        return const LinearGradient(
          colors: [AppColors.neonGreen, AppColors.neonBlue],
        );
      case DfcThemeMode.fightWeek:
        return const LinearGradient(
          colors: [AppColors.neonRed, AppColors.neonOrange],
        );
      case DfcThemeMode.fightDay:
        return const LinearGradient(
          colors: [AppColors.neonAmber, AppColors.neonOrange],
        );
      case DfcThemeMode.recovery:
        return const LinearGradient(
          colors: [AppColors.neonPurple, AppColors.neonSky],
        );
    }
  }

  /// Get description for each mode
  static String get description {
    switch (mode.value) {
      case DfcThemeMode.classic:
        return 'Default theme for everyday use';
      case DfcThemeMode.baseCamp:
        return 'Pre-camp preparation phase';
      case DfcThemeMode.fightCamp:
        return 'Active training camp mode';
      case DfcThemeMode.fightWeek:
        return 'Final week intensity';
      case DfcThemeMode.fightDay:
        return 'Fight day focus';
      case DfcThemeMode.recovery:
        return 'Post-fight recovery phase';
    }
  }
}
