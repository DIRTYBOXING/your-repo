import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/adrenaline_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EVENT COUNTDOWN — T-Minus Ticker for High-Stakes Events
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Real-time countdown that intensifies visually as the event approaches.
/// Fire and glow increase as days → hours → minutes.
///
///   EventCountdown(
///     eventDate: DateTime(2026, 4, 24, 18, 30),
///     label: 'ROESLER vs TANWAR',
///   )
///
/// ═══════════════════════════════════════════════════════════════════════════
class EventCountdown extends StatefulWidget {
  final DateTime eventDate;
  final String? label;
  final bool compact;

  const EventCountdown({
    super.key,
    required this.eventDate,
    this.label,
    this.compact = false,
  });

  @override
  State<EventCountdown> createState() => _EventCountdownState();
}

class _EventCountdownState extends State<EventCountdown> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final diff = widget.eventDate.difference(now);
    if (mounted) {
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// Urgency factor [0.0 → 1.0] — increases as event approaches.
  /// 14+ days = 0.1, 7 days = 0.3, 1 day = 0.7, <1 hour = 1.0
  double get _urgency {
    if (_remaining == Duration.zero) return 1.0;
    final hours = _remaining.inHours;
    if (hours > 336) return 0.1; // 14+ days
    if (hours > 168) return 0.2; // 7-14 days
    if (hours > 72) return 0.3; // 3-7 days
    if (hours > 24) return 0.5; // 1-3 days
    if (hours > 1) return 0.7; // hours away
    return 0.9; // minutes away
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return _buildLiveBadge();
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;
    final urgency = _urgency;
    final accentColor = AdrenalineTheme.hypeColor(urgency);

    if (widget.compact) {
      return _buildCompact(days, hours, minutes, seconds, accentColor, urgency);
    }
    return _buildFull(days, hours, minutes, seconds, accentColor, urgency);
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: Colors.white),
          SizedBox(width: 6),
          Text(
            'LIVE NOW',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(
    int d,
    int h,
    int m,
    int s,
    Color accent,
    double urgency,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        boxShadow: AdrenalineTheme.hypeGlow(urgency * 0.5),
      ),
      child: Text(
        d > 0 ? '${d}d ${h}h ${m}m' : '${h}h ${m}m ${s}s',
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildFull(int d, int h, int m, int s, Color accent, double urgency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.3 + urgency * 0.3),
        ),
        boxShadow: AdrenalineTheme.hypeGlow(urgency * 0.6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.label!,
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimeUnit(d.toString().padLeft(2, '0'), 'DAYS', accent),
              _buildSeparator(accent),
              _buildTimeUnit(h.toString().padLeft(2, '0'), 'HRS', accent),
              _buildSeparator(accent),
              _buildTimeUnit(m.toString().padLeft(2, '0'), 'MIN', accent),
              _buildSeparator(accent),
              _buildTimeUnit(s.toString().padLeft(2, '0'), 'SEC', accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label, Color accent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: accent.withValues(alpha: 0.7),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          color: accent.withValues(alpha: 0.5),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
