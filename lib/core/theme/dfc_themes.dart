import 'package:flutter/material.dart';
import 'semantic_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// DFC Theme Modes
///
/// Three distinct themes the user can pick from Settings:
///   • Dark    — The default deep-blue night mode
///   • Dracula — Purple-black with soft pink/magenta accents
///   • Neon    — Black-green hacker aesthetic (high contrast)
/// ═══════════════════════════════════════════════════════════════════════

enum DFCThemeMode {
  dark,
  dracula,
  neon;

  String get label {
    switch (this) {
      case DFCThemeMode.dark:
        return 'Dark';
      case DFCThemeMode.dracula:
        return 'Dracula';
      case DFCThemeMode.neon:
        return 'Neon';
    }
  }

  String get description {
    switch (this) {
      case DFCThemeMode.dark:
        return 'Deep-blue night mode (default)';
      case DFCThemeMode.dracula:
        return 'Purple-black with pink accents';
      case DFCThemeMode.neon:
        return 'High-contrast hacker green';
    }
  }

  IconData get icon {
    switch (this) {
      case DFCThemeMode.dark:
        return Icons.dark_mode;
      case DFCThemeMode.dracula:
        return Icons.nights_stay;
      case DFCThemeMode.neon:
        return Icons.flash_on;
    }
  }

  Color get previewAccent {
    switch (this) {
      case DFCThemeMode.dark:
        return const Color(0xFFB9C7DA);
      case DFCThemeMode.dracula:
        return const Color(0xFFFF79C6); // pink
      case DFCThemeMode.neon:
        return const Color(0xFF39FF14); // green
    }
  }
}

/// Generates a full ThemeData for each mode.
class DFCThemes {
  DFCThemes._();

  static ThemeData forMode(DFCThemeMode mode) {
    switch (mode) {
      case DFCThemeMode.dark:
        return _darkTheme();
      case DFCThemeMode.dracula:
        return _draculaTheme();
      case DFCThemeMode.neon:
        return _neonTheme();
    }
  }

  // ───────────────────────────────────────────────────────────────────
  //  DARK THEME (existing default)
  // ───────────────────────────────────────────────────────────────────
  static ThemeData _darkTheme() {
    const bg = Color(0xFF0B1017);
    const bg2 = Color(0xFF111722);
    const card = Color(0xFF151D2A);
    const surface = Color(0xFF273243);
    const accent = Color(0xFFB9C7DA);
    const secondary = Color(0xFF8FA2BB);
    const tertiary = Color(0xFF5D8F79);
    const err = Color(0xFFE06C75);

    return _buildTheme(
      bg: bg,
      bg2: bg2,
      card: card,
      surface: surface,
      accent: accent,
      secondary: secondary,
      tertiary: tertiary,
      err: err,
      semantic: DFCSemanticColors.neonDark,
    );
  }

  // ───────────────────────────────────────────────────────────────────
  //  DRACULA THEME
  // ───────────────────────────────────────────────────────────────────
  static ThemeData _draculaTheme() {
    const bg = Color(0xFF282A36);
    const bg2 = Color(0xFF1E1F29);
    const card = Color(0xFF343746);
    const surface = Color(0xFF44475A);
    const accent = Color(0xFFFF79C6); // pink
    const secondary = Color(0xFFBD93F9); // purple
    const tertiary = Color(0xFF50FA7B); // green
    const err = Color(0xFFFF5555);

    return _buildTheme(
      bg: bg,
      bg2: bg2,
      card: card,
      surface: surface,
      accent: accent,
      secondary: secondary,
      tertiary: tertiary,
      err: err,
      semantic: const DFCSemanticColors(
        success: Color(0xFF50FA7B),
        onSuccess: Color(0xFF282A36),
        successContainer: Color(0x2050FA7B),
        warning: Color(0xFFF1FA8C),
        onWarning: Color(0xFF282A36),
        warningContainer: Color(0x20F1FA8C),
        danger: Color(0xFFFF5555),
        onDanger: Color(0xFFFFFFFF),
        dangerContainer: Color(0x20FF5555),
        info: Color(0xFF8BE9FD),
        onInfo: Color(0xFF282A36),
        infoContainer: Color(0x208BE9FD),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  //  NEON THEME (hacker green)
  // ───────────────────────────────────────────────────────────────────
  static ThemeData _neonTheme() {
    const bg = Color(0xFF0D0D0D);
    const bg2 = Color(0xFF141414);
    const card = Color(0xFF1A1A1A);
    const surface = Color(0xFF262626);
    const accent = Color(0xFF39FF14); // electric green
    const secondary = Color(0xFF00FFFF); // cyan
    const tertiary = Color(0xFFFF00FF); // magenta
    const err = Color(0xFFFF073A);

    return _buildTheme(
      bg: bg,
      bg2: bg2,
      card: card,
      surface: surface,
      accent: accent,
      secondary: secondary,
      tertiary: tertiary,
      err: err,
      semantic: const DFCSemanticColors(
        success: Color(0xFF39FF14),
        onSuccess: Color(0xFF0D0D0D),
        successContainer: Color(0x2039FF14),
        warning: Color(0xFFFFFF00),
        onWarning: Color(0xFF0D0D0D),
        warningContainer: Color(0x20FFFF00),
        danger: Color(0xFFFF073A),
        onDanger: Color(0xFFFFFFFF),
        dangerContainer: Color(0x20FF073A),
        info: Color(0xFF00FFFF),
        onInfo: Color(0xFF0D0D0D),
        infoContainer: Color(0x2000FFFF),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  //  SHARED BUILDER
  // ───────────────────────────────────────────────────────────────────
  static ThemeData _buildTheme({
    required Color bg,
    required Color bg2,
    required Color card,
    required Color surface,
    required Color accent,
    required Color secondary,
    required Color tertiary,
    required Color err,
    required DFCSemanticColors semantic,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: accent,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: secondary,
        tertiary: tertiary,
        surface: card,
        error: err,
        onPrimary: bg,
        onSecondary: bg,
        onError: Colors.white,
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
      extensions: <ThemeExtension<dynamic>>[semantic],
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: surface),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: bg,
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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent.withValues(alpha: 0.55)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: surface),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: surface),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bg2,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        elevation: 2,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: bg,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        labelStyle: const TextStyle(color: Colors.white),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(color: surface, thickness: 1),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFB0B8C8)),
        bodySmall: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFB0B8C8),
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
