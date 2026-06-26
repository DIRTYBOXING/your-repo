/// ═══════════════════════════════════════════════════════════════════════════
/// BADGES SERVICE - Gamification & Achievements System
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Combat sports achievement system:
/// - Training milestones
/// - Competition achievements
/// - Streak rewards
/// - Community engagement badges
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/foundation.dart';

/// Badge rarity levels
enum BadgeRarity { common, uncommon, rare, epic, legendary }

/// Badge categories
enum BadgeCategory {
  training,
  competition,
  streak,
  social,
  wellness,
  milestone,
}

/// Badge model
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final BadgeRarity rarity;
  final BadgeCategory category;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress; // 0.0 - 1.0

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.rarity,
    required this.category,
    this.xpReward = 100,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0.0,
  });

  /// Color based on rarity
  int get colorValue {
    switch (rarity) {
      case BadgeRarity.common:
        return 0xFF808080; // Gray
      case BadgeRarity.uncommon:
        return 0xFF00FF88; // Green
      case BadgeRarity.rare:
        return 0xFF00D4FF; // Blue
      case BadgeRarity.epic:
        return 0xFFAA66FF; // Purple
      case BadgeRarity.legendary:
        return 0xFFFFD700; // Gold
    }
  }
}

/// User's badge progress
class BadgeProgress {
  final int totalBadges;
  final int unlockedBadges;
  final int totalXP;
  final int currentLevel;
  final double levelProgress;

  BadgeProgress({
    required this.totalBadges,
    required this.unlockedBadges,
    required this.totalXP,
    required this.currentLevel,
    required this.levelProgress,
  });

  double get completionPercentage =>
      totalBadges > 0 ? unlockedBadges / totalBadges : 0;
}

/// Badges Service
class BadgesService extends ChangeNotifier {
  static final BadgesService _instance = BadgesService._internal();
  factory BadgesService() => _instance;
  BadgesService._internal();

  // State
  final List<Badge> _allBadges = [];
  int _totalXP = 0;
  int _currentLevel = 1;

  // Getters
  List<Badge> get allBadges => List.unmodifiable(_allBadges);
  List<Badge> get unlockedBadges =>
      _allBadges.where((b) => b.isUnlocked).toList();
  List<Badge> get lockedBadges =>
      _allBadges.where((b) => !b.isUnlocked).toList();
  int get totalXP => _totalXP;
  int get currentLevel => _currentLevel;

  /// Initialize the service
  Future<void> initialize() async {
    _loadBadges();
    _calculateXP();
    notifyListeners();
    debugPrint('🏆 Badges Service initialized');
  }

  void _loadBadges() {
    _allBadges.clear();
    _allBadges.addAll([
      // Training badges
      Badge(
        id: 'first_session',
        name: 'First Steps',
        description: 'Complete your first training session',
        iconName: 'directions_walk',
        rarity: BadgeRarity.common,
        category: BadgeCategory.training,
        xpReward: 50,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Badge(
        id: 'hundred_sessions',
        name: 'Century Club',
        description: 'Complete 100 training sessions',
        iconName: 'fitness_center',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.training,
        xpReward: 500,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Badge(
        id: 'iron_chin',
        name: 'Iron Chin',
        description: 'Complete 50 sparring sessions',
        iconName: 'sports_mma',
        rarity: BadgeRarity.uncommon,
        category: BadgeCategory.training,
        xpReward: 250,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Badge(
        id: 'grappling_master',
        name: 'Ground Game',
        description: 'Log 100 hours of grappling',
        iconName: 'self_improvement',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.training,
        xpReward: 400,
        progress: 0.72,
      ),

      // Competition badges
      Badge(
        id: 'first_fight',
        name: 'Warrior',
        description: 'Complete your first competition',
        iconName: 'emoji_events',
        rarity: BadgeRarity.uncommon,
        category: BadgeCategory.competition,
        xpReward: 300,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      Badge(
        id: 'gold_medal',
        name: 'Gold Standard',
        description: 'Win a gold medal in competition',
        iconName: 'military_tech',
        rarity: BadgeRarity.epic,
        category: BadgeCategory.competition,
        xpReward: 1000,
      ),
      Badge(
        id: 'ko_artist',
        name: 'KO Artist',
        description: 'Win by KO/TKO',
        iconName: 'flash_on',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.competition,
        xpReward: 500,
      ),
      Badge(
        id: 'submission_ace',
        name: 'Submission Ace',
        description: 'Win by submission',
        iconName: 'lock',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.competition,
        xpReward: 500,
      ),

      // Streak badges
      Badge(
        id: 'week_streak',
        name: 'Consistent',
        description: 'Train 7 days in a row',
        iconName: 'local_fire_department',
        rarity: BadgeRarity.common,
        category: BadgeCategory.streak,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Badge(
        id: 'month_streak',
        name: 'Dedicated',
        description: 'Train 30 days in a row',
        iconName: 'whatshot',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.streak,
        xpReward: 500,
        progress: 0.45,
      ),
      Badge(
        id: 'year_streak',
        name: 'Living Legend',
        description: 'Train 365 days in a row',
        iconName: 'stars',
        rarity: BadgeRarity.legendary,
        category: BadgeCategory.streak,
        xpReward: 5000,
        progress: 0.12,
      ),

      // Wellness badges
      Badge(
        id: 'hydration_hero',
        name: 'Hydration Hero',
        description: 'Hit hydration goals 30 days straight',
        iconName: 'water_drop',
        rarity: BadgeRarity.uncommon,
        category: BadgeCategory.wellness,
        xpReward: 200,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Badge(
        id: 'sleep_master',
        name: 'Sleep Master',
        description: 'Average 8+ hours sleep for a month',
        iconName: 'bedtime',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.wellness,
        xpReward: 350,
        progress: 0.6,
      ),
      Badge(
        id: 'weight_discipline',
        name: 'Weight Discipline',
        description: 'Stay within 5% of target weight for 90 days',
        iconName: 'monitor_weight',
        rarity: BadgeRarity.epic,
        category: BadgeCategory.wellness,
        xpReward: 800,
        progress: 0.33,
      ),

      // Social badges
      Badge(
        id: 'team_player',
        name: 'Team Player',
        description: 'Train with 10 different partners',
        iconName: 'groups',
        rarity: BadgeRarity.uncommon,
        category: BadgeCategory.social,
        xpReward: 200,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Badge(
        id: 'mentor',
        name: 'Mentor',
        description: 'Help 5 beginners in their journey',
        iconName: 'school',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.social,
        xpReward: 400,
        progress: 0.4,
      ),
    ]);
  }

  void _calculateXP() {
    _totalXP = unlockedBadges.fold(0, (sum, badge) => sum + badge.xpReward);
    _currentLevel = (_totalXP / 1000).floor() + 1;
  }

  /// Get progress summary
  BadgeProgress getProgress() {
    return BadgeProgress(
      totalBadges: _allBadges.length,
      unlockedBadges: unlockedBadges.length,
      totalXP: _totalXP,
      currentLevel: _currentLevel,
      levelProgress: (_totalXP % 1000) / 1000,
    );
  }

  /// Get badges by category
  List<Badge> getBadgesByCategory(BadgeCategory category) {
    return _allBadges.where((b) => b.category == category).toList();
  }

  /// Get recent badges (last 7 days)
  List<Badge> getRecentBadges() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return unlockedBadges
        .where((b) => b.unlockedAt != null && b.unlockedAt!.isAfter(weekAgo))
        .toList();
  }

  /// Unlock a badge
  void unlockBadge(String badgeId) {
    final index = _allBadges.indexWhere((b) => b.id == badgeId);
    if (index != -1 && !_allBadges[index].isUnlocked) {
      final badge = _allBadges[index];
      _allBadges[index] = Badge(
        id: badge.id,
        name: badge.name,
        description: badge.description,
        iconName: badge.iconName,
        rarity: badge.rarity,
        category: badge.category,
        xpReward: badge.xpReward,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
        progress: 1.0,
      );
      _calculateXP();
      notifyListeners();
      debugPrint('🏆 Badge unlocked: ${badge.name}');
    }
  }
}
