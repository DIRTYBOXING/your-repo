// Premium Dashboard Widgets - Glass-morphism panels with neon glow
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/fight_camp_service.dart';
import '../../../shared/widgets/glass_components.dart'; // GlassPanel widget
import '../../../shared/widgets/dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PREMIUM TRAINING DASHBOARD PANELS - 2026 Flagship UI Components
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Glass-morphism panels with neon glow effects for the Training Dashboard:
/// - CampStatusPanel - Fight camp phase indicator
/// - TrainingLoadPanel - Load/Recovery balance
/// - StatsRow - Quick stat indicators
/// - AdaptationChart - Performance trend visualization
/// ═══════════════════════════════════════════════════════════════════════════

/// Floating orb particle for cosmic background
class FloatingOrb {
  double x;
  double y;
  double radius;
  double speed;
  double opacity;
  Color color;

  FloatingOrb({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}

/// Temporary CornerVoice class for motivational quotes
class CornerVoice {
  static const List<String> _quotes = [
    "Stay focused, champ.",
    "Every round counts.",
    "Train hard, win easy.",
    "Your only limit is you.",
    "Push past the pain.",
    "Greatness is earned.",
    "Rest. Recover. Rise.",
    "Discipline beats motivation.",
    "Visualize victory.",
    "One step at a time.",
    "Consistency is key.",
    "Champions train, losers complain.",
    "You are your only competition.",
    "No shortcuts to success.",
    "Embrace the grind.",
    "Fight for your dreams.",
    "Stay hungry, stay humble.",
    "Make today count.",
    "Winners never quit.",
    "Rise and shine.",
    "Outwork yesterday.",
    "Mind over matter.",
    "Strength in struggle.",
    "Dedication defines destiny.",
    "Never back down.",
    "Finish strong.",
    "Believe and achieve.",
    "Earn your respect.",
    "Keep moving forward.",
    "The ring is yours.",
  ];

  static String quote(int day) {
    // Cycle through quotes based on the day
    return _quotes[day % _quotes.length];
  }
}

/// Star particle for dense starfield
class StarParticle {
  final double x;
  final double y;
  final double size;
  final double brightness;
  final bool isGlowing;

  StarParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
    this.isGlowing = false,
  });
}

/// Cosmic background painter with starfield and floating orbs
class CosmicBackgroundPainter extends CustomPainter {
  final List<FloatingOrb> orbs;
  final double animation;
  late final List<StarParticle> stars;

  CosmicBackgroundPainter({required this.orbs, required this.animation}) {
    final random = math.Random(42);
    stars = List.generate(200, (i) {
      return StarParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 2 + 0.5,
        brightness: random.nextDouble() * 0.8 + 0.2,
        isGlowing: random.nextDouble() > 0.85,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    // ── Deep space gradient ──────────────────────────────────────────────
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF020610), Color(0xFF050A18), Color(0xFF0B1228)],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // ── Twinkling starfield ─────────────────────────────────────────────
    for (final star in stars) {
      final twinkle = star.isGlowing
          ? (math.sin(animation * math.pi * 2 + star.x * 20) * 0.4 + 0.6)
          : star.brightness;
      final alpha = (twinkle * 0.9).clamp(0.0, 1.0);
      final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
      // Glow halo on bright stars
      if (star.isGlowing) {
        canvas.drawCircle(
          Offset(star.x * size.width, star.y * size.height),
          star.size * 3,
          Paint()..color = AppTheme.neonCyan.withValues(alpha: alpha * 0.08),
        );
      }
    }

    // ── Animated floating orbs with drift ────────────────────────────────
    for (var orb in orbs) {
      final drift = math.sin(animation * math.pi * 2 * orb.speed) * 0.02;
      final ox = (orb.x + drift) * size.width;
      final oy = (orb.y + drift * 0.7) * size.height;

      // Outer glow
      canvas.drawCircle(
        Offset(ox, oy),
        orb.radius * 2.5,
        Paint()..color = orb.color.withValues(alpha: orb.opacity * 0.15),
      );
      // Mid glow
      canvas.drawCircle(
        Offset(ox, oy),
        orb.radius * 1.2,
        Paint()..color = orb.color.withValues(alpha: orb.opacity * 0.35),
      );
      // Core
      canvas.drawCircle(
        Offset(ox, oy),
        orb.radius * 0.5,
        Paint()..color = orb.color.withValues(alpha: orb.opacity * 0.7),
      );
    }

    // ── Subtle hexagon grid overlay ──────────────────────────────────────
    _drawHexGrid(canvas, size);
  }

  void _drawHexGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.neonCyan.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const hexSize = 40.0;
    final rows = (size.height / (hexSize * 1.5)).ceil() + 1;
    final cols = (size.width / (hexSize * 1.732)).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final offsetX =
            col * hexSize * 1.732 + (row.isOdd ? hexSize * 0.866 : 0);
        final offsetY = row * hexSize * 1.5;
        _drawHexagon(canvas, Offset(offsetX, offsetY), hexSize, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * math.pi / 180;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CosmicBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Camp Status Panel - Shows fight camp phase
class CampStatusPanel extends StatelessWidget {
  const CampStatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final FightCampService? fightCampService;
    try {
      fightCampService = Provider.of<FightCampService>(context);
    } catch (e) {
      debugPrint('CampStatusPanel: Provider read failed: $e');
      return const GlassPanel(
        glowColor: AppTheme.neonCyan,
        padding: EdgeInsets.all(12),
        child: Center(
          child: Text(
            'Camp status loading...',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      );
    }
    final theme = fightCampService.currentTheme;
    return GestureDetector(
      onTap: () => context.push('/fight-camp/phase'),
      child: GlassPanel(
        glowColor: theme.primary,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Phase icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: theme.gradientColors),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: theme.glow.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(theme.phaseIcon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                // Phase info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.phaseName,
                        style: TextStyle(
                          color: theme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (fightCampService.nextFight != null)
                        Text(
                          'vs ${fightCampService.nextFight!.opponent}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        )
                      else
                        Text(
                          theme.phaseDescription,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Countdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    fightCampService.countdownString,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.primary,
                      shadows: [
                        Shadow(
                          color: theme.glow.withValues(alpha: 0.6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Motivational Prep Talk Panel
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.psychology, color: theme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      CornerVoice.quote(DateTime.now().day),
                      style: TextStyle(
                        color: theme.primary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Training Load Panel - Shows load vs recovery
class TrainingLoadPanel extends StatelessWidget {
  final double loadScore;
  final double recoveryScore;
  final double ratio;

  const TrainingLoadPanel({
    super.key,
    this.loadScore = 78,
    this.recoveryScore = 72,
    this.ratio = 1.08,
  });

  @override
  Widget build(BuildContext context) {
    final isBalanced = ratio >= 0.8 && ratio <= 1.3;
    final statusColor = isBalanced ? AppTheme.neonGreen : AppTheme.neonOrange;

    return GestureDetector(
      onTap: () => context.push('/training/load'),
      child: GlassPanel(
        glowColor: statusColor,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: statusColor, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Training Load',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isBalanced ? 'BALANCED' : 'WATCH',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn(
                    'LOAD',
                    loadScore,
                    AppTheme.neonOrange,
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.white12),
                Expanded(
                  child: _buildMetricColumn(
                    'RECOVERY',
                    recoveryScore,
                    AppTheme.neonGreen,
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.white12),
                Expanded(
                  child: _buildMetricColumn(
                    'RATIO',
                    ratio * 100,
                    statusColor,
                    suffix: '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildProgressBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(
    String label,
    double value,
    Color color, {
    String suffix = '%',
  }) {
    return Column(
      children: [
        Text(
          '${value.toInt()}$suffix',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Weekly Progress',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
            Text(
              '${(loadScore * 0.85).toInt()}/100',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: loadScore / 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.neonCyan, AppTheme.neonGreen],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Stats Row - Quick stat indicators
class StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/performance/coach'),
      child: GlassPanel(
        glowColor: color,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.neonPurple, AppTheme.neonMagenta],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonPurple.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Adaptation Chart - Performance trend visualization
class AdaptationChart extends StatelessWidget {
  final List<double> data;
  final String title;
  final Color lineColor;

  const AdaptationChart({
    super.key,
    this.data = const [65, 70, 68, 75, 78, 74, 82, 80, 85],
    this.title = 'Performance Trend',
    this.lineColor = AppTheme.neonCyan,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      glowColor: lineColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: lineColor, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: AppTheme.neonGreen,
                      size: 11,
                    ),
                    SizedBox(width: 3),
                    Text(
                      '+8%',
                      style: TextStyle(
                        color: AppTheme.neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 65,
            child: CustomPaint(
              size: const Size(double.infinity, 65),
              painter: ChartPainter(data: data, lineColor: lineColor),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7 days ago',
                style: TextStyle(color: Colors.white24, fontSize: 9),
              ),
              Text(
                'Today',
                style: TextStyle(color: Colors.white24, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Monthly Balance Panel
class MonthlyBalancePanel extends StatelessWidget {
  final int workDays;
  final int restDays;
  final int targetWorkDays;

  const MonthlyBalancePanel({
    super.key,
    this.workDays = 18,
    this.restDays = 6,
    this.targetWorkDays = 22,
  });

  @override
  Widget build(BuildContext context) {
    final progress = workDays / targetWorkDays;

    return GlassPanel(
      glowColor: AppTheme.neonMagenta,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                color: AppTheme.neonMagenta,
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'Monthly Balance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppTheme.neonMagenta,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDayIndicator('Work', workDays, AppTheme.neonGreen),
              const SizedBox(width: 8),
              _buildDayIndicator('Rest', restDays, AppTheme.neonPurple),
              const SizedBox(width: 8),
              _buildDayIndicator('Target', targetWorkDays, AppTheme.neonCyan),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(AppTheme.neonMagenta),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayIndicator(String label, int days, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$days',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TrainingRecoveryPanel - Merged Training Load + Monthly Balance
// ═══════════════════════════════════════════════════════════════════════════
class TrainingRecoveryPanel extends StatelessWidget {
  final double loadScore;
  final double recoveryScore;
  final double ratio;
  final int workDays;
  final int restDays;
  final int targetWorkDays;

  const TrainingRecoveryPanel({
    super.key,
    this.loadScore = 78,
    this.recoveryScore = 72,
    this.ratio = 1.08,
    this.workDays = 18,
    this.restDays = 6,
    this.targetWorkDays = 22,
  });

  @override
  Widget build(BuildContext context) {
    final isBalanced = ratio >= 0.8 && ratio <= 1.3;
    final statusColor = isBalanced ? AppTheme.neonGreen : AppTheme.neonOrange;
    final monthProgress = workDays / targetWorkDays;

    return GlassPanel(
      glowColor: statusColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.insights, color: statusColor, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Training & Recovery',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isBalanced ? 'BALANCED' : 'WATCH',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Load / Recovery / Ratio row
          Row(
            children: [
              _buildCompactMetric(
                'LOAD',
                '${loadScore.toInt()}%',
                AppTheme.neonOrange,
              ),
              const SizedBox(width: 6),
              _buildCompactMetric(
                'RECOVERY',
                '${recoveryScore.toInt()}%',
                AppTheme.neonGreen,
              ),
              const SizedBox(width: 6),
              _buildCompactMetric(
                'RATIO',
                '${(ratio * 100).toInt()}',
                statusColor,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Monthly balance inline
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: AppTheme.neonMagenta,
                size: 12,
              ),
              const SizedBox(width: 4),
              const Text(
                'Monthly: ',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Text(
                '${workDays}W',
                style: const TextStyle(
                  color: AppTheme.neonGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' / ${restDays}R',
                style: const TextStyle(
                  color: AppTheme.neonPurple,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' / ${targetWorkDays}T',
                style: const TextStyle(
                  color: AppTheme.neonCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(monthProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppTheme.neonMagenta,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: monthProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(AppTheme.neonMagenta),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 8,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// StatsRow - Quick stat indicators for dashboard
// ═══════════════════════════════════════════════════════════════════════════
class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStat('Readiness', '85%', Icons.favorite, DesignTokens.neonGreen),
        const SizedBox(width: 8),
        _buildStat('Load', '72%', Icons.fitness_center, DesignTokens.neonCyan),
        const SizedBox(width: 8),
        _buildStat('Recovery', '90%', Icons.healing, DesignTokens.neonMagenta),
      ],
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: accent.withValues(alpha: 0.08),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CoachMonitorPanel - AI Coach insights panel
// ═══════════════════════════════════════════════════════════════════════════
class CoachMonitorPanel extends StatelessWidget {
  final String coachName;
  final String insightText;
  final int readinessScore;
  final String recommendation;

  const CoachMonitorPanel({
    super.key,
    required this.coachName,
    required this.insightText,
    required this.readinessScore,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = readinessScore >= 80
        ? DesignTokens.neonGreen
        : readinessScore >= 60
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;

    return GlassPanel(
      glowColor: DesignTokens.neonCyan,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.smart_toy_outlined,
                color: DesignTokens.neonCyan,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                coachName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: scoreColor.withValues(alpha: 0.2),
                  border: Border.all(
                    color: scoreColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '$readinessScore%',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insightText,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: DesignTokens.neonAmber,
                size: 14,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  recommendation,
                  style: TextStyle(
                    color: DesignTokens.neonAmber.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ReadinessHeroPanel - Fight Readiness Score (0–100) HUD
// ═══════════════════════════════════════════════════════════════════════════
class ReadinessHeroPanel extends StatelessWidget {
  final int readinessScore;

  const ReadinessHeroPanel({super.key, required this.readinessScore});

  @override
  Widget build(BuildContext context) {
    final clamped = readinessScore.clamp(0, 100);
    Color ringColor;
    String label;
    if (clamped >= 85) {
      ringColor = DesignTokens.neonGreen;
      label = 'PEAK READY';
    } else if (clamped >= 70) {
      ringColor = DesignTokens.neonAmber;
      label = 'GOOD TO GO';
    } else if (clamped >= 55) {
      ringColor = const Color(0xFFFFB800);
      label = 'CAUTION';
    } else {
      ringColor = DesignTokens.neonRed;
      label = 'RED ZONE';
    }

    return GlassPanel(
      glowColor: ringColor,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fight Readiness Score',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Blends sleep, recovery, stress and hydration into one number the corner can trust.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: ringColor.withValues(alpha: 0.15),
                    border: Border.all(color: ringColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, color: ringColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: ringColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 72,
            height: 72,
            child: CustomPaint(
              painter: _ReadinessRingPainter(
                score: clamped.toDouble(),
                color: ringColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessRingPainter extends CustomPainter {
  final double score; // 0-100
  final Color color;

  _ReadinessRingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final fgPaint = Paint()
      ..shader = SweepGradient(
        colors: [color, color.withValues(alpha: 0.3), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = (score.clamp(0, 100) / 100) * 3.6; // degrees
    final startAngle = -90.0 * (math.pi / 180.0);
    final sweepRad = sweepAngle * (math.pi / 180.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepRad,
      false,
      fgPaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: score.toInt().toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset =
        center - Offset(textPainter.width / 2, textPainter.height / 2 + 2);
    textPainter.paint(canvas, offset);

    final subPainter = TextPainter(
      text: const TextSpan(
        text: '%',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final subOffset =
        center + Offset(textPainter.width / 2 - 2, textPainter.height / 2 - 10);
    subPainter.paint(canvas, subOffset);
  }

  @override
  bool shouldRepaint(covariant _ReadinessRingPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ChartPainter - Simple line chart custom painter
// ═══════════════════════════════════════════════════════════════════════════
class ChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  ChartPainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.3),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final isFlatLine = (maxVal - minVal).abs() < 0.000001;
    final range = isFlatLine ? 1.0 : (maxVal - minVal);

    final path = Path();
    final fillPath = Path();
    final stepX = data.length > 1 ? size.width / (data.length - 1) : 0.0;

    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1 ? size.width / 2 : i * stepX;
      final normalized = isFlatLine
          ? 0.5
          : ((data[i] - minVal) / range).clamp(0.0, 1.0);
      final y = size.height - normalized * size.height * 0.85;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1 ? size.width / 2 : i * stepX;
      final normalized = isFlatLine
          ? 0.5
          : ((data[i] - minVal) / range).clamp(0.0, 1.0);
      final y = size.height - normalized * size.height * 0.85;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.lineColor != lineColor;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Role-Based Dashboard Panel (Fighter, Gym, Promoter, Fan)
// ═══════════════════════════════════════════════════════════════════════════
class RoleDashboardPanel extends StatelessWidget {
  final String role;
  final String? userName;
  final String? gymName;
  final String? eventName;
  final String? logoUrl;
  final void Function()? onUploadLogo;
  final void Function()? onCreateEvent;
  final void Function()? onViewTools;
  final void Function()? onViewAds;
  final void Function()? onViewNews;
  final void Function()? onViewStreams;

  const RoleDashboardPanel({
    required this.role,
    this.userName,
    this.gymName,
    this.eventName,
    this.logoUrl,
    this.onUploadLogo,
    this.onCreateEvent,
    this.onViewTools,
    this.onViewAds,
    this.onViewNews,
    this.onViewStreams,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      glowColor: _roleColor(role),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_roleIcon(role), color: _roleColor(role), size: 24),
              const SizedBox(width: 10),
              Text(
                _roleTitle(role),
                style: TextStyle(
                  color: _roleColor(role),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              if (logoUrl != null)
                DfcCircleAvatar(
                  imageUrl: logoUrl,
                  radius: 18,
                  backgroundColor: _roleColor(role).withValues(alpha: 0.14),
                  fallbackIcon: _roleIcon(role),
                  fallbackIconColor: _roleColor(role),
                ),
              if (onUploadLogo != null)
                IconButton(
                  icon: Icon(Icons.upload_file, color: _roleColor(role)),
                  onPressed: onUploadLogo,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (userName != null)
            Text(
              'User: $userName',
              style: const TextStyle(color: Colors.white70),
            ),
          if (gymName != null)
            Text(
              'Gym: $gymName',
              style: const TextStyle(color: Colors.white70),
            ),
          if (eventName != null)
            Text(
              'Event: $eventName',
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (onCreateEvent != null && role == 'promoter')
                ElevatedButton.icon(
                  icon: const Icon(Icons.event),
                  label: const Text('Create Event'),
                  onPressed: onCreateEvent,
                ),
              if (onViewTools != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.build),
                  label: const Text('Tools'),
                  onPressed: onViewTools,
                ),
              if (onViewAds != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.campaign),
                  label: const Text('Ads'),
                  onPressed: onViewAds,
                ),
              if (onViewNews != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.article),
                  label: const Text('News'),
                  onPressed: onViewNews,
                ),
              if (onViewStreams != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.stream),
                  label: const Text('Streams'),
                  onPressed: onViewStreams,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'fighter':
        return DesignTokens.neonGreen;
      case 'gym':
        return DesignTokens.neonCyan;
      case 'promoter':
        return DesignTokens.neonMagenta;
      case 'fan':
        return DesignTokens.neonAmber;
      default:
        return Colors.white;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'fighter':
        return Icons.sports_mma;
      case 'gym':
        return Icons.fitness_center;
      case 'promoter':
        return Icons.event;
      case 'fan':
        return Icons.star;
      default:
        return Icons.person;
    }
  }

  String _roleTitle(String role) {
    switch (role) {
      case 'fighter':
        return 'Fighter Mode';
      case 'gym':
        return 'Gym Space';
      case 'promoter':
        return 'Event Manager';
      case 'fan':
        return 'Fan Zone';
      default:
        return 'User';
    }
  }
}
