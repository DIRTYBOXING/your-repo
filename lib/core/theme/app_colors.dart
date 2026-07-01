import 'package:flutter/material.dart';

/// Extended color palette for DataFightCentral
/// Includes neon accents, surfaces, and gradients
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // NEON ACCENTS
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color neonBlue = Color(0xFF00D9FF);
  static const Color neonCyan = Color(0xFF00FFF0); // Primary accent
  static const Color neonGreen = Color(0xFF00FF9D);
  static const Color neonRed = Color(0xFFFF2D55);
  static const Color neonMagenta = Color(0xFFFF0080);
  static const Color neonPurple = Color(0xFFB100FF);
  static const Color neonOrange = Color(0xFFFF9800);
  static const Color neonAmber = Color(0xFFFFCA28);
  static const Color neonPink = Color(0xFFFF5722);
  static const Color neonSky = Color(0xFF2196F3);

  // ═══════════════════════════════════════════════════════════════════════════
  // SURFACES
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color bg = Color(0xFF060A14);
  static const Color panel = Color(0xFF0C1226);
  static const Color surface = Color(0xFF131830);
  static const Color elevated = Color(0xFF1C2240);
  static const Color cardBackground = Color(0xFF1A2235);

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDERS
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color border = Color(0xFF1D2B4F);

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color textPrimary = Color(0xFFEAF2FF);
  static const Color textSecondary = Color(0xFF9AA7C0);
  static const Color textTertiary = Color(0xFF566380);

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════
  static const LinearGradient neonGrad = LinearGradient(
    colors: [neonBlue, neonGreen],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, neonMagenta],
  );

  static const LinearGradient bgGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bg, surface, Color(0xFF0A1628)],
  );
}
