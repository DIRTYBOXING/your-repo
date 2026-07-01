import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 2026 Custom Graph Painters
/// No stock packages - flagship quality with CustomPainter
/// Soft glow, gradient fill, depth, motion easing

/// HR/HRV Overlay Graph - Line + Area with glow
class HRVGraphPainter extends CustomPainter {
  final List<double> hrData;
  final List<double> hrvData;
  final double animationValue;

  HRVGraphPainter({
    required this.hrData,
    required this.hrvData,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hrData.isEmpty || hrvData.isEmpty) return;

    final hrMax = hrData.reduce(math.max);
    final hrMin = hrData.reduce(math.min);
    final hrvMax = hrvData.reduce(math.max);
    final hrvMin = hrvData.reduce(math.min);

    // Draw gridlines
    _drawGridLines(canvas, size, hrMin, hrMax);

    // Draw HRV area fill first (behind)
    _drawAreaFill(canvas, size, hrvData, hrvMin, hrvMax, [
      const Color(0xFF00CEC9).withValues(alpha: 0.3),
      const Color(0xFF00CEC9).withValues(alpha: 0.05),
    ]);

    // Draw HR area fill
    _drawAreaFill(canvas, size, hrData, hrMin, hrMax, [
      const Color(0xFFFF6B6B).withValues(alpha: 0.25),
      const Color(0xFFFF6B6B).withValues(alpha: 0.02),
    ]);

    // Draw HRV line with glow
    _drawGlowLine(
      canvas,
      size,
      hrvData,
      hrvMin,
      hrvMax,
      const Color(0xFF00CEC9),
    );

    // Draw HR line with glow
    _drawGlowLine(canvas, size, hrData, hrMin, hrMax, const Color(0xFFFF6B6B));

    // Draw data points
    _drawDataPoints(
      canvas,
      size,
      hrData,
      hrMin,
      hrMax,
      const Color(0xFFFF6B6B),
    );
    _drawDataPoints(
      canvas,
      size,
      hrvData,
      hrvMin,
      hrvMax,
      const Color(0xFF00CEC9),
    );

    // Draw axis labels
    _drawAxisLabels(canvas, size, hrMin, hrMax);
  }

  void _drawGridLines(Canvas canvas, Size size, double min, double max) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const gridCount = 4;
    for (int i = 0; i <= gridCount; i++) {
      final y = size.height * i / gridCount;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawAxisLabels(Canvas canvas, Size size, double min, double max) {
    const labelStyle = TextStyle(
      color: Colors.white70,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    const gridCount = 4;
    for (int i = 0; i <= gridCount; i++) {
      final value = max - (max - min) * i / gridCount;
      final y = size.height * i / gridCount;
      String healthTip = '';
      if (i == 0) healthTip = 'Peak wellness';
      if (i == gridCount) healthTip = 'Needs improvement';
      final tp = TextPainter(
        text: TextSpan(
          text:
              value.toStringAsFixed(0) +
              (healthTip.isNotEmpty ? ' • $healthTip' : ''),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }
    // X-axis label (time)
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Time • Consistency = Results',
        style: labelStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size.width - tp.width - 2, size.height - tp.height - 2),
    );
  }

  void _drawAreaFill(
    Canvas canvas,
    Size size,
    List<double> data,
    double min,
    double max,
    List<Color> gradientColors,
  ) {
    final path = Path();
    final range = max - min;
    final effectiveRange = range == 0 ? 1.0 : range;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width * animationValue;
      final normalizedY = (data[i] - min) / effectiveRange;
      final y =
          size.height - (normalizedY * size.height * 0.8) - size.height * 0.1;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Smooth curve using quadratic bezier
        final prevX =
            ((i - 1) / (data.length - 1)) * size.width * animationValue;
        final prevY =
            size.height -
            ((data[i - 1] - min) / effectiveRange * size.height * 0.8) -
            size.height * 0.1;
        final midX = (prevX + x) / 2;
        path.quadraticBezierTo(prevX, prevY, midX, (prevY + y) / 2);
        if (i == data.length - 1) {
          path.lineTo(x, y);
        }
      }
    }

    // Close path to bottom
    path.lineTo(size.width * animationValue, size.height);
    path.lineTo(0, size.height);
    path.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: gradientColors,
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawPath(path, paint);
  }

  void _drawGlowLine(
    Canvas canvas,
    Size size,
    List<double> data,
    double min,
    double max,
    Color color,
  ) {
    final path = Path();
    final range = max - min;
    final effectiveRange = range == 0 ? 1.0 : range;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width * animationValue;
      final normalizedY = (data[i] - min) / effectiveRange;
      final y =
          size.height - (normalizedY * size.height * 0.8) - size.height * 0.1;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX =
            ((i - 1) / (data.length - 1)) * size.width * animationValue;
        final prevY =
            size.height -
            ((data[i - 1] - min) / effectiveRange * size.height * 0.8) -
            size.height * 0.1;
        final midX = (prevX + x) / 2;
        path.quadraticBezierTo(prevX, prevY, midX, (prevY + y) / 2);
        if (i == data.length - 1) {
          path.lineTo(x, y);
        }
      }
    }

    // Glow effect (multiple strokes with decreasing opacity)
    for (int i = 3; i >= 0; i--) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.1 + (0.15 * (3 - i)))
        ..strokeWidth = 2.0 + (i * 2)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = i > 0
            ? MaskFilter.blur(BlurStyle.normal, i * 2.0)
            : null;
      canvas.drawPath(path, glowPaint);
    }

    // Main line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  void _drawDataPoints(
    Canvas canvas,
    Size size,
    List<double> data,
    double min,
    double max,
    Color color,
  ) {
    final range = max - min;
    final effectiveRange = range == 0 ? 1.0 : range;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width * animationValue;
      final normalizedY = (data[i] - min) / effectiveRange;
      final y =
          size.height - (normalizedY * size.height * 0.8) - size.height * 0.1;

      // Outer glow
      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()..color = color.withValues(alpha: 0.3),
      );

      // Inner point
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);

      // Center highlight
      canvas.drawCircle(
        Offset(x, y),
        1.5,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant HRVGraphPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.hrData != hrData ||
        oldDelegate.hrvData != hrvData;
  }
}

/// Weight Cut Curve - Safe vs Aggressive bands
class WeightCutGraphPainter extends CustomPainter {
  final List<double> weightData;
  final double targetWeight;
  final double baselineWeight;
  final double animationValue;

  WeightCutGraphPainter({
    required this.weightData,
    required this.targetWeight,
    required this.baselineWeight,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weightData.isEmpty) return;

    final maxWeight = baselineWeight + 5;
    final minWeight = targetWeight - 5;
    final range = maxWeight - minWeight;

    // Draw gridlines
    _drawGridLines(canvas, size, minWeight, maxWeight);

    // Draw safe zone band (green)
    final safeTop =
        size.height - ((baselineWeight - 2 - minWeight) / range * size.height);
    final safeBottom =
        size.height - ((targetWeight + 3 - minWeight) / range * size.height);

    final safePaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF00B894).withValues(alpha: 0.15),
              const Color(0xFF00B894).withValues(alpha: 0.05),
            ],
          ).createShader(
            Rect.fromLTWH(0, safeTop, size.width, safeBottom - safeTop),
          );

    canvas.drawRect(
      Rect.fromLTWH(0, safeTop, size.width, safeBottom - safeTop),
      safePaint,
    );

    // Draw danger zone band (red - below target)
    final dangerTop =
        size.height - ((targetWeight - minWeight) / range * size.height);
    final dangerPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFF6B6B).withValues(alpha: 0.1),
              const Color(0xFFFF6B6B).withValues(alpha: 0.2),
            ],
          ).createShader(
            Rect.fromLTWH(0, dangerTop, size.width, size.height - dangerTop),
          );

    canvas.drawRect(
      Rect.fromLTWH(0, dangerTop, size.width, size.height - dangerTop),
      dangerPaint,
    );

    // Draw target line
    final targetY =
        size.height - ((targetWeight - minWeight) / range * size.height);
    final targetPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Dashed line
    const dashWidth = 8.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width * animationValue) {
      canvas.drawLine(
        Offset(startX, targetY),
        Offset(
          math.min(startX + dashWidth, size.width * animationValue),
          targetY,
        ),
        targetPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Draw weight curve
    final path = Path();
    for (int i = 0; i < weightData.length; i++) {
      final x = (i / (weightData.length - 1)) * size.width * animationValue;
      final y =
          size.height - ((weightData[i] - minWeight) / range * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX =
            ((i - 1) / (weightData.length - 1)) * size.width * animationValue;
        final prevY =
            size.height -
            ((weightData[i - 1] - minWeight) / range * size.height);
        final midX = (prevX + x) / 2;
        path.quadraticBezierTo(prevX, prevY, midX, (prevY + y) / 2);
        if (i == weightData.length - 1) {
          path.lineTo(x, y);
        }
      }
    }

    // Glow effect
    for (int i = 2; i >= 0; i--) {
      final glowPaint = Paint()
        ..color = AppTheme.neonCyan.withValues(alpha: 0.1 + (0.1 * (2 - i)))
        ..strokeWidth = 3.0 + (i * 2)
        ..style = PaintingStyle.stroke
        ..maskFilter = i > 0
            ? MaskFilter.blur(BlurStyle.normal, i * 2.0)
            : null;
      canvas.drawPath(path, glowPaint);
    }

    // Main line
    final linePaint = Paint()
      ..color = AppTheme.neonCyan
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw current weight point (last)
    if (weightData.isNotEmpty) {
      final lastX = size.width * animationValue;
      final lastY =
          size.height - ((weightData.last - minWeight) / range * size.height);

      // Pulse effect
      canvas.drawCircle(
        Offset(lastX, lastY),
        8,
        Paint()..color = AppTheme.neonCyan.withValues(alpha: 0.2),
      );
      canvas.drawCircle(
        Offset(lastX, lastY),
        5,
        Paint()..color = AppTheme.neonCyan,
      );
      canvas.drawCircle(Offset(lastX, lastY), 2, Paint()..color = Colors.white);
    }

    // Draw axis labels
    _drawAxisLabels(canvas, size, minWeight, maxWeight);
  }

  void _drawGridLines(Canvas canvas, Size size, double min, double max) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const gridCount = 4;
    for (int i = 0; i <= gridCount; i++) {
      final y = size.height * i / gridCount;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawAxisLabels(Canvas canvas, Size size, double min, double max) {
    const labelStyle = TextStyle(
      color: Colors.white70,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    const gridCount = 4;
    for (int i = 0; i <= gridCount; i++) {
      final value = max - (max - min) * i / gridCount;
      final y = size.height * i / gridCount;
      String healthTip = '';
      if (i == 0) healthTip = 'Safe zone';
      if (i == gridCount) healthTip = 'Danger zone';
      final tp = TextPainter(
        text: TextSpan(
          text:
              value.toStringAsFixed(1) +
              (healthTip.isNotEmpty ? ' • $healthTip' : ''),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }
    // X-axis label (time)
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Time • Hydrate, sleep, eat clean',
        style: labelStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size.width - tp.width - 2, size.height - tp.height - 2),
    );
  }

  @override
  bool shouldRepaint(covariant WeightCutGraphPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Training Load vs Recovery Debt
class LoadRecoveryGraphPainter extends CustomPainter {
  final List<double> loadData;
  final List<double> recoveryData;
  final double animationValue;

  LoadRecoveryGraphPainter({
    required this.loadData,
    required this.recoveryData,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (loadData.isEmpty || recoveryData.isEmpty) return;

    const maxValue = 10.0;

    // Draw gridlines
    _drawGridLines(canvas, size, maxValue);

    // Draw recovery area (green/amber/red zones)
    _drawZoneBands(canvas, size);

    // Draw bars
    final barWidth = (size.width / loadData.length) * 0.35;
    final spacing = (size.width / loadData.length);

    for (int i = 0; i < loadData.length; i++) {
      final x = spacing * i + spacing * 0.25;

      // Load bar
      final loadHeight =
          (loadData[i] / maxValue) * size.height * 0.85 * animationValue;
      final loadRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - loadHeight, barWidth, loadHeight),
        const Radius.circular(4),
      );

      final loadPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
        ).createShader(loadRect.outerRect);

      canvas.drawRRect(loadRect, loadPaint);

      // Recovery bar
      final recoveryHeight =
          (recoveryData[i] / maxValue) * size.height * 0.85 * animationValue;
      final recoveryRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x + barWidth + 2,
          size.height - recoveryHeight,
          barWidth,
          recoveryHeight,
        ),
        const Radius.circular(4),
      );

      final recoveryPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
        ).createShader(recoveryRect.outerRect);

      canvas.drawRRect(recoveryRect, recoveryPaint);
    }

    // Draw axis labels
    _drawAxisLabels(canvas, size, maxValue);
  }

  void _drawGridLines(Canvas canvas, Size size, double maxValue) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const gridCount = 4;
    for (int i = 0; i <= gridCount; i++) {
      final y = size.height * i / gridCount;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawAxisLabels(Canvas canvas, Size size, double maxValue) {
    const labelStyle = TextStyle(
      color: Colors.white70,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    const gridCount = 4;
    for (int i = 0; i <= gridCount; i++) {
      final value = maxValue - (maxValue) * i / gridCount;
      final y = size.height * i / gridCount;
      String healthTip = '';
      if (i == 0) healthTip = 'Best friend: recovery';
      if (i == gridCount) healthTip = 'Overload: rest needed';
      final tp = TextPainter(
        text: TextSpan(
          text:
              value.toStringAsFixed(0) +
              (healthTip.isNotEmpty ? ' • $healthTip' : ''),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }
    // X-axis label (time)
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Time • Sleep, hydrate, avoid late night alcohol',
        style: labelStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size.width - tp.width - 2, size.height - tp.height - 2),
    );
  }

  void _drawZoneBands(Canvas canvas, Size size) {
    // Red zone (overload)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.2),
      Paint()..color = const Color(0xFFFF6B6B).withValues(alpha: 0.08),
    );

    // Amber zone (caution)
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.2, size.width, size.height * 0.3),
      Paint()..color = const Color(0xFFFFA502).withValues(alpha: 0.05),
    );
  }

  @override
  bool shouldRepaint(covariant LoadRecoveryGraphPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Hydration vs Electrolyte Balance
class HydrationElectrolyteGraphPainter extends CustomPainter {
  final List<double> hydrationData;
  final List<double> sodiumData;
  final List<double> potassiumData;
  final double animationValue;

  HydrationElectrolyteGraphPainter({
    required this.hydrationData,
    required this.sodiumData,
    required this.potassiumData,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hydrationData.isEmpty) return;

    // Draw gridlines
    _drawGridLines(canvas, size);

    // Hydration fill area
    final hydrationPath = Path();
    for (int i = 0; i < hydrationData.length; i++) {
      final x = (i / (hydrationData.length - 1)) * size.width * animationValue;
      final y = size.height - (hydrationData[i] / 100 * size.height * 0.85);

      if (i == 0) {
        hydrationPath.moveTo(x, y);
      } else {
        hydrationPath.lineTo(x, y);
      }
    }
    hydrationPath.lineTo(size.width * animationValue, size.height);
    hydrationPath.lineTo(0, size.height);
    hydrationPath.close();

    final hydrationPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF74B9FF).withValues(alpha: 0.4),
          const Color(0xFF74B9FF).withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(hydrationPath, hydrationPaint);

    // Hydration line
    _drawSmoothLine(canvas, size, hydrationData, 100, const Color(0xFF74B9FF));

    // Sodium line (smaller scale)
    _drawSmoothLine(canvas, size, sodiumData, 200, const Color(0xFFFFD700));

    // Potassium line
    _drawSmoothLine(canvas, size, potassiumData, 200, const Color(0xFFFF6B6B));

    // Draw axis labels
    _drawAxisLabels(canvas, size);
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const gridCount = 4;
    for (int i = 0; i <= gridCount; i++) {
      final y = size.height * i / gridCount;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawAxisLabels(Canvas canvas, Size size) {
    const labelStyle = TextStyle(
      color: Colors.white70,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    const gridCount = 4;
    for (int i = 0; i <= gridCount; i++) {
      final percent = 100 - (100) * i / gridCount;
      final y = size.height * i / gridCount;
      String healthTip = '';
      if (i == 0) healthTip = 'Hydrated';
      if (i == gridCount) healthTip = 'Dehydrated';
      final tp = TextPainter(
        text: TextSpan(
          text:
              '${percent.toStringAsFixed(0)}% ${healthTip.isNotEmpty ? '• $healthTip' : ''}',
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }
    // X-axis label (time)
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Time • Nutrition, water, self-care',
        style: labelStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size.width - tp.width - 2, size.height - tp.height - 2),
    );
  }

  void _drawSmoothLine(
    Canvas canvas,
    Size size,
    List<double> data,
    double maxVal,
    Color color,
  ) {
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width * animationValue;
      final y = size.height - (data[i] / maxVal * size.height * 0.85);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Main line
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant HydrationElectrolyteGraphPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
