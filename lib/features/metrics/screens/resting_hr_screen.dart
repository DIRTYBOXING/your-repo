import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/sports_science_engine.dart';

/// Resting Heart Rate — Cardiac baseline intelligence
class RestingHRScreen extends StatefulWidget {
  const RestingHRScreen({super.key});

  @override
  State<RestingHRScreen> createState() => _RestingHRScreenState();
}

class _RestingHRScreenState extends State<RestingHRScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _curve;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  List<double> _weeklyRhrData(BuildContext context) {
    final trend = context
        .watch<SportsScienceEngine>()
        .getRestingHRTrend(days: 7)
        .map((entry) => entry.value)
        .toList();

    const fallback = [58.0, 62.0, 60.0, 65.0, 59.0, 62.0, 61.0];
    if (trend.isEmpty) return fallback;
    if (trend.length >= 7) return trend.sublist(trend.length - 7);

    return [...List<double>.filled(7 - trend.length, trend.first), ...trend];
  }

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _curve = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        title: const Text(
          'Resting Heart Rate',
          style: TextStyle(
            color: DesignTokens.neonRed,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 1,
          ),
        ),
        iconTheme: const IconThemeData(color: DesignTokens.textSecondary),
      ),
      body: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(),
              const SizedBox(height: 20),
              _buildWeeklyChart(),
              const SizedBox(height: 20),
              _buildZones(),
              const SizedBox(height: 20),
              _buildInsight(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final weeklyRhr = _weeklyRhrData(context);
    final currentRhr = weeklyRhr.last;
    final avgRhr = weeklyRhr.reduce((a, b) => a + b) / weeklyRhr.length;
    final delta = currentRhr - avgRhr;
    final zone = currentRhr < 50
        ? 'Elite'
        : currentRhr <= 65
        ? 'Athletic'
        : currentRhr <= 72
        ? 'Above Average'
        : currentRhr <= 80
        ? 'Average'
        : 'Below Average';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonRed.withValues(alpha: 0.12),
            DesignTokens.bgCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DesignTokens.neonRed.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _HRGaugePainter(
                progress: (currentRhr / 100).clamp(0.3, 0.95) * _curve.value,
                color: DesignTokens.neonRed,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(currentRhr * _curve.value).toInt()}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: DesignTokens.neonRed,
                      ),
                    ),
                    const Text(
                      'bpm',
                      style: TextStyle(
                        fontSize: 12,
                        color: DesignTokens.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This Morning',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _tag(
                  delta <= 0 ? Icons.trending_down : Icons.trending_up,
                  '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} bpm vs avg',
                  delta <= 0 ? DesignTokens.neonGreen : DesignTokens.neonAmber,
                ),
                const SizedBox(height: 4),
                _tag(Icons.favorite, 'Zone: $zone', DesignTokens.neonRed),
                const SizedBox(height: 4),
                _tag(
                  Icons.nightlight,
                  'Measured: 6:15 AM',
                  DesignTokens.neonMagenta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: DesignTokens.textSecondary),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    final weeklyRhr = _weeklyRhrData(context);
    final avgRhr = weeklyRhr.reduce((a, b) => a + b) / weeklyRhr.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.neonRed.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '7-Day Resting HR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Avg: ${avgRhr.toStringAsFixed(0)} bpm',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.neonRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _LineChartPainter(
                data: weeklyRhr,
                progress: _curve.value,
                color: DesignTokens.neonRed,
                days: _days,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZones() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.neonRed.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HR Fitness Zones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _zoneRow('Elite Athlete', '<50 bpm', DesignTokens.neonGold, false),
          _zoneRow('Athletic', '50–65 bpm', DesignTokens.neonGreen, true),
          _zoneRow('Above Average', '65–72 bpm', DesignTokens.neonCyan, false),
          _zoneRow('Average', '72–80 bpm', DesignTokens.neonAmber, false),
          _zoneRow('Below Average', '>80 bpm', DesignTokens.neonRed, false),
        ],
      ),
    );
  }

  Widget _zoneRow(String zone, String range, Color color, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: active ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                zone,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? color : DesignTokens.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            range,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? color : DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsight() {
    final weeklyRhr = _weeklyRhrData(context);
    final currentRhr = weeklyRhr.last;
    final maxRhr = weeklyRhr.reduce(math.max);
    final avgRhr = weeklyRhr.reduce((a, b) => a + b) / weeklyRhr.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonGreen.withValues(alpha: 0.08),
            DesignTokens.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: DesignTokens.neonGreen, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'RHR at ${currentRhr.toStringAsFixed(0)} bpm with a 7-day average of ${avgRhr.toStringAsFixed(0)} bpm. Weekly peak was ${maxRhr.toStringAsFixed(0)} bpm — watch recovery load if elevated after hard sessions.',
              style: const TextStyle(
                fontSize: 14,
                color: DesignTokens.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HRGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  _HRGaugePainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HRGaugePainter old) => progress != old.progress;
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final Color color;
  final List<String> days;
  _LineChartPainter({
    required this.data,
    required this.progress,
    required this.color,
    required this.days,
  });
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final minV = data.reduce(math.min) - 5;
    final maxV = data.reduce(math.max) + 5;
    final range = maxV - minV;
    final stepX = size.width / (data.length - 1);

    // Grid
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y =
          size.height -
          ((data[i] - minV) / range) * size.height * 0.8 -
          size.height * 0.1;
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
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    // Fill gradient
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.15 * progress),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Dots + labels
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, Paint()..color = color);
      canvas.drawCircle(
        points[i],
        6,
        Paint()..color = color.withValues(alpha: 0.2),
      );
      // Day labels
      final tp = TextPainter(
        text: TextSpan(
          text: days[i],
          style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.6)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(points[i].dx - tp.width / 2, size.height - tp.height + 16),
      );
      // Value labels
      final vp = TextPainter(
        text: TextSpan(
          text: '${data[i].toInt()}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      vp.paint(canvas, Offset(points[i].dx - vp.width / 2, points[i].dy - 16));
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => progress != old.progress;
}
