import 'package:flutter/material.dart';
import '../../../shared/services/fight_simulation_engine.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT PREVIEW MODAL — Monte Carlo fight simulation before events.
/// Connects: FightSimulationEngine → Fight Preview UI
/// ═══════════════════════════════════════════════════════════════════════════

const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);
const _kCyan = Color(0xFF00E5FF);
const _kMagenta = Color(0xFFE040FB);
const _kGold = Color(0xFFFFD740);
const _kGreen = Color(0xFF00E676);
const _kRed = Color(0xFFFF1744);

class FightPreviewScreen extends StatefulWidget {
  final String fightId;
  const FightPreviewScreen({super.key, required this.fightId});

  @override
  State<FightPreviewScreen> createState() => _FightPreviewScreenState();
}

class _FightPreviewScreenState extends State<FightPreviewScreen> {
  final FightSimulationEngine _engine = FightSimulationEngine();
  FightSimulationResult? _result;
  bool _simulating = false;

  void _runSimulation() {
    setState(() => _simulating = true);

    // Demo fighters for simulation preview.
    final fighterA = const FighterDNA(
      fighterId: 'fighter_a',
      name: 'Fighter A',
      strikingAccuracy: 0.85,
      strikingPower: 0.80,
      grapplingSkill: 0.70,
      cardio: 0.80,
      chinDurability: 0.75,
      ringIQ: 0.80,
    );
    final fighterB = const FighterDNA(
      fighterId: 'fighter_b',
      name: 'Fighter B',
      strikingAccuracy: 0.75,
      strikingPower: 0.70,
      grapplingSkill: 0.85,
      cardio: 0.82,
      chinDurability: 0.80,
      ringIQ: 0.78,
    );

    final result = _engine.simulate(fighterA, fighterB);
    setState(() {
      _result = result;
      _simulating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('FIGHT PREVIEW'),
        backgroundColor: _kBg,
        foregroundColor: _kCyan,
        elevation: 0,
        centerTitle: true,
      ),
      body: _result == null ? _buildStartView() : _buildResultView(),
    );
  }

  Widget _buildStartView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.science, color: _kCyan, size: 80),
          const SizedBox(height: 20),
          const Text(
            'FIGHT SIMULATION ENGINE',
            style: TextStyle(
              color: _kCyan,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Monte Carlo · 1,000 iterations · Round-by-round',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _simulating ? null : _runSimulation,
            icon: _simulating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_simulating ? 'SIMULATING...' : 'RUN SIMULATION'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final r = _result!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _resultHeader(r),
        const SizedBox(height: 16),
        _probabilityBar(r),
        const SizedBox(height: 16),
        _methodBreakdown(r),
        const SizedBox(height: 16),
        _roundByRound(r),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: _runSimulation,
            icon: const Icon(Icons.refresh),
            label: const Text('RE-SIMULATE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kMagenta,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultHeader(FightSimulationResult r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCyan.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Text(
            'PREDICTED WINNER',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            r.predictedWinnerName,
            style: const TextStyle(
              color: _kGold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(r.predictedWinnerProbability * 100).toStringAsFixed(1)}% probability',
            style: const TextStyle(color: _kGreen, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Most likely: ${r.predictedFinish.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _probabilityBar(FightSimulationResult r) {
    final aPercent = r.fighterAWinProbability * 100;
    final bPercent = r.fighterBWinProbability * 100;
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
            'WIN PROBABILITY',
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
                  flex: aPercent.round(),
                  child: Container(height: 24, color: _kCyan),
                ),
                Expanded(
                  flex: bPercent.round(),
                  child: Container(height: 24, color: _kRed),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fighter A: ${aPercent.toStringAsFixed(1)}%',
                style: const TextStyle(color: _kCyan, fontSize: 11),
              ),
              Text(
                'Fighter B: ${bPercent.toStringAsFixed(1)}%',
                style: const TextStyle(color: _kRed, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _methodBreakdown(FightSimulationResult r) {
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
            'FINISH METHOD BREAKDOWN',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _methodRow('Predicted', r.predictedFinish.name, 1.0),
        ],
      ),
    );
  }

  Widget _roundByRound(FightSimulationResult r) {
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
            'ROUND-BY-ROUND PREDICTION',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...r.roundByRound.map(
            (round) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _kCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'R${round.round}',
                        style: const TextStyle(
                          color: _kCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Winner: ${round.dominantFighter}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'A: ${round.fighterAScore.toStringAsFixed(1)} / B: ${round.fighterBScore.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (round.isFinishRound)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _kRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'FINISH ${round.finishType?.name ?? ""}',
                        style: const TextStyle(color: _kRed, fontSize: 9),
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

  Widget _methodRow(String label, String value, double fraction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: _kBorder,
                color: _kMagenta,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: _kMagenta, fontSize: 10)),
        ],
      ),
    );
  }
}
