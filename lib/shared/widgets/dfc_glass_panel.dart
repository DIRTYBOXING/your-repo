import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/app_colors.dart';

/// Glassmorphism panel with blur effect and neon glow
/// Used for elevated content cards throughout the app
class DfcGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? glowColor;
  final double blurSigma;
  final VoidCallback? onTap;

  const DfcGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 12,
    Color? glowColor,
    Color? accent,
    this.blurSigma = 8,
    this.onTap,
  }) : glowColor = glowColor ?? accent;

  @override
  Widget build(BuildContext context) {
    final accent = glowColor ?? ThemeController.accent;

    final panelDecoration = BoxDecoration(
      color: kIsWeb
          ? AppColors.panel.withValues(alpha: 0.85)
          : AppColors.panel.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: accent.withValues(alpha: 0.14), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.08),
          blurRadius: 18,
          spreadRadius: 2,
        ),
      ],
    );

    final content = Container(
      padding: padding,
      decoration: panelDecoration,
      child: child,
    );

    // Skip BackdropFilter on web — causes rendering artifacts
    if (kIsWeb) {
      return GestureDetector(onTap: onTap, child: content);
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      ),
    );
  }
}
