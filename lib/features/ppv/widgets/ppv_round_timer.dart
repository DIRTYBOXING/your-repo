import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV ROUND TIMER — ANIMATED CENTERPIECE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Circular/pill-shaped timer showing:
/// - Current round
/// - Time remaining in round (mm:ss)
/// - Pulsing neon glow
/// - Tap to advance/previous rounds
///
/// ═══════════════════════════════════════════════════════════════════════════

class PPVRoundTimer extends StatefulWidget {
  final ValueNotifier<int> currentRound;
  final int totalRounds;
  final ValueNotifier<int> timeRemaining;
  final AnimationController pulseAnimation;
  final VoidCallback onNextRound;
  final VoidCallback onPrevRound;

  const PPVRoundTimer({
    super.key,
    required this.currentRound,
    required this.totalRounds,
    required this.timeRemaining,
    required this.pulseAnimation,
    required this.onNextRound,
    required this.onPrevRound,
  });

  @override
  State<PPVRoundTimer> createState() => _PPVRoundTimerState();
}

class _PPVRoundTimerState extends State<PPVRoundTimer> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Previous Round Button ──
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPrevRound,
            child: Icon(
              Icons.chevron_left,
              color: Colors.white.withValues(alpha: 0.4),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Round Timer Circle ──
        AnimatedBuilder(
          animation: widget.pulseAnimation,
          builder: (context, _) {
            return GestureDetector(
              onTap: widget.onNextRound,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      DesignTokens.neonCyan.withValues(alpha: 0.15),
                      DesignTokens.neonCyan.withValues(alpha: 0.05),
                    ],
                  ),
                  boxShadow: [
                    // Outer glow
                    BoxShadow(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: widget.pulseAnimation.value * 8,
                    ),
                    // Inner shadow
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: DesignTokens.neonCyan.withValues(
                      alpha: 0.3 + (widget.pulseAnimation.value * 0.3),
                    ),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Round Number ──
                      ValueListenableBuilder<int>(
                        valueListenable: widget.currentRound,
                        builder: (context, round, _) {
                          return Text(
                            'ROUND $round',
                            style: TextStyle(
                              color: DesignTokens.neonCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // ── Time Remaining ──
                      ValueListenableBuilder<int>(
                        valueListenable: widget.timeRemaining,
                        builder: (context, seconds, _) {
                          final mins = seconds ~/ 60;
                          final secs = seconds % 60;
                          return Text(
                            '$mins:${secs.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      // ── Max Rounds Indicator ──
                      Text(
                        'of ${widget.totalRounds}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // ── Next Round Button ──
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onNextRound,
            child: Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.4),
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}
