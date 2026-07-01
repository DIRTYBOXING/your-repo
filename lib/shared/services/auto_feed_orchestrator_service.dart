import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/agent_role_registry.dart';
import 'content_safety_service.dart';
import 'feed_pipeline_audit_service.dart';
import 'fight_news_service.dart';
import 'meta_content_service.dart';
import 'source_trust_rules_service.dart';
import 'beast_mode_service.dart';
import 'youtube_service.dart';

/// Unified source categories used by the auto-feed orchestrator.
enum FeedSourceType { social, news, video, partner, studio }

/// Normalized cross-source feed item.
class AutoFeedItem {
  final String id;
  final String title;
  final String body;
  final String source;
  final FeedSourceType sourceType;
  final DateTime publishedAt;
  final String? linkUrl;
  final String? imageUrl;
  final String? videoUrl;
  final List<String> tags;
  final double trustScore;
  final double rankingWeight;
  final String trustProfileKey;
  final double promoterOpportunityScore;
  final double strategicScore;
  final List<String> commandSignals;

  /// True when this content was voluntarily shared to DFC by the rights holder
  /// (e.g. a promoter sharing a fight poster from Facebook/Instagram).
  /// Shared content is lawfully consented for promotional use on DFC.
  final bool sharedByOwner;

  /// Derived from [sharedByOwner] or explicit DFC partner status.
  /// When true, posters, event cards, and media may be amplified for promotion.
  final bool promotionCleared;

  const AutoFeedItem({
    required this.id,
    required this.title,
    required this.body,
    required this.source,
    required this.sourceType,
    required this.publishedAt,
    this.linkUrl,
    this.imageUrl,
    this.videoUrl,
    this.tags = const [],
    this.trustScore = 0.0,
    this.rankingWeight = 0.0,
    this.trustProfileKey = 'unclassified',
    this.promoterOpportunityScore = 0.0,
    this.strategicScore = 0.0,
    this.commandSignals = const [],
    this.sharedByOwner = false,
    this.promotionCleared = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'source': source,
    'sourceType': sourceType.name,
    'publishedAt': Timestamp.fromDate(publishedAt),
    'linkUrl': linkUrl,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'tags': tags,
    'trustScore': trustScore,
    'rankingWeight': rankingWeight,
    'trustProfileKey': trustProfileKey,
    'promoterOpportunityScore': promoterOpportunityScore,
    'strategicScore': strategicScore,
    'commandSignals': commandSignals,
    'sharedByOwner': sharedByOwner,
    'promotionCleared': promotionCleared,
  };

  static AutoFeedItem fromMap(Map<String, dynamic> m) => AutoFeedItem(
    id: m['id'] as String? ?? '',
    title: m['title'] as String? ?? '',
    body: m['body'] as String? ?? '',
    source: m['source'] as String? ?? '',
    sourceType: FeedSourceType.values.firstWhere(
      (e) => e.name == (m['sourceType'] as String? ?? 'news'),
      orElse: () => FeedSourceType.news,
    ),
    publishedAt: m['publishedAt'] is Timestamp
        ? (m['publishedAt'] as Timestamp).toDate()
        : DateTime.tryParse(m['publishedAt']?.toString() ?? '') ??
              DateTime.now(),
    linkUrl: m['linkUrl'] as String?,
    imageUrl: m['imageUrl'] as String?,
    videoUrl: m['videoUrl'] as String?,
    tags:
        (m['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const [],
    trustScore: (m['trustScore'] as num?)?.toDouble() ?? 0.0,
    rankingWeight: (m['rankingWeight'] as num?)?.toDouble() ?? 0.0,
    trustProfileKey: m['trustProfileKey'] as String? ?? 'unclassified',
    promoterOpportunityScore:
        (m['promoterOpportunityScore'] as num?)?.toDouble() ?? 0.0,
    strategicScore: (m['strategicScore'] as num?)?.toDouble() ?? 0.0,
    commandSignals:
        (m['commandSignals'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    sharedByOwner: m['sharedByOwner'] as bool? ?? false,
    promotionCleared: m['promotionCleared'] as bool? ?? false,
  );
}

/// AutoFeedOrchestratorService
///
/// Purpose:
/// - Aggregate UFC/news/video/studio content from existing services.
/// - Normalize all feed items into a single stream for ranking and display.
///
/// Guardrail:
/// - This service does not control layout, panel sizes, routing, or infra.
/// - It only fetches and shapes content payloads.
class AutoFeedOrchestratorService {
  static final AutoFeedOrchestratorService _instance =
      AutoFeedOrchestratorService._internal();
  factory AutoFeedOrchestratorService() => _instance;
  AutoFeedOrchestratorService._internal();

  final MetaContentService _meta = MetaContentService();
  final FightNewsService _news = FightNewsService();
  final YouTubeService _youtube = YouTubeService();
  final ContentSafetyService _safety = ContentSafetyService();
  final FeedPipelineAuditService _audit = FeedPipelineAuditService();
  final SourceTrustRulesService _trustRules = SourceTrustRulesService();
  final BeastModeService _beastMode = BeastModeService();

  final List<AutoFeedItem> _cache = [];
  final _controller = StreamController<List<AutoFeedItem>>.broadcast();
  FeedPipelineStage? _lastStage;

  static const Set<String> _legendKeywords = {
    'ultimate legends',
    'legend',
    'legends',
    'john scida',
  };

  // Launch campaign lane: Legends shows + Samurai promotion.
  static const Set<String> _samuraiPromotionKeywords = {
    'samurai promotion',
    'samurai promotions',
    'samurai launch',
    'legends show',
    'legends shows',
    'ultimate legends',
    'fight week rollout',
    'priority access drop',
    'card reveal',
    'promotion rollout',
  };

  static const Set<String> _aussiePromoterKeywords = {
    'australia',
    'australian',
    'melbourne',
    'sydney',
    'brisbane',
    'gold coast',
    'perth',
    'adelaide',
    'promoter',
    'promotion',
    'fight night',
    'undercard',
    'main event',
    'ultimate legends',
    'international brawling championship',
    'ibc',
  };

  static const Set<String> _globalReachKeywords = {
    'ppv',
    'pay per view',
    'livestream',
    'live stream',
    'watch worldwide',
    'global audience',
    'international viewers',
    'world title',
    'broadcast',
    'tickets',
  };

  static const Set<String> _premiumPromoterKeywords = {
    'verified promoter',
    'premium promoter',
    'partner promotion',
    'official promoter',
    'fight promoter',
    'promoter',
  };

  // THE MAIN EVENT — the draw card. Every ticket, every VIP seat, every PPV
  // buy exists because of who is in the main event. This is the promoter's
  // entire product. The undercard services the main event.
  static const Set<String> _mainEventKeywords = {
    // The bout itself
    'main event', 'headline bout', 'headline fight', 'headliner',
    'co-main event', 'co-main', 'feature bout',
    // Billing language
    'top of the card', 'top of card', 'main card',
    'marquee matchup', 'marquee fight', 'marquee bout',
    'showstopper', 'the main attraction', 'the draw',
    'draw card', 'drawcard',
    // Fight announcement language
    'fight announced', 'bout announced', 'fight confirmed',
    'fight is on', 'main event confirmed', 'headliner confirmed',
    'headliner announced', 'top billing',
    // Undercard context (implies a main event exists)
    'undercard', 'prelims', 'preliminary card', 'support card',
    'supporting bout', 'opening bout',
  };

  // Ticket selling is the #1 bottom line — the more signals, the higher the lift.
  static const Set<String> _ticketRevenueKeywords = {
    // Core ticket language
    'ticket', 'tickets', 'sell tickets', 'ticket drop', 'ticket link',
    'ticket sales', 'ticket on sale', 'tickets on sale', 'buy tickets',
    'get tickets', 'grab tickets', 'tickets available', 'box office',
    // Urgency / scarcity
    'sold out', 'selling fast', 'limited seats', 'almost gone',
    'last tickets', 'few left', 'limited availability', 'final tickets',
    'dont miss out', 'act fast', 'last chance',
    // Access tiers
    'early bird', 'vip', 'vip table', 'vip package', 'floor tickets',
    'ringside', 'general admission', 'ga tickets', 'premium seats',
    'seated area', 'standing room', 'door sales', 'gate sales',
    // Online / platform channels
    'eventbrite', 'humanitix', 'trybooking', 'ticketek', 'ticketmaster',
    'moshtix', 'oztix', 'stickytickets',
    // Revenue formats
    'ppv', 'pay per view', 'pay-per-view', 'commission',
    'gate revenue', 'door revenue', 'ticket revenue',
    // Audience breadth
    'all ages', 'all audiences', 'family friendly', 'open to public',
    // Fan conversion
    'bring your friends', 'group tickets', 'group booking', 'block booking',
    'fan packages', 'supporter packages',
  };

  // Sell-out urgency keywords — fires the sell-out-risk signal
  static const Set<String> _sellOutUrgencyKeywords = {
    'sold out',
    'selling fast',
    'almost gone',
    'limited seats',
    'last tickets',
    'few left',
    'final tickets',
    'dont miss out',
    'last chance',
    'limited availability',
    'nearly full',
  };

  static const Set<String> _viralMomentumKeywords = {
    'viral',
    'trending',
    'fight week',
    'hype',
    'spotlight',
    'announcement',
    'launch',
    'breaking',
  };

  static const Set<String> _safetyTrustKeywords = {
    'fighter safety',
    'medical clearance',
    'sanctioned',
    'commission approved',
    'safe matchmaking',
    'injury protocol',
    'concussion protocol',
    'health checks',
  };

  static const Set<String> _creatorEconomyKeywords = {
    'followers',
    'fanbase',
    'fan base',
    'creator',
    'ticket sales',
    'ticket link',
    'ppv sales',
    'pay per view',
    'affiliate',
    'revenue share',
    'monetize',
    'conversion',
  };

  static const Set<String> _trendingFighterKeywords = {
    'trending fighter',
    'breakout fighter',
    'prospect',
    'rising star',
    'undefeated',
    'viral fighter',
    'fighter signs',
    // Discovery-first language — DFC finds them before anyone else
    'undiscovered',
    'hidden gem',
    'next big thing',
    'one to watch',
    'watch this fighter',
    'future champion',
    'up and coming fighter',
    'raw talent',
    'early access',
    'before they blow up',
    'first to sign',
  };

  static const Set<String> _highFollowingKeywords = {
    // Follower scale milestones
    '1k followers', '5k followers', '10k followers', '20k followers',
    '50k followers', '100k followers', '500k followers', '1m followers',
    '1k subs', '5k subs', '10k subs', '50k subs', '100k subs',
    '500k subs', '1m subs', '80k subs', '80000 subs',
    // Platform-specific fighter social presence
    'tiktok following', 'tiktok fans', 'tiktok fighter',
    'instagram following', 'instagram reach', 'instagram fighter',
    'youtube fighter', 'youtube channel', 'youtube subs',
    'twitter following', 'x following',
    // Generic social scale
    'million followers', 'followers', 'following',
    'fan growth', 'social following', 'engagement rate',
    'subscribers', 'subs', 'social media reach', 'online audience',
    'community size', 'social proof',
  };

  // Fighter + social following = ticket selling machine.
  // This combo is what makes a fighter commercially valuable beyond just wins.
  static const Set<String> _socialSellingPowerKeywords = {
    'sells tickets',
    'sold tickets',
    'ticket demand',
    'fans travel',
    'fans fly',
    'followers buy tickets',
    'social media following sells',
    'viral fighter sells',
    'fighter brand',
    'personal brand',
    'fight brand',
    'merch sells',
    'merch line',
    'fighter merch',
    'fanbase sells',
    'pulls a crowd',
    'draws a crowd',
    'box office fighter',
    'gates well',
    'packed venue',
    'collab opportunity',
    'brand deal fighter',
    'sponsorship ready',
    'sponsor magnet',
  };

  // Stage 2 of the DFC pipeline: building the fighter up.
  // Entourage, team, management, camp — the infrastructure around a rising star.
  static const Set<String> _entourageGrowthKeywords = {
    'signed with team',
    'joined team',
    'new management',
    'new coach',
    'new trainer',
    'training camp',
    'fight camp',
    'new gym',
    'switched camps',
    'building team',
    'growing team',
    'full camp',
    'manager signed',
    'agent signed',
    'pr team',
    'media team',
    'social media manager',
    'content team',
    'brand team',
    'entourage',
    'corner team',
    'strength coach',
    'nutritionist on board',
  };

  // Stage 3 of the DFC pipeline: winning → stardom conversion.
  // Wins build the record; stardom builds the audience.
  static const Set<String> _winToStardomKeywords = {
    // Winning
    'undefeated', 'on a winning streak', 'win streak',
    'perfect record', 'knockout artist', 'finish rate',
    'highlight reel knockout', 'performance bonus',
    'fight of the night', 'knockout of the night',
    'submission of the night', 'stopped their opponent',
    // Stardom building
    'star in the making', 'future star', 'next superstar',
    'superstar potential', 'headliner material',
    'main event potential', 'ready to headline',
    'crowd favourite', 'crowd favorite', 'fan favourite',
    'fan favorite', 'the fans love', 'fan reaction',
    'getting noticed', 'turning heads', 'hype is real',
    // Full arc completion
    'superstar', 'fight superstar', 'combat superstar',
    'mma superstar', 'boxing superstar',
  };

  // The Jake Paul Effect: a personality with a massive social audience
  // crosses into combat sports. Their following BUY tickets regardless of
  // record. This is the most commercially disruptive force in modern fight
  // promotion — and older promoters need to understand it exists.
  static const Set<String> _jakePaulEffectKeywords = {
    // Celebrity / influencer crossover
    'influencer fight', 'influencer boxer', 'influencer mma',
    'celebrity fight', 'celebrity boxer', 'celebrity bout',
    'social media star fights', 'youtuber fight', 'youtuber boxing',
    'tiktoker fight', 'content creator fight', 'creator vs',
    // The crossover appeal language
    'crossover event', 'crossover fight', 'crossover star',
    'new audience', 'brings new fans', 'non-traditional fan',
    'casual fan', 'casual viewers', 'casual audience',
    'mainstream audience', 'non-fight fan', 'general public',
    // Commercial impact language
    'record ppv', 'record buys', 'record viewers', 'record gate',
    'sold out arena', 'sold out stadium', 'biggest gate',
    'most watched', 'most viewed fight', 'highest selling',
    // Platform-native fighter
    'youtube boxing', 'creator boxing', 'influencer boxing event',
    'social star', 'internet celebrity fight',
  };

  static const Set<String> _dealContractKeywords = {
    'contract',
    'multi-fight deal',
    'deal signed',
    'signed deal',
    'partnership deal',
    'distribution deal',
    'broadcast rights',
  };

  // Deal-closing language for event/promoter acquisition.
  static const Set<String> _dealCloseKeywords = {
    'letter of intent',
    'loi',
    'term sheet',
    'heads of agreement',
    'agreement in principle',
    'venue hold',
    'venue secured',
    'date secured',
    'contract out',
    'paperwork sent',
    'ready to sign',
    'signing this week',
    'deal closing',
    'closing the deal',
    'sign seal deliver',
    'signed sealed delivered',
    'exclusive deal',
    'final terms',
    'lock in the event',
    'promoter package',
    'event package',
  };

  static const Set<String> _singleFightSaleKeywords = {
    'single fight',
    'single-fight',
    'single bout',
    'buy this fight',
    'one-fight pass',
    'ppv single',
  };

  static const Set<String> _internationalExpansionKeywords = {
    'international',
    'worldwide',
    'global exposure',
    'cross-border',
    'anz',
    'asia pacific',
    'europe',
    'middle east',
    'north america',
  };

  static const Set<String> _creatorBreakoutKeywords = {
    'last 2 weeks',
    'past 2 weeks',
    '2 week growth',
    'rapid growth',
    'explosive growth',
    'going viral',
    'viral content',
    'tiktok growth',
    'youtube growth',
    'shorts growth',
  };

  static const Set<String> _creatorRevenueKeywords = {
    'creator revenue',
    'youtube pay',
    'youtube payout',
    'ad revenue',
    'monetized channel',
    '5k a month',
    '\$5k a month',
    'monthly creator income',
  };

  static const Set<String> _fighterTourPackageKeywords = {
    'fighter tour package',
    'stopover package',
    'extra day',
    'extra days',
    'stay longer',
    'experience australia',
    'fighter tourism',
    'host city experience',
    'recovery day',
    'media day plus',
  };

  static const Set<String> _fighterCareTravelKeywords = {
    'travel recovery',
    'jet lag recovery',
    'weight cut recovery',
    'fighter welfare',
    'human first',
    'respect fighters',
    'athlete care',
    'post-fight rest',
    'mental reset',
  };

  static const Set<String> _humanityFirstKeywords = {
    'humanity first',
    'human first',
    'athlete dignity',
    'fighter dignity',
    'compassion',
    'ethical promotion',
    'duty of care',
  };

  static const Set<String> _eventCareKeywords = {
    'event care',
    'safe event ops',
    'fighter transport',
    'recovery logistics',
    'weigh-in support',
    'health-first event',
    'athlete support team',
  };

  static const Set<String> _destinationAttractionKeywords = {
    'fight in australia',
    'come to australia',
    'australia fight tour',
    'destination event',
    'host city package',
    'visit and fight',
  };

  static const Set<String> _valueEfficiencyKeywords = {
    'more for less',
    'better deal',
    'high value package',
    'affordable camp',
    'lower cost travel',
    'cost efficient event',
    'bigger return',
  };

  // Small-show growth: 1K → 10K → 100K trajectory
  static const Set<String> _smallShowBreakoutKeywords = {
    'small show',
    'indie show',
    'local promotion',
    'regional event',
    'grassroots fight',
    'debut card',
    'first card',
    'emerging promotion',
    'up and coming show',
    'growing show',
    'building following',
    'early momentum',
    'gaining fans',
    'growing audience',
    'ground up',
    'starting out',
    'underground fight',
    'underground card',
  };

  // Mainstream crossover: small show ready to scale to national/global reach
  static const Set<String> _mainstreamReadyKeywords = {
    'mainstream ready',
    'broadcast ready',
    'streaming ready',
    'national exposure',
    'national platform',
    'network ready',
    'ready to scale',
    'going national',
    'crossover potential',
    'mainstream card',
    'platform deal',
    'tv deal',
    'streamer deal',
    'picked up by',
    'signed with network',
    '10000 views',
    '100000 views',
    '10k views',
    '100k views',
  };

  static const Map<String, Set<String>> _ecosystemRoleKeywords = {
    'fighters': {'fighter', 'fighters', 'athlete', 'athletes', 'bout'},
    'gyms': {'gym', 'gyms', 'academy', 'fight camp', 'training camp'},
    'fans': {'fan', 'fans', 'supporters', 'fanbase', 'community'},
    'events': {'event', 'events', 'fight night', 'card', 'main event'},
    'trainers': {'trainer', 'trainers', 'coach', 'coaches'},
    'managers': {'manager', 'managers', 'management'},
    'promoters': {'promoter', 'promoters', 'promotion', 'promotions'},
  };
  static const Duration _freshnessTtl = Duration(hours: 72);
  static const Duration _recencyHalfLife = Duration(hours: 24);
  static const double _strategicWeight = 0.55;
  static const double _trustWeight = 0.30;
  static const double _recencyWeight = 0.15;

  Stream<List<AutoFeedItem>> get stream => _controller.stream;
  List<AutoFeedItem> get cached => List.unmodifiable(_cache);
  Stream<List<FeedPipelineEvent>> get auditStream => _audit.stream;

  /// Aggregate and normalize all available feeds.
  Future<List<AutoFeedItem>> refreshUnifiedFeed() async {
    _audit.clear();
    _lastStage = null;

    try {
      await _trustRules.ensureProfilesSeeded();

      _advanceStage(
        FeedPipelineStage.sourceIntake,
        'Fetching approved sources',
      );
      final results = await Future.wait([
        _meta.fetchAll(),
        _news.refreshNews(),
        _youtube.fetchCombatVideos(maxResults: 20),
      ]);

      _advanceStage(FeedPipelineStage.normalize, 'Normalizing source payloads');
      final metaItems = (results[0] as List<MetaContent>)
          .map(
            (m) => AutoFeedItem(
              id: 'meta_${m.id}',
              title: m.title.isEmpty ? m.authorName : m.title,
              body: m.body,
              source: m.authorHandle,
              sourceType: FeedSourceType.social,
              publishedAt: m.publishedAt,
              linkUrl: m.sourceUrl,
              imageUrl: m.imageUrl,
              videoUrl: m.videoUrl,
              tags: m.tags,
            ),
          )
          .toList();

      final newsItems = (results[1] as List<FightNewsArticle>)
          .map(
            (n) => AutoFeedItem(
              id: 'news_${n.id}',
              title: n.title,
              body: n.summary,
              source: n.source,
              sourceType: FeedSourceType.news,
              publishedAt: n.publishedAt,
              linkUrl: n.url,
              imageUrl: n.imageUrl,
              tags: n.tags,
            ),
          )
          .toList();

      final videoItems = (results[2] as List<YouTubeVideo>)
          .map(
            (v) => AutoFeedItem(
              id: 'yt_${v.id}',
              title: v.title,
              body: v.description,
              source: v.channelTitle,
              sourceType: FeedSourceType.video,
              publishedAt: v.publishedAt,
              linkUrl: v.videoUrl,
              imageUrl: v.thumbnailUrl,
              videoUrl: v.videoUrl,
              tags: const ['youtube', 'combat'],
            ),
          )
          .toList();

      // ── AI-Generated Content (n8n Content Brain pipeline) ──
      final aiGeneratedItems = await _fetchAiGeneratedContent();
      final hardenedItems = _applyFeedHardening(<AutoFeedItem>[
        ...metaItems,
        ...newsItems,
        ...videoItems,
        ...aiGeneratedItems,
      ]);

      _advanceStage(
        FeedPipelineStage.trustSafety,
        'Validating sources and content safety',
      );
      final classified = await Future.wait<AutoFeedItem>(
        hardenedItems.map(_classifyTrust),
      );
      final approved = classified
          .where(_isItemApproved)
          .toList();

      _advanceStage(FeedPipelineStage.rank, 'Ranking approved content');
      approved.sort(_compareItems);

      _advanceStage(
        FeedPipelineStage.publish,
        'Publishing approved feed items',
      );
      _cache
        ..clear()
        ..addAll(approved);
      _controller.add(cached);

      // ── Firestore persistence (Facebook's "precomputing feeds" pattern) ──
      // Write the ranked feed to Firestore so the next app open gets instant
      // content without waiting for live API calls.
      _persistToFirestore(approved);

      _advanceStage(FeedPipelineStage.audit, 'Pipeline completed successfully');
      return cached;
    } catch (error) {
      _audit.log(
        stage: FeedPipelineStage.failed,
        success: false,
        message: 'Pipeline halted: $error',
      );
      rethrow;
    }
  }

  void _advanceStage(FeedPipelineStage nextStage, String message) {
    if (!AgentRoleRegistry.canAdvance(previous: _lastStage, next: nextStage)) {
      throw StateError(
        'Invalid pipeline transition from $_lastStage to $nextStage',
      );
    }
    _lastStage = nextStage;
    _audit.log(stage: nextStage, success: true, message: message);
  }

  bool _isItemApproved(AutoFeedItem item) {
    final contentPassed = _safety.isTextClean('${item.title}\n${item.body}');
    if (!contentPassed) {
      _audit.log(
        stage: FeedPipelineStage.failed,
        success: false,
        message: 'Rejected unsafe content: ${item.id}',
      );
      return false;
    }

    if (item.trustScore >= 0.8) {
      return true;
    }

    _audit.log(
      stage: FeedPipelineStage.failed,
      success: false,
      message:
          'Rejected low-trust source: ${item.id} (${item.trustProfileKey}, ${item.trustScore.toStringAsFixed(2)})',
    );
    return false;
  }

  Future<AutoFeedItem> _classifyTrust(AutoFeedItem item) async {
    final decision = await _trustRules.assess(
      url: item.linkUrl,
      source: item.source,
    );
    final isLegendItem = _isLegendItem(item);
    final promoterLift = _promoterGrowthLift(item);
    final premiumLift = _premiumPromoterLift(item);
    final revenueLift = _ticketRevenueLift(item);
    final mainEventLift = _mainEventLift(item);
    final viralLift = _viralMomentumLift(item);
    final safetyLift = _safetyTrustLift(item);
    final creatorLift = _creatorEconomyLift(item);
    final talentLift = _trendingFighterLift(item);
    final followingLift = _highFollowingLift(item);
    final socialSellingLift = _socialSellingPowerLift(
      item,
      talentLift,
      followingLift,
    );
    final jakePaulLift = _jakePaulEffectLift(item);
    final samuraiLift = _samuraiPromotionLift(item);
    final entourageLift = _entourageGrowthLift(item);
    final winStardomLift = _winToStardomLift(item);
    final contractLift = _dealContractLift(item);
    final dealCloseLift = _dealCloseLift(item);
    final singleFightLift = _singleFightLift(item);
    final globalLift = _internationalExposureLift(item);
    final ecosystemLift = _ecosystemRoleLift(item);
    final roleSignals = _ecosystemRoleSignals(item);
    final creatorBreakoutLift = _creatorBreakoutLift(item);
    final creatorRevenueLift = _creatorRevenueLift(item);
    final tourPackageLift = _fighterTourPackageLift(item);
    final fighterCareLift = _fighterCareTravelLift(item);
    final humanityLift = _humanityFirstLift(item);
    final eventCareLift = _eventCareLift(item);
    final destinationLift = _destinationAttractionLift(item);
    final valueLift = _valueEfficiencyLift(item);
    final smallShowLift = _smallShowBreakoutLift(item);
    final mainstreamLift = _mainstreamReadyLift(item);
    final beastLift = _beastModeLift();
    final opportunityScore =
        (promoterLift +
                premiumLift +
                revenueLift +
                mainEventLift +
                viralLift +
                safetyLift +
                creatorLift +
                talentLift +
                followingLift +
                socialSellingLift +
                jakePaulLift +
                samuraiLift +
                entourageLift +
                winStardomLift +
                contractLift +
                dealCloseLift +
                singleFightLift +
                globalLift +
                ecosystemLift +
                creatorBreakoutLift +
                creatorRevenueLift +
                tourPackageLift +
                fighterCareLift +
                humanityLift +
                eventCareLift +
                destinationLift +
                valueLift +
                smallShowLift +
                mainstreamLift)
            .clamp(0.0, 1.0);
    final commandSignals = _buildCommandSignals(
      item: item,
      promoterLift: promoterLift,
      premiumLift: premiumLift,
      revenueLift: revenueLift,
      mainEventLift: mainEventLift,
      viralLift: viralLift,
      safetyLift: safetyLift,
      creatorLift: creatorLift,
      talentLift: talentLift,
      followingLift: followingLift,
      socialSellingLift: socialSellingLift,
      jakePaulLift: jakePaulLift,
      samuraiLift: samuraiLift,
      entourageLift: entourageLift,
      winStardomLift: winStardomLift,
      contractLift: contractLift,
      dealCloseLift: dealCloseLift,
      singleFightLift: singleFightLift,
      globalLift: globalLift,
      roleSignals: roleSignals,
      creatorBreakoutLift: creatorBreakoutLift,
      creatorRevenueLift: creatorRevenueLift,
      tourPackageLift: tourPackageLift,
      fighterCareLift: fighterCareLift,
      humanityLift: humanityLift,
      eventCareLift: eventCareLift,
      destinationLift: destinationLift,
      valueLift: valueLift,
      smallShowLift: smallShowLift,
      mainstreamLift: mainstreamLift,
      isLegendItem: isLegendItem,
    );
    final liftedWeight =
        (decision.rankingWeight +
                (isLegendItem ? 0.32 : 0.0) +
                promoterLift +
                premiumLift +
                revenueLift +
                mainEventLift +
                viralLift +
                safetyLift +
                creatorLift +
                talentLift +
                followingLift +
                socialSellingLift +
                jakePaulLift +
                samuraiLift +
                entourageLift +
                winStardomLift +
                contractLift +
                dealCloseLift +
                singleFightLift +
                globalLift +
                ecosystemLift +
                creatorBreakoutLift +
                creatorRevenueLift +
                tourPackageLift +
                fighterCareLift +
                humanityLift +
                eventCareLift +
                destinationLift +
                valueLift +
                smallShowLift +
                mainstreamLift +
                beastLift)
            .clamp(0.0, 2.0);

    final strategicScore =
        ((decision.trustScore * liftedWeight) + opportunityScore).clamp(
          0.0,
          3.0,
        );

    final elevatedType =
        (decision.highPriority ||
            isLegendItem ||
            promoterLift >= 0.2 ||
            premiumLift > 0.0 ||
            revenueLift > 0.0 ||
            mainEventLift > 0.0 ||
            creatorLift > 0.0 ||
            contractLift > 0.0 ||
            dealCloseLift > 0.0 ||
            globalLift > 0.0 ||
            ecosystemLift > 0.0 ||
            creatorBreakoutLift > 0.0 ||
            tourPackageLift > 0.0 ||
            humanityLift > 0.0 ||
            destinationLift > 0.0 ||
            valueLift > 0.0 ||
            smallShowLift > 0.0 ||
            mainstreamLift > 0.0 ||
            socialSellingLift > 0.0 ||
            jakePaulLift > 0.0 ||
            samuraiLift > 0.0 ||
            entourageLift > 0.0 ||
            winStardomLift > 0.0)
        ? (item.sourceType == FeedSourceType.social ||
                  item.sourceType == FeedSourceType.news
              ? FeedSourceType.partner
              : item.sourceType)
        : item.sourceType;

    return AutoFeedItem(
      id: item.id,
      title: item.title,
      body: item.body,
      source: item.source,
      sourceType: elevatedType,
      publishedAt: item.publishedAt,
      linkUrl: item.linkUrl,
      imageUrl: item.imageUrl,
      videoUrl: item.videoUrl,
      tags: item.tags,
      trustScore: decision.trustScore,
      rankingWeight: liftedWeight,
      trustProfileKey: decision.profileKey,
      promoterOpportunityScore: opportunityScore,
      strategicScore: strategicScore,
      commandSignals: commandSignals,
    );
  }

  List<String> _buildCommandSignals({
    required AutoFeedItem item,
    required double promoterLift,
    required double premiumLift,
    required double revenueLift,
    required double mainEventLift,
    required double viralLift,
    required double safetyLift,
    required double creatorLift,
    required double talentLift,
    required double followingLift,
    required double socialSellingLift,
    required double jakePaulLift,
    required double samuraiLift,
    required double entourageLift,
    required double winStardomLift,
    required double contractLift,
    required double dealCloseLift,
    required double singleFightLift,
    required double globalLift,
    required List<String> roleSignals,
    required double creatorBreakoutLift,
    required double creatorRevenueLift,
    required double tourPackageLift,
    required double fighterCareLift,
    required double humanityLift,
    required double eventCareLift,
    required double destinationLift,
    required double valueLift,
    required double smallShowLift,
    required double mainstreamLift,
    required bool isLegendItem,
  }) {
    final signals = <String>[];
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();

    if (promoterLift >= 0.2 || premiumLift > 0.0) {
      signals.add('contact-now');
    }
    // Main event = the draw card = the reason tickets sell.
    // This is the highest-priority ticket signal in the engine.
    // A promoter's entire revenue depends on this one fight.
    if (mainEventLift > 0.0) {
      signals.add('main-event-draw');
    }
    if (revenueLift >= 0.30) {
      signals.add('ticket-seller'); // top-tier ticket conversion potential
    } else if (revenueLift > 0.0) {
      signals.add('ppv-ready');
    }
    if (_hasSellOutUrgency(item)) {
      signals.add('sell-out-risk'); // act fast — scarcity detected
    }
    if (text.contains('sponsor') || text.contains('partnership')) {
      signals.add('sponsor-ready');
    }
    if (viralLift > 0.0 || _beastMode.isActive) {
      signals.add('viral-push');
    }
    if (safetyLift > 0.0) {
      signals.add('safety-verified');
    }
    if (creatorLift > 0.0) {
      signals.add('creator-monetize');
    }
    if (creatorBreakoutLift > 0.0) {
      signals.add('creator-breakout');
    }
    if (creatorRevenueLift > 0.0) {
      signals.add('creator-revenue');
    }
    if (tourPackageLift > 0.0) {
      signals.add('tour-package');
    }
    if (fighterCareLift > 0.0) {
      signals.add('fighter-care');
    }
    if (humanityLift > 0.0) {
      signals.add('humanity-first');
    }
    if (eventCareLift > 0.0) {
      signals.add('event-care');
    }
    if (destinationLift > 0.0) {
      signals.add('destination-draw');
    }
    if (valueLift > 0.0) {
      signals.add('high-value-low-cost');
    }
    if (smallShowLift > 0.0) {
      signals.add('breakout-potential');
    }
    if (mainstreamLift > 0.0) {
      signals.add('mainstream-ready');
    }
    if (talentLift > 0.0 || followingLift > 0.0) {
      signals.add('talent-scout');
    }
    if (socialSellingLift >= 0.2) {
      signals.add('social-seller'); // fighter + following = ticket machine
    }
    if (jakePaulLift > 0.0) {
      signals.add('jake-paul-effect');
    }
    if (samuraiLift > 0.0) {
      signals.add('samurai-promotion');
    }
    if (isLegendItem) {
      signals.add('legends-show');
    }
    // DFC Fighter Stardom Pipeline — detect which stage the fighter is at.
    // Stage 1 DISCOVER: following detected, not yet selling
    // Stage 2 BUILD:    entourage/team building detected
    // Stage 3 WIN:      wins + stardom language detected
    // Stage 4 SELL:     ticket sales + social following = full arc complete
    final hasFollowing = followingLift > 0.0 || talentLift > 0.0;
    final hasBuilding = entourageLift > 0.0;
    final hasWinning = winStardomLift > 0.0;
    final hasSelling = revenueLift > 0.0 || socialSellingLift > 0.0;
    final pipelineStages = [
      hasFollowing,
      hasBuilding,
      hasWinning,
      hasSelling,
    ].where((s) => s).length;
    if (pipelineStages >= 2) {
      // Full pipeline signal fires when 2+ stages detected together
      signals.add('stardom-pipeline');
      // Tag which stage they are on so UI can highlight it
      if (hasSelling) {
        signals.add('pipeline:sell');
      } else if (hasWinning) {
        signals.add('pipeline:win');
      } else if (hasBuilding) {
        signals.add('pipeline:build');
      } else {
        signals.add('pipeline:discover');
      }
    }
    if (entourageLift > 0.0) {
      signals.add('team-building');
    }
    if (winStardomLift > 0.0) {
      signals.add('stardom-rising');
    }
    if (talentLift > 0.0 && followingLift > 0.0 && revenueLift == 0.0) {
      signals.add('discovery-pick'); // DFC found them before the market did
    }
    if (contractLift > 0.0) {
      signals.add('contract-ready');
    }
    if (dealCloseLift > 0.0) {
      signals.add('deal-close-ready');
    }
    final hasPromoterRole = roleSignals.contains('role-promoters');
    final hasEventRole = roleSignals.contains('role-events');
    if (dealCloseLift > 0.0 && (hasPromoterRole || hasEventRole)) {
      signals.add('promoter-event-hook');
    }
    if (dealCloseLift > 0.0 && hasPromoterRole && hasEventRole) {
      signals.add('sign-seal-deliver');
    }
    if (singleFightLift > 0.0) {
      signals.add('single-fight-sell');
    }
    if (globalLift > 0.0) {
      signals.add('intl-exposure');
    }
    signals.addAll(roleSignals);
    if (roleSignals.length >= 3) {
      signals.add('ecosystem-unified');
    }
    if (isLegendItem) {
      signals.add('legend-headliner');
    }

    if (signals.isEmpty) {
      signals.add('monitor');
    }
    return signals;
  }

  bool _isLegendItem(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    if (_legendKeywords.any(text.contains)) {
      return true;
    }

    for (final tag in item.tags) {
      final normalized = tag.toLowerCase();
      if (_legendKeywords.any(normalized.contains)) {
        return true;
      }
    }
    return false;
  }

  double _promoterGrowthLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    var lift = 0.0;

    if (_aussiePromoterKeywords.any(text.contains)) {
      lift += 0.2;
    }
    if (_globalReachKeywords.any(text.contains)) {
      lift += 0.18;
    }

    for (final tag in item.tags) {
      final normalized = tag.toLowerCase();
      if (_aussiePromoterKeywords.any(normalized.contains)) {
        lift += 0.08;
        break;
      }
    }

    return lift.clamp(0.0, 0.4);
  }

  double _premiumPromoterLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _premiumPromoterKeywords.any(text.contains) ? 0.18 : 0.0;
  }

  /// Main event lift — the draw card. Highest combined ticket signal.
  /// When a main event is detected, score it higher than any other single
  /// ticket signal because the whole show's revenue depends on it.
  double _mainEventLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    final matchCount = _mainEventKeywords.where(text.contains).length;
    if (matchCount == 0) return 0.0;
    if (matchCount == 1) return 0.18;
    return 0.30; // confirmed main event with billing = full draw card score
  }

  /// Ticket revenue is the #1 metric — tiered lift up to 0.35.
  /// More ticket signals present = higher lift. This is intentionally the
  /// highest-weighted single factor in the scoring pipeline.
  double _ticketRevenueLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    final matchCount = _ticketRevenueKeywords.where(text.contains).length;
    if (matchCount == 0) return 0.0;
    if (matchCount == 1) return 0.16;
    if (matchCount <= 3) return 0.24;
    if (matchCount <= 6) return 0.30;
    return 0.35; // 7+ ticket signals = maximum ticket conversion score
  }

  bool _hasSellOutUrgency(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _sellOutUrgencyKeywords.any(text.contains);
  }

  double _viralMomentumLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _viralMomentumKeywords.any(text.contains) ? 0.12 : 0.0;
  }

  double _beastModeLift() {
    if (!_beastMode.isActive) {
      return 0.0;
    }
    return (_beastMode.viralPotentialBoost * 0.12).clamp(0.0, 0.12);
  }

  double _safetyTrustLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _safetyTrustKeywords.any(text.contains) ? 0.1 : 0.0;
  }

  double _creatorEconomyLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _creatorEconomyKeywords.any(text.contains) ? 0.14 : 0.0;
  }

  double _trendingFighterLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _trendingFighterKeywords.any(text.contains) ? 0.12 : 0.0;
  }

  /// Tiered lift based on follower scale — more scale keywords = higher lift.
  /// A fighter with 500k followers is worth materially more to a show
  /// than one with 1k, and the scoring reflects that.
  double _highFollowingLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    final matchCount = _highFollowingKeywords.where(text.contains).length;
    if (matchCount == 0) return 0.0;
    if (matchCount == 1) return 0.10;
    if (matchCount <= 3) return 0.16;
    return 0.22; // 4+ social presence signals = major social asset
  }

  /// The Jake Paul Effect lift: crossover social/celebrity fighter detected.
  /// These personalities bring entirely new audiences into fight venues.
  /// A promoter who books one gets fans who never watched boxing before.
  double _jakePaulEffectLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _jakePaulEffectKeywords.any(text.contains) ? 0.25 : 0.0;
  }

  double _samuraiPromotionLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    final matchCount = _samuraiPromotionKeywords.where(text.contains).length;
    if (matchCount == 0) return 0.0;
    if (matchCount == 1) return 0.12;
    return 0.2;
  }

  double _entourageGrowthLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _entourageGrowthKeywords.any(text.contains) ? 0.13 : 0.0;
  }

  /// Win-to-stardom lift: fighter is building a winning record AND
  /// the audience is responding. This is stage 3 of the DFC pipeline.
  double _winToStardomLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    final matchCount = _winToStardomKeywords.where(text.contains).length;
    if (matchCount == 0) return 0.0;
    if (matchCount == 1) return 0.13;
    return 0.20; // multiple stardom signals = legitimate rising star
  }

  /// Combo lift: fighter with both talent AND social following.
  /// This is the DFC discovery prize — the climber who hasn't blown up yet
  /// but WILL sell tickets once the platform amplifies them.
  double _socialSellingPowerLift(
    AutoFeedItem item,
    double talentLift,
    double followingLift,
  ) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    final hasSocialSelling = _socialSellingPowerKeywords.any(text.contains);
    final hasCombo = talentLift > 0.0 && followingLift > 0.0;
    // Pure social selling signal
    if (hasSocialSelling) return 0.20;
    // Combo: fighter + following detected together = amplified
    if (hasCombo) return 0.18;
    return 0.0;
  }

  double _dealContractLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _dealContractKeywords.any(text.contains) ? 0.14 : 0.0;
  }

  double _dealCloseLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    final matchCount = _dealCloseKeywords.where(text.contains).length;
    if (matchCount == 0) return 0.0;
    if (matchCount == 1) return 0.12;
    return 0.18;
  }

  double _singleFightLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _singleFightSaleKeywords.any(text.contains) ? 0.12 : 0.0;
  }

  double _internationalExposureLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _internationalExpansionKeywords.any(text.contains) ? 0.12 : 0.0;
  }

  double _creatorBreakoutLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _creatorBreakoutKeywords.any(text.contains) ? 0.14 : 0.0;
  }

  double _creatorRevenueLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _creatorRevenueKeywords.any(text.contains) ? 0.1 : 0.0;
  }

  double _fighterTourPackageLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _fighterTourPackageKeywords.any(text.contains) ? 0.12 : 0.0;
  }

  double _fighterCareTravelLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _fighterCareTravelKeywords.any(text.contains) ? 0.1 : 0.0;
  }

  double _humanityFirstLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _humanityFirstKeywords.any(text.contains) ? 0.1 : 0.0;
  }

  double _eventCareLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _eventCareKeywords.any(text.contains) ? 0.08 : 0.0;
  }

  double _destinationAttractionLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _destinationAttractionKeywords.any(text.contains) ? 0.1 : 0.0;
  }

  double _valueEfficiencyLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _valueEfficiencyKeywords.any(text.contains) ? 0.08 : 0.0;
  }

  /// Detects small/emerging shows with 1K→10K→100K growth trajectory.
  /// DFC surfaces them early so they sell more tickets and scale faster.
  double _smallShowBreakoutLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _smallShowBreakoutKeywords.any(text.contains) ? 0.12 : 0.0;
  }

  /// Detects shows crossing into mainstream reach — broadcast, network, 10K+ views.
  double _mainstreamReadyLift(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    return _mainstreamReadyKeywords.any(text.contains) ? 0.14 : 0.0;
  }

  double _ecosystemRoleLift(AutoFeedItem item) {
    final roles = _ecosystemRoleSignals(item).length;
    if (roles >= 5) return 0.16;
    if (roles >= 3) return 0.1;
    if (roles >= 2) return 0.05;
    return 0.0;
  }

  List<String> _ecosystemRoleSignals(AutoFeedItem item) {
    final text = '${item.title} ${item.body} ${item.source}'.toLowerCase();
    final signals = <String>[];

    _ecosystemRoleKeywords.forEach((role, keywords) {
      if (keywords.any(text.contains)) {
        signals.add('role-$role');
      }
    });

    return signals;
  }

  @visibleForTesting
  List<AutoFeedItem> debugApplyFeedHardening(
    List<AutoFeedItem> rawItems, {
    DateTime? now,
  }) {
    return _applyFeedHardening(rawItems, now: now);
  }

  List<AutoFeedItem> _applyFeedHardening(
    List<AutoFeedItem> rawItems, {
    DateTime? now,
  }) {
    final normalizedNow = (now ?? DateTime.now()).toUtc();
    final dedupedByFingerprint = <String, AutoFeedItem>{};
    var malformedCount = 0;
    var staleCount = 0;
    var duplicateCount = 0;

    for (final item in rawItems) {
      if (!_isSchemaValid(item)) {
        malformedCount += 1;
        continue;
      }

      if (normalizedNow.difference(item.publishedAt.toUtc()) > _freshnessTtl) {
        staleCount += 1;
        continue;
      }

      final canonicalLink = _canonicalizeUrl(item.linkUrl);
      final normalizedItem = _copyWithLinkUrl(item, canonicalLink);
      final fingerprint = _buildFingerprint(normalizedItem);
      final existing = dedupedByFingerprint[fingerprint];
      if (existing != null) {
        duplicateCount += 1;
        if (normalizedItem.publishedAt.isAfter(existing.publishedAt)) {
          dedupedByFingerprint[fingerprint] = normalizedItem;
        }
        continue;
      }

      dedupedByFingerprint[fingerprint] = normalizedItem;
    }

    _audit.log(
      stage: FeedPipelineStage.normalize,
      success: true,
      message:
          'Feed hardening: raw=${rawItems.length}, kept=${dedupedByFingerprint.length}, duplicates=$duplicateCount, stale=$staleCount, malformed=$malformedCount',
    );

    return dedupedByFingerprint.values.toList();
  }

  bool _isSchemaValid(AutoFeedItem item) {
    if (item.id.trim().isEmpty) return false;
    if (item.title.trim().length < 5) return false;
    if (item.source.trim().isEmpty) return false;
    if (item.publishedAt.year < 2000) return false;
    return true;
  }

  AutoFeedItem _copyWithLinkUrl(AutoFeedItem item, String? canonicalLink) {
    return AutoFeedItem(
      id: item.id,
      title: item.title,
      body: item.body,
      source: item.source,
      sourceType: item.sourceType,
      publishedAt: item.publishedAt,
      linkUrl: canonicalLink,
      imageUrl: item.imageUrl,
      videoUrl: item.videoUrl,
      tags: item.tags,
      trustScore: item.trustScore,
      rankingWeight: item.rankingWeight,
      trustProfileKey: item.trustProfileKey,
      promoterOpportunityScore: item.promoterOpportunityScore,
      strategicScore: item.strategicScore,
      commandSignals: item.commandSignals,
      sharedByOwner: item.sharedByOwner,
      promotionCleared: item.promotionCleared,
    );
  }

  String? _canonicalizeUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || uri.host.isEmpty) return rawUrl.trim();

    final filteredQuery = Map<String, String>.fromEntries(
      uri.queryParameters.entries.where(
        (entry) =>
            !entry.key.toLowerCase().startsWith('utm_') &&
            entry.key.toLowerCase() != 'fbclid' &&
            entry.key.toLowerCase() != 'gclid',
      ),
    );
    final normalizedPath = uri.path.endsWith('/') && uri.path.length > 1
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;

    final normalizedUrl = uri
        .replace(
          scheme: uri.scheme.toLowerCase(),
          host: uri.host.toLowerCase(),
          path: normalizedPath,
          query: filteredQuery.isEmpty ? '' : null,
          queryParameters: filteredQuery.isEmpty ? null : filteredQuery,
        )
        .toString();
    return normalizedUrl.endsWith('?')
        ? normalizedUrl.substring(0, normalizedUrl.length - 1)
        : normalizedUrl;
  }

  String _buildFingerprint(AutoFeedItem item) {
    final canonicalLink = item.linkUrl?.trim().toLowerCase();
    if (canonicalLink != null && canonicalLink.isNotEmpty) {
      return '${item.sourceType.name}|$canonicalLink';
    }

    final normalizedTitle = item.title.toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final normalizedBody = item.body.toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return '${item.sourceType.name}|${item.source.toLowerCase()}|$normalizedTitle|$normalizedBody';
  }

  int _compareItems(AutoFeedItem left, AutoFeedItem right) {
    final now = DateTime.now().toUtc();
    final leftScore = _compositeRankScore(left, now);
    final rightScore = _compositeRankScore(right, now);

    final scoreDelta = rightScore.compareTo(leftScore);
    if (scoreDelta != 0) {
      return scoreDelta;
    }

    final sourceDelta =
        _sourceWeight(right.sourceType) - _sourceWeight(left.sourceType);
    if (sourceDelta != 0) {
      return sourceDelta;
    }
    return right.publishedAt.compareTo(left.publishedAt);
  }

  @visibleForTesting
  double debugCompositeRankScore(AutoFeedItem item, {DateTime? now}) {
    return _compositeRankScore(item, (now ?? DateTime.now()).toUtc());
  }

  double _compositeRankScore(AutoFeedItem item, DateTime now) {
    final recencyScore = _recencyDecayScore(item.publishedAt.toUtc(), now);
    return (item.strategicScore * _strategicWeight) +
        (item.trustScore * _trustWeight) +
        (recencyScore * _recencyWeight);
  }

  double _recencyDecayScore(DateTime publishedAt, DateTime now) {
    final ageMinutes = now.difference(publishedAt).inMinutes;
    if (ageMinutes <= 0) {
      return 1.0;
    }
    final halfLifeMinutes = _recencyHalfLife.inMinutes;
    final exponent = ageMinutes / halfLifeMinutes;
    return math.pow(0.5, exponent).toDouble();
  }

  int _sourceWeight(FeedSourceType type) {
    switch (type) {
      case FeedSourceType.partner:
        return 5;
      case FeedSourceType.studio:
        return 4;
      case FeedSourceType.news:
        return 3;
      case FeedSourceType.video:
        return 2;
      case FeedSourceType.social:
        return 1;
    }
  }

  void dispose() {
    _controller.close();
  }

  // ═══════════════════════════════════════════════════════════════
  //  FIRESTORE FEED CACHE — Facebook's "precomputing feeds" pattern
  // ═══════════════════════════════════════════════════════════════

  static const String _feedCollection = 'precomputed_feed';
  static const String _feedDoc = 'global';
  static const int _maxCachedItems = 50;

  /// Load the last-known feed from Firestore so the UI has content instantly
  /// (before live API calls complete). Call this in app startup.
  Future<List<AutoFeedItem>> loadCachedFeed() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_feedCollection)
          .doc(_feedDoc)
          .get();
      if (!doc.exists) return const [];
      final data = doc.data();
      if (data == null) return const [];

      final rawItems = data['items'] as List<dynamic>? ?? [];
      final items = rawItems
          .map((e) => AutoFeedItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (items.isNotEmpty) {
        _cache
          ..clear()
          ..addAll(items);
        _controller.add(cached);
        debugPrint('Feed cache loaded: ${items.length} precomputed items');
      }
      return items;
    } catch (e) {
      debugPrint('Feed cache load skipped: $e');
      return const [];
    }
  }

  /// Persist ranked feed to Firestore so next app open is instant.
  void _persistToFirestore(List<AutoFeedItem> items) {
    // Fire-and-forget write — don't block the pipeline on persistence.
    final trimmed = items.take(_maxCachedItems).toList();
    FirebaseFirestore.instance
        .collection(_feedCollection)
        .doc(_feedDoc)
        .set({
          'items': trimmed.map((e) => e.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
          'itemCount': trimmed.length,
        })
        .then(
          (_) => debugPrint('Feed cache persisted: ${trimmed.length} items'),
        )
        .catchError((e) => debugPrint('Feed cache persist failed: $e'));
  }

  /// Add a Legends event to the pipeline
  void addLegendsEvent({
    required String id,
    required String title,
    required String body,
    required String imageUrl,
    required DateTime publishedAt,
    List<String> tags = const ['legends', 'event', 'ultimate promotions'],
  }) {
    final item = AutoFeedItem(
      id: id,
      title: title,
      body: body,
      source: 'Ultimate Legends Promotions',
      sourceType: FeedSourceType.partner,
      publishedAt: publishedAt,
      imageUrl: imageUrl,
      tags: tags,
      trustScore: 0.95,
      rankingWeight: 1.0,
      trustProfileKey: 'legends',
      promoterOpportunityScore: 1.0,
      strategicScore: 1.0,
      commandSignals: ['promote_legends'],
    );
    _cache.add(item);
    _controller.add(_cache);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI-GENERATED CONTENT — n8n Content Brain pipeline integration
  // ═══════════════════════════════════════════════════════════════════════

  /// Fetch recent AI-generated content from Firestore and normalize into
  /// [AutoFeedItem]s for the unified ranking pipeline.
  Future<List<AutoFeedItem>> _fetchAiGeneratedContent() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 48));
      final snap = await FirebaseFirestore.instance
          .collection('ai_generated_content')
          .where('generatedAt', isGreaterThan: Timestamp.fromDate(cutoff))
          .orderBy('generatedAt', descending: true)
          .limit(30)
          .get();

      if (snap.docs.isEmpty) return const [];

      final items = <AutoFeedItem>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final headline = data['headline'] as String? ?? '';
        final summary = data['summary'] as String? ?? '';
        final viralScore = (data['viralScore'] as num?)?.toDouble() ?? 5.0;
        final posts = data['posts'] as List<dynamic>? ?? [];
        final generatedAt = data['generatedAt'] is Timestamp
            ? (data['generatedAt'] as Timestamp).toDate()
            : DateTime.now();

        // Build body from first post caption or summary
        String body = summary;
        if (posts.isNotEmpty) {
          final firstPost = posts[0] as Map<String, dynamic>? ?? {};
          body = (firstPost['caption'] as String?) ?? summary;
        }

        if (headline.isEmpty && body.isEmpty) continue;

        items.add(
          AutoFeedItem(
            id: 'ai_${doc.id}',
            title: headline.isNotEmpty ? headline : 'AI Generated',
            body: body,
            source: 'DFC Content Brain',
            sourceType: FeedSourceType.partner,
            publishedAt: generatedAt,
            tags: const ['ai_generated', 'content_brain', 'dfc_original'],
            // AI content from our own pipeline is high-trust
            trustScore: 0.95,
            rankingWeight: 0.9 + (viralScore / 100), // viral boost
            trustProfileKey: 'dfc_internal',
            promoterOpportunityScore: viralScore / 10,
            strategicScore: viralScore / 10,
            commandSignals: const ['ai_content', 'auto_generated'],
            promotionCleared: true,
          ),
        );
      }

      debugPrint(
        '[AutoFeed] Loaded ${items.length} AI-generated content items',
      );
      return items;
    } catch (e) {
      debugPrint('[AutoFeed] AI content fetch failed: $e');
      return const [];
    }
  }
}
