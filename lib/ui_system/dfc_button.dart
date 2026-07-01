import 'package:flutter/material.dart';
import 'dfc_colors.dart';
import '../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC UI SYSTEM — Reusable Button Component
/// ═══════════════════════════════════════════════════════════════════════════

enum DfcButtonSize { small, medium, large }

class DfcButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color accentColor;
  final DfcButtonSize size;
  final IconData? icon;
  final bool fullWidth;

  const DfcButton({
    required this.label,
    required this.onPressed,
    this.accentColor = DfcColors.neonCyan,
    this.size = DfcButtonSize.medium,
    this.icon,
    this.fullWidth = false,
    super.key,
  });

  @override
  State<DfcButton> createState() => _DfcButtonState();
}

class _DfcButtonState extends State<DfcButton> {
  bool _hovered = false;
  bool _pressed = false;

  double get _height {
    switch (widget.size) {
      case DfcButtonSize.small:
        return 32;
      case DfcButtonSize.medium:
        return 40;
      case DfcButtonSize.large:
        return 48;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case DfcButtonSize.small:
        return 10;
      case DfcButtonSize.medium:
        return 12;
      case DfcButtonSize.large:
        return 14;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case DfcButtonSize.small:
        return 14;
      case DfcButtonSize.medium:
        return 16;
      case DfcButtonSize.large:
        return 18;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: _height,
          width: widget.fullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: widget.size == DfcButtonSize.small
                ? DesignTokens.spacingM
                : DesignTokens.spacingL,
          ),
          decoration: BoxDecoration(
            color: isDisabled
                ? DfcColors.glassLight
                : _hovered
                ? widget.accentColor.withValues(alpha: 0.2)
                : widget.accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            border: Border.all(
              color: isDisabled
                  ? DfcColors.borderSubtle
                  : _hovered
                  ? widget.accentColor.withValues(alpha: 0.5)
                  : widget.accentColor.withValues(alpha: 0.3),
              width: 0.6,
            ),
            boxShadow: _hovered && !isDisabled
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: widget.fullWidth
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: _iconSize,
                  color: isDisabled
                      ? DfcColors.textDisabled
                      : widget.accentColor,
                ),
                const SizedBox(width: DesignTokens.spacingXS),
              ],
              Transform.scale(
                scale: _pressed ? 0.95 : 1.0,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: isDisabled
                        ? DfcColors.textDisabled
                        : widget.accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC ICON BUTTON — Micro action button
/// ═══════════════════════════════════════════════════════════════════════════

class DfcIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color accentColor;
  final double size;

  const DfcIconButton({
    required this.icon,
    required this.onPressed,
    this.accentColor = DfcColors.neonCyan,
    this.size = 32,
    super.key,
  });

  @override
  State<DfcIconButton> createState() => _DfcIconButtonState();
}

class _DfcIconButtonState extends State<DfcIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _hovered
                ? widget.accentColor.withValues(alpha: 0.15)
                : DfcColors.glassLight,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            border: Border.all(
              color: _hovered
                  ? widget.accentColor.withValues(alpha: 0.4)
                  : DfcColors.borderSubtle,
              width: 0.6,
            ),
          ),
          child: Icon(
            widget.icon,
            size: widget.size * 0.5,
            color: widget.accentColor,
          ),
        ),
      ),
    );
  }
}
