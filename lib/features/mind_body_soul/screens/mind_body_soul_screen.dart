import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MIND · BODY · SOUL — The three pillars of the complete fighter.
///
/// The cage tests all three. Most apps only train the body.
/// DFC trains the whole human.
///
///  MIND  — Mental resilience, visualization, focus, fear management
///  BODY  — Physical metrics, recovery, nutrition, sleep optimization
///  SOUL  — Purpose, community, legacy, what fighting means to you
///
/// Each pillar has a live score (0-10) tracked by AI + self-reporting.
/// ═══════════════════════════════════════════════════════════════════════════

class MindBodySoulScreen extends StatefulWidget {
  const MindBodySoulScreen({super.key});

  @override
  State<MindBodySoulScreen> createState() => _MindBodySoulScreenState();
}

class _MindBodySoulScreenState extends State<MindBodySoulScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // Live pillar scores (0-10)
  final _mindScore = 7.4;
  final _bodyScore = 6.8;
  final _soulScore = 8.1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _overallScore => (_mindScore + _bodyScore + _soulScore) / 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background energy field
              CustomPaint(painter: _EnergyFieldPainter(phase: _ctrl.value)),
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildTriangleScore()),
                    SliverToBoxAdapter(child: _buildMindSection()),
                    SliverToBoxAdapter(child: _buildBodySection()),
                    SliverToBoxAdapter(child: _buildSoulSection()),
                    SliverToBoxAdapter(child: _buildDailyRitual()),
                    SliverToBoxAdapter(child: _buildPhilosophy()),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MIND · BODY · SOUL',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'The complete fighter',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRIANGLE SCORE — Unified pillar visualization
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTriangleScore() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: CustomPaint(
              size: const Size(double.infinity, 220),
              painter: _PillarTrianglePainter(
                phase: _ctrl.value,
                mind: _mindScore / 10,
                body: _bodyScore / 10,
                soul: _soulScore / 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'WARRIOR INDEX: ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Text(
                _overallScore.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                ' / 10',
                style: TextStyle(
                  color: AppColors.neonCyan.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MIND — Mental resilience
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMindSection() {
    return _pillarSection(
      'MIND',
      _mindScore,
      AppColors.neonMagenta,
      Icons.psychology,
      'Mental resilience, visualization, focus, fear management',
      [
        const _PillarTool(
          'Visualization Chamber',
          'Pre-fight mental rehearsal with guided imagery',
          Icons.remove_red_eye,
        ),
        const _PillarTool(
          'Fear Mapping',
          'Identify, confront, and reframe your fight fears',
          Icons.map,
        ),
        const _PillarTool(
          'Focus Timer',
          'Deep work sessions with HRV-guided breaks',
          Icons.timer,
        ),
        const _PillarTool(
          'Fight Film Study',
          'Analyze opponents with AI-annotated footage',
          Icons.slow_motion_video,
        ),
      ],
      [
        const _Insight(
          'Focus duration increased 23% this month',
          AppColors.neonGreen,
        ),
        const _Insight(
          'Pre-fight anxiety patterns detected — visualization recommended',
          AppColors.neonOrange,
        ),
        const _Insight('Meditation streak: 12 days consecutive', AppColors.neonCyan),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BODY — Physical system
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBodySection() {
    return _pillarSection(
      'BODY',
      _bodyScore,
      AppColors.neonGreen,
      Icons.fitness_center,
      'Physical metrics, recovery, nutrition, sleep optimization',
      [
        const _PillarTool(
          'Recovery Matrix',
          'Real-time recovery score from HRV, sleep, and training load',
          Icons.healing,
        ),
        const _PillarTool(
          'Sleep Architecture',
          'Deep sleep, REM cycles, and circadian rhythm optimization',
          Icons.bedtime,
        ),
        const _PillarTool(
          'Nutrition Fuel',
          'Macro tracking aligned to training phases',
          Icons.restaurant,
        ),
        const _PillarTool(
          'Movement Lab',
          'Mobility assessment and corrective exercise protocols',
          Icons.accessibility_new,
        ),
      ],
      [
        const _Insight(
          'Sleep quality dropped 15% — correlates with late training sessions',
          AppColors.neonOrange,
        ),
        const _Insight(
          'VO₂ max trending upward: 52.3 ml/kg/min (+2.1 this month)',
          AppColors.neonGreen,
        ),
        const _Insight(
          'Hydration consistently below target on sparring days',
          AppColors.neonRed,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SOUL — Purpose & legacy
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSoulSection() {
    return _pillarSection(
      'SOUL',
      _soulScore,
      AppColors.neonPurple,
      Icons.auto_awesome,
      'Purpose, community, legacy, what fighting means to you',
      [
        const _PillarTool(
          'Legacy Journal',
          'Document your journey — wins, losses, lessons, growth',
          Icons.book,
        ),
        const _PillarTool(
          'Mentor Connection',
          'Connect with retired fighters who\'ve walked the path',
          Icons.people,
        ),
        const _PillarTool(
          'Community Give Back',
          'Youth coaching, charity events, spreading the art',
          Icons.volunteer_activism,
        ),
        const _PillarTool(
          'Purpose Compass',
          'Why do you fight? Guided reflection on your deeper mission',
          Icons.explore,
        ),
      ],
      [
        const _Insight(
          'Community engagement: 3 mentoring sessions this month',
          AppColors.neonGreen,
        ),
        const _Insight(
          'Legacy journal entries increasing — strong narrative building',
          AppColors.neonCyan,
        ),
        const _Insight(
          'Your "why" alignment score is high — purpose is clear',
          AppColors.neonPurple,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DAILY RITUAL — The routine that connects all three
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDailyRitual() {
    final rituals = [
      const _Ritual(
        'DAWN',
        '5:30 AM',
        'Breathwork + Visualization (Mind)',
        AppColors.neonMagenta,
        true,
      ),
      const _Ritual(
        'MORNING',
        '7:00 AM',
        'Training Session (Body)',
        AppColors.neonGreen,
        true,
      ),
      const _Ritual(
        'MIDDAY',
        '12:00 PM',
        'Nutrition + Recovery Check (Body)',
        AppColors.neonGreen,
        false,
      ),
      const _Ritual(
        'AFTERNOON',
        '3:00 PM',
        'Technique Study + Sparring (Mind + Body)',
        AppColors.neonOrange,
        false,
      ),
      const _Ritual(
        'EVENING',
        '7:00 PM',
        'Journal + Mentor Call (Soul)',
        AppColors.neonPurple,
        false,
      ),
      const _Ritual(
        'NIGHT',
        '9:30 PM',
        'Sleep Protocol — Devices Track Overnight (All)',
        AppColors.neonCyan,
        false,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('DAILY RITUAL', AppColors.neonCyan),
          const SizedBox(height: 4),
          Text(
            'Your optimized routine — synced to your biometrics',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          ...rituals.map((r) => _RitualCard(ritual: r, pulse: _ctrl.value)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHILOSOPHY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPhilosophy() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.02),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          children: [
            Text(
              'THE WAY OF THE WARRIOR',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The mind decides the fight before it starts. The body executes what the mind commands. The soul determines why you fight at all. Train all three — or you train nothing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 12,
                height: 1.7,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PILLAR SECTION BUILDER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _pillarSection(
    String name,
    double score,
    Color color,
    IconData icon,
    String subtitle,
    List<_PillarTool> tools,
    List<_Insight> insights,
  ) {
    final p = math.sin(_ctrl.value * math.pi * 2) * 0.5 + 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(name, color),
          const SizedBox(height: 12),
          // Score card
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: color.withValues(alpha: 0.03),
                  border: Border.all(
                    color: color.withValues(alpha: 0.1 + p * 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 9,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              score.toStringAsFixed(1),
                              style: TextStyle(
                                color: color,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '/ 10',
                              style: TextStyle(
                                color: color.withValues(alpha: 0.4),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Score bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: score / 10,
                        backgroundColor: color.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation(
                          color.withValues(alpha: 0.5),
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Tools
                    ...tools.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: color.withValues(alpha: 0.06),
                              ),
                              child: Icon(
                                t.icon,
                                color: color.withValues(alpha: 0.5),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.name,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    t.desc,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                      fontSize: 9,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: color.withValues(alpha: 0.2),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // AI Insights
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white.withValues(alpha: 0.02),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI INSIGHTS',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...insights.map(
                            (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i.color,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      i.text,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        fontSize: 10,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _label(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═════════════════════════════════════════════════════════════════════════════
class _PillarTool {
  final String name, desc;
  final IconData icon;
  const _PillarTool(this.name, this.desc, this.icon);
}

class _Insight {
  final String text;
  final Color color;
  const _Insight(this.text, this.color);
}

class _Ritual {
  final String time, label, desc;
  final Color color;
  final bool done;
  const _Ritual(this.time, this.label, this.desc, this.color, this.done);
}

// ═════════════════════════════════════════════════════════════════════════════
// ENERGY FIELD — Background particle aura
// ═════════════════════════════════════════════════════════════════════════════
class _EnergyFieldPainter extends CustomPainter {
  final double phase;

  _EnergyFieldPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      AppColors.neonMagenta,
      AppColors.neonGreen,
      AppColors.neonPurple,
    ];
    for (int i = 0; i < 3; i++) {
      final cx = size.width * (0.2 + i * 0.3);
      final cy =
          size.height * (0.15 + math.sin(phase * math.pi * 2 + i) * 0.05);
      canvas.drawCircle(
        Offset(cx, cy),
        80 + math.sin(phase * math.pi * 2 + i * 2) * 20,
        Paint()
          ..color = colors[i].withValues(alpha: 0.015)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyFieldPainter old) => old.phase != phase;
}

// ═════════════════════════════════════════════════════════════════════════════
// PILLAR TRIANGLE — Mind/Body/Soul score visualization
// ═════════════════════════════════════════════════════════════════════════════
class _PillarTrianglePainter extends CustomPainter {
  final double phase, mind, body, soul;

  _PillarTrianglePainter({
    required this.phase,
    required this.mind,
    required this.body,
    required this.soul,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.min(cx, cy) - 30;

    // Vertices
    final mindPos = Offset(cx, cy - maxR); // top
    final bodyPos = Offset(cx - maxR * 0.87, cy + maxR * 0.5); // bottom-left
    final soulPos = Offset(cx + maxR * 0.87, cy + maxR * 0.5); // bottom-right

    final vertices = [mindPos, bodyPos, soulPos];
    final scores = [mind, body, soul];
    final colors = [
      AppColors.neonMagenta,
      AppColors.neonGreen,
      AppColors.neonPurple,
    ];
    final labels = ['MIND', 'BODY', 'SOUL'];

    // Outer triangle
    final outerPath = Path()
      ..moveTo(mindPos.dx, mindPos.dy)
      ..lineTo(bodyPos.dx, bodyPos.dy)
      ..lineTo(soulPos.dx, soulPos.dy)
      ..close();

    canvas.drawPath(
      outerPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // Score triangle
    final pulse = math.sin(phase * math.pi * 2) * 0.02;
    final scorePath = Path();
    for (int i = 0; i < 3; i++) {
      final v = vertices[i];
      final s = scores[i] + pulse;
      final sx = cx + (v.dx - cx) * s;
      final sy = cy + (v.dy - cy) * s;
      if (i == 0) {
        scorePath.moveTo(sx, sy);
      } else {
        scorePath.lineTo(sx, sy);
      }
    }
    scorePath.close();

    // Fill
    canvas.drawPath(
      scorePath,
      Paint()..color = AppColors.neonCyan.withValues(alpha: 0.06),
    );

    // Border
    canvas.drawPath(
      scorePath,
      Paint()
        ..color = AppColors.neonCyan.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Vertices + labels
    for (int i = 0; i < 3; i++) {
      final v = vertices[i];
      final s = scores[i] + pulse;
      final sx = cx + (v.dx - cx) * s;
      final sy = cy + (v.dy - cy) * s;
      final p = math.sin(phase * math.pi * 2 + i) * 0.5 + 0.5;

      // Glow
      canvas.drawCircle(
        Offset(sx, sy),
        10 + p * 4,
        Paint()
          ..color = colors[i].withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      canvas.drawCircle(
        Offset(sx, sy),
        5,
        Paint()..color = colors[i].withValues(alpha: 0.6),
      );

      // Score text
      final scoreTp = TextPainter(
        text: TextSpan(
          text: (scores[i] * 10).toStringAsFixed(1),
          style: TextStyle(
            color: colors[i],
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Label
      final labelTp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: colors[i].withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelOffset = i == 0
          ? Offset(v.dx - labelTp.width / 2, v.dy - 22)
          : Offset(v.dx - labelTp.width / 2, v.dy + 12);
      labelTp.paint(canvas, labelOffset);

      final scoreOffset = i == 0
          ? Offset(v.dx - scoreTp.width / 2, v.dy - 36)
          : Offset(v.dx - scoreTp.width / 2, v.dy + 24);
      scoreTp.paint(canvas, scoreOffset);
    }

    // Center emblem
    final centerTp = TextPainter(
      text: TextSpan(
        text: ((mind + body + soul) / 3 * 10).toStringAsFixed(1),
        style: TextStyle(
          color: AppColors.neonCyan.withValues(alpha: 0.4),
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    centerTp.paint(
      canvas,
      Offset(cx - centerTp.width / 2, cy - centerTp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PillarTrianglePainter old) =>
      old.phase != phase;
}

// ═════════════════════════════════════════════════════════════════════════════
// RITUAL CARD
// ═════════════════════════════════════════════════════════════════════════════
class _RitualCard extends StatelessWidget {
  final _Ritual ritual;
  final double pulse;

  const _RitualCard({required this.ritual, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 50,
            child: Text(
              ritual.label,
              style: TextStyle(
                color: ritual.color.withValues(alpha: 0.5),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Timeline dot + line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ritual.done
                      ? ritual.color.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: ritual.color.withValues(
                      alpha: ritual.done ? 0.5 : 0.15,
                    ),
                    width: 1.5,
                  ),
                ),
                child: ritual.done
                    ? Icon(
                        Icons.check,
                        size: 6,
                        color: Colors.white.withValues(alpha: 0.8),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: ritual.color.withValues(
                  alpha: ritual.done ? 0.04 : 0.02,
                ),
                border: Border.all(
                  color: ritual.color.withValues(
                    alpha: ritual.done ? 0.1 : 0.04,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ritual.desc,
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: ritual.done ? 0.6 : 0.35,
                            ),
                            fontSize: 11,
                            decoration: ritual.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    ritual.label,
                    style: TextStyle(
                      color: ritual.color.withValues(alpha: 0.3),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
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
}
