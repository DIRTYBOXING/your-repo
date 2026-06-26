import '../models/badge_model.dart';

class BadgeService {
  static final List<Badge> allBadges = [
    const Badge(
      id: 'streak_3',
      name: '3-Win Streak',
      description: 'Win 3 predictions in a row.',
      iconPath: 'assets/icons/badge_streak3.png',
      pointsRequired: 0,
    ),
    const Badge(
      id: 'points_1000',
      name: '1,000 Points',
      description: 'Earn 1,000 total points.',
      iconPath: 'assets/icons/badge_1000pts.png',
      pointsRequired: 1000,
    ),
    const Badge(
      id: 'leaderboard_top10',
      name: 'Top 10',
      description: 'Reach the top 10 on the leaderboard.',
      iconPath: 'assets/icons/badge_top10.png',
      pointsRequired: 0,
    ),
  ];

  // Returns badges the user has unlocked
  static List<Badge> getUnlockedBadges(
    int points,
    int streak,
    int leaderboardRank,
  ) {
    final unlocked = <Badge>[];
    for (final badge in allBadges) {
      if (badge.id == 'streak_3' && streak >= 3) unlocked.add(badge);
      if (badge.id == 'points_1000' && points >= 1000) unlocked.add(badge);
      if (badge.id == 'leaderboard_top10' && leaderboardRank <= 10) {
        unlocked.add(badge);
      }
    }
    return unlocked;
  }
}
