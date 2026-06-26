import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// Normal Heart Rate — Pre-training cardiac baseline
class NormalHRScreen extends StatefulWidget {
  const NormalHRScreen({super.key});

  @override
  State<NormalHRScreen> createState() => _NormalHRScreenState();
}

class _NormalHRScreenState extends State<NormalHRScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _curve;

  final List<int> _weeklyHR = [72, 68, 75, 70, 74, 69, 71];
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
          'Normal Heart Rate',
          style: TextStyle(
            color: DesignTokens.neonGreen,
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
              _buildDailyBreakdown(),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonGreen.withValues(alpha: 0.12),
            DesignTokens.bgCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _OrbPainter(
                progress: 0.71 * _curve.value,
                color: DesignTokens.neonGreen,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(71 * _curve.value).toInt()}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: DesignTokens.neonGreen,
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
                  'Pre-Training HR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _tag(
                  Icons.check_circle,
                  'Status: Normal',
                  DesignTokens.neonGreen,
                ),
                const SizedBox(height: 4),
                _tag(
                  Icons.trending_flat,
                  'Stable this week',
                  DesignTokens.neonCyan,
                ),
                const SizedBox(height: 4),
                _tag(
                  Icons.access_time,
                  'Measured: 2:00 PM',
                  DesignTokens.neonAmber,
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
    final maxVal = _weeklyHR.reduce(math.max).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '7-Day Normal HR',
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
                  color: DesignTokens.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Avg: 71 bpm',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.neonGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final ratio = _weeklyHR[i] / maxVal;
                final color = _weeklyHR[i] <= 70
                    ? DesignTokens.neonGreen
                    : _weeklyHR[i] <= 75
                    ? DesignTokens.neonCyan
                    : DesignTokens.neonAmber;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${_weeklyHR[i]}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 70 * ratio * _curve.value,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [color.withValues(alpha: 0.3), color],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.25),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _days[i],
                        style: const TextStyle(
                          fontSize: 11,
                          color: DesignTokens.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Pattern',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _timeSlot('Morning', '68 bpm', DesignTokens.neonGreen, 0.68),
          _timeSlot('Midday', '72 bpm', DesignTokens.neonCyan, 0.72),
          _timeSlot('Pre-Training', '71 bpm', DesignTokens.neonGreen, 0.71),
          _timeSlot('Evening', '66 bpm', DesignTokens.neonMagenta, 0.66),
        ],
      ),
    );
  }

  Widget _timeSlot(String label, String value, Color color, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: DesignTokens.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct * _curve.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.5), color],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsight() {
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
      child: const Row(
        children: [
          Icon(Icons.psychology, color: DesignTokens.neonGreen, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Normal HR is stable at 71 bpm — consistent with good cardiovascular fitness. Evening drop to 66 bpm shows healthy parasympathetic recovery.',
              style: TextStyle(
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

class _OrbPainter extends CustomPainter {
  final double progress;
  final Color color;
  _OrbPainter({required this.progress, required this.color});
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
  bool shouldRepaint(_OrbPainter old) => progress != old.progress;
}
