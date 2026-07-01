import 'package:flutter/material.dart';

class FightCampTimelineChart extends StatelessWidget {
  final List<double> readinessValues;

  const FightCampTimelineChart({super.key, required this.readinessValues});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: CustomPaint(painter: _TimelinePainter(readinessValues)),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<double> values;

  _TimelinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (values.isNotEmpty) {
      final step = size.width / (values.length - 1);
      path.moveTo(0, size.height - values[0]);

      for (int i = 1; i < values.length; i++) {
        path.lineTo(i * step, size.height - values[i]);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
