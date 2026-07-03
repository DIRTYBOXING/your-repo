import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ═══════════════════════════════════════════════════════════════════════════
/// META CONTENT SERVICE
/// Fetches fight content from Meta platforms (Facebook, Instagram)
/// Uses oEmbed API (no auth required) + Graph API (optional with token)
///
/// How it works:
///  1. oEmbed (public, no token): Embed any public IG/FB post by URL
///     GET https://graph.facebook.com/v19.0/instagram_oembed?url=...
///     GET https://graph.facebook.com/v19.0/oembed_post?url=...
///
///  2. Graph API (requires Page/App token): Search pages, get page posts
///     GET https://graph.facebook.com/v19.0/{page-id}/posts?access_token=...
///
///  3. Instagram Basic Display API → now Instagram API with Meta login
///     GET https://graph.instagram.com/me/media?access_token=...
///
/// For production, store tokens in Firebase Remote Config or Cloud Functions.
/// ═══════════════════════════════════════════════════════════════════════════

/// Represents a piece of content from Meta platforms
class MetaContent {
  final String id;
  final String platform; // 'instagram', 'facebook'
  final String title;
  final String body;
  final String? imageUrl;
  final String? videoUrl;
  final String sourceUrl;
  final String authorName;
  final String authorHandle;
  final String? authorAvatarUrl;
  final DateTime publishedAt;
  final int likes;
  final int comments;
  final int shares;
  final List<String> tags;
  final MetaContentType type;
  final bool isVerified;

  const MetaContent({
    required this.id,
    required this.platform,
    required this.title,
    required this.body,
    this.imageUrl,
    this.videoUrl,
    required this.sourceUrl,
    required this.authorName,
    required this.authorHandle,
    this.authorAvatarUrl,
    required this.publishedAt,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.tags = const [],
    this.type = MetaContentType.post,
    this.isVerified = false,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  String get engagementLabel {
    final total = likes + comments + shares;
    if (total >= 1000000) return '${(total / 1000000).toStringAsFixed(1)}M';
    if (total >= 1000) return '${(total / 1000).toStringAsFixed(1)}K';
    return '$total';
  }
}

enum MetaContentType { post, reel, story, live, event, showCard }

/// Service to fetch and manage Meta platform content
class MetaContentService {
  static final MetaContentService _instance = MetaContentService._internal();
  factory MetaContentService() => _instance;
  MetaContentService._internal();

  // In production, load from Firebase Remote Config
  String? _fbAccessToken;
  String? _igAccessToken;

  final List<MetaContent> _cache = [];
  final _controller = StreamController<List<MetaContent>>.broadcast();
  Timer? _refreshTimer;

  Stream<List<MetaContent>> get contentStream => _controller.stream;
  List<MetaContent> get cached => List.unmodifiable(_cache);

  /// Configure API tokens (call from app init or settings)
  void configure({String? fbToken, String? igToken}) {
    _fbAccessToken = fbToken;
    _igAccessToken = igToken;
  }

  /// Start auto-refreshing content
  void startAutoRefresh({Duration interval = const Duration(minutes: 15)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => fetchAll());
    fetchAll();
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Fetch content from all configured sources
  Future<List<MetaContent>> fetchAll() async {
    final results = <MetaContent>[];

    // Try Graph API if token available
    if (_fbAccessToken != null) {
      results.addAll(await _fetchFacebookPages());
    }
    if (_igAccessToken != null) {
      results.addAll(await _fetchInstagramMedia());
    }

    // Always include curated fight content (oEmbed-ready URLs)
    results.addAll(_getCuratedFightContent());

    // Partner amplification wheel: when partner posts drop, DFC mirrors them
    // in the same cycle so we can promote their run instantly.
    results.addAll(_buildPartnerAmplification(results));

    _cache
      ..clear()
      ..addAll(results);
    _controller.add(_cache);
    return _cache;
  }

  List<MetaContent> _buildPartnerAmplification(List<MetaContent> content) {
    final amplified = <MetaContent>[];
    const partnerHandles = {'@ultimatelegendspromotions'};

    for (final item in content) {
      if (!partnerHandles.contains(item.authorHandle.toLowerCase())) {
        continue;
      }
      if (!_isPublicPromoSource(item.sourceUrl)) {
        continue;
      }

      amplified.add(
        MetaContent(
          id: '${item.id}_dfc_amp',
          platform: item.platform,
          title: 'DFC Amplifies: ${item.title}',
          body:
              '${item.body}\n\nPowered by DFC Partner Amplification. '
              'Follow ${item.authorHandle} and lock in through DataFightCentral.\n'
              '👉 https://datafightcentral.web.app',
          imageUrl: item.imageUrl,
          videoUrl: item.videoUrl,
          sourceUrl: item.sourceUrl,
          authorName: 'DataFightCentral',
          authorHandle: '@datafightcentral',
          publishedAt: item.publishedAt.add(const Duration(minutes: 5)),
          likes: (item.likes * 0.35).round(),
          comments: (item.comments * 0.35).round(),
          shares: (item.shares * 0.5).round(),
          tags: [...item.tags, 'DFCAmplified', 'PartnerRun', 'DFCLink'],
          type: item.type,
          isVerified: true,
        ),
      );
    }

    return amplified;
  }

  /// Mutable whitelist — editable at runtime via the admin Domain Manager.
  /// Keys are bare hostnames (no scheme, no trailing slash).
  static final Set<String> approvedDomains = {
    'instagram.com',
    'www.instagram.com',
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'youtu.be',
    'facebook.com',
    'www.facebook.com',
    'bareknuckle.tv',
    'www.bareknuckle.tv',
    'livecombatsports.com.au',
    'www.livecombatsports.com.au',
    'ultimatelegends.com.au',
    'www.ultimatelegends.com.au',
  };

  bool _isPublicPromoSource(String url) {
    if (url.isEmpty) return false;

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority) return false;

    return approvedDomains.contains(uri.host.toLowerCase());
  }

  /// Fetch oEmbed data for a specific post URL
  /// Works without any auth token — just provide a public post URL
  Future<Map<String, dynamic>?> getOEmbed(String url) async {
    try {
      final isInstagram = url.contains('instagram.com');
      final endpoint = isInstagram
          ? 'https://graph.facebook.com/v19.0/instagram_oembed'
          : 'https://graph.facebook.com/v19.0/oembed_post';

      final response = await http.get(
        Uri.parse('$endpoint?url=${Uri.encodeComponent(url)}&omitscript=true'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('MetaContentService._fetchOEmbed error: $e');
    }
    return null;
  }

  /// Fetch posts from followed Facebook pages
  Future<List<MetaContent>> _fetchFacebookPages() async {
    if (_fbAccessToken == null) return [];
    try {
      // Example: Fetch from UFC, BKFC, ONE Championship pages
      final pageIds = [
        '6176666019', // UFC
        '243211502372204', // BKFC
        '263453583686498', // ONE Championship
      ];

      final results = <MetaContent>[];
      for (final pageId in pageIds) {
        final url =
            'https://graph.facebook.com/v19.0/$pageId/posts'
            '?fields=id,message,created_time,full_picture,shares,reactions.summary(true),comments.summary(true)'
            '&limit=5&access_token=$_fbAccessToken';

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
        final posts = data['data'] as List<dynamic>? ?? [];
    for (final dynamic post in posts) {
      if (post is! Map<String, dynamic>) continue;
      results.add(
        MetaContent(
          id: post['id']?.toString() ?? '',
          platform: 'facebook',
          title: '',
          body: post['message']?.toString() ?? '',
          imageUrl: post['full_picture']?.toString(),
          sourceUrl: 'https://facebook.com/$pageId/posts/${post['id']}',
          authorName: 'Facebook Page',
          authorHandle: '@page',
          publishedAt:
              DateTime.tryParse(post['created_time']?.toString() ?? '') ??
              DateTime.now(),
          likes: (post['reactions'] as Map<String, dynamic>?)?['summary']?['total_count'] as int? ?? 0,
          comments: (post['comments'] as Map<String, dynamic>?)?['summary']?['total_count'] as int? ?? 0,
          shares: (post['shares'] as Map<String, dynamic>?)?['count'] as int? ?? 0,
          isVerified: true,
        ),
      );
    }
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Fetch Instagram media via Instagram API
  Future<List<MetaContent>> _fetchInstagramMedia() async {
    if (_igAccessToken == null) return [];
    try {
      final url =
          'https://graph.instagram.com/me/media'
          '?fields=id,caption,media_type,media_url,thumbnail_url,permalink,timestamp,like_count,comments_count'
          '&limit=10&access_token=$_igAccessToken';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['data'] as List<dynamic>? ?? [];
        return items.map<MetaContent>((dynamic item) {
          if (item is! Map<String, dynamic>) {
            return MetaContent(
              id: '', 
              platform: 'instagram', 
              title: '', 
              body: '', 
              sourceUrl: '', 
              authorName: '', 
              authorHandle: '', 
              publishedAt: DateTime.fromMicrosecondsSinceEpoch(0)
            );
          }
          return MetaContent(
            id: item['id']?.toString() ?? '',
            platform: 'instagram',
            title: '',
            body: item['caption']?.toString() ?? '',
            imageUrl: item['media_type'] == 'VIDEO'
                ? item['thumbnail_url']?.toString()
                : item['media_url']?.toString(),
            videoUrl: item['media_type'] == 'VIDEO' ? item['media_url']?.toString() : null,
            sourceUrl: item['permalink']?.toString() ?? '',
            authorName: 'Instagram',
            authorHandle: '@datafightcentral',
            publishedAt:
                DateTime.tryParse(item['timestamp']?.toString() ?? '') ?? DateTime.now(),
            likes: item['like_count'] as int? ?? 0,
            comments: item['comments_count'] as int? ?? 0,
            type: item['media_type'] == 'VIDEO'
                ? MetaContentType.reel
                : MetaContentType.post,
          );
        }).where((c) => c.id.isNotEmpty).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Curated fight content from known public accounts / pages
  /// These are real-world accounts that post fight content
  List<MetaContent> _getCuratedFightContent() {
    final now = DateTime.now();
    return [
      MetaContent(
        id: 'meta_ufc_1',
        platform: 'instagram',
        title: 'UFC 325 Official Poster Revealed',
        body:
            '\u{1F525} The official poster for #UFC325 is HERE! Alex Pereira vs Magomed Ankalaev for the Light Heavyweight Championship in S\u00e3o Paulo. Who you got? \u{1F3C6}\n\n#UFC #MMA #UFC325 #Santos #Aliyev #LHW',
        sourceUrl: 'https://www.instagram.com/ufc/',
        authorName: 'UFC',
        authorHandle: '@ufc',
        publishedAt: now.subtract(const Duration(hours: 2)),
        likes: 284500,
        comments: 18200,
        shares: 42000,
        tags: ['UFC', 'MMA', 'UFC325', 'Santos'],
        isVerified: true,
      ),
      MetaContent(
        id: 'meta_bkfc_1',
        platform: 'instagram',
        title: 'KnuckleMania VI Fight Card',
        body:
            'KnuckleMania VI is going to be INSANE \u{1F94A}\u{1F4A5} Biggest bare knuckle card of 2026 with stacked main card! Full lineup dropping soon. Tag someone who needs to see this!\n\n#BKFC #BareKnuckle #KnuckleMania',
        sourceUrl: 'https://www.instagram.com/bareknucklefc/',
        authorName: 'Bare Knuckle FC',
        authorHandle: '@bareknucklefc',
        publishedAt: now.subtract(const Duration(hours: 5)),
        likes: 45200,
        comments: 3100,
        shares: 8500,
        tags: ['BKFC', 'BareKnuckle', 'MikePerry'],
        isVerified: true,
      ),
      MetaContent(
        id: 'meta_one_1',
        platform: 'facebook',
        title: 'ONE Samurai I Preview \u2014 Tokyo',
        body:
            'Stamp Fairtex defends her atomweight throne at ONE Samurai I in Tokyo! Plus Somsak vs Whitfield II for the flyweight Muay Thai belt \u{1F3C6}\u{1F525} Watch LIVE on Prime Video March 29.',
        sourceUrl: 'https://www.facebook.com/ONEChampionship',
        authorName: 'ONE Championship',
        authorHandle: '@ONEChampionship',
        publishedAt: now.subtract(const Duration(hours: 8)),
        likes: 32100,
        comments: 2800,
        shares: 5600,
        tags: ['ONEChampionship', 'MuayThai', 'Apichai'],
        isVerified: true,
      ),
      MetaContent(
        id: 'meta_espn_mma',
        platform: 'instagram',
        title: 'P4P Rankings Shake-Up After UFC 324',
        body:
            '\u{1F4CA} The new P4P rankings are in after UFC 324 Liverpool! Islam Makhachev holds the #1 spot, Alexander Volkanovski closing in fast. Conor McGregor back in the top 15 after his spectacular KO. Full breakdown on ESPN+ \u{1F44A}',
        sourceUrl: 'https://www.instagram.com/espnmma/',
        authorName: 'ESPN MMA',
        authorHandle: '@espnmma',
        publishedAt: now.subtract(const Duration(hours: 12)),
        likes: 156000,
        comments: 12400,
        shares: 28000,
        tags: ['ESPN', 'MMA', 'P4P', 'Rankings'],
        isVerified: true,
      ),
      MetaContent(
        id: 'meta_glory_1',
        platform: 'instagram',
        title: 'GLORY Kickboxing Returns March 2026',
        body:
            'GLORY is BACK! 💥 The heavyweight Grand Prix continues with 4 of the world\'s best colliding in Amsterdam. Tickets on sale NOW. Link in bio 🎫\n\n#GLORY #Kickboxing #GrandPrix',
        sourceUrl: 'https://www.instagram.com/glorykickboxing/',
        authorName: 'GLORY Kickboxing',
        authorHandle: '@glorykickboxing',
        publishedAt: now.subtract(const Duration(hours: 16)),
        likes: 18700,
        comments: 1200,
        shares: 3400,
        tags: ['GLORY', 'Kickboxing', 'Amsterdam'],
        isVerified: true,
      ),
      MetaContent(
        id: 'meta_dfc_1',
        platform: 'instagram',
        title: 'DFC AI Training Analysis Update',
        body:
            '🤖 NEW: AI-powered training analysis is now live in DataFightCentral! Track your RPE, training minutes, resting HR, and get real-time AI insights from your wearable data. Download now! 📲\n\n#DataFightCentral #FightTech #AI',
        sourceUrl: 'https://www.instagram.com/datafightcentral/',
        authorName: 'DataFightCentral',
        authorHandle: '@datafightcentral',
        publishedAt: now.subtract(const Duration(hours: 1)),
        likes: 2400,
        comments: 180,
        shares: 520,
        tags: ['DataFightCentral', 'FightTech', 'AI'],
        isVerified: true,
      ),
      MetaContent(
        id: 'meta_joseph_1',
        platform: 'instagram',
        title: 'Ultimate Legends Fight Week Is Live',
        body:
            'Legends fight week is open. Athlete check-ins, team prep, and behind-the-scenes clips are rolling daily. Follow for schedules, card updates, and ticket links.\n\n#Legends #Boxing #Kickboxing #MuayThai #FightWeek',
        sourceUrl: 'https://www.instagram.com/ultimatelegendspromotions/',
        authorName: 'Ultimate Legends Promotions',
        authorHandle: '@ultimatelegendspromotions',
        publishedAt: now.subtract(const Duration(hours: 4)),
        likes: 3200,
        comments: 260,
        shares: 480,
        tags: ['UltimateLegends', 'Legends', 'FightWeek', 'Promotion'],
        isVerified: true,
        type: MetaContentType.reel,
      ),
      MetaContent(
        id: 'meta_joseph_2',
        platform: 'instagram',
        title: 'Ultimate Legends Countdown: 7 Days',
        body:
            '7 days to go. Card locked. Camps peaking. Melbourne fight fans, this one is built for real combat sport supporters.\n\n#UltimateLegends #Countdown #FightNight #Melbourne',
        sourceUrl: 'https://www.instagram.com/ultimatelegendspromotions/',
        authorName: 'Ultimate Legends Promotions',
        authorHandle: '@ultimatelegendspromotions',
        publishedAt: now.subtract(const Duration(hours: 6)),
        likes: 2850,
        comments: 210,
        shares: 390,
        tags: ['UltimateLegends', 'Countdown', 'FightNight', 'Melbourne'],
        isVerified: true,
      ),
      MetaContent(
        id: 'meta_joseph_3',
        platform: 'instagram',
        title: 'Fighter Spotlight: Main Event Preview',
        body:
            'Main event spotlight is up now. Full breakdown, style match-up, and what to watch in rounds 1-3.\n\n#FightBreakdown #MainEvent #Boxing #Kickboxing',
        sourceUrl: 'https://www.instagram.com/ultimatelegendspromotions/',
        authorName: 'Ultimate Legends Promotions',
        authorHandle: '@ultimatelegendspromotions',
        publishedAt: now.subtract(const Duration(hours: 10)),
        likes: 2410,
        comments: 180,
        shares: 320,
        tags: ['MainEvent', 'FightBreakdown', 'Legends', 'CombatSports'],
        isVerified: true,
        type: MetaContentType.reel,
      ),
      MetaContent(
        id: 'meta_joseph_4',
        platform: 'instagram',
        title: 'Ultimate Legends Tickets + VIP Tables Open Now',
        body:
            'Tickets and VIP tables are open now. Ultimate Legends Promotions (1.2K followers) is driving K1 Kickboxing, Muay Thai, and Boxing events from 135-157 Racecourse Road, Kensington VIC 3031. Book now via ultimatelegends.com.au or contact [contact via DFC] / info.ultimatelegends@gmail.com.\n\n#Tickets #VIP #UltimateLegends #LiveCombatSports',
        sourceUrl: 'https://www.instagram.com/ultimatelegendspromotions/',
        authorName: 'Ultimate Legends Promotions',
        authorHandle: '@ultimatelegendspromotions',
        publishedAt: now.subtract(const Duration(hours: 13)),
        likes: 1980,
        comments: 155,
        shares: 290,
        tags: ['Tickets', 'VIP', 'UltimateLegends', 'LiveEvent'],
        isVerified: true,
      ),
      MetaContent(
        id: 'meta_ultimate_official_1',
        platform: 'facebook',
        title: 'Ultimate Legends Promotions Official Details',
        body:
            'K1 Kickboxing, Muay Thai & Boxing Event. Always open. Address: 135-157 Racecourse Road, Kensington VIC 3031. Website: ultimatelegends.com.au. Contact: [contact via DFC] | info.ultimatelegends@gmail.com. WBC on the line and undercard pressure is real. Follow now and secure tickets early.',
        sourceUrl: 'https://ultimatelegends.com.au',
        authorName: 'Ultimate Legends Promotions',
        authorHandle: '@ultimatelegendspromotions',
        publishedAt: now.subtract(const Duration(hours: 3)),
        likes: 3020,
        comments: 244,
        shares: 512,
        tags: ['UltimateLegends', 'Official', 'Contact', 'Tickets'],
        isVerified: true,
      ),
      MetaContent(
        id: 'meta_joseph_5',
        platform: 'instagram',
        title: 'Ultimate Legends Livestream Access + Last Card Update',
        body:
            'Final card update and livestream details are now posted. If you cannot make venue, lock in your stream access early.\n\n#Livestream #FightCard #CombatSports #Legends',
        sourceUrl: 'https://www.instagram.com/ultimatelegendspromotions/',
        authorName: 'Ultimate Legends Promotions',
        authorHandle: '@ultimatelegendspromotions',
        publishedAt: now.subtract(const Duration(hours: 18)),
        likes: 2230,
        comments: 170,
        shares: 340,
        tags: ['Livestream', 'FightCard', 'UltimateLegends', 'Broadcast'],
        isVerified: true,
        type: MetaContentType.reel,
      ),
      MetaContent(
        id: 'meta_joseph_6',
        platform: 'instagram',
        title: 'IBC 3 Is On The Way — Rollout Live',
        body:
            'IBC 3 rollout is active. Final logistics, media schedule, and fighter arrivals are moving now. Stay locked for live drops and venue updates.\n\n#IBC3 #FightWeek #CombatSports #DFCLive',
        sourceUrl: 'https://www.instagram.com/ultimatelegendspromotions/',
        authorName: 'Ultimate Legends Promotions',
        authorHandle: '@ultimatelegendspromotions',
        publishedAt: now.subtract(const Duration(hours: 21)),
        likes: 2460,
        comments: 190,
        shares: 360,
        tags: ['IBC3', 'FightWeek', 'Rollout', 'Promotion'],
        isVerified: true,
        type: MetaContentType.reel,
      ),
      MetaContent(
        id: 'meta_joseph_7',
        platform: 'instagram',
        title: 'Building Up The Legends — Episode 1',
        body:
            'We are building up the Legends lane with daily fighter features, camp clips, and matchup storytelling. Legacy plus new blood, all in one push.\n\n#UltimateLegends #LegendsBuild #Boxing #MuayThai #Kickboxing',
        sourceUrl: 'https://www.instagram.com/ultimatelegendspromotions/',
        authorName: 'Ultimate Legends Promotions',
        authorHandle: '@ultimatelegendspromotions',
        publishedAt: now.subtract(const Duration(hours: 26)),
        likes: 2310,
        comments: 175,
        shares: 335,
        tags: ['UltimateLegends', 'LegendsBuild', 'Promotion'],
        isVerified: true,
      ),
      MetaContent(
        id: 'meta_ibc_official_1',
        platform: 'instagram',
        title: 'International Brawling Champions Official Details',
        body:
            'Official IBC channels are now live. Website: internationalbrawling.com | Instagram: @internationalbrawling | Contact: info@internationalbrawling.com. DFC is amplifying event visibility, media distribution, and promo momentum while the promotion leads from the front.',
        sourceUrl: 'https://internationalbrawling.com',
        authorName: 'International Brawling Champions',
        authorHandle: '@internationalbrawling',
        publishedAt: now.subtract(const Duration(hours: 2)),
        likes: 2640,
        comments: 210,
        shares: 430,
        tags: ['IBC', 'InternationalBrawling', 'Official', 'Contact'],
        isVerified: true,
      ),
      MetaContent(
        id: 'meta_joseph_8',
        platform: 'instagram',
        title: 'IBC 3 × Ultimate Legends: Two Worlds, One Push',
        body:
            'IBC 3 was just the beginning \u2014 Ultimate Legends is the next wave. Two promotions, one mission: putting Australian combat sports on the world map. Lock in now.\n\n#IBC3 #UltimateLegends #DFC #AustralianFighting',
        sourceUrl: 'https://www.instagram.com/ultimatelegendspromotions/',
        authorName: 'Ultimate Legends Promotions',
        authorHandle: '@ultimatelegendspromotions',
        publishedAt: now.subtract(const Duration(hours: 30)),
        likes: 2890,
        comments: 220,
        shares: 410,
        tags: ['IBC3', 'UltimateLegends', 'CrossPromo', 'DFC'],
        isVerified: true,
      ),
      MetaContent(
        id: 'meta_pfl_1',
        platform: 'facebook',
        title: 'PFL Champions vs Bellator Super Card',
        body:
            'The BIGGEST card in PFL history! Champions vs Bellator legends at Madison Square Garden. Patricio Pitbull, Valeria Cruz, and more! 🏟️🔥 Tickets available at pfl.com',
        sourceUrl: 'https://www.facebook.com/PFLmma',
        authorName: 'PFL MMA',
        authorHandle: '@PFLmma',
        publishedAt: now.subtract(const Duration(hours: 20)),
        likes: 28900,
        comments: 2100,
        shares: 6700,
        tags: ['PFL', 'Bellator', 'MMA', 'MSG'],
        isVerified: true,
      ),
      MetaContent(
        id: 'meta_toprank_1',
        platform: 'instagram',
        title: 'Boxing: Rising Prospect 15-0 KO Streak',
        body:
            '15 fights. 15 KOs. 0 losses. � This 22-year-old heavyweight prospect is the REAL DEAL. Watch his latest highlight reel and tell us he\'s not the future of boxing! 🥊\n\n#Boxing #KO #Prospect #TopRank',
        sourceUrl: 'https://www.instagram.com/topaborankboxing/',
        authorName: 'Premier Boxing Promotions',
        authorHandle: '@toprank',
        publishedAt: now.subtract(const Duration(hours: 24)),
        likes: 95400,
        comments: 7200,
        shares: 19000,
        tags: ['Boxing', 'TopRank', 'KO', 'Prospect'],
        isVerified: true,
        type: MetaContentType.reel,
      ),
      MetaContent(
        id: 'meta_tiger_mt',
        platform: 'instagram',
        title: 'Golden Dragon Muay Thai 8-Week Fight Camp Open',
        body:
            '🐯 Registrations OPEN for our legendary 8-week fight camp in Phuket! Train with world champions, learn authentic Muay Thai, and prepare for competition. Limited spots! 💪\n\n#TigerMuayThai #FightCamp #Phuket #MuayThai',
        sourceUrl: 'https://www.instagram.com/tigermuaythai/',
        authorName: 'Golden Dragon Muay Thai',
        authorHandle: '@tigermuaythai',
        publishedAt: now.subtract(const Duration(hours: 30)),
        likes: 12300,
        comments: 890,
        shares: 2100,
        tags: ['TigerMuayThai', 'FightCamp', 'Phuket'],
        isVerified: true,
      ),
      MetaContent(
        id: 'meta_showtime_1',
        platform: 'facebook',
        title: 'Showtime Boxing: Beterbiev Highlights',
        body:
            'UNDISPUTED 🏆 Artur Beterbiev finishes every single fight he starts. Watch the complete highlight reel of boxing\'s most dominant champion. Full replay available on Showtime.',
        sourceUrl: 'https://www.facebook.com/SHOsports',
        authorName: 'SHOWTIME Boxing',
        authorHandle: '@SHOsports',
        publishedAt: now.subtract(const Duration(days: 2)),
        likes: 67800,
        comments: 4500,
        shares: 15200,
        tags: ['Boxing', 'Volkov', 'Undisputed'],
        isVerified: true,
        type: MetaContentType.reel,
      ),
    ];
  }

  /// Get content filtered by platform
  List<MetaContent> getByPlatform(String platform) =>
      _cache.where((c) => c.platform == platform).toList();

  /// Get content filtered by tags
  List<MetaContent> getByTag(String tag) =>
      _cache.where((c) => c.tags.contains(tag)).toList();

  /// Search content
  List<MetaContent> search(String query) {
    final q = query.toLowerCase();
    return _cache.where((c) {
      return c.title.toLowerCase().contains(q) ||
          c.body.toLowerCase().contains(q) ||
          c.authorName.toLowerCase().contains(q) ||
          c.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  void dispose() {
    stopAutoRefresh();
    _controller.close();
  }
}
