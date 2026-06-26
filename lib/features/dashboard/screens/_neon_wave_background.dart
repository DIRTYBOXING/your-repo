import 'dart:math' as math;
import 'package:flutter/material.dart';

class NeonWaveBackground extends StatefulWidget {
  const NeonWaveBackground({super.key});

  @override
  State<NeonWaveBackground> createState() => NeonWaveBackgroundState();
}

class NeonWaveBackgroundState extends State<NeonWaveBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
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
        return CustomPaint(painter: _NeonWavePainter(t: _controller.value));
      },
    );
  }
}

class _NeonWavePainter extends CustomPainter {
  final double t;
  const _NeonWavePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.black.withValues(alpha: 0.92);
    canvas.drawRect(Offset.zero & size, bg);

    // Draw multiple animated neon waves
    for (int i = 0; i < 3; i++) {
      final phase = t * 2 * math.pi + i * math.pi / 2;
      final color = [
        Colors.cyanAccent,
        Colors.purpleAccent,
        Colors.blueAccent,
      ][i % 3].withValues(alpha: 0.18 + 0.08 * i);
      _drawWave(canvas, size, phase, color, 0.18 + 0.04 * i, 60.0 + 20.0 * i);
    }

    // Sparkles
    final rand = math.Random(42);
    for (int i = 0; i < 24; i++) {
      final sparkleT = (t + i * 0.04) % 1.0;
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final opacity = 0.18 + 0.18 * math.sin(sparkleT * 2 * math.pi);
      final paint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(x, y), 2.5 + 2 * sparkleT, paint);
    }
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double phase,
    Color color,
    double opacity,
    double amplitude,
  ) {
    final path = Path();
    for (double x = 0; x <= size.width; x += 2) {
      final y =
          size.height / 2 +
          amplitude * math.sin((x / size.width) * 2 * math.pi + phase);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
