import 'dart:math';

/// ═══════════════════════════════════════════════════════════════════════════
/// TREND DETECTION SERVICE — Predictive Virality & Content Trend Engine
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Scores content for viral potential BEFORE publication. Identifies
/// trending topics across the DFC feed and predicts which posts will
/// break out based on engagement velocity, keyword momentum, and
/// time-series pattern matching.
///
/// Works alongside AutoFeedOrchestratorService but focuses on
/// PREDICTIVE scoring rather than post-hoc ranking.
/// ═══════════════════════════════════════════════════════════════════════════

enum TrendSignal {
  engagementVelocity('Engagement Velocity', 0.25),
  keywordMomentum('Keyword Momentum', 0.20),
  creatorAuthority('Creator Authority', 0.15),
  timingFit('Timing Fit', 0.15),
  contentFreshness('Content Freshness', 0.10),
  crossPlatformEcho('Cross-Platform Echo', 0.10),
  audienceMatch('Audience Match', 0.05);

  final String label;
  final double weight;
  const TrendSignal(this.label, this.weight);
}

enum ViralPotential {
  cold('Cold', 0, 20),
  warming('Warming', 20, 40),
  trending('Trending', 40, 60),
  hot('Hot', 60, 80),
  viral('Viral', 80, 100);

  final String label;
  final double min;
  final double max;
  const ViralPotential(this.label, this.min, this.max);

  static ViralPotential fromScore(double score) {
    if (score >= 80) return viral;
    if (score >= 60) return hot;
    if (score >= 40) return trending;
    if (score >= 20) return warming;
    return cold;
  }
}

class TrendTopic {
  final String keyword;
  final double momentum; // 0–100 velocity of mentions
  final int mentionCount;
  final int mentionDelta; // change from previous window
  final DateTime firstSeen;
  final DateTime lastSeen;

  const TrendTopic({
    required this.keyword,
    required this.momentum,
    required this.mentionCount,
    required this.mentionDelta,
    required this.firstSeen,
    required this.lastSeen,
  });

  bool get isBreakout => mentionDelta > mentionCount * 0.5 && momentum > 60;
}

class ContentViralityScore {
  final String contentId;
  final double overallScore; // 0–100
  final ViralPotential potential;
  final Map<TrendSignal, double> signalScores;
  final List<String> matchedTrends;
  final List<String> amplificationTips;
  final DateTime scoredAt;

  const ContentViralityScore({
    required this.contentId,
    required this.overallScore,
    required this.potential,
    required this.signalScores,
    required this.matchedTrends,
    required this.amplificationTips,
    required this.scoredAt,
  });

  Map<String, dynamic> toMap() => {
    'contentId': contentId,
    'overallScore': overallScore,
    'potential': potential.label,
    'signals': signalScores.map((k, v) => MapEntry(k.label, v)),
    'matchedTrends': matchedTrends,
    'tips': amplificationTips,
    'scoredAt': scoredAt.toIso8601String(),
  };
}

class EngagementSnapshot {
  final int likes;
  final int comments;
  final int shares;
  final int views;
  final Duration age; // how old the content is

  const EngagementSnapshot({
    required this.likes,
    required this.comments,
    required this.shares,
    required this.views,
    required this.age,
  });

  double get engagementRate =>
      views > 0 ? (likes + comments * 2 + shares * 3) / views * 100 : 0;
}

class ContentMetadata {
  final String contentId;
  final String title;
  final String body;
  final List<String> tags;
  final String authorId;
  final double authorFollowerCount;
  final bool authorVerified;
  final DateTime publishedAt;
  final EngagementSnapshot? engagement;

  const ContentMetadata({
    required this.contentId,
    required this.title,
    required this.body,
    required this.tags,
    required this.authorId,
    this.authorFollowerCount = 0,
    this.authorVerified = false,
    required this.publishedAt,
    this.engagement,
  });
}

class TrendDetectionService {
  TrendDetectionService._();
  static final TrendDetectionService instance = TrendDetectionService._();

  // ── Active combat sport trend keywords (seed list) ──
  static const _combatTrendKeywords = <String>[
    'UFC',
    'fight night',
    'knockout',
    'main event',
    'title fight',
    'weigh-in',
    'fight week',
    'press conference',
    'cage warriors',
    'bare knuckle',
    'BKFC',
    'ONE Championship',
    'PFL',
    'Bellator',
    'Jake Paul',
    'undercard',
    'co-main',
    'card',
    'PPV',
    'submission',
    'ground and pound',
    'TKO',
    'decision',
    'training camp',
    'sparring',
    'weight cut',
    'fight camp',
  ];

  final List<TrendTopic> _activeTrends = [];

  List<TrendTopic> get activeTrends => List.unmodifiable(_activeTrends);

  /// Score a piece of content for viral potential
  ContentViralityScore scoreContent(ContentMetadata content) {
    final signals = <TrendSignal, double>{};

    signals[TrendSignal.engagementVelocity] = _scoreEngagementVelocity(content);
    signals[TrendSignal.keywordMomentum] = _scoreKeywordMomentum(content);
    signals[TrendSignal.creatorAuthority] = _scoreCreatorAuthority(content);
    signals[TrendSignal.timingFit] = _scoreTimingFit(content);
    signals[TrendSignal.contentFreshness] = _scoreContentFreshness(content);
    signals[TrendSignal.crossPlatformEcho] = _scoreCrossPlatformEcho(content);
    signals[TrendSignal.audienceMatch] = _scoreAudienceMatch(content);

    final overall = signals.entries.fold<double>(
      0.0,
      (sum, e) => sum + e.value * e.key.weight,
    );

    final matchedTrends = _findMatchingTrends(content);
    final tips = _generateAmplificationTips(signals, matchedTrends);

    return ContentViralityScore(
      contentId: content.contentId,
      overallScore: overall.clamp(0, 100),
      potential: ViralPotential.fromScore(overall),
      signalScores: signals,
      matchedTrends: matchedTrends,
      amplificationTips: tips,
      scoredAt: DateTime.now(),
    );
  }

  /// Ingest engagement data to update trend topics
  void ingestEngagementBatch(List<ContentMetadata> recentContent) {
    final keywordCounts = <String, int>{};

    for (final c in recentContent) {
      final text = '${c.title} ${c.body}'.toLowerCase();
      for (final kw in _combatTrendKeywords) {
        if (text.contains(kw.toLowerCase())) {
          keywordCounts[kw] = (keywordCounts[kw] ?? 0) + 1;
        }
      }
      for (final tag in c.tags) {
        keywordCounts[tag] = (keywordCounts[tag] ?? 0) + 1;
      }
    }

    final now = DateTime.now();
    for (final entry in keywordCounts.entries) {
      final existingIdx = _activeTrends.indexWhere(
        (t) => t.keyword == entry.key,
      );
      if (existingIdx >= 0) {
        final old = _activeTrends[existingIdx];
        _activeTrends[existingIdx] = TrendTopic(
          keyword: entry.key,
          momentum: _computeMomentum(entry.value, old.mentionCount),
          mentionCount: old.mentionCount + entry.value,
          mentionDelta: entry.value,
          firstSeen: old.firstSeen,
          lastSeen: now,
        );
      } else {
        _activeTrends.add(
          TrendTopic(
            keyword: entry.key,
            momentum: min(100, entry.value * 15.0),
            mentionCount: entry.value,
            mentionDelta: entry.value,
            firstSeen: now,
            lastSeen: now,
          ),
        );
      }
    }

    // Decay stale trends (not seen in last batch)
    _activeTrends.removeWhere(
      (t) => now.difference(t.lastSeen).inHours > 24 && t.momentum < 20,
    );

    // Sort by momentum
    _activeTrends.sort((a, b) => b.momentum.compareTo(a.momentum));
  }

  /// Get breakout trends (sudden spikes)
  List<TrendTopic> getBreakoutTrends() =>
      _activeTrends.where((t) => t.isBreakout).toList();

  // ── Signal Scorers ────────────────────────────────────────────────────

  double _scoreEngagementVelocity(ContentMetadata content) {
    final eng = content.engagement;
    if (eng == null) return 30; // pre-publish neutral
    final minutes = eng.age.inMinutes;
    if (minutes <= 0) return 50;

    // Engagement per minute (weighted)
    final velocity = (eng.likes + eng.comments * 3 + eng.shares * 5) / minutes;

    // >10/min = viral, >5 = hot, >1 = trending
    if (velocity > 10) return 95;
    if (velocity > 5) return 80;
    if (velocity > 2) return 65;
    if (velocity > 1) return 50;
    if (velocity > 0.5) return 35;
    return 20;
  }

  double _scoreKeywordMomentum(ContentMetadata content) {
    if (_activeTrends.isEmpty) return 40;

    final text = '${content.title} ${content.body}'.toLowerCase();
    double topMatch = 0;
    for (final trend in _activeTrends.take(10)) {
      if (text.contains(trend.keyword.toLowerCase())) {
        topMatch = max(topMatch, trend.momentum);
      }
    }
    for (final tag in content.tags) {
      for (final trend in _activeTrends.take(10)) {
        if (tag.toLowerCase() == trend.keyword.toLowerCase()) {
          topMatch = max(topMatch, trend.momentum);
        }
      }
    }
    return topMatch;
  }

  double _scoreCreatorAuthority(ContentMetadata content) {
    double score = 30;
    if (content.authorVerified) score += 30;
    // Follower tiers
    final f = content.authorFollowerCount;
    if (f > 100000) {
      score += 40;
    } else if (f > 10000) {
      score += 30;
    } else if (f > 1000) {
      score += 20;
    } else if (f > 100) {
      score += 10;
    }
    return min(100, score);
  }

  double _scoreTimingFit(ContentMetadata content) {
    final hour = content.publishedAt.hour;
    // Peak engagement hours (US primetime + AU evening)
    if ((hour >= 18 && hour <= 22) || (hour >= 8 && hour <= 10)) {
      return 85;
    }
    if ((hour >= 12 && hour <= 14) || (hour >= 16 && hour <= 18)) {
      return 65;
    }
    return 40;
  }

  double _scoreContentFreshness(ContentMetadata content) {
    final age = DateTime.now().difference(content.publishedAt);
    if (age.inMinutes < 30) return 95;
    if (age.inHours < 2) return 80;
    if (age.inHours < 6) return 65;
    if (age.inHours < 24) return 45;
    return 20;
  }

  double _scoreCrossPlatformEcho(ContentMetadata content) {
    // Check if keywords appear across multiple trend sources
    final text = '${content.title} ${content.body}'.toLowerCase();
    int matches = 0;
    for (final kw in _combatTrendKeywords) {
      if (text.contains(kw.toLowerCase())) matches++;
    }
    if (matches >= 5) return 90;
    if (matches >= 3) return 70;
    if (matches >= 1) return 45;
    return 20;
  }

  double _scoreAudienceMatch(ContentMetadata content) {
    // Tags match combat sport taxonomy = high audience fit
    final combatTags = content.tags
        .where(
          (t) => _combatTrendKeywords.any(
            (kw) => kw.toLowerCase() == t.toLowerCase(),
          ),
        )
        .length;
    if (combatTags >= 3) return 90;
    if (combatTags >= 2) return 75;
    if (combatTags >= 1) return 55;
    return 30;
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  double _computeMomentum(int newCount, int oldTotal) {
    if (oldTotal == 0) return min(100, newCount * 20.0);
    final growth = newCount / oldTotal;
    return min(100, growth * 100);
  }

  List<String> _findMatchingTrends(ContentMetadata content) {
    final text = '${content.title} ${content.body}'.toLowerCase();
    final matched = <String>[];
    for (final trend in _activeTrends.take(20)) {
      if (text.contains(trend.keyword.toLowerCase()) ||
          content.tags.any(
            (t) => t.toLowerCase() == trend.keyword.toLowerCase(),
          )) {
        matched.add(trend.keyword);
      }
    }
    return matched;
  }

  List<String> _generateAmplificationTips(
    Map<TrendSignal, double> signals,
    List<String> matchedTrends,
  ) {
    final tips = <String>[];

    if (signals[TrendSignal.timingFit]! < 50) {
      tips.add('Consider scheduling for peak hours (6–10 PM) for 2x reach');
    }
    if (signals[TrendSignal.keywordMomentum]! < 40 && matchedTrends.isEmpty) {
      tips.add(
        'Add trending tags: ${_activeTrends.take(3).map((t) => "#${t.keyword}").join(", ")}',
      );
    }
    if (signals[TrendSignal.contentFreshness]! < 50) {
      tips.add('Content is aging — publish or boost within the next hour');
    }
    if (signals[TrendSignal.creatorAuthority]! < 50) {
      tips.add('Co-create with a verified creator to amplify reach');
    }
    if (signals[TrendSignal.engagementVelocity]! > 70) {
      tips.add(
        'Engagement velocity is HIGH — amplify now with cross-platform shares',
      );
    }

    if (tips.isEmpty) {
      tips.add('Content is well-positioned — maintain current strategy');
    }

    return tips;
  }
}
