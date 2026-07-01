import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC UI SYSTEM — 2026 Compact System Colors
/// ═══════════════════════════════════════════════════════════════════════════
///
/// RULE: No giant empty cards. Use glass panels (opacity 0.03–0.07).
/// Borders neon thin 0.6px. Soft glow only on hover.

class DfcColors {
  DfcColors._();

  // ── Primary neon palette ──
  static const neonBlue = Color(0xFF00D9FF);
  static const neonCyan = Color(0xFF00FFCC);
  static const neonGreen = Color(0xFF00FF88);
  static const neonOrange = Color(0xFFFF6B35);
  static const neonRed = Color(0xFFFF2D55);
  static const neonPurple = Color(0xFFBF5AF2);
  static const neonMagenta = Color(0xFFFF2D92);
  static const neonYellow = Color(0xFFFFD60A);

  // ── Glass panel system ──
  static Color glassLight = Colors.white.withValues(alpha: 0.03);
  static Color glassMedium = Colors.white.withValues(alpha: 0.05);
  static Color glassHeavy = Colors.white.withValues(alpha: 0.07);

  // ── Border system ──
  static Color borderSubtle = Colors.white.withValues(alpha: 0.08);
  static Color borderMedium = Colors.white.withValues(alpha: 0.15);
  static Color borderBright = Colors.white.withValues(alpha: 0.25);

  // ── Text hierarchy ──
  static Color textPrimary = Colors.white.withValues(alpha: 0.95);
  static Color textSecondary = Colors.white.withValues(alpha: 0.65);
  static Color textTertiary = Colors.white.withValues(alpha: 0.4);
  static Color textDisabled = Colors.white.withValues(alpha: 0.2);

  // ── Background ──
  static const bgDeep = Color(0xFF020508);
  static const bgDark = Color(0xFF0A0E14);
  static const bgMedium = Color(0xFF121820);

  // ── Status colors ──
  static const statusSuccess = Color(0xFF00FF88);
  static const statusWarning = Color(0xFFFFD60A);
  static const statusError = Color(0xFFFF2D55);
  static const statusInfo = Color(0xFF00D9FF);

  // ── Helper: Neon glow with opacity ──
  static Color neonGlow(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // ── Helper: Dynamic border based on accent ──
  static BoxBorder neonBorder(Color accentColor, {double opacity = 0.15}) {
    return Border.all(
      color: accentColor.withValues(alpha: opacity),
      width: 0.6,
    );
  }

  // ── Helper: Glass with neon accent ──
  static BoxDecoration glassBox({
    required Color accentColor,
    double glassOpacity = 0.03,
    double borderOpacity = 0.15,
    double glowOpacity = 0.1,
    double glowBlur = 12,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: glassOpacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: accentColor.withValues(alpha: borderOpacity),
        width: 0.6,
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withValues(alpha: glowOpacity),
          blurRadius: glowBlur,
        ),
      ],
    );
  }

  // ── Helper: Hover state glass (for desktop) ──
  static BoxDecoration glassBoxHover({
    required Color accentColor,
    double glassOpacity = 0.06,
    double borderOpacity = 0.3,
    double glowOpacity = 0.2,
    double glowBlur = 20,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: glassOpacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: accentColor.withValues(alpha: borderOpacity),
        width: 0.8,
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withValues(alpha: glowOpacity),
          blurRadius: glowBlur,
          spreadRadius: 2,
        ),
      ],
    );
  }
}
