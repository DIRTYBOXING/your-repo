import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// Stress Monitor — Autonomic nervous system intelligence
class StressScreen extends StatefulWidget {
  const StressScreen({super.key});

  @override
  State<StressScreen> createState() => _StressScreenState();
}

class _StressScreenState extends State<StressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _curve;

  final List<int> _weeklyStress = [3, 4, 5, 6, 4, 3, 3];
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
          'Stress Monitor',
          style: TextStyle(
            color: DesignTokens.neonAmber,
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
              _buildStressFactors(),
              const SizedBox(height: 20),
              _buildCopingStrategies(),
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
    const level = 3;
    final color = level <= 3
        ? DesignTokens.neonGreen
        : level <= 6
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;
    final label = level <= 3
        ? 'LOW'
        : level <= 6
        ? 'MODERATE'
        : 'HIGH';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.12), DesignTokens.bgCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _StressGaugePainter(
                progress: (level / 10) * _curve.value,
                color: color,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$level',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    const Text(
                      '/10',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Current Stress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Autonomic balance: good\nCortisol estimate: normal',
                  style: TextStyle(
                    fontSize: 13,
                    color: DesignTokens.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
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
            '7-Day Stress Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final ratio = _weeklyStress[i] / 10;
                final color = _weeklyStress[i] <= 3
                    ? DesignTokens.neonGreen
                    : _weeklyStress[i] <= 6
                    ? DesignTokens.neonAmber
                    : DesignTokens.neonRed;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${_weeklyStress[i]}',
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

  Widget _buildStressFactors() {
    final factors = [
      {
        'name': 'Training Volume',
        'impact': 0.7,
        'color': DesignTokens.neonAmber,
      },
      {
        'name': 'Sleep Deficit',
        'impact': 0.4,
        'color': DesignTokens.neonMagenta,
      },
      {'name': 'Weight Cut', 'impact': 0.6, 'color': DesignTokens.neonRed},
      {'name': 'Mental Load', 'impact': 0.3, 'color': DesignTokens.neonCyan},
    ];
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
            'Stress Contributors',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...factors.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      f['name'] as String,
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
                        color: (f['color'] as Color).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (f['impact'] as double) * _curve.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                (f['color'] as Color).withValues(alpha: 0.5),
                                f['color'] as Color,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: (f['color'] as Color).withValues(
                                  alpha: 0.3,
                                ),
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
                    '${((f['impact'] as double) * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: f['color'] as Color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopingStrategies() {
    final strategies = [
      {
        'icon': Icons.self_improvement,
        'title': 'Breathwork',
        'desc': '4-7-8 technique • 5 min',
        'color': DesignTokens.neonGreen,
      },
      {
        'icon': Icons.spa,
        'title': 'Cold Exposure',
        'desc': 'Ice bath • 3 min',
        'color': DesignTokens.neonCyan,
      },
      {
        'icon': Icons.headphones,
        'title': 'Guided Meditation',
        'desc': 'Body scan • 10 min',
        'color': DesignTokens.neonMagenta,
      },
      {
        'icon': Icons.directions_walk,
        'title': 'Active Recovery',
        'desc': 'Light walk • 20 min',
        'color': DesignTokens.neonAmber,
      },
    ];
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
            'Coping Strategies',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...strategies.map(
            (s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (s['color'] as Color).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      s['icon'] as IconData,
                      color: s['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.textPrimary,
                          ),
                        ),
                        Text(
                          s['desc'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DesignTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.play_circle_outline,
                    color: (s['color'] as Color).withValues(alpha: 0.5),
                    size: 24,
                  ),
                ],
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
              'Stress levels are well managed. Wednesday spike correlated with increased sparring volume — consider adding a breathwork session post-training.',
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

class _StressGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  _StressGaugePainter({required this.progress, required this.color});
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
  bool shouldRepaint(_StressGaugePainter old) => progress != old.progress;
}
