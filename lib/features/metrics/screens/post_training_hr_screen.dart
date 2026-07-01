import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// Post-Training Heart Rate — Recovery velocity intelligence
class PostTrainingHRScreen extends StatefulWidget {
  const PostTrainingHRScreen({super.key});

  @override
  State<PostTrainingHRScreen> createState() => _PostTrainingHRScreenState();
}

class _PostTrainingHRScreenState extends State<PostTrainingHRScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _curve;

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
          'Post-Training HR',
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
              _buildRecoveryCurve(),
              const SizedBox(height: 20),
              _buildSessionComparison(),
              const SizedBox(height: 20),
              _buildRecoverySpeed(),
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
            DesignTokens.neonAmber.withValues(alpha: 0.12),
            DesignTokens.bgCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: DesignTokens.neonAmber.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _DualRingPainter(
                peak: 0.88 * _curve.value,
                recovery: 0.45 * _curve.value,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(165 * _curve.value).toInt()}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: DesignTokens.neonAmber,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_downward,
                      size: 14,
                      color: DesignTokens.neonGreen,
                    ),
                    Text(
                      '${(82 * _curve.value).toInt()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.neonGreen,
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
                  'Last Session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _tag(
                  Icons.arrow_upward,
                  'Peak: 165 bpm',
                  DesignTokens.neonAmber,
                ),
                const SizedBox(height: 4),
                _tag(
                  Icons.arrow_downward,
                  'Recovery: 82 bpm',
                  DesignTokens.neonGreen,
                ),
                const SizedBox(height: 4),
                _tag(Icons.timer, 'Recovery: 4m 30s', DesignTokens.neonCyan),
                const SizedBox(height: 4),
                _tag(
                  Icons.fitness_center,
                  'Pad Work — 45 min',
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

  Widget _buildRecoveryCurve() {
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
            'Recovery Curve',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Heart rate descent after peak exertion',
            style: TextStyle(fontSize: 13, color: DesignTokens.textMuted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _RecoveryCurvePainter(progress: _curve.value),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionComparison() {
    final sessions = [
      {
        'type': 'Pad Work',
        'peak': 165,
        'recovery': 82,
        'time': '4:30',
        'color': DesignTokens.neonAmber,
      },
      {
        'type': 'Sparring',
        'peak': 178,
        'recovery': 95,
        'time': '5:45',
        'color': DesignTokens.neonRed,
      },
      {
        'type': 'Road Run',
        'peak': 155,
        'recovery': 75,
        'time': '3:15',
        'color': DesignTokens.neonGreen,
      },
      {
        'type': 'Bag Work',
        'peak': 160,
        'recovery': 80,
        'time': '4:00',
        'color': DesignTokens.neonCyan,
      },
    ];
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
            'Session Comparison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...sessions.map(
            (s) => Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (s['color'] as Color).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (s['color'] as Color).withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s['type'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      _miniStat('Peak', '${s['peak']}', s['color'] as Color),
                      const SizedBox(width: 14),
                      _miniStat(
                        'Rec',
                        '${s['recovery']}',
                        DesignTokens.neonGreen,
                      ),
                      const SizedBox(width: 14),
                      _miniStat(
                        'Time',
                        s['time'] as String,
                        DesignTokens.neonCyan,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: DesignTokens.textMuted),
        ),
      ],
    );
  }

  Widget _buildRecoverySpeed() {
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
            'Recovery Speed Rating',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _speedRow(
            '1-min recovery',
            '-30 bpm',
            0.85,
            DesignTokens.neonGreen,
            'Excellent',
          ),
          _speedRow(
            '3-min recovery',
            '-65 bpm',
            0.78,
            DesignTokens.neonGreen,
            'Good',
          ),
          _speedRow(
            '5-min recovery',
            '-83 bpm',
            0.92,
            DesignTokens.neonGreen,
            'Excellent',
          ),
        ],
      ),
    );
  }

  Widget _speedRow(
    String label,
    String drop,
    double pct,
    Color color,
    String grade,
  ) {
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
              Row(
                children: [
                  Text(
                    drop,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      grade,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
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
              widthFactor: pct * _curve.value,
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
              'Recovery velocity is excellent — 30 bpm drop in first minute indicates strong cardiovascular fitness. Sparring sessions take longest to recover — normal for high-intensity intervals.',
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

class _DualRingPainter extends CustomPainter {
  final double peak;
  final double recovery;
  _DualRingPainter({required this.peak, required this.recovery});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = DesignTokens.neonAmber.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * peak,
      false,
      Paint()
        ..color = DesignTokens.neonAmber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 10),
      -math.pi / 2,
      2 * math.pi * recovery,
      false,
      Paint()
        ..color = DesignTokens.neonGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DualRingPainter old) =>
      peak != old.peak || recovery != old.recovery;
}

class _RecoveryCurvePainter extends CustomPainter {
  final double progress;
  _RecoveryCurvePainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final hrValues = [165.0, 140.0, 120.0, 105.0, 95.0, 88.0, 84.0, 82.0];
    final labels = ['0s', '30s', '1m', '1.5m', '2m', '3m', '4m', '4.5m'];
    final minV = 75.0;
    final maxV = 175.0;
    final range = maxV - minV;
    final stepX = size.width / (hrValues.length - 1);

    // Grid
    for (int i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = DesignTokens.neonAmber.withValues(alpha: 0.06)
          ..strokeWidth = 0.5,
      );
    }

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];
    for (int i = 0; i < hrValues.length; i++) {
      final x = i * stepX;
      final y =
          size.height - ((hrValues[i] - minV) / range) * size.height * 0.85;
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

    final gradColors = [DesignTokens.neonAmber, DesignTokens.neonGreen];
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            gradColors[0].withValues(alpha: 0.12 * progress),
            gradColors[1].withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: gradColors,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    for (int i = 0; i < points.length; i++) {
      final t = i / (points.length - 1);
      final dotColor = Color.lerp(
        DesignTokens.neonAmber,
        DesignTokens.neonGreen,
        t,
      )!;
      canvas.drawCircle(points[i], 3.5, Paint()..color = dotColor);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 9, color: DesignTokens.textMuted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, size.height + 4));
    }
  }

  @override
  bool shouldRepaint(_RecoveryCurvePainter old) => progress != old.progress;
}
