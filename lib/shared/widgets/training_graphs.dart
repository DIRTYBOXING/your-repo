import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

/// Camp State - Bullish/Bearish like stock markets
enum CampState {
  bullish, // Recovery good, readiness high
  neutral, // Balanced, normal
  bearish, // Fatigue accumulating, risk rising
  danger, // Overload, immediate attention needed
}

/// Evaluate camp state based on health metrics
CampState evaluateCampState({
  required double restingHR, // bpm - lower is better
  required double sleepScore, // 0.0 - 1.0
  required double hydration, // 0.0 - 1.0
  required double stress, // 0.0 - 1.0 - lower is better
  double? hrv, // ms - higher is better
}) {
  // Danger conditions
  if (restingHR > 80 || hydration < 0.5 || stress > 0.8) {
    return CampState.danger;
  }

  // Bearish conditions
  if (sleepScore < 0.6 || hydration < 0.7 || stress > 0.6 || restingHR > 70) {
    return CampState.bearish;
  }

  // Bullish conditions
  if (sleepScore > 0.8 && hydration > 0.85 && stress < 0.3 && restingHR < 60) {
    return CampState.bullish;
  }

  return CampState.neutral;
}

/// Get color for camp state
Color campStateColor(CampState state) {
  switch (state) {
    case CampState.bullish:
      return AppTheme.neonGreen;
    case CampState.neutral:
      return Colors.blueGrey;
    case CampState.bearish:
      return Colors.orangeAccent;
    case CampState.danger:
      return const Color(0xFFFF4757);
  }
}

/// Get label for camp state
String campStateLabel(CampState state) {
  switch (state) {
    case CampState.bullish:
      return 'BULLISH';
    case CampState.neutral:
      return 'NEUTRAL';
    case CampState.bearish:
      return 'BEARISH';
    case CampState.danger:
      return 'REDLINE';
  }
}

/// Readiness Line Graph - CustomPainter for holographic look
class ReadinessGraphPainter extends CustomPainter {
  final List<double> values;
  final Color glowColor;
  final double animationValue;
  final bool showGlow;

  ReadinessGraphPainter({
    required this.values,
    required this.glowColor,
    this.animationValue = 1.0,
    this.showGlow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final path = Path();
    final fillPath = Path();

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y =
          size.height -
          (values[i].clamp(0.0, 1.0) * size.height * 0.85) -
          (size.height * 0.075);
      points.add(Offset(x, y));
    }

    // Create smooth curve through points
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      fillPath.moveTo(0, size.height);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = i > 0 ? points[i - 1] : points[i];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = i < points.length - 2 ? points[i + 2] : p2;

        final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
        final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
        final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
        final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

        path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
        fillPath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }

      fillPath.lineTo(size.width, size.height);
      fillPath.close();
    }

    // Draw fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          glowColor.withValues(alpha: 0.3 * animationValue),
          glowColor.withValues(alpha: 0.05 * animationValue),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Draw glow effect (blurred line)
    if (showGlow) {
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.5 * animationValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawPath(path, glowPaint);
    }

    // Draw main line
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          glowColor.withValues(alpha: 0.8 * animationValue),
          glowColor.withValues(alpha: animationValue),
          glowColor.withValues(alpha: 0.8 * animationValue),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Draw points
    final dotPaint = Paint()..color = glowColor;
    final dotGlowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (final point in points) {
      canvas.drawCircle(point, 6, dotGlowPaint);
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ReadinessGraphPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.animationValue != animationValue;
  }
}

/// Dual Line Graph - Load vs Recovery
class DualLineGraphPainter extends CustomPainter {
  final List<double> loadValues;
  final List<double> recoveryValues;
  final double animationValue;

  DualLineGraphPainter({
    required this.loadValues,
    required this.recoveryValues,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (loadValues.isEmpty || recoveryValues.isEmpty) return;

    // Draw recovery line (green/cyan)
    _drawLine(canvas, size, recoveryValues, AppTheme.neonCyan, animationValue);

    // Draw load line (orange/pink)
    _drawLine(
      canvas,
      size,
      loadValues,
      const Color(0xFFFF6B9D),
      animationValue,
    );

    // Draw danger zones where load > recovery
    _drawDangerZones(canvas, size);
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    List<double> values,
    Color color,
    double animation,
  ) {
    if (values.isEmpty) return;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y =
          size.height -
          (values[i].clamp(0.0, 1.0) * size.height * 0.8) -
          (size.height * 0.1);
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final cpx = (prev.dx + curr.dx) / 2;
        path.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
      }
    }

    // Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4 * animation)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    // Main line
    final linePaint = Paint()
      ..color = color.withValues(alpha: animation)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  void _drawDangerZones(Canvas canvas, Size size) {
    final dangerPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.15 * animationValue);

    for (int i = 0; i < loadValues.length && i < recoveryValues.length; i++) {
      if (loadValues[i] > recoveryValues[i]) {
        final x = (i / (loadValues.length - 1)) * size.width;
        final barWidth = size.width / loadValues.length;
        canvas.drawRect(
          Rect.fromLTWH(x - barWidth / 2, 0, barWidth, size.height),
          dangerPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DualLineGraphPainter oldDelegate) {
    return oldDelegate.loadValues != loadValues ||
        oldDelegate.recoveryValues != recoveryValues ||
        oldDelegate.animationValue != animationValue;
  }
}

/// Radial Recovery Ring - Sleep, HRV, Mobility, Stress
class RecoveryRingPainter extends CustomPainter {
  final double sleep; // 0.0 - 1.0
  final double hrv; // 0.0 - 1.0
  final double mobility; // 0.0 - 1.0
  final double stress; // 0.0 - 1.0 (inverted - lower is better)
  final double animationValue;

  RecoveryRingPainter({
    required this.sleep,
    required this.hrv,
    required this.mobility,
    required this.stress,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    // Draw background rings
    _drawRing(
      canvas,
      center,
      radius,
      0.0,
      Colors.white.withValues(alpha: 0.1),
      8,
    );
    _drawRing(
      canvas,
      center,
      radius - 20,
      0.0,
      Colors.white.withValues(alpha: 0.1),
      8,
    );
    _drawRing(
      canvas,
      center,
      radius - 40,
      0.0,
      Colors.white.withValues(alpha: 0.1),
      8,
    );
    _drawRing(
      canvas,
      center,
      radius - 60,
      0.0,
      Colors.white.withValues(alpha: 0.1),
      8,
    );

    // Draw metric rings with glow
    final metrics = [
      (sleep, AppTheme.neonCyan, 'SLEEP'),
      (hrv, AppTheme.neonGreen, 'HRV'),
      (mobility, const Color(0xFF9B59B6), 'MOBILITY'),
      (1.0 - stress, const Color(0xFFFF6B9D), 'CALM'),
    ];

    for (int i = 0; i < metrics.length; i++) {
      final (value, color, _) = metrics[i];
      final ringRadius = radius - (i * 20);
      final animatedValue = value * animationValue;

      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final sweepAngle = animatedValue * 2 * math.pi * 0.75;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        -math.pi / 2 - math.pi / 8,
        sweepAngle,
        false,
        glowPaint,
      );

      // Main arc
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        -math.pi / 2 - math.pi / 8,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double value,
    Color color,
    double width,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 - math.pi / 8,
      2 * math.pi * 0.75,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant RecoveryRingPainter oldDelegate) {
    return oldDelegate.sleep != sleep ||
        oldDelegate.hrv != hrv ||
        oldDelegate.mobility != mobility ||
        oldDelegate.stress != stress ||
        oldDelegate.animationValue != animationValue;
  }
}

/// Bar Chart with stacked training types
class TrainingLoadBarsPainter extends CustomPainter {
  final List<Map<String, double>>
  dailyData; // Each day has {striking, grappling, conditioning, recovery}
  final double animationValue;

  TrainingLoadBarsPainter({required this.dailyData, this.animationValue = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (dailyData.isEmpty) return;

    final barWidth = (size.width / dailyData.length) * 0.7;
    final gap = (size.width / dailyData.length) * 0.3;

    for (int i = 0; i < dailyData.length; i++) {
      final data = dailyData[i];
      final x = i * (barWidth + gap) + gap / 2;

      double currentY = size.height;

      // Stack: Recovery (bottom) -> Conditioning -> Grappling -> Striking (top)
      final segments = [
        (data['recovery'] ?? 0.0, const Color(0xFF2ECC71)), // Green
        (data['conditioning'] ?? 0.0, const Color(0xFF3498DB)), // Blue
        (data['grappling'] ?? 0.0, const Color(0xFF9B59B6)), // Purple
        (data['striking'] ?? 0.0, const Color(0xFFE74C3C)), // Red
      ];

      for (final (value, color) in segments) {
        final segmentHeight = (value * size.height * 0.8 * animationValue);
        if (segmentHeight > 0) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(x, currentY - segmentHeight, barWidth, segmentHeight),
            const Radius.circular(4),
          );

          // Glow
          final glowPaint = Paint()
            ..color = color.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawRRect(rect, glowPaint);

          // Bar
          final barPaint = Paint()..color = color;
          canvas.drawRRect(rect, barPaint);

          currentY -= segmentHeight;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TrainingLoadBarsPainter oldDelegate) {
    return oldDelegate.dailyData != dailyData ||
        oldDelegate.animationValue != animationValue;
  }
}
