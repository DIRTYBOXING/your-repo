import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../screens/ppv_watch_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV STATS OVERLAY — FIGHT INTELLIGENCE LAYER
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Displays side-by-side fighter stats:
/// - Strikes landed / attempted
/// - Takedowns landed / attempted
/// - Control time
/// - Round scorecard
/// - Animated transitions
///
/// ═══════════════════════════════════════════════════════════════════════════

class PPVStatsOverlay extends StatefulWidget {
  final String fighter1;
  final String fighter2;
  final ValueNotifier<FighterStats> fighter1Stats;
  final ValueNotifier<FighterStats> fighter2Stats;

  const PPVStatsOverlay({
    super.key,
    required this.fighter1,
    required this.fighter2,
    required this.fighter1Stats,
    required this.fighter2Stats,
  });

  @override
  State<PPVStatsOverlay> createState() => _PPVStatsOverlayState();
}

class _PPVStatsOverlayState extends State<PPVStatsOverlay> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: const ColorFilter.mode(Colors.black26, BlendMode.srcOver),
            child: Container(
              width: _expanded ? 320 : 140,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STATS',
                          style: TextStyle(
                            color: DesignTokens.neonCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          color: DesignTokens.neonCyan,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_expanded) ...[
                      // ── Fighter 1 Stats ──
                      _buildFighterStats(
                        widget.fighter1,
                        widget.fighter1Stats,
                        isLeft: true,
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.1),
                        height: 1,
                      ),
                      const SizedBox(height: 12),

                      // ── Fighter 2 Stats ──
                      _buildFighterStats(
                        widget.fighter2,
                        widget.fighter2Stats,
                        isLeft: false,
                      ),
                    ] else ...[
                      // ── Compact Mode ──
                      ValueListenableBuilder<FighterStats>(
                        valueListenable: widget.fighter1Stats,
                        builder: (context, stats, _) {
                          return _buildStatRow(
                            '${stats.strikesLanded}',
                            'Strikes',
                            '${widget.fighter2Stats.value.strikesLanded}',
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<FighterStats>(
                        valueListenable: widget.fighter1Stats,
                        builder: (context, stats, _) {
                          return _buildStatRow(
                            '${stats.takedownsLanded}',
                            'Takedowns',
                            '${widget.fighter2Stats.value.takedownsLanded}',
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<FighterStats>(
                        valueListenable: widget.fighter1Stats,
                        builder: (context, stats, _) {
                          return _buildStatRow(
                            stats.controlTimeDisplay,
                            'Control',
                            widget.fighter2Stats.value.controlTimeDisplay,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFighterStats(
    String fighterName,
    ValueNotifier<FighterStats> statsNotifier, {
    required bool isLeft,
  }) {
    return ValueListenableBuilder<FighterStats>(
      valueListenable: statsNotifier,
      builder: (context, stats, _) {
        return Column(
          crossAxisAlignment: isLeft
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fighterName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatItem(
              label: 'STRIKES',
              value: '${stats.strikesLanded}/${stats.strikeAttempts}',
              accuracy: stats.strikeAccuracy,
              isLeft: isLeft,
            ),
            const SizedBox(height: 6),
            _buildStatItem(
              label: 'TAKEDOWNS',
              value: '${stats.takedownsLanded}/${stats.takedownAttempts}',
              accuracy: stats.takedownAccuracy,
              isLeft: isLeft,
            ),
            const SizedBox(height: 6),
            _buildStatItem(
              label: 'CONTROL TIME',
              value: stats.controlTimeDisplay,
              accuracy: null,
              isLeft: isLeft,
            ),
            const SizedBox(height: 6),
            _buildStatItem(
              label: 'KNOCKDOWNS',
              value: '${stats.knockdowns}',
              accuracy: null,
              isLeft: isLeft,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required double? accuracy,
    required bool isLeft,
  }) {
    return Row(
      mainAxisAlignment: isLeft
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: [
        if (!isLeft) const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: isLeft
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (accuracy != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${accuracy.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isLeft) const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatRow(String leftValue, String label, String rightValue) {
    return Row(
      children: [
        Expanded(
          child: Text(
            leftValue,
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            rightValue,
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
