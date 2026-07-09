import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/event_session_model.dart';
import '../services/event_orchestration_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ORCHESTRATION STATS INPUT — Live Combat Metrics Data Entry
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Data operator interface for recording live fight stats:
///   - Strikes (landed/attempted)
///   - Takedowns (landed/attempted)
///   - Control time
///   - Knockdowns
///   - Significant strikes
///   - Guard passes
///   - Reversals
///
/// ═══════════════════════════════════════════════════════════════════════════

class OrchestrationStatsInput extends StatefulWidget {
  /// Event ID
  final String eventId;

  /// Session ID
  final String sessionId;

  /// Fight ID
  final String fightId;

  const OrchestrationStatsInput({
    super.key,
    required this.eventId,
    required this.sessionId,
    required this.fightId,
  });

  @override
  State<OrchestrationStatsInput> createState() =>
      _OrchestrationStatsInputState();
}

class _OrchestrationStatsInputState extends State<OrchestrationStatsInput> {
  late EventOrchestrationService _orchestrationService;
  FightSession? _fight;
  bool _isInitialized = false;

  // ── Fighter 1 Stats ──
  int _f1Strikes = 0;
  int _f1StrikeAttempts = 0;
  int _f1Takedowns = 0;
  int _f1TakedownAttempts = 0;
  int _f1ControlSeconds = 0;
  int _f1Knockdowns = 0;

  // ── Fighter 2 Stats ──
  int _f2Strikes = 0;
  int _f2StrikeAttempts = 0;
  int _f2Takedowns = 0;
  int _f2TakedownAttempts = 0;
  int _f2ControlSeconds = 0;
  int _f2Knockdowns = 0;

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
      debugPrint('❌ Error initializing stats input: $e');
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
        appBar: AppBar(title: const Text('Live Stats Input')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgCard,
        title: const Text('Live Stats Input'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fighter 1 Stats ──
            _buildFighterStatsCard(
              fighterName: _fight!.fighter1Name,
              fighterIndex: 1,
              strikes: _f1Strikes,
              strikeAttempts: _f1StrikeAttempts,
              takedowns: _f1Takedowns,
              takedownAttempts: _f1TakedownAttempts,
              controlSeconds: _f1ControlSeconds,
              knockdowns: _f1Knockdowns,
              onStrikesChanged: (v) => setState(() => _f1Strikes = v),
              onStrikeAttemptsChanged: (v) =>
                  setState(() => _f1StrikeAttempts = v),
              onTakedownsChanged: (v) => setState(() => _f1Takedowns = v),
              onTakedownAttemptsChanged: (v) =>
                  setState(() => _f1TakedownAttempts = v),
              onControlChanged: (v) => setState(() => _f1ControlSeconds = v),
              onKnockdownsChanged: (v) => setState(() => _f1Knockdowns = v),
            ),
            const SizedBox(height: 24),

            // ── Fighter 2 Stats ──
            _buildFighterStatsCard(
              fighterName: _fight!.fighter2Name,
              fighterIndex: 2,
              strikes: _f2Strikes,
              strikeAttempts: _f2StrikeAttempts,
              takedowns: _f2Takedowns,
              takedownAttempts: _f2TakedownAttempts,
              controlSeconds: _f2ControlSeconds,
              knockdowns: _f2Knockdowns,
              onStrikesChanged: (v) => setState(() => _f2Strikes = v),
              onStrikeAttemptsChanged: (v) =>
                  setState(() => _f2StrikeAttempts = v),
              onTakedownsChanged: (v) => setState(() => _f2Takedowns = v),
              onTakedownAttemptsChanged: (v) =>
                  setState(() => _f2TakedownAttempts = v),
              onControlChanged: (v) => setState(() => _f2ControlSeconds = v),
              onKnockdownsChanged: (v) => setState(() => _f2Knockdowns = v),
            ),
            const SizedBox(height: 24),

            // ── Submit Button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitAllStats,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.neonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'SUBMIT ALL STATS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFighterStatsCard({
    required String fighterName,
    required int fighterIndex,
    required int strikes,
    required int strikeAttempts,
    required int takedowns,
    required int takedownAttempts,
    required int controlSeconds,
    required int knockdowns,
    required ValueChanged<int> onStrikesChanged,
    required ValueChanged<int> onStrikeAttemptsChanged,
    required ValueChanged<int> onTakedownsChanged,
    required ValueChanged<int> onTakedownAttemptsChanged,
    required ValueChanged<int> onControlChanged,
    required ValueChanged<int> onKnockdownsChanged,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fighterName.toUpperCase(),
            style: TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatInput(
            label: 'Strikes Landed',
            value: strikes,
            onChanged: onStrikesChanged,
          ),
          _buildStatInput(
            label: 'Strike Attempts',
            value: strikeAttempts,
            onChanged: onStrikeAttemptsChanged,
          ),
          _buildStatInput(
            label: 'Takedowns Landed',
            value: takedowns,
            onChanged: onTakedownsChanged,
          ),
          _buildStatInput(
            label: 'Takedown Attempts',
            value: takedownAttempts,
            onChanged: onTakedownAttemptsChanged,
          ),
          _buildStatInput(
            label: 'Control Time (sec)',
            value: controlSeconds,
            onChanged: onControlChanged,
          ),
          _buildStatInput(
            label: 'Knockdowns',
            value: knockdowns,
            onChanged: onKnockdownsChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildStatInput({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Row(
              children: [
                GestureDetector(
                  onTap: value > 0 ? () => onChanged(value - 1) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.remove, size: 16),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$value',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => onChanged(value + 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.add, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAllStats() async {
    try {
      // Submit Fighter 1 stats
      await _orchestrationService.updateFighterStat(
        widget.eventId,
        widget.sessionId,
        widget.fightId,
        1,
        'strikesLanded',
        _f1Strikes,
      );
      await _orchestrationService.updateFighterStat(
        widget.eventId,
        widget.sessionId,
        widget.fightId,
        1,
        'strikeAttempts',
        _f1StrikeAttempts,
      );
      await _orchestrationService.updateFighterStat(
        widget.eventId,
        widget.sessionId,
        widget.fightId,
        1,
        'takedownsLanded',
        _f1Takedowns,
      );
      await _orchestrationService.updateFighterStat(
        widget.eventId,
        widget.sessionId,
        widget.fightId,
        1,
        'takedownAttempts',
        _f1TakedownAttempts,
      );
      await _orchestrationService.updateFighterStat(
        widget.eventId,
        widget.sessionId,
        widget.fightId,
        1,
        'controlTimeSeconds',
        _f1ControlSeconds,
      );
      await _orchestrationService.updateFighterStat(
        widget.eventId,
        widget.sessionId,
        widget.fightId,
        1,
        'knockdowns',
        _f1Knockdowns,
      );

      // Submit Fighter 2 stats
      await _orchestrationService.updateFighterStat(
        widget.eventId,
        widget.sessionId,
        widget.fightId,
        2,
        'strikesLanded',
        _f2Strikes,
      );
      await _orchestrationService.updateFighterStat(
        widget.eventId,
        widget.sessionId,
        widget.fightId,
        2,
        'strikeAttempts',
        _f2StrikeAttempts,
      );
      await _orchestrationService.updateFighterStat(
        widget.eventId,
        widget.sessionId,
        widget.fightId,
        2,
        'takedownsLanded',
        _f2Takedowns,
      );
      await _orchestrationService.updateFighterStat(
        widget.eventId,
        widget.sessionId,
        widget.fightId,
        2,
        'takedownAttempts',
        _f2TakedownAttempts,
      );
      await _orchestrationService.updateFighterStat(
        widget.eventId,
        widget.sessionId,
        widget.fightId,
        2,
        'controlTimeSeconds',
        _f2ControlSeconds,
      );
      await _orchestrationService.updateFighterStat(
        widget.eventId,
        widget.sessionId,
        widget.fightId,
        2,
        'knockdowns',
        _f2Knockdowns,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All stats submitted!'),
            backgroundColor: DesignTokens.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: DesignTokens.neonRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _orchestrationService.removeListener(_onUpdate);
    _orchestrationService.dispose();
    super.dispose();
  }
}
