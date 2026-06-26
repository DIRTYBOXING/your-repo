import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/design_tokens.dart';

class DFCTabIntroHeader extends StatelessWidget {
  const DFCTabIntroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accent = DesignTokens.neonCyan,
    this.leading,
    this.trailing,
    this.topInset = 56,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget? leading;
  final Widget? trailing;
  final double topInset;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final useShellV2 = AppConstants.featureShellV2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedLayout = constraints.maxWidth < 360;

        return Container(
          margin: margin.copyWith(top: margin.top + topInset),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: useShellV2
                ? DesignTokens.shellSurface.withValues(alpha: 0.98)
                : DesignTokens.bgOverlay.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: useShellV2
                  ? DesignTokens.shellBorder
                  : accent.withValues(alpha: 0.2),
            ),
          ),
          child: useStackedLayout
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (leading != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: leading,
                          ),
                        ],
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: useShellV2
                                ? DesignTokens.shellSurfaceRaised
                                : accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: useShellV2
                                ? Border.all(color: DesignTokens.shellBorder)
                                : null,
                          ),
                          child: Icon(icon, color: accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HeaderCopy(
                            title: title,
                            subtitle: subtitle,
                            useShellV2: useShellV2,
                          ),
                        ),
                      ],
                    ),
                    if (trailing != null) ...[
                      const SizedBox(height: 14),
                      Align(alignment: Alignment.centerLeft, child: trailing),
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leading != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: leading,
                      ),
                    ],
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: useShellV2
                            ? DesignTokens.shellSurfaceRaised
                            : accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: useShellV2
                            ? Border.all(color: DesignTokens.shellBorder)
                            : null,
                      ),
                      child: Icon(icon, color: accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeaderCopy(
                        title: title,
                        subtitle: subtitle,
                        useShellV2: useShellV2,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      Flexible(child: trailing!),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _HeaderCopy extends StatelessWidget {
  const _HeaderCopy({
    required this.title,
    required this.subtitle,
    required this.useShellV2,
  });

  final String title;
  final String subtitle;
  final bool useShellV2;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: useShellV2 ? DesignTokens.shellText : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: useShellV2
                ? DesignTokens.shellTextMuted
                : Colors.white.withValues(alpha: 0.68),
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
