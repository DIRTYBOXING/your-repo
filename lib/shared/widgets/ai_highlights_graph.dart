import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../services/video_highlights_service.dart';

/// Cloudinary-style AI Highlights Graph overlay for video timelines.
///
/// Renders a filled interest-level sparkline with:
///  - Gradient fill (cyan → magenta peaks)
///  - Key moment markers (pulsing dots)
///  - Hover/tap interaction to show labels + scores
///  - Suggested clip region highlight
///
/// Usage:
/// ```dart
/// AiHighlightsGraph(
///   highlights: myVideoHighlights,
///   playbackPosition: 0.35,
///   onSeek: (pos) => controller.seekTo(pos * duration),
/// )
/// ```
class AiHighlightsGraph extends StatefulWidget {
  final VideoHighlights highlights;

  /// Current playback position as fraction 0.0–1.0
  final double playbackPosition;

  /// Height of the graph widget
  final double height;

  /// Called when user taps/drags on the graph — fraction 0.0–1.0
  final ValueChanged<double>? onSeek;

  /// Show key moment markers
  final bool showKeyMoments;

  /// Show the suggested clip region
  final bool showClipRegion;

  /// Whether to animate the entry
  final bool animate;

  const AiHighlightsGraph({
    super.key,
    required this.highlights,
    this.playbackPosition = 0.0,
    this.height = 56,
    this.onSeek,
    this.showKeyMoments = true,
    this.showClipRegion = true,
    this.animate = true,
  });

  @override
  State<AiHighlightsGraph> createState() => _AiHighlightsGraphState();
}

class _AiHighlightsGraphState extends State<AiHighlightsGraph>
    with SingleTickerProviderStateMixin {
  double? _hoverPosition;
  late AnimationController _animCtrl;
  late Animation<double> _revealAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _revealAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
    if (widget.animate) {
      _animCtrl.forward();
    } else {
      _animCtrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleInteraction(Offset localPosition, double width) {
    final pos = (localPosition.dx / width).clamp(0.0, 1.0);
    setState(() => _hoverPosition = pos);
    widget.onSeek?.call(pos);
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.highlights;
    if (h.segments.isEmpty) {
      return SizedBox(height: widget.height);
    }

    return AnimatedBuilder(
      animation: _revealAnim,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (d) => _handleInteraction(
            d.localPosition,
            context.size?.width ?? MediaQuery.of(context).size.width,
          ),
          onHorizontalDragUpdate: (d) => _handleInteraction(
            d.localPosition,
            context.size?.width ?? MediaQuery.of(context).size.width,
          ),
          onHorizontalDragEnd: (_) => setState(() => _hoverPosition = null),
          child: MouseRegion(
            onHover: (e) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                setState(
                  () => _hoverPosition = e.localPosition.dx / box.size.width,
                );
              }
            },
            onExit: (_) => setState(() => _hoverPosition = null),
            cursor: SystemMouseCursors.click,
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: CustomPaint(
                painter: _HighlightsGraphPainter(
                  segments: h.segments,
                  keyMoments: widget.showKeyMoments ? h.keyMoments : [],
                  durationSeconds: h.durationSeconds,
                  playbackPosition: widget.playbackPosition,
                  hoverPosition: _hoverPosition,
                  revealFraction: _revealAnim.value,
                  suggestedClipStart: widget.showClipRegion
                      ? h.suggestedClipStart
                      : null,
                  suggestedClipEnd: widget.showClipRegion
                      ? h.suggestedClipEnd
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER
// ═════════════════════════════════════════════════════════════════════════════

class _HighlightsGraphPainter extends CustomPainter {
  final List<HighlightSegment> segments;
  final List<KeyMoment> keyMoments;
  final double durationSeconds;
  final double playbackPosition;
  final double? hoverPosition;
  final double revealFraction;
  final double? suggestedClipStart;
  final double? suggestedClipEnd;

  _HighlightsGraphPainter({
    required this.segments,
    required this.keyMoments,
    required this.durationSeconds,
    required this.playbackPosition,
    this.hoverPosition,
    this.revealFraction = 1.0,
    this.suggestedClipStart,
    this.suggestedClipEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final barHeight = h - 16; // Reserve 16px top for markers/labels

    // ── Clip region highlight ──
    if (suggestedClipStart != null &&
        suggestedClipEnd != null &&
        durationSeconds > 0) {
      final clipX0 = (suggestedClipStart! / durationSeconds) * w;
      final clipX1 = (suggestedClipEnd! / durationSeconds) * w;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(clipX0, 16, clipX1, h),
          const Radius.circular(4),
        ),
        Paint()..color = DesignTokens.neonGold.withValues(alpha: 0.08),
      );
      // Top bracket lines
      final bracketPaint = Paint()
        ..color = DesignTokens.neonGold.withValues(alpha: 0.5)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(clipX0, 16), Offset(clipX0, h), bracketPaint);
      canvas.drawLine(Offset(clipX1, 16), Offset(clipX1, h), bracketPaint);
    }

    // ── Build interest curve path ──
    final path = Path();
    final fillPath = Path();
    final step = w / segments.length;

    for (var i = 0; i < segments.length; i++) {
      final x = i * step + step / 2;
      // Reveal animation: scale Y from 0 to full
      final y = h - (segments[i].interestScore * barHeight * revealFraction);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(0, h);
        fillPath.lineTo(0, y);
      } else {
        // Smooth cubic interpolation
        final prevX = (i - 1) * step + step / 2;
        final prevY =
            h - (segments[i - 1].interestScore * barHeight * revealFraction);
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    fillPath.lineTo(w, h);
    fillPath.close();

    // ── Gradient fill ──
    final gradient = ui.Gradient.linear(
      Offset(0, h),
      const Offset(0, 16),
      [
        DesignTokens.neonCyan.withValues(alpha: 0.0),
        DesignTokens.neonCyan.withValues(alpha: 0.25),
        DesignTokens.neonMagenta.withValues(alpha: 0.4),
      ],
      [0.0, 0.5, 1.0],
    );

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill,
    );

    // ── Stroke line ──
    final linePaint = Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(w, 0), [
        DesignTokens.neonCyan,
        DesignTokens.neonMagenta,
      ])
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // ── Playback position indicator ──
    if (playbackPosition > 0) {
      final px = playbackPosition.clamp(0.0, 1.0) * w;
      canvas.drawLine(
        Offset(px, 16),
        Offset(px, h),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..strokeWidth = 2.0,
      );
      // Small dot at top
      canvas.drawCircle(Offset(px, 16), 3, Paint()..color = Colors.white);
    }

    // ── Hover indicator ──
    if (hoverPosition != null) {
      final hx = hoverPosition!.clamp(0.0, 1.0) * w;
      canvas.drawLine(
        Offset(hx, 16),
        Offset(hx, h),
        Paint()
          ..color = DesignTokens.neonCyan.withValues(alpha: 0.6)
          ..strokeWidth = 1.2,
      );

      // Show interest score at hover
      final segIdx = (hoverPosition! * segments.length)
          .clamp(0, segments.length - 1)
          .toInt();
      final score = segments[segIdx].interestScore;
      final label = '${(score * 100).round()}%';

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: DesignTokens.neonCyan,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelX = (hx - tp.width / 2).clamp(0.0, w - tp.width);
      tp.paint(canvas, Offset(labelX, 2));
    }

    // ── Key moment markers ──
    if (durationSeconds > 0) {
      for (final moment in keyMoments) {
        final mx = (moment.timestamp / durationSeconds).clamp(0.0, 1.0) * w;
        final markerColor = _momentColor(moment.type);

        // Outer glow
        canvas.drawCircle(
          Offset(mx, h - 4),
          5,
          Paint()..color = markerColor.withValues(alpha: 0.3),
        );
        // Inner dot
        canvas.drawCircle(Offset(mx, h - 4), 3, Paint()..color = markerColor);
      }
    }
  }

  Color _momentColor(MomentType type) {
    return switch (type) {
      MomentType.knockdown => DesignTokens.neonRed,
      MomentType.finish => DesignTokens.neonGold,
      MomentType.strike => DesignTokens.neonAmber,
      MomentType.takedown => DesignTokens.neonCyan,
      MomentType.submission => DesignTokens.neonMagenta,
      MomentType.technique => DesignTokens.neonGreen,
      MomentType.crowd => DesignTokens.neonBlue,
      MomentType.other => DesignTokens.textSecondary,
    };
  }

  @override
  bool shouldRepaint(covariant _HighlightsGraphPainter oldDelegate) {
    return oldDelegate.playbackPosition != playbackPosition ||
        oldDelegate.hoverPosition != hoverPosition ||
        oldDelegate.revealFraction != revealFraction ||
        oldDelegate.segments != segments;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// KEY MOMENT CHIP — companion widget
// ═════════════════════════════════════════════════════════════════════════════

/// Displays a clickable key-moment badge for the highlights timeline.
class KeyMomentChip extends StatelessWidget {
  final KeyMoment moment;
  final double? durationSeconds;
  final VoidCallback? onTap;

  const KeyMomentChip({
    super.key,
    required this.moment,
    this.durationSeconds,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _chipColor(moment.type);
    final time = _formatTime(moment.timestamp);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: DesignTokens.spacingXS,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: DesignTokens.borderThin,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_chipIcon(moment.type), color: color, size: 14),
              const SizedBox(width: DesignTokens.spacingXS),
              Text(
                time,
                style: TextStyle(
                  color: color,
                  fontSize: DesignTokens.fontSizeMicro,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingXS),
              Flexible(
                child: Text(
                  moment.label,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeCaption,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingXS),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(moment.interestScore * 100).round()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(double seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).round();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _chipColor(MomentType type) => switch (type) {
    MomentType.knockdown => DesignTokens.neonRed,
    MomentType.finish => DesignTokens.neonGold,
    MomentType.strike => DesignTokens.neonAmber,
    MomentType.takedown => DesignTokens.neonCyan,
    MomentType.submission => DesignTokens.neonMagenta,
    MomentType.technique => DesignTokens.neonGreen,
    MomentType.crowd => DesignTokens.neonBlue,
    MomentType.other => DesignTokens.textSecondary,
  };

  IconData _chipIcon(MomentType type) => switch (type) {
    MomentType.knockdown => Icons.flash_on,
    MomentType.finish => Icons.emoji_events,
    MomentType.strike => Icons.sports_mma,
    MomentType.takedown => Icons.arrow_downward,
    MomentType.submission => Icons.lock,
    MomentType.technique => Icons.star,
    MomentType.crowd => Icons.people,
    MomentType.other => Icons.access_time,
  };
}

// ═════════════════════════════════════════════════════════════════════════════
// MINI SPARKLINE — compact inline version
// ═════════════════════════════════════════════════════════════════════════════

/// A compact interest sparkline for cards, lists, thumbnails.
class HighlightSparkline extends StatelessWidget {
  final List<double> scores;
  final double height;
  final double width;
  final Color color;

  const HighlightSparkline({
    super.key,
    required this.scores,
    this.height = 24,
    this.width = 120,
    this.color = DesignTokens.neonCyan,
  });

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) return SizedBox(height: height, width: width);
    return SizedBox(
      height: height,
      width: width,
      child: CustomPaint(
        painter: _SparklinePainter(scores: scores, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> scores;
  final Color color;

  _SparklinePainter({required this.scores, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;
    final path = Path();
    final step = size.width / (scores.length - 1).clamp(1, scores.length);
    final maxH = size.height;

    for (var i = 0; i < scores.length; i++) {
      final x = i * step;
      final y = maxH - (scores[i].clamp(0.0, 1.0) * maxH);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final px = (i - 1) * step;
        final py = maxH - (scores[i - 1].clamp(0.0, 1.0) * maxH);
        final cpx = (px + x) / 2;
        path.cubicTo(cpx, py, cpx, y, x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Faint fill below
    final fill = Path.from(path)
      ..lineTo(size.width, maxH)
      ..lineTo(0, maxH)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, maxH), Offset.zero, [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.15),
        ]),
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.scores != scores || old.color != color;
}
