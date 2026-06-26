import 'package:flutter/material.dart';
import '../../core/constants/app_logos.dart';
import '../../core/theme/design_tokens.dart';

enum DFCLogoSize { small, medium, large }

/// Cosmic background widget with animated particle effect
class DFCCosmicBackground extends StatefulWidget {
  final int particleCount;
  final Color? primaryColor;
  final Color? secondaryColor;

  const DFCCosmicBackground({
    super.key,
    this.particleCount = 20,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<DFCCosmicBackground> createState() => _DFCCosmicBackgroundState();
}

class _DFCCosmicBackgroundState extends State<DFCCosmicBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.particleCount,
      (index) => AnimationController(
        duration: Duration(seconds: 3 + (index % 6)),
        vsync: this,
      )..repeat(reverse: true),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.primaryColor ?? DesignTokens.neonCyan,
            widget.secondaryColor ?? DesignTokens.bgPrimary,
          ],
        ),
      ),
      child: Stack(
        children: List.generate(
          widget.particleCount,
          (index) => AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              return Positioned(
                left: (index * 40.0) % MediaQuery.of(context).size.width,
                top: (index * 30.0) % MediaQuery.of(context).size.height,
                child: Opacity(
                  opacity: 0.3 + (0.4 * _controllers[index].value),
                  child: Container(
                    width: 4 + (index % 3) * 2.0,
                    height: 4 + (index % 3) * 2.0,
                    decoration: const BoxDecoration(
                      color: DesignTokens.neonMagenta,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// DFC Logo widget with size variants
class DFCLogo extends StatelessWidget {
  final DFCLogoSize size;
  final Color? color;

  const DFCLogo({super.key, this.size = DFCLogoSize.medium, this.color});

  double _getSize() {
    switch (size) {
      case DFCLogoSize.small:
        return 48;
      case DFCLogoSize.medium:
        return 80;
      case DFCLogoSize.large:
        return 120;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = _getSize();
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: (color ?? DesignTokens.neonCyan).withAlpha(100),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Image.asset(
        AppLogos.icon,
        width: logoSize,
        height: logoSize,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Neon divider widget
class DFCNeonDivider extends StatelessWidget {
  final Color color;
  final double thickness;
  final double height;
  final bool glowEffect;

  const DFCNeonDivider({
    super.key,
    this.color = DesignTokens.neonCyan,
    this.thickness = 2,
    this.height = 16,
    this.glowEffect = true,
  });

  @override
  Widget build(BuildContext context) {
    final divider = Container(height: thickness, color: color);

    if (!glowEffect) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: height / 2),
        child: divider,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: height / 2),
      child: Container(
        height: thickness,
        decoration: BoxDecoration(
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(200),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
