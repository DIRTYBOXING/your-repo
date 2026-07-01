// ═══════════════════════════════════════════════════════════════════════════
// SOCIAL CHALLENGES ENGINE — Gamification, Achievements, XP, Streaks
// ═══════════════════════════════════════════════════════════════════════════
//
// Full gamification layer for social engagement:
//  • XP system — earn experience for platform actions
//  • Achievements — unlock badges for milestones
//  • Streaks — daily engagement tracking with multipliers
//  • Challenges — community-wide and personal goals
//  • Leaderboards — weekly/monthly rankings
//  • Levels — progression system with tier unlocks
//
// Drives engagement beyond content consumption into active participation
// ═══════════════════════════════════════════════════════════════════════════

// ─── Enums ──────────────────────────────────────────────────────────────

enum XPAction {
  createPost(15, 'Created a post'),
  addComment(5, 'Left a comment'),
  receiveLike(2, 'Post was liked'),
  receiveComment(3, 'Post received comment'),
  sharePost(8, 'Shared content'),
  joinGroup(20, 'Joined a community'),
  attendEvent(30, 'Attended an event'),
  watchLiveStream(10, 'Watched a live stream'),
  sendTip(25, 'Tipped a creator'),
  completeChallenge(50, 'Completed a challenge'),
  inviteFriend(40, 'Friend joined from invite'),
  firstPost(100, 'First ever post'),
  profileComplete(50, 'Completed profile setup'),
  weekStreak(75, 'Week-long daily streak'),
  monthStreak(500, 'Month-long daily streak'),
  winLeaderboard(200, 'Won weekly leaderboard'),
  ppvPurchase(20, 'Purchased a PPV event'),
  createReel(20, 'Created a short video');

  final int xp;
  final String description;
  const XPAction(this.xp, this.description);
}

enum AchievementRarity {
  common('Common', '🟢', 1.0),
  uncommon('Uncommon', '🔵', 1.5),
  rare('Rare', '🟣', 2.0),
  epic('Epic', '🟠', 3.0),
  legendary('Legendary', '🟡', 5.0);

  final String label;
  final String icon;
  final double xpMultiplier;
  const AchievementRarity(this.label, this.icon, this.xpMultiplier);
}

enum ChallengeType {
  daily('Daily', Duration(hours: 24)),
  weekly('Weekly', Duration(days: 7)),
  monthly('Monthly', Duration(days: 30)),
  community('Community', Duration(days: 14)),
  seasonal('Seasonal', Duration(days: 90));

  final String label;
  final Duration duration;
  const ChallengeType(this.label, this.duration);
}

// ─── Models ─────────────────────────────────────────────────────────────

class UserXPProfile {
  final String userId;
  final int totalXP;
  final int level;
  final int xpToNextLevel;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final List<String> unlockedAchievements;
  final Map<String, int> actionCounts;
  final double streakMultiplier;

  const UserXPProfile({
    required this.userId,
    this.totalXP = 0,
    this.level = 1,
    this.xpToNextLevel = 100,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.unlockedAchievements = const [],
    this.actionCounts = const {},
    this.streakMultiplier = 1.0,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'totalXP': totalXP,
    'level': level,
    'xpToNextLevel': xpToNextLevel,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'achievementCount': unlockedAchievements.length,
    'streakMultiplier': streakMultiplier,
  };
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementRarity rarity;
  final int xpReward;
  final bool Function(UserXPProfile) condition;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.xpReward,
    required this.condition,
  });
}

class Challenge {
  final String challengeId;
  final String title;
  final String description;
  final ChallengeType type;
  final int xpReward;
  final int targetCount;
  final XPAction targetAction;
  final DateTime startsAt;
  final DateTime endsAt;
  final int participantCount;
  final bool isActive;

  const Challenge({
    required this.challengeId,
    required this.title,
    required this.description,
    required this.type,
    required this.xpReward,
    required this.targetCount,
    required this.targetAction,
    required this.startsAt,
    required this.endsAt,
    this.participantCount = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'challengeId': challengeId,
    'title': title,
    'type': type.name,
    'xpReward': xpReward,
    'targetCount': targetCount,
    'targetAction': targetAction.name,
    'participantCount': participantCount,
    'isActive': isActive,
  };
}

class ChallengeProgress {
  final String challengeId;
  final String userId;
  final int currentCount;
  final int targetCount;
  final bool isCompleted;
  final DateTime? completedAt;

  const ChallengeProgress({
    required this.challengeId,
    required this.userId,
    required this.currentCount,
    required this.targetCount,
    this.isCompleted = false,
    this.completedAt,
  });

  double get progressPercent =>
      targetCount > 0 ? (currentCount / targetCount).clamp(0, 1) : 0;
}

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int xp;
  final int rank;
  final int level;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.xp,
    required this.rank,
    required this.level,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'displayName': displayName,
    'xp': xp,
    'rank': rank,
    'level': level,
  };
}

// ─── Engine ─────────────────────────────────────────────────────────────

class SocialChallengesEngine {
  SocialChallengesEngine._();
  static final SocialChallengesEngine instance = SocialChallengesEngine._();

  // XP curve: level N requires N * 100 XP
  static int xpForLevel(int level) => level * 100;

  // Streak multiplier caps at 3x for 30+ days
  static double streakMultiplier(int streakDays) {
    if (streakDays <= 0) return 1.0;
    if (streakDays < 3) return 1.0;
    if (streakDays < 7) return 1.25;
    if (streakDays < 14) return 1.5;
    if (streakDays < 30) return 2.0;
    return 3.0;
  }

  final _profiles = <String, UserXPProfile>{};
  final _challenges = <Challenge>[];
  final _challengeProgress = <String, Map<String, ChallengeProgress>>{};

  // ─── Built-in achievements ────────────────────────────────────────────
  List<Achievement> get achievements => [
    Achievement(
      id: 'first_post',
      title: 'First Blood',
      description: 'Create your first post',
      icon: '🥊',
      rarity: AchievementRarity.common,
      xpReward: 100,
      condition: (p) => (p.actionCounts['createPost'] ?? 0) >= 1,
    ),
    Achievement(
      id: 'social_butterfly',
      title: 'Social Butterfly',
      description: 'Leave 50 comments',
      icon: '🦋',
      rarity: AchievementRarity.uncommon,
      xpReward: 200,
      condition: (p) => (p.actionCounts['addComment'] ?? 0) >= 50,
    ),
    Achievement(
      id: 'content_machine',
      title: 'Content Machine',
      description: 'Create 100 posts',
      icon: '⚡',
      rarity: AchievementRarity.rare,
      xpReward: 500,
      condition: (p) => (p.actionCounts['createPost'] ?? 0) >= 100,
    ),
    Achievement(
      id: 'week_warrior',
      title: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      icon: '🗓️',
      rarity: AchievementRarity.uncommon,
      xpReward: 150,
      condition: (p) => p.longestStreak >= 7,
    ),
    Achievement(
      id: 'month_master',
      title: 'Month Master',
      description: 'Maintain a 30-day streak',
      icon: '🏅',
      rarity: AchievementRarity.epic,
      xpReward: 1000,
      condition: (p) => p.longestStreak >= 30,
    ),
    Achievement(
      id: 'generous_spirit',
      title: 'Generous Spirit',
      description: 'Send 10 tips to creators',
      icon: '💎',
      rarity: AchievementRarity.rare,
      xpReward: 300,
      condition: (p) => (p.actionCounts['sendTip'] ?? 0) >= 10,
    ),
    Achievement(
      id: 'community_builder',
      title: 'Community Builder',
      description: 'Join 5 groups',
      icon: '🏘️',
      rarity: AchievementRarity.uncommon,
      xpReward: 200,
      condition: (p) => (p.actionCounts['joinGroup'] ?? 0) >= 5,
    ),
    Achievement(
      id: 'legend_status',
      title: 'Legend Status',
      description: 'Reach level 50',
      icon: '👑',
      rarity: AchievementRarity.legendary,
      xpReward: 5000,
      condition: (p) => p.level >= 50,
    ),
    Achievement(
      id: 'viral_sensation',
      title: 'Viral Sensation',
      description: 'Receive 1000 likes total',
      icon: '🔥',
      rarity: AchievementRarity.epic,
      xpReward: 750,
      condition: (p) => (p.actionCounts['receiveLike'] ?? 0) >= 1000,
    ),
    Achievement(
      id: 'event_enthusiast',
      title: 'Event Enthusiast',
      description: 'Attend 10 events',
      icon: '🎟️',
      rarity: AchievementRarity.rare,
      xpReward: 400,
      condition: (p) => (p.actionCounts['attendEvent'] ?? 0) >= 10,
    ),
  ];

  /// Record an XP action for a user.
  UserXPProfile recordAction({
    required String userId,
    required XPAction action,
    String? displayName,
  }) {
    var profile = _profiles[userId] ?? UserXPProfile(userId: userId);

    // Update streak
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int newStreak = profile.currentStreak;
    int longestStreak = profile.longestStreak;

    if (profile.lastActiveDate != null) {
      final lastActive = DateTime(
        profile.lastActiveDate!.year,
        profile.lastActiveDate!.month,
        profile.lastActiveDate!.day,
      );
      final daysDiff = today.difference(lastActive).inDays;
      if (daysDiff == 1) {
        newStreak = profile.currentStreak + 1;
      } else if (daysDiff > 1) {
        newStreak = 1; // Streak broken
      }
      // Same day = no streak change
    } else {
      newStreak = 1;
    }
    if (newStreak > longestStreak) longestStreak = newStreak;

    // Calculate XP with streak multiplier
    final multiplier = streakMultiplier(newStreak);
    final earnedXP = (action.xp * multiplier).round();
    final newTotalXP = profile.totalXP + earnedXP;

    // Calculate level
    int newLevel = 1;
    int xpAccum = 0;
    while (xpAccum + xpForLevel(newLevel) <= newTotalXP) {
      xpAccum += xpForLevel(newLevel);
      newLevel++;
    }
    final xpToNext = xpForLevel(newLevel) - (newTotalXP - xpAccum);

    // Update action counts
    final newCounts = Map<String, int>.from(profile.actionCounts);
    newCounts[action.name] = (newCounts[action.name] ?? 0) + 1;

    // Check for new achievements
    final newAchievements = List<String>.from(profile.unlockedAchievements);
    final tempProfile = UserXPProfile(
      userId: userId,
      totalXP: newTotalXP,
      level: newLevel,
      xpToNextLevel: xpToNext,
      currentStreak: newStreak,
      longestStreak: longestStreak,
      lastActiveDate: now,
      unlockedAchievements: newAchievements,
      actionCounts: newCounts,
      streakMultiplier: multiplier,
    );

    for (final achievement in achievements) {
      if (!newAchievements.contains(achievement.id) &&
          achievement.condition(tempProfile)) {
        newAchievements.add(achievement.id);
      }
    }

    profile = UserXPProfile(
      userId: userId,
      totalXP: newTotalXP,
      level: newLevel,
      xpToNextLevel: xpToNext,
      currentStreak: newStreak,
      longestStreak: longestStreak,
      lastActiveDate: now,
      unlockedAchievements: newAchievements,
      actionCounts: newCounts,
      streakMultiplier: multiplier,
    );

    _profiles[userId] = profile;

    // Update challenge progress
    _updateChallengeProgress(userId, action);

    return profile;
  }

  /// Get or create a user profile.
  UserXPProfile getProfile(String userId) {
    return _profiles[userId] ?? UserXPProfile(userId: userId);
  }

  /// Create a new challenge.
  Challenge createChallenge({
    required String title,
    required String description,
    required ChallengeType type,
    required int xpReward,
    required int targetCount,
    required XPAction targetAction,
  }) {
    final now = DateTime.now();
    final challenge = Challenge(
      challengeId: 'challenge_${now.millisecondsSinceEpoch}',
      title: title,
      description: description,
      type: type,
      xpReward: xpReward,
      targetCount: targetCount,
      targetAction: targetAction,
      startsAt: now,
      endsAt: now.add(type.duration),
    );
    _challenges.add(challenge);
    return challenge;
  }

  /// Get active challenges.
  List<Challenge> getActiveChallenges() {
    final now = DateTime.now();
    return _challenges
        .where((c) => c.isActive && c.endsAt.isAfter(now))
        .toList();
  }

  /// Get challenge progress for a user.
  ChallengeProgress getChallengeProgress(String userId, String challengeId) {
    return _challengeProgress[userId]?[challengeId] ??
        ChallengeProgress(
          challengeId: challengeId,
          userId: userId,
          currentCount: 0,
          targetCount:
              _challenges
                  .where((c) => c.challengeId == challengeId)
                  .firstOrNull
                  ?.targetCount ??
              0,
        );
  }

  /// Get the weekly leaderboard.
  List<LeaderboardEntry> getLeaderboard({int limit = 20}) {
    final entries = _profiles.values.toList()
      ..sort((a, b) => b.totalXP.compareTo(a.totalXP));

    return entries.take(limit).toList().asMap().entries.map((e) {
      final profile = e.value;
      return LeaderboardEntry(
        userId: profile.userId,
        displayName: 'Fighter ${profile.userId}',
        xp: profile.totalXP,
        rank: e.key + 1,
        level: profile.level,
      );
    }).toList();
  }

  /// Get the number of challenges completed by a user.
  int completedChallengeCount(String userId) {
    final userProgress = _challengeProgress[userId];
    if (userProgress == null) return 0;
    return userProgress.values.where((p) => p.isCompleted).length;
  }

  void _updateChallengeProgress(String userId, XPAction action) {
    for (final challenge in getActiveChallenges()) {
      if (challenge.targetAction != action) continue;

      final userProgress = _challengeProgress[userId] ?? {};
      final current = userProgress[challenge.challengeId];
      final newCount = (current?.currentCount ?? 0) + 1;
      final isComplete = newCount >= challenge.targetCount;

      userProgress[challenge.challengeId] = ChallengeProgress(
        challengeId: challenge.challengeId,
        userId: userId,
        currentCount: newCount,
        targetCount: challenge.targetCount,
        isCompleted: isComplete,
        completedAt: isComplete ? DateTime.now() : null,
      );
      _challengeProgress[userId] = userProgress;
    }
  }
}
