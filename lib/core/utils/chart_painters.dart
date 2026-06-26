import 'package:flutter/material.dart';

class GraphPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  GraphPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final max = data.reduce((a, b) => a > b ? a : b);
    final min = data.reduce((a, b) => a < b ? a : b);
    final range = max - min;
    const pad = 14.0;
    final step = size.width / (data.length - 1);

    final path = Path();
    final fill = Path();

    for (var i = 0; i < data.length; i++) {
      final x = i * step;
      final y =
          pad +
          (1 - (data[i] - min) / (range == 0 ? 1 : range)) *
              (size.height - pad * 2);
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final lx = (data.length - 1) * step;
    final ly =
        pad +
        (1 - (data.last - min) / (range == 0 ? 1 : range)) *
            (size.height - pad * 2);
    canvas.drawCircle(Offset(lx, ly), 4, Paint()..color = color);
    canvas.drawCircle(
      Offset(lx, ly),
      7,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiniSparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  MiniSparkPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final max = data.reduce((a, b) => a > b ? a : b);
    final min = data.reduce((a, b) => a < b ? a : b);
    final range = max - min;
    final step = size.width / (data.length - 1);
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = i * step;
      final y = (1 - (data[i] - min) / (range == 0 ? 1 : range)) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
