import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC GRADIENT PANEL — Neon Gradient Container with Glass Blur
/// ═══════════════════════════════════════════════════════════════════════════
///
/// A promotional / hero panel supporting:
///   • Multi-stop gradient backgrounds
///   • Glass blur overlay
///   • Animated hover scale + border glow
///   • Optional accent stripe (top or left)
///
/// Usage:
///   DFCGradientPanel(
///     gradient: LinearGradient(colors: [neonCyan, neonMagenta]),
///     child: Text('Pro Feature'),
///   )
/// ═══════════════════════════════════════════════════════════════════════════

class DFCGradientPanel extends StatefulWidget {
  final Widget child;
  final Gradient? gradient;
  final Color accent;
  final EdgeInsets padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool enableHover;
  final bool hasAccentStripe;

  const DFCGradientPanel({
    super.key,
    required this.child,
    this.gradient,
    this.accent = DesignTokens.neonCyan,
    this.padding = const EdgeInsets.all(DesignTokens.cardPaddingMedium),
    this.borderRadius = DesignTokens.radiusMedium,
    this.onTap,
    this.enableHover = true,
    this.hasAccentStripe = true,
  });

  @override
  State<DFCGradientPanel> createState() => _DFCGradientPanelState();
}

class _DFCGradientPanelState extends State<DFCGradientPanel> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.98 : (_hovered ? 1.01 : 1.0);
    final defaultGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        widget.accent.withValues(alpha: 0.15),
        widget.accent.withValues(alpha: 0.04),
      ],
    );

    return MouseRegion(
      onEnter: widget.enableHover
          ? (_) => setState(() => _hovered = true)
          : null,
      onExit: widget.enableHover
          ? (_) => setState(() => _hovered = false)
          : null,
      child: GestureDetector(
        onTapDown: widget.onTap != null
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.onTap != null
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap!();
              }
            : null,
        onTapCancel: widget.onTap != null
            ? () => setState(() => _pressed = false)
            : null,
        child: AnimatedContainer(
          duration: DesignTokens.animFast,
          curve: DesignTokens.animCurve,
          transform: Matrix4.identity()..scaleByDouble(scale, scale, 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: widget.gradient ?? defaultGradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.accent.withValues(
                alpha: _hovered
                    ? DesignTokens.glassBorderOpacityHover
                    : DesignTokens.glassBorderOpacity,
              ),
              width: DesignTokens.borderThin,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.2),
                      blurRadius: DesignTokens.glowRadius,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: _buildPanelContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelContent() {
    final content = Stack(
      children: [
        if (widget.hasAccentStripe)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.accent, widget.accent.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ),
        Padding(padding: widget.padding, child: widget.child),
      ],
    );

    // Skip BackdropFilter on web — causes invisible/broken panels
    if (kIsWeb) return content;

    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: DesignTokens.glassBlurLight,
        sigmaY: DesignTokens.glassBlurLight,
      ),
      child: content,
    );
  }
}
