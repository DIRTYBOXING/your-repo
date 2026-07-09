import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/fight_stats_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV SCORECARD DISPLAY — FIGHT ADJUDICATION
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Displays the official scorecard:
///   - Round-by-round scores
///   - Fighter totals
///   - Round winner badges
///   - Fight result (if completed)
///
/// Uses 10-point must system:
///   - 10-9 (winner/loser)
///   - 10-8 (significant advantage)
///   - 10-7 (dominant round)
///
/// ═══════════════════════════════════════════════════════════════════════════

class PPVScorecardDisplay extends StatelessWidget {
  /// Official scorecard object
  final FightScorecard scorecard;

  /// Fighter 1 name (for header)
  final String fighter1Name;

  /// Fighter 2 name (for header)
  final String fighter2Name;

  /// Whether to show full details or compact view
  final bool isCompact;

  const PPVScorecardDisplay({
    super.key,
    required this.scorecard,
    required this.fighter1Name,
    required this.fighter2Name,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        border: Border.all(
          color: DesignTokens.neonCyan.withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: Fighter Names & Totals ──
          _buildHeader(),
          const SizedBox(height: 16),

          // ── Round-by-round scores ──
          if (!isCompact) ...[_buildRoundScores(), const SizedBox(height: 12)],

          // ── Result (if fight ended) ──
          if (scorecard.result != null) ...[_buildResult()],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Fighter names with total scores
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fighter1Name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    scorecard.fighter1TotalScore.toString(),
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'vs',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fighter2Name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    scorecard.fighter2TotalScore.toString(),
                    style: TextStyle(
                      color: DesignTokens.neonGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoundScores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ROUND SCORES',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            scorecard.rounds.length,
            (idx) => _buildRoundBadge(scorecard.rounds[idx]),
          ),
        ),
      ],
    );
  }

  Widget _buildRoundBadge(RoundStats round) {
    final fighter1Score = round.fighter1Stats.currentRoundScore ?? 0;
    final fighter2Score = round.fighter2Stats.currentRoundScore ?? 0;

    // Determine badge color based on round winner
    Color badgeColor = Colors.white12;
    if (fighter1Score > fighter2Score) {
      badgeColor = DesignTokens.neonCyan.withOpacity(0.2);
    } else if (fighter2Score > fighter1Score) {
      badgeColor = DesignTokens.neonGreen.withOpacity(0.2);
    }

    return Container(
      decoration: BoxDecoration(
        color: badgeColor,
        border: Border.all(
          color: _getRoundWinnerColor(fighter1Score, fighter2Score),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        children: [
          Text(
            'R${round.roundNumber}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$fighter1Score-$fighter2Score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoundWinnerColor(int score1, int score2) {
    if (score1 > score2) return DesignTokens.neonCyan;
    if (score2 > score1) return DesignTokens.neonGreen;
    return Colors.white30;
  }

  Widget _buildResult() {
    final winner = scorecard.getWinner();
    final isADraw = winner == 0;

    return Container(
      decoration: BoxDecoration(
        color: isADraw
            ? Colors.orange.withOpacity(0.1)
            : (winner == 1
                  ? DesignTokens.neonCyan.withOpacity(0.1)
                  : DesignTokens.neonGreen.withOpacity(0.1)),
        border: Border.all(
          color: isADraw
              ? Colors.orange
              : (winner == 1 ? DesignTokens.neonCyan : DesignTokens.neonGreen),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Text(
            'RESULT',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isADraw
                ? 'DRAW'
                : '${winner == 1 ? fighter1Name.toUpperCase() : fighter2Name.toUpperCase()} WINS',
            style: TextStyle(
              color: isADraw
                  ? Colors.orange
                  : (winner == 1
                        ? DesignTokens.neonCyan
                        : DesignTokens.neonGreen),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (scorecard.method != null) ...[
            const SizedBox(height: 2),
            Text(
              'via ${scorecard.method}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
