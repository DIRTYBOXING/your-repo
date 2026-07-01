class FightStock {
  final String fighterId;
  final double value;
  final DateTime lastUpdated;

  FightStock({
    required this.fighterId,
    required this.value,
    required this.lastUpdated,
  });
}

class EngagementMetrics {
  final String contentId;
  final int likes;
  final int comments;
  final int shares;

  EngagementMetrics({
    required this.contentId,
    required this.likes,
    required this.comments,
    required this.shares,
  });
}

class UserActivity {
  final String userId;
  final String activityType;
  final DateTime timestamp;

  UserActivity({
    required this.userId,
    required this.activityType,
    required this.timestamp,
  });
}

class AdPerformance {
  final String adId;
  final int impressions;
  final int clicks;

  AdPerformance({
    required this.adId,
    required this.impressions,
    required this.clicks,
  });
}

class AIRecommendation {
  final String userId;
  final String recommendationType;
  final String recommendedContentId;

  AIRecommendation({
    required this.userId,
    required this.recommendationType,
    required this.recommendedContentId,
  });
}
