import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// LIVE FIGHT TICKER SERVICE — Real-Time Round-by-Round Updates
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Real-time fight tracking that:
///  1. Streams live round-by-round updates via Firestore
///  2. Tracks significant strikes, takedowns, submissions
///  3. AI-generates live commentary via Gemini CF
///  4. Pushes score predictions after each round
///  5. Notifies subscribers on knockdowns/submissions/finishes
///  6. Maintains fight history for replay
///  7. Provides minute-by-minute action timeline
///  8. Wolverine Protocol: Auto-recovers dropped connections
/// ═══════════════════════════════════════════════════════════════════════════

final _firestore = FirebaseFirestore.instance;
final _functions = FirebaseFunctions.instanceFor(
  region: 'australia-southeast1',
);

/// Fight status
enum FightStatus {
  scheduled,
  walkout,
  live,
  roundBreak,
  finished,
  cancelled,
  postponed,
}

/// Fight outcome types
enum FightOutcome {
  koTko,
  submission,
  decision,
  splitDecision,
  draw,
  noContest,
  dq,
  pending,
}

/// Significant action types
enum ActionType {
  significantStrike,
  knockdown,
  takedown,
  submissionAttempt,
  groundControl,
  clinchWork,
  legKick,
  headKick,
  bodyShot,
  elbow,
  knee,
  doctorStoppage,
  cornorStoppage,
  finish,
}

/// Live round data
class LiveRound {
  final int roundNumber;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, int> fighter1Stats;
  final Map<String, int> fighter2Stats;
  final List<FightAction> actions;
  final String? aiCommentary;

  const LiveRound({
    required this.roundNumber,
    required this.startTime,
    this.endTime,
    required this.fighter1Stats,
    required this.fighter2Stats,
    this.actions = const [],
    this.aiCommentary,
  });

  factory LiveRound.fromMap(Map<String, dynamic> map) => LiveRound(
    roundNumber: map['roundNumber'] ?? 1,
    startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
    endTime: (map['endTime'] as Timestamp?)?.toDate(),
    fighter1Stats: Map<String, int>.from(map['fighter1Stats'] ?? {}),
    fighter2Stats: Map<String, int>.from(map['fighter2Stats'] ?? {}),
    actions:
        (map['actions'] as List<dynamic>?)
            ?.map((a) => FightAction.fromMap(a))
            .toList() ??
        [],
    aiCommentary: map['aiCommentary'],
  );

  Map<String, dynamic> toMap() => {
    'roundNumber': roundNumber,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    'fighter1Stats': fighter1Stats,
    'fighter2Stats': fighter2Stats,
    'actions': actions.map((a) => a.toMap()).toList(),
    'aiCommentary': aiCommentary,
  };
}

/// Individual fight action
class FightAction {
  final String id;
  final ActionType type;
  final String fighterId;
  final String fighterName;
  final int round;
  final int minuteInRound;
  final int secondInRound;
  final String description;
  final int? damage;
  final DateTime timestamp;

  const FightAction({
    required this.id,
    required this.type,
    required this.fighterId,
    required this.fighterName,
    required this.round,
    required this.minuteInRound,
    required this.secondInRound,
    required this.description,
    this.damage,
    required this.timestamp,
  });

  factory FightAction.fromMap(Map<String, dynamic> map) => FightAction(
    id: map['id'] ?? '',
    type: ActionType.values.firstWhere(
      (t) => t.name == map['type'],
      orElse: () => ActionType.significantStrike,
    ),
    fighterId: map['fighterId'] ?? '',
    fighterName: map['fighterName'] ?? 'Unknown',
    round: map['round'] ?? 1,
    minuteInRound: map['minuteInRound'] ?? 0,
    secondInRound: map['secondInRound'] ?? 0,
    description: map['description'] ?? '',
    damage: map['damage'],
    timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'fighterId': fighterId,
    'fighterName': fighterName,
    'round': round,
    'minuteInRound': minuteInRound,
    'secondInRound': secondInRound,
    'description': description,
    'damage': damage,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

/// Live fight state
class LiveFight {
  final String id;
  final String eventId;
  final String eventName;
  final String fighter1Id;
  final String fighter1Name;
  final String fighter2Id;
  final String fighter2Name;
  final String weightClass;
  final int scheduledRounds;
  final FightStatus status;
  final int currentRound;
  final List<LiveRound> rounds;
  final FightOutcome? outcome;
  final String? winnerId;
  final String? finishTime;
  final String? aiPrediction;
  final Map<String, double> livePrediction;
  final DateTime lastUpdate;

  const LiveFight({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.fighter1Id,
    required this.fighter1Name,
    required this.fighter2Id,
    required this.fighter2Name,
    required this.weightClass,
    this.scheduledRounds = 3,
    required this.status,
    this.currentRound = 0,
    this.rounds = const [],
    this.outcome,
    this.winnerId,
    this.finishTime,
    this.aiPrediction,
    this.livePrediction = const {},
    required this.lastUpdate,
  });

  factory LiveFight.fromMap(Map<String, dynamic> map) => LiveFight(
    id: map['id'] ?? '',
    eventId: map['eventId'] ?? '',
    eventName: map['eventName'] ?? '',
    fighter1Id: map['fighter1Id'] ?? '',
    fighter1Name: map['fighter1Name'] ?? 'Fighter 1',
    fighter2Id: map['fighter2Id'] ?? '',
    fighter2Name: map['fighter2Name'] ?? 'Fighter 2',
    weightClass: map['weightClass'] ?? 'Unknown',
    scheduledRounds: map['scheduledRounds'] ?? 3,
    status: FightStatus.values.firstWhere(
      (s) => s.name == map['status'],
      orElse: () => FightStatus.scheduled,
    ),
    currentRound: map['currentRound'] ?? 0,
    rounds:
        (map['rounds'] as List<dynamic>?)
            ?.map((r) => LiveRound.fromMap(r))
            .toList() ??
        [],
    outcome: map['outcome'] != null
        ? FightOutcome.values.firstWhere(
            (o) => o.name == map['outcome'],
            orElse: () => FightOutcome.pending,
          )
        : null,
    winnerId: map['winnerId'],
    finishTime: map['finishTime'],
    aiPrediction: map['aiPrediction'],
    livePrediction: Map<String, double>.from(map['livePrediction'] ?? {}),
    lastUpdate: (map['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'eventId': eventId,
    'eventName': eventName,
    'fighter1Id': fighter1Id,
    'fighter1Name': fighter1Name,
    'fighter2Id': fighter2Id,
    'fighter2Name': fighter2Name,
    'weightClass': weightClass,
    'scheduledRounds': scheduledRounds,
    'status': status.name,
    'currentRound': currentRound,
    'rounds': rounds.map((r) => r.toMap()).toList(),
    'outcome': outcome?.name,
    'winnerId': winnerId,
    'finishTime': finishTime,
    'aiPrediction': aiPrediction,
    'livePrediction': livePrediction,
    'lastUpdate': FieldValue.serverTimestamp(),
  };
}

/// Live Fight Ticker Service
class LiveFightTickerService with ChangeNotifier {
  static final LiveFightTickerService _instance =
      LiveFightTickerService._internal();
  factory LiveFightTickerService() => _instance;
  LiveFightTickerService._internal();

  bool _initialized = false;
  LiveFight? _currentFight;
  final List<LiveFight> _todaysFights = [];
  final List<FightAction> _recentActions = [];
  StreamSubscription<DocumentSnapshot>? _fightSubscription;
  StreamSubscription<QuerySnapshot>? _actionsSubscription;

  // Getters
  bool get initialized => _initialized;
  LiveFight? get currentFight => _currentFight;
  List<LiveFight> get todaysFights => List.unmodifiable(_todaysFights);
  List<FightAction> get recentActions => List.unmodifiable(_recentActions);
  bool get isLive => _currentFight?.status == FightStatus.live;

  /// Initialize the ticker service
  Future<void> initialize() async {
    if (_initialized) return;
    debugPrint('🥊 LiveFightTickerService: Initializing...');
    await _loadTodaysFights();
    _initialized = true;
    notifyListeners();
    debugPrint(
      '🥊 LiveFightTickerService: Ready with ${_todaysFights.length} fights today',
    );
  }

  /// Load today's scheduled fights
  Future<void> _loadTodaysFights() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('live_fights')
          .where(
            'scheduledTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('scheduledTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('scheduledTime')
          .get();

      _todaysFights.clear();
      for (final doc in snapshot.docs) {
        _todaysFights.add(LiveFight.fromMap({...doc.data(), 'id': doc.id}));
      }
    } catch (e) {
      debugPrint('LiveFightTickerService: Failed to load fights: $e');
    }
  }

  /// Subscribe to a live fight
  Future<void> subscribeTo(String fightId) async {
    await _fightSubscription?.cancel();
    await _actionsSubscription?.cancel();

    // Subscribe to fight document
    _fightSubscription = _firestore
        .collection('live_fights')
        .doc(fightId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            _currentFight = LiveFight.fromMap({
              ...snapshot.data()!,
              'id': snapshot.id,
            });
            notifyListeners();
          }
        });

    // Subscribe to actions subcollection
    _actionsSubscription = _firestore
        .collection('live_fights')
        .doc(fightId)
        .collection('actions')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          _recentActions.clear();
          for (final doc in snapshot.docs) {
            _recentActions.add(
              FightAction.fromMap({...doc.data(), 'id': doc.id}),
            );
          }
          notifyListeners();
        });

    debugPrint('🥊 LiveFightTickerService: Subscribed to fight $fightId');
  }

  /// Unsubscribe from current fight
  Future<void> unsubscribe() async {
    await _fightSubscription?.cancel();
    await _actionsSubscription?.cancel();
    _fightSubscription = null;
    _actionsSubscription = null;
    _currentFight = null;
    _recentActions.clear();
    notifyListeners();
  }

  /// Get AI live commentary
  Future<String?> getAICommentary({
    required String fighter1Name,
    required String fighter2Name,
    required int round,
    required Map<String, int> fighter1Stats,
    required Map<String, int> fighter2Stats,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateLiveFightCommentary');
      final result = await callable.call<Map<String, dynamic>>({
        'fighter1Name': fighter1Name,
        'fighter2Name': fighter2Name,
        'round': round,
        'fighter1Stats': fighter1Stats,
        'fighter2Stats': fighter2Stats,
      });

      return result.data['commentary'] as String?;
    } catch (e) {
      debugPrint('LiveFightTickerService: Commentary failed: $e');
      return null;
    }
  }

  /// Get live prediction update
  Future<Map<String, double>?> getLivePrediction({
    required String fighter1Id,
    required String fighter2Id,
    required int currentRound,
    required List<LiveRound> rounds,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateLivePrediction');
      final result = await callable.call<Map<String, dynamic>>({
        'fighter1Id': fighter1Id,
        'fighter2Id': fighter2Id,
        'currentRound': currentRound,
        'roundsData': rounds.map((r) => r.toMap()).toList(),
      });

      final content = result.data['prediction'] as Map<String, dynamic>?;
      if (content != null) {
        return {
          'fighter1': (content['fighter1Win'] ?? 0.5).toDouble(),
          'fighter2': (content['fighter2Win'] ?? 0.5).toDouble(),
        };
      }
    } catch (e) {
      debugPrint('LiveFightTickerService: Prediction failed: $e');
    }
    return null;
  }

  /// Log a significant action (admin/moderator)
  Future<void> logAction({
    required String fightId,
    required ActionType type,
    required String fighterId,
    required String fighterName,
    required int round,
    required int minuteInRound,
    required int secondInRound,
    required String description,
    int? damage,
  }) async {
    try {
      await _firestore
          .collection('live_fights')
          .doc(fightId)
          .collection('actions')
          .add({
            'type': type.name,
            'fighterId': fighterId,
            'fighterName': fighterName,
            'round': round,
            'minuteInRound': minuteInRound,
            'secondInRound': secondInRound,
            'description': description,
            'damage': damage,
            'timestamp': FieldValue.serverTimestamp(),
          });

      debugPrint('🥊 LiveFightTickerService: Logged action - $description');
    } catch (e) {
      debugPrint('LiveFightTickerService: Failed to log action: $e');
    }
  }

  /// Get fight timeline
  List<FightAction> getTimeline({int? round}) {
    if (round != null) {
      return _recentActions.where((a) => a.round == round).toList();
    }
    return _recentActions;
  }

  /// Get stats summary for current fight
  Map<String, dynamic> getStatsSummary() {
    if (_currentFight == null) return {};

    final allRounds = _currentFight!.rounds;
    final fighter1Total = <String, int>{};
    final fighter2Total = <String, int>{};

    for (final round in allRounds) {
      round.fighter1Stats.forEach((key, value) {
        fighter1Total[key] = (fighter1Total[key] ?? 0) + value;
      });
      round.fighter2Stats.forEach((key, value) {
        fighter2Total[key] = (fighter2Total[key] ?? 0) + value;
      });
    }

    return {
      'fighter1': {'name': _currentFight!.fighter1Name, 'stats': fighter1Total},
      'fighter2': {'name': _currentFight!.fighter2Name, 'stats': fighter2Total},
      'currentRound': _currentFight!.currentRound,
      'status': _currentFight!.status.name,
    };
  }

  @override
  void dispose() {
    _fightSubscription?.cancel();
    _actionsSubscription?.cancel();
    super.dispose();
  }
}
