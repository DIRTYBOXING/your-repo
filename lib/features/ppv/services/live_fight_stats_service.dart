import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/fight_stats_model.dart';
import '../../../shared/models/ppv_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// LIVE FIGHT STATS SERVICE — Real-time Combat Metrics
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Firestore listener that streams live fight statistics:
///   - Per-fighter stats (strikes, takedowns, control, knockdowns)
///   - Round transitions
///   - Scorecards
///   - Fight completion
///
/// Designed for:
///   - HUD real-time display
///   - Stats overlay updates
///   - Round timer sync
///   - Analytics/trending
///
/// Firestore Collection Structure:
///   ppv_events/{eventId}/fight_sessions/{sessionId}/fighter_stats/{fighterId}
///   ├─ strikesLanded (int)
///   ├─ strikeAttempts (int)
///   ├─ takedownsLanded (int)
///   ├─ takedownAttempts (int)
///   ├─ controlTimeSeconds (int)
///   ├─ knockdowns (int)
///   ├─ scoresPerRound (array<int>)
///   ├─ lastUpdated (timestamp)
///   └─ ... (see FighterStats.toFirestore())
///
/// ═══════════════════════════════════════════════════════════════════════════

class LiveFightStatsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Current Fight State ──
  String? _eventId;
  String? _sessionId;
  int _currentRound = 1;
  bool _isFightActive = false;
  FighterStats? _fighter1Stats;
  FighterStats? _fighter2Stats;
  FightScorecard? _scorecard;

  // ── Stream Subscriptions ──
  StreamSubscription<DocumentSnapshot>? _fighter1Subscription;
  StreamSubscription<DocumentSnapshot>? _fighter2Subscription;
  StreamSubscription<DocumentSnapshot>? _roundMetadataSubscription;

  // ── Getters ──
  int get currentRound => _currentRound;
  bool get isFightActive => _isFightActive;
  FighterStats? get fighter1Stats => _fighter1Stats;
  FighterStats? get fighter2Stats => _fighter2Stats;
  FightScorecard? get scorecard => _scorecard;

  /// Initialize live stats listener for a specific fight session
  Future<void> initializeFightStats(String eventId, String sessionId) async {
    try {
      _eventId = eventId;
      _sessionId = sessionId;
      _isFightActive = true;

      // Check if Firestore paths exist
      final fightPath = 'ppv_events/$eventId/fight_sessions/$sessionId';

      // ── Listen to Fighter 1 Stats ──
      _fighter1Subscription = _firestore
          .doc('$fightPath/fighter_stats/fighter_1')
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists) {
              _fighter1Stats = FighterStats.fromFirestore(
                snapshot.data() as Map<String, dynamic>,
              );
              notifyListeners();
              _onStatsUpdated('fighter1', _fighter1Stats!);
            }
          });

      // ── Listen to Fighter 2 Stats ──
      _fighter2Subscription = _firestore
          .doc('$fightPath/fighter_stats/fighter_2')
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists) {
              _fighter2Stats = FighterStats.fromFirestore(
                snapshot.data() as Map<String, dynamic>,
              );
              notifyListeners();
              _onStatsUpdated('fighter2', _fighter2Stats!);
            }
          });

      // ── Listen to Round Metadata ──
      _roundMetadataSubscription = _firestore
          .doc('$fightPath/metadata')
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data() as Map<String, dynamic>;
              final newRound = data['currentRound'] as int? ?? 1;

              if (newRound != _currentRound) {
                _currentRound = newRound;
                _onRoundTransition(newRound);
                debugPrint('🔄 [LIVE STATS] Round transition: R$_currentRound');
              }

              _isFightActive = data['isActive'] as bool? ?? true;
              notifyListeners();
            }
          });

      debugPrint(
        '✅ [LIVE STATS] Initialized for event=$eventId, session=$sessionId',
      );
    } catch (e) {
      debugPrint('❌ [LIVE STATS] Error initializing: $e');
      _isFightActive = false;
    }
  }

  /// Update fighter stats directly (for seeding/demo)
  Future<void> updateFighterStats(String fighterId, FighterStats stats) async {
    if (_eventId == null || _sessionId == null) return;

    try {
      final fightPath =
          'ppv_events/$_eventId/fight_sessions/$_sessionId/fighter_stats/$fighterId';

      await _firestore.doc(fightPath).set(stats.toFirestore());

      debugPrint(
        '📝 [LIVE STATS] Updated $fighterId\n'
        '  ├─ Strikes: ${stats.strikesLanded}/${stats.strikeAttempts}\n'
        '  ├─ Takedowns: ${stats.takedownsLanded}/${stats.takedownAttempts}\n'
        '  └─ Control: ${stats.formattedControlTime}',
      );
    } catch (e) {
      debugPrint('❌ [LIVE STATS] Error updating $fighterId: $e');
    }
  }

  /// Advance to next round
  Future<void> advanceRound() async {
    if (_eventId == null || _sessionId == null) return;

    try {
      final metadataPath =
          'ppv_events/$_eventId/fight_sessions/$_sessionId/metadata';
      await _firestore.doc(metadataPath).update({
        'currentRound': _currentRound + 1,
      });

      debugPrint('⏭️ [LIVE STATS] Advanced to Round ${_currentRound + 1}');
    } catch (e) {
      debugPrint('❌ [LIVE STATS] Error advancing round: $e');
    }
  }

  /// End fight
  Future<void> endFight({
    required int winner, // 1 or 2
    required String method,
  }) async {
    if (_eventId == null || _sessionId == null) return;

    try {
      final metadataPath =
          'ppv_events/$_eventId/fight_sessions/$_sessionId/metadata';
      await _firestore.doc(metadataPath).update({
        'isActive': false,
        'winner': winner,
        'method': method,
        'endedAt': FieldValue.serverTimestamp(),
      });

      _isFightActive = false;
      notifyListeners();

      debugPrint(
        '🏁 [LIVE STATS] Fight ended: Fighter $winner wins via $method',
      );
    } catch (e) {
      debugPrint('❌ [LIVE STATS] Error ending fight: $e');
    }
  }

  /// Get stream of Fighter 1 stats (for reactive UI)
  Stream<FighterStats?> get fighter1StatsStream =>
      _fighter1Subscription?.asFuture().asStream() ?? Stream.value(null);

  /// Get stream of Fighter 2 stats (for reactive UI)
  Stream<FighterStats?> get fighter2StatsStream =>
      _fighter2Subscription?.asFuture().asStream() ?? Stream.value(null);

  /// Internal: Called when stats update
  void _onStatsUpdated(String fighter, FighterStats stats) {
    debugPrint(
      '📊 [LIVE STATS] Updated $fighter stats\n'
      '  ├─ Strikes: ${stats.strikesLanded}/${stats.strikeAttempts} (${stats.strikeAccuracy.toStringAsFixed(1)}%)\n'
      '  ├─ Takedowns: ${stats.takedownsLanded}/${stats.takedownAttempts} (${stats.takedownAccuracy.toStringAsFixed(1)}%)\n'
      '  ├─ Control: ${stats.formattedControlTime}\n'
      '  ├─ Knockdowns: ${stats.knockdowns}\n'
      '  └─ Sig. Strikes: ${stats.significantStrikesLanded}',
    );
  }

  /// Internal: Called when round transitions
  void _onRoundTransition(int newRound) {
    debugPrint('🔔 [LIVE STATS] ROUND $newRound START');
  }

  /// Clean up subscriptions
  void dispose() {
    _fighter1Subscription?.cancel();
    _fighter2Subscription?.cancel();
    _roundMetadataSubscription?.cancel();
    _isFightActive = false;
    super.dispose();
  }
}
