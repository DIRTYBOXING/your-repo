import 'dart:ui';
import 'package:flutter/material.dart';

class DfcGlassPanel extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final Color overlayColor;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final double? width;

  const DfcGlassPanel({
    super.key,
    required this.child,
    this.blurSigma = 24.0, // Apple-grade high blur
    this.overlayColor = const Color(0x40000000), // 25% black for contrast
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;

    return Container(
      margin: margin,
      height: height,
      width: width,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: overlayColor,
              border:
                  border ??
                  Border.all(color: Colors.white.withValues(alpha: 0.08)),
              borderRadius: radius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
