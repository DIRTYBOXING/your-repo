import 'package:flutter/material.dart';
import '../../../shared/services/realtime_scoring_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// LIVE EVENT OVERLAY — Real-time scoring during live fights.
/// Connects: RealtimeScoringService → Live Event UI
/// ═══════════════════════════════════════════════════════════════════════════

const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);
const _kCyan = Color(0xFF00E5FF);
const _kGold = Color(0xFFFFD740);
const _kGreen = Color(0xFF00E676);
const _kRed = Color(0xFFFF1744);

class LiveScoringOverlayScreen extends StatefulWidget {
  final String fightId;
  const LiveScoringOverlayScreen({super.key, required this.fightId});

  @override
  State<LiveScoringOverlayScreen> createState() =>
      _LiveScoringOverlayScreenState();
}

class _LiveScoringOverlayScreenState extends State<LiveScoringOverlayScreen> {
  final RealtimeScoringService _scoring = RealtimeScoringService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('LIVE SCORING'),
        backgroundColor: _kBg,
        foregroundColor: _kGold,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _kRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kRed.withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: _kRed,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _scoring,
        builder: (context, _) {
          final scoring = _scoring.getFight(widget.fightId);
          if (scoring == null) return _buildWaiting();
          return _buildLiveView(scoring);
        },
      ),
    );
  }

  Widget _buildWaiting() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.scoreboard, color: _kCyan, size: 64),
          const SizedBox(height: 16),
          const Text(
            'WAITING FOR FIGHT TO START',
            style: TextStyle(color: _kCyan, fontSize: 16, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            'Fight ID: ${widget.fightId}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _scoring.startFight(widget.fightId, 'fighter_a', 'fighter_b');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('START SCORING'),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveView(LiveFightScoring scoring) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFighterHeader(scoring),
        const SizedBox(height: 16),
        _buildScoreCards(scoring),
        const SizedBox(height: 16),
        _buildRoundStats(scoring),
        const SizedBox(height: 16),
        _buildFanPoll(scoring),
      ],
    );
  }

  Widget _buildFighterHeader(LiveFightScoring scoring) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.sports_mma, color: _kCyan, size: 36),
                const SizedBox(height: 6),
                Text(
                  scoring.fighterAId,
                  style: const TextStyle(
                    color: _kCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                'ROUND ${scoring.currentRound}',
                style: const TextStyle(
                  color: _kGold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                scoring.isActive ? 'LIVE' : 'ENDED',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.sports_mma, color: _kRed, size: 36),
                const SizedBox(height: 6),
                Text(
                  scoring.fighterBId,
                  style: const TextStyle(
                    color: _kRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCards(LiveFightScoring scoring) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JUDGE SCORECARDS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...scoring.judgeScorecards.map(
            (judge) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      judge.judgeName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${judge.totalForFighter(scoring.fighterAId)}',
                    style: const TextStyle(
                      color: _kCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    '\u2014',
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${judge.totalForFighter(scoring.fighterBId)}',
                    style: const TextStyle(
                      color: _kRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundStats(LiveFightScoring scoring) {
    final aStats = scoring.fighterARounds[scoring.currentRound];
    final bStats = scoring.fighterBRounds[scoring.currentRound];
    if (aStats == null || bStats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ROUND ${scoring.currentRound} STATS',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _statRow(
            'Strikes Landed',
            '${aStats.sigStrikesLanded}',
            '${bStats.sigStrikesLanded}',
          ),
          _statRow(
            'Takedowns',
            '${aStats.takedownsLanded}',
            '${bStats.takedownsLanded}',
          ),
          _statRow(
            'Knockdowns',
            '${aStats.knockdowns}',
            '${bStats.knockdowns}',
          ),
        ],
      ),
    );
  }

  Widget _buildFanPoll(LiveFightScoring scoring) {
    final a = scoring.fanPoll[scoring.fighterAId] ?? 0;
    final b = scoring.fanPoll[scoring.fighterBId] ?? 0;
    final total = a + b;
    final aPct = total > 0 ? (a / total * 100) : 50.0;
    final bPct = total > 0 ? (b / total * 100) : 50.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FAN POLL',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: aPct.round().clamp(1, 99),
                  child: Container(height: 20, color: _kCyan),
                ),
                Expanded(
                  flex: bPct.round().clamp(1, 99),
                  child: Container(height: 20, color: _kRed),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${aPct.toStringAsFixed(0)}% ($a votes)',
                style: const TextStyle(color: _kCyan, fontSize: 10),
              ),
              Text(
                '${bPct.toStringAsFixed(0)}% ($b votes)',
                style: const TextStyle(color: _kRed, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String aVal, String bVal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            aVal,
            style: const TextStyle(
              color: _kCyan,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            bVal,
            style: const TextStyle(
              color: _kRed,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
