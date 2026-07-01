import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// AI Performance Coach — Neural coaching intelligence
class AIPerformanceCoachScreen extends StatefulWidget {
  const AIPerformanceCoachScreen({super.key});

  @override
  State<AIPerformanceCoachScreen> createState() =>
      _AIPerformanceCoachScreenState();
}

class _AIPerformanceCoachScreenState extends State<AIPerformanceCoachScreen>
    with TickerProviderStateMixin {
  late AnimationController _anim;
  late AnimationController _pulse;
  late Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _curve = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    _pulse.dispose();
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
          'AI Performance Coach',
          style: TextStyle(
            color: DesignTokens.neonMagenta,
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
              _buildCoachOrb(),
              const SizedBox(height: 24),
              _buildPerformanceScores(),
              const SizedBox(height: 24),
              _buildCoachAdvice(),
              const SizedBox(height: 24),
              _buildTrainingPlan(),
              const SizedBox(height: 24),
              _buildWeeklyFocus(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoachOrb() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DesignTokens.neonMagenta.withValues(
                alpha: 0.1 + 0.04 * _pulse.value,
              ),
              DesignTokens.neonCyan.withValues(alpha: 0.05),
              DesignTokens.bgCard,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: DesignTokens.neonMagenta.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DesignTokens.neonMagenta, DesignTokens.neonCyan],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.neonMagenta.withValues(
                      alpha: 0.3 * _pulse.value,
                    ),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Neural Coach Online',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DesignTokens.neonGreen,
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.neonGreen.withValues(
                                alpha: 0.6,
                              ),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Analyzing your data in real-time',
                        style: TextStyle(
                          fontSize: 13,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceScores() {
    final scores = [
      {
        'title': 'Focus',
        'score': 8,
        'max': 10,
        'color': DesignTokens.neonCyan,
        'icon': Icons.center_focus_strong,
      },
      {
        'title': 'Attitude',
        'score': 9,
        'max': 10,
        'color': DesignTokens.neonGreen,
        'icon': Icons.emoji_emotions,
      },
      {
        'title': 'Discipline',
        'score': 7,
        'max': 10,
        'color': DesignTokens.neonAmber,
        'icon': Icons.military_tech,
      },
      {
        'title': 'Recovery',
        'score': 8,
        'max': 10,
        'color': DesignTokens.neonMagenta,
        'icon': Icons.healing,
      },
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Scores',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: scores.map((s) {
              final pct = (s['score'] as int) / (s['max'] as int);
              return Column(
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CustomPaint(
                      painter: _ScoreRingPainter(
                        progress: pct * _curve.value,
                        color: s['color'] as Color,
                      ),
                      child: Center(
                        child: Text(
                          '${s['score']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: s['color'] as Color,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s['title'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DesignTokens.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachAdvice() {
    final tips = [
      {
        'icon': Icons.bedtime,
        'title': 'Sleep 8+ Hours',
        'desc': 'Your REM cycles improve motor learning by 23%',
        'color': DesignTokens.neonMagenta,
      },
      {
        'icon': Icons.water_drop,
        'title': 'Hydrate Early',
        'desc': 'Aim for 500ml within first hour of waking',
        'color': DesignTokens.neonCyan,
      },
      {
        'icon': Icons.restaurant,
        'title': 'Pre-Training Fuel',
        'desc': 'Complex carbs 90 min before session',
        'color': DesignTokens.neonAmber,
      },
      {
        'icon': Icons.visibility,
        'title': 'Visualize Success',
        'desc': '5 min mental rehearsal improves execution',
        'color': DesignTokens.neonGreen,
      },
      {
        'icon': Icons.videocam,
        'title': 'Review Footage',
        'desc': 'Watch last sparring — identify 3 patterns',
        'color': DesignTokens.neonRed,
      },
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coach Recommendations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (t['color'] as Color).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      t['icon'] as IconData,
                      color: t['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['title'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.textPrimary,
                          ),
                        ),
                        Text(
                          t['desc'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            color: DesignTokens.textMuted,
                            height: 1.3,
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

  Widget _buildTrainingPlan() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.08),
            DesignTokens.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: DesignTokens.neonCyan,
              ),
              SizedBox(width: 8),
              Text(
                'Today\'s Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _planItem(
            '08:00',
            'Morning Mobility',
            '15 min',
            DesignTokens.neonGreen,
            true,
          ),
          _planItem(
            '10:00',
            'Pad Work — Power',
            '45 min',
            DesignTokens.neonAmber,
            false,
          ),
          _planItem(
            '14:00',
            'Sparring Rounds',
            '30 min',
            DesignTokens.neonRed,
            false,
          ),
          _planItem(
            '16:00',
            'Strength & Conditioning',
            '40 min',
            DesignTokens.neonCyan,
            false,
          ),
          _planItem(
            '20:00',
            'Recovery Protocol',
            '20 min',
            DesignTokens.neonMagenta,
            false,
          ),
        ],
      ),
    );
  }

  Widget _planItem(
    String time,
    String title,
    String duration,
    Color color,
    bool done,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: DesignTokens.textMuted,
              ),
            ),
          ),
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: done
                        ? DesignTokens.textMuted
                        : DesignTokens.textPrimary,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  duration,
                  style: const TextStyle(fontSize: 12, color: DesignTokens.textMuted),
                ),
              ],
            ),
          ),
          if (done)
            const Icon(Icons.check_circle, size: 20, color: DesignTokens.neonGreen),
        ],
      ),
    );
  }

  Widget _buildWeeklyFocus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonAmber.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Week\'s Focus Areas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _focusBar('Jab technique', 0.85, DesignTokens.neonGreen),
          _focusBar('Footwork angles', 0.6, DesignTokens.neonCyan),
          _focusBar('Counter timing', 0.45, DesignTokens.neonAmber),
          _focusBar('Clinch control', 0.7, DesignTokens.neonMagenta),
        ],
      ),
    );
  }

  Widget _focusBar(String label, double pct, Color color) {
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textPrimary,
                ),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
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
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ScoreRingPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => progress != old.progress;
}
