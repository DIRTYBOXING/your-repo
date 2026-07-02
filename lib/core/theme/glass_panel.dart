import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// GLASS PANEL - Glassmorphism Widget for Premium DFC UI
/// Apple Vision Pro style frosted glass effect
/// ═══════════════════════════════════════════════════════════════════════════
class GlassPanel extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final double blurStrength;
  final bool hasBorder;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const GlassPanel({
    Key? key,
    this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.backgroundColor,
    this.blurStrength = 12.0,
    this.hasBorder = true,
    this.borderColor,
    this.borderWidth = 1.0,
    this.shadows,
    this.onTap,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: gradient,
              color: backgroundColor ?? AppColors.glassLight,
              border: hasBorder
                  ? Border.all(
                      color: borderColor ?? AppColors.neonCyan.withValues(alpha: 0.2),
                      width: borderWidth,
                    )
                  : null,
              borderRadius: borderRadius,
              boxShadow: shadows,
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// GLASS CARD - Specialized Glass Panel for Cards
/// ═══════════════════════════════════════════════════════════════════════════
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final Color? accentColor;
  final bool withGlow;

  const GlassCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.width,
    this.height,
    this.accentColor,
    this.withGlow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      backgroundColor: AppColors.glassMedium,
      blurStrength: 18,
      borderColor: accentColor?.withValues(alpha: 0.3),
      onTap: onTap,
      child: child,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// GLASS BUTTON - Glassmorphism Button for Premium Feel
/// ═══════════════════════════════════════════════════════════════════════════
class GlassButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? accentColor;
  final double? width;
  final double? height;
  final EdgeInsets padding;

  const GlassButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.accentColor,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  }) : super(key: key);

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: (widget.accentColor ?? AppColors.neonCyan).withValues(alpha: 
                _isHovered ? 0.8 : 0.5,
              ),
              width: 1.5,
            ),
          ),
          child: GlassPanel(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            padding: widget.padding,
            hasBorder: false,
            blurStrength: 12,
            backgroundColor: AppColors.glassMedium.withValues(alpha: 
              _isHovered ? 0.12 : 0.08,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
