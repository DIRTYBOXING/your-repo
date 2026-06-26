import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';

// ═════════════════════════════════════════════════════════════════════════════
// COMBAT ANALYTICS CHARTS — First-of-Kind Visualization System
// ═════════════════════════════════════════════════════════════════════════════
//
// 1. CombatPulseTimeline — ECG-style daily training heartbeat
// 2. OrbitalTrainingPie — Atomic orbital ring system (weekly)
// 3. DNAHelixChart — Double-helix load/recovery spiral (monthly)
//
// All 100% custom-painted. No third-party libraries.
// ═════════════════════════════════════════════════════════════════════════════

/// Training session data for daily tracking
class CombatSession {
  final String label; // e.g. "Morning Sparring"
  final String type; // striking, grappling, conditioning, recovery
  final double intensity; // 0.0 - 1.0
  final double duration; // hours
  final double timeOfDay; // 0.0 (midnight) - 1.0 (midnight)
  final String? note;

  const CombatSession({
    required this.label,
    required this.type,
    required this.intensity,
    required this.duration,
    required this.timeOfDay,
    this.note,
  });
}

/// Daily summary for monthly view
class DailySummary {
  final double load; // 0.0 - 1.0
  final double recovery; // 0.0 - 1.0
  final bool isBreakthrough; // exceeded personal best
  final bool isInjuryRisk; // overtraining detected
  final String dayLabel;

  const DailySummary({
    required this.load,
    required this.recovery,
    this.isBreakthrough = false,
    this.isInjuryRisk = false,
    this.dayLabel = '',
  });
}

/// Weekly category data for orbital view
class WeeklyCategory {
  final String label;
  final Color color;
  final double totalHours;
  final double percentage; // 0.0 - 1.0
  final List<double> dailyIntensities; // 7 values, 0.0-1.0

  const WeeklyCategory({
    required this.label,
    required this.color,
    required this.totalHours,
    required this.percentage,
    required this.dailyIntensities,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. COMBAT PULSE TIMELINE — Daily ECG-style heartbeat graph
//    Each training session creates a "heartbeat spike" on a continuous ECG
//    line. Zone coloring (green→amber→red) shows intensity zones.
//    Glowing beat markers pulse at session positions.
// ═════════════════════════════════════════════════════════════════════════════

class CombatPulseTimeline extends StatefulWidget {
  final List<CombatSession> sessions;
  final double overallReadiness; // 0.0 - 1.0

  const CombatPulseTimeline({
    super.key,
    required this.sessions,
    this.overallReadiness = 0.75,
  });

  @override
  State<CombatPulseTimeline> createState() => _CombatPulseTimelineState();
}

class _CombatPulseTimelineState extends State<CombatPulseTimeline>
    with TickerProviderStateMixin {
  late AnimationController _drawCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _drawAnim;

  @override
  void initState() {
    super.initState();
    _drawCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _drawAnim = CurvedAnimation(parent: _drawCtrl, curve: Curves.easeOutCubic);
    _drawCtrl.forward();
  }

  @override
  void dispose() {
    _drawCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with pulse indicator
        _buildHeader(),
        const SizedBox(height: 12),
        // Time axis labels
        _buildTimeAxis(),
        const SizedBox(height: 4),
        // Main ECG canvas
        SizedBox(
          height: 180,
          child: AnimatedBuilder(
            animation: Listenable.merge([_drawAnim, _pulseCtrl]),
            builder: (context, _) {
              return RepaintBoundary(
                child: CustomPaint(
                  painter: _CombatPulsePainter(
                    sessions: widget.sessions,
                    drawProgress: _drawAnim.value,
                    pulsePhase: _pulseCtrl.value,
                    readiness: widget.overallReadiness,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Zone legend
        _buildZoneLegend(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Animated heartbeat icon
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, _) {
            final scale = 1.0 + _pulseCtrl.value * 0.15;
            return Transform.scale(
              scale: scale,
              child: Icon(
                Icons.monitor_heart,
                color: _readinessColor(widget.overallReadiness),
                size: 20,
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        const Text(
          'COMBAT PULSE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _readinessColor(
              widget.overallReadiness,
            ).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _readinessColor(
                widget.overallReadiness,
              ).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '${(widget.overallReadiness * 100).round()}% READY',
            style: TextStyle(
              color: _readinessColor(widget.overallReadiness),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeAxis() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ['5AM', '8AM', '11AM', '2PM', '5PM', '8PM', '11PM']
          .map(
            (t) => Text(
              t,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildZoneLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(AppTheme.neonGreen, 'Recovery'),
        const SizedBox(width: 16),
        _legendDot(AppTheme.neonCyan, 'Moderate'),
        const SizedBox(width: 16),
        _legendDot(Colors.amber, 'High'),
        const SizedBox(width: 16),
        _legendDot(const Color(0xFFFF3366), 'Redline'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _readinessColor(double r) {
    if (r >= 0.75) return AppTheme.neonGreen;
    if (r >= 0.5) return AppTheme.neonCyan;
    if (r >= 0.25) return Colors.amber;
    return const Color(0xFFFF3366);
  }
}

class _CombatPulsePainter extends CustomPainter {
  final List<CombatSession> sessions;
  final double drawProgress;
  final double pulsePhase;
  final double readiness;

  _CombatPulsePainter({
    required this.sessions,
    required this.drawProgress,
    required this.pulsePhase,
    required this.readiness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawZoneBands(canvas, size);
    _drawGridLines(canvas, size);
    _drawECGLine(canvas, size);
    _drawSessionMarkers(canvas, size);
    _drawScanLine(canvas, size);
  }

  void _drawZoneBands(Canvas canvas, Size size) {
    // Intensity zone bands (horizontal)
    final zones = [
      (0.0, 0.25, const Color(0xFFFF3366), 0.04), // Redline (top = high)
      (0.25, 0.50, Colors.amber, 0.03),
      (0.50, 0.75, AppTheme.neonCyan, 0.02),
      (0.75, 1.0, AppTheme.neonGreen, 0.02), // Recovery (bottom = low)
    ];
    for (final (top, bottom, color, opacity) in zones) {
      canvas.drawRect(
        Rect.fromLTRB(
          0,
          size.height * top,
          size.width * drawProgress,
          size.height * bottom,
        ),
        Paint()..color = color.withValues(alpha: opacity),
      );
    }
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    // Horizontal zone dividers
    for (double y = 0.25; y < 1.0; y += 0.25) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width * drawProgress, size.height * y),
        gridPaint,
      );
    }

    // Vertical time markers every ~3 hours
    for (int i = 1; i < 7; i++) {
      final x = (i / 7) * size.width;
      if (x <= size.width * drawProgress) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.03)
            ..strokeWidth = 0.5,
        );
      }
    }
  }

  void _drawECGLine(Canvas canvas, Size size) {
    if (sessions.isEmpty) return;

    // Sort sessions by time
    final sorted = List<CombatSession>.from(sessions)
      ..sort((a, b) => a.timeOfDay.compareTo(b.timeOfDay));

    final path = Path();
    final points = <Offset>[];

    // Start flatline at rest
    final startX = 0.0;
    final restY = size.height * 0.78; // Rest = near bottom
    path.moveTo(startX, restY);
    points.add(Offset(startX, restY));

    for (final session in sorted) {
      final centerX = session.timeOfDay * size.width;
      final peakY =
          size.height * (1.0 - session.intensity) * 0.85 + size.height * 0.05;

      // Lead-in (approach the beat)
      final approachX = centerX - session.duration * size.width * 0.3;
      if (approachX > points.last.dx) {
        points.add(Offset(approachX, restY));
      }

      // ECG spike: small dip down, sharp spike up, dip down, return
      final spikeW = session.duration * size.width * 0.15;

      // P-wave (small bump before QRS)
      points.add(Offset(centerX - spikeW * 2, restY));
      points.add(
        Offset(centerX - spikeW * 1.5, restY - (restY - peakY) * 0.15),
      );
      points.add(Offset(centerX - spikeW * 1, restY));

      // Q-dip
      points.add(
        Offset(centerX - spikeW * 0.5, restY + (size.height - restY) * 0.3),
      );

      // R-peak (main spike)
      points.add(Offset(centerX, peakY));

      // S-dip
      points.add(
        Offset(centerX + spikeW * 0.5, restY + (size.height - restY) * 0.2),
      );

      // T-wave (recovery bump)
      points.add(Offset(centerX + spikeW * 1.2, restY));
      points.add(Offset(centerX + spikeW * 1.8, restY - (restY - peakY) * 0.1));
      points.add(Offset(centerX + spikeW * 2.5, restY));

      // Flatline after
      final exitX = centerX + session.duration * size.width * 0.4;
      points.add(Offset(exitX, restY));
    }

    // End flatline
    points.add(Offset(size.width, restY));

    // Build smooth path
    if (points.length >= 2) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        // Only smooth between certain points
        if ((curr.dy - prev.dy).abs() < size.height * 0.05) {
          path.lineTo(curr.dx, curr.dy);
        } else {
          final cpx = (prev.dx + curr.dx) / 2;
          path.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
        }
      }
    }

    // Clip to draw progress
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, 0, size.width * drawProgress, size.height),
    );

    // Glow line
    final glowColor = _intensityToColor(readiness);
    canvas.drawPath(
      path,
      Paint()
        ..color = glowColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Main line with gradient
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppTheme.neonGreen.withValues(alpha: 0.9),
            AppTheme.neonCyan,
            Colors.amber,
            const Color(0xFFFF3366),
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  void _drawSessionMarkers(Canvas canvas, Size size) {
    for (final session in sessions) {
      final x = session.timeOfDay * size.width;
      if (x > size.width * drawProgress) continue;

      final peakY =
          size.height * (1.0 - session.intensity) * 0.85 + size.height * 0.05;

      // Pulsing glow at each session peak
      final pulseRadius = 4.0 + pulsePhase * 4.0;
      final color = _typeColor(session.type);
      final alpha = (0.3 + pulsePhase * 0.3).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(x, peakY),
        pulseRadius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(Offset(x, peakY), 3, Paint()..color = color);

      // Vertical dashed guide
      _drawDashedLine(
        canvas,
        Offset(x, peakY + 6),
        Offset(x, size.height),
        Paint()
          ..color = color.withValues(alpha: 0.1)
          ..strokeWidth = 0.5,
      );
    }
  }

  void _drawScanLine(Canvas canvas, Size size) {
    // Animated scan line at draw edge
    final scanX = size.width * drawProgress;
    if (drawProgress >= 0.99) return;

    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppTheme.neonCyan.withValues(alpha: 0.4),
          AppTheme.neonCyan.withValues(alpha: 0.8),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(scanX - 20, 0, 40, size.height));

    canvas.drawRect(Rect.fromLTWH(scanX - 1, 0, 2, size.height), scanPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final distance = (end - start).distance;
    final dash = 3.0;
    final gap = 3.0;
    final direction = (end - start) / distance;
    var current = 0.0;

    while (current < distance) {
      final segEnd = math.min(current + dash, distance);
      canvas.drawLine(
        start + direction * current,
        start + direction * segEnd,
        paint,
      );
      current = segEnd + gap;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'striking':
        return const Color(0xFFFF3366);
      case 'grappling':
        return AppColors.neonBlue;
      case 'conditioning':
        return Colors.orange;
      case 'recovery':
        return AppTheme.neonGreen;
      default:
        return AppTheme.neonCyan;
    }
  }

  Color _intensityToColor(double i) {
    if (i >= 0.75) return AppTheme.neonGreen;
    if (i >= 0.5) return AppTheme.neonCyan;
    if (i >= 0.25) return Colors.amber;
    return const Color(0xFFFF3366);
  }

  @override
  bool shouldRepaint(covariant _CombatPulsePainter old) =>
      old.drawProgress != drawProgress || old.pulsePhase != pulsePhase;
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. ORBITAL TRAINING PIE — Atomic orbital ring system (weekly)
//    Instead of flat pizza slices, each training category is a glowing
//    orbital ring at a different angle. Satellites (dots) on each ring
//    represent daily sessions — their size = session intensity.
//    The nucleus shows total weekly hours.
// ═════════════════════════════════════════════════════════════════════════════

class OrbitalTrainingPie extends StatefulWidget {
  final List<WeeklyCategory> categories;
  final double totalHours;

  const OrbitalTrainingPie({
    super.key,
    required this.categories,
    this.totalHours = 0,
  });

  @override
  State<OrbitalTrainingPie> createState() => _OrbitalTrainingPieState();
}

class _OrbitalTrainingPieState extends State<OrbitalTrainingPie>
    with TickerProviderStateMixin {
  late AnimationController _orbitCtrl;
  late AnimationController _revealCtrl;
  late Animation<double> _revealAnim;

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _revealCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _revealAnim = CurvedAnimation(
      parent: _revealCtrl,
      curve: Curves.easeOutCubic,
    );
    _revealCtrl.forward();
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chart
        SizedBox(
          height: 240,
          child: AnimatedBuilder(
            animation: Listenable.merge([_orbitCtrl, _revealAnim]),
            builder: (context, _) {
              return RepaintBoundary(
                child: CustomPaint(
                  painter: _OrbitalPiePainter(
                    categories: widget.categories,
                    totalHours: widget.totalHours,
                    orbitPhase: _orbitCtrl.value,
                    revealProgress: _revealAnim.value,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: widget.categories.map((cat) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 3,
              decoration: BoxDecoration(
                color: cat.color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: cat.color.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${cat.label} · ${cat.totalHours.toStringAsFixed(1)}h',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _OrbitalPiePainter extends CustomPainter {
  final List<WeeklyCategory> categories;
  final double totalHours;
  final double orbitPhase;
  final double revealProgress;

  _OrbitalPiePainter({
    required this.categories,
    required this.totalHours,
    required this.orbitPhase,
    required this.revealProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 16;

    _drawNucleus(canvas, center, maxRadius);
    _drawOrbitalRings(canvas, center, maxRadius);
    _drawSatellites(canvas, center, maxRadius);
    _drawPercentageArcs(canvas, center, maxRadius);
  }

  void _drawNucleus(Canvas canvas, Offset center, double maxRadius) {
    // Core glow
    final nucleusRadius = maxRadius * 0.22 * revealProgress;

    // Outer glow ring
    canvas.drawCircle(
      center,
      nucleusRadius + 8,
      Paint()
        ..color = AppTheme.neonCyan.withValues(alpha: 0.08 * revealProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );

    // Background circle
    canvas.drawCircle(
      center,
      nucleusRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.02),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: nucleusRadius)),
    );

    // Border ring
    canvas.drawCircle(
      center,
      nucleusRadius,
      Paint()
        ..color = AppTheme.neonCyan.withValues(alpha: 0.3 * revealProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Total hours text
    final hoursPainter = TextPainter(
      text: TextSpan(
        text: totalHours.toStringAsFixed(1),
        style: TextStyle(
          color: Colors.white.withValues(alpha: revealProgress),
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    hoursPainter.layout();
    hoursPainter.paint(
      canvas,
      center - Offset(hoursPainter.width / 2, hoursPainter.height / 2 + 4),
    );

    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'HOURS',
        style: TextStyle(
          color: AppTheme.neonCyan.withValues(alpha: 0.5 * revealProgress),
          fontSize: 7,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      center - Offset(labelPainter.width / 2, labelPainter.height / 2 - 12),
    );
  }

  void _drawOrbitalRings(Canvas canvas, Offset center, double maxRadius) {
    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final ringRadius =
          maxRadius * (0.4 + (i / categories.length) * 0.55) * revealProgress;
      // tiltAngle reserved for future 3D rotation
      // final tiltAngle = (i * math.pi / categories.length) + math.pi / 6;

      // Save and rotate for orbital tilt
      canvas.save();
      canvas.translate(center.dx, center.dy);

      // Slight tilt to simulate 3D
      final scaleY = 0.35 + (i * 0.12);

      // Ring glow
      // glowRect used implicitly by drawOval below
      // final glowRect = Rect.fromCircle(center: Offset.zero, radius: ringRadius);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: ringRadius * 2,
          height: ringRadius * 2 * scaleY,
        ),
        Paint()
          ..color = cat.color.withValues(alpha: 0.12 * revealProgress)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Ring line
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: ringRadius * 2,
          height: ringRadius * 2 * scaleY,
        ),
        Paint()
          ..color = cat.color.withValues(alpha: 0.4 * revealProgress)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );

      canvas.restore();
    }
  }

  void _drawSatellites(Canvas canvas, Offset center, double maxRadius) {
    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final ringRadius =
          maxRadius * (0.4 + (i / categories.length) * 0.55) * revealProgress;
      final scaleY = 0.35 + (i * 0.12);

      // Place 7 satellites (one per day) around the orbit
      for (int d = 0; d < cat.dailyIntensities.length && d < 7; d++) {
        final intensity = cat.dailyIntensities[d];
        if (intensity <= 0) continue;

        final angle =
            (d / 7) * math.pi * 2 + orbitPhase * math.pi * 2 * (0.5 + i * 0.3);

        final sx = center.dx + math.cos(angle) * ringRadius;
        final sy = center.dy + math.sin(angle) * ringRadius * scaleY;

        final dotSize = 2.0 + intensity * 5.0;

        // Glow
        canvas.drawCircle(
          Offset(sx, sy),
          dotSize + 3,
          Paint()
            ..color = cat.color.withValues(alpha: 0.3 * revealProgress)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );

        // Dot
        canvas.drawCircle(
          Offset(sx, sy),
          dotSize * revealProgress,
          Paint()..color = cat.color.withValues(alpha: 0.9 * revealProgress),
        );
      }
    }
  }

  void _drawPercentageArcs(Canvas canvas, Offset center, double maxRadius) {
    // Draw percentage arcs at the outer edge
    final arcRadius = maxRadius * 0.95 * revealProgress;
    var startAngle = -math.pi / 2;

    for (final cat in categories) {
      final sweep = cat.percentage * math.pi * 2 * revealProgress;
      if (sweep <= 0) continue;

      // Glow arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        startAngle,
        sweep - 0.03,
        false,
        Paint()
          ..color = cat.color.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Main arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        startAngle,
        sweep - 0.03,
        false,
        Paint()
          ..color = cat.color.withValues(alpha: 0.8 * revealProgress)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitalPiePainter old) =>
      old.orbitPhase != orbitPhase || old.revealProgress != revealProgress;
}

// ═════════════════════════════════════════════════════════════════════════════
// 3. DNA HELIX CHART — Double-helix monthly Load vs Recovery
//    Two intertwining helical strands (like DNA) spiraling across 30 days.
//    The left strand = Training Load, right strand = Recovery Score.
//    Cross-links (rungs) connect them — green when balanced, red when off.
//    Mutation markers (⚡ breakthrough, ⚠ injury risk) appear at key points.
// ═════════════════════════════════════════════════════════════════════════════

class DNAHelixChart extends StatefulWidget {
  final List<DailySummary> days; // 28-31 entries
  final double currentLoad;
  final double currentRecovery;

  const DNAHelixChart({
    super.key,
    required this.days,
    this.currentLoad = 0.65,
    this.currentRecovery = 0.72,
  });

  @override
  State<DNAHelixChart> createState() => _DNAHelixChartState();
}

class _DNAHelixChartState extends State<DNAHelixChart>
    with TickerProviderStateMixin {
  late AnimationController _helixCtrl;
  late AnimationController _drawCtrl;
  late Animation<double> _drawAnim;

  @override
  void initState() {
    super.initState();
    _helixCtrl = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    _drawCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _drawAnim = CurvedAnimation(parent: _drawCtrl, curve: Curves.easeOutCubic);
    _drawCtrl.forward();
  }

  @override
  void dispose() {
    _helixCtrl.dispose();
    _drawCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: AnimatedBuilder(
            animation: Listenable.merge([_helixCtrl, _drawAnim]),
            builder: (context, _) {
              return RepaintBoundary(
                child: CustomPaint(
                  painter: _DNAHelixPainter(
                    days: widget.days,
                    helixPhase: _helixCtrl.value,
                    drawProgress: _drawAnim.value,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildStrandLegend(),
        const SizedBox(height: 8),
        _buildSummaryRow(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.biotech, color: AppColors.neonPurple, size: 18),
        const SizedBox(width: 8),
        const Text(
          'TRAINING DNA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        Text(
          '${widget.days.length} DAYS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildStrandLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _strandLegend(AppColors.neonRed, 'Training Load'),
        const SizedBox(width: 24),
        _strandLegend(AppTheme.neonCyan, 'Recovery Score'),
        const SizedBox(width: 24),
        _strandLegend(AppTheme.neonGreen, 'Balanced'),
      ],
    );
  }

  Widget _strandLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 3),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    final avgLoad = widget.days.isEmpty
        ? 0.0
        : widget.days.map((d) => d.load).reduce((a, b) => a + b) /
              widget.days.length;
    final avgRecovery = widget.days.isEmpty
        ? 0.0
        : widget.days.map((d) => d.recovery).reduce((a, b) => a + b) /
              widget.days.length;
    final breakthroughs = widget.days.where((d) => d.isBreakthrough).length;
    final risks = widget.days.where((d) => d.isInjuryRisk).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _summaryChip(
            'Avg Load',
            '${(avgLoad * 100).round()}%',
            AppColors.neonRed,
          ),
          _summaryChip(
            'Avg Recovery',
            '${(avgRecovery * 100).round()}%',
            AppTheme.neonCyan,
          ),
          _summaryChip('Breakthroughs', '$breakthroughs', AppTheme.neonGreen),
          _summaryChip(
            'Risks',
            '$risks',
            risks > 0 ? const Color(0xFFFF3366) : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DNAHelixPainter extends CustomPainter {
  final List<DailySummary> days;
  final double helixPhase;
  final double drawProgress;

  _DNAHelixPainter({
    required this.days,
    required this.helixPhase,
    required this.drawProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;

    final dayCount = days.length;
    final centerY = size.height / 2;
    final amplitude = size.height * 0.30;
    final frequency = math.pi * 2.5; // ~2.5 full rotations across chart

    // Clipping to drawProgress
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, 0, size.width * drawProgress, size.height),
    );

    // Draw background gradient bands
    _drawBackgroundBands(canvas, size, centerY);

    // Generate helix points
    final loadPoints = <Offset>[];
    final recoveryPoints = <Offset>[];

    for (int i = 0; i < dayCount; i++) {
      final t = i / (dayCount - 1);
      final x = t * size.width;
      final phase = t * frequency + helixPhase * math.pi * 2;

      // Helix displacement based on data values
      final loadAmp = amplitude * days[i].load;
      final recoveryAmp = amplitude * days[i].recovery;

      final loadY = centerY + math.sin(phase) * loadAmp;
      final recoveryY = centerY - math.sin(phase) * recoveryAmp;

      loadPoints.add(Offset(x, loadY));
      recoveryPoints.add(Offset(x, recoveryY));
    }

    // Draw cross-links (rungs) connecting the two strands
    _drawRungs(canvas, loadPoints, recoveryPoints, centerY);

    // Draw load strand (red/orange)
    _drawStrand(canvas, loadPoints, AppColors.neonRed, size);

    // Draw recovery strand (cyan)
    _drawStrand(canvas, recoveryPoints, AppTheme.neonCyan, size);

    // Draw mutation markers
    _drawMutationMarkers(canvas, loadPoints, recoveryPoints);

    // Day labels at bottom
    _drawDayLabels(canvas, size, dayCount);

    canvas.restore();
  }

  void _drawBackgroundBands(Canvas canvas, Size size, double centerY) {
    // Subtle gradient showing healthy zone
    canvas.drawRect(
      Rect.fromLTRB(0, centerY - 10, size.width, centerY + 10),
      Paint()
        ..shader =
            LinearGradient(
              colors: [
                AppTheme.neonGreen.withValues(alpha: 0.03),
                AppTheme.neonGreen.withValues(alpha: 0.06),
                AppTheme.neonGreen.withValues(alpha: 0.03),
              ],
            ).createShader(
              Rect.fromLTRB(0, centerY - 10, size.width, centerY + 10),
            ),
    );

    // Center line
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.04)
        ..strokeWidth = 0.5,
    );
  }

  void _drawRungs(
    Canvas canvas,
    List<Offset> loadPts,
    List<Offset> recoveryPts,
    double centerY,
  ) {
    for (int i = 0; i < loadPts.length; i++) {
      final loadY = loadPts[i].dy;
      final recY = recoveryPts[i].dy;
      final x = loadPts[i].dx;

      // Color based on balance
      final diff = (days[i].load - days[i].recovery).abs();
      Color rungColor;
      if (diff < 0.15) {
        rungColor = AppTheme.neonGreen;
      } else if (diff < 0.3) {
        rungColor = Colors.amber;
      } else {
        rungColor = const Color(0xFFFF3366);
      }

      canvas.drawLine(
        Offset(x, loadY),
        Offset(x, recY),
        Paint()
          ..color = rungColor.withValues(alpha: 0.08)
          ..strokeWidth = 1.5,
      );

      // Small dots at connection points
      canvas.drawCircle(
        Offset(x, (loadY + recY) / 2),
        1.5,
        Paint()..color = rungColor.withValues(alpha: 0.15),
      );
    }
  }

  void _drawStrand(Canvas canvas, List<Offset> points, Color color, Size size) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpx = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
    }

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Main line
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Dots at each data point
    for (final p in points) {
      canvas.drawCircle(p, 2.5, Paint()..color = color);
    }
  }

  void _drawMutationMarkers(
    Canvas canvas,
    List<Offset> loadPts,
    List<Offset> recoveryPts,
  ) {
    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final x = loadPts[i].dx;

      if (day.isBreakthrough) {
        // Gold star burst
        final y = math.min(loadPts[i].dy, recoveryPts[i].dy) - 12;
        _drawStarburst(canvas, Offset(x, y), AppTheme.neonGreen, 6);
      }

      if (day.isInjuryRisk) {
        // Red warning triangle
        final y = math.max(loadPts[i].dy, recoveryPts[i].dy) + 12;
        _drawWarningTriangle(canvas, Offset(x, y), const Color(0xFFFF3366), 5);
      }
    }
  }

  void _drawStarburst(Canvas canvas, Offset center, Color color, double r) {
    // 6-point star
    final path = Path();
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2 - math.pi / 2;
      final radius = i.isEven ? r : r * 0.5;
      final p =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawWarningTriangle(
    Canvas canvas,
    Offset center,
    Color color,
    double r,
  ) {
    final path = Path();
    for (int i = 0; i < 3; i++) {
      final angle = (i / 3) * math.pi * 2 - math.pi / 2;
      final p = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawDayLabels(Canvas canvas, Size size, int dayCount) {
    // Show every 5th day label
    for (int i = 0; i < dayCount; i++) {
      if (i % 5 != 0 && i != dayCount - 1) continue;
      final x = (i / (dayCount - 1)) * size.width;
      final label = days[i].dayLabel.isNotEmpty ? days[i].dayLabel : '${i + 1}';

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.2),
            fontSize: 8,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - tp.height));
    }
  }

  @override
  bool shouldRepaint(covariant _DNAHelixPainter old) =>
      old.helixPhase != helixPhase || old.drawProgress != drawProgress;
}
