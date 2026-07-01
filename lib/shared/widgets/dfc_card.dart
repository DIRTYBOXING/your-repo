import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC CARD — THE SINGLE UNIVERSAL GLASS CARD FOR THE ENTIRE APP
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Every screen uses this. One component. Consistent forever.
///
/// Variants via [DFCCardStyle]:
///   .standard    — default glass panel
///   .section     — titled section with icon header
///   .stat        — stat display (number + label)
///   .action      — tappable with CTA
///   .banner      — wide promo/announcement banner
///   .pricing     — subscription tier card
///   .pass        — fight pass / ticket card
///   .compact     — minimal padding, inline use
///
/// All honour design_tokens.dart. No rogue styling allowed.
/// ═══════════════════════════════════════════════════════════════════════════

enum DFCCardStyle {
  standard,
  section,
  stat,
  action,
  banner,
  pricing,
  pass,
  compact,
}

class DFCCard extends StatefulWidget {
  // ── Core ──
  final Widget child;
  final DFCCardStyle style;
  final Color accent;
  final VoidCallback? onTap;

  // ── Layout ──
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final double? maxHeight;

  // ── Glass ──
  final bool hasTopGlow;
  final bool hasBottomGradient;
  final bool enableHover;
  final bool enableBlur;
  final double? borderRadius;

  // ── Section header (style == section) ──
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  // ── Stat (style == stat) ──
  final String? statValue;
  final String? statLabel;

  // ── Action (style == action) ──
  final String? ctaText;

  // ── Pass / Banner ──
  final bool isFeatured;
  final bool isLocked;

  const DFCCard({
    super.key,
    required this.child,
    this.style = DFCCardStyle.standard,
    this.accent = DesignTokens.neonCyan,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.maxHeight,
    this.hasTopGlow = false,
    this.hasBottomGradient = false,
    this.enableHover = true,
    this.enableBlur = true,
    this.borderRadius,
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.statValue,
    this.statLabel,
    this.ctaText,
    this.isFeatured = false,
    this.isLocked = false,
  });

  // ── Named constructors for common patterns ──

  /// Standard glass card
  const DFCCard.glass({
    super.key,
    required this.child,
    this.accent = DesignTokens.neonCyan,
    this.onTap,
    this.padding,
    this.margin,
    this.hasTopGlow = true,
    this.enableHover = true,
  }) : style = DFCCardStyle.standard,
       width = null,
       height = null,
       maxHeight = null,
       hasBottomGradient = false,
       enableBlur = true,
       borderRadius = null,
       title = null,
       subtitle = null,
       icon = null,
       trailing = null,
       statValue = null,
       statLabel = null,
       ctaText = null,
       isFeatured = false,
       isLocked = false;

  /// Section card with icon + title header
  const DFCCard.section({
    super.key,
    required this.child,
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
    this.accent = DesignTokens.neonCyan,
    this.onTap,
    this.padding,
    this.margin,
  }) : style = DFCCardStyle.section,
       width = null,
       height = null,
       maxHeight = null,
       hasTopGlow = false,
       hasBottomGradient = false,
       enableHover = true,
       enableBlur = true,
       borderRadius = null,
       statValue = null,
       statLabel = null,
       ctaText = null,
       isFeatured = false,
       isLocked = false;

  /// Stat display card
  const DFCCard.stat({
    super.key,
    required this.statValue,
    required this.statLabel,
    this.accent = DesignTokens.neonCyan,
    this.icon,
    this.onTap,
    this.margin,
  }) : style = DFCCardStyle.stat,
       child = const SizedBox.shrink(),
       width = null,
       height = null,
       maxHeight = null,
       padding = null,
       hasTopGlow = false,
       hasBottomGradient = false,
       enableHover = true,
       enableBlur = true,
       borderRadius = null,
       title = null,
       subtitle = null,
       trailing = null,
       ctaText = null,
       isFeatured = false,
       isLocked = false;

  /// Action card with CTA button
  const DFCCard.action({
    super.key,
    required this.child,
    required this.ctaText,
    this.accent = DesignTokens.neonCyan,
    this.onTap,
    this.title,
    this.subtitle,
    this.icon,
    this.padding,
    this.margin,
  }) : style = DFCCardStyle.action,
       width = null,
       height = null,
       maxHeight = null,
       hasTopGlow = false,
       hasBottomGradient = false,
       enableHover = true,
       enableBlur = true,
       borderRadius = null,
       trailing = null,
       statValue = null,
       statLabel = null,
       isFeatured = false,
       isLocked = false;

  /// Wide banner / announcement
  const DFCCard.banner({
    super.key,
    required this.child,
    this.accent = DesignTokens.neonCyan,
    this.onTap,
    this.isFeatured = false,
    this.padding,
    this.margin,
  }) : style = DFCCardStyle.banner,
       width = null,
       height = null,
       maxHeight = null,
       hasTopGlow = true,
       hasBottomGradient = true,
       enableHover = true,
       enableBlur = true,
       borderRadius = null,
       title = null,
       subtitle = null,
       icon = null,
       trailing = null,
       statValue = null,
       statLabel = null,
       ctaText = null,
       isLocked = false;

  /// Fight pass / ticket card
  const DFCCard.pass({
    super.key,
    required this.child,
    this.accent = DesignTokens.neonCyan,
    this.onTap,
    this.title,
    this.subtitle,
    this.icon,
    this.ctaText,
    this.isFeatured = false,
    this.isLocked = false,
    this.padding,
    this.margin,
  }) : style = DFCCardStyle.pass,
       width = null,
       height = null,
       maxHeight = null,
       hasTopGlow = true,
       hasBottomGradient = true,
       enableHover = true,
       enableBlur = true,
       borderRadius = null,
       trailing = null,
       statValue = null,
       statLabel = null;

  @override
  State<DFCCard> createState() => _DFCCardState();
}

class _DFCCardState extends State<DFCCard> {
  bool _isHovered = false;

  EdgeInsets get _effectivePadding {
    if (widget.padding != null) return widget.padding!;
    switch (widget.style) {
      case DFCCardStyle.compact:
        return const EdgeInsets.all(DesignTokens.cardPaddingSmall);
      case DFCCardStyle.banner:
        return const EdgeInsets.all(DesignTokens.cardPaddingLarge);
      case DFCCardStyle.stat:
        return const EdgeInsets.symmetric(
          horizontal: DesignTokens.cardPaddingMedium,
          vertical: DesignTokens.cardPaddingSmall,
        );
      default:
        return const EdgeInsets.all(DesignTokens.cardPaddingMedium);
    }
  }

  double get _radius => widget.borderRadius ?? DesignTokens.radiusMedium;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.enableHover
          ? (_) => setState(() => _isHovered = true)
          : null,
      onExit: widget.enableHover
          ? (_) => setState(() => _isHovered = false)
          : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DesignTokens.animFast,
          curve: DesignTokens.animCurve,
          width: widget.width,
          height: widget.height,
          margin:
              widget.margin ??
              const EdgeInsets.only(bottom: DesignTokens.spacingM),
          constraints: widget.maxHeight != null
              ? BoxConstraints(maxHeight: widget.maxHeight!)
              : null,
          decoration: BoxDecoration(
            color: widget.accent.withValues(
              alpha: _isHovered
                  ? DesignTokens.glassOpacityHover
                  : DesignTokens.glassOpacity,
            ),
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: widget.accent.withValues(
                alpha: _isHovered
                    ? DesignTokens.glassBorderOpacityHover
                    : DesignTokens.glassBorderOpacity,
              ),
              width: widget.isFeatured
                  ? DesignTokens.borderNormal
                  : DesignTokens.borderThin,
            ),
            boxShadow: (_isHovered || widget.isFeatured)
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(
                        alpha: DesignTokens.glowOpacity,
                      ),
                      blurRadius: DesignTokens.glowRadius,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            // Skip BackdropFilter on web — causes invisible/broken panels
            child: (widget.enableBlur && !kIsWeb)
                ? BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: DesignTokens.glassBlur,
                      sigmaY: DesignTokens.glassBlur,
                    ),
                    child: _buildContent(),
                  )
                : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        // Top glow
        if (widget.hasTopGlow)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.accent.withValues(alpha: 0.15),
                    widget.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        // Bottom gradient
        if (widget.hasBottomGradient)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    widget.accent.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        // Lock overlay
        if (widget.isLocked)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(_radius),
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_outline,
                  color: DesignTokens.textMuted,
                  size: 32,
                ),
              ),
            ),
          ),
        // Main content
        Padding(padding: _effectivePadding, child: _buildByStyle()),
      ],
    );
  }

  Widget _buildByStyle() {
    switch (widget.style) {
      case DFCCardStyle.section:
        return _buildSection();
      case DFCCardStyle.stat:
        return _buildStat();
      case DFCCardStyle.action:
        return _buildAction();
      case DFCCardStyle.pass:
        return _buildPass();
      default:
        return widget.child;
    }
  }

  // ── Section ──
  Widget _buildSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.accent, size: 18),
              const SizedBox(width: DesignTokens.spacingS),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ?? '',
                    style: TextStyle(
                      color: widget.accent,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeMicro,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
        const SizedBox(height: DesignTokens.spacingM),
        widget.child,
      ],
    );
  }

  // ── Stat ──
  Widget _buildStat() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: widget.accent, size: 20),
          const SizedBox(height: DesignTokens.spacingXS),
        ],
        Text(
          widget.statValue ?? '0',
          style: TextStyle(
            color: widget.accent,
            fontSize: DesignTokens.fontSizeStatLarge,
            fontWeight: DesignTokens.fontWeightStat,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.statLabel ?? '',
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: DesignTokens.fontSizeMicro,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Action ──
  Widget _buildAction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) ...[
          Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.accent, size: 18),
                const SizedBox(width: DesignTokens.spacingS),
              ],
              Expanded(
                child: Text(
                  widget.title!,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeTitle,
                    fontWeight: DesignTokens.fontWeightTitle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingXS),
        ],
        if (widget.subtitle != null) ...[
          Text(
            widget.subtitle!,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: DesignTokens.fontSizeSubtitleLarge,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
        ],
        widget.child,
        if (widget.ctaText != null) ...[
          const SizedBox(height: DesignTokens.spacingM),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                border: Border.all(
                  color: widget.accent.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                widget.ctaText!,
                style: TextStyle(
                  color: widget.accent,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Pass ──
  Widget _buildPass() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pass header
        Row(
          children: [
            if (widget.icon != null)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accent.withValues(alpha: 0.12),
                  border: Border.all(
                    color: widget.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(widget.icon, color: widget.accent, size: 22),
              ),
            if (widget.icon != null)
              const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.title != null)
                    Text(
                      widget.title!,
                      style: TextStyle(
                        color: widget.accent,
                        fontSize: DesignTokens.fontSizeTitle,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeSubtitle,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.isLocked)
              const Icon(Icons.lock, color: DesignTokens.textMuted, size: 18),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingM),
        widget.child,
        if (widget.ctaText != null) ...[
          const SizedBox(height: DesignTokens.spacingM),
          SizedBox(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.accent.withValues(alpha: 0.2),
                    widget.accent.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                border: Border.all(
                  color: widget.accent.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                widget.ctaText!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.accent,
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC SECTION HEADER — Reusable section label used above card groups
/// ═══════════════════════════════════════════════════════════════════════════
class DFCSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsets padding;

  const DFCSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.only(
      bottom: DesignTokens.spacingS,
      left: 4,
      right: 4,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: DesignTokens.textMuted, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
