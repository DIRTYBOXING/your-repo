import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// NEON GLOW EFFECTS - Premium Neon Glows for DFC
/// Reusable glow utilities for cards, buttons, and premium UI elements
/// ═══════════════════════════════════════════════════════════════════════════
class NeonGlow {
  NeonGlow._();

  /// Soft glow - subtle, elegant
  static List<BoxShadow> softCyan() => [
    BoxShadow(
      color: AppColors.glowCyanSoft,
      blurRadius: 12,
      spreadRadius: 1,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> softMagenta() => [
    BoxShadow(
      color: AppColors.glowMagentaSoft,
      blurRadius: 12,
      spreadRadius: 1,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> softLime() => [
    BoxShadow(
      color: AppColors.glowLimeSoft,
      blurRadius: 12,
      spreadRadius: 1,
      offset: const Offset(0, 2),
    ),
  ];

  /// Medium glow - noticeable, premium
  static List<BoxShadow> mediumCyan() => [
    BoxShadow(
      color: AppColors.glowCyanMedium,
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.glowCyanSoft,
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> mediumMagenta() => [
    BoxShadow(
      color: AppColors.glowMagentaMedium,
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.glowMagentaSoft,
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> mediumLime() => [
    BoxShadow(
      color: AppColors.glowLimeMedium,
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.glowLimeSoft,
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 1),
    ),
  ];

  /// Hard glow - intense, CTA-ready
  static List<BoxShadow> hardCyan() => [
    BoxShadow(
      color: AppColors.glowCyanHard,
      blurRadius: 24,
      spreadRadius: 4,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.glowCyanMedium,
      blurRadius: 12,
      spreadRadius: 1,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> hardMagenta() => [
    BoxShadow(
      color: AppColors.glowMagentaHard,
      blurRadius: 24,
      spreadRadius: 4,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.glowMagentaMedium,
      blurRadius: 12,
      spreadRadius: 1,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> hardLime() => [
    BoxShadow(
      color: AppColors.glowLimeHard,
      blurRadius: 24,
      spreadRadius: 4,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.glowLimeMedium,
      blurRadius: 12,
      spreadRadius: 1,
      offset: const Offset(0, 2),
    ),
  ];

  /// Pulse animation glow (for buttons, CTAs)
  static List<BoxShadow> pulsingCyan({double intensity = 1.0}) => [
    BoxShadow(
      color: AppColors.glowCyanMedium.withValues(alpha: intensity),
      blurRadius: 20 * intensity,
      spreadRadius: 2 * intensity,
      offset: Offset(0, 4 * intensity),
    ),
  ];

  static List<BoxShadow> pulsingMagenta({double intensity = 1.0}) => [
    BoxShadow(
      color: AppColors.glowMagentaMedium.withValues(alpha: intensity),
      blurRadius: 20 * intensity,
      spreadRadius: 2 * intensity,
      offset: Offset(0, 4 * intensity),
    ),
  ];
}

/// ═══════════════════════════════════════════════════════════════════════════
/// NEON BORDER - Glowing Borders for Cards & Buttons
/// ═══════════════════════════════════════════════════════════════════════════
class NeonBorder {
  NeonBorder._();

  static BorderSide cyan({double width = 1.5}) =>
      BorderSide(color: AppColors.neonCyan, width: width);

  static BorderSide magenta({double width = 1.5}) =>
      BorderSide(color: AppColors.neonMagenta, width: width);

  static BorderSide lime({double width = 1.5}) =>
      BorderSide(color: AppColors.neonLime, width: width);

  static BorderSide violet({double width = 1.5}) =>
      BorderSide(color: AppColors.neonViolet, width: width);

  static BorderSide orange({double width = 1.5}) =>
      BorderSide(color: AppColors.neonOrange, width: width);

  /// Faded borders (for secondary elements)
  static BorderSide fadedCyan({double width = 1.0}) =>
      BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.4), width: width);

  static BorderSide fadedMagenta({double width = 1.0}) =>
      BorderSide(color: AppColors.neonMagenta.withValues(alpha: 0.4), width: width);
}
