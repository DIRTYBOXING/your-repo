import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../ppv/models/ppv_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// LIVE FIGHT BANNER WIDGET — Real-Time Fight Indicator
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Displays a live fight banner in the social feed:
///   - Fighter names & images
///   - Current round
///   - Time remaining
///   - Recent action (knockdowns, submissions)
///   - Tap to watch or purchase PPV
///   - Live indicator
///   - Auto-updates with orchestration events
///
/// ═══════════════════════════════════════════════════════════════════════════

class LiveFightBannerWidget extends StatefulWidget {
  /// PPV Event
  final PPVEvent event;

  /// Current fight from fightCard
  final PPVFight? currentFight;

  /// Current round
  final int round;

  /// Time in round (seconds)
  final int timeInRound;

  /// Recent action text
  final String? recentAction;

  /// Callback when tapped
  final VoidCallback onTap;

  const LiveFightBannerWidget({
    super.key,
    required this.event,
    this.currentFight,
    this.round = 1,
    this.timeInRound = 0,
    this.recentAction,
    required this.onTap,
  });

  @override
  State<LiveFightBannerWidget> createState() => _LiveFightBannerWidgetState();
}

class _LiveFightBannerWidgetState extends State<LiveFightBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final fight = widget.currentFight;
    if (fight == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DesignTokens.neonRed.withOpacity(0.15),
              DesignTokens.neonCyan.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: DesignTokens.neonRed.withOpacity(0.5),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.neonRed.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Main Content ──
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Live Indicator
                      Row(
                        children: [
                          _buildPulseDot(),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: DesignTokens.neonRed,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),

                      // Round & Time
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonCyan.withOpacity(0.2),
                          border: Border.all(
                            color: DesignTokens.neonCyan.withOpacity(0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'R${widget.round} · ${_formatTime(widget.timeInRound)}',
                          style: TextStyle(
                            color: DesignTokens.neonCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Watch Button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonGreen.withOpacity(0.3),
                          border: Border.all(
                            color: DesignTokens.neonGreen,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'WATCH',
                          style: TextStyle(
                            color: DesignTokens.neonGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Fighter Names ──
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fight.fighter1Name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fight.fighter1Record,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'vs',
                          style: TextStyle(
                            color: DesignTokens.neonCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fight.fighter2Name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fight.fighter2Record,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Recent Action ──
                  if (widget.recentAction != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonAmber.withOpacity(0.2),
                          border: Border.all(
                            color: DesignTokens.neonAmber.withOpacity(0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.recentAction!,
                          style: TextStyle(
                            color: DesignTokens.neonAmber,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Live Pulse Background ──
            Positioned(
              top: 0,
              right: 0,
              child: Opacity(
                opacity: _pulseController.value * 0.1,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignTokens.neonRed,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build pulsing live indicator dot
  Widget _buildPulseDot() {
    return ScaleTransition(
      scale: _pulseController,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: DesignTokens.neonRed,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: DesignTokens.neonRed.withOpacity(0.5),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
