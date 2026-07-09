import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/event_session_model.dart';
import '../../ppv/models/fight_stats_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EVENT ORCHESTRATION SERVICE — Production Backend
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Authoritative control room for live events:
///   - Manage event sessions
///   - Start/advance/pause/end fights
///   - Record scores, knockdowns, submissions
///   - Update live stats (feeds Tier 3)
///   - Timeline management
///   - Multi-fight coordination
///
/// Data Flow:
///   Production Staff (Promoter/Referee)
///   ↓
///   EventOrchestrationService
///   ↓
///   Firestore (authoritative source)
///   ↓
///   LiveFightStatsService (Tier 3 listener)
///   ↓
///   PPVWatchScreen HUD/Overlays
///
/// ═══════════════════════════════════════════════════════════════════════════

class EventOrchestrationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Current Session State ──
  EventSession? _currentSession;
  FightSession? _currentFight;

  // ── Getters ──
  EventSession? get currentSession => _currentSession;
  FightSession? get currentFight => _currentFight;
  bool get isEventLive => _currentSession?.isLive ?? false;
  bool get isFightActive => _currentFight?.status == FightStatus.live;

  /// Initialize or load an event session
  Future<void> initializeSession(String eventId, String sessionId) async {
    try {
      final sessionDoc = await _firestore
          .doc('ppv_events/$eventId/event_sessions/$sessionId')
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Session $sessionId not found');
      }

      _currentSession = EventSession.fromFirestore(
        sessionDoc.data() as Map<String, dynamic>,
      );
      notifyListeners();

      debugPrint(
        '✅ [ORCHESTRATION] Initialized session: ${_currentSession?.name}',
      );
    } catch (e) {
      debugPrint('❌ [ORCHESTRATION] Error initializing session: $e');
      rethrow;
    }
  }

  /// Start a new fight session
  Future<void> startFight(
    String eventId,
    String sessionId,
    String fightId,
    String fighter1Id,
    String fighter2Id,
    String fighter1Name,
    String fighter2Name,
  ) async {
    try {
      final fightSession = FightSession(
        id: fightId,
        fighter1Id: fighter1Id,
        fighter2Id: fighter2Id,
        fighter1Name: fighter1Name,
        fighter2Name: fighter2Name,
        currentRound: 1,
        status: FightStatus.live,
        roundTimeRemaining: 300,
        roundDuration: 300,
        isRoundActive: true,
        startedAt: DateTime.now(),
      );

      // Write fight metadata
      await _firestore
          .doc(
            'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/metadata',
          )
          .set(fightSession.toFirestore());

      // Initialize fighter stats documents
      await _firestore
          .doc(
            'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/fighter_stats/fighter_1',
          )
          .set(FighterStats.initial().toFirestore());

      await _firestore
          .doc(
            'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/fighter_stats/fighter_2',
          )
          .set(FighterStats.initial().toFirestore());

      // Record event
      await _recordFightEvent(
        eventId,
        sessionId,
        fightId,
        FightEvent(
          type: EventType.roundStart,
          round: 1,
          timeInRound: 0,
          description: 'Fight started: $fighter1Name vs $fighter2Name',
          timestamp: DateTime.now(),
        ),
      );

      _currentFight = fightSession;
      _currentSession = _currentSession?.copyWith(activeFightId: fightId);
      notifyListeners();

      debugPrint(
        '🔴 [ORCHESTRATION] Fight started: $fighter1Name vs $fighter2Name',
      );
    } catch (e) {
      debugPrint('❌ [ORCHESTRATION] Error starting fight: $e');
      rethrow;
    }
  }

  /// Advance to next round
  Future<void> advanceRound(
    String eventId,
    String sessionId,
    String fightId,
  ) async {
    if (_currentFight == null) return;

    try {
      final nextRound = _currentFight!.currentRound + 1;

      final updatedFight = _currentFight!.copyWith(
        currentRound: nextRound,
        roundTimeRemaining: _currentFight!.roundDuration,
        isRoundActive: true,
      );

      await _firestore
          .doc(
            'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/metadata',
          )
          .update(updatedFight.toFirestore());

      // Record round start event
      await _recordFightEvent(
        eventId,
        sessionId,
        fightId,
        FightEvent(
          type: EventType.roundStart,
          round: nextRound,
          timeInRound: 0,
          description: 'Round $nextRound started',
          timestamp: DateTime.now(),
        ),
      );

      _currentFight = updatedFight;
      notifyListeners();

      debugPrint('⏭️ [ORCHESTRATION] Advanced to Round $nextRound');
    } catch (e) {
      debugPrint('❌ [ORCHESTRATION] Error advancing round: $e');
      rethrow;
    }
  }

  /// Record knockdown event
  Future<void> recordKnockdown(
    String eventId,
    String sessionId,
    String fightId,
    int fighterIndex, // 1 or 2
    int timeInRound,
  ) async {
    if (_currentFight == null) return;

    try {
      final fighterName = fighterIndex == 1
          ? _currentFight!.fighter1Name
          : _currentFight!.fighter2Name;

      await _recordFightEvent(
        eventId,
        sessionId,
        fightId,
        FightEvent(
          type: EventType.knockdown,
          round: _currentFight!.currentRound,
          timeInRound: timeInRound,
          fighterIndex: fighterIndex,
          description: 'Knockdown: $fighterName',
          timestamp: DateTime.now(),
        ),
      );

      debugPrint(
        '💥 [ORCHESTRATION] Knockdown recorded: $fighterName @ R${_currentFight!.currentRound}:${timeInRound}s',
      );
    } catch (e) {
      debugPrint('❌ [ORCHESTRATION] Error recording knockdown: $e');
      rethrow;
    }
  }

  /// Record submission event
  Future<void> recordSubmission(
    String eventId,
    String sessionId,
    String fightId,
    int submittingFighterIndex, // 1 or 2
    String submissionType,
    int timeInRound,
  ) async {
    if (_currentFight == null) return;

    try {
      final winner = submittingFighterIndex;
      final winnerName = winner == 1
          ? _currentFight!.fighter1Name
          : _currentFight!.fighter2Name;

      // Record submission event
      await _recordFightEvent(
        eventId,
        sessionId,
        fightId,
        FightEvent(
          type: EventType.submission,
          round: _currentFight!.currentRound,
          timeInRound: timeInRound,
          fighterIndex: submittingFighterIndex,
          description: '$winnerName wins via $submissionType submission',
          timestamp: DateTime.now(),
        ),
      );

      // End fight
      await endFight(
        eventId,
        sessionId,
        fightId,
        winner: winner,
        method: 'Submission - $submissionType',
      );

      debugPrint(
        '🔐 [ORCHESTRATION] Submission: $winnerName via $submissionType @ R${_currentFight!.currentRound}:${timeInRound}s',
      );
    } catch (e) {
      debugPrint('❌ [ORCHESTRATION] Error recording submission: $e');
      rethrow;
    }
  }

  /// Record round scores (10-point must system)
  Future<void> recordRoundScores(
    String eventId,
    String sessionId,
    String fightId,
    int fighter1Score, // 10, 9, 8, 7
    int fighter2Score,
  ) async {
    try {
      await _firestore
          .doc(
            'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/scores/round_${_currentFight?.currentRound ?? 1}',
          )
          .set({
            'fighter1Score': fighter1Score,
            'fighter2Score': fighter2Score,
            'round': _currentFight?.currentRound ?? 1,
            'recordedAt': FieldValue.serverTimestamp(),
          });

      // Update fighter stats with new score
      if (_currentFight != null) {
        final fighter1StatsRef = _firestore.doc(
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/fighter_stats/fighter_1',
        );
        final fighter2StatsRef = _firestore.doc(
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/fighter_stats/fighter_2',
        );

        // Read current stats
        final f1Snapshot = await fighter1StatsRef.get();
        final f2Snapshot = await fighter2StatsRef.get();

        if (f1Snapshot.exists && f2Snapshot.exists) {
          final f1 = FighterStats.fromFirestore(
            f1Snapshot.data() as Map<String, dynamic>,
          );
          final f2 = FighterStats.fromFirestore(
            f2Snapshot.data() as Map<String, dynamic>,
          );

          // Add score to scoresPerRound
          final f1NewScores = [...f1.scoresPerRound, fighter1Score];
          final f2NewScores = [...f2.scoresPerRound, fighter2Score];

          await fighter1StatsRef.update({
            'scoresPerRound': f1NewScores,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          await fighter2StatsRef.update({
            'scoresPerRound': f2NewScores,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }

      debugPrint(
        '📋 [ORCHESTRATION] Round scores recorded: R${_currentFight?.currentRound ?? 1} → $fighter1Score-$fighter2Score',
      );
    } catch (e) {
      debugPrint('❌ [ORCHESTRATION] Error recording scores: $e');
      rethrow;
    }
  }

  /// Record live stat update (strikes, takedowns, control)
  Future<void> updateFighterStat(
    String eventId,
    String sessionId,
    String fightId,
    int fighterIndex, // 1 or 2
    String statField, // 'strikesLanded', 'strikeAttempts', etc.
    int value,
  ) async {
    try {
      final fighterKey = 'fighter_$fighterIndex';
      final statsRef = _firestore.doc(
        'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/fighter_stats/$fighterKey',
      );

      await statsRef.update({
        statField: value,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      debugPrint(
        '📊 [ORCHESTRATION] Updated Fighter $fighterIndex: $statField = $value',
      );
    } catch (e) {
      debugPrint('❌ [ORCHESTRATION] Error updating fighter stat: $e');
      rethrow;
    }
  }

  /// End fight with decision
  Future<void> endFight(
    String eventId,
    String sessionId,
    String fightId, {
    required int winner, // 1, 2, or 0 (draw)
    required String method,
  }) async {
    if (_currentFight == null) return;

    try {
      final endedFight = _currentFight!.copyWith(
        status: FightStatus.completed,
        decisionWinner: winner,
        decisionMethod: method,
        decisionRound: _currentFight!.currentRound,
        isRoundActive: false,
        endedAt: DateTime.now(),
      );

      await _firestore
          .doc(
            'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/metadata',
          )
          .update(endedFight.toFirestore());

      // Record decision event
      final winnerName = winner == 1
          ? _currentFight!.fighter1Name
          : winner == 2
          ? _currentFight!.fighter2Name
          : 'Draw';

      await _recordFightEvent(
        eventId,
        sessionId,
        fightId,
        FightEvent(
          type: EventType.decision,
          round: _currentFight!.currentRound,
          timeInRound: 0,
          fighterIndex: winner == 0 ? null : winner,
          description: 'Fight ended: $winnerName wins via $method',
          timestamp: DateTime.now(),
        ),
      );

      _currentFight = null;
      _currentSession = _currentSession?.copyWith(activeFightId: null);
      notifyListeners();

      debugPrint(
        '🏁 [ORCHESTRATION] Fight ended: $winnerName wins via $method',
      );
    } catch (e) {
      debugPrint('❌ [ORCHESTRATION] Error ending fight: $e');
      rethrow;
    }
  }

  /// Internal: Record event to timeline
  Future<void> _recordFightEvent(
    String eventId,
    String sessionId,
    String fightId,
    FightEvent event,
  ) async {
    try {
      await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('fight_sessions')
          .doc(fightId)
          .collection('events')
          .add(event.toFirestore());
    } catch (e) {
      debugPrint('❌ [ORCHESTRATION] Error recording event: $e');
    }
  }

  /// Clean up
  @override
  void dispose() {
    _currentSession = null;
    _currentFight = null;
    super.dispose();
  }
}
