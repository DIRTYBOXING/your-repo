import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC STAT CARD — Compact Animated Stat Display
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Self-contained stat widget with:
///   • Animated hover/tap scale + glow
///   • Optional trend indicator (up/down/neutral)
///   • Optional sparkline or icon
///   • Respects design_tokens.dart
///
/// Usage:
///   DFCStatCard(
///     value: '87%',
///     label: 'Win Rate',
///     accent: DesignTokens.neonGreen,
///     trend: DFCTrend.up,
///     trendLabel: '+3.2%',
///   )
/// ═══════════════════════════════════════════════════════════════════════════

enum DFCTrend { up, down, neutral }

class DFCStatCard extends StatefulWidget {
  final String value;
  final String label;
  final Color accent;
  final IconData? icon;
  final DFCTrend trend;
  final String? trendLabel;
  final VoidCallback? onTap;
  final Widget? trailing;

  const DFCStatCard({
    super.key,
    required this.value,
    required this.label,
    this.accent = DesignTokens.neonCyan,
    this.icon,
    this.trend = DFCTrend.neutral,
    this.trendLabel,
    this.onTap,
    this.trailing,
  });

  @override
  State<DFCStatCard> createState() => _DFCStatCardState();
}

class _DFCStatCardState extends State<DFCStatCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.97 : (_hovered ? 1.02 : 1.0);
    final glowAlpha = _hovered ? 0.18 : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: DesignTokens.animFast,
          curve: DesignTokens.animCurve,
          transform: Matrix4.identity()..scaleByDouble(scale, scale, 1.0, 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
          decoration:
              GlassDecoration.card(
                accent: widget.accent,
                isHovered: _hovered,
                hasGlow: _hovered,
              ).copyWith(
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: widget.accent.withValues(alpha: glowAlpha),
                          blurRadius: DesignTokens.glowRadius,
                        ),
                      ]
                    : null,
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon + Trend row
              Row(
                children: [
                  if (widget.icon != null)
                    Icon(widget.icon, color: widget.accent, size: 18),
                  if (widget.icon != null)
                    const SizedBox(width: DesignTokens.spacingS),
                  const Spacer(),
                  if (widget.trendLabel != null) _buildTrend(),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
              const SizedBox(height: DesignTokens.spacingM),
              // Value
              Text(
                widget.value,
                style: TextStyle(
                  color: widget.accent,
                  fontSize: DesignTokens.fontSizeStatLarge,
                  fontWeight: DesignTokens.fontWeightStat,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXS),
              // Label
              Text(
                widget.label,
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrend() {
    final isUp = widget.trend == DFCTrend.up;
    final isDown = widget.trend == DFCTrend.down;
    final trendColor = isUp
        ? DesignTokens.success
        : isDown
        ? DesignTokens.error
        : DesignTokens.textMuted;
    final trendIcon = isUp
        ? Icons.trending_up
        : isDown
        ? Icons.trending_down
        : Icons.trending_flat;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(trendIcon, color: trendColor, size: 14),
        const SizedBox(width: 3),
        Text(
          widget.trendLabel!,
          style: TextStyle(
            color: trendColor,
            fontSize: DesignTokens.fontSizeMicro,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
