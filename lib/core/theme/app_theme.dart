import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'semantic_colors.dart';

/// DataFightCentral Theme Configuration
/// Dark theme with neon accents for combat sports aesthetic
/// NOTE: Colors now unified with DesignTokens system
class AppTheme {
  AppTheme._();

  // Brand Colors — unified with DesignTokens
  static const Color primaryBackground = DesignTokens.bgPrimary;
  static const Color secondaryBackground = DesignTokens.bgSecondary;
  static const Color cardBackground = DesignTokens.bgCard;
  static const Color surfaceColor = Color(0xFF142236);

  // Neon Accent Colors — unified with DesignTokens
  static const Color neonCyan = DesignTokens.neonCyan;
  static const Color neonMagenta = DesignTokens.neonMagenta;
  static const Color neonGreen = DesignTokens.neonGreen;
  static const Color neonOrange = DesignTokens.neonAmber;
  static const Color neonPurple = DesignTokens.neonPurple;

  // Additional theme colors
  static const Color background = DesignTokens.bgPrimary;
  static const Color accentTeal = DesignTokens.neonCyan;
  static const Color accentCyan = DesignTokens.neonCyan;
  static const Color accentPurple = DesignTokens.neonPurple;
  static const Color neonPink = DesignTokens.neonPink;
  static const Color surfaceDark = DesignTokens.bgOverlay;

  // Semantic Colors
  static const Color success = DesignTokens.neonGreen;
  static const Color error = DesignTokens.neonRed;
  static const Color neonRed = DesignTokens.neonRed;
  static const Color warning = DesignTokens.neonAmber;
  static const Color info = DesignTokens.neonCyan;

  // Text Colors — unified with DesignTokens
  static const Color textPrimary = DesignTokens.textPrimary;
  static const Color textSecondary = DesignTokens.textSecondary;
  static const Color textMuted = DesignTokens.textMuted;

  // Role-specific Colors
  static const Map<String, Color> roleColors = {
    'fighter': neonCyan,
    'coach': neonOrange,
    'gym': neonPurple,
    'promoter': neonMagenta,
    'sponsor': neonGreen,
    'fan': Color(0xFF4A9EFF),
    'admin': Color(0xFFFFD700),
  };

  static Color getRoleColor(String role) {
    return roleColors[role.toLowerCase()] ?? neonCyan;
  }

  static const Color errorColor = error;
  static const Color textDisabled = DesignTokens.textDisabled;

  // Aliases for common usage
  static const Color backgroundDark = primaryBackground;
  static const Color cardDark = cardBackground;

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, neonMagenta],
  );

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
        'Noto Sans Symbols 2',
      ],

      // Semantic color extensions (success / warning / danger / info)
      extensions: const <ThemeExtension<dynamic>>[DFCSemanticColors.neonDark],

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceColor),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonCyan,
          foregroundColor: primaryBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonCyan,
          side: const BorderSide(color: neonCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
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
