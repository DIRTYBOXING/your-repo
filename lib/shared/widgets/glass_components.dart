import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GLASS COMPONENTS - Glassmorphism UI Components
// ═══════════════════════════════════════════════════════════════════════════

/// GlassPanel widget for glassmorphism effect with neon glow.
/// Used in premium dashboard panels.
class GlassPanel extends StatelessWidget {
  final Color glowColor;
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsets padding;
  final double borderRadius;
  final Gradient? gradient;

  const GlassPanel({
    super.key,
    required this.glowColor,
    required this.child,
    this.blur = 16.0,
    this.opacity = 0.18,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 14,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final panelDecoration = BoxDecoration(
      // On web use a more opaque background so content is visible without blur
      color: kIsWeb
          ? glowColor.withValues(alpha: 0.28)
          : glowColor.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.35),
          blurRadius: 18,
          spreadRadius: 2,
        ),
      ],
      border: Border.all(color: glowColor.withValues(alpha: 0.32), width: 1.2),
      gradient:
          gradient ??
          LinearGradient(
            colors: kIsWeb
                ? [
                    glowColor.withValues(alpha: 0.30),
                    const Color(0xFF0A1628).withValues(alpha: 0.85),
                    glowColor.withValues(alpha: 0.18),
                  ]
                : [
                    glowColor.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.08),
                    glowColor.withValues(alpha: 0.12),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
    );

    // Skip BackdropFilter on web — causes rendering artifacts in Flutter web
    if (kIsWeb) {
      return Container(
        padding: padding,
        decoration: panelDecoration,
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          // Glass blur effect (native only)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(color: Colors.transparent),
          ),
          Container(
            padding: padding,
            decoration: panelDecoration,
            child: child,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GlassCard - Slim glass card with accent glow
// ═══════════════════════════════════════════════════════════════════════════
class GlassCard extends StatelessWidget {
  final Color accent;
  final double? maxHeight;
  final Widget child;

  const GlassCard({
    super.key,
    required this.accent,
    this.maxHeight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: maxHeight != null
          ? BoxConstraints(maxHeight: maxHeight!)
          : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CollapsiblePanel - Expandable section with glass styling
// ═══════════════════════════════════════════════════════════════════════════
class CollapsiblePanel extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final bool initiallyExpanded;
  final String? subtitle;
  final Widget child;

  const CollapsiblePanel({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    this.initiallyExpanded = false,
    this.subtitle,
    required this.child,
  });

  @override
  State<CollapsiblePanel> createState() => _CollapsiblePanelState();
}

class _CollapsiblePanelState extends State<CollapsiblePanel> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: widget.accent.withValues(alpha: 0.06),
        border: Border.all(
          color: widget.accent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: DesignTokens.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: const TextStyle(
                              color: DesignTokens.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: widget.accent.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PillChip - Small pill-shaped label chip
// ═══════════════════════════════════════════════════════════════════════════
class PillChip extends StatelessWidget {
  final String label;
  final Color accent;
  final bool isSmall;

  const PillChip({
    super.key,
    required this.label,
    required this.accent,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: accent.withValues(alpha: 0.15),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// QuickStatCard - Small stat indicator card
// ═══════════════════════════════════════════════════════════════════════════
class QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const QuickStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: DesignTokens.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// StatRow - Label-value row for stats with icon
// ═══════════════════════════════════════════════════════════════════════════
class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const StatRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: accent.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: DesignTokens.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PillButton - Rounded action button
// ═══════════════════════════════════════════════════════════════════════════
class PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onPressed;

  const PillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
