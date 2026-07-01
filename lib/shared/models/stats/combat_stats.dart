import 'package:equatable/equatable.dart';

class CombatStats extends Equatable {
  final String fighterId;
  final Duration totalSparringTime;
  final int totalStrikesLanded;
  final int totalStrikesThrown;
  final int totalTakedowns;
  final int totalTakedownsAttempted;
  final double winRate; // Calculated or stored separately
  final int wins;
  final int losses;
  final int knockouts;
  final List<PerformanceDataPoint> performanceHistory;

  const CombatStats({
    required this.fighterId,
    this.totalSparringTime = Duration.zero,
    this.totalStrikesLanded = 0,
    this.totalStrikesThrown = 0,
    this.totalTakedowns = 0,
    this.totalTakedownsAttempted = 0,
    this.winRate = 0.0,
    this.wins = 0,
    this.losses = 0,
    this.knockouts = 0,
    this.performanceHistory = const [],
  });

  double get accuracy => totalStrikesThrown > 0
      ? (totalStrikesLanded / totalStrikesThrown) * 100
      : 0;

  double get takedownAccuracy => totalTakedownsAttempted > 0
      ? (totalTakedowns / totalTakedownsAttempted) * 100
      : 0;

  @override
  List<Object?> get props => [
    fighterId,
    totalSparringTime,
    totalStrikesLanded,
    totalStrikesThrown,
    totalTakedowns,
    totalTakedownsAttempted,
    winRate,
    wins,
    losses,
    knockouts,
    performanceHistory,
  ];

  static CombatStats fromMap(Map<String, dynamic> map) {
    return CombatStats(
      fighterId: map['fighterId'] ?? '',
      totalSparringTime: Duration(
        seconds: map['totalSparringTimeSeconds'] ?? 0,
      ),
      totalStrikesLanded: map['totalStrikesLanded'] ?? 0,
      totalStrikesThrown: map['totalStrikesThrown'] ?? 0,
      totalTakedowns: map['totalTakedowns'] ?? 0,
      totalTakedownsAttempted: map['totalTakedownsAttempted'] ?? 0,
      winRate: (map['winRate'] ?? 0.0).toDouble(),
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      knockouts: map['knockouts'] ?? 0,
      performanceHistory: ((map['performanceHistory'] as List?) ?? const [])
          .whereType<Map>()
          .map<PerformanceDataPoint>(
            (entry) =>
                PerformanceDataPoint.fromMap(Map<String, dynamic>.from(entry)),
          )
          .toList(),
    );
  }
}

class PerformanceDataPoint extends Equatable {
  final DateTime date;
  final double rating; // 0-10 or localized metric

  const PerformanceDataPoint({required this.date, required this.rating});

  @override
  List<Object?> get props => [date, rating];

  static PerformanceDataPoint fromMap(Map<String, dynamic> map) {
    return PerformanceDataPoint(
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      rating: (map['rating'] ?? 0.0).toDouble(),
    );
  }
}
