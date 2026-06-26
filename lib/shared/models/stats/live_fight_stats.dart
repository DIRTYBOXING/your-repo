import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Real-time fight statistics streamed from Genius Sports via
/// the `syncGeniusStats` Cloud Function → Firestore `live_stats/{eventId}`.
class LiveFightStats extends Equatable {
  final String eventId;
  final CornerStats redCorner;
  final CornerStats blueCorner;
  final int round;
  final int clockSeconds;
  final String matchStatus;
  final DateTime? lastUpdated;

  const LiveFightStats({
    required this.eventId,
    required this.redCorner,
    required this.blueCorner,
    this.round = 0,
    this.clockSeconds = 0,
    this.matchStatus = 'live',
    this.lastUpdated,
  });

  factory LiveFightStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LiveFightStats(
      eventId: data['eventId'] as String? ?? doc.id,
      redCorner: CornerStats.fromMap(
        data['redCorner'] as Map<String, dynamic>? ?? {},
      ),
      blueCorner: CornerStats.fromMap(
        data['blueCorner'] as Map<String, dynamic>? ?? {},
      ),
      round: data['round'] as int? ?? 0,
      clockSeconds: data['clockSeconds'] as int? ?? 0,
      matchStatus: data['matchStatus'] as String? ?? 'live',
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  /// Clock formatted as MM:SS
  String get clockDisplay {
    final m = clockSeconds ~/ 60;
    final s = clockSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get isLive => matchStatus == 'live';

  @override
  List<Object?> get props => [
    eventId,
    redCorner,
    blueCorner,
    round,
    clockSeconds,
    matchStatus,
    lastUpdated,
  ];
}

class CornerStats extends Equatable {
  final String name;
  final int strikes;
  final int takedowns;
  final double? liveOdds;

  const CornerStats({
    required this.name,
    this.strikes = 0,
    this.takedowns = 0,
    this.liveOdds,
  });

  factory CornerStats.fromMap(Map<String, dynamic> map) {
    return CornerStats(
      name: map['name'] as String? ?? 'Unknown',
      strikes: map['strikes'] as int? ?? 0,
      takedowns: map['takedowns'] as int? ?? 0,
      liveOdds: (map['liveOdds'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [name, strikes, takedowns, liveOdds];
}
