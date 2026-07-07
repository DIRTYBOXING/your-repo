import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Standard DFC surface card — a rounded, bordered container used across
/// community and dashboard screens.
class DfcCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? accent;

  const DfcCard({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.padding,
    this.margin,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? DesignTokens.neonCyan;
    return Container(
      height: height,
      width: width,
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}
