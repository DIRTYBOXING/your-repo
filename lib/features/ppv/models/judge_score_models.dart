import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// "YOU'RE THE JUDGE" — Live Round Scoring System
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Let fans score fights in real-time, compete on accuracy, earn XP & badges.
/// NO gambling, pure judging skill and bragging rights.
///
/// Firestore Structure:
///   user_judge_scores/{userId}/events/{eventId}/fights/{fightId}/rounds/{roundNum}
///   judge_leaderboards/global/users/{userId}
///   judge_leaderboards/{eventId}/users/{userId}
///
/// XP System:
///   - Correct round score: +10 XP
///   - Exact match to official judges: +25 XP
///   - First to score (within 30s of round end): +5 XP bonus
///   - Perfect fight card (all rounds correct): +100 XP bonus
///
/// Badges:
///   - 🥉 Bronze Judge: 50 correct rounds
///   - 🥈 Silver Judge: 200 correct rounds
///   - 🥇 Gold Judge: 500 correct rounds
///   - 🏆 Hall of Fame: 1000 correct rounds + 95% accuracy
///   - 🔥 Hot Streak: 10 correct rounds in a row
///   - 🎯 Eagle Eye: 20 exact matches to judges
/// ═══════════════════════════════════════════════════════════════════════════

enum JudgeAccuracyLevel {
  perfect, // Exact match to official judges
  correct, // Same winner, close score
  close, // Within 1 point
  wrong, // Different winner
}

enum JudgeRank {
  rookie, // 0-49 XP
  bronze, // 50-199 XP
  silver, // 200-499 XP
  gold, // 500-999 XP
  champion, // 1000-1999 XP
  hallOfFame, // 2000+ XP
}

enum JudgeBadge {
  bronzeJudge, // 50 correct rounds
  silverJudge, // 200 correct rounds
  goldJudge, // 500 correct rounds
  hallOfFame, // 1000 correct + 95% accuracy
  hotStreak, // 10 correct in a row
  eagleEye, // 20 exact matches
  speedDemon, // 50 first-to-score bonuses
  perfectCard, // All rounds correct on an event
  controversialKing, // 20 correct on split decisions
  knockoutCaller, // Predicted 10 finishes correctly
}

/// User's round score prediction
class RoundScore extends Equatable {
  final String userId;
  final String eventId;
  final String fightId;
  final int roundNumber;
  final int redCornerScore; // 10-7 scale
  final int blueCornerScore; // 10-7 scale
  final DateTime submittedAt;
  final int? officialRedScore;
  final int? officialBlueScore;
  final JudgeAccuracyLevel? accuracy;
  final int xpEarned;
  final bool firstToScore;

  const RoundScore({
    required this.userId,
    required this.eventId,
    required this.fightId,
    required this.roundNumber,
    required this.redCornerScore,
    required this.blueCornerScore,
    required this.submittedAt,
    this.officialRedScore,
    this.officialBlueScore,
    this.accuracy,
    this.xpEarned = 0,
    this.firstToScore = false,
  });

  String get winner {
    if (redCornerScore > blueCornerScore) return 'red';
    if (blueCornerScore > redCornerScore) return 'blue';
    return 'draw';
  }

  bool get isCorrect =>
      accuracy == JudgeAccuracyLevel.perfect ||
      accuracy == JudgeAccuracyLevel.correct;

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'eventId': eventId,
      'fightId': fightId,
      'roundNumber': roundNumber,
      'redCornerScore': redCornerScore,
      'blueCornerScore': blueCornerScore,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'officialRedScore': officialRedScore,
      'officialBlueScore': officialBlueScore,
      'accuracy': accuracy?.name,
      'xpEarned': xpEarned,
      'firstToScore': firstToScore,
    };
  }

  factory RoundScore.fromFirestore(Map<String, dynamic> data) {
    return RoundScore(
      userId: data['userId'] ?? '',
      eventId: data['eventId'] ?? '',
      fightId: data['fightId'] ?? '',
      roundNumber: data['roundNumber'] ?? 1,
      redCornerScore: data['redCornerScore'] ?? 10,
      blueCornerScore: data['blueCornerScore'] ?? 10,
      submittedAt:
          (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      officialRedScore: data['officialRedScore'],
      officialBlueScore: data['officialBlueScore'],
      accuracy: data['accuracy'] != null
          ? JudgeAccuracyLevel.values.byName(data['accuracy'])
          : null,
      xpEarned: data['xpEarned'] ?? 0,
      firstToScore: data['firstToScore'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    eventId,
    fightId,
    roundNumber,
    redCornerScore,
    blueCornerScore,
    submittedAt,
  ];
}

/// User's judge profile with stats and badges
class JudgeProfile extends Equatable {
  final String userId;
  final int totalXP;
  final int correctRounds;
  final int totalRounds;
  final int perfectMatches;
  final int currentStreak;
  final int longestStreak;
  final List<JudgeBadge> badges;
  final JudgeRank rank;
  final DateTime? lastScoreAt;
  final Map<String, int> eventScores; // eventId -> XP earned

  const JudgeProfile({
    required this.userId,
    this.totalXP = 0,
    this.correctRounds = 0,
    this.totalRounds = 0,
    this.perfectMatches = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.badges = const [],
    this.rank = JudgeRank.rookie,
    this.lastScoreAt,
    this.eventScores = const {},
  });

  double get accuracy =>
      totalRounds > 0 ? (correctRounds / totalRounds) * 100 : 0.0;

  JudgeRank calculateRank() {
    if (totalXP >= 2000) return JudgeRank.hallOfFame;
    if (totalXP >= 1000) return JudgeRank.champion;
    if (totalXP >= 500) return JudgeRank.gold;
    if (totalXP >= 200) return JudgeRank.silver;
    if (totalXP >= 50) return JudgeRank.bronze;
    return JudgeRank.rookie;
  }

  List<JudgeBadge> calculateEarnedBadges() {
    final earned = <JudgeBadge>[];
    if (correctRounds >= 50) earned.add(JudgeBadge.bronzeJudge);
    if (correctRounds >= 200) earned.add(JudgeBadge.silverJudge);
    if (correctRounds >= 500) earned.add(JudgeBadge.goldJudge);
    if (correctRounds >= 1000 && accuracy >= 95) {
      earned.add(JudgeBadge.hallOfFame);
    }
    if (currentStreak >= 10) earned.add(JudgeBadge.hotStreak);
    if (perfectMatches >= 20) earned.add(JudgeBadge.eagleEye);
    return earned;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalXP': totalXP,
      'correctRounds': correctRounds,
      'totalRounds': totalRounds,
      'perfectMatches': perfectMatches,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'badges': badges.map((b) => b.name).toList(),
      'rank': rank.name,
      'lastScoreAt': lastScoreAt != null
          ? Timestamp.fromDate(lastScoreAt!)
          : null,
      'eventScores': eventScores,
    };
  }

  factory JudgeProfile.fromFirestore(Map<String, dynamic> data) {
    return JudgeProfile(
      userId: data['userId'] ?? '',
      totalXP: data['totalXP'] ?? 0,
      correctRounds: data['correctRounds'] ?? 0,
      totalRounds: data['totalRounds'] ?? 0,
      perfectMatches: data['perfectMatches'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      badges: ((data['badges'] as List<dynamic>?) ?? [])
          .map((b) => JudgeBadge.values.byName(b as String))
          .toList(),
      rank: data['rank'] != null
          ? JudgeRank.values.byName(data['rank'])
          : JudgeRank.rookie,
      lastScoreAt: (data['lastScoreAt'] as Timestamp?)?.toDate(),
      eventScores: Map<String, int>.from(data['eventScores'] ?? {}),
    );
  }

  JudgeProfile copyWith({
    int? totalXP,
    int? correctRounds,
    int? totalRounds,
    int? perfectMatches,
    int? currentStreak,
    int? longestStreak,
    List<JudgeBadge>? badges,
    JudgeRank? rank,
    DateTime? lastScoreAt,
    Map<String, int>? eventScores,
  }) {
    return JudgeProfile(
      userId: userId,
      totalXP: totalXP ?? this.totalXP,
      correctRounds: correctRounds ?? this.correctRounds,
      totalRounds: totalRounds ?? this.totalRounds,
      perfectMatches: perfectMatches ?? this.perfectMatches,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      badges: badges ?? this.badges,
      rank: rank ?? this.rank,
      lastScoreAt: lastScoreAt ?? this.lastScoreAt,
      eventScores: eventScores ?? this.eventScores,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    totalXP,
    correctRounds,
    totalRounds,
    perfectMatches,
    currentStreak,
    longestStreak,
    badges,
    rank,
    lastScoreAt,
    eventScores,
  ];
}

/// Leaderboard entry for rankings
class JudgeLeaderboardEntry extends Equatable {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int totalXP;
  final double accuracy;
  final int correctRounds;
  final JudgeRank rank;
  final List<JudgeBadge> topBadges;
  final int position;

  const JudgeLeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.totalXP,
    required this.accuracy,
    required this.correctRounds,
    required this.rank,
    this.topBadges = const [],
    this.position = 0,
  });

  @override
  List<Object?> get props => [
    userId,
    displayName,
    photoUrl,
    totalXP,
    accuracy,
    correctRounds,
    rank,
    topBadges,
    position,
  ];
}
