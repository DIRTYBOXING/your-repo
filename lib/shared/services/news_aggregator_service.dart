// ═══════════════════════════════════════════════════════════════════════════
// DFC NEWS AGGREGATOR 2.0 SERVICE
// ═══════════════════════════════════════════════════════════════════════════
// Automatic multi-source combat sports news aggregation with trust scoring
// Sources: MMA Junkie, MMA Fighting, Bloody Elbow, Boxing Scene, Ring Magazine,
// ONE Championship, BKFC News
// ═══════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum NewsSource {
  mmaJunkie,
  mmaFighting,
  bloodyElbow,
  boxingScene,
  ringMagazine,
  oneChampionship,
  bkfcNews,
  ufc,
  bellator,
  pfl,
}

enum ContentCategory {
  breakingNews,
  fightAnnouncement,
  results,
  interview,
  analysis,
  ranking,
  injury,
  weighIn,
  presser,
  training,
  retirement,
  rumor,
}

enum TrustLevel { verified, trusted, unverified, flagged }

class NewsSourceConfig {
  final NewsSource source;
  final String name;
  final String feedUrl;
  final String baseUrl;
  final String logoAsset;
  final TrustLevel trustLevel;
  final int trustScore; // 0-100
  final List<String> sportFocus;
  final bool requiresProxy;
  final Duration updateInterval;

  const NewsSourceConfig({
    required this.source,
    required this.name,
    required this.feedUrl,
    required this.baseUrl,
    required this.logoAsset,
    required this.trustLevel,
    required this.trustScore,
    required this.sportFocus,
    this.requiresProxy = false,
    this.updateInterval = const Duration(minutes: 15),
  });
}

class AggregatedNewsItem {
  final String id;
  final NewsSource source;
  final String title;
  final String summary;
  final String? imageUrl;
  final String articleUrl;
  final DateTime publishedAt;
  final DateTime fetchedAt;
  final ContentCategory category;
  final List<String> tags;
  final List<String> mentionedFighters;
  final List<String> mentionedEvents;
  final int trustScore;
  final bool isBreaking;
  final bool isFeatured;
  final int engagementScore;
  final Map<String, dynamic> metadata;

  AggregatedNewsItem({
    required this.id,
    required this.source,
    required this.title,
    required this.summary,
    this.imageUrl,
    required this.articleUrl,
    required this.publishedAt,
    required this.fetchedAt,
    required this.category,
    required this.tags,
    required this.mentionedFighters,
    required this.mentionedEvents,
    required this.trustScore,
    this.isBreaking = false,
    this.isFeatured = false,
    this.engagementScore = 0,
    this.metadata = const {},
  });

  factory AggregatedNewsItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AggregatedNewsItem(
      id: doc.id,
      source: NewsSource.values.firstWhere(
        (s) => s.name == data['source'],
        orElse: () => NewsSource.mmaJunkie,
      ),
      title: data['title'] ?? '',
      summary: data['summary'] ?? '',
      imageUrl: data['imageUrl'],
      articleUrl: data['articleUrl'] ?? '',
      publishedAt:
          (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fetchedAt: (data['fetchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: ContentCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => ContentCategory.breakingNews,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      mentionedFighters: List<String>.from(data['mentionedFighters'] ?? []),
      mentionedEvents: List<String>.from(data['mentionedEvents'] ?? []),
      trustScore: data['trustScore'] ?? 50,
      isBreaking: data['isBreaking'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      engagementScore: data['engagementScore'] ?? 0,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'source': source.name,
    'title': title,
    'summary': summary,
    'imageUrl': imageUrl,
    'articleUrl': articleUrl,
    'publishedAt': Timestamp.fromDate(publishedAt),
    'fetchedAt': Timestamp.fromDate(fetchedAt),
    'category': category.name,
    'tags': tags,
    'mentionedFighters': mentionedFighters,
    'mentionedEvents': mentionedEvents,
    'trustScore': trustScore,
    'isBreaking': isBreaking,
    'isFeatured': isFeatured,
    'engagementScore': engagementScore,
    'metadata': metadata,
  };
}

class FeedHealth {
  final NewsSource source;
  final DateTime lastFetch;
  final int itemsFetched;
  final bool isHealthy;
  final String? errorMessage;
  final Duration avgFetchTime;

  FeedHealth({
    required this.source,
    required this.lastFetch,
    required this.itemsFetched,
    required this.isHealthy,
    this.errorMessage,
    required this.avgFetchTime,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// SERVICE
// ═══════════════════════════════════════════════════════════════════════════

class NewsAggregatorService {
  static final NewsAggregatorService _instance =
      NewsAggregatorService._internal();
  factory NewsAggregatorService() => _instance;
  NewsAggregatorService._internal();

  final _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // SOURCE CONFIGURATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<NewsSourceConfig> sourceConfigs = [
    NewsSourceConfig(
      source: NewsSource.mmaJunkie,
      name: 'MMA Junkie',
      feedUrl: 'https://mmajunkie.usatoday.com/feed',
      baseUrl: 'https://mmajunkie.usatoday.com',
      logoAsset: 'assets/logos/sources/mma_junkie.png',
      trustLevel: TrustLevel.verified,
      trustScore: 95,
      sportFocus: ['MMA', 'UFC', 'Bellator', 'PFL'],
      updateInterval: Duration(minutes: 10),
    ),
    NewsSourceConfig(
      source: NewsSource.mmaFighting,
      name: 'MMA Fighting',
      feedUrl: 'https://www.mmafighting.com/rss/current',
      baseUrl: 'https://www.mmafighting.com',
      logoAsset: 'assets/logos/sources/mma_fighting.png',
      trustLevel: TrustLevel.verified,
      trustScore: 95,
      sportFocus: ['MMA', 'UFC', 'Bellator', 'ONE'],
      updateInterval: Duration(minutes: 10),
    ),
    NewsSourceConfig(
      source: NewsSource.bloodyElbow,
      name: 'Bloody Elbow',
      feedUrl: 'https://www.bloodyelbow.com/rss/current',
      baseUrl: 'https://www.bloodyelbow.com',
      logoAsset: 'assets/logos/sources/bloody_elbow.png',
      trustLevel: TrustLevel.verified,
      trustScore: 90,
      sportFocus: ['MMA', 'UFC', 'Analysis'],
    ),
    NewsSourceConfig(
      source: NewsSource.boxingScene,
      name: 'Boxing Scene',
      feedUrl: 'https://www.boxingscene.com/rss/headlines.xml',
      baseUrl: 'https://www.boxingscene.com',
      logoAsset: 'assets/logos/sources/boxing_scene.png',
      trustLevel: TrustLevel.verified,
      trustScore: 92,
      sportFocus: ['Boxing', 'Bare Knuckle'],
    ),
    NewsSourceConfig(
      source: NewsSource.ringMagazine,
      name: 'Ring Magazine',
      feedUrl: 'https://www.ringtv.com/feed/',
      baseUrl: 'https://www.ringtv.com',
      logoAsset: 'assets/logos/sources/ring_magazine.png',
      trustLevel: TrustLevel.verified,
      trustScore: 95,
      sportFocus: ['Boxing', 'Rankings'],
      updateInterval: Duration(minutes: 20),
    ),
    NewsSourceConfig(
      source: NewsSource.oneChampionship,
      name: 'ONE Championship',
      feedUrl: 'https://www.onefc.com/feed/',
      baseUrl: 'https://www.onefc.com',
      logoAsset: 'assets/logos/sources/one_championship.png',
      trustLevel: TrustLevel.verified,
      trustScore: 98,
      sportFocus: ['MMA', 'Muay Thai', 'Kickboxing', 'Submission Grappling'],
    ),
    NewsSourceConfig(
      source: NewsSource.bkfcNews,
      name: 'BKFC News',
      feedUrl: 'https://www.bareknuckle.tv/news/feed',
      baseUrl: 'https://www.bareknuckle.tv',
      logoAsset: 'assets/logos/sources/bkfc.png',
      trustLevel: TrustLevel.trusted,
      trustScore: 88,
      sportFocus: ['Bare Knuckle', 'BKFC'],
      updateInterval: Duration(minutes: 20),
    ),
    NewsSourceConfig(
      source: NewsSource.ufc,
      name: 'UFC Official',
      feedUrl: 'https://www.ufc.com/rss/news',
      baseUrl: 'https://www.ufc.com',
      logoAsset: 'assets/logos/sources/ufc.png',
      trustLevel: TrustLevel.verified,
      trustScore: 100,
      sportFocus: ['UFC', 'MMA'],
      updateInterval: Duration(minutes: 10),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT FETCHING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get aggregated news feed with filters
  Stream<List<AggregatedNewsItem>> getNewsFeed({
    List<NewsSource>? sources,
    List<ContentCategory>? categories,
    List<String>? sportFilters,
    String? searchQuery,
    int limit = 50,
    bool breakingOnly = false,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('aggregated_news')
        .orderBy('publishedAt', descending: true)
        .limit(limit);

    if (sources != null && sources.isNotEmpty) {
      query = query.where(
        'source',
        whereIn: sources.map((s) => s.name).toList(),
      );
    }

    if (breakingOnly) {
      query = query.where('isBreaking', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      var items = snapshot.docs
          .map(AggregatedNewsItem.fromFirestore)
          .toList();

      // Apply additional filtering
      if (categories != null && categories.isNotEmpty) {
        items = items.where((i) => categories.contains(i.category)).toList();
      }

      if (sportFilters != null && sportFilters.isNotEmpty) {
        items = items
            .where(
              (i) => i.tags.any(
                (t) => sportFilters.any(
                  (f) => t.toLowerCase().contains(f.toLowerCase()),
                ),
              ),
            )
            .toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        items = items
            .where(
              (i) =>
                  i.title.toLowerCase().contains(q) ||
                  i.summary.toLowerCase().contains(q) ||
                  i.mentionedFighters.any((f) => f.toLowerCase().contains(q)),
            )
            .toList();
      }

      return items;
    });
  }

  /// Get breaking news only
  Stream<List<AggregatedNewsItem>> getBreakingNews({int limit = 10}) {
    return _firestore
        .collection('aggregated_news')
        .where('isBreaking', isEqualTo: true)
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AggregatedNewsItem.fromFirestore)
              .toList(),
        );
  }

  /// Get featured/curated stories
  Stream<List<AggregatedNewsItem>> getFeaturedStories({int limit = 5}) {
    return _firestore
        .collection('aggregated_news')
        .where('isFeatured', isEqualTo: true)
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AggregatedNewsItem.fromFirestore)
              .toList(),
        );
  }

  /// Get news for specific fighter
  Stream<List<AggregatedNewsItem>> getNewsForFighter(
    String fighterName, {
    int limit = 20,
  }) {
    return _firestore
        .collection('aggregated_news')
        .where('mentionedFighters', arrayContains: fighterName)
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AggregatedNewsItem.fromFirestore)
              .toList(),
        );
  }

  /// Get news for specific event
  Stream<List<AggregatedNewsItem>> getNewsForEvent(
    String eventName, {
    int limit = 30,
  }) {
    return _firestore
        .collection('aggregated_news')
        .where('mentionedEvents', arrayContains: eventName)
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AggregatedNewsItem.fromFirestore)
              .toList(),
        );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT NORMALIZATION & SCORING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Normalize incoming content from any source
  AggregatedNewsItem normalizeContent({
    required NewsSource source,
    required String title,
    required String description,
    required String link,
    String? imageUrl,
    required DateTime pubDate,
  }) {
    final config = getSourceConfig(source);
    final category = _detectCategory(title, description);
    final fighters = _extractFighterMentions(title, description);
    final events = _extractEventMentions(title, description);
    final tags = _generateTags(title, description, source);
    final isBreaking = _isBreakingNews(title, category);

    return AggregatedNewsItem(
      id: _generateContentId(source, link),
      source: source,
      title: _cleanTitle(title),
      summary: _cleanSummary(description),
      imageUrl: _validateImageUrl(imageUrl),
      articleUrl: link,
      publishedAt: pubDate,
      fetchedAt: DateTime.now(),
      category: category,
      tags: tags,
      mentionedFighters: fighters,
      mentionedEvents: events,
      trustScore: config?.trustScore ?? 50,
      isBreaking: isBreaking,
    );
  }

  ContentCategory _detectCategory(String title, String description) {
    final text = '$title $description'.toLowerCase();

    if (text.contains('breaking') ||
        text.contains('just in') ||
        text.contains('report:')) {
      return ContentCategory.breakingNews;
    }
    if (text.contains('vs') ||
        text.contains('announced') ||
        text.contains('booked') ||
        text.contains('signed')) {
      return ContentCategory.fightAnnouncement;
    }
    if (text.contains('results') ||
        text.contains('wins') ||
        text.contains('defeats') ||
        text.contains('knockout') ||
        text.contains('submission') ||
        text.contains('decision')) {
      return ContentCategory.results;
    }
    if (text.contains('interview') ||
        text.contains('speaks') ||
        text.contains('says') ||
        text.contains('reacts')) {
      return ContentCategory.interview;
    }
    if (text.contains('analysis') ||
        text.contains('breakdown') ||
        text.contains('preview')) {
      return ContentCategory.analysis;
    }
    if (text.contains('ranking') ||
        text.contains('ranked') ||
        text.contains('#')) {
      return ContentCategory.ranking;
    }
    if (text.contains('injured') ||
        text.contains('injury') ||
        text.contains('out of') ||
        text.contains('sidelined')) {
      return ContentCategory.injury;
    }
    if (text.contains('weigh-in') ||
        text.contains('weight') ||
        text.contains('makes weight')) {
      return ContentCategory.weighIn;
    }
    if (text.contains('press conference') ||
        text.contains('face-off') ||
        text.contains('staredown')) {
      return ContentCategory.presser;
    }
    if (text.contains('retires') ||
        text.contains('retirement') ||
        text.contains('hangs up')) {
      return ContentCategory.retirement;
    }
    if (text.contains('rumor') ||
        text.contains('reportedly') ||
        text.contains('sources say')) {
      return ContentCategory.rumor;
    }

    return ContentCategory.breakingNews;
  }

  List<String> _extractFighterMentions(String title, String description) {
    // Known fighter patterns to detect
    final knownPatterns = [
      // Champion keywords
      r'(\w+\s+\w+)\s+(?:vs\.?|versus)\s+(\w+\s+\w+)',
      // Common name formats
      r"([A-Z][a-z]+\s+(?:O')?[A-Z][a-z]+)",
    ];

    final mentions = <String>[];
    final text = '$title $description';

    for (final pattern in knownPatterns) {
      final regex = RegExp(pattern);
      final matches = regex.allMatches(text);
      for (final match in matches) {
        if (match.group(1) != null) mentions.add(match.group(1)!);
        if (match.groupCount > 1 && match.group(2) != null) {
          mentions.add(match.group(2)!);
        }
      }
    }

    return mentions.toSet().toList();
  }

  List<String> _extractEventMentions(String title, String description) {
    final eventPatterns = [
      r'UFC\s+\d+',
      r'Bellator\s+\d+',
      r'PFL\s+\d+',
      r'ONE\s+(?:Championship\s+)?\d+',
      r'UFC\s+Fight\s+Night',
      r'BKFC\s+\d+',
      r'KnuckeMania\s+\d*',
    ];

    final mentions = <String>[];
    final text = '$title $description';

    for (final pattern in eventPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final matches = regex.allMatches(text);
      for (final match in matches) {
        mentions.add(match.group(0)!);
      }
    }

    return mentions.toSet().toList();
  }

  List<String> _generateTags(
    String title,
    String description,
    NewsSource source,
  ) {
    final tags = <String>[];
    final text = '$title $description'.toLowerCase();

    // Sport tags
    if (text.contains('ufc') ||
        text.contains('mma') ||
        text.contains('mixed martial')) {
      tags.add('MMA');
    }
    if (text.contains('boxing') || text.contains('boxer')) {
      tags.add('Boxing');
    }
    if (text.contains('bkfc') || text.contains('bare knuckle')) {
      tags.add('Bare Knuckle');
    }
    if (text.contains('muay thai') || text.contains('kickboxing')) {
      tags.add('Kickboxing');
    }
    if (text.contains('wrestling') || text.contains('grappling')) {
      tags.add('Grappling');
    }
    if (text.contains('jiu jitsu') || text.contains('bjj')) {
      tags.add('BJJ');
    }

    // Organization tags
    if (text.contains('ufc')) tags.add('UFC');
    if (text.contains('bellator')) tags.add('Bellator');
    if (text.contains('pfl')) tags.add('PFL');
    if (text.contains('one championship') || text.contains('one fc')) {
      tags.add('ONE');
    }
    if (text.contains('bkfc')) tags.add('BKFC');

    // Add source sport focus
    final config = getSourceConfig(source);
    if (config != null) {
      tags.addAll(config.sportFocus.take(2));
    }

    return tags.toSet().toList();
  }

  bool _isBreakingNews(String title, ContentCategory category) {
    final lowerTitle = title.toLowerCase();

    // Explicit breaking indicators
    if (lowerTitle.startsWith('breaking') ||
        lowerTitle.contains('just in') ||
        lowerTitle.contains('report:') ||
        lowerTitle.contains('breaking:')) {
      return true;
    }

    // Categories that are often breaking
    if (category == ContentCategory.fightAnnouncement ||
        category == ContentCategory.injury ||
        category == ContentCategory.retirement) {
      return true;
    }

    return false;
  }

  String _generateContentId(NewsSource source, String link) {
    return '${source.name}_${link.hashCode.abs()}';
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^\[.*?\]\s*'), '')
        .trim();
  }

  String _cleanSummary(String summary) {
    return summary
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('Read more...', '')
        .replaceAll('Continue reading', '')
        .trim();
  }

  String? _validateImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGAGEMENT & RANKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track article view
  Future<void> trackArticleView(String newsId) async {
    await _firestore.collection('aggregated_news').doc(newsId).update({
      'views': FieldValue.increment(1),
      'engagementScore': FieldValue.increment(1),
    });
  }

  /// Track article share
  Future<void> trackArticleShare(String newsId, String platform) async {
    await _firestore.collection('aggregated_news').doc(newsId).update({
      'shares.$platform': FieldValue.increment(1),
      'engagementScore': FieldValue.increment(5),
    });
  }

  /// Get trending news (by engagement)
  Stream<List<AggregatedNewsItem>> getTrendingNews({
    int limit = 10,
    Duration timeWindow = const Duration(hours: 24),
  }) {
    final cutoff = DateTime.now().subtract(timeWindow);
    return _firestore
        .collection('aggregated_news')
        .where('publishedAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('publishedAt', descending: true)
        .orderBy('engagementScore', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AggregatedNewsItem.fromFirestore)
              .toList(),
        );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FEED HEALTH MONITORING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get health status for all feeds
  Future<List<FeedHealth>> getSourceHealthStatus() async {
    final healthDocs = await _firestore.collection('feed_health').get();

    return healthDocs.docs.map((doc) {
      final data = doc.data();
      return FeedHealth(
        source: NewsSource.values.firstWhere(
          (s) => s.name == doc.id,
          orElse: () => NewsSource.mmaJunkie,
        ),
        lastFetch:
            (data['lastFetch'] as Timestamp?)?.toDate() ?? DateTime.now(),
        itemsFetched: data['itemsFetched'] ?? 0,
        isHealthy: data['isHealthy'] ?? false,
        errorMessage: data['errorMessage'],
        avgFetchTime: Duration(milliseconds: data['avgFetchTimeMs'] ?? 0),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER PERSONALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save user's source preferences
  Future<void> saveSourcePreferences(
    String userId,
    List<NewsSource> enabledSources,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'newsPreferences.enabledSources': enabledSources
          .map((s) => s.name)
          .toList(),
      'newsPreferences.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Save user's sport filters
  Future<void> saveSportFilters(String userId, List<String> sports) async {
    await _firestore.collection('users').doc(userId).update({
      'newsPreferences.sportFilters': sports,
      'newsPreferences.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get personalized feed for user
  Stream<List<AggregatedNewsItem>> getPersonalizedFeed(
    String userId, {
    int limit = 50,
  }) {
    return _firestore.collection('users').doc(userId).snapshots().asyncMap((
      userDoc,
    ) async {
      final prefs = userDoc.data()?['newsPreferences'];

      List<NewsSource>? sources;
      List<String>? sports;

      if (prefs != null) {
        final enabledSourceNames = List<String>.from(
          prefs['enabledSources'] ?? [],
        );
        if (enabledSourceNames.isNotEmpty) {
          sources = enabledSourceNames
              .map(
                (name) => NewsSource.values.firstWhere(
                  (s) => s.name == name,
                  orElse: () => NewsSource.mmaJunkie,
                ),
              )
              .toList();
        }

        sports = List<String>.from(prefs['sportFilters'] ?? []);
      }

      final snapshot = await _firestore
          .collection('aggregated_news')
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      var items = snapshot.docs
          .map(AggregatedNewsItem.fromFirestore)
          .toList();

      if (sources != null && sources.isNotEmpty) {
        items = items.where((i) => sources!.contains(i.source)).toList();
      }

      if (sports != null && sports.isNotEmpty) {
        items = items
            .where(
              (i) => i.tags.any(
                (t) => sports!.any(
                  (s) => t.toLowerCase().contains(s.toLowerCase()),
                ),
              ),
            )
            .toList();
      }

      return items;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get source configuration
  static NewsSourceConfig? getSourceConfig(NewsSource source) {
    try {
      return sourceConfigs.firstWhere((c) => c.source == source);
    } catch (_) {
      return null;
    }
  }

  /// Get all available sources
  static List<NewsSourceConfig> getAllSources() => sourceConfigs;

  /// Get category display name
  static String getCategoryDisplayName(ContentCategory category) {
    switch (category) {
      case ContentCategory.breakingNews:
        return 'Breaking News';
      case ContentCategory.fightAnnouncement:
        return 'Fight Announcement';
      case ContentCategory.results:
        return 'Results';
      case ContentCategory.interview:
        return 'Interview';
      case ContentCategory.analysis:
        return 'Analysis';
      case ContentCategory.ranking:
        return 'Rankings';
      case ContentCategory.injury:
        return 'Injury Report';
      case ContentCategory.weighIn:
        return 'Weigh-In';
      case ContentCategory.presser:
        return 'Press Conference';
      case ContentCategory.training:
        return 'Training';
      case ContentCategory.retirement:
        return 'Retirement';
      case ContentCategory.rumor:
        return 'Rumor';
    }
  }

  /// Get category icon
  static String getCategoryIcon(ContentCategory category) {
    switch (category) {
      case ContentCategory.breakingNews:
        return '🔥';
      case ContentCategory.fightAnnouncement:
        return '📢';
      case ContentCategory.results:
        return '🏆';
      case ContentCategory.interview:
        return '🎤';
      case ContentCategory.analysis:
        return '📊';
      case ContentCategory.ranking:
        return '📈';
      case ContentCategory.injury:
        return '🏥';
      case ContentCategory.weighIn:
        return '⚖️';
      case ContentCategory.presser:
        return '📺';
      case ContentCategory.training:
        return '🥊';
      case ContentCategory.retirement:
        return '🎖️';
      case ContentCategory.rumor:
        return '👀';
    }
  }

  /// Get trust level badge color
  static int getTrustBadgeColor(TrustLevel trust) {
    switch (trust) {
      case TrustLevel.verified:
        return 0xFF4CAF50; // Green
      case TrustLevel.trusted:
        return 0xFF2196F3; // Blue
      case TrustLevel.unverified:
        return 0xFFFF9800; // Orange
      case TrustLevel.flagged:
        return 0xFFF44336; // Red
    }
  }
}
