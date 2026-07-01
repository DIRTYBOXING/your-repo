/// ═══════════════════════════════════════════════════════════════════════════
/// DFC UI SYSTEM RULES - 2026 STYLE DESIGN TOKENS
/// LOCKED SPECIFICATION - DO NOT OVERRIDE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Style: Apple Vision Pro + Cyber Neon MMA Intelligence OS
/// Vibe: Clean, Pro, Futuristic, Premium Software (NOT kids app)
///
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';

/// Design tokens - IMMUTABLE UI SPECIFICATIONS
abstract class DesignTokens {
  DesignTokens._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CARD DIMENSIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Card max heights - keep panels slim
  static const double cardMaxHeightDesktop = 160.0;
  static const double cardMaxHeightMobile = 130.0;
  static const double cardMinHeight = 80.0;

  /// Card padding - tight, not bloated
  static const double cardPaddingSmall = 12.0;
  static const double cardPaddingMedium = 16.0;
  static const double cardPaddingLarge = 20.0;

  /// Border radius - modern, not too round
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 18.0;
  static const double radiusLarge = 24.0;
  static const double radiusPill = 100.0;

  /// Border width - thin, subtle
  static const double borderThin = 0.6;
  static const double borderNormal = 1.0;
  static const double borderThick = 1.5;

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════

  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY - Hierarchy
  // ═══════════════════════════════════════════════════════════════════════════

  /// Title - bold, clear
  static const double fontSizeTitle = 18.0;
  static const double fontSizeTitleLarge = 20.0;
  static const FontWeight fontWeightTitle = FontWeight.bold;

  /// Subtitle - muted, smaller
  static const double fontSizeSubtitle = 12.0;
  static const double fontSizeSubtitleLarge = 13.0;

  /// Stat numbers - prominent
  static const double fontSizeStatSmall = 20.0;
  static const double fontSizeStatLarge = 24.0;
  static const FontWeight fontWeightStat = FontWeight.bold;

  /// Body text
  static const double fontSizeBody = 14.0;
  static const double fontSizeCaption = 11.0;
  static const double fontSizeMicro = 10.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // BUTTONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightLarge = 44.0;
  static const double buttonPaddingH = 16.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // GLASS MORPHISM - Apple Vision Pro Style
  // ═══════════════════════════════════════════════════════════════════════════

  /// Background opacity for glass cards
  static const double glassOpacity = 0.04;
  static const double glassOpacityHover = 0.08;

  /// Border opacity
  static const double glassBorderOpacity = 0.14;
  static const double glassBorderOpacityHover = 0.25;

  /// Blur intensity
  static const double glassBlur = 18.0;
  static const double glassBlurLight = 12.0;

  /// Glow settings - only on hover/focus
  static const double glowRadius = 20.0;
  static const double glowOpacity = 0.15;

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORS - Neon Accents
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color neonCyan = Color(0xFF00F5FF);
  static const Color neonMagenta = Color(0xFFFF00FF);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonAmber = Color(0xFFFFB800);
  static const Color neonRed = Color(0xFFFF3366);
  static const Color neonGold = Color(0xFFFFD700);
  static const Color neonBlue = Color(0xFF00D9FF);
  static const Color neonOrange = Color(0xFFFF6B00);
  static const Color neonPurple = Color(0xFF9D00FF);
  static const Color neonPink = Color(0xFFFF1493);

  /// Semantic colors
  static const Color success = Color(0xFF00FF88);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF3366);

  /// Border colors
  static const Color borderSubtle = Color(0x33FFFFFF); // 20%

  /// Background colors
  static const Color bgPrimary = Color(0xFF050A14);
  static const Color bgSecondary = Color(0xFF0A1628);
  static const Color bgCard = Color(0xFF0D1B2A);
  static const Color bgSurface = Color(0xFF142236);
  static const Color bgOverlay = Color(0xFF0A0E1A);

  /// Professional shell palette for main chrome and commerce surfaces.
  static const Color shellBackground = Color(0xFF0B1017);
  static const Color shellSurface = Color(0xFF111722);
  static const Color shellSurfaceRaised = Color(0xFF151D2A);
  static const Color shellOverlay = Color(0xFF0D131C);
  static const Color shellBorder = Color(0xFF273243);
  static const Color shellAccent = Color(0xFFB9C7DA);
  static const Color shellAccentSoft = Color(0xFF8FA2BB);
  static const Color shellText = Color(0xFFE7EDF5);
  static const Color shellTextMuted = Color(0xFF9AA8BA);
  static const Color shellTextSubtle = Color(0xFF6F7E92);
  static const Color ppvAccent = Color(0xFFD8B26A);
  static const Color ppvSurface = Color(0xFF101A27);
  static const Color ppvSurfaceRaised = Color(0xFF162234);
  static const Color ppvSuccess = Color(0xFF37E8A8);
  static const Color ppvWarning = Color(0xFFFFC977);

  /// Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF); // 70%
  static const Color textMuted = Color(0x80FFFFFF); // 50%
  static const Color textDisabled = Color(0x4DFFFFFF); // 30%

  // ═══════════════════════════════════════════════════════════════════════════
  // SPORT-SPECIFIC COLOR PALETTES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sport accent colors — used in PPV cards, fight posters, & sport filters
  static const Map<String, Color> sportAccent = {
    'ufc': Color(0xFFD4AF37),
    'mma': neonCyan,
    'boxing': Color(0xFF4CAF50),
    'bkfc': neonRed,
    'kickboxing': neonOrange,
    'muay_thai': neonGold,
    'wrestling': neonPurple,
    'bare_knuckle': neonRed,
    'drone_racing': neonOrange,
  };

  /// Lookup helper — falls back to neonCyan
  static Color sportColor(String sport) =>
      sportAccent[sport.toLowerCase().replaceAll(' ', '_')] ?? neonCyan;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);
  static const Curve animCurve = Curves.easeOutCubic;
}

/// Glass card decoration builder
class GlassDecoration {
  GlassDecoration._();

  /// Standard glass card decoration
  static BoxDecoration card({
    Color accent = DesignTokens.neonCyan,
    bool isHovered = false,
    bool hasGlow = false,
    double radius = DesignTokens.radiusMedium,
  }) {
    return BoxDecoration(
      color: accent.withValues(
        alpha: isHovered
            ? DesignTokens.glassOpacityHover
            : DesignTokens.glassOpacity,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: accent.withValues(
          alpha: isHovered
              ? DesignTokens.glassBorderOpacityHover
              : DesignTokens.glassBorderOpacity,
        ),
        width: DesignTokens.borderThin,
      ),
      boxShadow: hasGlow
          ? [
              BoxShadow(
                color: accent.withValues(alpha: DesignTokens.glowOpacity),
                blurRadius: DesignTokens.glowRadius,
              ),
            ]
          : null,
    );
  }

  /// Top glow strip decoration
  static BoxDecoration topGlowStrip({
    Color accent = DesignTokens.neonCyan,
    double radius = DesignTokens.radiusMedium,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withValues(alpha: 0.3), accent.withValues(alpha: 0.0)],
        stops: const [0.0, 0.15],
      ),
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

/// Typography styles following design tokens
class DFCTextStyles {
  DFCTextStyles._();

  static const TextStyle title = TextStyle(
    color: DesignTokens.textPrimary,
    fontSize: DesignTokens.fontSizeTitle,
    fontWeight: DesignTokens.fontWeightTitle,
    letterSpacing: 0.3,
  );

  static const TextStyle titleLarge = TextStyle(
    color: DesignTokens.textPrimary,
    fontSize: DesignTokens.fontSizeTitleLarge,
    fontWeight: DesignTokens.fontWeightTitle,
    letterSpacing: 0.3,
  );

  static const TextStyle subtitle = TextStyle(
    color: DesignTokens.textMuted,
    fontSize: DesignTokens.fontSizeSubtitle,
  );

  static const TextStyle subtitleLarge = TextStyle(
    color: DesignTokens.textMuted,
    fontSize: DesignTokens.fontSizeSubtitleLarge,
  );

  static const TextStyle statNumber = TextStyle(
    color: DesignTokens.textPrimary,
    fontSize: DesignTokens.fontSizeStatLarge,
    fontWeight: DesignTokens.fontWeightStat,
    letterSpacing: -0.5,
  );

  static const TextStyle statNumberSmall = TextStyle(
    color: DesignTokens.textPrimary,
    fontSize: DesignTokens.fontSizeStatSmall,
    fontWeight: DesignTokens.fontWeightStat,
    letterSpacing: -0.5,
  );

  static const TextStyle body = TextStyle(
    color: DesignTokens.textSecondary,
    fontSize: DesignTokens.fontSizeBody,
  );

  static const TextStyle caption = TextStyle(
    color: DesignTokens.textMuted,
    fontSize: DesignTokens.fontSizeCaption,
  );

  static const TextStyle label = TextStyle(
    color: DesignTokens.textMuted,
    fontSize: DesignTokens.fontSizeCaption,
    letterSpacing: 0.5,
  );
}
