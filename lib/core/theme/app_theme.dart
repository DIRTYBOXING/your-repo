import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'design_tokens.dart';
import 'semantic_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC PREMIUM THEME - Social + PPV Platform
/// Dark neon theme with glassmorphism, glow effects, and premium typography
/// Ready for TikTok-style feeds, Facebook-style profiles, and PPV monetization
/// ═══════════════════════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // BRAND COLORS (Unified with AppColors for consistency)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color primaryBackground = AppColors.bgPrimary;
  static const Color secondaryBackground = AppColors.bgSecondary;
  static const Color cardBackground = AppColors.cardBackground;
  static const Color surfaceColor = AppColors.surfaceElevated;

  // Neon Accent Colors — unified with DesignTokens
  static const Color neonCyan = AppColors.neonCyan;
  static const Color neonMagenta = AppColors.neonMagenta;
  static const Color neonGreen = AppColors.neonLime;
  static const Color neonOrange = AppColors.neonOrange;
  static const Color neonPurple = AppColors.neonViolet;

  // Additional theme colors
  static const Color background = AppColors.bgPrimary;
  static const Color accentTeal = AppColors.neonCyan;
  static const Color accentCyan = AppColors.neonCyan;
  static const Color accentPurple = AppColors.neonViolet;
  static const Color neonPink = AppColors.neonPink;
  static const Color surfaceDark = AppColors.bgSecondary;

  // Semantic Colors
  static const Color success = AppColors.successGreen;
  static const Color error = AppColors.dangerRed;
  static const Color warning = AppColors.warningOrange;
  static const Color info = AppColors.infoBlue;

  // Text Colors — unified with DesignTokens
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = AppColors.textTertiary;

  // Role-specific Colors
  static final Map<String, Color> roleColors = AppColors.roleColors;

  static Color getRoleColor(String role) {
    return AppColors.getRoleColor(role);
  }

  static const Color errorColor = error;
  static const Color textDisabled = AppColors.textDisabled;

  // Aliases for common usage
  static const Color backgroundDark = primaryBackground;
  static const Color cardDark = cardBackground;

  // ═══════════════════════════════════════════════════════════════════════════
  // PREMIUM TYPOGRAPHY (Highly Readable, UI Friendly)
  // ═══════════════════════════════════════════════════════════════════════════
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
    color: textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: textSecondary,
  );

  // Gradients
  static const LinearGradient primaryGradient = AppColors.gradientPPV;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBackground,
      primaryColor: neonCyan,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonMagenta,
        tertiary: neonGreen,
        surface: cardBackground,
        error: error,
        onPrimary: primaryBackground,
        onSecondary: primaryBackground,
        onError: textPrimary,
      ),
      fontFamily: 'Segoe UI',
      fontFamilyFallback: const [
        'Segoe UI Symbol',
        'Apple Color Emoji',
        'Segoe UI Emoji',
        'Noto Color Emoji',
        'Noto Sans Symbols',
      ],

      // Semantic color extensions
      extensions: const <ThemeExtension<dynamic>>[DFCSemanticColors.neonDark],

      // AppBar Theme (Clean & UI Friendly)
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black45,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),

      // Card Theme (Premium with subtle borders)
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0, // We use NeonGlow/GlassPanel instead of default elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // Elevated Button Theme (Primary Call to Action, e.g., Buy PPV)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonCyan,
          foregroundColor: primaryBackground,
          elevation: 4,
          shadowColor: AppColors.glowCyanSoft.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Outlined Button Theme (Secondary Actions)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonCyan,
          side: BorderSide(color: Colors.cyanAccent),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonCyan,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: surfaceColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: surfaceColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: secondaryBackground,
        selectedItemColor: neonCyan,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: neonCyan,
        foregroundColor: primaryBackground,
        elevation: 4,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        labelStyle: const TextStyle(color: textPrimary),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(color: surfaceColor, thickness: 1),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Extension for neon glow effects
extension NeonEffects on BoxDecoration {
  BoxDecoration withNeonGlow(
    Color color, {
    double blur = 20,
    double spread = 2,
  }) {
    return copyWith(
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: blur,
          spreadRadius: spread,
        ),
      ],
    );
  }
}

/// Gradient presets for the app
class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [AppTheme.primaryBackground, AppTheme.secondaryBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [AppTheme.cardBackground, AppTheme.surfaceColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
