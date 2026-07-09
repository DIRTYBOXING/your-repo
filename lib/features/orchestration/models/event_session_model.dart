import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EVENT SESSION MODEL — Live Event State
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Represents a live PPV event session:
///   - Multi-fight event orchestration
///   - Fight session state (active fight, round, timing)
///   - Timeline of all events (starts, knockdowns, subs, decisions)
///   - Production state (live, paused, ended)
///
/// Firestore Structure:
///   ppv_events/{eventId}/event_sessions/{sessionId}/
///   ├─ metadata (event/session info)
///   ├─ fight_sessions/{fightId}/
///   │  ├─ metadata (fight state)
///   │  ├─ fighter_stats/{fighterId} (live stats from Tier 3)
///   │  └─ events (timeline markers)
///   └─ timeline (all session events)
///
/// ═══════════════════════════════════════════════════════════════════════════

enum FightStatus { scheduled, live, paused, completed, cancelled }

enum EventType {
  roundStart,
  roundEnd,
  knockdown,
  submission,
  decision,
  pause,
  resume,
}

/// ── Event Session (Multi-fight Event) ──
class EventSession extends Equatable {
  /// Unique session ID (e.g., "live", "20260709_ufc_294")
  final String id;

  /// Parent PPV event ID
  final String eventId;

  /// Event name (e.g., "UFC 294: Adesanya vs. Pereira")
  final String name;

  /// Current active fight ID (null if no fight active)
  final String? activeFightId;

  /// All fights in this session
  final List<FightSession> fights;

  /// Session status
  final bool isLive;

  /// Created timestamp
  final DateTime createdAt;

  /// Last updated timestamp
  final DateTime lastUpdatedAt;

  /// Optional: Notes from production
  final String? notes;

  const EventSession({
    required this.id,
    required this.eventId,
    required this.name,
    this.activeFightId,
    this.fights = const [],
    this.isLive = false,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.notes,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'eventId': eventId,
      'name': name,
      'activeFightId': activeFightId,
      'isLive': isLive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'notes': notes,
    };
  }

  /// Create from Firestore document
  factory EventSession.fromFirestore(Map<String, dynamic> data) {
    return EventSession(
      id: data['id'] as String? ?? '',
      eventId: data['eventId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      activeFightId: data['activeFightId'] as String?,
      fights: const [], // Populated separately
      isLive: data['isLive'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt:
          (data['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'] as String?,
    );
  }

  /// Copy with updates
  EventSession copyWith({
    String? id,
    String? eventId,
    String? name,
    String? activeFightId,
    List<FightSession>? fights,
    bool? isLive,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    String? notes,
  }) {
    return EventSession(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      activeFightId: activeFightId ?? this.activeFightId,
      fights: fights ?? this.fights,
      isLive: isLive ?? this.isLive,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    eventId,
    name,
    activeFightId,
    fights,
    isLive,
    createdAt,
    lastUpdatedAt,
    notes,
  ];
}

/// ── Individual Fight Session ──
class FightSession extends Equatable {
  /// Unique fight ID within the event
  final String id;

  /// Fighter 1 ID
  final String fighter1Id;

  /// Fighter 2 ID
  final String fighter2Id;

  /// Fighter 1 name
  final String fighter1Name;

  /// Fighter 2 name
  final String fighter2Name;

  /// Current round
  final int currentRound;

  /// Fight status
  final FightStatus status;

  /// Round time remaining (seconds)
  final int roundTimeRemaining;

  /// Total round duration (seconds, typically 300 = 5 min)
  final int roundDuration;

  /// Is round currently active (timer running)
  final bool isRoundActive;

  /// Official decision (if fight completed)
  final int? decisionWinner; // 1, 2, or 0 (draw)

  /// Decision method (e.g., "Decision - Unanimous", "KO", "Submission")
  final String? decisionMethod;

  /// Round decision occurred in
  final int? decisionRound;

  /// All events in this fight (knockdowns, subs, etc.)
  final List<FightEvent> events;

  /// Session start time
  final DateTime startedAt;

  /// Session end time
  final DateTime? endedAt;

  /// Production notes
  final String? notes;

  const FightSession({
    required this.id,
    required this.fighter1Id,
    required this.fighter2Id,
    required this.fighter1Name,
    required this.fighter2Name,
    this.currentRound = 1,
    this.status = FightStatus.scheduled,
    this.roundTimeRemaining = 300,
    this.roundDuration = 300,
    this.isRoundActive = false,
    this.decisionWinner,
    this.decisionMethod,
    this.decisionRound,
    this.events = const [],
    required this.startedAt,
    this.endedAt,
    this.notes,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'fighter1Id': fighter1Id,
      'fighter2Id': fighter2Id,
      'fighter1Name': fighter1Name,
      'fighter2Name': fighter2Name,
      'currentRound': currentRound,
      'status': status.toString().split('.').last,
      'roundTimeRemaining': roundTimeRemaining,
      'roundDuration': roundDuration,
      'isRoundActive': isRoundActive,
      'decisionWinner': decisionWinner,
      'decisionMethod': decisionMethod,
      'decisionRound': decisionRound,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'notes': notes,
    };
  }

  /// Create from Firestore document
  factory FightSession.fromFirestore(Map<String, dynamic> data) {
    return FightSession(
      id: data['id'] as String? ?? '',
      fighter1Id: data['fighter1Id'] as String? ?? '',
      fighter2Id: data['fighter2Id'] as String? ?? '',
      fighter1Name: data['fighter1Name'] as String? ?? '',
      fighter2Name: data['fighter2Name'] as String? ?? '',
      currentRound: data['currentRound'] as int? ?? 1,
      status: _parseFightStatus(data['status'] as String?),
      roundTimeRemaining: data['roundTimeRemaining'] as int? ?? 300,
      roundDuration: data['roundDuration'] as int? ?? 300,
      isRoundActive: data['isRoundActive'] as bool? ?? false,
      decisionWinner: data['decisionWinner'] as int?,
      decisionMethod: data['decisionMethod'] as String?,
      decisionRound: data['decisionRound'] as int?,
      events: const [], // Populated separately
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String?,
    );
  }

  /// Copy with updates
  FightSession copyWith({
    String? id,
    String? fighter1Id,
    String? fighter2Id,
    String? fighter1Name,
    String? fighter2Name,
    int? currentRound,
    FightStatus? status,
    int? roundTimeRemaining,
    int? roundDuration,
    bool? isRoundActive,
    int? decisionWinner,
    String? decisionMethod,
    int? decisionRound,
    List<FightEvent>? events,
    DateTime? startedAt,
    DateTime? endedAt,
    String? notes,
  }) {
    return FightSession(
      id: id ?? this.id,
      fighter1Id: fighter1Id ?? this.fighter1Id,
      fighter2Id: fighter2Id ?? this.fighter2Id,
      fighter1Name: fighter1Name ?? this.fighter1Name,
      fighter2Name: fighter2Name ?? this.fighter2Name,
      currentRound: currentRound ?? this.currentRound,
      status: status ?? this.status,
      roundTimeRemaining: roundTimeRemaining ?? this.roundTimeRemaining,
      roundDuration: roundDuration ?? this.roundDuration,
      isRoundActive: isRoundActive ?? this.isRoundActive,
      decisionWinner: decisionWinner ?? this.decisionWinner,
      decisionMethod: decisionMethod ?? this.decisionMethod,
      decisionRound: decisionRound ?? this.decisionRound,
      events: events ?? this.events,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fighter1Id,
    fighter2Id,
    fighter1Name,
    fighter2Name,
    currentRound,
    status,
    roundTimeRemaining,
    roundDuration,
    isRoundActive,
    decisionWinner,
    decisionMethod,
    decisionRound,
    events,
    startedAt,
    endedAt,
    notes,
  ];
}

/// ── Fight Event (Timeline Marker) ──
class FightEvent extends Equatable {
  /// Event type
  final EventType type;

  /// Round number
  final int round;

  /// Time in round (seconds)
  final int timeInRound;

  /// Which fighter (1 or 2), if applicable
  final int? fighterIndex;

  /// Event description
  final String description;

  /// Timestamp
  final DateTime timestamp;

  const FightEvent({
    required this.type,
    required this.round,
    required this.timeInRound,
    this.fighterIndex,
    required this.description,
    required this.timestamp,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toString().split('.').last,
      'round': round,
      'timeInRound': timeInRound,
      'fighterIndex': fighterIndex,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Create from Firestore document
  factory FightEvent.fromFirestore(Map<String, dynamic> data) {
    return FightEvent(
      type: _parseEventType(data['type'] as String?),
      round: data['round'] as int? ?? 1,
      timeInRound: data['timeInRound'] as int? ?? 0,
      fighterIndex: data['fighterIndex'] as int?,
      description: data['description'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    type,
    round,
    timeInRound,
    fighterIndex,
    description,
    timestamp,
  ];
}

/// ── Helpers ──
FightStatus _parseFightStatus(String? status) {
  switch (status) {
    case 'live':
      return FightStatus.live;
    case 'paused':
      return FightStatus.paused;
    case 'completed':
      return FightStatus.completed;
    case 'cancelled':
      return FightStatus.cancelled;
    default:
      return FightStatus.scheduled;
  }
}

EventType _parseEventType(String? type) {
  switch (type) {
    case 'roundStart':
      return EventType.roundStart;
    case 'roundEnd':
      return EventType.roundEnd;
    case 'knockdown':
      return EventType.knockdown;
    case 'submission':
      return EventType.submission;
    case 'decision':
      return EventType.decision;
    case 'pause':
      return EventType.pause;
    case 'resume':
      return EventType.resume;
    default:
      return EventType.roundStart;
  }
}
