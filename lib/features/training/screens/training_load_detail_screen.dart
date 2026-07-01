import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// Training Load Analytics — Volume, intensity & AI insight intelligence
class TrainingLoadDetailScreen extends StatefulWidget {
  const TrainingLoadDetailScreen({super.key});

  @override
  State<TrainingLoadDetailScreen> createState() =>
      _TrainingLoadDetailScreenState();
}

class _TrainingLoadDetailScreenState extends State<TrainingLoadDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _curve;

  final List<Map<String, dynamic>> _weeklyLoad = [
    {'day': 'Mon', 'load': 180, 'type': 'Pad Work'},
    {'day': 'Tue', 'load': 140, 'type': 'Conditioning'},
    {'day': 'Wed', 'load': 220, 'type': 'Sparring'},
    {'day': 'Thu', 'load': 100, 'type': 'Recovery'},
    {'day': 'Fri', 'load': 170, 'type': 'Bag Work'},
    {'day': 'Sat', 'load': 80, 'type': 'Light'},
    {'day': 'Sun', 'load': 20, 'type': 'Rest'},
  ];

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
          'Training Load',
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
              _buildSummaryCard(),
              const SizedBox(height: 20),
              _buildWeeklyBars(),
              const SizedBox(height: 20),
              _buildLoadZones(),
              const SizedBox(height: 20),
              _buildTrendAnalysis(),
              const SizedBox(height: 20),
              _buildInsight(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final total = _weeklyLoad.fold<int>(
      0,
      (sum, e) => sum + (e['load'] as int),
    );
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
              painter: _LoadGaugePainter(
                progress: (total / 1200).clamp(0.0, 1.0) * _curve.value,
                color: DesignTokens.neonGreen,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(total * _curve.value).toInt()}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: DesignTokens.neonGreen,
                      ),
                    ),
                    const Text(
                      'AU',
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
                  'Weekly Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _tag(
                  Icons.trending_up,
                  '+12% vs last week',
                  DesignTokens.neonGreen,
                ),
                const SizedBox(height: 4),
                _tag(
                  Icons.balance,
                  'Load:Recovery = 1.2',
                  DesignTokens.neonCyan,
                ),
                const SizedBox(height: 4),
                _tag(
                  Icons.warning_amber,
                  'Overtraining risk: Low',
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

  Widget _buildWeeklyBars() {
    final maxLoad = _weeklyLoad
        .map((e) => e['load'] as int)
        .reduce(math.max)
        .toDouble();
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
          const Text(
            'Daily Load Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyLoad.map((d) {
                final ratio = (d['load'] as int) / maxLoad;
                final color = ratio > 0.8
                    ? DesignTokens.neonAmber
                    : ratio > 0.3
                    ? DesignTokens.neonGreen
                    : DesignTokens.textMuted;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${d['load']}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 90 * ratio * _curve.value,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
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
                        d['day'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: DesignTokens.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        d['type'] as String,
                        style: const TextStyle(
                          fontSize: 8,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadZones() {
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
            'Training Zones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _zoneRow('High Intensity', '35%', 0.35, DesignTokens.neonRed),
          _zoneRow('Moderate', '40%', 0.40, DesignTokens.neonAmber),
          _zoneRow('Low / Recovery', '25%', 0.25, DesignTokens.neonGreen),
        ],
      ),
    );
  }

  Widget _zoneRow(String label, String pct, double ratio, Color color) {
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
                widthFactor: ratio * _curve.value * 2.5,
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
            pct,
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

  Widget _buildTrendAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonAmber.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '4-Week Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _trendRow('Week 1', 780, 1200, DesignTokens.neonCyan),
          _trendRow('Week 2', 920, 1200, DesignTokens.neonCyan),
          _trendRow('Week 3', 1050, 1200, DesignTokens.neonAmber),
          _trendRow('Week 4 (current)', 910, 1200, DesignTokens.neonGreen),
        ],
      ),
    );
  }

  Widget _trendRow(String label, int value, int max, Color color) {
    final ratio = value / max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textSecondary,
                ),
              ),
              Text(
                '$value AU',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio * _curve.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.5), color],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
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
              'Week 3 peak at 1,050 AU was close to overreach threshold. Current deload to 910 AU is optimal — maintaining fitness while promoting supercompensation.',
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

class _LoadGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  _LoadGaugePainter({required this.progress, required this.color});
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
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_LoadGaugePainter old) => progress != old.progress;
}
