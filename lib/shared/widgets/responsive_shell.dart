import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC RESPONSIVE SHELL & BREAKPOINTS
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Breakpoints:
///   compact  : < 600   (phones)
///   medium   : 600–899 (tablets portrait, foldables)
///   expanded : ≥ 900   (tablets landscape, desktops)
///
/// Widgets:
///   ResponsiveShell   — max-width wrapper with adaptive padding
///   DFCResponsiveGrid — auto-column grid that follows breakpoints
///   DFCBreakpoints    — static helpers for LayoutBuilder/MediaQuery
/// ═══════════════════════════════════════════════════════════════════════════

class DFCBreakpoints {
  DFCBreakpoints._();

  static const double compact = 600;
  static const double medium = 900;

  /// Returns true if width is in the compact range (< 600)
  static bool isCompact(double width) => width < compact;

  /// Returns true if width is in the medium range (600–899)
  static bool isMedium(double width) => width >= compact && width < medium;

  /// Returns true if width is in the expanded range (≥ 900)
  static bool isExpanded(double width) => width >= medium;

  /// Suggested column count for the given width
  static int columns(double width) {
    if (width >= medium) return 3;
    if (width >= compact) return 2;
    return 1;
  }

  /// Adaptive horizontal padding
  static double horizontalPadding(double width) {
    if (width >= medium) return 32;
    if (width >= compact) return 24;
    return 16;
  }
}

class ResponsiveShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveShell({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final hp = DFCBreakpoints.horizontalPadding(width);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding ?? EdgeInsets.symmetric(horizontal: hp),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Adaptive grid that switches column count based on available width.
///
/// Usage:
///   DFCResponsiveGrid(
///     children: [CardA(), CardB(), CardC(), CardD()],
///   )
class DFCResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? overrideColumns;

  const DFCResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.overrideColumns,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols =
            overrideColumns ?? DFCBreakpoints.columns(constraints.maxWidth);
        final itemWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth.clamp(0, constraints.maxWidth),
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}
