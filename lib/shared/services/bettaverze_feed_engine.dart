// ═══════════════════════════════════════════════════════════════════════════
// BETTAVERZE FEED ENGINE — Next-Gen AI Feed Algorithm
// ═══════════════════════════════════════════════════════════════════════════
//
// Multi-signal feed ranking that surpasses legacy social platforms:
//  • Engagement prediction — estimates virality before content trends
//  • Content diversity enforcement — prevents echo chambers
//  • Freshness decay — time-weighted scoring avoids stale feeds
//  • Creator affinity — learns user preferences across content types
//  • Social proximity — weighs close connections over weak ties
//  • Wellbeing adjustment — reduces rage-bait and doomscroll patterns
//
// Feeds the existing FeedPrioritizationService with ML-grade signals.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math';

// ─── Signal weights (tuned for positive engagement) ─────────────────────

enum FeedSignal {
  engagementPrediction(0.22, 'Predicted engagement rate'),
  creatorAffinity(0.18, 'User-creator relationship strength'),
  socialProximity(0.16, 'Connection closeness score'),
  contentDiversity(0.14, 'Category variety enforcement'),
  freshness(0.12, 'Time decay factor'),
  contentQuality(0.10, 'Post quality indicators'),
  wellbeingGuard(0.08, 'Anti-doomscroll adjustment');

  final double weight;
  final String description;
  const FeedSignal(this.weight, this.description);
}

enum ContentCategory {
  combatHighlight('Combat Highlight', '🥊'),
  trainingTip('Training Tip', '💪'),
  newsUpdate('News Update', '📰'),
  communityPost('Community Post', '👥'),
  creatorContent('Creator Content', '🎬'),
  eventPromo('Event Promo', '🎟️'),
  meme('Meme / Humor', '😂'),
  personalUpdate('Personal Update', '💬'),
  marketplace('Marketplace', '🛒'),
  educational('Educational', '📚'),
  liveStream('Live Stream', '🔴'),
  poll('Poll / Question', '📊');

  final String label;
  final String emoji;
  const ContentCategory(this.label, this.emoji);
}

enum FeedQuality {
  exceptional(90, 100, 'Top-tier content'),
  high(70, 89, 'Strong engagement expected'),
  standard(40, 69, 'Normal feed content'),
  low(15, 39, 'Below average signals'),
  suppressed(0, 14, 'Doomscroll or low quality');

  final int minScore;
  final int maxScore;
  final String description;
  const FeedQuality(this.minScore, this.maxScore, this.description);

  static FeedQuality fromScore(double score) {
    final s = score.round();
    if (s >= 90) return exceptional;
    if (s >= 70) return high;
    if (s >= 40) return standard;
    if (s >= 15) return low;
    return suppressed;
  }
}

// ─── Models ─────────────────────────────────────────────────────────────

class FeedCandidate {
  final String postId;
  final String authorId;
  final ContentCategory category;
  final DateTime publishedAt;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final bool hasMedia;
  final bool isPremium;
  final bool isVerified;
  final double? authorTrustScore;
  final List<String> hashtags;
  final int wordCount;
  final double? sentimentScore; // -1.0 negative to 1.0 positive

  const FeedCandidate({
    required this.postId,
    required this.authorId,
    required this.category,
    required this.publishedAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.viewCount = 0,
    this.hasMedia = false,
    this.isPremium = false,
    this.isVerified = false,
    this.authorTrustScore,
    this.hashtags = const [],
    this.wordCount = 0,
    this.sentimentScore,
  });
}

class UserFeedProfile {
  final String userId;
  final Map<ContentCategory, double> categoryPreferences;
  final Set<String> followedCreators;
  final Set<String> closeFriends;
  final Set<String> mutedAuthors;
  final Set<String> blockedAuthors;
  final int dailySessionCount;
  final Duration avgSessionDuration;
  final Map<String, double> creatorAffinityScores;
  final DateTime lastFeedRefresh;

  const UserFeedProfile({
    required this.userId,
    this.categoryPreferences = const {},
    this.followedCreators = const {},
    this.closeFriends = const {},
    this.mutedAuthors = const {},
    this.blockedAuthors = const {},
    this.dailySessionCount = 0,
    this.avgSessionDuration = Duration.zero,
    this.creatorAffinityScores = const {},
    required this.lastFeedRefresh,
  });
}

class ScoredFeedItem {
  final FeedCandidate candidate;
  final double totalScore;
  final FeedQuality quality;
  final Map<FeedSignal, double> signalBreakdown;
  final String? boostReason;
  final bool diversityBoosted;

  const ScoredFeedItem({
    required this.candidate,
    required this.totalScore,
    required this.quality,
    required this.signalBreakdown,
    this.boostReason,
    this.diversityBoosted = false,
  });

  Map<String, dynamic> toMap() => {
    'postId': candidate.postId,
    'totalScore': totalScore,
    'quality': quality.name,
    'diversityBoosted': diversityBoosted,
    'boostReason': boostReason,
    'signals': signalBreakdown.map((k, v) => MapEntry(k.name, v)),
  };
}

class FeedResult {
  final List<ScoredFeedItem> items;
  final int totalCandidates;
  final int filtered;
  final Map<ContentCategory, int> categoryDistribution;
  final double avgQuality;
  final DateTime generatedAt;

  const FeedResult({
    required this.items,
    required this.totalCandidates,
    required this.filtered,
    required this.categoryDistribution,
    required this.avgQuality,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() => {
    'itemCount': items.length,
    'totalCandidates': totalCandidates,
    'filtered': filtered,
    'avgQuality': avgQuality,
    'categoryDistribution': categoryDistribution.map(
      (k, v) => MapEntry(k.name, v),
    ),
    'generatedAt': generatedAt.toIso8601String(),
  };
}

// ─── Engine ─────────────────────────────────────────────────────────────

class BettaverzeFeedEngine {
  BettaverzeFeedEngine._();
  static final BettaverzeFeedEngine instance = BettaverzeFeedEngine._();

  // Diversity config: max percentage any single category can occupy
  static const double _maxCategoryRatio = 0.30;
  // Freshness half-life in hours
  static const double _freshnessHalfLifeHours = 6.0;
  // Minimum engagement rate to predict virality
  static const double _viralThreshold = 0.08;
  // Wellbeing: suppress content with very negative sentiment
  static const double _negativeSentimentThreshold = -0.6;
  // Doomscroll protection: reduce score after N consecutive negative items
  static const int _doomscrollWindow = 3;

  /// Rank a batch of candidates for a user's personalized feed.
  FeedResult rankFeed({
    required List<FeedCandidate> candidates,
    required UserFeedProfile profile,
    int limit = 50,
  }) {
    // Phase 1: Filter blocked/muted
    final filtered = candidates.where((c) {
      if (profile.blockedAuthors.contains(c.authorId)) return false;
      if (profile.mutedAuthors.contains(c.authorId)) return false;
      return true;
    }).toList();

    final filteredCount = candidates.length - filtered.length;

    // Phase 2: Score each candidate
    final scored = filtered.map((c) => _scoreCandidate(c, profile)).toList();

    // Phase 3: Diversity enforcement
    final diversified = _enforceDiversity(scored, limit);

    // Phase 4: Wellbeing check — break up negative content runs
    final reordered = _wellbeingReorder(diversified);

    // Phase 5: Build category distribution
    final catDist = <ContentCategory, int>{};
    for (final item in reordered) {
      catDist[item.candidate.category] =
          (catDist[item.candidate.category] ?? 0) + 1;
    }

    final avgQ = reordered.isEmpty
        ? 0.0
        : reordered.map((i) => i.totalScore).reduce((a, b) => a + b) /
              reordered.length;

    return FeedResult(
      items: reordered,
      totalCandidates: candidates.length,
      filtered: filteredCount,
      categoryDistribution: catDist,
      avgQuality: avgQ,
      generatedAt: DateTime.now(),
    );
  }

  ScoredFeedItem _scoreCandidate(FeedCandidate c, UserFeedProfile profile) {
    final signals = <FeedSignal, double>{};

    // 1. Engagement prediction
    signals[FeedSignal.engagementPrediction] = _predictEngagement(c);

    // 2. Creator affinity
    signals[FeedSignal.creatorAffinity] = _scoreCreatorAffinity(c, profile);

    // 3. Social proximity
    signals[FeedSignal.socialProximity] = _scoreSocialProximity(c, profile);

    // 4. Content diversity (neutral — adjusted in post-processing)
    signals[FeedSignal.contentDiversity] = _scoreCategoryPreference(c, profile);

    // 5. Freshness
    signals[FeedSignal.freshness] = _scoreFreshness(c);

    // 6. Content quality
    signals[FeedSignal.contentQuality] = _scoreContentQuality(c);

    // 7. Wellbeing guard
    signals[FeedSignal.wellbeingGuard] = _scoreWellbeing(c);

    // Weighted total
    double total = 0;
    for (final entry in signals.entries) {
      total += entry.value * entry.key.weight;
    }

    // Premium boost (additive, not multiplicative — fair but visible)
    String? boostReason;
    if (c.isPremium) {
      total += 8.0;
      boostReason = 'Premium creator boost';
    }
    if (c.isVerified) {
      total += 3.0;
      boostReason = (boostReason != null)
          ? '$boostReason + Verified'
          : 'Verified creator';
    }

    total = total.clamp(0, 100).toDouble();

    return ScoredFeedItem(
      candidate: c,
      totalScore: total,
      quality: FeedQuality.fromScore(total),
      signalBreakdown: signals,
      boostReason: boostReason,
    );
  }

  // ─── Signal Scorers ───────────────────────────────────────────────────

  double _predictEngagement(FeedCandidate c) {
    if (c.viewCount == 0) return 50.0; // New content gets neutral score
    final totalEngagement = c.likeCount + c.commentCount * 2 + c.shareCount * 3;
    final engagementRate = totalEngagement / max(c.viewCount, 1);

    if (engagementRate >= _viralThreshold) return 95.0;
    if (engagementRate >= 0.05) return 80.0;
    if (engagementRate >= 0.02) return 60.0;
    if (engagementRate >= 0.01) return 40.0;
    return 20.0;
  }

  double _scoreCreatorAffinity(FeedCandidate c, UserFeedProfile profile) {
    if (profile.closeFriends.contains(c.authorId)) return 100.0;
    if (profile.followedCreators.contains(c.authorId)) return 75.0;
    final affinity = profile.creatorAffinityScores[c.authorId];
    if (affinity != null) return (affinity * 100).clamp(0, 100);
    return 30.0; // Unknown creators get discovery score
  }

  double _scoreSocialProximity(FeedCandidate c, UserFeedProfile profile) {
    if (profile.closeFriends.contains(c.authorId)) return 100.0;
    if (profile.followedCreators.contains(c.authorId)) return 60.0;
    return 20.0; // Weak tie or algorithmic discovery
  }

  double _scoreCategoryPreference(FeedCandidate c, UserFeedProfile profile) {
    final pref = profile.categoryPreferences[c.category];
    if (pref != null) return (pref * 100).clamp(0, 100);
    return 50.0; // Neutral for unknown preferences
  }

  double _scoreFreshness(FeedCandidate c) {
    final ageHours = DateTime.now().difference(c.publishedAt).inMinutes / 60.0;
    if (ageHours <= 0) return 100.0;
    // Exponential decay with half-life
    final decay = pow(0.5, ageHours / _freshnessHalfLifeHours).toDouble();
    return (decay * 100).clamp(0, 100);
  }

  double _scoreContentQuality(FeedCandidate c) {
    double score = 40.0; // Baseline
    if (c.hasMedia) score += 15.0;
    if (c.wordCount > 20 && c.wordCount < 500) score += 10.0;
    if (c.hashtags.isNotEmpty && c.hashtags.length <= 5) score += 5.0;
    if (c.isVerified) score += 10.0;
    if (c.authorTrustScore != null) {
      score += (c.authorTrustScore! * 20).clamp(0, 20);
    }
    return score.clamp(0, 100);
  }

  double _scoreWellbeing(FeedCandidate c) {
    if (c.sentimentScore == null) return 70.0; // Neutral assumption
    if (c.sentimentScore! < _negativeSentimentThreshold) return 10.0;
    if (c.sentimentScore! < -0.3) return 40.0;
    if (c.sentimentScore! > 0.5) return 90.0;
    return 60.0;
  }

  // ─── Post-Processing ──────────────────────────────────────────────────

  List<ScoredFeedItem> _enforceDiversity(
    List<ScoredFeedItem> items,
    int limit,
  ) {
    // Sort by score descending
    final sorted = List<ScoredFeedItem>.from(items)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    final result = <ScoredFeedItem>[];
    final catCounts = <ContentCategory, int>{};

    for (final item in sorted) {
      if (result.length >= limit) break;

      final cat = item.candidate.category;
      final count = catCounts[cat] ?? 0;
      final maxForCat = (limit * _maxCategoryRatio).ceil();

      if (count >= maxForCat) {
        // Category saturated — skip or add with diversity flag
        continue;
      }

      catCounts[cat] = count + 1;
      result.add(item);
    }

    // If we have room, fill with remaining items (diversity-boosted)
    if (result.length < limit) {
      for (final item in sorted) {
        if (result.length >= limit) break;
        if (result.any((r) => r.candidate.postId == item.candidate.postId)) {
          continue;
        }
        result.add(
          ScoredFeedItem(
            candidate: item.candidate,
            totalScore: item.totalScore,
            quality: item.quality,
            signalBreakdown: item.signalBreakdown,
            boostReason: item.boostReason,
            diversityBoosted: true,
          ),
        );
      }
    }

    return result;
  }

  List<ScoredFeedItem> _wellbeingReorder(List<ScoredFeedItem> items) {
    if (items.length < _doomscrollWindow + 1) return items;

    final result = List<ScoredFeedItem>.from(items);

    // Scan for runs of negative sentiment and inject positive content
    for (int i = _doomscrollWindow; i < result.length; i++) {
      int negativeRun = 0;
      for (int j = i - _doomscrollWindow; j < i; j++) {
        final sentiment = result[j].candidate.sentimentScore;
        if (sentiment != null && sentiment < -0.3) negativeRun++;
      }

      if (negativeRun >= _doomscrollWindow) {
        // Find next positive item and swap
        for (int k = i + 1; k < result.length; k++) {
          final sentiment = result[k].candidate.sentimentScore;
          if (sentiment != null && sentiment > 0.3) {
            final temp = result[k];
            result[k] = result[i];
            result[i] = temp;
            break;
          }
        }
      }
    }

    return result;
  }

  /// Explain why a specific post appears in the feed (transparency).
  String explainRanking(ScoredFeedItem item) {
    final signals = item.signalBreakdown.entries.toList()
      ..sort(
        (a, b) => (b.value * b.key.weight).compareTo(a.value * a.key.weight),
      );

    final topSignal = signals.first;
    final buf = StringBuffer();
    buf.write('This post scored ${item.totalScore.toStringAsFixed(1)}/100. ');
    buf.write('Top signal: ${topSignal.key.description} ');
    buf.write('(${topSignal.value.toStringAsFixed(0)}). ');

    if (item.boostReason != null) {
      buf.write('Boost: ${item.boostReason}. ');
    }
    if (item.diversityBoosted) {
      buf.write('Added for feed variety. ');
    }

    return buf.toString().trim();
  }
}
