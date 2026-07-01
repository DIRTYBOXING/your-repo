import '../models/judge_score_models.dart';

/// Result of grading a round score with achievements
class GradeResult {
  final RoundScore roundScore;
  final int xpEarned;
  final JudgeProfile updatedProfile;
  final JudgeProfile? previousProfile;
  final List<JudgeBadge> newBadgesUnlocked;
  final bool rankedUp;
  final JudgeRank? previousRank;
  final JudgeRank? newRank;
  final bool perfectCard; // True if all rounds in event are perfect

  GradeResult({
    required this.roundScore,
    required this.xpEarned,
    required this.updatedProfile,
    this.previousProfile,
    this.newBadgesUnlocked = const [],
    this.rankedUp = false,
    this.previousRank,
    this.newRank,
    this.perfectCard = false,
  });

  bool get hasAchievements =>
      newBadgesUnlocked.isNotEmpty || rankedUp || perfectCard;

  bool get isPerfectScore => roundScore.accuracy == JudgeAccuracyLevel.perfect;
}
