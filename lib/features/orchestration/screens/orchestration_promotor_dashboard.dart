import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/event_session_model.dart';
import '../services/event_orchestration_service.dart';
import '../widgets/round_control_panel.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ORCHESTRATION PROMOTER DASHBOARD — Production Booth
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Main control interface for promoters and production staff:
///   - Event management
///   - Fight session control
///   - Round advancement
///   - Status monitoring
///   - Multi-fight coordination
///
/// ═══════════════════════════════════════════════════════════════════════════

class OrchestrationPromotorDashboard extends StatefulWidget {
  /// Event ID
  final String eventId;

  /// Session ID
  final String sessionId;

  const OrchestrationPromotorDashboard({
    super.key,
    required this.eventId,
    required this.sessionId,
  });

  @override
  State<OrchestrationPromotorDashboard> createState() =>
      _OrchestrationPromotorDashboardState();
}

class _OrchestrationPromotorDashboardState
    extends State<OrchestrationPromotorDashboard> {
  late EventOrchestrationService _orchestrationService;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _orchestrationService = EventOrchestrationService();
    _orchestrationService.addListener(_onOrchestrationUpdate);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _orchestrationService.initializeSession(
        widget.eventId,
        widget.sessionId,
      );
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to load session: $e');
      }
    }
  }

  void _onOrchestrationUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Production Booth')),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Production Booth')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final session = _orchestrationService.currentSession;
    final fight = _orchestrationService.currentFight;

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgCard,
        title: Text(session?.name ?? 'Production Booth'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Session Status ──
              _buildSessionStatus(session),
              const SizedBox(height: 24),

              // ── Active Fight Control ──
              if (fight != null) ...[
                _buildFightControl(fight),
                const SizedBox(height: 24),
              ],

              // ── Round Control Panel ──
              if (fight != null) ...[
                RoundControlPanel(
                  fight: fight,
                  onAdvanceRound: () => _onAdvanceRound(fight),
                  onEndFight: () => _showEndFightDialog(fight),
                ),
                const SizedBox(height: 24),
              ],

              // ── Start Fight Button ──
              if (fight == null) ...[_buildStartFightForm()],

              // ── Fight Lineup ──
              if (session?.fights.isNotEmpty ?? false) ...[
                _buildFightLineup(session!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStatus(EventSession? session) {
    if (session == null) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        border: Border.all(
          color: session.isLive ? DesignTokens.neonRed : Colors.white24,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                session.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: session.isLive
                      ? DesignTokens.neonRed.withOpacity(0.2)
                      : Colors.white10,
                  border: Border.all(
                    color: session.isLive
                        ? DesignTokens.neonRed
                        : Colors.white30,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  session.isLive ? '🔴 LIVE' : '⚫ STANDBY',
                  style: TextStyle(
                    color: session.isLive
                        ? DesignTokens.neonRed
                        : Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Session ID: ${session.id}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (session.notes != null) ...[
            const SizedBox(height: 8),
            Text(
              'Notes: ${session.notes}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFightControl(FightSession fight) {
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
            'ACTIVE FIGHT',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fight.fighter1Name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fighter 1',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'ROUND ${fight.currentRound}',
                      style: TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fight.roundTimeRemaining}s',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fighter 2',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Status: ${fight.status.toString().split('.').last.toUpperCase()}',
            style: TextStyle(
              color: fight.status == FightStatus.live
                  ? DesignTokens.neonGreen
                  : Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartFightForm() {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        border: Border.all(
          color: DesignTokens.neonGreen.withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'START NEW FIGHT',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showStartFightDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '+ Start Fight',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFightLineup(EventSession session) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        border: Border.all(color: Colors.white12, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FIGHT LINEUP',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...session.fights.map((fight) {
            final isActive = session.activeFightId == fight.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isActive ? Colors.white10 : Colors.transparent,
                  border: Border.all(
                    color: isActive ? DesignTokens.neonCyan : Colors.white12,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${fight.fighter1Name} vs ${fight.fighter2Name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      fight.status.toString().split('.').last,
                      style: TextStyle(
                        color: isActive
                            ? DesignTokens.neonCyan
                            : Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showStartFightDialog() {
    final fighter1Controller = TextEditingController();
    final fighter2Controller = TextEditingController();
    final fight1IdController = TextEditingController();
    final fight2IdController = TextEditingController();
    final fightIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: const Text('Start New Fight'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fightIdController,
                decoration: const InputDecoration(labelText: 'Fight ID'),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: fight1IdController,
                decoration: const InputDecoration(labelText: 'Fighter 1 ID'),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: fighter1Controller,
                decoration: const InputDecoration(labelText: 'Fighter 1 Name'),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: fight2IdController,
                decoration: const InputDecoration(labelText: 'Fighter 2 ID'),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: fighter2Controller,
                decoration: const InputDecoration(labelText: 'Fighter 2 Name'),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _orchestrationService.startFight(
                widget.eventId,
                widget.sessionId,
                fightIdController.text,
                fight1IdController.text,
                fight2IdController.text,
                fighter1Controller.text,
                fighter2Controller.text,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Future<void> _onAdvanceRound(FightSession fight) async {
    await _orchestrationService.advanceRound(
      widget.eventId,
      widget.sessionId,
      fight.id,
    );
  }

  void _showEndFightDialog(FightSession fight) {
    final methodController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: const Text('End Fight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Winner:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _endFightWithWinner(fight, 1, methodController.text);
                    },
                    child: Text(fight.fighter1Name),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _endFightWithWinner(fight, 2, methodController.text);
                    },
                    child: Text(fight.fighter2Name),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: methodController,
              decoration: const InputDecoration(labelText: 'Decision Method'),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _endFightWithWinner(
    FightSession fight,
    int winner,
    String method,
  ) async {
    await _orchestrationService.endFight(
      widget.eventId,
      widget.sessionId,
      fight.id,
      winner: winner,
      method: method.isNotEmpty ? method : 'Decision',
    );
  }

  @override
  void dispose() {
    _orchestrationService.removeListener(_onOrchestrationUpdate);
    _orchestrationService.dispose();
    super.dispose();
  }
}
