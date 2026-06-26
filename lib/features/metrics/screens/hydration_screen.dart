import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// Hydration Command — Fluid intake intelligence
class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _curve;

  final List<double> _weeklyLiters = [2.5, 2.1, 2.8, 3.0, 1.8, 2.4, 2.1];
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final double _target = 3.0;

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
          'Hydration Command',
          style: TextStyle(
            color: DesignTokens.neonCyan,
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
              _buildBenefits(),
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
    final current = 2.1;
    final pct = (current / _target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.12),
            DesignTokens.bgCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _WaterGaugePainter(
                progress: pct * _curve.value,
                color: DesignTokens.neonCyan,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (current * _curve.value).toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: DesignTokens.neonCyan,
                      ),
                    ),
                    Text(
                      '/ ${_target.toStringAsFixed(1)}L',
                      style: const TextStyle(
                        fontSize: 11,
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
                  'Today\'s Intake',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _tag(
                  Icons.water_drop,
                  '${(pct * 100).toInt()}% of goal',
                  pct >= 0.8 ? DesignTokens.neonGreen : DesignTokens.neonAmber,
                ),
                const SizedBox(height: 4),
                _tag(
                  Icons.local_drink,
                  '0.9L remaining',
                  DesignTokens.neonCyan,
                ),
                const SizedBox(height: 4),
                _tag(
                  Icons.schedule,
                  'Next: 250ml in 45min',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '7-Day Hydration',
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
                  color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Avg: 2.4L',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.neonCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final ratio = (_weeklyLiters[i] / _target).clamp(0.0, 1.0);
                final color = _weeklyLiters[i] >= _target
                    ? DesignTokens.neonGreen
                    : _weeklyLiters[i] >= 2.0
                    ? DesignTokens.neonCyan
                    : DesignTokens.neonAmber;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${_weeklyLiters[i]}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        children: [
                          Container(
                            height: 80,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.05,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          Container(
                            height: 80 * ratio * _curve.value,
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
                        ],
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

  Widget _buildBenefits() {
    final items = [
      {
        'icon': Icons.bolt,
        'title': 'Performance',
        'desc': '+12% power when fully hydrated',
        'color': DesignTokens.neonGreen,
      },
      {
        'icon': Icons.psychology,
        'title': 'Focus',
        'desc': 'Reaction time improves 15%',
        'color': DesignTokens.neonCyan,
      },
      {
        'icon': Icons.healing,
        'title': 'Recovery',
        'desc': 'Muscle repair accelerated',
        'color': DesignTokens.neonMagenta,
      },
      {
        'icon': Icons.thermostat,
        'title': 'Temperature',
        'desc': 'Core temp regulation optimal',
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
            'Hydration Impact',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: item['color'] as Color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.textPrimary,
                          ),
                        ),
                        Text(
                          item['desc'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DesignTokens.textMuted,
                          ),
                        ),
                      ],
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

  Widget _buildInsight() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.08),
            DesignTokens.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.psychology, color: DesignTokens.neonCyan, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'You\'re averaging 2.4L — 80% of target. Increase intake by 200ml in the first hour after waking to hit 3L consistently.',
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

class _WaterGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  _WaterGaugePainter({required this.progress, required this.color});
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
  bool shouldRepaint(_WaterGaugePainter old) => progress != old.progress;
}
