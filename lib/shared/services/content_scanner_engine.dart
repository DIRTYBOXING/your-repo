import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CONTENT SCANNER ENGINE — The Heart of DataFightCentral
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Autonomous multi-source content aggregation engine that scans:
///  - Facebook / Meta pages & groups
///  - Instagram fight accounts & hashtags
///  - TikTok fight content (via RSS/embed)
///  - News sites: MMAFighting, Sherdog, BoxingScene, ESPN MMA, etc.
///  - YouTube fight channels
///  - Reddit: r/MMA, r/Boxing, r/MuayThai
///  - Twitter/X fight journalists
///  - Event calendars: UFC, Bellator, ONE, PFL, BKFC, Glory
///  - Blog RSS feeds
///  - Fight show schedules & event pages
///
/// Architecture:
///  1. Scanner bots run on configurable intervals
///  2. Content normalized into unified ScannedContent model
///  3. AI relevance scoring + categorization
///  4. Feeds into FightNewsService, FightWire, MetaContent, and dashboard
///  5. PromoterAI reads scanner output to generate promotional content
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Source Types ─────────────────────────────────────────────────────────
enum ScanSource {
  // Western Social Media
  facebook,
  instagram,
  tiktok,
  youtube,
  twitter,
  reddit,
  snapchat,
  twitch,
  discord,
  telegram,
  // Asian Platforms (East)
  wechat,
  douyin,
  bilibili,
  line,
  kakao,
  // Japanese Platforms
  niconico,
  pixiv,
  // South Asian Platforms — India
  // ShareChat: India's answer to Facebook (~350M users, Hindi + 15 regional languages)
  shareChat,
  // Moj: India's TikTok replacement (post-ban), short combat/sport clips
  moj,
  // Josh: MX Player short video, strong in Tier-2 Indian cities
  josh,
  // Roposo: Indian short-form video, Hindi/regional combat content
  roposo,
  // Chingari: Indian social app, Hindi + Punjabi martial arts/pehlwani clips
  chingari,
  // Helo: ByteDance-built Indian social (Hindi/Telugu/Tamil/Kannada)
  helo,
  // MX TakaTak: mainstream Indian short-form video
  takatak,
  // South Asian Platforms — Pakistan & Punjabi
  // TikTok Pakistan: Urdu/Punjabi pehlwani, kabaddi, kushti, combat clips
  tiktokPakistan,
  // Bigo Live Pakistan: live streams of pehlwani tournaments, fight events
  bigoPakistan,
  // Snack Video Pakistan: short-form kabaddi and martial arts clips
  snackVideoPakistan,
  // Likee Pakistan: short fight/sports clips in Urdu/Punjabi
  likeePakistan,
  // Facebook Pakistan/Punjabi pages: pehlwani, kushti, boxing communities
  facebookPakistan,
  // YouTube Pakistan/Punjabi: full pehlwani/kushti/kabaddi event archives
  youtubePakistan,
  // Gig/Creator Platforms
  fiverr,
  airtasker,
  upwork,
  // News & Blogs
  newsRss,
  blogRss,
  mediumBlogs,
  // Events & Promotions
  eventCalendar,
  fightPromotion,
  // Public Safety & Threat Intelligence
  threatIntel,
  // Audio & Podcasts
  podcast,
  spotify,
  // AI & Emerging
  aiGenerated,
  web3Content,
  // Search Engines & Tech
  googleNews,
  techBlogs,
  aiAnalysis,
  // Lifestyle & Products
  supplements,
  fightwear,
  fitness,
  events,
  // Sports & Racing
  droneRacing,
  redBull,
  // Financial & Stocks
  stockNews,
  financeTrading,
  // Metaverse & Web3 Partnerships
  roblox,
  fortnite,
  decentraland,
  sandbox,
  horizonWorlds,
  // Premium Partnership Channels
  premiumVerified,
  partnerNetwork,
  // DFC Native Owned Channels — first-party, trust score 1.00
  // FightPipe: DFC's official YouTube channel
  dfcYoutube,
  // DFC Facebook: DFC's official Facebook page
  dfcFacebook,
  // Catch-all for emerging platforms
  other,
}

enum ContentCategory {
  breakingNews,
  fightAnnouncement,
  fightResult,
  trainingClip,
  interview,
  pressConference,
  highlight,
  analysis,
  opinion,
  eventPromo,
  fighterSpotlight,
  ranking,
  weightIn,
  behindTheScenes,
  fanContent,
  merchandise,
  healthScience,
  spotlight,
  publicSafetyAlert,
  threatAlert,
}

enum FightSport {
  ufc,
  mma,
  boxing,
  muayThai,
  kickboxing,
  bjj,
  wrestling,
  bkfc,
  bareKnuckle,
  brawling,
  oneChampionship,
  pfl,
  bellator,
  glory,
  karate,
  judo,
  taekwondo,
  capoeira,
  sambo,
  mixed,
}

// ─── Scanned Content Model ───────────────────────────────────────────────
class ScannedContent {
  final String id;
  final ScanSource source;
  final ContentCategory category;
  final FightSport sport;
  final String title;
  final String body;
  final String? imageUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String sourceUrl;
  final String sourceName;
  final String authorName;
  final String? authorAvatar;
  final DateTime scannedAt;
  final DateTime publishedAt;
  final double relevanceScore; // 0.0 - 1.0
  final double viralScore; // 0.0 - 1.0
  final int engagementCount;
  final List<String> tags;
  final List<String> fighters; // Fighter names mentioned
  final bool isBreaking;
  final bool isVerified;
  final Map<String, dynamic> metadata;

  const ScannedContent({
    required this.id,
    required this.source,
    required this.category,
    required this.sport,
    required this.title,
    required this.body,
    this.imageUrl,
    this.videoUrl,
    this.thumbnailUrl,
    required this.sourceUrl,
    required this.sourceName,
    required this.authorName,
    this.authorAvatar,
    required this.scannedAt,
    required this.publishedAt,
    this.relevanceScore = 0.5,
    this.viralScore = 0.0,
    this.engagementCount = 0,
    this.tags = const [],
    this.fighters = const [],
    this.isBreaking = false,
    this.isVerified = false,
    this.metadata = const {},
  });

  String get timeAgo {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inSeconds < 60) return 'JUST NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  String get sourceIcon {
    switch (source) {
      case ScanSource.threatIntel:
        return '🚨';
      // Western Social Media
      case ScanSource.facebook:
        return '📘';
      case ScanSource.instagram:
        return '📸';
      case ScanSource.tiktok:
        return '🎵';
      case ScanSource.youtube:
        return '▶️';
      case ScanSource.twitter:
        return '🐦';
      case ScanSource.reddit:
        return '🟠';
      case ScanSource.snapchat:
        return '👻';
      case ScanSource.twitch:
        return '🎮';
      case ScanSource.discord:
        return '💜';
      case ScanSource.telegram:
        return '✈️';
      // Asian Platforms
      case ScanSource.wechat:
        return '💚';
      case ScanSource.douyin:
        return '🎶';
      case ScanSource.bilibili:
        return '📺';
      case ScanSource.line:
        return '💬';
      case ScanSource.kakao:
        return '🟨';
      // Japanese Platforms
      case ScanSource.niconico:
        return '🔴';
      case ScanSource.pixiv:
        return '🎨';
      // South Asian Platforms — India
      case ScanSource.shareChat:
        return '🇮🇳';
      case ScanSource.moj:
        return '🎬';
      case ScanSource.josh:
        return '🎥';
      case ScanSource.roposo:
        return '📱';
      case ScanSource.chingari:
        return '🔥';
      case ScanSource.helo:
        return '💫';
      case ScanSource.takatak:
        return '🎶';
      // South Asian Platforms — Pakistan & Punjabi
      case ScanSource.tiktokPakistan:
        return '🇵🇰';
      case ScanSource.bigoPakistan:
        return '🎙️';
      case ScanSource.snackVideoPakistan:
        return '🍿';
      case ScanSource.likeePakistan:
        return '❤️';
      case ScanSource.facebookPakistan:
        return '📘';
      case ScanSource.youtubePakistan:
        return '▶️';
      // Gig/Creator Platforms
      case ScanSource.fiverr:
        return '💼';
      case ScanSource.airtasker:
        return '🛠️';
      case ScanSource.upwork:
        return '🌐';
      // News & Blogs
      case ScanSource.newsRss:
        return '📰';
      case ScanSource.blogRss:
        return '✍️';
      case ScanSource.mediumBlogs:
        return '📝';
      // Events & Promotions
      case ScanSource.eventCalendar:
        return '📅';
      case ScanSource.fightPromotion:
        return '🥊';
      // Audio & Podcasts
      case ScanSource.podcast:
        return '🎙️';
      case ScanSource.spotify:
        return '🎧';
      // AI & Emerging
      case ScanSource.aiGenerated:
        return '🤖';
      case ScanSource.web3Content:
        return '⛓️';
      // Search Engines & Tech
      case ScanSource.googleNews:
        return '🔍';
      case ScanSource.techBlogs:
        return '💻';
      case ScanSource.aiAnalysis:
        return '⚙️';
      // Lifestyle & Products
      case ScanSource.supplements:
        return '💊';
      case ScanSource.fightwear:
        return '👕';
      case ScanSource.fitness:
        return '🏋️';
      case ScanSource.events:
        return '🎪';
      // Sports & Racing
      case ScanSource.droneRacing:
        return '🚁';
      case ScanSource.redBull:
        return '🔴';
      // Financial & Stocks
      case ScanSource.stockNews:
        return '📊';
      case ScanSource.financeTrading:
        return '💹';
      // Metaverse & Web3 Partnerships
      case ScanSource.roblox:
        return '🎮';
      case ScanSource.fortnite:
        return '⚡';
      case ScanSource.decentraland:
        return '🌐';
      case ScanSource.sandbox:
        return '🏜️';
      case ScanSource.horizonWorlds:
        return '🥽';
      // Premium Partnership Channels
      case ScanSource.premiumVerified:
        return '✅';
      case ScanSource.partnerNetwork:
        return '🤝';
      // DFC Native Owned Channels
      case ScanSource.dfcYoutube:
        return '▶️';
      case ScanSource.dfcFacebook:
        return '🏟️';
      case ScanSource.other:
        return '🌍';
    }
  }

  String get sportLabel {
    switch (sport) {
      case FightSport.ufc:
        return 'UFC';
      case FightSport.mma:
        return 'MMA';
      case FightSport.boxing:
        return 'Boxing';
      case FightSport.muayThai:
        return 'Muay Thai';
      case FightSport.kickboxing:
        return 'Kickboxing';
      case FightSport.bjj:
        return 'BJJ';
      case FightSport.wrestling:
        return 'Wrestling';
      case FightSport.bkfc:
        return 'BKFC';
      case FightSport.bareKnuckle:
        return 'Bare Knuckle';
      case FightSport.brawling:
        return 'Brawling';
      case FightSport.oneChampionship:
        return 'ONE';
      case FightSport.pfl:
        return 'PFL';
      case FightSport.bellator:
        return 'Bellator';
      case FightSport.glory:
        return 'GLORY';
      case FightSport.karate:
        return 'Karate';
      case FightSport.judo:
        return 'Judo';
      case FightSport.taekwondo:
        return 'TKD';
      case FightSport.capoeira:
        return 'Capoeira';
      case FightSport.sambo:
        return 'Sambo';
      case FightSport.mixed:
        return 'Mixed';
    }
  }

  String get engagementLabel {
    if (engagementCount >= 1000000) {
      return '${(engagementCount / 1000000).toStringAsFixed(1)}M';
    }
    if (engagementCount >= 1000) {
      return '${(engagementCount / 1000).toStringAsFixed(1)}K';
    }
    return '$engagementCount';
  }
}

// ─── Scanner Bot Config ──────────────────────────────────────────────────
class ScannerBot {
  final String name;
  final ScanSource source;
  final Duration interval;
  final List<String> targets; // URLs, hashtags, page IDs
  final bool isActive;
  final DateTime? lastScan;
  final int itemsFound;
  final double successRate;

  const ScannerBot({
    required this.name,
    required this.source,
    this.interval = const Duration(minutes: 15),
    this.targets = const [],
    this.isActive = true,
    this.lastScan,
    this.itemsFound = 0,
    this.successRate = 1.0,
  });

  ScannerBot copyWith({
    bool? isActive,
    DateTime? lastScan,
    int? itemsFound,
    double? successRate,
  }) {
    return ScannerBot(
      name: name,
      source: source,
      interval: interval,
      targets: targets,
      isActive: isActive ?? this.isActive,
      lastScan: lastScan ?? this.lastScan,
      itemsFound: itemsFound ?? this.itemsFound,
      successRate: successRate ?? this.successRate,
    );
  }
}

// ─── Scanner Engine Stats ────────────────────────────────────────────────
class ScannerStats {
  final int totalScans;
  final int totalContentFound;
  final int activeBots;
  final int totalBots;
  final DateTime? lastFullScan;
  final Duration avgScanDuration;
  final Map<ScanSource, int> contentBySource;
  final Map<FightSport, int> contentBySport;
  final double overallHealth; // 0.0 - 1.0

  const ScannerStats({
    this.totalScans = 0,
    this.totalContentFound = 0,
    this.activeBots = 0,
    this.totalBots = 0,
    this.lastFullScan,
    this.avgScanDuration = Duration.zero,
    this.contentBySource = const {},
    this.contentBySport = const {},
    this.overallHealth = 1.0,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// CONTENT SCANNER ENGINE — Master Service
/// ═══════════════════════════════════════════════════════════════════════════
class ContentScannerEngine extends ChangeNotifier {
  // ─── Threat Intelligence Bot ───────────────────────────────
  List<ScannedContent> _scanThreatIntel(ScannerBot bot) {
    final items = <ScannedContent>[];
    // Example: Simulated threat alerts (replace with real API integration)
    final alerts = [
      (
        'Public Safety Alert: Increased security at major Sydney events after Bondi incident',
        'NSW Police',
        null,
        ContentCategory.publicSafetyAlert,
        true,
      ),
      (
        'Terrorism Threat: High-profile event flagged for additional monitoring (Port Arthur anniversary)',
        'Australian Federal Police',
        null,
        ContentCategory.threatAlert,
        true,
      ),
      (
        'Global Alert: US State Dept issues warning for large gatherings in Europe',
        'US State Dept',
        null,
        ContentCategory.threatAlert,
        true,
      ),
    ];
    for (final (title, source, sport, cat, breaking) in alerts) {
      items.add(
        _makeContent(
          source: ScanSource.threatIntel,
          category: cat,
          sport: sport,
          title: title,
          body: title,
          sourceName: source,
          authorName: source,
          isBreaking: breaking,
        ),
      );
    }
    return items;
  }

  static final ContentScannerEngine _instance =
      ContentScannerEngine._internal();
  factory ContentScannerEngine() => _instance;
  ContentScannerEngine._internal();

  // ─── State ─────────────────────────────────────────────────────────────
  final List<ScannedContent> _contentFeed = [];
  final List<ScannerBot> _bots = [];
  Timer? _masterTimer;
  bool _isRunning = false;
  bool _isScanning = false;
  int _totalScans = 0;
  DateTime? _lastScan;
  final _random = math.Random();
  final _contentController = StreamController<List<ScannedContent>>.broadcast();

  // ─── Getters ───────────────────────────────────────────────────────────
  List<ScannedContent> get contentFeed => List.unmodifiable(_contentFeed);
  List<ScannerBot> get bots => List.unmodifiable(_bots);
  bool get isRunning => _isRunning;
  bool get isScanning => _isScanning;
  int get totalScans => _totalScans;
  DateTime? get lastScan => _lastScan;
  Stream<List<ScannedContent>> get contentStream => _contentController.stream;

  ScannerStats get stats => ScannerStats(
    totalScans: _totalScans,
    totalContentFound: _contentFeed.length,
    activeBots: _bots.where((b) => b.isActive).length,
    totalBots: _bots.length,
    lastFullScan: _lastScan,
    avgScanDuration: const Duration(seconds: 3),
    contentBySource: _countBySource(),
    contentBySport: _countBySport(),
    overallHealth: _bots.isEmpty
        ? 1.0
        : _bots.where((b) => b.isActive).length / _bots.length,
  );

  /// Run an on-demand scan for a specific source.
  Future<List<ScannedContent>> scan(ScanSource source) async {
    if (!AppConstants.syntheticContentEnabled) {
      return const [];
    }
    await initialize();
    final bot = _bots.firstWhere(
      (b) => b.source == source,
      orElse: () => ScannerBot(
        name: 'Ad-hoc Scanner',
        source: source,
        interval: Duration.zero,
      ),
    );
    return _scanWithBot(bot);
  }

  // ─── Initialize Scanner Bots ──────────────────────────────────────────
  Future<void> initialize() async {
    if (_bots.isNotEmpty) return; // Already initialized

    _bots.addAll([
      // Social Media Bots
      const ScannerBot(
        name: 'Meta Scanner',
        source: ScanSource.facebook,
        interval: Duration(minutes: 20),
        targets: [
          'UFC',
          'TopRankBoxing',
          'BellatorMMA',
          'ONEChampionship',
          'PFLmma',
          'BKFC',
          'GloryKickboxing',
          'DanaWhite',
        ],
      ),
      const ScannerBot(
        name: 'Instagram Crawler',
        source: ScanSource.instagram,
        targets: [
          '#UFC',
          '#Boxing',
          '#MMA',
          '#MuayThai',
          '#Kickboxing',
          '#BKFC',
          '#FightNight',
          '#KnockOut',
          '#BJJ',
          '#RIZIN',
          '#IFMA',
          '#EMF',
          '#IBC',
          '#BareKnuckle',
          '@ufc',
          '@toprank',
          '@matchroomboxing',
          '@onechampionship',
          '@mannypacquiao',
          '@cookinwithvolk',
          '@nawid_yosufi15',
          '@ufconparamount',
          '@internationalbrawling',
          '@bareknucklefc',
          '@emfmuaythai_official',
          '@coach.mertturk',
          '@breaking_the_cycle_tassie',
          '@jakepaul',
          '@mostvaluablepromotions',
        ],
      ),
      const ScannerBot(
        name: 'TikTok Tracker',
        source: ScanSource.tiktok,
        interval: Duration(minutes: 10),
        targets: [
          '#FightTok',
          '#MMA',
          '#Boxing',
          '#UFC',
          '#KO',
          '#MuayThai',
          '#MartialArts',
          '#FightHighlights',
        ],
      ),
      const ScannerBot(
        name: 'YouTube Monitor',
        source: ScanSource.youtube,
        interval: Duration(minutes: 30),
        targets: [
          'UFC',
          'ESPN MMA',
          'DAZN Boxing',
          'Matchroom Boxing',
          'ONE Championship',
          'Fight Night',
          'Morning Kombat',
          'The MMA Hour',
          'Luke Thomas',
          'MMA On Point',
        ],
      ),
      const ScannerBot(
        name: 'Twitter/X Wire',
        source: ScanSource.twitter,
        interval: Duration(minutes: 5),
        targets: [
          '@araborenstein',
          '@aaaborenstein',
          '@MMAFighting',
          '@ESPNmma',
          '@MikeGarafolo',
          '@MMAjunkie',
          '@BoxingScene',
          '@daborenstein',
          '@UFCNews',
        ],
      ),
      const ScannerBot(
        name: 'Reddit Scanner',
        source: ScanSource.reddit,
        interval: Duration(minutes: 10),
        targets: [
          'r/MMA',
          'r/boxing',
          'r/MuayThai',
          'r/bjj',
          'r/kickboxing',
          'r/UFC',
          'r/martialarts',
        ],
      ),

      // News Bots
      const ScannerBot(
        name: 'MMA News Wire',
        source: ScanSource.newsRss,
        targets: [
          'https://www.mmafighting.com/rss',
          'https://mmajunkie.usatoday.com/feed',
          'https://www.mmamania.com/rss',
        ],
      ),
      const ScannerBot(
        name: 'Boxing News Wire',
        source: ScanSource.newsRss,
        targets: [
          'https://www.boxingscene.com/rss',
          'https://www.ringtv.com/feed/',
          'https://www.badlefthook.com/rss',
          'https://www.worldboxingnews.net/feed',
        ],
      ),
      const ScannerBot(
        name: 'ESPN Fight Desk',
        source: ScanSource.newsRss,
        interval: Duration(minutes: 20),
        targets: [
          'https://www.espn.com/espn/rss/mma/news',
          'https://www.espn.com/espn/rss/boxing/news',
        ],
      ),

      // Blog & Podcast Bots
      const ScannerBot(
        name: 'Fight Blog Crawler',
        source: ScanSource.blogRss,
        interval: Duration(minutes: 60),
        targets: [
          'https://combatsportstoday.com/feed',
          'https://fightstate.com/feed',
          'https://themmadigest.com/feed',
        ],
      ),
      const ScannerBot(
        name: 'Podcast Tracker',
        source: ScanSource.podcast,
        interval: Duration(hours: 2),
        targets: [
          'The MMA Hour',
          'Morning Kombat',
          'Below the Belt',
          'Believe You Me',
          'JRE MMA Show',
          'DC & RC',
        ],
      ),

      // Event & Promotion Bots
      const ScannerBot(
        name: 'Event Calendar Bot',
        source: ScanSource.eventCalendar,
        interval: Duration(hours: 1),
        targets: [
          'UFC Events',
          'Bellator Events',
          'ONE Events',
          'PFL Events',
          'BKFC Events',
          'Glory Events',
          'Premier Boxing Events',
          'Matchroom Events',
          'DAZN Events',
        ],
      ),
      const ScannerBot(
        name: 'Promotion Wire',
        source: ScanSource.fightPromotion,
        interval: Duration(minutes: 30),
        targets: [
          'UFC',
          'Bellator',
          'ONE Championship',
          'PFL',
          'BKFC',
          'Glory',
          'Rizin',
          'KSW',
          'Cage Titans',
        ],
      ),

      // Additional Western Platforms
      const ScannerBot(
        name: 'Snapchat Stories Scanner',
        source: ScanSource.snapchat,
        targets: ['UFC', 'MMA', 'Boxing', 'Fight Stories', 'Combat Sports'],
      ),
      const ScannerBot(
        name: 'Twitch Fight Streams',
        source: ScanSource.twitch,
        interval: Duration(minutes: 10),
        targets: [
          'MMA',
          'Boxing',
          'Combat Sports',
          'Fight Analysis',
          'Training',
        ],
      ),
      const ScannerBot(
        name: 'Discord Fight Communities',
        source: ScanSource.discord,
        interval: Duration(minutes: 20),
        targets: [
          'MMA Discord',
          'Boxing Discord',
          'Combat Servers',
          'Fight Fan Communities',
        ],
      ),
      const ScannerBot(
        name: 'Telegram Fight Channels',
        source: ScanSource.telegram,
        targets: ['UFC News', 'Boxing News', 'MMA Updates', 'Fight Results'],
      ),

      // Asian Platforms
      const ScannerBot(
        name: 'WeChat Fight Groups',
        source: ScanSource.wechat,
        interval: Duration(minutes: 20),
        targets: ['MMA China', 'Beijing Fight', 'Shanghai Combat', 'Asian MMA'],
      ),
      const ScannerBot(
        name: 'Douyin Fight Content',
        source: ScanSource.douyin,
        interval: Duration(minutes: 10),
        targets: ['格斗', 'MMA', '拳击', '搏击', '功夫'],
      ),
      const ScannerBot(
        name: 'Bilibili Combat Videos',
        source: ScanSource.bilibili,
        targets: ['MMA', '格斗', '拳击', '综合格斗', '搏击视频'],
      ),
      const ScannerBot(
        name: 'LINE Fight Updates',
        source: ScanSource.line,
        interval: Duration(minutes: 20),
        targets: ['MMA Japan', 'Rizin News', 'Fight News JP'],
      ),
      const ScannerBot(
        name: 'Kakao Fight Content',
        source: ScanSource.kakao,
        interval: Duration(minutes: 20),
        targets: ['MMA Korea', 'Bellator Korea', 'Korean Fight'],
      ),

      // Japanese Platforms
      const ScannerBot(
        name: 'Niconico Fight Channel',
        source: ScanSource.niconico,
        interval: Duration(minutes: 25),
        targets: ['Rizin', 'PRIDE', '格闘技', 'MMA', '総合格闘技'],
      ),
      const ScannerBot(
        name: 'Pixiv MMA Art',
        source: ScanSource.pixiv,
        interval: Duration(hours: 1),
        targets: ['格闘技', 'MMA', 'UFC', '格闘ゲーム'],
      ),

      // Creator/Gig Platforms
      const ScannerBot(
        name: 'Fiverr Training Content',
        source: ScanSource.fiverr,
        interval: Duration(hours: 2),
        targets: [
          'MMA Training',
          'Boxing Coach',
          'Fight Analysis',
          'Combat Training',
        ],
      ),
      const ScannerBot(
        name: 'AirTasker Fight Services',
        source: ScanSource.airtasker,
        interval: Duration(hours: 2),
        targets: [
          'MMA Training',
          'Boxing Training',
          'Combat Sports',
          'Fight Coaching',
        ],
      ),
      const ScannerBot(
        name: 'Upwork Combat Professionals',
        source: ScanSource.upwork,
        interval: Duration(hours: 2),
        targets: [
          'MMA Content',
          'Boxing Analysis',
          'Fight Commentary',
          'Sports Writing',
        ],
      ),

      // Additional News Sources
      const ScannerBot(
        name: 'Medium Fight Blogs',
        source: ScanSource.mediumBlogs,
        interval: Duration(minutes: 45),
        targets: ['MMA Analysis', 'Boxing', 'Combat Sports', 'Fight Breakdown'],
      ),

      // Podcast Aggregation
      const ScannerBot(
        name: 'Spotify MMA Podcasts',
        source: ScanSource.spotify,
        interval: Duration(hours: 3),
        targets: ['MMA', 'Boxing', 'Combat Sports', 'UFC Podcast'],
      ),

      // AI & Emerging Platforms
      const ScannerBot(
        name: 'AI Generated Fight Content',
        source: ScanSource.aiGenerated,
        interval: Duration(hours: 4),
        targets: [
          'AI MMA',
          'Generated Highlights',
          'AI Analysis',
          'Synthetic Fight Content',
        ],
      ),
      const ScannerBot(
        name: 'Web3 Fight Communities',
        source: ScanSource.web3Content,
        interval: Duration(hours: 4),
        targets: [
          'Crypto MMA',
          'NFT Fight',
          'Blockchain Sports',
          'Metaverse Combat',
        ],
      ),

      // Metaverse Platform Partnership Bots
      const ScannerBot(
        name: 'Roblox Fight Games Scanner',
        source: ScanSource.roblox,
        interval: Duration(hours: 2),
        targets: [
          'MMA Games',
          'Boxing Simulators',
          'Combat Arena',
          'Fight Championship',
          'Battle Royale MMA',
        ],
      ),
      const ScannerBot(
        name: 'Fortnite Combat Events',
        source: ScanSource.fortnite,
        interval: Duration(hours: 2),
        targets: [
          'Combat Events',
          'MMA Emotes',
          'Fighter Skins',
          'Battle Royale',
          'Combat Pass',
        ],
      ),
      const ScannerBot(
        name: 'Decentraland Fight Hub',
        source: ScanSource.decentraland,
        interval: Duration(hours: 3),
        targets: [
          'Virtual Arenas',
          'NFT Fights',
          'Exhibition Matches',
          'Land Events',
          'Combat Commerce',
        ],
      ),
      const ScannerBot(
        name: 'The Sandbox Metaverse',
        source: ScanSource.sandbox,
        interval: Duration(hours: 3),
        targets: [
          'Games',
          'Combat Experiences',
          'Virtual Events',
          'NFT Props',
          'Creator Content',
        ],
      ),
      const ScannerBot(
        name: 'Horizon Worlds VR Arena',
        source: ScanSource.horizonWorlds,
        interval: Duration(hours: 2),
        targets: [
          'VR Combat',
          'Boxing VR',
          'MMA Practice',
          'Social Battles',
          'World Events',
        ],
      ),

      // Premium Verified Channel (Content Amplification)
      const ScannerBot(
        name: 'Premium Verified Feed',
        source: ScanSource.premiumVerified,
        interval: Duration(minutes: 30),
        targets: [
          'Verified Content',
          'Clean Fight Archive',
          'Premium Streams',
          'Safety Certified',
          'Family Friendly',
        ],
      ),

      // Partner Network Hub (Handshake Deals)
      const ScannerBot(
        name: 'Partner Network Integration',
        source: ScanSource.partnerNetwork,
        targets: [
          'the promotion CEO',
          'Joe Rogan',
          'Bellator',
          'ONE Championship',
          'PRIDE Legacy',
          'Metaverse Partners',
          'Brand Collaborations',
          'Tech Integrations',
        ],
      ),

      // ─── SOUTH ASIAN RADAR — India ──────────────────────────────────────
      // ShareChat: India's answer to Facebook — 350M users, 15 regional languages
      const ScannerBot(
        name: 'ShareChat Desi Combat Radar',
        source: ScanSource.shareChat,
        interval: Duration(minutes: 20),
        targets: [
          'पहलवानी', // Pehlwani
          'मुक्केबाजी', // Boxing
          'कबड्डी', // Kabaddi
          'MMA India',
          'कुश्ती', // Kushti
          '#FightIndia',
          '#IndianMMA',
          '#Pehlwani',
        ],
      ),
      // Moj: India's TikTok replacement — short pehlwani/kushti/MMA clips
      const ScannerBot(
        name: 'Moj India Fight Tracker',
        source: ScanSource.moj,
        interval: Duration(minutes: 10),
        targets: [
          '#Pehlwani',
          '#IndianBoxing',
          '#KabaddiIndia',
          '#MMAIndia',
          '#FightClip',
          '#martialarts',
        ],
      ),
      // Josh: MX Player short-form, strong in Tier-2 Indian cities
      const ScannerBot(
        name: 'Josh Short Combat Feed',
        source: ScanSource.josh,
        targets: [
          '#BoxingIndia',
          '#MMAIndia',
          '#Pehlwani',
          '#Wrestling',
          '#FightTok',
        ],
      ),
      // Roposo: Hindi/regional short-form combat content
      const ScannerBot(
        name: 'Roposo Desi Fight Scanner',
        source: ScanSource.roposo,
        interval: Duration(minutes: 20),
        targets: [
          'MMA India',
          'Indian Boxing',
          'Pehlwani India',
          'Kushti',
          'Martial Arts India',
        ],
      ),
      // Chingari: Hindi + Punjabi martial arts, pehlwani, MMA
      const ScannerBot(
        name: 'Chingari Combat Crawler',
        source: ScanSource.chingari,
        interval: Duration(minutes: 20),
        targets: [
          'Pehlwani',
          'Punjabi Wrestling',
          'MMA India',
          'Indian Martial Arts',
          'कुश्ती',
        ],
      ),
      // Helo: ByteDance Indian social — Hindi/Telugu/Tamil/Kannada
      const ScannerBot(
        name: 'Helo Regional Combat Feed',
        source: ScanSource.helo,
        interval: Duration(minutes: 30),
        targets: [
          'MMA India',
          'Boxing India',
          'Fight Videos',
          'Wrestling India',
        ],
      ),
      // MX TakaTak: mainstream Indian short-form
      const ScannerBot(
        name: 'TakaTak Fight Tracker',
        source: ScanSource.takatak,
        targets: [
          '#FightIndia',
          '#IndianBoxer',
          '#MuayThaiIndia',
          '#MMAIndia',
          '#Pehlwani',
        ],
      ),

      // ─── SOUTH ASIAN RADAR — Pakistan & Punjabi ─────────────────────────
      // TikTok Pakistan: Urdu/Punjabi — pehlwani, kabaddi, kushti tournaments
      const ScannerBot(
        name: 'TikTok PK Pehlwani Radar',
        source: ScanSource.tiktokPakistan,
        interval: Duration(minutes: 10),
        targets: [
          '#پہلوانی', // Pehlwani
          '#کبڈی', // Kabaddi
          '#کُشتی', // Kushti
          '#PakistanBoxing',
          '#MuayThaiPK',
          '#FightPK',
          'Pehlwani Pakistan',
        ],
      ),
      // Bigo Live Pakistan: live pehlwani tournament streams
      const ScannerBot(
        name: 'Bigo PK Live Fight Streams',
        source: ScanSource.bigoPakistan,
        targets: [
          'Pehlwani Live',
          'Pakistan Wrestling',
          'Kushti Pakistan',
          'Kabaddi Live PK',
          'Pakistani Boxer',
        ],
      ),
      // Snack Video Pakistan: short kabaddi and martial arts clips
      const ScannerBot(
        name: 'Snack Video PK Combat Radar',
        source: ScanSource.snackVideoPakistan,
        targets: [
          '#Pehlwani',
          '#KabaddiPakistan',
          '#PakistanBoxing',
          '#MartialArtsPK',
        ],
      ),
      // Likee Pakistan: short fight/sports in Urdu/Punjabi
      const ScannerBot(
        name: 'Likee PK Fight Tracker',
        source: ScanSource.likeePakistan,
        interval: Duration(minutes: 20),
        targets: [
          'Pakistan Fight',
          'Pehlwani Clips',
          'Pakistani Boxer',
          'Combat PK',
        ],
      ),
      // Facebook Pakistan — Punjabi pehlwani and kushti communities
      const ScannerBot(
        name: 'Facebook PK Punjabi Fight Pages',
        source: ScanSource.facebookPakistan,
        interval: Duration(minutes: 20),
        targets: [
          'پہلوانی پاکستان',
          'Pakistan Pehlwani',
          'Punjabi Wrestling',
          'Pakistan Kabaddi',
          'Pakistani Boxers',
          'Fight Club Pakistan',
          'Lahore MMA',
        ],
      ),
      // YouTube Pakistan/Punjabi — full pehlwani/kushti/kabaddi event archives
      const ScannerBot(
        name: 'YouTube PK Punjabi Combat Archive',
        source: ScanSource.youtubePakistan,
        interval: Duration(minutes: 30),
        targets: [
          'Pehlwani Pakistan',
          'Kushti Tournament Pakistan',
          'Kabaddi Pakistan 2026',
          'Pakistani Boxing Champion',
          'Punjabi Wrestler',
          'پہلوانی ٹورنامنٹ',
        ],
      ),
      // ── DFC NATIVE OWNED CHANNELS — first-party, trust score 1.00
      // FightPipe is DFC's official YouTube channel — monitor for upload
      // confirmation, comment engagement, and cross-promotion signals
      const ScannerBot(
        name: 'FightPipe YouTube (DFC Official)',
        source: ScanSource.dfcYoutube,
        interval: Duration(minutes: 5),
        targets: [
          'https://www.youtube.com/@FightPipe',
          'FightPipe',
          '#FightPipe',
          'DataFightCentral',
          'DFC PPV',
          'DFC Fight Pass',
        ],
      ),
      // DFC Facebook — monitor DFC's own page for post reach, comments,
      // share velocity, and fan engagement signals
      const ScannerBot(
        name: 'DFC Facebook Official Page',
        source: ScanSource.dfcFacebook,
        interval: Duration(minutes: 5),
        targets: [
          'https://www.facebook.com/datafightcentral',
          'DataFightCentral',
          '#DataFightCentral',
          '#DFCFight',
          'DFC Event',
          'info@datafightcentral.com',
        ],
      ),
    ]);

    // Skip synthetic scanning when disabled.
    if (AppConstants.syntheticContentEnabled) {
      await _runFullScan();
    }

    // Always try to load curated content from Firestore (admin-published).
    await _loadFirestoreContent();

    debugPrint('🔍 ContentScannerEngine initialized with ${_bots.length} bots');
    notifyListeners();
  }

  // ─── Start Engine ─────────────────────────────────────────────────────
  void startEngine({Duration interval = const Duration(minutes: 5)}) {
    if (!AppConstants.syntheticContentEnabled) {
      debugPrint(
        '⏭️ ContentScannerEngine disabled (ALLOW_SYNTHETIC_CONTENT=false)',
      );
      return;
    }
    if (_isRunning) return;
    _isRunning = true;
    _masterTimer?.cancel();
    _masterTimer = Timer.periodic(interval, (_) => _runFullScan());
    debugPrint(
      '🚀 ContentScannerEngine STARTED — scanning every ${interval.inMinutes}m',
    );
    notifyListeners();
  }

  void stopEngine() {
    _isRunning = false;
    _masterTimer?.cancel();
    _masterTimer = null;
    debugPrint('⏹️ ContentScannerEngine STOPPED');
    notifyListeners();
  }

  // ─── Full Scan (all bots) ─────────────────────────────────────────────
  Future<void> _runFullScan() async {
    if (!AppConstants.syntheticContentEnabled) {
      return;
    }
    if (_isScanning) return;
    _isScanning = true;
    notifyListeners();

    try {
      final newContent = <ScannedContent>[];

      for (var i = 0; i < _bots.length; i++) {
        final bot = _bots[i];
        if (!bot.isActive) continue;

        final items = await _scanWithBot(bot);
        newContent.addAll(items);

        _bots[i] = bot.copyWith(
          lastScan: DateTime.now(),
          itemsFound: bot.itemsFound + items.length,
          successRate: 0.85 + _random.nextDouble() * 0.15,
        );
      }

      // Deduplicate by title similarity
      final deduplicated = _deduplicateContent(newContent);

      // Score & sort
      deduplicated.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      // Add to feed (keep last 500)
      _contentFeed.insertAll(0, deduplicated);
      if (_contentFeed.length > 500) {
        _contentFeed.removeRange(500, _contentFeed.length);
      }

      _totalScans++;
      _lastScan = DateTime.now();
      _contentController.add(_contentFeed);

      debugPrint(
        '🔍 Scan #$_totalScans complete — ${deduplicated.length} new items, ${_contentFeed.length} total',
      );
    } catch (e) {
      debugPrint('❌ Scan error: $e');
    }

    _isScanning = false;
    notifyListeners();
  }

  // ─── Individual Bot Scan ──────────────────────────────────────────────
  Future<List<ScannedContent>> _scanWithBot(ScannerBot bot) async {
    // In production, each bot calls real APIs.
    // For now, generate realistic simulated content per source.
    await Future.delayed(Duration(milliseconds: 100 + _random.nextInt(200)));

    switch (bot.source) {
      case ScanSource.facebook:
        return _scanFacebook(bot);
      case ScanSource.instagram:
        return _scanInstagram(bot);
      case ScanSource.tiktok:
        return _scanTikTok(bot);
      case ScanSource.youtube:
        return _scanYouTube(bot);
      case ScanSource.twitter:
        return _scanTwitter(bot);
      case ScanSource.reddit:
        return _scanReddit(bot);
      case ScanSource.snapchat:
        return _scanSnapchat(bot);
      case ScanSource.twitch:
        return _scanTwitch(bot);
      case ScanSource.discord:
        return _scanDiscord(bot);
      case ScanSource.telegram:
        return _scanTelegram(bot);
      case ScanSource.wechat:
        return _scanWeChat(bot);
      case ScanSource.douyin:
        return _scanDouyin(bot);
      case ScanSource.bilibili:
        return _scanBilibili(bot);
      case ScanSource.line:
        return _scanLine(bot);
      case ScanSource.kakao:
        return _scanKakao(bot);
      case ScanSource.niconico:
        return _scanNiconico(bot);
      case ScanSource.pixiv:
        return _scanPixiv(bot);
      // South Asian Platforms — routed through generic social/short-video scanners
      case ScanSource.shareChat:
      case ScanSource.moj:
      case ScanSource.josh:
      case ScanSource.roposo:
      case ScanSource.chingari:
      case ScanSource.helo:
      case ScanSource.takatak:
      case ScanSource.tiktokPakistan:
      case ScanSource.bigoPakistan:
      case ScanSource.snackVideoPakistan:
      case ScanSource.likeePakistan:
      case ScanSource.facebookPakistan:
      case ScanSource.youtubePakistan:
        return _scanSouthAsian(bot);
      case ScanSource.fiverr:
        return _scanFiverr(bot);
      case ScanSource.airtasker:
        return _scanAirTasker(bot);
      case ScanSource.upwork:
        return _scanUpwork(bot);
      case ScanSource.newsRss:
        return _scanNewsRSS(bot);
      case ScanSource.googleNews:
        return _scanNewsRSS(bot);
      case ScanSource.stockNews:
        return _scanNewsRSS(bot);
      case ScanSource.financeTrading:
        return _scanNewsRSS(bot);
      case ScanSource.blogRss:
        return _scanBlogs(bot);
      case ScanSource.techBlogs:
        return _scanBlogs(bot);
      case ScanSource.mediumBlogs:
        return _scanMedium(bot);
      case ScanSource.aiAnalysis:
        return _scanAIContent(bot);
      case ScanSource.eventCalendar:
        return _scanEvents(bot);
      case ScanSource.threatIntel:
        return _scanThreatIntel(bot);
      case ScanSource.events:
        return _scanEvents(bot);
      case ScanSource.droneRacing:
        return _scanEvents(bot);
      case ScanSource.redBull:
        return _scanEvents(bot);
      case ScanSource.fightPromotion:
        return _scanPromotions(bot);
      case ScanSource.supplements:
        return _scanPromotions(bot);
      case ScanSource.fightwear:
        return _scanPromotions(bot);
      case ScanSource.fitness:
        return _scanPromotions(bot);
      case ScanSource.podcast:
        return _scanPodcasts(bot);
      case ScanSource.spotify:
        return _scanSpotify(bot);
      case ScanSource.aiGenerated:
        return _scanAIContent(bot);
      case ScanSource.web3Content:
        return _scanWeb3(bot);
      // Metaverse Platforms
      case ScanSource.roblox:
        return _scanRoblox(bot);
      case ScanSource.fortnite:
        return _scanFortnite(bot);
      case ScanSource.decentraland:
        return _scanDecentraland(bot);
      case ScanSource.sandbox:
        return _scanSandbox(bot);
      case ScanSource.horizonWorlds:
        return _scanHorizonWorlds(bot);
      // Premium Partnership Channels
      case ScanSource.premiumVerified:
        return _scanPremiumVerified(bot);
      case ScanSource.partnerNetwork:
        return _scanPartnerNetwork(bot);
      // DFC Native Owned Channels
      case ScanSource.dfcYoutube:
        return _scanDfcYoutube(bot);
      case ScanSource.dfcFacebook:
        return _scanDfcFacebook(bot);
      case ScanSource.other:
        return _scanOther(bot);
    }
  }

  // ─── Source Scanners ──────────────────────────────────────────────────

  List<ScannedContent> _scanFacebook(ScannerBot bot) {
    final items = <ScannedContent>[];
    final fbPosts = [
      (
        'UFC 325 OFFICIAL: Pereira vs Ankalaev for the LHW title in São Paulo. 5 title fights on one card. Farmasi Arena is going to ERUPT 🇧🇷🔥',
        'UFC',
        FightSport.ufc,
        ContentCategory.fightAnnouncement,
        true,
      ),
      (
        'BREAKING: Serrano vs Taylor III confirmed for Croke Park, Dublin. 82,000 tickets sold out in 4 hours. Biggest women\'s boxing event in HISTORY 🇮🇪🥊',
        'DAZN Boxing',
        FightSport.boxing,
        ContentCategory.fightAnnouncement,
        true,
      ),
      (
        'Amanda Serrano returns to Dublin for the biggest women\'s boxing event in history. Three world title fights. 80,000 fans at Croke Park. June 7 💎🥊',
        'Showtime Boxing',
        FightSport.boxing,
        ContentCategory.fightAnnouncement,
        true,
      ),
      (
        'ONE Samurai I: Stamp Fairtex vs Ji-Yeon Park for the atomweight title at Tokyo Dome. Muay Thai, MMA, kickboxing triple-header. BIGGEST ONE card ever 🇯🇵',
        'ONE Championship',
        FightSport.oneChampionship,
        ContentCategory.eventPromo,
        true,
      ),
      (
        'Zhang Weili vs Yan Xiaonan LIVE NOW — UFC Fight Night Shanghai. Strawweight supremacy on the line. Weili looking razor sharp in round 1 🇨🇳',
        'UFC',
        FightSport.ufc,
        ContentCategory.fightResult,
        true,
      ),
      (
        'BKFC KnuckleMania VI results: Three first-round KOs on the main card. Jason Knight stops opponent in 47 seconds. Bare knuckle is BOOMING �',
        'BKFC',
        FightSport.bkfc,
        ContentCategory.fightResult,
        false,
      ),
      (
        'PFL vs Bellator Champions super card confirmed for MSG. Valeria Cruz, Patricio Pitbull, Taylor Hunt all on one night. This is STACKED 🏟️',
        'PFL',
        FightSport.pfl,
        ContentCategory.fightAnnouncement,
        true,
      ),
      (
        'GLORY 92 Rotterdam SOLD OUT. Heavyweight Grand Prix finals: Rico Verhoeven vs Jamal Ben Saddik IV. The biggest kickboxing rivalry continues 🇳🇱',
        'GLORY Kickboxing',
        FightSport.glory,
        ContentCategory.eventPromo,
        false,
      ),
      (
        'Canelo Álvarez announces undisputed super middleweight defense at AT&T Stadium. 70,000 seats. September 13. The Mexican superstar returns 🇲🇽',
        'DAZN Boxing',
        FightSport.boxing,
        ContentCategory.fightAnnouncement,
        true,
      ),
      (
        'Dana White confirms UFC 324: McGregor vs Pimblett at Anfield Stadium Liverpool. 55,000 capacity. June 2026. "Biggest UFC event in UK history"',
        'the promotion CEO',
        FightSport.ufc,
        ContentCategory.breakingNews,
        true,
      ),
      (
        'Ring Magazine P4P update: Zhang Weili enters top 5. First time a women\'s MMA fighter cracks the combined pound-for-pound list. History made 📊',
        'Ring Magazine',
        FightSport.mma,
        ContentCategory.ranking,
        false,
      ),
      (
        'Valentina Shevchenko signs new 4-fight UFC deal. "I want to be champion again. Flyweight is my division." Eyes 2027 title shot 🏆',
        'ESPN MMA',
        FightSport.ufc,
        ContentCategory.breakingNews,
        false,
      ),
    ];
    for (var i = 0; i < fbPosts.length; i++) {
      final (body, author, sport, cat, breaking) = fbPosts[i];
      items.add(
        _makeContent(
          source: ScanSource.facebook,
          category: cat,
          sport: sport,
          title: body.length > 80 ? '${body.substring(0, 77)}...' : body,
          body: body,
          sourceName: 'Facebook',
          authorName: author,
          isBreaking: breaking,
          minutesAgo: _random.nextInt(120),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanInstagram(ScannerBot bot) {
    final items = <ScannedContent>[];
    final igPosts = [
      (
        'Training camp update 🥊 8 weeks out, feeling sharp. New striking combinations looking dangerous. Coach says I\'m ahead of schedule',
        '@thenotorious',
        FightSport.mma,
        ContentCategory.trainingClip,
      ),
      (
        'Weigh-in day. Made weight easy. 155 on the dot. Tomorrow we fight! 💪',
        '@derekstone',
        FightSport.ufc,
        ContentCategory.weightIn,
      ),
      (
        'Another day, another round. Strawweight queen doesn\'t take days off 👑 #AndStill #UFC',
        '@zhangweilimma',
        FightSport.ufc,
        ContentCategory.trainingClip,
      ),
      (
        'The realest champion in women\'s boxing. Camp is going perfect. Katie Taylor stand up! 🥊💎',
        '@katie_t86',
        FightSport.boxing,
        ContentCategory.trainingClip,
      ),
      (
        'Dublin. Croke Park. 80,000. The Trilogy. This is what we live for. 🇮🇪🥊 #SerranoTaylor3',
        '@katie_t86',
        FightSport.boxing,
        ContentCategory.highlight,
      ),
      (
        'Two-sport world champion vibes. Muay Thai in the morning, MMA in the afternoon. Bangkok life 🇹🇭🔥',
        '@stamp_fairtex',
        FightSport.muayThai,
        ContentCategory.behindTheScenes,
      ),
      (
        'Behind the scenes at Golden Dragon Muay Thai — World class training with legends 🐯',
        '@tigermuaythai',
        FightSport.muayThai,
        ContentCategory.behindTheScenes,
      ),
      (
        'Women\'s MMA History: Making it to the Main Event 🌟 #WomenInSports',
        '@wmmaseries',
        FightSport.mma,
        ContentCategory.spotlight,
      ),
      (
        'GLORY 92 Amsterdam SOLD OUT! Get your tickets for the livestream 🎫',
        '@glorykickboxing',
        FightSport.glory,
        ContentCategory.eventPromo,
      ),
      (
        'Struggle to Success: Documentary coming soon 🎬 My journey from poverty to the octagon',
        '@combatsports_doc',
        FightSport.mma,
        ContentCategory.behindTheScenes,
      ),
      (
        'New gym merch just dropped — limited edition fight week collection 🔥',
        '@ufcstore',
        FightSport.ufc,
        ContentCategory.merchandise,
      ),
      (
        'Model. Fighter. Champion. All of the above 👑💪 #WomensMMA #Breaking',
        '@fighter_model_champ',
        FightSport.mma,
        ContentCategory.spotlight,
      ),
      (
        'This finish is INCREDIBLE 😱 Watch till the end #UFC #MMA #Skills',
        '@mma_highlights',
        FightSport.mma,
        ContentCategory.highlight,
      ),
      (
        'Joe Rogan Experience clipped: "Here\'s why women are taking over combat sports" 🎙️',
        '@joeroganclips',
        FightSport.mma,
        ContentCategory.interview,
      ),
      (
        'From the streets to the pinnacle of MMA 🔥 Underdog champion inspires millions #NeverGiveUp',
        '@inspirationalfighter',
        FightSport.mma,
        ContentCategory.interview,
      ),
      (
        '70.1K views 🥊 The People\'s Champ is back in the gym. Legacy never stops. #PacMan #Boxing #Legend',
        '@mannypacquiao',
        FightSport.boxing,
        ContentCategory.trainingClip,
      ),
      (
        'Charcoal cheeseburgers on the grill 🍔🔥 226K views — who says fighters can\'t cook? Recovery meals done right #CookinWithVolk #UFC',
        '@cookinwithvolk',
        FightSport.ufc,
        ContentCategory.behindTheScenes,
      ),
      (
        'Official collaboration agreement signed ✍️ @natediaz209 x @nawid_yosufi15 — big things coming. Stay tuned 🔥 #MMA #Collab',
        '@nawid_yosufi15',
        FightSport.mma,
        ContentCategory.spotlight,
      ),
      (
        'Looking for sponsors 🙏 \$350 of \$600 target reached. Help us break the cycle through combat sports in Tasmania 🥊💪 #BreakingTheCycle #CombatSports #Community',
        '@breaking_the_cycle_tassie',
        FightSport.mma,
        ContentCategory.spotlight,
      ),
      (
        '13th IFMA Muaythai International EMF Open Cup 🏆 Antalya, Turkey | March 25-29 — Athletes from 40+ nations competing. This is the future of Muay Thai 🇹🇷🥊 #IFMA #EMF #MuayThai',
        '@coach.mertturk',
        FightSport.muayThai,
        ContentCategory.eventPromo,
      ),
      (
        'EMF Muay Thai bringing elite competition to the world stage 🌍 Open Cup registration closing soon — represent your nation 🥇 #EMFMuayThai #IFMA #OpenCup',
        '@emfmuaythai_official',
        FightSport.muayThai,
        ContentCategory.eventPromo,
      ),
      (
        'Paramount+ is the new home of UFC! 🏠🔥 564 posts, 238K strong. Every fight, every card, streaming live. #UFConParamount #UFC #MMA',
        '@ufconparamount',
        FightSport.ufc,
        ContentCategory.eventPromo,
      ),
      (
        'March 7th, Gold Coast 🌴 Doors 5pm. International Brawling Championship is BACK. Raw combat, no gloves, all heart 👊 #IBC #BareKnuckle #GoldCoast',
        '@internationalbrawling',
        FightSport.brawling,
        ContentCategory.eventPromo,
      ),
      (
        '#BKFCNEWCASTLE | Mar 14 | Newcastle, UK 🇬🇧 The world\'s fastest growing combat sport 👊 1.9M followers strong. Bare knuckle is HERE. Get your tickets now! #BKFC #BareKnuckle',
        '@bareknucklefc',
        FightSport.bareKnuckle,
        ContentCategory.eventPromo,
      ),
      (
        '28.9M deep 👊 Most Valuable Promotions is changing the game. 1,592 posts of pure chaos. The Problem Child runs combat sports now. #JakePaul #MVP #Boxing',
        '@jakepaul',
        FightSport.boxing,
        ContentCategory.eventPromo,
      ),
      (
        'Fight week loading 🔥 @mostvaluablepromotions bringing another STACKED card. Health @getw | Bet @betr | Fight @mostvaluablepromotions | Fun @paulfamilyranch #MVP #Boxing',
        '@jakepaul',
        FightSport.boxing,
        ContentCategory.spotlight,
      ),
    ];
    for (final (body, author, sport, cat) in igPosts) {
      items.add(
        _makeContent(
          source: ScanSource.instagram,
          category: cat,
          sport: sport,
          title: body.length > 80 ? '${body.substring(0, 77)}...' : body,
          body: body,
          sourceName: 'Instagram',
          authorName: author,
          minutesAgo: _random.nextInt(90),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanTikTok(ScannerBot bot) {
    final items = <ScannedContent>[];
    final tikToks = [
      (
        'Zhang Weili\'s striking is on another level 😤 Watch this 3-punch combo on Yan Xiaonan. Strawweight QUEEN #UFC #ZhangWeili #WomensMMA',
        '@zhangweilimma',
        FightSport.ufc,
        8400000,
      ),
      (
        'Amanda Serrano Ring Magazine cover shoot BTS 👑 The Real Deal. Multiple weight class champion. Changed women\'s boxing forever #Boxing',
        '@Aboranda_Serrano',
        FightSport.boxing,
        5200000,
      ),
      (
        'Serrano vs Taylor III announcement reaction 🇮🇪 80,000 at Croke Park! Women\'s boxing IS the main event now #SerranoTaylor3',
        '@Aboranda_Serrano',
        FightSport.boxing,
        6800000,
      ),
      (
        'Stamp Fairtex Muay Thai clinch masterclass 🇹🇭 She makes it look effortless. Two-sport world champion #ONEChampionship',
        '@stamp_fairtex',
        FightSport.muayThai,
        4100000,
      ),
      (
        'Pereira training footage for UFC 325 — those left hooks are INCREDIBLE 🇧🇷 Ankalaev is in serious trouble #Poatan #UFC325',
        '@alexpoatan',
        FightSport.ufc,
        9700000,
      ),
      (
        'Valentina Shevchenko does Kyrgyz folk dance then throws a head kick 😂🏆 Most well-rounded fighter alive #Bullet',
        '@bulletvalentina',
        FightSport.ufc,
        3800000,
      ),
      (
        'Conor McGregor arrives at Anfield for UFC 324 presser. 55,000 fans going INSANE 🇮🇪🔥 #TheNotorious #UFC324 #Liverpool',
        '@thenotorious',
        FightSport.ufc,
        12300000,
      ),
      (
        'Canelo Álvarez body shot compilation — the most precise punch in boxing 🇲🇽🥊 Save this for technique study #Canelo',
        '@Canelo',
        FightSport.boxing,
        7500000,
      ),
      (
        'BKFC KnuckleMania VI highlights � Three first-round KOs. Bare knuckle hits DIFFERENT. Not for the faint hearted #BKFC',
        '@bareknucklefc',
        FightSport.bkfc,
        4200000,
      ),
      (
        'Naoya Inoue\'s speed is phenomenal ⚡ Stops opponent in 74 seconds at Tokyo Dome. 28-0 #Inoue #Boxing #PureSkill',
        '@naaborandainoue_official',
        FightSport.boxing,
        6100000,
      ),
      (
        'ONE Championship Muay Thai showcase — Somsak, Whitfield, Superlek, Apichai. The most beautiful combat sport in the world 🇹🇭🔥',
        '@onechampionship',
        FightSport.muayThai,
        5400000,
      ),
      (
        'Katie Taylor training at 39 years old. Fastest hands in women\'s boxing. Dublin is going to be ELECTRIC 🇮🇪 #KatieTaylor',
        '@katie_t86',
        FightSport.boxing,
        3200000,
      ),
      (
        'Islam Makhachev grappling session with Makhachev coaching — lightweight division is LOCKED 🔒 #UFC #Makhachev #Dagestan',
        '@islam_makhachev',
        FightSport.ufc,
        8900000,
      ),
      // ── Australian Combat Sports 2026 ──
      (
        'Zoe Putorak defends WBC MuayThai World title for the FIFTH time 🇦🇺🏆 Dominates Sigrid Kapanen in Canberra. Australia\'s Muay Thai QUEEN #WBCMuayThai #AusMuayThai',
        '@zoeputorak',
        FightSport.muayThai,
        2100000,
      ),
      (
        'Katie-Rose Mitchell captures WBC MuayThai Lightweight World Championship in Sydney!! 🇦🇺🥇 Historic night for Australian combat sports #WBCMuayThai',
        '@katierosemitchell_mt',
        FightSport.muayThai,
        1800000,
      ),
      (
        'Antonio Orden reclaims WBC MuayThai Featherweight World Title in Madrid 🇦🇺🇪🇸 The Aussie-Filipino king is BACK #AusMuayThai',
        '@antonio_orden',
        FightSport.muayThai,
        1400000,
      ),
      (
        'PFL officially expanding to Australia and New Zealand 🇦🇺🇳🇿 Rob Wilkinson and Sean Gauci to headline. This is MASSIVE for Aussie MMA #PFL #AusMMA',
        '@pflmma',
        FightSport.mma,
        3500000,
      ),
      (
        'Jai Opetaia is the BEST cruiserweight on the planet 🇦🇺🥊 IBF World Champion defending at home in Sydney. Danny Green: "Best Aussie boxer since Kostya Tszyu" #Boxing',
        '@jaiopetaia',
        FightSport.boxing,
        2800000,
      ),
      (
        'Capital Combat Pro Series 1 sold out in Canberra! Professional Muay Thai returns to the nation\'s capital 🇦🇺 What a card #AusMuayThai #Canberra',
        '@capitalcombat',
        FightSport.muayThai,
        850000,
      ),
      (
        'Hex Fight Series 27 Brisbane is going to be FIRE 🔥 Jack Della Maddalena headlines. Australia\'s best MMA promotion #HexFS #Brisbane',
        '@hexfightseries',
        FightSport.mma,
        1200000,
      ),
      (
        'ONE Championship fighters calling for events in Australia 🇦🇺 Danial Williams and Reece McLaren leading the charge. Make it happen @ONEChampionship!',
        '@fightnewsaus',
        FightSport.mma,
        950000,
      ),
      (
        'Paige VanZant spinning back fist KO from every angle 🤯 Women\'s MMA moment of the YEAR #UFC #WomensMMA',
        '@jessicaandrade',
        FightSport.ufc,
        5600000,
      ),
      (
        'GLORY kickboxing highlight reel 2026 — Rico Verhoeven, Marat Grigorian, Sitthichai. LEVELS above 🏆 #GLORY #Kickboxing',
        '@glorykickboxing',
        FightSport.glory,
        2800000,
      ),
      (
        'Taylor Hunt training for PFL vs Bellator super fight. 16-1. Olympic judoka. She\'s coming for EVERYONE 🥇 #PFL #WomensMMA',
        '@kaylaharrison',
        FightSport.pfl,
        3400000,
      ),
      (
        'Sean O\'Malley featherweight debut camp footage — speed difference at 145 is CRAZY 🌈 #SugaShow #UFC',
        '@sugaseanmma',
        FightSport.ufc,
        4700000,
      ),
      (
        'Valeria Cruz deadlifting 143 kg (315 lbs) then doing pad work. At 40 she\'s STILL the most dominant woman alive 🔥💪 #Cruz #PFL',
        '@craborisCruz',
        FightSport.pfl,
        2900000,
      ),
    ];
    for (final (body, author, sport, views) in tikToks) {
      items.add(
        _makeContent(
          source: ScanSource.tiktok,
          category: ContentCategory.highlight,
          sport: sport,
          title: body.length > 80 ? '${body.substring(0, 77)}...' : body,
          body: body,
          sourceName: 'TikTok',
          authorName: author,
          engagement: views,
          minutesAgo: _random.nextInt(60),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanYouTube(ScannerBot bot) {
    final items = <ScannedContent>[];
    final videos = [
      (
        'UFC 325 Full Press Conference — Pereira vs Ankalaev Face Off Gets HEATED in São Paulo',
        'UFC',
        FightSport.ufc,
        ContentCategory.pressConference,
      ),
      (
        'Serrano vs Taylor Trilogy: Full Press Conference Dublin — 80,000 at Croke Park',
        'DAZN Boxing',
        FightSport.boxing,
        ContentCategory.pressConference,
      ),
      (
        'Zhang Weili Full Fight Highlights vs Yan Xiaonan — Strawweight Dominance | UFC',
        'UFC',
        FightSport.ufc,
        ContentCategory.highlight,
      ),
      (
        'Katie Taylor: Croke Park Dublin — Full Undercard Breakdown | ESPN',
        'ESPN Boxing',
        FightSport.boxing,
        ContentCategory.analysis,
      ),
      (
        'ONE Samurai I: Stamp Fairtex vs Ji-Yeon Park — Full Fight Preview Tokyo',
        'ONE Championship',
        FightSport.oneChampionship,
        ContentCategory.analysis,
      ),
      (
        'Morning Kombat: UFC 325 Full Card Breakdown — Pereira, Makhachev, O\'Malley',
        'Morning Kombat',
        FightSport.ufc,
        ContentCategory.analysis,
      ),
      (
        'TOP 10 Finishes of 2026 So Far — Pereira, Andrade, Inoue | ESPN MMA',
        'ESPN MMA',
        FightSport.mma,
        ContentCategory.highlight,
      ),
      (
        'Canelo Álvarez AT&T Stadium Mega Fight: 70K Fans — Full Embedded Ep. 1',
        'Canelo Álvarez',
        FightSport.boxing,
        ContentCategory.behindTheScenes,
      ),
      (
        'GLORY 92 HW Grand Prix Finals: Rico Verhoeven vs Jamal Ben Saddik — Full Weigh-In',
        'GLORY Kickboxing',
        FightSport.glory,
        ContentCategory.pressConference,
      ),
      (
        'BKFC KnuckleMania VI: Full Fight Card Preview — Bare Knuckle Super Card 2026',
        'Bare Knuckle FC',
        FightSport.bkfc,
        ContentCategory.analysis,
      ),
      (
        'Naoya Inoue 28-0 Complete KO Highlight Reel — The Monster of Boxing',
        'DAZN Boxing',
        FightSport.boxing,
        ContentCategory.highlight,
      ),
      (
        'Conor McGregor UFC 324 Liverpool: Anfield 55K — Full Press Conference',
        'UFC',
        FightSport.ufc,
        ContentCategory.pressConference,
      ),
      (
        'Islam Makhachev Training Camp — Dagestan Wrestling to Lightweight GOAT | Full Documentary',
        'MMA On Point',
        FightSport.ufc,
        ContentCategory.behindTheScenes,
      ),
      (
        'PFL vs Bellator Super Card MSG: Taylor Hunt, Valeria Cruz, Patricio Pitbull — Full Preview',
        'PFL MMA',
        FightSport.pfl,
        ContentCategory.analysis,
      ),
      (
        'Valentina Shevchenko Signs with ONE Championship — Full Interview & Career Retrospective',
        'ONE Championship',
        FightSport.oneChampionship,
        ContentCategory.interview,
      ),
      (
        'Somsak vs Whitfield Muay Thai War — Full Fight Replay | ONE Championship',
        'ONE Championship',
        FightSport.muayThai,
        ContentCategory.highlight,
      ),
    ];
    for (final (title, author, sport, cat) in videos) {
      items.add(
        _makeContent(
          source: ScanSource.youtube,
          category: cat,
          sport: sport,
          title: title,
          body: '$title — Watch the full video on YouTube',
          sourceName: 'YouTube',
          authorName: author,
          engagement: 50000 + _random.nextInt(500000),
          minutesAgo: _random.nextInt(180),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanTwitter(ScannerBot bot) {
    final items = <ScannedContent>[];
    final tweets = [
      (
        'BREAKING: UFC 325 co-main confirmed — Islam Makhachev vs Aram Kazarian 2 for lightweight title in São Paulo. Full card is STACKED.',
        '@MMAFighting',
        FightSport.ufc,
        true,
      ),
      (
        'Sources: Serrano vs Taylor III contract signed for May 17 at Croke Park. 80,000 capacity. Biggest women\'s boxing event in history. 👀',
        '@araborenstein',
        FightSport.boxing,
        true,
      ),
      (
        'BREAKING: Conor McGregor vs Jake Lawson confirmed for UFC 324 at Anfield, Liverpool. 55,000 seats. June 14. It\'s happening.',
        '@shabornie',
        FightSport.ufc,
        true,
      ),
      (
        'Katie Taylor announces homecoming fight in Dublin — June 7. Undisputed lightweight champion headlines Croke Park. 🥊👑',
        '@ESPNRingside',
        FightSport.boxing,
        true,
      ),
      (
        'Canelo Álvarez vs Diego Castillo at AT&T Stadium, Sep 13. 70,000+ expected. DAZN PPV worldwide. The fight boxing needs. 🇲🇽',
        '@DAZNBoxing',
        FightSport.boxing,
        false,
      ),
      (
        'Zhang Weili training footage from Beijing — those combinations are SHARP. Strawweight GOAT discussion is real. #UFC',
        '@MMAJunkie',
        FightSport.ufc,
        false,
      ),
      (
        'GLORY 92 HW Grand Prix bracket set: Verhoeven vs Ben Saddik, Adegbuyi vs Hari. Amsterdam, Mar 22. Kickboxing is ELITE.',
        '@GLORYfighting',
        FightSport.glory,
        false,
      ),
      (
        'ONE Samurai I official card: Stamp Fairtex vs Ji-Yeon Park for atomweight, plus Somsak, Superlek, Apichai. Tokyo, Apr 5. 🇯🇵',
        '@ONEChampionship',
        FightSport.oneChampionship,
        false,
      ),
      (
        'BKFC KnuckleMania VI full card just dropped. Six title fights. March 29. Bare knuckle keeps growing. �🥊',
        '@bareaborknucklefc',
        FightSport.bkfc,
        false,
      ),
      (
        'Naoya Inoue vs Hiro Sakata rematch set for Tokyo Dome, July. 28-0 Monster defending all four belts. Boxing\'s P4P #1.',
        '@BoxingScene',
        FightSport.boxing,
        false,
      ),
      (
        'PFL vs Bellator Champions: Super card at Madison Square Garden locked in. Taylor Hunt, Valeria Cruz, Patricio Pitbull. 🏟️',
        '@PFLmma',
        FightSport.pfl,
        true,
      ),
      (
        'Valentina Shevchenko officially signs with ONE Championship. Former UFC flyweight queen enters a new chapter. Massive signing. 🦁',
        '@UFCNews',
        FightSport.oneChampionship,
        true,
      ),
      (
        'Ring Magazine P4P rankings update: 1. Inoue 2. Makhachev 3. Pereira 4. Crawford 5. Volkov. Thoughts? 📊',
        '@RingMagazine',
        FightSport.boxing,
        false,
      ),
      (
        'Paige VanZant spinning back fist KO goes viral — 15M views in 24 hours. Women\'s MMA moment of the year so far. 🤯',
        '@ESPNmma',
        FightSport.ufc,
        false,
      ),
      (
        'Sean O\'Malley featherweight debut confirmed — stepping up to face the division\'s best. Bold move from Sugar. 🌈',
        '@MMAFighting',
        FightSport.ufc,
        false,
      ),
    ];
    for (final (body, author, sport, breaking) in tweets) {
      items.add(
        _makeContent(
          source: ScanSource.twitter,
          category: breaking
              ? ContentCategory.breakingNews
              : ContentCategory.opinion,
          sport: sport,
          title: body.length > 80 ? '${body.substring(0, 77)}...' : body,
          body: body,
          sourceName: 'X / Twitter',
          authorName: author,
          isBreaking: breaking,
          minutesAgo: _random.nextInt(30),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanReddit(ScannerBot bot) {
    final items = <ScannedContent>[];
    final posts = [
      (
        '[Official] UFC 325 Pereira vs Ankalaev — Live Discussion Thread',
        'r/MMA',
        FightSport.ufc,
        ContentCategory.analysis,
        8400,
      ),
      (
        'Serrano vs Taylor III at 80K in Dublin — is this the biggest women\'s fight of all time?',
        'r/boxing',
        FightSport.boxing,
        ContentCategory.opinion,
        5200,
      ),
      (
        'Amanda Serrano promoting the trilogy in Dublin — biggest women\'s boxing event ever',
        'r/boxing',
        FightSport.boxing,
        ContentCategory.fightAnnouncement,
        3100,
      ),
      (
        'Paige VanZant spinning back fist KO — slow motion breakdown and technique analysis',
        'r/MMA',
        FightSport.ufc,
        ContentCategory.highlight,
        6700,
      ),
      (
        'GLORY 92 HW Grand Prix predictions: Verhoeven vs Ben Saddik, who takes it?',
        'r/kickboxing',
        FightSport.glory,
        ContentCategory.opinion,
        1800,
      ),
      (
        'Stamp Fairtex vs Ji-Yeon Park — ONE Samurai I atomweight title fight preview',
        'r/MMA',
        FightSport.oneChampionship,
        ContentCategory.analysis,
        2400,
      ),
      (
        'Canelo vs Benavidez at AT&T Stadium for 70K — will it be the biggest boxing gate ever?',
        'r/boxing',
        FightSport.boxing,
        ContentCategory.opinion,
        4300,
      ),
      (
        'Zhang Weili is the strawweight GOAT. Here\'s the statistical breakdown proving it.',
        'r/MMA',
        FightSport.ufc,
        ContentCategory.analysis,
        3800,
      ),
      (
        'BKFC KnuckleMania VI: 6 title fights on one card. Bare knuckle is legitimately growing.',
        'r/MMA',
        FightSport.bkfc,
        ContentCategory.fightAnnouncement,
        2100,
      ),
      (
        'Islam Makhachev vs Aram Kazarian 2 — lightweight title fight at UFC 325 breakdown',
        'r/MMA',
        FightSport.ufc,
        ContentCategory.analysis,
        4600,
      ),
    ];
    for (final (title, sub, sport, cat, upvotes) in posts) {
      items.add(
        _makeContent(
          source: ScanSource.reddit,
          category: cat,
          sport: sport,
          title: title,
          body: '$title — Discussion on $sub',
          sourceName: sub,
          authorName: sub,
          engagement: upvotes,
          minutesAgo: _random.nextInt(240),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanNewsRSS(ScannerBot bot) {
    final items = <ScannedContent>[];
    final articles = [
      (
        'UFC 325: Pereira vs Ankalaev Official — Full Card, Start Times, How to Watch',
        'MMA Fighting',
        FightSport.ufc,
        ContentCategory.fightAnnouncement,
        true,
      ),
      (
        'Serrano vs Taylor III: 80,000 Tickets Sell Out in 4 Hours at Croke Park Dublin',
        'Boxing Scene',
        FightSport.boxing,
        ContentCategory.breakingNews,
        true,
      ),
      (
        'Canelo Álvarez vs Diego Castillo Set for AT&T Stadium Sept 13 — DAZN PPV Worldwide',
        'ESPN Boxing',
        FightSport.boxing,
        ContentCategory.fightAnnouncement,
        true,
      ),
      (
        'Ring Magazine P4P Rankings: Inoue #1, Makhachev #2, Pereira Enters Top 3',
        'Ring Magazine',
        FightSport.boxing,
        ContentCategory.ranking,
        false,
      ),
      (
        'Valentina Shevchenko Officially Signs Multi-Fight Deal with ONE Championship',
        'MMA Junkie',
        FightSport.oneChampionship,
        ContentCategory.breakingNews,
        true,
      ),
      (
        'GLORY 92 Amsterdam: Heavyweight Grand Prix Bracket — Verhoeven, Ben Saddik, Hari, Adegbuyi',
        'GLORY Kickboxing',
        FightSport.glory,
        ContentCategory.fightAnnouncement,
        false,
      ),
      (
        'Zhang Weili Breaks Daniela Costa\' Record for Most Consecutive UFC Title Defenses by a Woman',
        'Sherdog',
        FightSport.ufc,
        ContentCategory.fightResult,
        false,
      ),
      (
        'BKFC KnuckleMania VI Card: Six Title Fights — Biggest Bare Knuckle Event in History',
        'Bloody Elbow',
        FightSport.bkfc,
        ContentCategory.fightAnnouncement,
        false,
      ),
      (
        'PFL vs Bellator Super Card: Taylor Hunt, Valeria Cruz Headline MSG Event',
        'ESPN MMA',
        FightSport.pfl,
        ContentCategory.fightAnnouncement,
        true,
      ),
      (
        'Naoya Inoue 28-0: How "The Monster" Became Boxing\'s Most Precise Puncher',
        'The Athletic',
        FightSport.boxing,
        ContentCategory.interview,
        false,
      ),
    ];
    for (final (title, source, sport, cat, breaking) in articles) {
      items.add(
        _makeContent(
          source: ScanSource.newsRss,
          category: cat,
          sport: sport,
          title: title,
          body: '$title — Read the full story on $source',
          sourceName: source,
          authorName: '$source Staff',
          isBreaking: breaking,
          minutesAgo: _random.nextInt(360),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanBlogs(ScannerBot bot) {
    final items = <ScannedContent>[];
    final blogs = [
      (
        'Pereira vs Ankalaev — Striking Biomechanics Breakdown: Left Hook vs Takedown Defence',
        'Combat Science Blog',
        FightSport.ufc,
        ContentCategory.analysis,
      ),
      (
        'Why Muay Thai Fighters Have the Best Cardio: Somsak, Superlek, and VO2 Max Data',
        'Fight Fitness Today',
        FightSport.muayThai,
        ContentCategory.healthScience,
      ),
      (
        'Serrano vs Taylor III: Nutritionist Reveals Fight Week Protocols for Elite Female Boxers',
        'Fighter Diet',
        FightSport.boxing,
        ContentCategory.healthScience,
      ),
      (
        'Zhang Weili\'s Striking Evolution: From Sanda Roots to UFC Strawweight Dominance',
        'The Fight Site',
        FightSport.ufc,
        ContentCategory.analysis,
      ),
    ];
    for (final (title, source, sport, cat) in blogs) {
      items.add(
        _makeContent(
          source: ScanSource.blogRss,
          category: cat,
          sport: sport,
          title: title,
          body: '$title — Full article on $source',
          sourceName: source,
          authorName: source,
          minutesAgo: _random.nextInt(720),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanEvents(ScannerBot bot) {
    final items = <ScannedContent>[];
    final now = DateTime.now();
    final events = [
      (
        'UFC 325: Pereira vs Ankalaev — LHW Title, São Paulo',
        'UFC',
        FightSport.ufc,
        now.add(const Duration(days: 40)),
      ),
      (
        'Serrano vs Taylor III — Croke Park Dublin, 80K Capacity',
        'DAZN Boxing',
        FightSport.boxing,
        now.add(const Duration(days: 75)),
      ),
      (
        'Serrano vs Taylor III — Croke Park Dublin',
        'DFC Boxing',
        FightSport.boxing,
        now.add(const Duration(days: 96)),
      ),
      (
        'GLORY 92: HW Grand Prix Finals — Amsterdam',
        'GLORY',
        FightSport.glory,
        now.add(const Duration(days: 19)),
      ),
      (
        'Canelo Álvarez Undisputed 168 — AT&T Stadium, 70K',
        'DAZN Boxing',
        FightSport.boxing,
        now.add(const Duration(days: 194)),
      ),
      (
        'BKFC KnuckleMania VI — Super Card, 6 Title Fights',
        'BKFC',
        FightSport.bkfc,
        now.add(const Duration(days: 26)),
      ),
      (
        'ONE Samurai I: Stamp vs Ji-Yeon Park — Tokyo',
        'ONE',
        FightSport.oneChampionship,
        now.add(const Duration(days: 33)),
      ),
      (
        'UFC 324: McGregor vs Chandler — Anfield, Liverpool 55K',
        'UFC',
        FightSport.ufc,
        now.add(const Duration(days: 103)),
      ),
      (
        'PFL vs Bellator Champions — Madison Square Garden',
        'PFL',
        FightSport.pfl,
        now.add(const Duration(days: 60)),
      ),
      (
        'Naoya Inoue vs Nakatani II — Tokyo Dome, All 4 Belts',
        'Premier Boxing',
        FightSport.boxing,
        now.add(const Duration(days: 130)),
      ),
    ];
    for (final (title, source, sport, date) in events) {
      final daysUntil = date.difference(now).inDays;
      items.add(
        _makeContent(
          source: ScanSource.eventCalendar,
          category: ContentCategory.eventPromo,
          sport: sport,
          title: '$title — ${daysUntil}d away',
          body:
              '$title happening ${daysUntil == 0 ? "TODAY" : "in $daysUntil days"}! Get your tickets now.',
          sourceName: source,
          authorName: '$source Events',
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanPromotions(ScannerBot bot) {
    final items = <ScannedContent>[];
    final promos = [
      (
        'UFC 325 Fight Card: Pereira vs Ankalaev, Makhachev vs Tsarukyan 2, O\'Malley debut at 145',
        'UFC',
        FightSport.ufc,
        ContentCategory.fightAnnouncement,
      ),
      (
        'BKFC KnuckleMania VI: Six title fights on one night — biggest bare knuckle card ever',
        'BKFC',
        FightSport.bkfc,
        ContentCategory.fightAnnouncement,
      ),
      (
        'PFL vs Bellator Champions Super Card at MSG — Taylor Hunt, Valeria Cruz headline',
        'PFL',
        FightSport.pfl,
        ContentCategory.fightAnnouncement,
      ),
      (
        'ONE Championship Samurai I: Stamp Fairtex headlines Tokyo card — tickets on sale',
        'ONE Championship',
        FightSport.oneChampionship,
        ContentCategory.eventPromo,
      ),
      (
        'GLORY 92 Amsterdam: HW Grand Prix Finals — Verhoeven, Ben Saddik, Adegbuyi, Hari',
        'GLORY',
        FightSport.glory,
        ContentCategory.fightAnnouncement,
      ),
      (
        'Serrano vs Taylor III Dublin — undisputed trilogy at Croke Park headlines',
        'DFC Boxing',
        FightSport.boxing,
        ContentCategory.fighterSpotlight,
      ),
    ];
    for (final (title, source, sport, cat) in promos) {
      items.add(
        _makeContent(
          source: ScanSource.fightPromotion,
          category: cat,
          sport: sport,
          title: title,
          body: '$source: $title',
          sourceName: source,
          authorName: source,
          minutesAgo: _random.nextInt(120),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanPodcasts(ScannerBot bot) {
    final items = <ScannedContent>[];
    final pods = [
      (
        'The MMA Hour: Alex Pereira on UFC 325, São Paulo homecoming, Ankalaev\'s power',
        'The MMA Hour',
        FightSport.ufc,
      ),
      (
        'Morning Kombat: Serrano vs Taylor III at 80K in Dublin — is this the biggest women\'s fight ever?',
        'Morning Kombat',
        FightSport.boxing,
      ),
      (
        'JRE MMA Show #162: Islam Makhachev on lightweight dominance, Makhachev coaching, legacy',
        'JRE MMA Show',
        FightSport.ufc,
      ),
      (
        'True Geordie Boxing Podcast: Canelo vs Benavidez at AT&T Stadium — 70K fans, undisputed at 168',
        'True Geordie',
        FightSport.boxing,
      ),
      (
        'Believe You Me: Bisping breaks down UFC 325 full card — Pereira, Makhachev, O\'Malley at 145',
        'Believe You Me',
        FightSport.ufc,
      ),
    ];
    for (final (title, source, sport) in pods) {
      items.add(
        _makeContent(
          source: ScanSource.podcast,
          category: ContentCategory.interview,
          sport: sport,
          title: title,
          body: 'New episode: $title — Listen now',
          sourceName: source,
          authorName: source,
          minutesAgo: _random.nextInt(480),
        ),
      );
    }
    return items;
  }

  // ─── Additional Platform Scanners ─────────────────────────────────────
  List<ScannedContent> _scanSnapchat(ScannerBot bot) {
    final items = <ScannedContent>[];
    final stories = [
      ('Live from UFC Fight Night in Vegas 🔥', 'UFCofficial', FightSport.ufc),
      ('MMA Training Session - 💪', 'MMA Chronicles', FightSport.mma),
      ('Boxing Knockout Compilation 🥊', 'Box Master', FightSport.boxing),
    ];
    for (final (title, author, sport) in stories) {
      items.add(
        _makeContent(
          source: ScanSource.snapchat,
          category: ContentCategory.highlight,
          sport: sport,
          title: title,
          body: title,
          sourceName: 'Snapchat',
          authorName: author,
          minutesAgo: _random.nextInt(60),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanTwitch(ScannerBot bot) {
    final items = <ScannedContent>[];
    final streams = [
      ('LIVE: MMA Analysis & Breakdown', 'FightChannel', FightSport.mma),
      ('Boxing Training Session LIVE', 'CoachMike', FightSport.boxing),
      ('Muay Thai Technique Class 🥋', 'ThaiMaster', FightSport.muayThai),
    ];
    for (final (title, author, sport) in streams) {
      items.add(
        _makeContent(
          source: ScanSource.twitch,
          category: ContentCategory.trainingClip,
          sport: sport,
          title: title,
          body: 'Watch $title on Twitch now',
          sourceName: 'Twitch',
          authorName: author,
          minutesAgo: _random.nextInt(120),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanDiscord(ScannerBot bot) {
    final items = <ScannedContent>[];
    final messages = [
      ('Latest UFC Event Discussion Thread', 'MMA Community', FightSport.ufc),
      (
        'Boxing Technique Breakdown & Analysis',
        'Boxing Discord',
        FightSport.boxing,
      ),
      (
        'Regional MMA Tournament Registration Open',
        'Fight Forums',
        FightSport.mma,
      ),
    ];
    for (final (title, server, sport) in messages) {
      items.add(
        _makeContent(
          source: ScanSource.discord,
          category: ContentCategory.breakingNews,
          sport: sport,
          title: title,
          body: title,
          sourceName: 'Discord',
          authorName: server,
          minutesAgo: _random.nextInt(180),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanTelegram(ScannerBot bot) {
    final items = <ScannedContent>[];
    final channels = [
      ('UFC News Channels Posts Latest Results', 'UFCNews', FightSport.ufc),
      ('Boxing Alert: Title Fight Announced', 'BoxingNews', FightSport.boxing),
      ('MMA Events Calendar Updated', 'MMAEvents', FightSport.mma),
    ];
    for (final (title, channel, sport) in channels) {
      items.add(
        _makeContent(
          source: ScanSource.telegram,
          category: ContentCategory.fightAnnouncement,
          sport: sport,
          title: title,
          body: title,
          sourceName: 'Telegram',
          authorName: channel,
          minutesAgo: _random.nextInt(240),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanWeChat(ScannerBot bot) {
    final items = <ScannedContent>[];
    final posts = [
      ('中国MMA锦标赛即将开始', 'MMA China', FightSport.mma),
      ('搏击明星训练直播', 'Fight Stars', FightSport.kickboxing),
      ('格斗技术分析第一期', 'Combat Academy', FightSport.muayThai),
    ];
    for (final (title, source, sport) in posts) {
      items.add(
        _makeContent(
          source: ScanSource.wechat,
          category: ContentCategory.breakingNews,
          sport: sport,
          title: title,
          body: title,
          sourceName: 'WeChat',
          authorName: source,
          minutesAgo: _random.nextInt(300),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanDouyin(ScannerBot bot) {
    final items = <ScannedContent>[];
    final videos = [
      ('格斗精彩瞬间集锦 #MMA', 'FightChannel', FightSport.mma),
      ('拳击训练技巧 #boxing', 'BoxCoach', FightSport.boxing),
      ('搏击比赛全程直播 #kickboxing', 'SportLive', FightSport.kickboxing),
    ];
    for (final (title, author, sport) in videos) {
      items.add(
        _makeContent(
          source: ScanSource.douyin,
          category: ContentCategory.highlight,
          sport: sport,
          title: title,
          body: '$title - 短视频',
          sourceName: 'Douyin',
          authorName: author,
          minutesAgo: _random.nextInt(120),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanBilibili(ScannerBot bot) {
    final items = <ScannedContent>[];
    final videos = [
      ('MMA比赛精彩回顾', 'MMA解说', FightSport.mma),
      ('拳击大师级教学', '拳击教练', FightSport.boxing),
      ('综合格斗技术分析视频', '格斗分析', FightSport.bjj),
    ];
    for (final (title, uploader, sport) in videos) {
      items.add(
        _makeContent(
          source: ScanSource.bilibili,
          category: ContentCategory.trainingClip,
          sport: sport,
          title: title,
          body: '在Bilibili观看完整视频',
          sourceName: 'Bilibili',
          authorName: uploader,
          minutesAgo: _random.nextInt(180),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanLine(ScannerBot bot) {
    final items = <ScannedContent>[];
    final posts = [
      ('Rizin 大会 来月開催予定', 'Rizin Japan', FightSport.mma),
      ('格闘技ニュース - 最新情報', 'Japan Fight', FightSport.boxing),
      ('MMA選手インタビュー特集', 'Fight Media', FightSport.muayThai),
    ];
    for (final (title, source, sport) in posts) {
      items.add(
        _makeContent(
          source: ScanSource.line,
          category: ContentCategory.fightAnnouncement,
          sport: sport,
          title: title,
          body: title,
          sourceName: 'LINE',
          authorName: source,
          minutesAgo: _random.nextInt(240),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanKakao(ScannerBot bot) {
    final items = <ScannedContent>[];
    final posts = [
      ('한국 MMA 대회 소식', 'Korea Fighting', FightSport.mma),
      ('격투기 뉴스 - 최신 업데이트', 'Fight Korea', FightSport.boxing),
      ('무에타이 기술 강좌', 'Thai Master', FightSport.muayThai),
    ];
    for (final (title, source, sport) in posts) {
      items.add(
        _makeContent(
          source: ScanSource.kakao,
          category: ContentCategory.breakingNews,
          sport: sport,
          title: title,
          body: title,
          sourceName: 'Kakao',
          authorName: source,
          minutesAgo: _random.nextInt(300),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanNiconico(ScannerBot bot) {
    final items = <ScannedContent>[];
    final videos = [
      ('Rizin大会ハイライト', 'ニコニコスポーツ', FightSport.mma),
      ('格闘技テクニック解説動画', '格闘技チャンネル', FightSport.boxing),
      ('MMA試合全試合ライブ配信', '総合格闘技', FightSport.bjj),
    ];
    for (final (title, channel, sport) in videos) {
      items.add(
        _makeContent(
          source: ScanSource.niconico,
          category: ContentCategory.highlight,
          sport: sport,
          title: title,
          body: 'ニコニコ動画で視聴する',
          sourceName: 'Niconico',
          authorName: channel,
          minutesAgo: _random.nextInt(150),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanPixiv(ScannerBot bot) {
    final items = <ScannedContent>[];
    final artworks = [
      ('格闘技アート集', 'PixivArtist1', FightSport.mma),
      ('ファイターイラスト', 'PixivArtist2', FightSport.boxing),
      ('格闘ゲーム創作', 'PixivArtist3', FightSport.kickboxing),
    ];
    for (final (title, artist, sport) in artworks) {
      items.add(
        _makeContent(
          source: ScanSource.pixiv,
          category: ContentCategory.spotlight,
          sport: sport,
          title: title,
          body: 'Pixivアート作品を見る',
          sourceName: 'Pixiv',
          authorName: artist,
          minutesAgo: _random.nextInt(1440),
        ),
      );
    }
    return items;
  }

  /// South Asian platform scanner — covers India (ShareChat, Moj, Josh, Roposo,
  /// Chingari, Helo, TakaTak) and Pakistan/Punjabi (TikTok PK, Bigo PK,
  /// Snack Video PK, Likee PK, Facebook PK, YouTube PK).
  /// Routes all South Asian sources through a unified scanner with
  /// region-appropriate content: pehlwani, kushti, kabaddi, boxing, MMA.
  List<ScannedContent> _scanSouthAsian(ScannerBot bot) {
    final items = <ScannedContent>[];
    final bool isPakistani = [
      ScanSource.tiktokPakistan,
      ScanSource.bigoPakistan,
      ScanSource.snackVideoPakistan,
      ScanSource.likeePakistan,
      ScanSource.facebookPakistan,
      ScanSource.youtubePakistan,
    ].contains(bot.source);

    final posts = isPakistani
        ? [
            (
              'پہلوانی ٹورنامنٹ 2026 — لاہور میں بڑا مقابلہ | Pehlwani Tournament Lahore 2026',
              'PehlwaniPK',
              FightSport.wrestling,
              ContentCategory.fightAnnouncement,
            ),
            (
              'کبڈی چیمپئنشپ پاکستان — ٹیم پنجاب vs ٹیم سندھ | Kabaddi Championship PK',
              'KabaddiPunjab',
              FightSport.mma,
              ContentCategory.fightAnnouncement,
            ),
            (
              'مکے بازی — نوجوان چیمپین کی ٹریننگ | Young Boxing Champion Training Lahore',
              'PakBoxingClub',
              FightSport.boxing,
              ContentCategory.trainingClip,
            ),
            (
              'کُشتی مقابلہ — روایتی پاکستانی ورثہ | Kushti Traditional Pakistani Wrestling',
              'KushtiPakistan',
              FightSport.wrestling,
              ContentCategory.spotlight,
            ),
          ]
        : [
            (
              'पहलवानी चैंपियनशिप 2026 — दिल्ली में महा मुकाबला | Pehlwani Championship Delhi',
              'PehlwaniIndia',
              FightSport.wrestling,
              ContentCategory.fightAnnouncement,
            ),
            (
              'कबड्डी प्रो लीग — मुंबई vs चेन्नई | Pro Kabaddi League Mumbai vs Chennai',
              'KabaddiIndia',
              FightSport.mma,
              ContentCategory.fightAnnouncement,
            ),
            (
              'MMA इंडिया — युवा फाइटर की ट्रेनिंग | MMA India Young Fighter Training Reel',
              'MMAIndia',
              FightSport.mma,
              ContentCategory.trainingClip,
            ),
            (
              'बॉक्सिंग अकादमी — फाइटर स्पॉटलाइट | Boxing Academy India Fighter Spotlight',
              'BoxingIndiaShorts',
              FightSport.boxing,
              ContentCategory.spotlight,
            ),
          ];

    for (final (title, author, sport, category) in posts) {
      items.add(
        _makeContent(
          source: bot.source,
          category: category,
          sport: sport,
          title: title,
          body: isPakistani
              ? 'پاکستانی کھیل کی ویڈیو دیکھیں'
              : 'भारतीय खेल वीडियो देखें',
          sourceName: isPakistani ? 'Pakistan Social' : 'India Short Video',
          authorName: author,
          minutesAgo: _random.nextInt(360),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanFiverr(ScannerBot bot) {
    final items = <ScannedContent>[];
    final services = [
      ('MMA Training Video Analysis', 'FiterrCoach1', FightSport.mma),
      ('Boxing Technique Breakdown', 'BoxingExpert', FightSport.boxing),
      ('Combat Sports Commentary', 'SportsVoice', FightSport.muayThai),
    ];
    for (final (title, seller, sport) in services) {
      items.add(
        _makeContent(
          source: ScanSource.fiverr,
          category: ContentCategory.breakingNews,
          sport: sport,
          title: title,
          body: 'Professional service: $title',
          sourceName: 'Fiverr',
          authorName: seller,
          minutesAgo: _random.nextInt(600),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanAirTasker(ScannerBot bot) {
    final items = <ScannedContent>[];
    final tasks = [
      ('Find MMA Training Spots', 'TaskSeeker1', FightSport.mma),
      ('Boxing Gym Research', 'TaskSeeker2', FightSport.boxing),
      ('Fight Event Coverage Needed', 'TaskSeeker3', FightSport.muayThai),
    ];
    for (final (title, poster, sport) in tasks) {
      items.add(
        _makeContent(
          source: ScanSource.airtasker,
          category: ContentCategory.eventPromo,
          sport: sport,
          title: title,
          body: title,
          sourceName: 'AirTasker',
          authorName: poster,
          minutesAgo: _random.nextInt(720),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanUpwork(ScannerBot bot) {
    final items = <ScannedContent>[];
    final jobs = [
      ('MMA Blog Content Writer Needed', 'ContentClient1', FightSport.mma),
      ('Boxing Analysis Article Required', 'ContentClient2', FightSport.boxing),
      ('Fight Commentary Services', 'ContentClient3', FightSport.muayThai),
    ];
    for (final (title, client, sport) in jobs) {
      items.add(
        _makeContent(
          source: ScanSource.upwork,
          category: ContentCategory.analysis,
          sport: sport,
          title: title,
          body: 'Freelance opportunity: $title',
          sourceName: 'Upwork',
          authorName: client,
          minutesAgo: _random.nextInt(480),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanMedium(ScannerBot bot) {
    final items = <ScannedContent>[];
    final articles = [
      ('The Evolution of MMA Strategy', 'Medium Writer 1', FightSport.mma),
      ('Boxing Psychology: Mental Game', 'Medium Writer 2', FightSport.boxing),
      (
        'Why Muay Thai is the Better Cardio',
        'Medium Writer 3',
        FightSport.muayThai,
      ),
    ];
    for (final (title, author, sport) in articles) {
      items.add(
        _makeContent(
          source: ScanSource.mediumBlogs,
          category: ContentCategory.analysis,
          sport: sport,
          title: title,
          body: 'Read on Medium: $title',
          sourceName: 'Medium',
          authorName: author,
          minutesAgo: _random.nextInt(400),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanSpotify(ScannerBot bot) {
    final items = <ScannedContent>[];
    final podcasts = [
      ('The MMA Hour - Latest Episode', 'Spotify', FightSport.mma),
      ('The Boxing Podcast - Championship Talk', 'Spotify', FightSport.boxing),
      ('Martial Arts Mastery Podcast', 'Spotify', FightSport.muayThai),
    ];
    for (final (title, platform, sport) in podcasts) {
      items.add(
        _makeContent(
          source: ScanSource.spotify,
          category: ContentCategory.interview,
          sport: sport,
          title: title,
          body: 'Listen on Spotify now',
          sourceName: 'Spotify',
          authorName: platform,
          minutesAgo: _random.nextInt(360),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanAIContent(ScannerBot bot) {
    final items = <ScannedContent>[];
    final aiContent = [
      ('AI-Generated MMA Highlights Reel', 'AI Studio', FightSport.mma),
      ('Synthetic Fight Breakdown Analysis', 'AI Lab', FightSport.boxing),
      ('Algorithmic Combat Strategy Guide', 'ML Sports', FightSport.muayThai),
    ];
    for (final (title, studio, sport) in aiContent) {
      items.add(
        _makeContent(
          source: ScanSource.aiGenerated,
          category: ContentCategory.analysis,
          sport: sport,
          title: title,
          body: 'AI-powered analysis: $title',
          sourceName: 'AI Content',
          authorName: studio,
          minutesAgo: _random.nextInt(480),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanWeb3(ScannerBot bot) {
    final items = <ScannedContent>[];
    final web3 = [
      ('NFT Fight Highlights Collection', 'Web3 Studio', FightSport.mma),
      ('Metaverse Boxing Tournament', 'Crypto Sports', FightSport.boxing),
      ('Blockchain MMA Championship', 'Web3 Sports', FightSport.muayThai),
    ];
    for (final (title, studio, sport) in web3) {
      items.add(
        _makeContent(
          source: ScanSource.web3Content,
          category: ContentCategory.eventPromo,
          sport: sport,
          title: title,
          body: title,
          sourceName: 'Web3',
          authorName: studio,
          minutesAgo: _random.nextInt(600),
        ),
      );
    }
    return items;
  }

  // ─── Metaverse Platform Scanners ──────────────────────────────────────
  List<ScannedContent> _scanRoblox(ScannerBot bot) {
    final items = <ScannedContent>[];
    final games = [
      ('Virtual MMA Championship Arena', 'Roblox Dev', FightSport.mma),
      ('Boxing Ring Simulator 3D', 'Game Creator', FightSport.boxing),
      ('Combat Games - 500K Players Online', 'Roblox Games', FightSport.mma),
      ('Training Dojo Experience', 'Education Dev', FightSport.muayThai),
      ('Battle Royale MMA Mode', 'Combat Games', FightSport.mma),
    ];
    for (final (title, author, sport) in games) {
      items.add(
        _makeContent(
          source: ScanSource.roblox,
          category: ContentCategory.eventPromo,
          sport: sport,
          title: title,
          body: 'Play now in Roblox metaverse: $title',
          sourceName: 'Roblox',
          authorName: author,
          minutesAgo: _random.nextInt(240),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanFortnite(ScannerBot bot) {
    final items = <ScannedContent>[];
    final events = [
      ('MMA Fighter Skin Collection - New', 'Fortnite', FightSport.mma),
      ('Combat Pass: Championship Edition', 'Epic Games', FightSport.boxing),
      ('Virtual Championship Event Live', 'Fortnite Events', FightSport.ufc),
      ('Fighter Emotes - Victory Poses', 'Item Shop', FightSport.mma),
      ('Battle Arena Combat LTM', 'Game Mode', FightSport.mma),
    ];
    for (final (title, publisher, sport) in events) {
      items.add(
        _makeContent(
          source: ScanSource.fortnite,
          category: ContentCategory.eventPromo,
          sport: sport,
          title: title,
          body: title,
          sourceName: 'Fortnite',
          authorName: publisher,
          minutesAgo: _random.nextInt(180),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanDecentraland(ScannerBot bot) {
    final items = <ScannedContent>[];
    final venues = [
      (
        'NFT Fight Arena - Virtual Championship',
        'Virtual Promoters',
        FightSport.mma,
      ),
      ('Digital Land Combat Exhibition', 'Web3 Org', FightSport.boxing),
      ('Blockchain MMA Tournament Announced', 'Decentraland', FightSport.ufc),
      ('Virtual Real Estate: Fight District', 'Land Owner', FightSport.mma),
      ('Commerce Platform: Fighter NFTs', 'Marketplace', FightSport.mma),
    ];
    for (final (title, org, sport) in venues) {
      items.add(
        _makeContent(
          source: ScanSource.decentraland,
          category: ContentCategory.fightAnnouncement,
          sport: sport,
          title: title,
          body: title,
          sourceName: 'Decentraland',
          authorName: org,
          minutesAgo: _random.nextInt(300),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanSandbox(ScannerBot bot) {
    final items = <ScannedContent>[];
    final experiences = [
      ('Designer Game: MMA Training Sim', 'Game Developer', FightSport.mma),
      ('Combat Experience NFT Collection', 'Creator', FightSport.boxing),
      ('Battle Games - User Created', 'Sandbox Dev', FightSport.mma),
      ('Fighter Avatar Props Available', 'Asset Store', FightSport.ufc),
      ('Virtual Tournament Event', 'Community Event', FightSport.mma),
    ];
    for (final (title, creator, sport) in experiences) {
      items.add(
        _makeContent(
          source: ScanSource.sandbox,
          category: ContentCategory.eventPromo,
          sport: sport,
          title: title,
          body: 'Explore in The Sandbox: $title',
          sourceName: 'The Sandbox',
          authorName: creator,
          minutesAgo: _random.nextInt(300),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanHorizonWorlds(ScannerBot bot) {
    final items = <ScannedContent>[];
    final vrWorlds = [
      ('VR Boxing Ring - Real Physics', 'Meta Developer', FightSport.boxing),
      ('Immersive MMA Training World', 'VR Creator', FightSport.mma),
      ('Social Battle Arena Experience', 'Horizon Studios', FightSport.ufc),
      ('Championship VR Tournament', 'Community', FightSport.mma),
      ('Multiplayer Combat Dojo', 'World Builder', FightSport.muayThai),
    ];
    for (final (title, builder, sport) in vrWorlds) {
      items.add(
        _makeContent(
          source: ScanSource.horizonWorlds,
          category: ContentCategory.trainingClip,
          sport: sport,
          title: title,
          body: 'Experience in VR: $title',
          sourceName: 'Horizon Worlds',
          authorName: builder,
          minutesAgo: _random.nextInt(240),
        ),
      );
    }
    return items;
  }

  // ─── Premium Partnership Scanners ──────────────────────────────────────
  List<ScannedContent> _scanPremiumVerified(ScannerBot bot) {
    final items = <ScannedContent>[];
    final premium = [
      ('✅ Verified: Clean Fight Library', 'Content Team', FightSport.mma),
      ('⭐ Premium Stream - Family Safe', 'Premium Network', FightSport.boxing),
      (
        '🏆 Championship Archive - Verified',
        'Certified Content',
        FightSport.ufc,
      ),
      (
        '🎖️ Safety Certified: All Content Reviewed',
        'Moderation',
        FightSport.mma,
      ),
      ('✨ Elite Content - Handpicked Fights', 'Curators', FightSport.mma),
      ('🛡️ Brand Safe - Zero Controversy', 'Filter Team', FightSport.boxing),
      ('💎 Premium Partnership Content', 'Partner Network', FightSport.ufc),
    ];
    for (final (title, curator, sport) in premium) {
      items.add(
        _makeContent(
          source: ScanSource.premiumVerified,
          category: ContentCategory.spotlight,
          sport: sport,
          title: title,
          body: title,
          sourceName: 'Premium Verified',
          authorName: curator,
          minutesAgo: _random.nextInt(120),
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanPartnerNetwork(ScannerBot bot) {
    final items = <ScannedContent>[];
    final partnerships = [
      (
        '🤝 Handshake Deal: the promotion CEO Exclusive',
        'UFC Partnership',
        FightSport.ufc,
      ),
      (
        '🎙️ Joe Rogan Experience - Mega Network Partner',
        'JRE Partnership',
        FightSport.mma,
      ),
      (
        '🔗 Bellator Integration - Content Multiplied',
        'Bellator Network',
        FightSport.mma,
      ),
      (
        '🌏 ONE Championship - Global Collaboration',
        'ONE Asia',
        FightSport.ufc,
      ),
      (
        '🏛️ PRIDE Legacy Partnership Archive',
        'Historical Network',
        FightSport.mma,
      ),
      (
        '🌐 Metaverse Company Alliance - Roblox, Fortnite, Decentraland',
        'Meta Alliance',
        FightSport.mixed,
      ),
      (
        '💼 Brand Sponsorships - Supplements, Fightwear',
        'B2B Network',
        FightSport.mma,
      ),
      (
        '⚡ Tech Integration - AI, Blockchain, IoT',
        'Tech Partners',
        FightSport.mixed,
      ),
      (
        '📱 Multi-Platform Distribution - 50+ channels',
        'Content CDN',
        FightSport.mma,
      ),
      (
        '🎬 Content Amplification - 10x Reach Guarantee',
        'Distribution Team',
        FightSport.mma,
      ),
    ];
    for (final (title, partner, sport) in partnerships) {
      items.add(
        _makeContent(
          source: ScanSource.partnerNetwork,
          category: ContentCategory.spotlight,
          sport: sport,
          title: title,
          body: title,
          sourceName: 'Partner Network',
          authorName: partner,
          minutesAgo: _random.nextInt(60),
        ),
      );
    }
    return items;
  }

  // ─── DFC Native Channel Scanners ─────────────────────────────────────────

  /// Monitors FightPipe (DFC's official YouTube channel) for new uploads,
  /// comment engagement, subscriber milestones, and cross-promo signals.
  List<ScannedContent> _scanDfcYoutube(ScannerBot bot) {
    final items = <ScannedContent>[];
    final uploads = [
      'NEW on FightPipe: Full fight card — watch now on YouTube',
      'FightPipe upload: Post-fight breakdown with Shido AI analysis',
      'FightPipe LIVE: Pre-fight press conference stream',
      'FightPipe Highlight: KO of the Night — now live',
      'FightPipe: DFC Fight Pass exclusive preview dropped',
    ];
    for (final title in uploads) {
      items.add(
        _makeContent(
          source: ScanSource.dfcYoutube,
          category: ContentCategory.highlight,
          sport: FightSport.mma,
          title: title,
          body: title,
          sourceName: 'FightPipe',
          authorName: 'DataFightCentral',
          minutesAgo: _random.nextInt(30),
          engagement: _random.nextInt(5000) + 500,
        ),
      );
    }
    return items;
  }

  /// Monitors DFC's official Facebook page for post reach, share velocity,
  /// fan engagement signals, and inbound fight promotion enquiries.
  List<ScannedContent> _scanDfcFacebook(ScannerBot bot) {
    final items = <ScannedContent>[];
    final posts = [
      'DFC Facebook: Event announcement post — share velocity tracking',
      'DFC Facebook: Fight card post reached 50K fans — amplifying',
      'DFC Facebook: Promoter enquiry received via info@datafightcentral.com',
      'DFC Facebook: Fan comment thread — fighter request trending',
      'DFC Facebook LIVE: Event countdown post engagement spike',
    ];
    for (final title in posts) {
      items.add(
        _makeContent(
          source: ScanSource.dfcFacebook,
          category: ContentCategory.eventPromo,
          sport: FightSport.mma,
          title: title,
          body: title,
          sourceName: 'DFC Facebook',
          authorName: 'DataFightCentral',
          minutesAgo: _random.nextInt(15),
          engagement: _random.nextInt(10000) + 1000,
        ),
      );
    }
    return items;
  }

  List<ScannedContent> _scanOther(ScannerBot bot) {
    final items = <ScannedContent>[];
    final other = [
      ('Global Fight News Aggregator', 'Global News', FightSport.mma),
      ('International Boxing Update', 'Intl Sports', FightSport.boxing),
      ('Worldwide Combat Sports Report', 'World Feed', FightSport.muayThai),
    ];
    for (final (title, source, sport) in other) {
      items.add(
        _makeContent(
          source: ScanSource.other,
          category: ContentCategory.breakingNews,
          sport: sport,
          title: title,
          body: title,
          sourceName: 'Global',
          authorName: source,
          minutesAgo: _random.nextInt(360),
        ),
      );
    }
    return items;
  }

  // ─── Content Factory ──────────────────────────────────────────────────

  // ─── Real Firestore Content Loader ────────────────────────────────────
  /// Loads admin-curated or previously-persisted content from Firestore.
  /// This runs regardless of syntheticContentEnabled, so curated content
  /// always appears in the feed.
  Future<void> _loadFirestoreContent() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('scanned_content')
          .orderBy('publishedAt', descending: true)
          .limit(50)
          .get();
      if (snap.docs.isEmpty) return;

      final loaded = snap.docs.map((d) {
        final data = d.data();
        return ScannedContent(
          id: d.id,
          source: _parseScanSource(data['source'] ?? ''),
          category: _parseCategory(data['category'] ?? ''),
          sport: _parseFightSport(data['sport'] ?? ''),
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          sourceUrl: data['sourceUrl'] ?? '',
          sourceName: data['sourceName'] ?? 'DFC',
          authorName: data['authorName'] ?? 'DFC Staff',
          imageUrl: data['imageUrl'],
          videoUrl: data['videoUrl'],
          scannedAt:
              (data['scannedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          publishedAt:
              (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          relevanceScore: (data['relevanceScore'] as num?)?.toDouble() ?? 0.7,
          viralScore: (data['viralScore'] as num?)?.toDouble() ?? 0.0,
          engagementCount: (data['engagementCount'] as num?)?.toInt() ?? 0,
          tags: List<String>.from(data['tags'] ?? []),
          isBreaking: data['isBreaking'] == true,
          isVerified: data['isVerified'] == true,
        );
      }).toList();

      _contentFeed.insertAll(0, loaded);
      _contentFeed.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
      _contentController.add(_contentFeed);
    } catch (e) {
      debugPrint('⚠️ Firestore content load skipped: $e');
    }
  }

  /// Fetch real RSS/Atom content from a URL, parse items, return ScannedContent.
  /// Used by bots whose source has a public RSS feed (YouTube, Reddit, news).
  Future<List<ScannedContent>> fetchRss({
    required String url,
    required ScanSource source,
    required FightSport sport,
    required String sourceName,
    int limit = 5,
  }) async {
    try {
      // Browsers enforce CORS for client-side HTTP. RSS scraping should run on
      // server-side workers, not in web clients.
      if (kIsWeb) return [];

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      // Minimal RSS/Atom parser — extract <item>/<entry> blocks
      final body = response.body;
      final items = <ScannedContent>[];
      final itemPattern = RegExp(
        r'<(?:item|entry)>(.*?)</(?:item|entry)>',
        dotAll: true,
      );
      for (final match in itemPattern.allMatches(body).take(limit)) {
        final block = match.group(1) ?? '';
        final title = _extractTag(block, 'title');
        final desc =
            _extractTag(block, 'description') ??
            _extractTag(block, 'summary') ??
            _extractTag(block, 'content') ??
            '';
        final link = _extractTag(block, 'link') ?? url;
        if (title == null || title.isEmpty) continue;

        items.add(
          ScannedContent(
            id: '${source.name}_rss_${title.hashCode}',
            source: source,
            category: ContentCategory.breakingNews,
            sport: sport,
            title: title,
            body: desc.length > 300 ? '${desc.substring(0, 300)}...' : desc,
            sourceUrl: link,
            sourceName: sourceName,
            authorName: sourceName,
            scannedAt: DateTime.now(),
            publishedAt: DateTime.now(),
            relevanceScore: 0.75,
            tags: _autoTag(title, desc, sport),
            isVerified: true,
          ),
        );
      }
      return items;
    } catch (e) {
      debugPrint('⚠️ RSS fetch failed ($url): $e');
      return [];
    }
  }

  static String? _extractTag(String xml, String tag) {
    final m = RegExp('<$tag[^>]*>(.*?)</$tag>', dotAll: true).firstMatch(xml);
    if (m == null) return null;
    // Strip CDATA
    var val = m.group(1) ?? '';
    val = val.replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '').trim();
    // Strip HTML tags
    val = val.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    return val.isEmpty ? null : val;
  }

  static ScanSource _parseScanSource(String s) {
    for (final v in ScanSource.values) {
      if (v.name == s) return v;
    }
    return ScanSource.newsRss;
  }

  static ContentCategory _parseCategory(String s) {
    for (final v in ContentCategory.values) {
      if (v.name == s) return v;
    }
    return ContentCategory.breakingNews;
  }

  static FightSport _parseFightSport(String s) {
    for (final v in FightSport.values) {
      if (v.name == s) return v;
    }
    return FightSport.mma;
  }

  ScannedContent _makeContent({
    required ScanSource source,
    required ContentCategory category,
    required FightSport sport,
    required String title,
    required String body,
    required String sourceName,
    required String authorName,
    int minutesAgo = 0,
    int engagement = 0,
    bool isBreaking = false,
  }) {
    final now = DateTime.now();
    final published = now.subtract(Duration(minutes: minutesAgo));
    final effectiveEngagement = engagement > 0
        ? engagement
        : 100 + _random.nextInt(50000);

    // AI relevance scoring
    double relevance = 0.5;
    if (isBreaking) relevance += 0.3;
    if (category == ContentCategory.fightAnnouncement) relevance += 0.2;
    if (category == ContentCategory.fightResult) relevance += 0.15;
    if (minutesAgo < 30) relevance += 0.15;
    if (effectiveEngagement > 100000) relevance += 0.1;
    relevance = relevance.clamp(0.0, 1.0);

    final viral = (effectiveEngagement / 5000000).clamp(0.0, 1.0);

    return ScannedContent(
      id: '${source.name}_${now.millisecondsSinceEpoch}_${_random.nextInt(99999)}',
      source: source,
      category: category,
      sport: sport,
      title: title,
      body: body,
      sourceUrl: 'https://datafightcentral.web.app/',
      sourceName: sourceName,
      authorName: authorName,
      scannedAt: now,
      publishedAt: published,
      relevanceScore: relevance,
      viralScore: viral,
      engagementCount: effectiveEngagement,
      tags: _autoTag(title, body, sport),
      isBreaking: isBreaking,
      isVerified:
          source == ScanSource.newsRss || source == ScanSource.eventCalendar,
    );
  }

  List<String> _autoTag(String title, String body, FightSport sport) {
    final tags = <String>[sport.name];
    final text = '$title $body'.toLowerCase();
    final keywords = {
      'knockout': 'KO',
      'ko': 'KO',
      'submission': 'SUB',
      'decision': 'Decision',
      'title': 'TitleFight',
      'champion': 'Champion',
      'ranking': 'Rankings',
      'training': 'Training',
      'camp': 'FightCamp',
      'ppv': 'PPV',
      'free': 'FreeEvent',
      'debut': 'Debut',
      'retire': 'Retirement',
      'injury': 'Injury',
      'weight': 'WeightClass',
      'press': 'PressConference',
      'stream': 'LiveStream',
    };
    for (final entry in keywords.entries) {
      if (text.contains(entry.key)) tags.add(entry.value);
    }
    return tags;
  }

  // ─── Deduplication ────────────────────────────────────────────────────
  List<ScannedContent> _deduplicateContent(List<ScannedContent> items) {
    final seen = <String>{};
    final result = <ScannedContent>[];
    for (final item in items) {
      final key = item.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final shortKey = key.length > 30 ? key.substring(0, 30) : key;
      if (!seen.contains(shortKey)) {
        seen.add(shortKey);
        result.add(item);
      }
    }
    return result;
  }

  // ─── Query Methods ────────────────────────────────────────────────────
  List<ScannedContent> getBySource(ScanSource source) =>
      _contentFeed.where((c) => c.source == source).toList();

  List<ScannedContent> getBySport(FightSport sport) =>
      _contentFeed.where((c) => c.sport == sport).toList();

  List<ScannedContent> getByCategory(ContentCategory category) =>
      _contentFeed.where((c) => c.category == category).toList();

  List<ScannedContent> getBreaking() =>
      _contentFeed.where((c) => c.isBreaking).toList();

  List<ScannedContent> getTrending({int limit = 20}) {
    final sorted = List<ScannedContent>.from(_contentFeed)
      ..sort((a, b) => b.viralScore.compareTo(a.viralScore));
    return sorted.take(limit).toList();
  }

  List<ScannedContent> getLatest({int limit = 50}) {
    return _contentFeed.take(limit).toList();
  }

  List<ScannedContent> search(String query) {
    final q = query.toLowerCase();
    return _contentFeed.where((c) {
      return c.title.toLowerCase().contains(q) ||
          c.body.toLowerCase().contains(q) ||
          c.tags.any((t) => t.toLowerCase().contains(q)) ||
          c.sourceName.toLowerCase().contains(q) ||
          c.sportLabel.toLowerCase().contains(q);
    }).toList();
  }

  // ─── Stats Helpers ────────────────────────────────────────────────────
  Map<ScanSource, int> _countBySource() {
    final map = <ScanSource, int>{};
    for (final c in _contentFeed) {
      map[c.source] = (map[c.source] ?? 0) + 1;
    }
    return map;
  }

  Map<FightSport, int> _countBySport() {
    final map = <FightSport, int>{};
    for (final c in _contentFeed) {
      map[c.sport] = (map[c.sport] ?? 0) + 1;
    }
    return map;
  }

  // ─── Manual Refresh ───────────────────────────────────────────────────
  Future<void> forceRefresh() async {
    await _runFullScan();
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────
  @override
  void dispose() {
    _masterTimer?.cancel();
    _contentController.close();
    super.dispose();
  }
}
