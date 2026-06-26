import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';

/// Elevated button with neon glow effect
/// Color defaults to current theme accent
class DfcGlowButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const DfcGlowButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? ThemeController.accent;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: c,
        foregroundColor: Colors.black,
        elevation: 6,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        shadowColor: c.withValues(alpha: 0.6),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
