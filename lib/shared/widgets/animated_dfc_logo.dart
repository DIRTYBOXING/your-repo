import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_logos.dart';
import '../../core/theme/theme_controller.dart';

/// AnimatedDfcLogo - Hexagonal DFC badge with pulsing neon glow
/// Matches the Play Store / Google badge design
class AnimatedDfcLogo extends StatefulWidget {
  final double size;
  final bool showGlow;
  final bool rotate;

  const AnimatedDfcLogo({
    super.key,
    this.size = 180,
    this.showGlow = true,
    this.rotate = false,
  });

  @override
  State<AnimatedDfcLogo> createState() => _AnimatedDfcLogoState();
}

class _AnimatedDfcLogoState extends State<AnimatedDfcLogo>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotateController;
  late final AnimationController _entryController;
  late final Animation<double> _scaleEntry;
  late final Animation<double> _fadeEntry;

  @override
  void initState() {
    super.initState();

    // Pulsing glow effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    // Optional slow rotation
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    if (widget.rotate) {
      _rotateController.repeat();
    }

    // Entry animation with elastic bounce
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleEntry = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _fadeEntry = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _rotateController,
        _entryController,
        ThemeController.mode,
      ]),
      builder: (context, child) {
        final accent = ThemeController.accent;
        final logoSize = widget.size;
        return FadeTransition(
          opacity: _fadeEntry,
          child: ScaleTransition(
            scale: _scaleEntry,
            child: Transform.rotate(
              angle: widget.rotate
                  ? _rotateController.value * 2 * math.pi * 0.02
                  : 0,
              child: SizedBox(
                width: logoSize,
                height: logoSize,
                child: Image.asset(
                  AppLogos.icon,
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                  errorBuilder: (c, o, s) => Image.asset(
                    'assets/logos/dfc_hex_badge.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    errorBuilder: (c, o, s) =>
                        _buildFallbackLogo(accent, logoSize),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackLogo(Color accent, double size) {
    // Hexagonal DFC badge with neon glow (matching brand logos)
    final glowSize = size * 1.1;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer neon glow layer
        Container(
          width: glowSize,
          height: glowSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.6),
                blurRadius: 30,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: accent.withValues(alpha: 0.3),
                blurRadius: 50,
                spreadRadius: 15,
              ),
            ],
          ),
        ),
        // Hexagon container
        ClipPath(
          clipper: HexagonClipper(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: accent, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [accent, AppColors.neonSky],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'DFC',
                  style: TextStyle(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hexagon clipper for brand badge
class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;
    const angle = 60.0;

    for (int i = 0; i < 6; i++) {
      final rad = (i * angle + 30) * 3.14159265359 / 180;
      final x = centerX + radius * math.cos(rad);
      final y = centerY + radius * math.sin(rad);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(HexagonClipper oldClipper) => false;
}

/// Compact hexagonal logo icon for app bars, buttons, etc.
class DfcHexIcon extends StatelessWidget {
  final double size;
  final Color? glowColor;

  const DfcHexIcon({super.key, this.size = 40, this.glowColor});

  @override
  Widget build(BuildContext context) {
    final color = glowColor ?? AppColors.neonBlue;
    final glowSize = size * 1.15;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow
        Container(
          width: glowSize,
          height: glowSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 3,
              ),
            ],
          ),
        ),
        // Hexagon
        ClipPath(
          clipper: HexagonClipper(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Center(
              child: Text(
                'DFC',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
