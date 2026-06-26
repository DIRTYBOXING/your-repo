import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ADRENALINE THEME — Pulsing Electric Crimson for the Digital Colosseum
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Provides the "Adrenaline Gate" visual language:
///   • Electric Crimson primary with 30px blur glow
///   • Living color interpolation based on hype level
///   • BoxDecoration factories for win probability states
///
/// ═══════════════════════════════════════════════════════════════════════════
abstract class AdrenalineTheme {
  AdrenalineTheme._();

  // ── Core "Adrenaline" Colors ──
  static const Color electricCrimson = Color(0xFFFF1744);
  static const Color deepCrimson = Color(0xFFB71C1C);
  static const Color whiteHot = Color(0xFFFFF3E0);
  static const Color koBlue = Color(0xFF448AFF); // "Iceman" variant
  static const Color warningOrange = Color(0xFFFF9100);

  /// The signature pulsing glow BoxShadow — blur radius 30.
  static List<BoxShadow> crimsonGlow({double opacity = 0.6}) => [
    BoxShadow(
      color: electricCrimson.withValues(alpha: opacity),
      blurRadius: 30,
      spreadRadius: 2,
    ),
  ];

  /// Dynamic glow that intensifies with hype level [0→1].
  static List<BoxShadow> hypeGlow(double intensity) {
    final clamped = intensity.clamp(0.0, 1.0);
    final color = hypeColor(clamped);
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.2 + 0.5 * clamped),
        blurRadius: 12 + 18 * clamped,
        spreadRadius: 1 + 3 * clamped,
      ),
    ];
  }

  /// Interpolated color based on hype level.
  /// 0.0 = muted, 0.5 = crimson, 0.8 = orange, 1.0 = white-hot
  static Color hypeColor(double intensity) {
    if (intensity < 0.5) {
      return Color.lerp(DesignTokens.neonRed, electricCrimson, intensity * 2)!;
    }
    if (intensity < 0.8) {
      return Color.lerp(
        electricCrimson,
        warningOrange,
        (intensity - 0.5) / 0.3,
      )!;
    }
    return Color.lerp(warningOrange, whiteHot, (intensity - 0.8) / 0.2)!;
  }

  /// The "Heat-Strike" border for cards reacting to fight data.
  static BoxDecoration heatStrikeDecoration({
    required double intensity,
    double borderRadius = DesignTokens.radiusMedium,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: hypeColor(intensity).withValues(alpha: 0.3 + 0.5 * intensity),
        width: 1.0 + intensity,
      ),
      boxShadow: hypeGlow(intensity),
    );
  }

  /// Fighter-specific fire color (extensible).
  static Color fighterFireColor(String? nickname) {
    final lower = (nickname ?? '').toLowerCase();
    if (lower.contains('ice') || lower.contains('frost')) return koBlue;
    if (lower.contains('matador') || lower.contains('bull')) return deepCrimson;
    return electricCrimson; // default
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// ADRENALINE HUD — Custom Painter for Hype Meter
/// ═══════════════════════════════════════════════════════════════════════════
///
/// A living arc-gauge that reacts to win probability. Replaces static bars
/// with a flowing, breathing meter.
///
///   HypeMeter(hypeLevel: 0.85, label: 'KO PROBABILITY')
///
/// ═══════════════════════════════════════════════════════════════════════════
class HypeMeter extends StatefulWidget {
  /// Current hype / win probability [0.0 → 1.0].
  final double hypeLevel;

  /// Label beneath the meter.
  final String label;

  /// Meter diameter.
  final double size;

  const HypeMeter({
    super.key,
    required this.hypeLevel,
    this.label = 'HYPE',
    this.size = 120,
  });

  @override
  State<HypeMeter> createState() => _HypeMeterState();
}

class _HypeMeterState extends State<HypeMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        final pulse = _pulseAnim.value;
        final hype = widget.hypeLevel.clamp(0.0, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _HypeMeterPainter(hypeLevel: hype, pulseValue: pulse),
                child: Center(
                  child: Text(
                    '${(hype * 100).toInt()}%',
                    style: TextStyle(
                      color: AdrenalineTheme.hypeColor(hype),
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: AdrenalineTheme.hypeColor(
                            hype,
                          ).withValues(alpha: 0.6 + 0.4 * pulse),
                          blurRadius: 12 + 8 * pulse,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: const TextStyle(
                color: DesignTokens.textSecondary,
                fontSize: DesignTokens.fontSizeCaption,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HypeMeterPainter extends CustomPainter {
  final double hypeLevel;
  final double pulseValue;

  _HypeMeterPainter({required this.hypeLevel, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const startAngle = math.pi * 0.75; // 7 o'clock
    const sweepMax = math.pi * 1.5; // 270° arc

    // ── Track (dim background arc) ──
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepMax,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // ── Filled arc (hype level) ──
    final sweepAngle = sweepMax * hypeLevel;
    final hypeColor = AdrenalineTheme.hypeColor(hypeLevel);

    // Outer glow (pulsing)
    final glowAlpha = 0.15 + 0.25 * pulseValue * hypeLevel;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = hypeColor.withValues(alpha: glowAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Main arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = hypeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // ── Endpoint dot (bright, pulsing) ──
    if (hypeLevel > 0.05) {
      final endAngle = startAngle + sweepAngle;
      final dotCenter = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );
      canvas.drawCircle(
        dotCenter,
        4 + 2 * pulseValue,
        Paint()..color = hypeColor,
      );
      canvas.drawCircle(
        dotCenter,
        8 + 4 * pulseValue,
        Paint()
          ..color = hypeColor.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(_HypeMeterPainter old) =>
      hypeLevel != old.hypeLevel || pulseValue != old.pulseValue;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FLASH OVERLAY — Visual Strobe for KO / Fight-Ending Sequences
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Sits at the top of your Stack. When triggered, flashes for 100ms
/// then fades into the Liquid Fire color.
///
///   FlashOverlay(controller: _flashController)
///
/// Trigger: _flashController.forward().then((_) => _flashController.reverse());
///
/// ═══════════════════════════════════════════════════════════════════════════
class FlashOverlay extends StatelessWidget {
  /// Should be an AnimationController driven externally.
  final Animation<double> animation;

  /// Flash color (defaults to electric white → crimson fade).
  final Color flashColor;

  const FlashOverlay({
    super.key,
    required this.animation,
    this.flashColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final value = animation.value;
        if (value < 0.01) return const SizedBox.shrink();

        // Flash: white peak → crimson fade
        final color = Color.lerp(
          flashColor,
          AdrenalineTheme.electricCrimson,
          (1 - value).clamp(0.0, 1.0),
        )!;

        return IgnorePointer(
          child: Container(color: color.withValues(alpha: value * 0.7)),
        );
      },
    );
  }
}
