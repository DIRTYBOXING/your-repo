import 'dart:math' as math;
import 'package:flutter/material.dart';

class NeonPulsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;
    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    final ringPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Colors.cyanAccent,
          Colors.blueAccent,
          Colors.purpleAccent,
          Colors.cyanAccent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, glowPaint);
    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ParticleBurstOverlay extends StatefulWidget {
  const ParticleBurstOverlay({super.key});

  @override
  State<ParticleBurstOverlay> createState() => ParticleBurstOverlayState();
}

class ParticleBurstOverlayState extends State<ParticleBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  static const int _particleCount = 32;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    final rand = math.Random();
    _particles = List.generate(_particleCount, (i) => _Particle.random(rand));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(_particles, _controller.value),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double radius;
  final Color color;
  final double size;
  final double startTime;

  _Particle({
    required this.angle,
    required this.speed,
    required this.radius,
    required this.color,
    required this.size,
    required this.startTime,
  });

  factory _Particle.random(math.Random rand) {
    final angle = rand.nextDouble() * 2 * math.pi;
    final speed = 0.5 + rand.nextDouble() * 1.5;
    final radius = 60 + rand.nextDouble() * 40;
    final color = Color.lerp(
      Colors.cyanAccent,
      Colors.purpleAccent,
      rand.nextDouble(),
    )!;
    final size = 4 + rand.nextDouble() * 6;
    final startTime = rand.nextDouble();
    return _Particle(
      angle: angle,
      speed: speed,
      radius: radius,
      color: color,
      size: size,
      startTime: startTime,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final p in particles) {
      final t = ((progress + p.startTime) % 1.0);
      final dist = p.radius * (0.7 + 0.3 * math.sin(t * math.pi * 2));
      final x = center.dx + dist * math.cos(p.angle);
      final y = center.dy + dist * math.sin(p.angle);
      final paint = Paint()
        ..color = p.color.withValues(alpha: 1.0 - t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(x, y), p.size * (1.0 - t), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
