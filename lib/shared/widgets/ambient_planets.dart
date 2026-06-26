import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AMBIENT PLANETS — Slow-drifting decorative orbs for background depth
/// Adds cosmic atmosphere without interfering with touch
/// ═══════════════════════════════════════════════════════════════════════════
class AmbientPlanets extends StatefulWidget {
  const AmbientPlanets({super.key});

  @override
  State<AmbientPlanets> createState() => _AmbientPlanetsState();
}

class _AmbientPlanetsState extends State<AmbientPlanets>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _PlanetPainter(phase: _ctrl.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _PlanetPainter extends CustomPainter {
  final double phase;

  _PlanetPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final planets = [
      _Planet(0.08, 0.12, 18, DesignTokens.neonCyan, 0.04, 1.0),
      _Planet(0.92, 0.08, 12, DesignTokens.neonMagenta, 0.035, 1.3),
      _Planet(0.85, 0.75, 22, DesignTokens.neonGreen, 0.025, 0.7),
      _Planet(0.05, 0.65, 10, DesignTokens.neonAmber, 0.03, 1.6),
      _Planet(0.55, 0.04, 8, DesignTokens.neonRed, 0.02, 2.0),
      _Planet(0.15, 0.88, 14, const Color(0xFF7B68EE), 0.03, 0.9),
      _Planet(0.75, 0.42, 6, DesignTokens.neonCyan, 0.015, 2.4),
    ];

    for (final p in planets) {
      final t = phase * math.pi * 2 * p.speed;
      final dx = math.sin(t + p.offsetPhase) * size.width * 0.02;
      final dy = math.cos(t * 0.7 + p.offsetPhase) * size.height * 0.015;

      final center = Offset(
        p.baseX * size.width + dx,
        p.baseY * size.height + dy,
      );

      // Outer glow
      canvas.drawCircle(
        center,
        p.radius * 2.5,
        Paint()
          ..color = p.color.withValues(alpha: p.alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );

      // Planet body
      canvas.drawCircle(
        center,
        p.radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              p.color.withValues(alpha: p.alpha * 1.2),
              p.color.withValues(alpha: p.alpha * 0.3),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: p.radius)),
      );

      // Specular highlight
      canvas.drawCircle(
        Offset(center.dx - p.radius * 0.25, center.dy - p.radius * 0.25),
        p.radius * 0.35,
        Paint()..color = Colors.white.withValues(alpha: p.alpha * 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlanetPainter old) => true;
}

class _Planet {
  final double baseX;
  final double baseY;
  final double radius;
  final Color color;
  final double alpha;
  final double speed;
  final double offsetPhase;

  _Planet(
    this.baseX,
    this.baseY,
    this.radius,
    this.color,
    this.alpha,
    this.speed,
  ) : offsetPhase = baseX * 10 + baseY * 7;
}
