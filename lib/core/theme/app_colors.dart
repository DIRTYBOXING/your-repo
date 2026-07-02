import 'package:flutter/material.dart';

/// PREMIUM NEON PALETTE for DataFightCentral
/// Dark + Cyber + Premium + Social‑Ready
/// Designed for PPV, Creator Economy, Combat Sports Discovery
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY NEON ACCENTS (Social Engine Colors)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color neonCyan = Color(0xFF00FFF0); // TikTok-style primary
  static const Color neonMagenta = Color(0xFFFF0080); // PPV hero color
  static const Color neonLime = Color(0xFF00FF9D); // Engagement/Follow
  static const Color neonViolet = Color(0xFFB100FF); // Creator mode
  static const Color neonOrange = Color(0xFFFF9800); // CTAs & urgency

  // ═══════════════════════════════════════════════════════════════════════════
  // SECONDARY NEON (Extended Palette)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color neonBlue = Color(0xFF00D9FF);
  static const Color neonGreen = Color(0xFF00FF9D);
  static const Color neonRed = Color(0xFFFF2D55);
  static const Color neonPink = Color(0xFFFF1493);
  static const Color neonAmber = Color(0xFFFFCA28);
  static const Color neonSky = Color(0xFF2196F3);

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS (Status & Action)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color successGreen = Color(0xFF00FF9D);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color dangerRed = Color(0xFFFF2D55);
  static const Color infoBlue = Color(0xFF00D9FF);

  // ═══════════════════════════════════════════════════════════════════════════
  // SURFACES & BACKGROUNDS (Dark Premium)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color bgPrimary = Color(0xFF060A14); // Jet black base
  static const Color bgSecondary = Color(0xFF0C1226); // Subtle lift
  static const Color bgTertiary = Color(0xFF131830); // Card base
  static const Color surfaceElevated = Color(0xFF1C2240); // Highest elevation
  static const Color cardBackground = Color(0xFF1A2235); // Card surface

  // Glass panel backgrounds (semi-transparent overlays)
  static const Color glassLight = Color(0x0DFFFFFF); // 5% white
  static const Color glassMedium = Color(0x14FFFFFF); // 8% white

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDERS & STROKES
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color borderLight = Color(0xFF1D2B4F); // Subtle
  static const Color borderMedium = Color(0xFF2A3F66); // Normal
  static const Color borderBold = Color(0xFF3A4F7F); // Prominent

  // Neon borders (glow-ready)
  static const Color borderCyanGlow = Color(0xFF00FFF0);
  static const Color borderMagentaGlow = Color(0xFFFF0080);

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT COLORS (Premium Hierarchy)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color textPrimary = Color(0xFFEAF2FF); // Main text
  static const Color textSecondary = Color(0xFF9AA7C0); // Secondary
  static const Color textTertiary = Color(0xFF566380); // Muted
  static const Color textDisabled = Color(0xFF3D4556); // Disabled

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENTS (Premium Branded)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary CTA gradient (PPV buy button)
  static const LinearGradient gradientPPV = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonMagenta, neonOrange],
  );

  /// Social engagement gradient (Follow, Like, Share)
  static const LinearGradient gradientSocial = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, neonLime],
  );

  /// Creator mode gradient
  static const LinearGradient gradientCreator = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonViolet, neonMagenta],
  );

  /// Background fade
  static const LinearGradient gradientBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgPrimary, bgSecondary, Color(0xFF0A1628)],
  );

  /// Card hover overlay
  static const LinearGradient gradientCardHover = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x0F00FFF0), // Subtle cyan overlay
      Color(0x08FFFFFF), // White highlight
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // GLOW COLORS (Neon Shadow/Aura for Premium Feel)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color glowCyanSoft = Color(0x2600FFF0);
  static const Color glowCyanMedium = Color(0x4600FFF0);
  static const Color glowCyanHard = Color(0x6600FFF0);

  static const Color glowMagentaSoft = Color(0x26FF0080);
  static const Color glowMagentaMedium = Color(0x46FF0080);
  static const Color glowMagentaHard = Color(0x66FF0080);

  static const Color glowLimeSoft = Color(0x2600FF9D);
  static const Color glowLimeMedium = Color(0x4600FF9D);
  static const Color glowLimeHard = Color(0x6600FF9D);

  // ═══════════════════════════════════════════════════════════════════════════
  // ROLE COLORS (Social/Gym/Fighter Identity)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Map<String, Color> roleColors = {
    'fighter': neonCyan,
    'coach': neonOrange,
    'gym': neonViolet,
    'promoter': neonMagenta,
    'sponsor': neonLime,
    'creator': neonViolet,
    'fan': neonBlue,
    'admin': neonAmber,
  };

  static Color getRoleColor(String role) =>
      roleColors[role.toLowerCase()] ?? neonCyan;

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY ALIASES (backward compatibility — do not remove, widely referenced)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color bg = bgPrimary;
  static const Color panel = bgSecondary;
  static const Color surface = bgTertiary;
  static const Color elevated = surfaceElevated;
  static const Color border = borderLight;
  static const Color neonPurple = neonViolet;

  static const LinearGradient neonGrad = LinearGradient(
    colors: [neonBlue, neonGreen],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, neonMagenta],
  );

  static const LinearGradient bgGrad = gradientBg;
}
