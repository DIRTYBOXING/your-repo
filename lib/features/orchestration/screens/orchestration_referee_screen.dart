import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/event_session_model.dart';
import '../services/event_orchestration_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ORCHESTRATION REFEREE SCREEN — Official Scoring Interface
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Referee/judge interface for:
///   - Round-by-round scoring (10-point must system)
///   - Knockdown/submission markers
///   - Official scorecard submission
///   - Decision recording
///
/// ═══════════════════════════════════════════════════════════════════════════

class OrchestrationRefereeScreen extends StatefulWidget {
  /// Event ID
  final String eventId;

  /// Session ID
  final String sessionId;

  /// Fight ID
  final String fightId;

  const OrchestrationRefereeScreen({
    super.key,
    required this.eventId,
    required this.sessionId,
    required this.fightId,
  });

  @override
  State<OrchestrationRefereeScreen> createState() =>
      _OrchestrationRefereeScreenState();
}

class _OrchestrationRefereeScreenState
    extends State<OrchestrationRefereeScreen> {
  late EventOrchestrationService _orchestrationService;
  FightSession? _fight;
  int _fighter1RoundScore = 10;
  int _fighter2RoundScore = 9;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _orchestrationService = EventOrchestrationService();
    _orchestrationService.addListener(_onUpdate);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _orchestrationService.initializeSession(
        widget.eventId,
        widget.sessionId,
      );
      _fight = _orchestrationService.currentFight;
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('❌ Error initializing referee screen: $e');
    }
  }

  void _onUpdate() {
    if (mounted) {
      setState(() => _fight = _orchestrationService.currentFight);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _fight == null) {
      return Scaffold(
        backgroundColor: DesignTokens.bgPrimary,
        appBar: AppBar(title: const Text('Referee - Official Scoring')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgCard,
        title: const Text('Referee - Official Scoring'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fight Header ──
            _buildFightHeader(),
            const SizedBox(height: 24),

            // ── Scoring Interface ──
            _buildScoringInterface(),
            const SizedBox(height: 24),

            // ── Submit Score Button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRoundScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.neonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'SUBMIT ROUND SCORE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFightHeader() {
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
        children: [
          Text(
            'ROUND ${_fight?.currentRound ?? 1}',
            style: TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fight?.fighter1Name ?? 'Fighter 1',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
              Text('vs', style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text(
                _fight?.fighter2Name ?? 'Fighter 2',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoringInterface() {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        border: Border.all(
          color: DesignTokens.neonAmber.withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '10-POINT MUST SYSTEM',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),

          // ── Fighter 1 Score ──
          _buildScoreControl(
            fighterName: _fight?.fighter1Name ?? 'Fighter 1',
            score: _fighter1RoundScore,
            onChanged: (value) {
              setState(() => _fighter1RoundScore = value);
            },
          ),
          const SizedBox(height: 20),

          // ── Fighter 2 Score ──
          _buildScoreControl(
            fighterName: _fight?.fighter2Name ?? 'Fighter 2',
            score: _fighter2RoundScore,
            onChanged: (value) {
              setState(() => _fighter2RoundScore = value);
            },
          ),

          // ── Score Display ──
          const SizedBox(height: 20),
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                '$_fighter1RoundScore - $_fighter2RoundScore',
                style: TextStyle(
                  color: _fighter1RoundScore > _fighter2RoundScore
                      ? DesignTokens.neonCyan
                      : _fighter2RoundScore > _fighter1RoundScore
                      ? DesignTokens.neonGreen
                      : Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreControl({
    required String fighterName,
    required int score,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fighterName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children:
              [
                ...([10, 9, 8, 7].map((value) {
                  final isSelected = score == value;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(value),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? DesignTokens.neonAmber.withOpacity(0.3)
                              : Colors.white10,
                          border: Border.all(
                            color: isSelected
                                ? DesignTokens.neonAmber
                                : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            '$value',
                            style: TextStyle(
                              color: isSelected
                                  ? DesignTokens.neonAmber
                                  : Colors.white60,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                })),
              ].map(
                (w) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: w,
                ),
              ),
        ),
      ],
    );
  }

  Future<void> _submitRoundScore() async {
    await _orchestrationService.recordRoundScores(
      widget.eventId,
      widget.sessionId,
      widget.fightId,
      _fighter1RoundScore,
      _fighter2RoundScore,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Round ${_fight?.currentRound} score submitted: $_fighter1RoundScore-$_fighter2RoundScore',
          ),
          backgroundColor: DesignTokens.neonGreen,
        ),
      );
    }
  }

  @override
  void dispose() {
    _orchestrationService.removeListener(_onUpdate);
    _orchestrationService.dispose();
    super.dispose();
  }
}
