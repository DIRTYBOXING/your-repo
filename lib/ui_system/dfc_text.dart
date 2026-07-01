import 'package:flutter/material.dart';
import 'dfc_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC UI SYSTEM — Typography
/// ═══════════════════════════════════════════════════════════════════════════

class DfcText {
  DfcText._();

  // ── Titles ──
  static TextStyle titleHero({Color? color}) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
    color: color ?? DfcColors.textPrimary,
    height: 1.1,
  );

  static TextStyle titleLarge({Color? color}) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 1,
    color: color ?? DfcColors.textPrimary,
    height: 1.2,
  );

  static TextStyle titleMedium({Color? color}) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: color ?? DfcColors.textPrimary,
    height: 1.3,
  );

  static TextStyle titleSmall({Color? color}) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: color ?? DfcColors.textPrimary,
    height: 1.3,
  );

  // ── Body text ──
  static TextStyle bodyLarge({Color? color}) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: color ?? DfcColors.textSecondary,
    height: 1.5,
  );

  static TextStyle bodyMedium({Color? color}) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: color ?? DfcColors.textSecondary,
    height: 1.5,
  );

  static TextStyle bodySmall({Color? color}) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: color ?? DfcColors.textTertiary,
    height: 1.4,
  );

  // ── Labels & badges ──
  static TextStyle labelBold({Color? color}) => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
    color: color ?? DfcColors.textPrimary,
  );

  static TextStyle labelMedium({Color? color}) => TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: color ?? DfcColors.textSecondary,
  );

  static TextStyle labelSmall({Color? color}) => TextStyle(
    fontSize: 7,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: color ?? DfcColors.textTertiary,
  );

  // ── Special: Micro stat ──
  static TextStyle microStat({Color? color}) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: color ?? DfcColors.textPrimary,
  );

  // ── Special: Button text ──
  static TextStyle buttonPrimary({Color? color}) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
    color: color ?? Colors.black,
  );

  static TextStyle buttonSecondary({Color? color}) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: color ?? DfcColors.textPrimary,
  );

  // ── Helper: Gradient text ──
  static Widget gradientText(
    String text, {
    required TextStyle style,
    required List<Color> colors,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          LinearGradient(colors: colors).createShader(bounds),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
