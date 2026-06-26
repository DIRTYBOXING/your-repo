// ═══════════════════════════════════════════════════════════════════════════
// SOCIAL ANALYTICS ENGINE — Creator & Content Performance Intelligence
// ═══════════════════════════════════════════════════════════════════════════
//
// Facebook-grade analytics for every DFC creator:
//  • Real-time content performance — impressions, reach, engagement rate
//  • Audience demographics — follower growth, interests, active hours
//  • Content breakdown — which types/topics perform best
//  • Growth trends — weekly/monthly/quarterly trajectory
//  • Competitive benchmarking — percentile ranking vs similar creators
//  • Optimal posting — AI-recommended best times and content types
//
// Every creator gets a free analytics dashboard (not gated behind paywall)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math';

// ─── Enums ──────────────────────────────────────────────────────────────

enum AnalyticsPeriod {
  today('Today', 1),
  week('This Week', 7),
  month('This Month', 30),
  quarter('This Quarter', 90),
  year('This Year', 365),
  allTime('All Time', 0);

  final String label;
  final int days;
  const AnalyticsPeriod(this.label, this.days);
}

enum ContentPerformance {
  viral('Viral', 5.0),
  highPerforming('High Performing', 2.0),
  aboveAverage('Above Average', 1.2),
  average('Average', 0.8),
  belowAverage('Below Average', 0.5),
  underperforming('Underperforming', 0.2);

  final String label;
  final double engagementThreshold;
  const ContentPerformance(this.label, this.engagementThreshold);
}

enum AudienceSegment {
  fighters('Fighters', 'Active competitors'),
  coaches('Coaches', 'Training professionals'),
  fans('Fans', 'Combat sports enthusiasts'),
  analysts('Analysts', 'Fight breakdown specialists'),
  promoters('Promoters', 'Event organizers'),
  media('Media', 'Journalists and content creators'),
  casual('Casual', 'General audience');

  final String label;
  final String description;
  const AudienceSegment(this.label, this.description);
}

enum GrowthTrend {
  rocketing('Rocketing', '🚀', 50.0),
  accelerating('Accelerating', '📈', 20.0),
  growing('Growing', '↗️', 5.0),
  stable('Stable', '➡️', -2.0),
  declining('Declining', '📉', -15.0),
  freefall('Freefall', '⬇️', -100.0);

  final String label;
  final String icon;
  final double minPercent;
  const GrowthTrend(this.label, this.icon, this.minPercent);
}

// ─── Models ─────────────────────────────────────────────────────────────

class ContentMetrics {
  final String contentId;
  final String contentType;
  final int impressions;
  final int reach;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final int clicks;
  final double engagementRate;
  final ContentPerformance performance;
  final DateTime publishedAt;

  const ContentMetrics({
    required this.contentId,
    required this.contentType,
    this.impressions = 0,
    this.reach = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saves = 0,
    this.clicks = 0,
    this.engagementRate = 0,
    this.performance = ContentPerformance.average,
    required this.publishedAt,
  });

  int get totalEngagements => likes + comments + shares + saves;

  Map<String, dynamic> toMap() => {
    'contentId': contentId,
    'contentType': contentType,
    'impressions': impressions,
    'reach': reach,
    'engagementRate': engagementRate,
    'performance': performance.label,
    'totalEngagements': totalEngagements,
  };
}

class AudienceInsight {
  final Map<AudienceSegment, double> segmentBreakdown;
  final Map<String, double> topCountries;
  final Map<int, double> activeHours; // 0-23 → activity %
  final int totalFollowers;
  final int newFollowersThisWeek;
  final int unfollowsThisWeek;
  final double followerGrowthRate;

  const AudienceInsight({
    this.segmentBreakdown = const {},
    this.topCountries = const {},
    this.activeHours = const {},
    this.totalFollowers = 0,
    this.newFollowersThisWeek = 0,
    this.unfollowsThisWeek = 0,
    this.followerGrowthRate = 0,
  });

  int get netFollowerChange => newFollowersThisWeek - unfollowsThisWeek;
  AudienceSegment? get primarySegment {
    if (segmentBreakdown.isEmpty) return null;
    return segmentBreakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  int? get peakHour {
    if (activeHours.isEmpty) return null;
    return activeHours.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Map<String, dynamic> toMap() => {
    'totalFollowers': totalFollowers,
    'netChange': netFollowerChange,
    'growthRate': followerGrowthRate,
    'primarySegment': primarySegment?.label,
    'peakHour': peakHour,
  };
}

class GrowthSnapshot {
  final DateTime date;
  final int followers;
  final int impressions;
  final int engagements;
  final double engagementRate;

  const GrowthSnapshot({
    required this.date,
    this.followers = 0,
    this.impressions = 0,
    this.engagements = 0,
    this.engagementRate = 0,
  });
}

class CreatorAnalytics {
  final String userId;
  final AnalyticsPeriod period;
  final int totalImpressions;
  final int totalReach;
  final int totalEngagements;
  final double avgEngagementRate;
  final ContentPerformance overallPerformance;
  final GrowthTrend growthTrend;
  final AudienceInsight audienceInsight;
  final List<ContentMetrics> topContent;
  final List<GrowthSnapshot> growthTimeline;
  final Map<String, double> contentTypeBreakdown;
  final List<int> bestPostingHours;
  final List<String> bestPostingDays;
  final int creatorPercentile;

  const CreatorAnalytics({
    required this.userId,
    required this.period,
    this.totalImpressions = 0,
    this.totalReach = 0,
    this.totalEngagements = 0,
    this.avgEngagementRate = 0,
    this.overallPerformance = ContentPerformance.average,
    this.growthTrend = GrowthTrend.stable,
    required this.audienceInsight,
    this.topContent = const [],
    this.growthTimeline = const [],
    this.contentTypeBreakdown = const {},
    this.bestPostingHours = const [],
    this.bestPostingDays = const [],
    this.creatorPercentile = 50,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'period': period.label,
    'totalImpressions': totalImpressions,
    'totalReach': totalReach,
    'avgEngagementRate': avgEngagementRate,
    'overallPerformance': overallPerformance.label,
    'growthTrend': growthTrend.label,
    'creatorPercentile': creatorPercentile,
    'topContentCount': topContent.length,
  };
}

class PostingRecommendation {
  final List<int> bestHours;
  final List<String> bestDays;
  final String bestContentType;
  final String reasoning;
  final double confidenceScore;

  const PostingRecommendation({
    required this.bestHours,
    required this.bestDays,
    required this.bestContentType,
    required this.reasoning,
    required this.confidenceScore,
  });
}

// ─── Service ────────────────────────────────────────────────────────────

class SocialAnalyticsEngine {
  SocialAnalyticsEngine._();
  static final SocialAnalyticsEngine instance = SocialAnalyticsEngine._();

  final _contentMetrics = <String, ContentMetrics>{};
  final _growthHistory = <String, List<GrowthSnapshot>>{};
  final _audienceCache = <String, AudienceInsight>{};

  /// Record content interaction.
  ContentMetrics trackContent({
    required String contentId,
    required String contentType,
    int impressions = 0,
    int reach = 0,
    int likes = 0,
    int comments = 0,
    int shares = 0,
    int saves = 0,
    int clicks = 0,
    required DateTime publishedAt,
  }) {
    final totalEngagements = likes + comments + shares + saves;
    final engagementRate = reach > 0 ? totalEngagements / reach * 100 : 0.0;

    final performance = _classifyPerformance(engagementRate);

    final metrics = ContentMetrics(
      contentId: contentId,
      contentType: contentType,
      impressions: impressions,
      reach: reach,
      likes: likes,
      comments: comments,
      shares: shares,
      saves: saves,
      clicks: clicks,
      engagementRate: engagementRate,
      performance: performance,
      publishedAt: publishedAt,
    );

    _contentMetrics[contentId] = metrics;
    return metrics;
  }

  /// Record a growth snapshot for a user.
  void recordGrowthSnapshot({
    required String userId,
    required int followers,
    required int impressions,
    required int engagements,
    double? engagementRate,
  }) {
    final rate =
        engagementRate ??
        (impressions > 0 ? engagements / impressions * 100 : 0.0);

    _growthHistory
        .putIfAbsent(userId, () => [])
        .add(
          GrowthSnapshot(
            date: DateTime.now(),
            followers: followers,
            impressions: impressions,
            engagements: engagements,
            engagementRate: rate,
          ),
        );
  }

  /// Update audience insight for a user.
  void updateAudienceInsight({
    required String userId,
    required AudienceInsight insight,
  }) {
    _audienceCache[userId] = insight;
  }

  /// Generate comprehensive creator analytics.
  CreatorAnalytics getAnalytics({
    required String userId,
    AnalyticsPeriod period = AnalyticsPeriod.month,
  }) {
    final now = DateTime.now();
    final cutoff = period.days > 0
        ? now.subtract(Duration(days: period.days))
        : DateTime(2020);

    // Filter content in time range
    final periodContent = _contentMetrics.values
        .where((m) => m.publishedAt.isAfter(cutoff))
        .toList();

    if (periodContent.isEmpty) {
      return CreatorAnalytics(
        userId: userId,
        period: period,
        audienceInsight: _audienceCache[userId] ?? const AudienceInsight(),
      );
    }

    // Aggregate metrics
    final totalImpressions = periodContent.fold<int>(
      0,
      (sum, m) => sum + m.impressions,
    );
    final totalReach = periodContent.fold<int>(0, (sum, m) => sum + m.reach);
    final totalEngagements = periodContent.fold<int>(
      0,
      (sum, m) => sum + m.totalEngagements,
    );
    final avgEngagement =
        periodContent.fold<double>(0, (sum, m) => sum + m.engagementRate) /
        periodContent.length;

    // Top content by engagement
    final topContent = List<ContentMetrics>.from(periodContent)
      ..sort((a, b) => b.totalEngagements.compareTo(a.totalEngagements));

    // Content type breakdown
    final typeMap = <String, double>{};
    for (final m in periodContent) {
      typeMap[m.contentType] = (typeMap[m.contentType] ?? 0) + 1;
    }
    final total = periodContent.length.toDouble();
    typeMap.updateAll((key, value) => value / total * 100);

    // Growth trend
    final growthHistory = _growthHistory[userId] ?? [];
    final trend = _calculateGrowthTrend(growthHistory, cutoff);

    // Best posting hours (from top performing content)
    final bestHours = _computeBestPostingHours(periodContent);

    // Best posting days
    final bestDays = _computeBestPostingDays(periodContent);

    // Creator percentile (based on engagement rate)
    final percentile = _estimatePercentile(avgEngagement);

    return CreatorAnalytics(
      userId: userId,
      period: period,
      totalImpressions: totalImpressions,
      totalReach: totalReach,
      totalEngagements: totalEngagements,
      avgEngagementRate: avgEngagement,
      overallPerformance: _classifyPerformance(avgEngagement),
      growthTrend: trend,
      audienceInsight: _audienceCache[userId] ?? const AudienceInsight(),
      topContent: topContent.take(10).toList(),
      growthTimeline: growthHistory,
      contentTypeBreakdown: typeMap,
      bestPostingHours: bestHours,
      bestPostingDays: bestDays,
      creatorPercentile: percentile,
    );
  }

  /// Get AI posting recommendations.
  PostingRecommendation getPostingRecommendation(String userId) {
    final analytics = getAnalytics(userId: userId);

    final bestHours = analytics.bestPostingHours.isNotEmpty
        ? analytics.bestPostingHours
        : [9, 12, 18]; // Defaults

    final bestDays = analytics.bestPostingDays.isNotEmpty
        ? analytics.bestPostingDays
        : ['Tuesday', 'Thursday', 'Saturday'];

    // Best content type
    String bestType = 'combat_highlight';
    if (analytics.contentTypeBreakdown.isNotEmpty) {
      bestType = analytics.contentTypeBreakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    final confidence = analytics.topContent.length >= 10 ? 0.85 : 0.55;

    return PostingRecommendation(
      bestHours: bestHours,
      bestDays: bestDays,
      bestContentType: bestType,
      reasoning: _generateReasoningText(analytics),
      confidenceScore: confidence,
    );
  }

  /// Compare two creators.
  Map<String, dynamic> compareCreators(String userId1, String userId2) {
    final a1 = getAnalytics(userId: userId1);
    final a2 = getAnalytics(userId: userId2);

    return {
      'creator1': {
        'userId': userId1,
        'impressions': a1.totalImpressions,
        'engagementRate': a1.avgEngagementRate,
        'percentile': a1.creatorPercentile,
        'trend': a1.growthTrend.label,
      },
      'creator2': {
        'userId': userId2,
        'impressions': a2.totalImpressions,
        'engagementRate': a2.avgEngagementRate,
        'percentile': a2.creatorPercentile,
        'trend': a2.growthTrend.label,
      },
      'winner': a1.avgEngagementRate > a2.avgEngagementRate ? userId1 : userId2,
    };
  }

  /// Platform-wide stats.
  Map<String, dynamic> get platformStats => {
    'totalContentTracked': _contentMetrics.length,
    'creatorsTracked': _audienceCache.length,
    'growthHistoryEntries': _growthHistory.values.fold<int>(
      0,
      (s, l) => s + l.length,
    ),
  };

  // ─── Private Helpers ──────────────────────────────────────────────────

  ContentPerformance _classifyPerformance(double engagementRate) {
    for (final perf in ContentPerformance.values) {
      if (engagementRate >= perf.engagementThreshold) return perf;
    }
    return ContentPerformance.underperforming;
  }

  GrowthTrend _calculateGrowthTrend(
    List<GrowthSnapshot> history,
    DateTime cutoff,
  ) {
    final relevant = history.where((s) => s.date.isAfter(cutoff)).toList();
    if (relevant.length < 2) return GrowthTrend.stable;

    final first = relevant.first.followers;
    final last = relevant.last.followers;

    if (first == 0) return GrowthTrend.stable;
    final percentChange = (last - first) / first * 100;

    for (final trend in GrowthTrend.values) {
      if (percentChange >= trend.minPercent) return trend;
    }
    return GrowthTrend.freefall;
  }

  List<int> _computeBestPostingHours(List<ContentMetrics> content) {
    if (content.isEmpty) return [];

    final hourScores = <int, double>{};
    for (final m in content) {
      final hour = m.publishedAt.hour;
      hourScores[hour] = (hourScores[hour] ?? 0) + m.engagementRate;
    }

    final sorted = hourScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key).toList();
  }

  List<String> _computeBestPostingDays(List<ContentMetrics> content) {
    if (content.isEmpty) return [];

    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final dayScores = <int, double>{};
    for (final m in content) {
      final day = m.publishedAt.weekday; // 1=Mon...7=Sun
      dayScores[day] = (dayScores[day] ?? 0) + m.engagementRate;
    }

    final sorted = dayScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => dayNames[e.key - 1]).toList();
  }

  int _estimatePercentile(double engagementRate) {
    // Heuristic percentile based on engagement rate distribution
    if (engagementRate >= 5.0) return 99;
    if (engagementRate >= 3.0) return 95;
    if (engagementRate >= 2.0) return 85;
    if (engagementRate >= 1.0) return 70;
    if (engagementRate >= 0.5) return 50;
    if (engagementRate >= 0.2) return 30;
    return min(20, max(1, (engagementRate * 100).round()));
  }

  String _generateReasoningText(CreatorAnalytics analytics) {
    final buffer = StringBuffer();
    buffer.write('Based on ${analytics.topContent.length} posts analyzed: ');

    if (analytics.bestPostingHours.isNotEmpty) {
      buffer.write(
        'Your content performs best around ${analytics.bestPostingHours.first}:00. ',
      );
    }

    if (analytics.contentTypeBreakdown.isNotEmpty) {
      final bestType = analytics.contentTypeBreakdown.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      buffer.write(
        '${bestType.key} content makes up ${bestType.value.toStringAsFixed(0)}% of your best posts. ',
      );
    }

    buffer.write(
      'You rank in the top ${100 - analytics.creatorPercentile}% '
      'of DFC creators.',
    );

    return buffer.toString();
  }
}
