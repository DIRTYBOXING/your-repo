import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC SHIMMER — Skeleton loader with neon pulse animation
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Drop-in shimmer placeholder while data loads.
///
/// Variants:
///   DFCShimmer.card()     — full glass card skeleton
///   DFCShimmer.line()     — single text line
///   DFCShimmer.circle()   — avatar / icon placeholder
///   DFCShimmer.statGrid() — 2×2 stat card grid skeleton
/// ═══════════════════════════════════════════════════════════════════════════

class DFCShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;

  const DFCShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
    this.baseColor = const Color(0xFF1A2235),
    this.highlightColor = const Color(0xFF2A3550),
  });

  /// Single text line placeholder
  const DFCShimmer.line({
    super.key,
    this.width = 120,
    this.height = 12,
    this.borderRadius = 6,
  }) : baseColor = const Color(0xFF1A2235),
       highlightColor = const Color(0xFF2A3550);

  /// Circle placeholder (avatar)
  factory DFCShimmer.circle({Key? key, double size = 40}) {
    return DFCShimmer(
      key: key,
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }

  /// Full card skeleton
  static Widget card({Key? key, double height = 120}) {
    return DFCShimmer(
      key: key,
      height: height,
      borderRadius: DesignTokens.radiusMedium,
    );
  }

  /// 2×2 stat grid skeleton
  static Widget statGrid({Key? key}) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(4, (i) {
        return SizedBox(
          width: 160,
          child: DFCShimmer(
            key: key != null ? ValueKey('$key-$i') : null,
            height: 80,
            borderRadius: DesignTokens.radiusMedium,
          ),
        );
      }),
    );
  }

  @override
  State<DFCShimmer> createState() => _DFCShimmerState();
}

class _DFCShimmerState extends State<DFCShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Convenience builder: wraps content with a shimmer skeleton when loading
class DFCShimmerWrap extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Widget? shimmerPlaceholder;

  const DFCShimmerWrap({
    super.key,
    required this.isLoading,
    required this.child,
    this.shimmerPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;
    return shimmerPlaceholder ?? DFCShimmer.card();
  }
}
