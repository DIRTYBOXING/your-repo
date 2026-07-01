import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Neon-bordered card with subtle glow effect
/// Standard card component for list items and feature cards
class NeonCard extends StatelessWidget {
  final Widget child;
  final Color glow;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double borderRadius;

  const NeonCard({
    super.key,
    required this.child,
    this.glow = AppColors.neonBlue,
    this.padding = const EdgeInsets.all(10),
    this.onTap,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: glow.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
