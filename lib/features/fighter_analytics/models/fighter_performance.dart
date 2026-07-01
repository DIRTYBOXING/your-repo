import 'package:equatable/equatable.dart';

/// Fighter performance metrics and career statistics
class FighterPerformance extends Equatable {
  final String fighterId;
  final int totalFights;
  final int wins;
  final int losses;
  final int draws;
  final double winRate;
  final int knockouts;
  final int submissions;
  final int decisions;
  final double avgRoundDuration; // in minutes
  final double strikeAccuracy; // percentage
  final double takedownDefense; // percentage
  final double controlTime; // percentage of fight
  final int currentWinStreak;
  final int longestWinStreak;
  final DateTime? lastFightDate;
  final double rating; // ELO or custom rating
  final List<FightRecord> recentFights;

  const FighterPerformance({
    required this.fighterId,
    this.totalFights = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.winRate = 0.0,
    this.knockouts = 0,
    this.submissions = 0,
    this.decisions = 0,
    this.avgRoundDuration = 0.0,
    this.strikeAccuracy = 0.0,
    this.takedownDefense = 0.0,
    this.controlTime = 0.0,
    this.currentWinStreak = 0,
    this.longestWinStreak = 0,
    this.lastFightDate,
    this.rating = 1500.0,
    this.recentFights = const [],
  });

  @override
  List<Object?> get props => [
    fighterId,
    totalFights,
    wins,
    losses,
    draws,
    winRate,
    knockouts,
    submissions,
    decisions,
    avgRoundDuration,
    strikeAccuracy,
    takedownDefense,
    controlTime,
    currentWinStreak,
    longestWinStreak,
    lastFightDate,
    rating,
    recentFights,
  ];

  FighterPerformance copyWith({
    String? fighterId,
    int? totalFights,
    int? wins,
    int? losses,
    int? draws,
    double? winRate,
    int? knockouts,
    int? submissions,
    int? decisions,
    double? avgRoundDuration,
    double? strikeAccuracy,
    double? takedownDefense,
    double? controlTime,
    int? currentWinStreak,
    int? longestWinStreak,
    DateTime? lastFightDate,
    double? rating,
    List<FightRecord>? recentFights,
  }) {
    return FighterPerformance(
      fighterId: fighterId ?? this.fighterId,
      totalFights: totalFights ?? this.totalFights,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      winRate: winRate ?? this.winRate,
      knockouts: knockouts ?? this.knockouts,
      submissions: submissions ?? this.submissions,
      decisions: decisions ?? this.decisions,
      avgRoundDuration: avgRoundDuration ?? this.avgRoundDuration,
      strikeAccuracy: strikeAccuracy ?? this.strikeAccuracy,
      takedownDefense: takedownDefense ?? this.takedownDefense,
      controlTime: controlTime ?? this.controlTime,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      longestWinStreak: longestWinStreak ?? this.longestWinStreak,
      lastFightDate: lastFightDate ?? this.lastFightDate,
      rating: rating ?? this.rating,
      recentFights: recentFights ?? this.recentFights,
    );
  }
}

/// Individual fight record for history
class FightRecord extends Equatable {
  final String fightId;
  final String opponent;
  final String result; // 'WIN', 'LOSS', 'DRAW'
  final String method; // 'KO', 'SUBMISSION', 'DECISION'
  final int roundEnded;
  final String timeInRound;
  final DateTime fightDate;
  final String event;
  final String opponent1Strikes;
  final String opponent2Strikes;

  const FightRecord({
    required this.fightId,
    required this.opponent,
    required this.result,
    required this.method,
    required this.roundEnded,
    required this.timeInRound,
    required this.fightDate,
    required this.event,
    this.opponent1Strikes = '',
    this.opponent2Strikes = '',
  });

  @override
  List<Object?> get props => [
    fightId,
    opponent,
    result,
    method,
    roundEnded,
    timeInRound,
    fightDate,
    event,
    opponent1Strikes,
    opponent2Strikes,
  ];
}
