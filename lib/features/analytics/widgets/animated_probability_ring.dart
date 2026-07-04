import 'dart:math' as math;
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATED PROBABILITY RING
// Smooth 600ms morphing arc gauge driven by live predictor output.
// Drop-in widget: AnimatedProbabilityRing(probA: 0.74, probB: 0.26, ...)
// ═══════════════════════════════════════════════════════════════════════════════

class AnimatedProbabilityRing extends StatefulWidget {
  final double probA;
  final double probB;
  final String nameA;
  final String nameB;
  final String flagA;
  final String flagB;
  final Color colorA;
  final Color colorB;
  final String? method;
  final double confidence;
  final bool isComputing;

  const AnimatedProbabilityRing({
    super.key,
    required this.probA,
    required this.probB,
    required this.nameA,
    required this.nameB,
    this.flagA = '🥊',
    this.flagB = '🥊',
    this.colorA = const Color(0xFF00E5FF),
    this.colorB = const Color(0xFFFF1744),
    this.method = 'Decision',
    this.confidence = 0.65,
    this.isComputing = false,
  });

  @override
  State<AnimatedProbabilityRing> createState() =>
      _AnimatedProbabilityRingState();
}

class _AnimatedProbabilityRingState extends State<AnimatedProbabilityRing>
    with TickerProviderStateMixin {
  late AnimationController _morphCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _spinCtrl;
  late Animation<double> _probAAnim;
  late Animation<double> _probBAnim;
  late Animation<double> _pulseAnim;

  double _prevProbA = 0.5;
  double _prevProbB = 0.5;

  @override
  void initState() {
    super.initState();

    _morphCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _pulseAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _initAnims(widget.probA, widget.probB);
    _morphCtrl.forward();
  }

  void _initAnims(double probA, double probB) {
    _probAAnim = Tween<double>(begin: _prevProbA, end: probA).animate(
      CurvedAnimation(parent: _morphCtrl, curve: Curves.easeInOutCubic),
    );
    _probBAnim = Tween<double>(begin: _prevProbB, end: probB).animate(
      CurvedAnimation(parent: _morphCtrl, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(AnimatedProbabilityRing old) {
    super.didUpdateWidget(old);
    if (old.probA != widget.probA || old.probB != widget.probB) {
      _prevProbA = _probAAnim.value;
      _prevProbB = _probBAnim.value;
      _initAnims(widget.probA, widget.probB);
      _morphCtrl.forward(from: 0);
      if (widget.isComputing) {
        _spinCtrl.repeat();
      } else {
        _spinCtrl.stop();
        _spinCtrl.reset();
      }
    }
  }

  @override
  void dispose() {
    _morphCtrl.dispose();
    _pulseCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF150A20)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9C6FFF).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFF9C6FFF), size: 16),
              const SizedBox(width: 8),
              const Text(
                'LIVE WIN PROBABILITY',
                style: TextStyle(
                  color: Color(0xFF9C6FFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (widget.isComputing)
                AnimatedBuilder(
                  animation: _spinCtrl,
                  builder: (_, child) => Transform.rotate(
                    angle: _spinCtrl.value * math.pi * 2,
                    child: child,
                  ),
                  child: const Icon(
                    Icons.sync,
                    color: Color(0xFF00E5FF),
                    size: 14,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF00E676).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Dual arc gauges
          AnimatedBuilder(
            animation: Listenable.merge([_probAAnim, _probBAnim, _pulseAnim]),
            builder: (_, __) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ringColumn(
                  widget.flagA,
                  widget.nameA,
                  _probAAnim.value,
                  widget.colorA,
                  _pulseAnim.value,
                ),
                _centerColumn(),
                _ringColumn(
                  widget.flagB,
                  widget.nameB,
                  _probBAnim.value,
                  widget.colorB,
                  _pulseAnim.value,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Method + Confidence strip
          _methodStrip(),
        ],
      ),
    );
  }

  Widget _ringColumn(
    String flag,
    String name,
    double prob,
    Color color,
    double pulse,
  ) {
    return Column(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: CustomPaint(
            painter: _RingPainter(
              probability: prob,
              color: color,
              pulse: pulse,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(flag, style: const TextStyle(fontSize: 22)),
                  Text(
                    '${(prob * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _centerColumn() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Text(
          'VS',
          style: TextStyle(
            color: const Color(
              0xFFFF1744,
            ).withValues(alpha: 0.4 + _pulseCtrl.value * 0.6),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD600).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFFFD600).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Text(
              '${(widget.confidence * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Color(0xFFFFD600),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'CONF.',
              style: TextStyle(
                color: Color(0xFFFFD600),
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _methodStrip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.sports_mma, size: 14, color: Colors.white38),
        const SizedBox(width: 6),
        Text(
          'PREDICTED METHOD: ',
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        Text(
          widget.method ?? 'Decision',
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double probability;
  final Color color;
  final double pulse;

  const _RingPainter({
    required this.probability,
    required this.color,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    const startAngle = -math.pi / 2;

    // Background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    // Glow layer
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      probability * math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = color.withValues(alpha: 0.18 * pulse)
        ..strokeCap = StrokeCap.round,
    );

    // Primary arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      probability * math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..color = color
        ..strokeCap = StrokeCap.round,
    );

    // Leading dot
    if (probability > 0.02) {
      final angle = startAngle + probability * math.pi * 2;
      final dotX = center.dx + radius * math.cos(angle);
      final dotY = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(dotX, dotY), 6, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(dotX, dotY), 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.probability != probability || old.pulse != pulse;
}
