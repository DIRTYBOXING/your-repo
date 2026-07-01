import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/image_assets.dart';
import '../../core/constants/app_constants.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// YOUTUBE SERVICE — Real Combat Sports Video Feed
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Fetches live combat sports content from YouTube Data API v3.
/// Falls back to curated channel IDs when no API key is present.
///
/// Usage:
///   flutter run --dart-define=YOUTUBE_API_KEY=YOUR_KEY_HERE
/// ═══════════════════════════════════════════════════════════════════════════

class YouTubeVideo {
  final String id;
  final String title;
  final String channelTitle;
  final String description;
  final String thumbnailUrl;
  final String videoUrl;
  final DateTime publishedAt;
  final String channelId;
  final int viewCount;
  final String duration;

  const YouTubeVideo({
    required this.id,
    required this.title,
    required this.channelTitle,
    required this.description,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.publishedAt,
    this.channelId = '',
    this.viewCount = 0,
    this.duration = '',
  });

  /// Build from YouTube Data API v3 search result item
  factory YouTubeVideo.fromSearchItem(Map<String, dynamic> item) {
    final snippet = item['snippet'] as Map<String, dynamic>? ?? {};
    final id = item['id'] as Map<String, dynamic>? ?? {};
    final videoId = id['videoId'] as String? ?? '';
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    final high =
        thumbnails['high'] as Map<String, dynamic>? ??
        thumbnails['medium'] as Map<String, dynamic>? ??
        thumbnails['default'] as Map<String, dynamic>? ??
        {};

    return YouTubeVideo(
      id: videoId,
      title: snippet['title'] as String? ?? '',
      channelTitle: snippet['channelTitle'] as String? ?? '',
      description: snippet['description'] as String? ?? '',
      thumbnailUrl: high['url'] as String? ?? '',
      videoUrl: 'https://www.youtube.com/watch?v=$videoId',
      publishedAt:
          DateTime.tryParse(snippet['publishedAt'] as String? ?? '') ??
          DateTime.now(),
      channelId: snippet['channelId'] as String? ?? '',
    );
  }

  /// Build from YouTube Data API v3 video item (with stats)
  factory YouTubeVideo.fromVideoItem(Map<String, dynamic> item) {
    final snippet = item['snippet'] as Map<String, dynamic>? ?? {};
    final stats = item['statistics'] as Map<String, dynamic>? ?? {};
    final contentDetails =
        item['contentDetails'] as Map<String, dynamic>? ?? {};
    final videoId = item['id'] as String? ?? '';
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    final high =
        thumbnails['high'] as Map<String, dynamic>? ??
        thumbnails['medium'] as Map<String, dynamic>? ??
        {};

    return YouTubeVideo(
      id: videoId,
      title: snippet['title'] as String? ?? '',
      channelTitle: snippet['channelTitle'] as String? ?? '',
      description: snippet['description'] as String? ?? '',
      thumbnailUrl: high['url'] as String? ?? '',
      videoUrl: 'https://www.youtube.com/watch?v=$videoId',
      publishedAt:
          DateTime.tryParse(snippet['publishedAt'] as String? ?? '') ??
          DateTime.now(),
      channelId: snippet['channelId'] as String? ?? '',
      viewCount: int.tryParse(stats['viewCount'] as String? ?? '0') ?? 0,
      duration: contentDetails['duration'] as String? ?? '',
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class YouTubeService {
  static final YouTubeService _instance = YouTubeService._();
  factory YouTubeService() => _instance;
  YouTubeService._();

  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  /// Combat sports search queries for rotation
  static const List<String> _combatQueries = [
    'UFC fight highlights 2026',
    'boxing highlight finishes',
    'MMA fight compilation',
    'muay thai fight',
    'BKFC bare knuckle competition',
    'ONE Championship highlights',
    'kickboxing fight',
    'BJJ competition highlights',
    'combat sports training',
    'fight camp documentary',
  ];

  /// Known combat sports YouTube channel IDs for targeted searches
  // ignore: unused_field
  static const List<String> _combatChannelIds = [
    'UCvgfXK4nTYKudb9SRSBSnog', // UFC
    'UCN1hnUccO4FD5WfM7ithXaw', // ONE Championship
    'UChmHHczPKRMBkmYEas5BISA', // DAZN Boxing
    'UC14UlmYlSNiQCBe9Eookf_A', // Bellator MMA
    'UCKxl_MTkDqNMHafiU2bGAKg', // PFL MMA
    'UCBJIBDGvoFgEMbG2VGPlCgg', // BKFC
  ];

  List<YouTubeVideo> _cachedVideos = [];
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 15);

  /// Normalize public YouTube URLs for desktop/web playback.
  ///
  /// - Converts `youtu.be/<id>` to `youtube.com/watch?v=<id>`
  /// - Converts `youtube.com/shorts/<id>` to `youtube.com/watch?v=<id>`
  /// - Preserves `t` query param when present
  static Uri normalizePublicYoutubeUri(
    String rawUrl, {
    String? fallbackSearchQuery,
  }) {
    final parsed = Uri.tryParse(rawUrl);
    if (parsed == null) {
      return Uri.https('www.youtube.com', '/results', {
        'search_query': fallbackSearchQuery ?? rawUrl,
      });
    }

    final host = parsed.host.toLowerCase();
    final segments = parsed.pathSegments;
    final t = parsed.queryParameters['t'];

    if (host == 'youtu.be' && segments.isNotEmpty) {
      final videoId = segments.first;
      return Uri.https('www.youtube.com', '/watch', {
        'v': videoId,
        if (t != null && t.isNotEmpty) 't': t,
      });
    }

    if (host.contains('youtube.com') &&
        segments.length >= 2 &&
        segments.first == 'shorts') {
      final videoId = segments[1];
      return Uri.https('www.youtube.com', '/watch', {
        'v': videoId,
        if (t != null && t.isNotEmpty) 't': t,
      });
    }

    return parsed;
  }

  bool get hasApiKey => AppConstants.hasYoutubeApiKey;
  String get _apiKey => AppConstants.youtubeApiKey;

  /// Fetch combat sports videos — returns cached if fresh
  Future<List<YouTubeVideo>> fetchCombatVideos({
    int maxResults = 15,
    bool forceRefresh = false,
  }) async {
    // Return cache if still fresh
    if (!forceRefresh &&
        _cachedVideos.isNotEmpty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedVideos;
    }

    if (!hasApiKey) {
      debugPrint('[YouTubeService] No API key — returning fallback data');
      return _getFallbackVideos();
    }

    try {
      final videos = await _searchVideos(maxResults: maxResults);
      if (videos.isNotEmpty) {
        _cachedVideos = videos;
        _lastFetchTime = DateTime.now();
      }
      return videos.isNotEmpty ? videos : _getFallbackVideos();
    } catch (e) {
      debugPrint('[YouTubeService] API error: $e');
      return _cachedVideos.isNotEmpty ? _cachedVideos : _getFallbackVideos();
    }
  }

  /// Search YouTube Data API v3
  Future<List<YouTubeVideo>> _searchVideos({int maxResults = 15}) async {
    // Pick 2 random queries for variety
    final queries = List<String>.from(_combatQueries)..shuffle();
    final query = queries.take(2).join('|');

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'part': 'snippet',
        'q': query,
        'type': 'video',
        'order': 'date',
        'maxResults': '$maxResults',
        'relevanceLanguage': 'en',
        'videoDuration': 'medium',
        'key': _apiKey,
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      debugPrint(
        '[YouTubeService] API ${response.statusCode}: ${response.body}',
      );
      throw Exception('YouTube API ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    return items
        .map(
          (item) => YouTubeVideo.fromSearchItem(item as Map<String, dynamic>),
        )
        .where((v) => v.id.isNotEmpty)
        .toList();
  }

  /// Fetch videos from a specific channel
  Future<List<YouTubeVideo>> fetchChannelVideos(
    String channelId, {
    int maxResults = 5,
  }) async {
    if (!hasApiKey) return [];

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'part': 'snippet',
        'channelId': channelId,
        'type': 'video',
        'order': 'date',
        'maxResults': '$maxResults',
        'key': _apiKey,
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      return items
          .map(
            (item) => YouTubeVideo.fromSearchItem(item as Map<String, dynamic>),
          )
          .where((v) => v.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[YouTubeService] Channel fetch error: $e');
      return [];
    }
  }

  /// Curated fallback when no API key is configured
  List<YouTubeVideo> _getFallbackVideos() {
    final now = DateTime.now();
    return [
      YouTubeVideo(
        id: 'ufc_313_preview',
        title: 'UFC 313: Santos vs Aliyev — Full Card Breakdown',
        channelTitle: 'UFC',
        description:
            'Light heavyweight title on the line. Full breakdown and predictions for the biggest UFC card of 2026.',
        thumbnailUrl: ImageAssets.ufcPlaceholder,
        videoUrl: 'https://www.youtube.com/@UFC',
        publishedAt: now.subtract(const Duration(hours: 3)),
      ),
      YouTubeVideo(
        id: 'dazn_boxing_hw',
        title: 'Joshua vs Zhang II — Wembley Highlights & Reaction',
        channelTitle: 'DAZN Boxing',
        description:
            '80,000 at Wembley Stadium for the biggest British boxing event of the decade.',
        thumbnailUrl: ImageAssets.boxingPlaceholder,
        videoUrl: 'https://www.youtube.com/@DAZNBoxing',
        publishedAt: now.subtract(const Duration(hours: 6)),
      ),
      YouTubeVideo(
        id: 'one_muay_thai_gp',
        title: 'ONE Championship: Narong vs Apichai — Muay Thai World GP',
        channelTitle: 'ONE Championship',
        description:
            'The greatest strikers on Earth collide in Bangkok. Full Muay Thai world grand prix coverage.',
        thumbnailUrl: ImageAssets.muayThaiPlaceholder,
        videoUrl: 'https://www.youtube.com/@ONEChampionship',
        publishedAt: now.subtract(const Duration(hours: 12)),
      ),
      YouTubeVideo(
        id: 'bkfc_knucklemania',
        title: 'BKFC KnuckleMania VI — Best Knockouts & Highlights',
        channelTitle: 'BKFC',
        description:
            'The best moments from KnuckleMania VI. Bare knuckle at its finest — no gloves, all heart and skill.',
        thumbnailUrl: ImageAssets.bkfcPlaceholder,
        videoUrl: 'https://www.youtube.com/@BareKnuckleFC',
        publishedAt: now.subtract(const Duration(days: 1)),
      ),
      YouTubeVideo(
        id: 'pfl_champions_2026',
        title: 'PFL Champions League 2026: Season 3 Semifinals — Riyadh',
        channelTitle: 'PFL MMA',
        description:
            '\$2 million on the line in Saudi Arabia. The PFL Champions League semi-finals deliver massive KOs.',
        thumbnailUrl: ImageAssets.bgPromo,
        videoUrl: 'https://www.youtube.com/@PFLMMA',
        publishedAt: now.subtract(const Duration(days: 1, hours: 6)),
      ),
      YouTubeVideo(
        id: 'glory_kickboxing_gp',
        title: 'GLORY 92: Heavyweight Grand Prix Finals — Amsterdam',
        channelTitle: 'GLORY Kickboxing',
        description:
            'The heavyweight grand prix finals from Ahoy Rotterdam. Elite kickboxing at the highest level.',
        thumbnailUrl: ImageAssets.kickboxingPlaceholder,
        videoUrl: 'https://www.youtube.com/@GLORYFighting',
        publishedAt: now.subtract(const Duration(days: 2)),
      ),
      YouTubeVideo(
        id: 'dfc_fight_camp_guide',
        title: 'Fight Camp Blueprint: 8-Week Pro Training Structure',
        channelTitle: 'DataFightCentral',
        description:
            'Complete fight camp guide for amateur and professional fighters. Periodisation, nutrition, recovery.',
        thumbnailUrl: ImageAssets.bgLogoSmall,
        videoUrl: 'https://datafightcentral.web.app',
        publishedAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  /// Clear cache to force fresh fetch
  void clearCache() {
    _cachedVideos = [];
    _lastFetchTime = null;
  }
}
