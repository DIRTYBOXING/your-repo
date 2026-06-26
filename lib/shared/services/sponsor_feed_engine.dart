import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SPONSOR FEED ENGINE — Paid Content Priority & Revenue Pump
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Determines feed ordering based on paid sponsorships. Posts from paid
/// sponsors ALWAYS surface above organic content. Higher-tier sponsors
/// get better placement. This is how the platform monetizes the feed.
///
/// Tier Hierarchy (top → bottom):
///   1. PINNED (admin override) — Always #1
///   2. DIAMOND SPONSOR ($$$) — Premium placement + glow badge
///   3. GOLD SPONSOR ($$)    — Top 5 guaranteed
///   4. SILVER SPONSOR ($)   — Boosted above organic
///   5. PROMOTED POST         — Slight lift over organic
///   6. ORGANIC               — Normal chronological
///
/// Feed Injection Rules:
///   - Every 3rd card is a sponsor slot (configurable)
///   - Diamond gets hero banner every 12hr rotation window
///   - Gold gets card insert every 5 items
///   - Silver gets insert every 10 items
///   - Promoted gets a subtle "Promoted" badge, no position guarantee
///
/// Revenue Tracking:
///   - Impressions counted per sponsor per feed load
///   - Click-throughs tracked for ROI reporting
///   - Engagement metrics feed back into priority scoring
///
/// Firestore collections:
///   `sponsors`         — Sponsor profiles + tier
///   `sponsored_posts`  — Content linked to sponsors
///   `sponsor_metrics`  — Impressions, clicks, engagement
/// ═══════════════════════════════════════════════════════════════════════════

enum SponsorTier { diamond, gold, silver, promoted, organic }

class SponsorProfile {
  final String id;
  final String name;
  final String? logoUrl;
  final SponsorTier tier;
  final bool isActive;
  final DateTime? expiresAt;
  final String? websiteUrl;
  final String? tagline;
  final Map<String, dynamic> metadata;

  const SponsorProfile({
    required this.id,
    required this.name,
    this.logoUrl,
    this.tier = SponsorTier.organic,
    this.isActive = true,
    this.expiresAt,
    this.websiteUrl,
    this.tagline,
    this.metadata = const {},
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isPaid =>
      tier == SponsorTier.diamond ||
      tier == SponsorTier.gold ||
      tier == SponsorTier.silver;

  String get tierLabel {
    switch (tier) {
      case SponsorTier.diamond:
        return '💎 Diamond Sponsor';
      case SponsorTier.gold:
        return '🥇 Gold Sponsor';
      case SponsorTier.silver:
        return '🥈 Silver Sponsor';
      case SponsorTier.promoted:
        return 'Promoted';
      case SponsorTier.organic:
        return '';
    }
  }

  double get priorityWeight {
    switch (tier) {
      case SponsorTier.diamond:
        return 1.0;
      case SponsorTier.gold:
        return 0.85;
      case SponsorTier.silver:
        return 0.65;
      case SponsorTier.promoted:
        return 0.35;
      case SponsorTier.organic:
        return 0.0;
    }
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'logoUrl': logoUrl,
    'tier': tier.name,
    'isActive': isActive,
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'websiteUrl': websiteUrl,
    'tagline': tagline,
    'metadata': metadata,
  };

  factory SponsorProfile.fromMap(String id, Map<String, dynamic> map) {
    return SponsorProfile(
      id: id,
      name: map['name'] as String? ?? '',
      logoUrl: map['logoUrl'] as String?,
      tier: SponsorTier.values.firstWhere(
        (t) => t.name == (map['tier'] as String? ?? 'organic'),
        orElse: () => SponsorTier.organic,
      ),
      isActive: map['isActive'] as bool? ?? true,
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      websiteUrl: map['websiteUrl'] as String?,
      tagline: map['tagline'] as String?,
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map<dynamic, dynamic>? ?? {},
      ),
    );
  }
}

class SponsoredPost {
  final String id;
  final String sponsorId;
  final String title;
  final String? body;
  final String? imageUrl;
  final String? ctaText;
  final String? ctaUrl;
  final SponsorTier tier;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int impressions;
  final int clicks;

  const SponsoredPost({
    required this.id,
    required this.sponsorId,
    required this.title,
    this.body,
    this.imageUrl,
    this.ctaText,
    this.ctaUrl,
    this.tier = SponsorTier.organic,
    required this.createdAt,
    this.expiresAt,
    this.impressions = 0,
    this.clicks = 0,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  double get ctr => impressions > 0 ? clicks / impressions : 0.0;

  Map<String, dynamic> toMap() => {
    'sponsorId': sponsorId,
    'title': title,
    'body': body,
    'imageUrl': imageUrl,
    'ctaText': ctaText,
    'ctaUrl': ctaUrl,
    'tier': tier.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'impressions': impressions,
    'clicks': clicks,
  };

  factory SponsoredPost.fromMap(String id, Map<String, dynamic> map) {
    return SponsoredPost(
      id: id,
      sponsorId: map['sponsorId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String?,
      imageUrl: map['imageUrl'] as String?,
      ctaText: map['ctaText'] as String?,
      ctaUrl: map['ctaUrl'] as String?,
      tier: SponsorTier.values.firstWhere(
        (t) => t.name == (map['tier'] as String? ?? 'organic'),
        orElse: () => SponsorTier.organic,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      impressions: map['impressions'] as int? ?? 0,
      clicks: map['clicks'] as int? ?? 0,
    );
  }
}

/// ─── Sponsor Feed Engine (Singleton) ───────────────────────────────────

class SponsorFeedEngine extends ChangeNotifier {
  SponsorFeedEngine._();
  static final SponsorFeedEngine _instance = SponsorFeedEngine._();
  factory SponsorFeedEngine() => _instance;

  final _firestore = FirebaseFirestore.instance;
  final _random = math.Random();

  final List<SponsorProfile> _sponsors = [];
  final List<SponsoredPost> _sponsoredPosts = [];
  Timer? _refreshTimer;

  List<SponsorProfile> get activeSponsors =>
      _sponsors.where((s) => s.isActive && !s.isExpired).toList();
  List<SponsoredPost> get activePosts =>
      _sponsoredPosts.where((p) => !p.isExpired).toList();

  // ── Configuration ─────────────────────────────────────────────────────

  /// How many organic items between each sponsor slot
  static const int sponsorSlotInterval = 3;

  /// Max sponsored posts per feed load
  static const int maxSponsorCardsPerLoad = 5;

  /// Diamond sponsors get hero banner position
  static const bool diamondGetHeroBanner = true;

  // ── Initialization ────────────────────────────────────────────────────

  /// Load sponsors and posts from Firestore
  Future<void> initialize() async {
    try {
      final sponsorSnap = await _firestore
          .collection('sponsors')
          .where('isActive', isEqualTo: true)
          .get();

      _sponsors.clear();
      for (final doc in sponsorSnap.docs) {
        _sponsors.add(SponsorProfile.fromMap(doc.id, doc.data()));
      }

      final postSnap = await _firestore
          .collection('sponsored_posts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _sponsoredPosts.clear();
      for (final doc in postSnap.docs) {
        _sponsoredPosts.add(SponsoredPost.fromMap(doc.id, doc.data()));
      }

      _startAutoRefresh();
      notifyListeners();
      debugPrint(
        '[SponsorFeed] Loaded ${_sponsors.length} sponsors, ${_sponsoredPosts.length} posts',
      );
    } catch (e) {
      debugPrint('[SponsorFeed] Init error: $e');
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => initialize(),
    );
  }

  // ── Feed Integration ──────────────────────────────────────────────────

  /// THE PUMP: Injects sponsored content into an organic feed.
  ///
  /// Takes a list of organic items (news, posts, events) and returns
  /// a new list with sponsor cards injected at the correct intervals.
  ///
  /// Each returned item is a [FeedItem] wrapping either the original
  /// organic content or a sponsored post.
  List<FeedItem<T>> buildSponsoredFeed<T>(List<T> organicItems) {
    final feed = <FeedItem<T>>[];
    final sponsors = _getRotatedSponsorPosts();

    int sponsorIndex = 0;
    int organicIndex = 0;

    // Diamond hero banner at position 0
    if (diamondGetHeroBanner) {
      final diamondPost = sponsors
          .where((p) => p.tier == SponsorTier.diamond)
          .toList();
      if (diamondPost.isNotEmpty) {
        feed.add(FeedItem<T>.sponsored(diamondPost.first));
        sponsorIndex++;
      }
    }

    // Interleave organic + sponsored
    while (organicIndex < organicItems.length) {
      // Add organic items up to the next sponsor slot
      for (
        int i = 0;
        i < sponsorSlotInterval && organicIndex < organicItems.length;
        i++
      ) {
        feed.add(FeedItem<T>.organic(organicItems[organicIndex]));
        organicIndex++;
      }

      // Insert sponsor card if available
      if (sponsorIndex < sponsors.length &&
          sponsorIndex < maxSponsorCardsPerLoad) {
        feed.add(FeedItem<T>.sponsored(sponsors[sponsorIndex]));
        _trackImpression(sponsors[sponsorIndex].id);
        sponsorIndex++;
      }
    }

    return feed;
  }

  /// Returns sponsored posts sorted by tier priority, shuffled within tier
  List<SponsoredPost> _getRotatedSponsorPosts() {
    final posts = List<SponsoredPost>.from(activePosts);

    // Sort by tier weight (diamond first, then gold, silver, promoted)
    posts.sort((a, b) {
      final tierA = _tierWeight(a.tier);
      final tierB = _tierWeight(b.tier);
      if (tierA != tierB) return tierB.compareTo(tierA);
      // Within same tier, randomize for fairness
      return _random.nextBool() ? 1 : -1;
    });

    return posts;
  }

  double _tierWeight(SponsorTier tier) {
    switch (tier) {
      case SponsorTier.diamond:
        return 1.0;
      case SponsorTier.gold:
        return 0.85;
      case SponsorTier.silver:
        return 0.65;
      case SponsorTier.promoted:
        return 0.35;
      case SponsorTier.organic:
        return 0.0;
    }
  }

  // ── Ranking ───────────────────────────────────────────────────────────

  /// Calculate a feed priority score for ANY content item.
  /// Combines sponsor tier + boost score + freshness + engagement.
  double calculateFeedScore({
    required SponsorTier tier,
    double boostScore = 0.0,
    DateTime? publishedAt,
    int engagementCount = 0,
  }) {
    double score = 0.0;

    // Tier weight (0-40 points)
    score += _tierWeight(tier) * 40;

    // Boost score from ContentPriorityService (0-25 points)
    score += boostScore * 25;

    // Freshness decay (0-20 points) — newer = higher
    if (publishedAt != null) {
      final hoursSincePublish = DateTime.now().difference(publishedAt).inHours;
      final freshness = (1.0 - (hoursSincePublish / 168).clamp(0.0, 1.0));
      score += freshness * 20;
    }

    // Engagement bonus (0-15 points)
    final engagementBonus = (engagementCount / 100).clamp(0.0, 1.0);
    score += engagementBonus * 15;

    return score;
  }

  /// Sort a mixed feed by calculated priority score
  List<T> rankFeed<T>(
    List<T> items, {
    required SponsorTier Function(T) getTier,
    required DateTime? Function(T) getDate,
    double Function(T)? getBoost,
    int Function(T)? getEngagement,
  }) {
    final ranked = List<T>.from(items);
    ranked.sort((a, b) {
      final scoreA = calculateFeedScore(
        tier: getTier(a),
        boostScore: getBoost?.call(a) ?? 0.0,
        publishedAt: getDate(a),
        engagementCount: getEngagement?.call(a) ?? 0,
      );
      final scoreB = calculateFeedScore(
        tier: getTier(b),
        boostScore: getBoost?.call(b) ?? 0.0,
        publishedAt: getDate(b),
        engagementCount: getEngagement?.call(b) ?? 0,
      );
      return scoreB.compareTo(scoreA);
    });
    return ranked;
  }

  // ── Metrics ───────────────────────────────────────────────────────────

  /// Track an impression for a sponsored post
  Future<void> _trackImpression(String postId) async {
    try {
      await _firestore.collection('sponsored_posts').doc(postId).update({
        'impressions': FieldValue.increment(1),
      });
    } catch (e) {
      // Silent fail — metrics are non-critical
    }
  }

  /// Track a click on a sponsored post (call from UI)
  Future<void> trackClick(String postId) async {
    try {
      await _firestore.collection('sponsored_posts').doc(postId).update({
        'clicks': FieldValue.increment(1),
      });
      debugPrint('[SponsorFeed] Click tracked: $postId');
    } catch (e) {
      debugPrint('[SponsorFeed] Click track error: $e');
    }
  }

  /// Get ROI metrics for a sponsor
  Future<Map<String, dynamic>> getSponsorMetrics(String sponsorId) async {
    try {
      final snap = await _firestore
          .collection('sponsored_posts')
          .where('sponsorId', isEqualTo: sponsorId)
          .get();

      int totalImpressions = 0;
      int totalClicks = 0;
      for (final doc in snap.docs) {
        totalImpressions += (doc.data()['impressions'] as int?) ?? 0;
        totalClicks += (doc.data()['clicks'] as int?) ?? 0;
      }

      return {
        'sponsorId': sponsorId,
        'totalPosts': snap.docs.length,
        'totalImpressions': totalImpressions,
        'totalClicks': totalClicks,
        'avgCTR': totalImpressions > 0
            ? (totalClicks / totalImpressions * 100).toStringAsFixed(2)
            : '0.00',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Admin ─────────────────────────────────────────────────────────────

  /// Create a new sponsor (admin only)
  Future<String?> createSponsor(SponsorProfile profile) async {
    try {
      final doc = _firestore.collection('sponsors').doc();
      await doc.set(profile.toMap());
      _sponsors.add(
        SponsorProfile(
          id: doc.id,
          name: profile.name,
          logoUrl: profile.logoUrl,
          tier: profile.tier,
          isActive: profile.isActive,
          expiresAt: profile.expiresAt,
          websiteUrl: profile.websiteUrl,
          tagline: profile.tagline,
        ),
      );
      notifyListeners();
      return doc.id;
    } catch (e) {
      debugPrint('[SponsorFeed] Create sponsor error: $e');
      return null;
    }
  }

  /// Create a sponsored post
  Future<String?> createSponsoredPost(SponsoredPost post) async {
    try {
      final doc = _firestore.collection('sponsored_posts').doc();
      await doc.set(post.toMap());
      _sponsoredPosts.insert(
        0,
        SponsoredPost(
          id: doc.id,
          sponsorId: post.sponsorId,
          title: post.title,
          body: post.body,
          imageUrl: post.imageUrl,
          ctaText: post.ctaText,
          ctaUrl: post.ctaUrl,
          tier: post.tier,
          createdAt: post.createdAt,
          expiresAt: post.expiresAt,
        ),
      );
      notifyListeners();
      return doc.id;
    } catch (e) {
      debugPrint('[SponsorFeed] Create post error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.dispose();
  }
}

/// ─── Feed Item Wrapper ─────────────────────────────────────────────────

/// Wraps either an organic content item or a sponsored post
/// so the feed widget can render both in a single list.
class FeedItem<T> {
  final T? organicContent;
  final SponsoredPost? sponsoredPost;
  final bool isSponsored;

  const FeedItem._({
    this.organicContent,
    this.sponsoredPost,
    required this.isSponsored,
  });

  factory FeedItem.organic(T content) =>
      FeedItem._(organicContent: content, isSponsored: false);

  factory FeedItem.sponsored(SponsoredPost post) =>
      FeedItem._(sponsoredPost: post, isSponsored: true);
}
