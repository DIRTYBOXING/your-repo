import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT STATS MODEL — Real-time Combat Metrics
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Immutable model for live fight statistics:
///   - Strikes (landed vs attempted)
///   - Takedowns (landed vs attempted)
///   - Control time
///   - Knockdowns
///   - Grappling exchanges
///   - Scorecard per round
///
/// Designed for real-time Firestore updates.
/// ═══════════════════════════════════════════════════════════════════════════

class FighterStats extends Equatable {
  /// Strikes landed in current round
  final int strikesLanded;

  /// Strike attempts in current round
  final int strikeAttempts;

  /// Takedowns landed in current round
  final int takedownsLanded;

  /// Takedown attempts in current round
  final int takedownAttempts;

  /// Time in control (seconds) in current round
  final int controlTimeSeconds;

  /// Knockdowns in current round
  final int knockdowns;

  /// Cumulative strikes landed (all rounds)
  final int totalStrikesLanded;

  /// Cumulative strike attempts (all rounds)
  final int totalStrikeAttempts;

  /// Cumulative takedowns landed (all rounds)
  final int totalTakedownsLanded;

  /// Cumulative takedown attempts (all rounds)
  final int totalTakedownAttempts;

  /// Cumulative control time (all rounds, seconds)
  final int totalControlTimeSeconds;

  /// Cumulative knockdowns (all rounds)
  final int totalKnockdowns;

  /// Scores per round [Round1, Round2, Round3, etc]
  /// Values: 10, 9, 8, 7 (10-point must system)
  final List<int> scoresPerRound;

  /// Significant strikes (strikes > 3.66" distance)
  final int significantStrikesLanded;

  /// Guard passes (grappling metric)
  final int guardPasses;

  /// Reversals (grappling metric)
  final int reversals;

  /// Last update timestamp (for UI rendering)
  final DateTime lastUpdated;

  const FighterStats({
    required this.strikesLanded,
    required this.strikeAttempts,
    required this.takedownsLanded,
    required this.takedownAttempts,
    required this.controlTimeSeconds,
    required this.knockdowns,
    required this.totalStrikesLanded,
    required this.totalStrikeAttempts,
    required this.totalTakedownsLanded,
    required this.totalTakedownAttempts,
    required this.totalControlTimeSeconds,
    required this.totalKnockdowns,
    required this.scoresPerRound,
    required this.significantStrikesLanded,
    required this.guardPasses,
    required this.reversals,
    required this.lastUpdated,
  });

  /// Factory: Create initial empty stats
  factory FighterStats.initial() {
    return FighterStats(
      strikesLanded: 0,
      strikeAttempts: 0,
      takedownsLanded: 0,
      takedownAttempts: 0,
      controlTimeSeconds: 0,
      knockdowns: 0,
      totalStrikesLanded: 0,
      totalStrikeAttempts: 0,
      totalTakedownsLanded: 0,
      totalTakedownAttempts: 0,
      totalControlTimeSeconds: 0,
      totalKnockdowns: 0,
      scoresPerRound: [10], // Start with 10 (no score yet)
      significantStrikesLanded: 0,
      guardPasses: 0,
      reversals: 0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Factory: From Firestore document
  factory FighterStats.fromFirestore(Map<String, dynamic> data) {
    return FighterStats(
      strikesLanded: data['strikesLanded'] as int? ?? 0,
      strikeAttempts: data['strikeAttempts'] as int? ?? 0,
      takedownsLanded: data['takedownsLanded'] as int? ?? 0,
      takedownAttempts: data['takedownAttempts'] as int? ?? 0,
      controlTimeSeconds: data['controlTimeSeconds'] as int? ?? 0,
      knockdowns: data['knockdowns'] as int? ?? 0,
      totalStrikesLanded: data['totalStrikesLanded'] as int? ?? 0,
      totalStrikeAttempts: data['totalStrikeAttempts'] as int? ?? 0,
      totalTakedownsLanded: data['totalTakedownsLanded'] as int? ?? 0,
      totalTakedownAttempts: data['totalTakedownAttempts'] as int? ?? 0,
      totalControlTimeSeconds: data['totalControlTimeSeconds'] as int? ?? 0,
      totalKnockdowns: data['totalKnockdowns'] as int? ?? 0,
      scoresPerRound: List<int>.from(data['scoresPerRound'] as List? ?? [10]),
      significantStrikesLanded: data['significantStrikesLanded'] as int? ?? 0,
      guardPasses: data['guardPasses'] as int? ?? 0,
      reversals: data['reversals'] as int? ?? 0,
      lastUpdated: data['lastUpdated'] != null
          ? DateTime.parse(data['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'strikesLanded': strikesLanded,
      'strikeAttempts': strikeAttempts,
      'takedownsLanded': takedownsLanded,
      'takedownAttempts': takedownAttempts,
      'controlTimeSeconds': controlTimeSeconds,
      'knockdowns': knockdowns,
      'totalStrikesLanded': totalStrikesLanded,
      'totalStrikeAttempts': totalStrikeAttempts,
      'totalTakedownsLanded': totalTakedownsLanded,
      'totalTakedownAttempts': totalTakedownAttempts,
      'totalControlTimeSeconds': totalControlTimeSeconds,
      'totalKnockdowns': totalKnockdowns,
      'scoresPerRound': scoresPerRound,
      'significantStrikesLanded': significantStrikesLanded,
      'guardPasses': guardPasses,
      'reversals': reversals,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // ── Computed Properties ──

  /// Strike accuracy percentage
  double get strikeAccuracy =>
      strikeAttempts > 0 ? (strikesLanded / strikeAttempts * 100) : 0.0;

  /// Takedown accuracy percentage
  double get takedownAccuracy =>
      takedownAttempts > 0 ? (takedownsLanded / takedownAttempts * 100) : 0.0;

  /// Total strike accuracy
  double get totalStrikeAccuracy => totalStrikeAttempts > 0
      ? (totalStrikesLanded / totalStrikeAttempts * 100)
      : 0.0;

  /// Total takedown accuracy
  double get totalTakedownAccuracy => totalTakedownAttempts > 0
      ? (totalTakedownsLanded / totalTakedownAttempts * 100)
      : 0.0;

  /// Format control time as mm:ss
  String get formattedControlTime {
    final minutes = controlTimeSeconds ~/ 60;
    final seconds = controlTimeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format total control time as mm:ss
  String get formattedTotalControlTime {
    final minutes = totalControlTimeSeconds ~/ 60;
    final seconds = totalControlTimeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Current round score (10-point must system)
  int get currentRoundScore =>
      scoresPerRound.isNotEmpty ? scoresPerRound.last : 10;

  /// Copy with modifications
  FighterStats copyWith({
    int? strikesLanded,
    int? strikeAttempts,
    int? takedownsLanded,
    int? takedownAttempts,
    int? controlTimeSeconds,
    int? knockdowns,
    int? totalStrikesLanded,
    int? totalStrikeAttempts,
    int? totalTakedownsLanded,
    int? totalTakedownAttempts,
    int? totalControlTimeSeconds,
    int? totalKnockdowns,
    List<int>? scoresPerRound,
    int? significantStrikesLanded,
    int? guardPasses,
    int? reversals,
    DateTime? lastUpdated,
  }) {
    return FighterStats(
      strikesLanded: strikesLanded ?? this.strikesLanded,
      strikeAttempts: strikeAttempts ?? this.strikeAttempts,
      takedownsLanded: takedownsLanded ?? this.takedownsLanded,
      takedownAttempts: takedownAttempts ?? this.takedownAttempts,
      controlTimeSeconds: controlTimeSeconds ?? this.controlTimeSeconds,
      knockdowns: knockdowns ?? this.knockdowns,
      totalStrikesLanded: totalStrikesLanded ?? this.totalStrikesLanded,
      totalStrikeAttempts: totalStrikeAttempts ?? this.totalStrikeAttempts,
      totalTakedownsLanded: totalTakedownsLanded ?? this.totalTakedownsLanded,
      totalTakedownAttempts:
          totalTakedownAttempts ?? this.totalTakedownAttempts,
      totalControlTimeSeconds:
          totalControlTimeSeconds ?? this.totalControlTimeSeconds,
      totalKnockdowns: totalKnockdowns ?? this.totalKnockdowns,
      scoresPerRound: scoresPerRound ?? this.scoresPerRound,
      significantStrikesLanded:
          significantStrikesLanded ?? this.significantStrikesLanded,
      guardPasses: guardPasses ?? this.guardPasses,
      reversals: reversals ?? this.reversals,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    strikesLanded,
    strikeAttempts,
    takedownsLanded,
    takedownAttempts,
    controlTimeSeconds,
    knockdowns,
    totalStrikesLanded,
    totalStrikeAttempts,
    totalTakedownsLanded,
    totalTakedownAttempts,
    totalControlTimeSeconds,
    totalKnockdowns,
    scoresPerRound,
    significantStrikesLanded,
    guardPasses,
    reversals,
    lastUpdated,
  ];
}

/// ─────────────────────────────────────────────────────────────────────────
/// Round-level fight state snapshot
/// ─────────────────────────────────────────────────────────────────────────

class RoundStats extends Equatable {
  /// Round number (1-indexed)
  final int roundNumber;

  /// Fighter 1 stats for this round
  final FighterStats fighter1Stats;

  /// Fighter 2 stats for this round
  final FighterStats fighter2Stats;

  /// Round duration (typically 300 seconds = 5 min)
  final int durationSeconds;

  /// Whether round is complete
  final bool isComplete;

  /// Timestamp when round started
  final DateTime startedAt;

  /// Timestamp when round ended (if complete)
  final DateTime? endedAt;

  const RoundStats({
    required this.roundNumber,
    required this.fighter1Stats,
    required this.fighter2Stats,
    required this.durationSeconds,
    required this.isComplete,
    required this.startedAt,
    this.endedAt,
  });

  /// Elapsed time in current round (seconds)
  int get elapsedSeconds {
    if (isComplete && endedAt != null) {
      return durationSeconds;
    }
    return DateTime.now().difference(startedAt).inSeconds;
  }

  /// Remaining time in round (seconds)
  int get remainingSeconds {
    final remaining = durationSeconds - elapsedSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Format remaining time as mm:ss
  String get formattedTimeRemaining {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Determine round winner (10-point must system)
  /// Returns: 1 (fighter1 wins), 2 (fighter2 wins), 0 (tie/draw)
  int getWinner() {
    final f1Score = fighter1Stats.currentRoundScore;
    final f2Score = fighter2Stats.currentRoundScore;

    if (f1Score > f2Score) return 1;
    if (f2Score > f1Score) return 2;
    return 0;
  }

  @override
  List<Object?> get props => [
    roundNumber,
    fighter1Stats,
    fighter2Stats,
    durationSeconds,
    isComplete,
    startedAt,
    endedAt,
  ];
}

/// ─────────────────────────────────────────────────────────────────────────
/// Fight-level scorecard (all rounds)
/// ─────────────────────────────────────────────────────────────────────────

class FightScorecard extends Equatable {
  /// Fighter 1 total score (sum of round scores)
  final int fighter1TotalScore;

  /// Fighter 2 total score
  final int fighter2TotalScore;

  /// All rounds completed
  final List<RoundStats> rounds;

  /// Fight result (if decided)
  /// 1 = Fighter1 wins, 2 = Fighter2 wins, 0 = Draw
  final int? result;

  /// Method (Decision, KO, TKO, Submission, DQ, etc)
  final String? method;

  const FightScorecard({
    required this.fighter1TotalScore,
    required this.fighter2TotalScore,
    required this.rounds,
    this.result,
    this.method,
  });

  /// Determine overall winner
  int getWinner() {
    if (result != null) return result!;
    if (fighter1TotalScore > fighter2TotalScore) return 1;
    if (fighter2TotalScore > fighter1TotalScore) return 2;
    return 0;
  }

  /// Format scores as "Fighter1 (score) vs Fighter2 (score)"
  String get formattedScores =>
      'Fighter 1: $fighter1TotalScore | Fighter 2: $fighter2TotalScore';

  @override
  List<Object?> get props => [
    fighter1TotalScore,
    fighter2TotalScore,
    rounds,
    result,
    method,
  ];
}
