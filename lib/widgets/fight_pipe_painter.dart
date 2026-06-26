import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT PIPE PAINTERS — Industrial Flowing-Data Visualizations
/// ═══════════════════════════════════════════════════════════════════════════
///
/// PipeFlowPainter     — Animated flowing pipe with dash-array pulses
/// PipeJunctionPainter — Junction node with glow + status indicator
/// PressureGaugePainter— NASA PSI gauge with danger zones
/// TankPainter         — Processing tank with bubbling liquid level
///
/// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// 1. PIPE FLOW — Vercel-style animated flowing line
// ─────────────────────────────────────────────────────────────────────────────
class PipeFlowPainter extends CustomPainter {
  /// 0.0 → 1.0 animation value driving the dash offset scroll
  final double flowPhase;

  /// 0.0 → 1.0 intensity (maps to glow + pipe color heat)
  final double intensity;

  /// Flow color (defaults applied if null)
  final Color pipeColor;

  /// Direction: true = left→right, false = right→left
  final bool flowForward;

  /// Whether the pipe is currently active (flowing)
  final bool isActive;

  /// Pipe thickness
  final double strokeWidth;

  /// Route waypoints (normalized 0→1 coordinates). If null, draws straight.
  final List<Offset>? waypoints;

  PipeFlowPainter({
    required this.flowPhase,
    this.intensity = 0.6,
    this.pipeColor = const Color(0xFF00F5FF),
    this.flowForward = true,
    this.isActive = true,
    this.strokeWidth = 6.0,
    this.waypoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Build the pipe path ──
    final path = Path();
    if (waypoints != null && waypoints!.length >= 2) {
      final pts = waypoints!
          .map((p) => Offset(p.dx * size.width, p.dy * size.height))
          .toList();
      path.moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        // Smoothed curve between waypoints
        if (i < pts.length - 1) {
          final mid = Offset(
            (pts[i].dx + pts[i + 1].dx) / 2,
            (pts[i].dy + pts[i + 1].dy) / 2,
          );
          path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
        } else {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
      }
    } else {
      // Default: straight horizontal pipe
      path.moveTo(0, size.height / 2);
      path.lineTo(size.width, size.height / 2);
    }

    // ── Pipe casing (dark industrial grey) ──
    final casingPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..strokeWidth = strokeWidth + 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, casingPaint);

    // ── Pipe inner wall ──
    final wallPaint = Paint()
      ..color = isActive
          ? pipeColor.withValues(alpha: 0.15)
          : const Color(0xFF0A0A1A)
      ..strokeWidth = strokeWidth + 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, wallPaint);

    if (!isActive) return;

    // ── Flowing data pulses (dash-array animation) ──
    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;
    const dashLength = 14.0;
    const gapLength = 22.0;
    final segmentLength = dashLength + gapLength;
    final phase = flowForward ? flowPhase : 1.0 - flowPhase;
    final offset = phase * segmentLength * 3; // scroll speed multiplier

    final flowPaint = Paint()
      ..color = Color.lerp(
        pipeColor,
        pipeColor.withValues(alpha: 0.3),
        0.3 - intensity * 0.3,
      )!
      ..strokeWidth = strokeWidth - 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw dashes along the path
    double dist = -offset % segmentLength;
    while (dist < totalLength) {
      final start = dist.clamp(0.0, totalLength);
      final end = (dist + dashLength).clamp(0.0, totalLength);
      if (end > start + 0.5) {
        final segment = metrics.extractPath(start, end);
        canvas.drawPath(segment, flowPaint);
      }
      dist += segmentLength;
    }

    // ── Outer glow ──
    final glowPaint = Paint()
      ..color = pipeColor.withValues(alpha: intensity * 0.25)
      ..strokeWidth = strokeWidth + 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + intensity * 4);
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant PipeFlowPainter old) =>
      old.flowPhase != flowPhase ||
      old.intensity != intensity ||
      old.isActive != isActive;
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. PIPE JUNCTION — Glowing node where pipes meet
// ─────────────────────────────────────────────────────────────────────────────
class PipeJunctionPainter extends CustomPainter {
  final Color color;
  final double pulseValue; // 0→1 for pulsing glow
  final bool isActive;
  final bool isError;

  PipeJunctionPainter({
    required this.color,
    required this.pulseValue,
    this.isActive = true,
    this.isError = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final effectiveColor = isError ? const Color(0xFFFF3366) : color;

    // Outer glow ring
    if (isActive) {
      final glowPaint = Paint()
        ..color = effectiveColor.withValues(alpha: 0.15 + pulseValue * 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + pulseValue * 6);
      canvas.drawCircle(center, radius + 4, glowPaint);
    }

    // Metal ring
    final ringPaint = Paint()
      ..color = const Color(0xFF2A2A3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, ringPaint);

    // Inner fill
    final fillPaint = Paint()
      ..color = isActive
          ? effectiveColor.withValues(alpha: 0.3 + pulseValue * 0.15)
          : const Color(0xFF0A0A14);
    canvas.drawCircle(center, radius - 2, fillPaint);

    // Core dot
    if (isActive) {
      final corePaint = Paint()
        ..color = effectiveColor.withValues(alpha: 0.7 + pulseValue * 0.3);
      canvas.drawCircle(center, radius * 0.35, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PipeJunctionPainter old) =>
      old.pulseValue != pulseValue ||
      old.isActive != isActive ||
      old.isError != isError;
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. PRESSURE GAUGE — NASA-style PSI gauge with danger zones
// ─────────────────────────────────────────────────────────────────────────────
class PressureGaugePainter extends CustomPainter {
  /// 0.0 → 1.0 fill value
  final double value;

  /// Current psi label
  final String label;

  /// Danger threshold (0→1). Above this = red zone
  final double dangerThreshold;

  /// Warning threshold. Above this = orange zone
  final double warningThreshold;

  final Color normalColor;

  PressureGaugePainter({
    required this.value,
    this.label = '',
    this.dangerThreshold = 0.8,
    this.warningThreshold = 0.6,
    this.normalColor = const Color(0xFF00F5FF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    const startAngle = 2.356; // 135°
    const sweepTotal = 4.712; // 270°

    // ── Bezel ring ──
    final bezelPaint = Paint()
      ..color = const Color(0xFF1A1A3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius + 2, bezelPaint);

    // ── Danger zone background (red arc for the danger portion) ──
    final dangerBgPaint = Paint()
      ..color = const Color(0xFFFF3366).withValues(alpha: 0.08)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      startAngle + sweepTotal * dangerThreshold,
      sweepTotal * (1.0 - dangerThreshold),
      false,
      dangerBgPaint,
    );

    // ── Warning zone background ──
    final warningBgPaint = Paint()
      ..color = const Color(0xFFFFB800).withValues(alpha: 0.06)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      startAngle + sweepTotal * warningThreshold,
      sweepTotal * (dangerThreshold - warningThreshold),
      false,
      warningBgPaint,
    );

    // ── Track arc ──
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // ── Tick marks ──
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    for (var i = 0; i <= 10; i++) {
      final angle = startAngle + sweepTotal * (i / 10);
      final inner = radius - (i % 5 == 0 ? 18 : 14);
      final outer = radius - 8;
      canvas.drawLine(
        Offset(
          center.dx + inner * math.cos(angle),
          center.dy + inner * math.sin(angle),
        ),
        Offset(
          center.dx + outer * math.cos(angle),
          center.dy + outer * math.sin(angle),
        ),
        tickPaint,
      );
    }

    // ── Value arc ──
    final clampedValue = value.clamp(0.0, 1.0);
    Color valueColor;
    if (clampedValue >= dangerThreshold) {
      valueColor = const Color(0xFFFF3366);
    } else if (clampedValue >= warningThreshold) {
      valueColor = const Color(0xFFFFB800);
    } else {
      valueColor = normalColor;
    }

    final valuePaint = Paint()
      ..color = valueColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      startAngle,
      sweepTotal * clampedValue,
      false,
      valuePaint,
    );

    // ── Value glow ──
    final glowPaint = Paint()
      ..color = valueColor.withValues(alpha: 0.3)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      startAngle,
      sweepTotal * clampedValue,
      false,
      glowPaint,
    );

    // ── Needle ──
    final needleAngle = startAngle + sweepTotal * clampedValue;
    final needlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + (radius - 16) * math.cos(needleAngle),
        center.dy + (radius - 16) * math.sin(needleAngle),
      ),
      needlePaint,
    );

    // Needle hub
    final hubPaint = Paint()..color = const Color(0xFF2A2A3E);
    canvas.drawCircle(center, 5, hubPaint);
    final hubCorePaint = Paint()..color = valueColor;
    canvas.drawCircle(center, 2.5, hubCorePaint);
  }

  @override
  bool shouldRepaint(covariant PressureGaugePainter old) =>
      old.value != value || old.dangerThreshold != dangerThreshold;
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. PROCESSING TANK — Bubbling liquid level indicator
// ─────────────────────────────────────────────────────────────────────────────
class TankPainter extends CustomPainter {
  /// 0.0 → 1.0 fill level
  final double level;

  /// Animation phase for bubbles
  final double bubblePhase;

  /// Liquid color
  final Color liquidColor;

  /// Show bubbling animation
  final bool isProcessing;

  TankPainter({
    required this.level,
    required this.bubblePhase,
    this.liquidColor = const Color(0xFF00F5FF),
    this.isProcessing = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const cornerR = 8.0;
    const wallThickness = 3.0;

    // ── Tank shell ──
    final shellRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        wallThickness,
        wallThickness,
        w - wallThickness * 2,
        h - wallThickness * 2,
      ),
      const Radius.circular(cornerR),
    );
    final shellPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = wallThickness;
    canvas.drawRRect(shellRect, shellPaint);

    // ── Inner dark ──
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        wallThickness + 1,
        wallThickness + 1,
        w - (wallThickness + 1) * 2,
        h - (wallThickness + 1) * 2,
      ),
      const Radius.circular(cornerR - 1),
    );
    final innerPaint = Paint()..color = const Color(0xFF050510);
    canvas.drawRRect(innerRect, innerPaint);

    // ── Liquid fill ──
    final fillH = (h - wallThickness * 2 - 2) * level.clamp(0.0, 1.0);
    final liquidTop = h - wallThickness - 1 - fillH;

    canvas.save();
    canvas.clipRRect(innerRect);

    // Wavey surface
    if (level > 0.01) {
      final wavePath = Path();
      wavePath.moveTo(wallThickness + 1, h);
      wavePath.lineTo(wallThickness + 1, liquidTop);

      // Surface waves
      for (double x = wallThickness + 1; x <= w - wallThickness - 1; x += 1) {
        final wave1 =
            math.sin((x / w) * math.pi * 3 + bubblePhase * math.pi * 2) * 2;
        final wave2 =
            math.sin((x / w) * math.pi * 5 - bubblePhase * math.pi * 1.5) * 1.2;
        wavePath.lineTo(x, liquidTop + wave1 + wave2);
      }

      wavePath.lineTo(w - wallThickness - 1, h);
      wavePath.close();

      // Liquid gradient
      final liquidPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            liquidColor.withValues(alpha: 0.5),
            liquidColor.withValues(alpha: 0.2),
          ],
        ).createShader(Rect.fromLTWH(0, liquidTop, w, fillH));
      canvas.drawPath(wavePath, liquidPaint);

      // Liquid glow
      final lgPaint = Paint()
        ..color = liquidColor.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(wavePath, lgPaint);
    }

    // ── Bubbles ──
    if (isProcessing && level > 0.05) {
      final rng = math.Random(42);
      final bubblePaint = Paint()..style = PaintingStyle.fill;
      for (var i = 0; i < 12; i++) {
        final bx =
            wallThickness + 8 + rng.nextDouble() * (w - wallThickness * 2 - 16);
        final baseY = h - wallThickness - 4;
        final travelDist = fillH * 0.9;
        final phaseBubble = (bubblePhase + rng.nextDouble()) % 1.0;
        final by = baseY - travelDist * phaseBubble;
        final br = 1.0 + rng.nextDouble() * 2.5;
        final alpha = (1.0 - phaseBubble) * 0.5;

        if (by > liquidTop) {
          bubblePaint.color = liquidColor.withValues(alpha: alpha);
          canvas.drawCircle(Offset(bx, by), br, bubblePaint);
        }
      }
    }

    canvas.restore();

    // ── Level markers ──
    final markerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      final my = h - wallThickness - 1 - (h - wallThickness * 2 - 2) * (i / 4);
      canvas.drawLine(
        Offset(w - wallThickness - 6, my),
        Offset(w - wallThickness - 1, my),
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TankPainter old) =>
      old.level != level ||
      old.bubblePhase != bubblePhase ||
      old.isProcessing != isProcessing;
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. CONVENIENCE WIDGETS — Ready-to-use animated pipe components
// ─────────────────────────────────────────────────────────────────────────────

/// Animated pipe widget with built-in animation controller
class AnimatedPipeFlow extends StatefulWidget {
  final double intensity;
  final Color pipeColor;
  final bool isActive;
  final double strokeWidth;
  final List<Offset>? waypoints;
  final double height;

  const AnimatedPipeFlow({
    super.key,
    this.intensity = 0.6,
    this.pipeColor = const Color(0xFF00F5FF),
    this.isActive = true,
    this.strokeWidth = 6.0,
    this.waypoints,
    this.height = 40,
  });

  @override
  State<AnimatedPipeFlow> createState() => _AnimatedPipeFlowState();
}

class _AnimatedPipeFlowState extends State<AnimatedPipeFlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => CustomPaint(
        painter: PipeFlowPainter(
          flowPhase: _ctrl.value,
          intensity: widget.intensity,
          pipeColor: widget.pipeColor,
          isActive: widget.isActive,
          strokeWidth: widget.strokeWidth,
          waypoints: widget.waypoints,
        ),
        size: Size(double.infinity, widget.height),
      ),
    );
  }
}

/// Animated processing tank widget
class AnimatedTank extends StatefulWidget {
  final double level;
  final Color liquidColor;
  final bool isProcessing;
  final double width;
  final double height;

  const AnimatedTank({
    super.key,
    required this.level,
    this.liquidColor = const Color(0xFF00F5FF),
    this.isProcessing = true,
    this.width = 80,
    this.height = 120,
  });

  @override
  State<AnimatedTank> createState() => _AnimatedTankState();
}

class _AnimatedTankState extends State<AnimatedTank>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => CustomPaint(
        painter: TankPainter(
          level: widget.level,
          bubblePhase: _ctrl.value,
          liquidColor: widget.liquidColor,
          isProcessing: widget.isProcessing,
        ),
        size: Size(widget.width, widget.height),
      ),
    );
  }
}

/// Pressure gauge widget label + value display
class PressureGaugeWidget extends StatelessWidget {
  final String label;
  final String valueText;
  final double value;
  final double dangerThreshold;
  final double warningThreshold;
  final Color normalColor;
  final double size;

  const PressureGaugeWidget({
    super.key,
    required this.label,
    required this.valueText,
    required this.value,
    this.dangerThreshold = 0.8,
    this.warningThreshold = 0.6,
    this.normalColor = const Color(0xFF00F5FF),
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    Color textColor;
    if (clampedValue >= dangerThreshold) {
      textColor = const Color(0xFFFF3366);
    } else if (clampedValue >= warningThreshold) {
      textColor = const Color(0xFFFFB800);
    } else {
      textColor = normalColor;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: PressureGaugePainter(
              value: clampedValue,
              dangerThreshold: dangerThreshold,
              warningThreshold: warningThreshold,
              normalColor: normalColor,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  valueText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: size * 0.16,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
