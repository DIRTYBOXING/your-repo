import 'package:flutter/material.dart';

/// Trend Chart Widget
/// Simple line chart for displaying health metric trends
/// Supports 7-day data visualization
class TrendChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double? minValue;
  final double? maxValue;
  final bool showDots;

  const TrendChart({
    super.key,
    required this.data,
    required this.color,
    this.minValue,
    this.maxValue,
    this.showDots = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: const Size(double.infinity, 60),
      painter: _TrendChartPainter(
        data: data,
        color: color,
        minValue: minValue ?? data.reduce((a, b) => a < b ? a : b) * 0.9,
        maxValue: maxValue ?? data.reduce((a, b) => a > b ? a : b) * 1.1,
        showDots: showDots,
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double minValue;
  final double maxValue;
  final bool showDots;

  _TrendChartPainter({
    required this.data,
    required this.color,
    required this.minValue,
    required this.maxValue,
    required this.showDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    final isFlatLine = (maxValue - minValue).abs() < 0.000001;
    final yRange = isFlatLine ? 1.0 : (maxValue - minValue);
    final xStep = data.length > 1 ? size.width / (data.length - 1) : 0.0;

    for (var i = 0; i < data.length; i++) {
      final x = data.length == 1 ? size.width / 2 : i * xStep;
      final normalizedY = isFlatLine
          ? 0.5
          : ((data[i] - minValue) / yRange).clamp(0.0, 1.0);
      final y = size.height - (normalizedY * size.height);

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Close fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw fill
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, paint);

    // Draw dots
    if (showDots) {
      for (final point in points) {
        canvas.drawCircle(point, 4, dotPaint);
        canvas.drawCircle(
          point,
          4,
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        color != oldDelegate.color ||
        minValue != oldDelegate.minValue ||
        maxValue != oldDelegate.maxValue ||
        showDots != oldDelegate.showDots;
  }
}
