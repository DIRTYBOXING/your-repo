import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/ppv_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV VIDEO PLAYER HUD — NEON TOP BAR
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Persistent overlay showing:
/// - Fighter names (left/right with weights)
/// - Round indicator
/// - Live badge (pulsing red)
/// - Fight clock
/// - Glassmorphism background
///
/// ═══════════════════════════════════════════════════════════════════════════

class PPVVideoPlayerHUD extends StatefulWidget {
  final PPVEvent event;
  final ValueNotifier<int> currentRound;
  final bool isLive;

  const PPVVideoPlayerHUD({
    super.key,
    required this.event,
    required this.currentRound,
    required this.isLive,
  });

  @override
  State<PPVVideoPlayerHUD> createState() => _PPVVideoPlayerHUDState();
}

class _PPVVideoPlayerHUDState extends State<PPVVideoPlayerHUD>
    with SingleTickerProviderStateMixin {
  late AnimationController _livePulseCtrl;
  late Animation<double> _livePulse;

  @override
  void initState() {
    super.initState();
    _livePulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _livePulse = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _livePulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _livePulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.event.fightCard.isEmpty) {
      return const SizedBox.shrink();
    }

    final fight = widget.event.fightCard.first;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: const ColorFilter.mode(Colors.black26, BlendMode.srcOver),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // ── Fighter 1 ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fight.fighter1Name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fight.weightClass.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Center: Round + Live ──
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: widget.currentRound,
                        builder: (context, round, _) {
                          return Text(
                            'R$round',
                            style: const TextStyle(
                              color: DesignTokens.neonCyan,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      if (widget.isLive)
                        AnimatedBuilder(
                          animation: _livePulse,
                          builder: (context, _) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(
                                  alpha: _livePulse.value * 0.3,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.red.withValues(
                                    alpha: _livePulse.value * 0.6,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),

                  // ── Fighter 2 ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fight.fighter2Name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fight.weightClass.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
