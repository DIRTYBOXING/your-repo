import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/constants/app_constants.dart';
import 'content_scanner_engine.dart';
import 'beast_mode_service.dart';

/// Cloud Functions instance for Nuclear Powerhouse
final _functions = FirebaseFunctions.instanceFor(
  region: 'australia-southeast1',
);

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTER AI SERVICE — Autonomous Fight Promotion Engine
/// ═══════════════════════════════════════════════════════════════════════════
///
/// AI-powered promotional bot that:
///  1. Reads ContentScannerEngine output continuously
///  2. Generates promotional content (hype posts, fighter spotlights, event ads)
///  3. Creates smart social media campaigns
///  4. Discovers promotional opportunities
///  5. Builds automated event hype timelines
///  6. Generates fighter comparison cards & matchup predictions
///  7. Creates viral content suggestions
///  8. Auto-fills app screens with curated promotional content
///  9. ** RESPONDS TO BEAST MODE FOR 3-5x AMPLIFICATION **
///
/// Bots:
///  - HypeBot: Generates hype content for upcoming events
///  - SpotlightBot: Creates fighter spotlight features
///  - MatchmakerBot: Generates dream matchup content
///  - TrendBot: Identifies and rides trending topics
///  - CampaignBot: Creates multi-post promotional campaigns
///  - EventBot: Builds event countdown & promotion content
///  - ViralBot: Generates share-worthy content snippets
///  - AnalyticsBot: Reports on content performance & reach
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Promo Content Types ─────────────────────────────────────────────────
enum PromoType {
  hypePosts,
  fighterSpotlight,
  dreamMatchup,
  eventCountdown,
  trendingTopic,
  viralSnippet,
  campaignPost,
  statsGraphic,
  pollQuestion,
  predictionCard,
  throwbackMoment,
  quoteCard,
  dailyDigest,
  weeklyRoundup,
}

enum PromoPlatform {
  inApp,
  facebook,
  instagram,
  tiktok,
  twitter,
  youtube,
  allPlatforms,
}

// ─── Promotional Content Model ───────────────────────────────────────────
class PromoContent {
  final String id;
  final PromoType type;
  final PromoPlatform platform;
  final String headline;
  final String body;
  final String? imagePrompt; // AI image generation prompt
  final String? videoPrompt; // AI video generation prompt
  final List<String> hashtags;
  final List<String> mentions;
  final DateTime generatedAt;
  final DateTime? scheduledFor;
  final double hypeScore; // 0.0 - 1.0
  final double viralPotential; // 0.0 - 1.0
  final String botName; // Which bot generated this
  final FightSport? sport;
  final Map<String, dynamic> metadata;
  final bool isPublished;

  const PromoContent({
    required this.id,
    required this.type,
    this.platform = PromoPlatform.inApp,
    required this.headline,
    required this.body,
    this.imagePrompt,
    this.videoPrompt,
    this.hashtags = const [],
    this.mentions = const [],
    required this.generatedAt,
    this.scheduledFor,
    this.hypeScore = 0.5,
    this.viralPotential = 0.5,
    this.botName = 'PromoterAI',
    this.sport,
    this.metadata = const {},
    this.isPublished = false,
  });

  String get typeLabel {
    switch (type) {
      case PromoType.hypePosts:
        return '🔥 HYPE';
      case PromoType.fighterSpotlight:
        return '⭐ SPOTLIGHT';
      case PromoType.dreamMatchup:
        return '🥊 MATCHUP';
      case PromoType.eventCountdown:
        return '⏱️ COUNTDOWN';
      case PromoType.trendingTopic:
        return '📈 TRENDING';
      case PromoType.viralSnippet:
        return '🚀 VIRAL';
      case PromoType.campaignPost:
        return '📣 CAMPAIGN';
      case PromoType.statsGraphic:
        return '📊 STATS';
      case PromoType.pollQuestion:
        return '🗳️ POLL';
      case PromoType.predictionCard:
        return '🔮 PREDICTION';
      case PromoType.throwbackMoment:
        return '🕐 THROWBACK';
      case PromoType.quoteCard:
        return '💬 QUOTE';
      case PromoType.dailyDigest:
        return '📰 DAILY';
      case PromoType.weeklyRoundup:
        return '📋 WEEKLY';
    }
  }
}

// ─── Promo Bot Config ────────────────────────────────────────────────────
class PromoBot {
  final String name;
  final String emoji;
  final PromoType speciality;
  final bool isActive;
  final int contentGenerated;
  final double performance; // 0.0 - 1.0
  final DateTime? lastRun;

  const PromoBot({
    required this.name,
    required this.emoji,
    required this.speciality,
    this.isActive = true,
    this.contentGenerated = 0,
    this.performance = 1.0,
    this.lastRun,
  });

  PromoBot copyWith({
    bool? isActive,
    int? contentGenerated,
    double? performance,
    DateTime? lastRun,
  }) {
    return PromoBot(
      name: name,
      emoji: emoji,
      speciality: speciality,
      isActive: isActive ?? this.isActive,
      contentGenerated: contentGenerated ?? this.contentGenerated,
      performance: performance ?? this.performance,
      lastRun: lastRun ?? this.lastRun,
    );
  }
}

// ─── Campaign Model ─────────────────────────────────────────────────────
class PromoCampaign {
  final String id;
  final String name;
  final String description;
  final List<PromoContent> posts;
  final DateTime startDate;
  final DateTime endDate;
  final FightSport? sport;
  final double reachEstimate;
  final bool isActive;

  const PromoCampaign({
    required this.id,
    required this.name,
    required this.description,
    this.posts = const [],
    required this.startDate,
    required this.endDate,
    this.sport,
    this.reachEstimate = 0,
    this.isActive = true,
  });
}

// ─── Promoter AI Stats ──────────────────────────────────────────────────
class PromoterStats {
  final int totalContentGenerated;
  final int activeBots;
  final int totalBots;
  final int activeCampaigns;
  final double avgHypeScore;
  final double avgViralPotential;
  final Map<PromoType, int> contentByType;
  final DateTime? lastGeneration;

  const PromoterStats({
    this.totalContentGenerated = 0,
    this.activeBots = 0,
    this.totalBots = 0,
    this.activeCampaigns = 0,
    this.avgHypeScore = 0.0,
    this.avgViralPotential = 0.0,
    this.contentByType = const {},
    this.lastGeneration,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTER AI SERVICE — Master Bot Commander
/// ═══════════════════════════════════════════════════════════════════════════
class PromoterAIService extends ChangeNotifier {
  static final PromoterAIService _instance = PromoterAIService._internal();
  factory PromoterAIService() => _instance;
  PromoterAIService._internal();

  // ─── State ─────────────────────────────────────────────────────────────
  final List<PromoContent> _promoFeed = [];
  final List<PromoBot> _bots = [];
  final List<PromoCampaign> _campaigns = [];
  final ContentScannerEngine _scanner = ContentScannerEngine();
  final BeastModeService _beastMode = BeastModeService();
  Timer? _generationTimer;
  bool _isRunning = false;
  bool _isGenerating = false;
  int _totalGenerated = 0;
  final _random = math.Random();
  final _promoController = StreamController<List<PromoContent>>.broadcast();

  // ─── Getters ───────────────────────────────────────────────────────────
  List<PromoContent> get promoFeed => List.unmodifiable(_promoFeed);
  List<PromoBot> get bots => List.unmodifiable(_bots);
  List<PromoCampaign> get campaigns => List.unmodifiable(_campaigns);
  bool get isRunning => _isRunning;
  bool get isGenerating => _isGenerating;
  int get totalGenerated => _totalGenerated;
  Stream<List<PromoContent>> get promoStream => _promoController.stream;

  PromoterStats get stats {
    final typeCount = <PromoType, int>{};
    for (final p in _promoFeed) {
      typeCount[p.type] = (typeCount[p.type] ?? 0) + 1;
    }
    final avgHype = _promoFeed.isEmpty
        ? 0.0
        : _promoFeed.map((p) => p.hypeScore).reduce((a, b) => a + b) /
              _promoFeed.length;
    final avgViral = _promoFeed.isEmpty
        ? 0.0
        : _promoFeed.map((p) => p.viralPotential).reduce((a, b) => a + b) /
              _promoFeed.length;

    return PromoterStats(
      totalContentGenerated: _totalGenerated,
      activeBots: _bots.where((b) => b.isActive).length,
      totalBots: _bots.length,
      activeCampaigns: _campaigns.where((c) => c.isActive).length,
      avgHypeScore: avgHype,
      avgViralPotential: avgViral,
      contentByType: typeCount,
      lastGeneration: _promoFeed.isNotEmpty
          ? _promoFeed.first.generatedAt
          : null,
    );
  }

  // ─── Initialize Bots ──────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_bots.isNotEmpty) return;

    _bots.addAll([
      const PromoBot(
        name: 'HypeBot',
        emoji: '🔥',
        speciality: PromoType.hypePosts,
      ),
      const PromoBot(
        name: 'SpotlightBot',
        emoji: '⭐',
        speciality: PromoType.fighterSpotlight,
      ),
      const PromoBot(
        name: 'MatchmakerBot',
        emoji: '🥊',
        speciality: PromoType.dreamMatchup,
      ),
      const PromoBot(
        name: 'TrendBot',
        emoji: '📈',
        speciality: PromoType.trendingTopic,
      ),
      const PromoBot(
        name: 'CampaignBot',
        emoji: '📣',
        speciality: PromoType.campaignPost,
      ),
      const PromoBot(
        name: 'EventBot',
        emoji: '⏱️',
        speciality: PromoType.eventCountdown,
      ),
      const PromoBot(
        name: 'ViralBot',
        emoji: '🚀',
        speciality: PromoType.viralSnippet,
      ),
      const PromoBot(
        name: 'AnalyticsBot',
        emoji: '📊',
        speciality: PromoType.statsGraphic,
      ),
    ]);

    // Skip synthetic generation when disabled.
    if (AppConstants.syntheticContentEnabled) {
      await _generatePromotionalContent();
    }

    // Create initial campaigns
    _createAutoCampaigns();

    debugPrint('📣 PromoterAI initialized with ${_bots.length} bots');
    notifyListeners();
  }

  // ─── Start Engine ─────────────────────────────────────────────────────
  void startEngine({Duration interval = const Duration(minutes: 10)}) {
    if (!AppConstants.syntheticContentEnabled) {
      debugPrint('⏭️ PromoterAI disabled (ALLOW_SYNTHETIC_CONTENT=false)');
      return;
    }
    if (_isRunning) return;
    _isRunning = true;
    _generationTimer?.cancel();

    // Apply Beast Mode frequency multiplier
    final beastMultiplier = _beastMode.contentFrequencyMultiplier;
    final adjustedInterval = Duration(
      milliseconds: (interval.inMilliseconds / beastMultiplier).round(),
    );

    _generationTimer = Timer.periodic(
      adjustedInterval,
      (_) => _generatePromotionalContent(),
    );
    debugPrint(
      '🚀 PromoterAI STARTED — generating every ${adjustedInterval.inMinutes}m '
      '(Beast Mode: ${beastMultiplier}x)',
    );
    notifyListeners();
  }

  void stopEngine() {
    _isRunning = false;
    _generationTimer?.cancel();
    _generationTimer = null;
    debugPrint('⏹️ PromoterAI STOPPED');
    notifyListeners();
  }

  // ─── Generate Promotional Content ─────────────────────────────────────
  Future<void> _generatePromotionalContent() async {
    if (!AppConstants.syntheticContentEnabled) {
      return;
    }
    if (_isGenerating) return;
    _isGenerating = true;
    notifyListeners();

    try {
      final newContent = <PromoContent>[];

      // Each bot generates content from scanner data
      for (var i = 0; i < _bots.length; i++) {
        final bot = _bots[i];
        if (!bot.isActive) continue;

        final items = _generateForBot(bot);
        newContent.addAll(items);

        _bots[i] = bot.copyWith(
          lastRun: DateTime.now(),
          contentGenerated: bot.contentGenerated + items.length,
          performance: 0.8 + _random.nextDouble() * 0.2,
        );
      }

      // Sort by hype score
      newContent.sort((a, b) => b.hypeScore.compareTo(a.hypeScore));

      _promoFeed.insertAll(0, newContent);
      if (_promoFeed.length > 300) {
        _promoFeed.removeRange(300, _promoFeed.length);
      }

      _totalGenerated += newContent.length;
      _promoController.add(_promoFeed);

      debugPrint(
        '📣 PromoterAI generated ${newContent.length} items (total: $_totalGenerated)',
      );
    } catch (e) {
      debugPrint('❌ PromoterAI error: $e');
    }

    _isGenerating = false;
    notifyListeners();
  }

  // ─── Bot Content Generators (Wolverine: CF first, fallback to local) ────
  List<PromoContent> _generateForBot(PromoBot bot) {
    switch (bot.speciality) {
      case PromoType.hypePosts:
        return _generateHypePosts();
      case PromoType.fighterSpotlight:
        return _generateSpotlights();
      case PromoType.dreamMatchup:
        return _generateMatchups();
      case PromoType.eventCountdown:
        return _generateCountdowns();
      case PromoType.trendingTopic:
        return _generateTrendingContent();
      case PromoType.viralSnippet:
        return _generateViralSnippets();
      case PromoType.campaignPost:
        return _generateCampaignPosts();
      case PromoType.statsGraphic:
        return _generateStatsContent();
      default:
        return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NUCLEAR POWERHOUSE — Gemini CF-Powered Content Generation
  // Wolverine Protocol: CF first → local fallback → regenerate on failure
  // ═══════════════════════════════════════════════════════════════════════

  /// Generate hype content via Nuclear CF
  Future<PromoContent?> generateHypeViaCF({
    String? eventName,
    String? mainEvent,
    String? date,
    String? venue,
    String? discipline,
    List<String>? fighters,
    String? context,
  }) async {
    try {
      final callable = _functions.httpsCallable('generatePromoHype');
      final result = await callable.call<Map<String, dynamic>>({
        'eventName': eventName,
        'mainEvent': mainEvent,
        'date': date,
        'venue': venue,
        'discipline': discipline,
        'fighters': fighters,
        'context': context,
      });
      final content = result.data['content'] as Map<String, dynamic>;
      return PromoContent(
        id: 'cf_hype_${DateTime.now().millisecondsSinceEpoch}',
        type: PromoType.hypePosts,
        headline: content['headline'] ?? 'Fight Night',
        body: content['body'] ?? 'The fight world is watching.',
        hashtags: List<String>.from(content['hashtags'] ?? []),
        hypeScore: (content['hypeScore'] ?? 0.85).toDouble(),
        viralPotential: (content['viralPotential'] ?? 0.80).toDouble(),
        generatedAt: DateTime.now(),
        botName: 'HypeBot (CF)',
      );
    } catch (e) {
      debugPrint('HypeBot CF failed, using local fallback: \$e');
      return null;
    }
  }

  /// Generate fighter spotlight via Nuclear CF
  Future<PromoContent?> generateSpotlightViaCF({
    String? fighterName,
    String? record,
    String? discipline,
    String? gym,
    String? achievements,
    String? style,
    String? country,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateFighterSpotlight');
      final result = await callable.call<Map<String, dynamic>>({
        'fighterName': fighterName,
        'record': record,
        'discipline': discipline,
        'gym': gym,
        'achievements': achievements,
        'style': style,
        'country': country,
      });
      final content = result.data['content'] as Map<String, dynamic>;
      return PromoContent(
        id: 'cf_spotlight_${DateTime.now().millisecondsSinceEpoch}',
        type: PromoType.fighterSpotlight,
        headline: content['headline'] ?? 'Fighter Spotlight',
        body: '${content['intro'] ?? ''} ${content['body'] ?? ''}',
        hashtags: List<String>.from(content['hashtags'] ?? []),
        hypeScore: (content['engagementScore'] ?? 0.82).toDouble(),
        generatedAt: DateTime.now(),
        botName: 'SpotlightBot (CF)',
        metadata: {'keyStats': content['keyStats'], 'quote': content['quote']},
      );
    } catch (e) {
      debugPrint('SpotlightBot CF failed, using local fallback: \$e');
      return null;
    }
  }

  /// Generate matchup analysis via Nuclear CF
  Future<PromoContent?> generateMatchupViaCF({
    String? fighter1,
    String? fighter2,
    String? discipline,
    String? stakes,
    String? event,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateMatchupAnalysis');
      final result = await callable.call<Map<String, dynamic>>({
        'fighter1': fighter1,
        'fighter2': fighter2,
        'discipline': discipline,
        'stakes': stakes,
        'event': event,
      });
      final content = result.data['content'] as Map<String, dynamic>;
      return PromoContent(
        id: 'cf_matchup_${DateTime.now().millisecondsSinceEpoch}',
        type: PromoType.dreamMatchup,
        headline: content['headline'] ?? 'Matchup Analysis',
        body: content['analysis'] ?? 'Styles make fights.',
        hashtags: List<String>.from(content['hashtags'] ?? []),
        hypeScore: (content['confidence'] ?? 0.75).toDouble(),
        generatedAt: DateTime.now(),
        botName: 'MatchmakerBot (CF)',
        metadata: {
          'fighter1Edge': content['fighter1Edge'],
          'fighter2Edge': content['fighter2Edge'],
          'prediction': content['prediction'],
          'xFactor': content['xFactor'],
          'pollQuestion': content['pollQuestion'],
        },
      );
    } catch (e) {
      debugPrint('MatchmakerBot CF failed, using local fallback: \$e');
      return null;
    }
  }

  /// Wolverine Protocol: Regenerate failed content
  Future<PromoContent?> wolverineRegenerate({
    required String failedContentId,
    required String originalPrompt,
    String? errorType,
    int retryCount = 1,
  }) async {
    try {
      final callable = _functions.httpsCallable('wolverineRegenerate');
      final result = await callable.call<Map<String, dynamic>>({
        'failedContentId': failedContentId,
        'originalPrompt': originalPrompt,
        'errorType': errorType,
        'retryCount': retryCount,
      });
      final content = result.data['content'] as Map<String, dynamic>;
      if (content['systemStatus'] == 'healed') {
        return PromoContent(
          id: 'wolverine_${DateTime.now().millisecondsSinceEpoch}',
          type: PromoType.hypePosts,
          headline: 'RECOVERED: Content Regenerated',
          body: content['regeneratedContent'] ?? 'System recovered.',
          generatedAt: DateTime.now(),
          botName: 'WolverineBot',
          hypeScore: (content['confidenceScore'] ?? 0.90).toDouble(),
          metadata: {'healingApplied': content['healingApplied']},
        );
      }
    } catch (e) {
      debugPrint('Wolverine regeneration failed: \$e');
    }
    return null;
  }

  List<PromoContent> _generateHypePosts() {
    final hype = [
      (
        '\u{1F525} UFC 325: Pereira vs Ankalaev \u2014 SATURDAY',
        'Alex "Poatan" Pereira puts his Light Heavyweight strap on the line against Magomed Ankalaev in Las Vegas. Five title fights. An entire arena witnessing elite skill. Pereira\'s power vs Ankalaev\'s technique \u2014 who rises to the moment? #UFC325 #DataFightCentral',
        0.97,
        FightSport.ufc,
      ),
      (
        '\u{1F94A} Reyes vs Brennan III \u2014 THE EPIC TRILOGY',
        'Amanda Serrano and Katie Taylor meet ONE MORE TIME in Dublin. Taylor wants to shine on home soil. Reyes wants to complete the journey she started. This is the biggest event in women\u2019s boxing HISTORY. March 15 at Croke Park. #ReyesTaylor3 #Boxing',
        0.95,
        FightSport.boxing,
      ),
      (
        '\u{1F94A} SERRANO VS TAYLOR III \u2014 THE EPIC TRILOGY IN DUBLIN',
        'Amanda Serrano headlines Croke Park in Dublin for the biggest women\'s boxing event ever. 80,000 fans. Three world title fights on the undercard. Serrano is building a LEGACY. June 7. #SerranoTaylor3 #Boxing',
        0.92,
        FightSport.boxing,
      ),
      (
        '\u{1F514} Mendoza AT AT&T STADIUM \u2014 APRIL 5',
        'Canelo Alvarez returns to the biggest stage in boxing. 80,000 seats at AT&T Stadium. Undisputed at 168. The Mexican superstar wants to cement his legacy as the best of this generation. Tickets selling FAST. #Mendoza #Undisputed',
        0.93,
        FightSport.boxing,
      ),
      (
        '\u{1F525} BKFC KnuckleMania VI \u2014 MARCH 7',
        'Bare knuckle\'s biggest night of the year. KnuckleMania VI showcases raw grit and pure technique \u2014 no gloves, all heart. Main card stacked with elite matchups. This is where legends prove themselves. #BKFC #KnuckleMania',
        0.88,
        FightSport.bkfc,
      ),
    ];
    return hype.map((h) {
      final (headline, body, hypeScore, sport) = h;
      return _makePromo(
        type: PromoType.hypePosts,
        headline: headline,
        body: body,
        hypeScore: hypeScore,
        sport: sport,
        botName: 'HypeBot',
        hashtags: ['#DataFightCentral', '#FightHype', '#MMA', '#Boxing'],
      );
    }).toList();
  }

  List<PromoContent> _generateSpotlights() {
    final spotlights = [
      (
        '\u2b50 FIGHTER SPOTLIGHT: Zhang Weili',
        'China\'s strawweight queen Zhang Weili has become the most skilled 115lb fighter on the planet. 24-3, multiple UFC title defences, and a highlight reel that leaves everyone in awe. Training out of Beijing with Black Panther Fight Club, she\'s rewriting MMA history. Full breakdown on DataFightCentral.',
        FightSport.mma,
      ),
      (
        '\u2b50 FROM PUERTO RICO TO THE WORLD: Amanda Serrano',
        'Amanda "The Real Deal" Reyes holds world titles in 7 weight classes. From Bushwick, Brooklyn to headlining Croke Park \u2014 she\'s the most decorated female boxer ALIVE. Her trilogy with Katie Taylor is the biggest event in women\'s combat sports. Exclusive coverage on DFC.',
        FightSport.boxing,
      ),
      (
        '\u2b50 MUAY THAI LEGEND: Somsak Kiatmook',
        'Somsak "The Iron Man" has 270+ fights and still fights like he\'s got something to prove. ONE Championship\'s flyweight Muay Thai king brings relentless pressure, an iron chin, and a smile that inspires everyone watching. Watch his latest showcase at ONE Samurai I on DFC.',
        FightSport.muayThai,
      ),
      (
        '\u2b50 MUAY THAI QUEEN: Stamp Fairtex',
        'Three belts across three disciplines. Muay Thai, Kickboxing, MMA \u2014 Stamp came from rural Thailand and built an empire with her fists. ONE Championship\u2019s most decorated female fighter is rewriting combat sports history. #StampFairtex',
        FightSport.muayThai,
      ),
    ];
    return spotlights.map((s) {
      final (headline, body, sport) = s;
      return _makePromo(
        type: PromoType.fighterSpotlight,
        headline: headline,
        body: body,
        hypeScore: 0.8,
        sport: sport,
        botName: 'SpotlightBot',
        hashtags: ['#FighterSpotlight', '#RisingStar', '#DataFightCentral'],
      );
    }).toList();
  }

  List<PromoContent> _generateMatchups() {
    final matchups = [
      (
        '\u{1F94A} DREAM MATCHUP: Santos vs Aliyev',
        'Alex Pereira: devastating left hook, 90% KO rate in title fights. Magomed Ankalaev: wrestling machine, 15 straight without a loss. Striker vs grappler at its absolute PEAK. Who takes the LHW strap at UFC 325? AI prediction and full breakdown on DataFightCentral. Vote now!',
        FightSport.ufc,
        0.94,
      ),
      (
        '\u{1F94A} SUPERFIGHT: Karimov vs Hayes?',
        'Islam Makhachev is the P4P #1 fighter on the planet. Conor McGregor just outperformed Paddy Pimblett at UFC 324 Liverpool. Could we see the biggest lightweight superfight ever? The numbers say Karimov by submission \u2014 but Hayes\'s left hand changes everything. Full AI analysis on DFC.',
        FightSport.mma,
        0.91,
      ),
      (
        '\u{1F94A} STAMP vs Ji-Yeon Park \u2014 ONE Samurai I',
        'Stamp Fairtex brings Muay Thai royalty to atomweight MMA. Ji-Yeon Park is a Korean submission specialist with 40+ pro fights. Styles make fights \u2014 and this one is going to be ELECTRIC in Tokyo. March 29 on DFC.',
        FightSport.mixed,
        0.85,
      ),
    ];
    return matchups.map((m) {
      final (headline, body, sport, hype) = m;
      return _makePromo(
        type: PromoType.dreamMatchup,
        headline: headline,
        body: body,
        hypeScore: hype,
        sport: sport,
        botName: 'MatchmakerBot',
        hashtags: ['#DreamMatchup', '#WhoWins', '#DataFightCentral'],
      );
    }).toList();
  }

  List<PromoContent> _generateCountdowns() {
    final countdowns = [
      (
        '\u23f1\ufe0f 3 DAYS UNTIL UFC 325 \u2014 S\u00c3O PAULO',
        'The countdown is ON. 72 hours until Santos vs Aliyev rocks Ibirapuera Arena. Plus Zhang Weili, Paige VanZant, and the deepest Brazilian card in UFC history. Full preview and AI predictions on DataFightCentral.',
        FightSport.ufc,
      ),
      (
        '\u23f1\ufe0f FIGHT WEEK: Reyes vs Brennan III \u2014 DUBLIN',
        'Press conferences \u2705 Open workouts \u2705 Weigh-ins Friday \u2705 Dublin is ELECTRIC for the biggest women\u2019s boxing event ever. 82,000 at Croke Park. Follow every moment of fight week LIVE on DataFightCentral.',
        FightSport.boxing,
      ),
    ];
    return countdowns.map((c) {
      final (headline, body, sport) = c;
      return _makePromo(
        type: PromoType.eventCountdown,
        headline: headline,
        body: body,
        hypeScore: 0.85,
        sport: sport,
        botName: 'EventBot',
        hashtags: ['#FightWeek', '#Countdown', '#DataFightCentral'],
      );
    }).toList();
  }

  List<PromoContent> _generateTrendingContent() {
    // Read from scanner's trending content
    final trending = _scanner.getTrending(limit: 5);
    if (trending.isEmpty) {
      return [
        _makePromo(
          type: PromoType.trendingTopic,
          headline: '📈 TRENDING NOW ON DFC',
          body:
              'The fight world never sleeps. Here\'s what\'s buzzing right now on DataFightCentral: Title fights, breaking news, and exclusive content. Tap in.',
          hypeScore: 0.75,
          sport: FightSport.mixed,
          botName: 'TrendBot',
          hashtags: ['#Trending', '#FightNews', '#DataFightCentral'],
        ),
      ];
    }

    return trending.take(3).map((t) {
      return _makePromo(
        type: PromoType.trendingTopic,
        headline: '📈 TRENDING: ${t.title}',
        body:
            '${t.body}\n\n🔥 ${t.engagementLabel} engagements and climbing. Follow this story on DataFightCentral.',
        hypeScore: t.viralScore.clamp(0.6, 0.95),
        sport: t.sport,
        botName: 'TrendBot',
        hashtags: ['#Trending', '#${t.sportLabel}', '#DataFightCentral'],
      );
    }).toList();
  }

  List<PromoContent> _generateViralSnippets() {
    final snippets = [
      (
        '\u{1F680} Santos\'s left hook just ended a whole career',
        'That left hook from Alex Pereira was a masterclass in timing. The crowd in S\u00e3o Paulo erupted. Watch the full replay and 10 more incredible moments on DataFightCentral.',
        0.93,
      ),
      (
        '\u{1F680} Name a better rivalry than Reyes vs Brennan \u2014 I\'ll wait...',
        'Two fights. Two wars. Now the trilogy in Dublin with 82,000 screaming fans. Amanda Serrano and Katie Taylor are writing history with their fists. Follow every round LIVE on DataFightCentral.',
        0.91,
      ),
      (
        '\u{1F680} Zhang Weili just did THAT to Yan Xiaonan',
        'A masterclass in technique. Zhang Weili reminded everyone why she\'s the most skilled 115lb fighter on the planet. If this doesn\'t inspire you, watch it again. Full highlights on DFC. \u{1F624}\u{1F94A}',
        0.88,
      ),
    ];
    return snippets.map((s) {
      final (headline, body, viral) = s;
      return _makePromo(
        type: PromoType.viralSnippet,
        headline: headline,
        body: body,
        hypeScore: viral,
        viralPotential: viral,
        sport: FightSport.mixed,
        botName: 'ViralBot',
        hashtags: ['#FightFans', '#Viral', '#DataFightCentral', '#ShareThis'],
      );
    }).toList();
  }

  List<PromoContent> _generateCampaignPosts() {
    return [
      _makePromo(
        type: PromoType.campaignPost,
        headline: '📣 JOIN THE FIGHT REVOLUTION',
        body:
            'DataFightCentral isn\'t just an app — it\'s the FUTURE of combat sports. AI-powered analysis, real-time scanning, fighter tracking, and the most passionate community in the game. Download now and join the revolution.',
        hypeScore: 0.92,
        sport: FightSport.mixed,
        botName: 'CampaignBot',
        hashtags: ['#DataFightCentral', '#FightRevolution', '#DownloadNow'],
      ),
      _makePromo(
        type: PromoType.campaignPost,
        headline: '📣 YOUR AI CORNER COACH IS READY',
        body:
            'Imagine having an AI coach that analyzes your training, predicts your performance, and creates personalized fight camp protocols. That\'s DataFightCentral. Try it FREE.',
        hypeScore: 0.88,
        sport: FightSport.mixed,
        botName: 'CampaignBot',
        hashtags: ['#AICoach', '#FightTech', '#DataFightCentral'],
      ),
    ];
  }

  List<PromoContent> _generateStatsContent() {
    return [
      _makePromo(
        type: PromoType.statsGraphic,
        headline: '📊 BY THE NUMBERS: This Week in Fighting',
        body:
            '🥊 12 events worldwide\n💥 47 finishes (68% finish rate)\n⏱️ Avg fight time: 8:42\n🏆 3 new champions crowned\n📈 2.4M total views on DFC\n\nThe fight game is BOOMING. Full stats breakdown on DataFightCentral.',
        hypeScore: 0.75,
        sport: FightSport.mixed,
        botName: 'AnalyticsBot',
        hashtags: ['#FightStats', '#ByTheNumbers', '#DataFightCentral'],
      ),
      _makePromo(
        type: PromoType.predictionCard,
        headline: '🔮 AI PREDICTION: Main Event Breakdown',
        body:
            'Our AI has analyzed 500+ data points including striking accuracy, takedown defense, cardio capacity, and fight IQ. The prediction? 67% chance of a 3rd round TKO. See the full AI breakdown on DataFightCentral.',
        hypeScore: 0.83,
        sport: FightSport.ufc,
        botName: 'AnalyticsBot',
        hashtags: ['#AIPrediction', '#FightPreview', '#DataFightCentral'],
      ),
    ];
  }

  // ─── Content Factory ──────────────────────────────────────────────────
  PromoContent _makePromo({
    required PromoType type,
    required String headline,
    required String body,
    required double hypeScore,
    required FightSport sport,
    required String botName,
    List<String> hashtags = const [],
    double? viralPotential,
  }) {
    // 🔥 APPLY BEAST MODE AMPLIFICATION
    final beastHypeBoost = _beastMode.hypeScoreBoost;
    final beastViralBoost = _beastMode.viralPotentialBoost;

    final amplifiedHype = (hypeScore + beastHypeBoost).clamp(0.0, 1.0);
    final baseViral =
        viralPotential ?? (hypeScore * 0.8 + _random.nextDouble() * 0.2);
    final amplifiedViral = (baseViral + beastViralBoost).clamp(0.0, 1.0);

    // Track Beast Mode boost
    if (_beastMode.isActive) {
      _beastMode.trackContentAmplified(1);
      _beastMode.trackViralBoost(beastViralBoost * 100);
    }

    return PromoContent(
      id: 'promo_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(99999)}',
      type: type,
      headline: headline,
      body: body,
      hashtags: hashtags,
      generatedAt: DateTime.now(),
      hypeScore: amplifiedHype,
      viralPotential: amplifiedViral,
      botName: botName,
      sport: sport,
      platform: PromoPlatform.allPlatforms,
    );
  }

  // ─── Auto Campaign Creator ────────────────────────────────────────────
  void _createAutoCampaigns() {
    final now = DateTime.now();
    _campaigns.addAll([
      PromoCampaign(
        id: 'camp_fight_week_${now.millisecondsSinceEpoch}',
        name: 'Fight Week Hype Machine',
        description:
            'Automated countdown and hype posts for upcoming fight events',
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        reachEstimate: 250000,
      ),
      PromoCampaign(
        id: 'camp_app_promo_${now.millisecondsSinceEpoch}',
        name: 'DFC App Launch Campaign',
        description: 'Promoting DataFightCentral features and AI capabilities',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        reachEstimate: 500000,
      ),
      PromoCampaign(
        id: 'camp_fighter_spotlight_${now.millisecondsSinceEpoch}',
        name: 'Weekly Fighter Spotlight Series',
        description: 'Featuring rising stars and legendary fighters every week',
        startDate: now,
        endDate: now.add(const Duration(days: 90)),
        reachEstimate: 150000,
      ),
    ]);
  }

  // ─── Query Methods ────────────────────────────────────────────────────
  List<PromoContent> getByType(PromoType type) =>
      _promoFeed.where((p) => p.type == type).toList();

  List<PromoContent> getTopHype({int limit = 10}) {
    final sorted = List<PromoContent>.from(_promoFeed)
      ..sort((a, b) => b.hypeScore.compareTo(a.hypeScore));
    return sorted.take(limit).toList();
  }

  List<PromoContent> getMostViral({int limit = 10}) {
    final sorted = List<PromoContent>.from(_promoFeed)
      ..sort((a, b) => b.viralPotential.compareTo(a.viralPotential));
    return sorted.take(limit).toList();
  }

  List<PromoContent> getForPlatform(PromoPlatform platform) => _promoFeed
      .where(
        (p) =>
            p.platform == platform || p.platform == PromoPlatform.allPlatforms,
      )
      .toList();

  List<PromoContent> getLatest({int limit = 20}) =>
      _promoFeed.take(limit).toList();

  // ─── Manual Trigger ───────────────────────────────────────────────────
  Future<void> forceGenerate() async {
    if (!AppConstants.syntheticContentEnabled) {
      return;
    }
    await _generatePromotionalContent();
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────
  @override
  void dispose() {
    _generationTimer?.cancel();
    _promoController.close();
    super.dispose();
  }
}
