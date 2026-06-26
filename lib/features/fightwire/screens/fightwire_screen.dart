import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/router_config.dart' as rc;
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/image_url_sanitizer.dart';
import '../../../shared/models/community/community_models.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/auto_feed_orchestrator_service.dart';
import '../../../shared/services/content_safety_service.dart';
import '../../../shared/services/content_scanner_engine.dart';
import '../../../shared/services/promoter_ai_service.dart';
import '../../../shared/services/dfc_ai_powerhouse.dart';
import '../../../shared/services/social_service.dart';
import '../../../shared/services/youtube_service.dart';
import '../../../shared/services/ecosystem_state_service.dart';
import '../../../shared/services/ecosystem_feedback_engine.dart';
import '../../../shared/services/platform_health_service.dart';
import '../../../shared/widgets/dfc_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTWIRE SCREEN — Infinite-scroll combat sports news + community feed
/// Merges fight news + Meta (IG/FB) + community posts into one scrolling panel
/// Like Twitter/X for combat sports — endless scroll, live feel
/// ═══════════════════════════════════════════════════════════════════════════
class FightWireScreen extends StatefulWidget {
  const FightWireScreen({super.key});

  @override
  State<FightWireScreen> createState() => _FightWireScreenState();
}

class _FightWireScreenState extends State<FightWireScreen>
    with SingleTickerProviderStateMixin {
  bool get _syntheticEnabled => AppConstants.syntheticContentEnabled;

  late AutoFeedOrchestratorService _autoFeedService;
  late ContentScannerEngine _scanner;
  late PromoterAIService _promoter;
  late DFCAIPowerhouse _powerhouse;
  late SocialService _socialService;
  late EcosystemStateService _ecosystemState;
  late EcosystemFeedbackEngine _feedbackEngine;
  bool _depsInitialized = false;
  final ScrollController _scrollController = ScrollController();
  List<Post> _communityPosts = [];

  List<_FeedItem> _feed = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _caseStudyMode = true;
  int _currentPage = 0;
  String _activeFilter = 'All';

  late AnimationController _pulseCtrl;

  // ── Auto-rotating hero carousel ──
  final PageController _heroPgCtrl = PageController();
  int _heroPage = 0;
  Timer? _heroTimer;

  static const _filters = [
    'All',
    'Launch',
    'UFC',
    'Boxing',
    'MMA',
    'Muay Thai',
    'BKFC',
    'ONE',
    'PFL',
    'Instagram',
    'Facebook',
    'TikTok',
    'YouTube',
    'Twitter',
    'Reddit',
    'Podcasts',
    'DFC Hype',
    'Community',
  ];

  void _goBackSafely() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  String? _realImageUrl(String? raw) {
    final cleaned = ImageUrlSanitizer.sanitize(raw, fallback: '').trim();
    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  /// Picks a sport-specific DFC background image based on tags/source so cards
  /// never appear without a visual.
  String _fallbackImageForItem(List<String> tags, String source) {
    final haystack = [...tags, source].join(' ').toLowerCase();
    if (haystack.contains('ufc') || haystack.contains('mma')) {
      return ImageAssets.ufcPlaceholder;
    }
    if (haystack.contains('boxing') || haystack.contains('wbc')) {
      return ImageAssets.boxingPlaceholder;
    }
    if (haystack.contains('bkfc') || haystack.contains('bare knuckle')) {
      return ImageAssets.bkfcPlaceholder;
    }
    if (haystack.contains('muay thai') || haystack.contains('kickboxing')) {
      return ImageAssets.kickboxingPlaceholder;
    }
    if (haystack.contains('brawl') || haystack.contains('ibc')) {
      return ImageAssets.posterForSport('brawling');
    }
    if (haystack.contains('wrestling') || haystack.contains('wwe')) {
      return ImageAssets.posterForSport('pro wrestling');
    }
    if (haystack.contains('glory') || haystack.contains('kickbox')) {
      return ImageAssets.kickboxingPlaceholder;
    }
    if (haystack.contains('rizin') || haystack.contains('pfl')) {
      return ImageAssets.muayThaiPlaceholder;
    }
    if (haystack.contains('gym') || haystack.contains('training')) {
      return ImageAssets.gymPlaceholder;
    }
    // Rotate through branded backgrounds to avoid visual repetition
    final hash = haystack.hashCode.abs();
    const bgs = [
      ImageAssets.bgAction,
      ImageAssets.bgEvent,
      ImageAssets.bgPromo,
      ImageAssets.bgCentral,
      ImageAssets.bgHero,
    ];
    return bgs[hash % bgs.length];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      _depsInitialized = true;
      _autoFeedService = AutoFeedOrchestratorService();
      _scanner = context.read<ContentScannerEngine>();
      _promoter = context.read<PromoterAIService>();
      _powerhouse = context.read<DFCAIPowerhouse>();
      _socialService = context.read<SocialService>();
      _ecosystemState = context.read<EcosystemStateService>();
      _feedbackEngine = EcosystemFeedbackEngine(
        ecosystemState: _ecosystemState,
        orchestrator: _autoFeedService,
      );
      _loadFeed();
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scrollController.addListener(_onScroll);
    // Auto-advance carousel every 6 seconds
    _heroTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      final featured = _feed.where((f) => f.isFeatured).toList();
      if (featured.isEmpty) return;
      final next = (_heroPage + 1) % featured.length.clamp(1, 8);
      setState(() => _heroPage = next);
      if (_heroPgCtrl.hasClients) {
        _heroPgCtrl.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    _currentPage = 0;

    try {
      // Boot synthetic generators only when explicitly enabled.
      if (_syntheticEnabled && !_powerhouse.initialized) {
        await _powerhouse.bootAllEngines();
      }

      final autoFeed = await PlatformHealthService.instance.guard(
        tag: 'fightwire_auto_feed',
        action: () => _autoFeedService.refreshUnifiedFeed(),
        fallback: <AutoFeedItem>[],
      );
      _communityPosts = PlatformHealthService.instance.safeCast<Post>(
        await PlatformHealthService.instance.guard(
          tag: 'fightwire_community',
          action: () => _socialService.getPostsPage(refresh: true),
          fallback: <dynamic>[],
        ),
        tag: 'fightwire_community_cast',
      );

      final scanned = _syntheticEnabled
          ? _scanner.getLatest()
          : <ScannedContent>[];
      final promos = _syntheticEnabled
          ? _promoter.getLatest()
          : <PromoContent>[];

      _mergeFeed(
        autoFeed,
        scanned: scanned,
        promos: promos,
        community: _communityPosts,
      );
    } catch (e) {
      debugPrint('[FightWire] _loadFeed self-heal: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    _currentPage++;

    try {
      // Scanner/promoter are synthetic generators and stay disabled by default.
      if (_syntheticEnabled) {
        await _scanner.forceRefresh();
        await _promoter.forceGenerate();
      }

      final autoFeed = _autoFeedService.cached.isNotEmpty
          ? _autoFeedService.cached
          : await PlatformHealthService.instance.guard(
              tag: 'fightwire_load_more',
              action: () => _autoFeedService.refreshUnifiedFeed(),
              fallback: <AutoFeedItem>[],
            );
      final scanned = _syntheticEnabled
          ? _scanner.getLatest(limit: 50 + _currentPage * 20)
          : <ScannedContent>[];
      final promos = _syntheticEnabled
          ? _promoter.getLatest(limit: 20 + _currentPage * 10)
          : <PromoContent>[];

      // Load next page of community posts
      final morePosts = await PlatformHealthService.instance.guard(
        tag: 'fightwire_more_posts',
        action: () => _socialService.getPostsPage(),
        fallback: <dynamic>[],
      );
      _communityPosts = [
        ..._communityPosts,
        ...PlatformHealthService.instance.safeCast<Post>(
          morePosts,
          tag: 'fightwire_more_cast',
        ),
      ];

      _mergeFeed(
        autoFeed,
        scanned: scanned,
        promos: promos,
        community: _communityPosts,
      );
    } catch (e) {
      debugPrint('[FightWire] _loadMore self-heal: $e');
    }

    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _mergeFeed(
    List<AutoFeedItem> autoFeed, {
    List<ScannedContent> scanned = const [],
    List<PromoContent> promos = const [],
    List<Post> community = const [],
  }) {
    final items = <_FeedItem>[];
    final seenIds = <String>{}; // deduplication by ID

    // Add orchestrated feed items
    for (final item in autoFeed) {
      if (seenIds.contains(item.id)) continue;
      seenIds.add(item.id);
      final platform = _platformFromAuto(item);
      items.add(
        _FeedItem(
          id: item.id,
          type:
              item.sourceType == FeedSourceType.news ||
                  item.sourceType == FeedSourceType.studio
              ? _FeedItemType.news
              : _FeedItemType.social,
          title: item.title,
          body: item.body,
          source: item.source,
          sourceHandle:
              item.sourceType == FeedSourceType.social ||
                  item.sourceType == FeedSourceType.partner
              ? item.source
              : null,
          sourceIcon: _sourceIconFromAuto(item, platform),
          timestamp: item.publishedAt,
          accent: _accentFromAuto(item, platform),
          tags: item.tags,
          isFeatured:
              item.sourceType == FeedSourceType.partner ||
              item.sourceType == FeedSourceType.studio,
          isVerified: item.sourceType != FeedSourceType.news,
          platform: platform,
          url: item.linkUrl,
          imageUrl:
              _realImageUrl(item.imageUrl) ??
              _fallbackImageForItem(item.tags, item.source),
          engagementLabel: item.sourceType == FeedSourceType.video
              ? 'AUTO'
              : null,
          isReel: platform == 'instagram' || platform == 'youtube',
          trustScore: item.trustScore,
          rankingWeight: item.rankingWeight,
          trustProfileKey: item.trustProfileKey,
          promoterOpportunityScore: item.promoterOpportunityScore,
          strategicScore: item.strategicScore,
          commandSignals: item.commandSignals,
        ),
      );
    }

    // Preserve orchestration strategy: strategic score first, then urgency, then recency.
    items.sort((a, b) {
      final strategyDelta = (b.strategicScore ?? 0.0).compareTo(
        a.strategicScore ?? 0.0,
      );
      if (strategyDelta != 0) return strategyDelta;
      if (a.isBreaking && !b.isBreaking) return -1;
      if (!a.isBreaking && b.isBreaking) return 1;
      return b.timestamp.compareTo(a.timestamp);
    });

    // Add scanner content — fills the feed with live internet data
    for (final s in scanned) {
      if (seenIds.contains(s.id)) continue;
      seenIds.add(s.id);
      final sourceIcon = switch (s.source) {
        ScanSource.instagram => Icons.camera_alt,
        ScanSource.facebook => Icons.facebook,
        ScanSource.tiktok => Icons.music_note,
        ScanSource.youtube => Icons.play_circle,
        ScanSource.twitter => Icons.tag,
        ScanSource.reddit => Icons.forum,
        ScanSource.podcast => Icons.podcasts,
        _ => Icons.language,
      };
      final accent = switch (s.source) {
        ScanSource.instagram => const Color(0xFFE1306C),
        ScanSource.facebook => const Color(0xFF1877F2),
        ScanSource.tiktok => const Color(0xFF00F2EA),
        ScanSource.youtube => const Color(0xFFFF0000),
        ScanSource.twitter => const Color(0xFF1DA1F2),
        ScanSource.reddit => const Color(0xFFFF4500),
        _ => DesignTokens.neonCyan,
      };
      items.add(
        _FeedItem(
          id: s.id,
          type:
              s.source == ScanSource.instagram ||
                  s.source == ScanSource.facebook ||
                  s.source == ScanSource.tiktok
              ? _FeedItemType.social
              : _FeedItemType.news,
          title: s.title,
          body: s.body,
          source: s.sourceName,
          sourceIcon: sourceIcon,
          timestamp: s.publishedAt,
          accent: accent,
          tags: s.tags,
          isBreaking: s.isBreaking,
          isVerified: s.isVerified,
          platform: s.source.name,
          imageUrl:
              _realImageUrl(s.imageUrl) ??
              _fallbackImageForItem(s.tags, s.sourceName),
          likes: s.engagementCount ~/ 3,
          comments: s.engagementCount ~/ 10,
          shares: s.engagementCount ~/ 20,
          engagementLabel: s.engagementLabel,
        ),
      );
    }

    // Add PromoterAI hype content — makes the feed feel alive
    for (final p in promos) {
      if (seenIds.contains(p.id)) continue;
      seenIds.add(p.id);
      items.add(
        _FeedItem(
          id: p.id,
          type: _FeedItemType.promo,
          title: p.headline,
          body: p.body,
          source: '${p.typeLabel} DFC',
          sourceIcon: Icons.auto_awesome,
          timestamp: p.generatedAt,
          accent: AppTheme.neonMagenta,
          tags: p.hashtags.map((h) => h.replaceAll('#', '')).toList(),
          isFeatured: p.hypeScore > 0.85,
          platform: 'dfc',
        ),
      );
    }

    // ── Community posts from SocialService ──────────────────────
    for (final post in community) {
      final postId = 'community_${post.id}';
      if (seenIds.contains(postId)) continue;
      seenIds.add(postId);
      // Extract hashtags from content
      final hashtagRegex = RegExp(r'#(\w+)');
      final tags = hashtagRegex
          .allMatches(post.content)
          .map((m) => m.group(1)!)
          .toList();
      final roleIcon = switch (post.userRole) {
        'fighter' => Icons.sports_mma,
        'coach' => Icons.school,
        'promoter' => Icons.campaign,
        'gym' => Icons.fitness_center,
        'media' => Icons.videocam,
        'admin' => Icons.verified,
        _ => Icons.person,
      };
      items.add(
        _FeedItem(
          id: postId,
          type: _FeedItemType.community,
          title: post.displayName,
          body: post.content,
          source: post.roleBadge,
          sourceIcon: roleIcon,
          timestamp: post.createdAt,
          accent: switch (post.userRole) {
            'fighter' => DesignTokens.neonRed,
            'coach' => DesignTokens.neonCyan,
            'promoter' => AppTheme.neonMagenta,
            'gym' => DesignTokens.neonGreen,
            'admin' => const Color(0xFFFFD700),
            _ => Colors.white70,
          },
          tags: tags,
          platform: 'community',
          likes: post.likes,
          comments: post.commentCount,
          imageUrl: post.mediaUrls.isNotEmpty
              ? post.mediaUrls.first
              : _fallbackImageForItem(tags, post.userRole ?? 'community'),
          communityPost: post,
        ),
      );
    }

    // ── Always-on partner & editorial seed content ───────────────────────
    // Real promotion partnerships and curated editorial — not synthetic.
    {
      final now = DateTime.now();
      final seeds = <_FeedItem>[
        // ── Australian Partner Promotions ────────────────────────
        _FeedItem(
          id: 'joseph_seed_1',
          type: _FeedItemType.promo,
          title: 'Ultimate Legends Fight Week Is Live',
          body:
              'Ultimate Legends fight week is active. WBC on the line, undercard loaded, and clip drops moving now. DFC amplification is running from the back while the promotion leads from the front.',
          source: 'Ultimate Legends',
          sourceHandle: '@ultimatelegendspromotions',
          sourceIcon: Icons.campaign,
          timestamp: now.subtract(const Duration(hours: 1)),
          accent: AppTheme.neonMagenta,
          tags: const ['UltimateLegends', 'FightWeek', 'Promotion', 'DFC'],
          isBreaking: true,
          isFeatured: true,
          isVerified: true,
          platform: 'instagram',
          url: 'https://www.instagram.com/ultimatelegendspromotions/',
          imageUrl: ImageAssets.bgPromo,
          engagementLabel: 'HOT',
          likes: 980,
          comments: 143,
          shares: 88,
        ),
        _FeedItem(
          id: 'ultimate_official_seed_1',
          type: _FeedItemType.promo,
          title: 'Ultimate Legends Official Contact + Ticket Push',
          body:
              'Official profile: 1.2K followers | 16 following. K1 Kickboxing, Muay Thai, and Boxing events. Always open. Address: 135-157 Racecourse Road, Kensington VIC 3031. Website: ultimatelegends.com.au.',
          source: 'Ultimate Legends Promotions',
          sourceHandle: '@ultimatelegendspromotions',
          sourceIcon: Icons.storefront,
          timestamp: now.subtract(const Duration(hours: 1, minutes: 40)),
          accent: const Color(0xFFFF6B00),
          tags: const ['UltimateLegends', 'Tickets', 'Melbourne', 'Contact'],
          isFeatured: true,
          isVerified: true,
          platform: 'facebook',
          url: 'https://ultimatelegends.com.au',
          imageUrl: ImageAssets.bgEvent,
          engagementLabel: 'SELLING FAST',
          likes: 1340,
          comments: 182,
          shares: 109,
        ),
        _FeedItem(
          id: 'ibc_official_seed_1',
          type: _FeedItemType.promo,
          title: 'IBC Official Details + Contact Hub',
          body:
              'International Brawling Champions is live and open for global reach. Official links: internationalbrawling.com | IG: @internationalbrawling | Contact: info@internationalbrawling.com.',
          source: 'International Brawling Champions',
          sourceHandle: '@internationalbrawling',
          sourceIcon: Icons.language,
          timestamp: now.subtract(const Duration(hours: 2)),
          accent: const Color(0xFFFFD700),
          tags: const ['IBC', 'InternationalBrawling', 'Contact', 'Promotion'],
          isFeatured: true,
          isVerified: true,
          platform: 'instagram',
          url: 'https://internationalbrawling.com',
          imageUrl: ImageAssets.bgCentral,
          engagementLabel: 'LIVE',
          likes: 1120,
          comments: 164,
          shares: 95,
        ),
        _FeedItem(
          id: 'joseph_seed_2',
          type: _FeedItemType.news,
          title: 'WBC Silver Australian Title Headlines Ultimate Legends Card',
          body:
              'Melbourne Pavilion hosts a stacked pro lineup as Ultimate Legends pushes one of the strongest Australian promotion nights on the 2026 calendar.',
          source: 'DFC Partner Desk',
          sourceIcon: Icons.verified,
          timestamp: now.subtract(const Duration(hours: 4)),
          accent: const Color(0xFFFFD700),
          tags: const ['WBC', 'UltimateLegends', 'Melbourne', 'Boxing'],
          isFeatured: true,
          isVerified: true,
          imageUrl: ImageAssets.boxingPlaceholder,
        ),
        _FeedItem(
          id: 'joseph_seed_3',
          type: _FeedItemType.social,
          title: 'Ticket Alert: Ultimate Legends Activates Priority Access',
          body:
              'Priority access is now moving through partner channels with fan demand climbing. Early buyers are securing premium sections before general release windows close.',
          source: 'Ultimate Legends Promotions',
          sourceHandle: '@ultimatelegendspromotions',
          sourceIcon: Icons.local_activity,
          timestamp: now.subtract(const Duration(hours: 7)),
          accent: DesignTokens.neonCyan,
          tags: const ['Tickets', 'UltimateLegends', 'Melbourne'],
          isFeatured: true,
          isVerified: true,
          platform: 'instagram',
          url: 'https://www.instagram.com/ultimatelegendspromotions/',
          imageUrl: ImageAssets.bgAction,
          likes: 720,
          comments: 102,
          shares: 65,
        ),

        // ── BKFC / Bare Knuckle (US) ───────────────────────────
        _FeedItem(
          id: 'bkfc_seed_1',
          type: _FeedItemType.news,
          title: 'BKFC KnuckleMania VI — Full Card Announced',
          body:
              'Bare Knuckle Fighting Championship returns with a stacked card. Six world title bouts confirmed across six weight classes.',
          source: 'BKFC',
          sourceIcon: Icons.sports_mma,
          timestamp: now.subtract(const Duration(hours: 3)),
          accent: const Color(0xFFFF3D00),
          tags: const ['BKFC', 'BareKnuckle', 'combat-sport', 'event'],
          isFeatured: true,
          url: 'https://www.bareknuckle.tv',
          imageUrl: ImageAssets.bkfcPlaceholder,
        ),
        _FeedItem(
          id: 'bkfc_seed_2',
          type: _FeedItemType.news,
          title: 'Inside Bare Knuckle Training — No Gloves, Raw Skill',
          body:
              'Fighters reveal the conditioning work that keeps hands safe in sanctioned bare-knuckle bouts. Wraps, conditioning, and technique breakdown.',
          source: 'BKFC Official',
          sourceIcon: Icons.sports_mma,
          timestamp: now.subtract(const Duration(hours: 8)),
          accent: const Color(0xFFFF3D00),
          tags: const ['BKFC', 'training', 'technique', 'BareKnuckle'],
          imageUrl: ImageAssets.bgHero,
        ),
        _FeedItem(
          id: 'bkfc_seed_3',
          type: _FeedItemType.news,
          title: 'BKFC Lightweight Title Fight: Champion Defends in Tampa',
          body:
              'The reigning BKFC lightweight champion puts the belt on the line against the No.1 ranked contender this Saturday night.',
          source: 'BKFC',
          sourceIcon: Icons.sports_mma,
          timestamp: now.subtract(const Duration(hours: 14)),
          accent: const Color(0xFFFF3D00),
          tags: const ['BKFC', 'BareKnuckle', 'title-fight', 'lightweight'],
          isBreaking: true,
          imageUrl: ImageAssets.bkfcPlaceholder,
        ),

        // ── UFC / MMA Global ───────────────────────────────────
        _FeedItem(
          id: 'ufc_global_1',
          type: _FeedItemType.news,
          title: 'UFC Fight Night 271: Adesanya vs Pyfer — Seattle, March 28',
          body:
              'Israel Adesanya headlines his first main event since losing the middleweight title, facing rising contender Austin Pyfer at Climate Pledge Arena in Seattle. Co-main: Moicano vs Hooker.',
          source: 'UFC',
          sourceIcon: Icons.sports_mma,
          timestamp: now.subtract(const Duration(hours: 2)),
          accent: DesignTokens.neonRed,
          tags: const ['UFC', 'MMA', 'Adesanya', 'Seattle'],
          isFeatured: true,
          isBreaking: true,
          imageUrl: ImageAssets.ufcPlaceholder,
          likes: 2340,
          comments: 456,
          shares: 312,
        ),
        _FeedItem(
          id: 'ufc_global_2',
          type: _FeedItemType.news,
          title: 'UFC 327: Prochazka vs Ulberg — April 11 CONFIRMED',
          body:
              'Jiri Prochazka meets rising City Kickboxing star Carlos Ulberg in a light heavyweight headliner. Ulberg riding an 8-fight win streak — NZ talent on the biggest stage.',
          source: 'UFC',
          sourceIcon: Icons.sports_mma,
          timestamp: now.subtract(const Duration(hours: 5)),
          accent: DesignTokens.neonRed,
          tags: const ['UFC', 'Prochazka', 'Ulberg', 'LHW'],
          isFeatured: true,
          imageUrl: ImageAssets.bgAction,
          likes: 1890,
          comments: 234,
          shares: 167,
        ),
        _FeedItem(
          id: 'ufc_global_3',
          type: _FeedItemType.news,
          title: 'UFC 328: Chimaev vs Strickland — May 9 PPV',
          body:
              'Khamzat Chimaev (13-0) finally faces Sean Strickland in a middleweight title eliminator. Two of the most polarizing fighters in MMA clash on PPV.',
          source: 'UFC',
          sourceIcon: Icons.sports_mma,
          timestamp: now.subtract(const Duration(hours: 10)),
          accent: DesignTokens.neonRed,
          tags: const ['MMA', 'UFC', 'Chimaev', 'Strickland', 'PPV'],
          imageUrl: ImageAssets.ufcPlaceholder,
          likes: 3200,
          comments: 567,
        ),
        _FeedItem(
          id: 'ufc_perth_1',
          type: _FeedItemType.social,
          title: 'UFC Perth: Della Maddalena Headlines Home — May 2',
          body:
              'Jack Della Maddalena returns to RAC Arena Perth to headline against Gilbert Burns rival Michel Prates. JDM riding a devastating 5-fight finish streak. Ticket presale selling fast.',
          source: 'UFC Australia',
          sourceHandle: '@ufcfightpass',
          sourceIcon: Icons.sports_mma,
          timestamp: now.subtract(const Duration(hours: 3)),
          accent: DesignTokens.neonRed,
          tags: const ['UFC', 'Perth', 'Australia', 'DellaMaddalena'],
          platform: 'instagram',
          imageUrl: ImageAssets.bgAction,
          likes: 2100,
          comments: 310,
          shares: 198,
        ),
        _FeedItem(
          id: 'ufc_london_results',
          type: _FeedItemType.news,
          title: 'UFC London Results: Evloev Stays Unbeaten at 20-0',
          body:
              'Movsar Evloev defeated Lerone Murphy by majority decision in the UFC Fight Night 270 main event. Murphy (17-1-1) suffers first career loss. Luke Riley (13-0) and Michael Page (25-3) also pick up wins.',
          source: 'MMA Fighting',
          sourceIcon: Icons.sports_mma,
          timestamp: now.subtract(const Duration(hours: 8)),
          accent: DesignTokens.neonRed,
          tags: const ['UFC', 'London', 'Evloev', 'results'],
          isBreaking: true,
          imageUrl: ImageAssets.ufcPlaceholder,
          likes: 4100,
          comments: 678,
          shares: 412,
        ),

        // ── Boxing International ───────────────────────────────
        _FeedItem(
          id: 'boxing_global_1',
          type: _FeedItemType.news,
          title: 'Canelo Álvarez Returns: Super Middleweight Title Defence Set',
          body:
              'Canelo Álvarez confirms his next undisputed super middleweight title defence. The Mexican superstar looking to extend his championship reign at T-Mobile Arena, Las Vegas.',
          source: 'Boxing Scene',
          sourceIcon: Icons.sports_kabaddi,
          timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
          accent: const Color(0xFFFFD700),
          tags: const ['Boxing', 'Canelo', 'LasVegas', 'PPV', 'title-fight'],
          isFeatured: true,
          isBreaking: true,
          imageUrl: ImageAssets.boxingPlaceholder,
          likes: 4500,
          comments: 890,
          shares: 567,
        ),
        _FeedItem(
          id: 'boxing_global_2',
          type: _FeedItemType.social,
          title: 'Naoya Inoue Continues Monster Run in Tokyo',
          body:
              'Japan\'s undisputed super bantamweight champion defends at Tokyo Dome. 28-0 with 25 KOs. The Monster shows no signs of slowing down.',
          source: 'Ring Magazine',
          sourceHandle: '@ringmagazine',
          sourceIcon: Icons.sports_kabaddi,
          timestamp: now.subtract(const Duration(hours: 6)),
          accent: const Color(0xFFFFD700),
          tags: const ['Boxing', 'Inoue', 'Japan', 'Tokyo', 'champion'],
          platform: 'instagram',
          imageUrl: ImageAssets.bgEvent,
          likes: 2100,
          comments: 345,
          shares: 210,
        ),
        _FeedItem(
          id: 'boxing_au_1',
          type: _FeedItemType.news,
          title: 'PFL Madrid: Van Steenis KOs Fabian Edwards — Elbows R3',
          body:
              'Costello van Steenis delivered a devastating KO via elbows in Round 3 to finish Fabian Edwards at PFL Europe in Madrid. Statement win puts him in title contention.',
          source: 'PFL MMA',
          sourceIcon: Icons.sports_mma,
          timestamp: now.subtract(const Duration(hours: 12)),
          accent: DesignTokens.neonGreen,
          tags: const ['PFL', 'Madrid', 'Europe', 'KO', 'MMA'],
          imageUrl: ImageAssets.ufcPlaceholder,
          likes: 1800,
          comments: 430,
          shares: 290,
        ),

        // ── ONE Championship (Asia) ──────────────────────────
        _FeedItem(
          id: 'one_asia_1',
          type: _FeedItemType.news,
          title: 'ONE Championship Bangkok: Stamp Fairtex Defends Title',
          body:
              'Thailand\'s Stamp Fairtex puts her atomweight MMA title on the line at Impact Arena Bangkok. Muay Thai royalty meets MMA excellence.',
          source: 'ONE Championship',
          sourceIcon: Icons.public,
          timestamp: now.subtract(const Duration(hours: 3, minutes: 30)),
          accent: DesignTokens.neonCyan,
          tags: const ['ONE', 'MuayThai', 'Thailand', 'Bangkok', 'MMA'],
          isFeatured: true,
          imageUrl: ImageAssets.muayThaiPlaceholder,
          likes: 1670,
          comments: 234,
          shares: 156,
        ),
        _FeedItem(
          id: 'one_asia_2',
          type: _FeedItemType.social,
          title: 'ONE Fight Night Singapore — Kickboxing Grand Prix',
          body:
              'The lightweight kickboxing Grand Prix continues at Singapore Indoor Stadium. Eight elite strikers battle for a shot at the championship.',
          source: 'ONE Championship',
          sourceHandle: '@onechampionship',
          sourceIcon: Icons.public,
          timestamp: now.subtract(const Duration(hours: 9)),
          accent: DesignTokens.neonCyan,
          tags: const ['ONE', 'Kickboxing', 'Singapore', 'GrandPrix'],
          platform: 'instagram',
          imageUrl: ImageAssets.kickboxingPlaceholder,
          likes: 1230,
          comments: 178,
          shares: 98,
        ),

        // ── GLORY Kickboxing (Europe) ──────────────────────────
        _FeedItem(
          id: 'glory_europe_1',
          type: _FeedItemType.news,
          title: 'GLORY 92 Rotterdam — Heavyweight Grand Prix Final',
          body:
              'Ahoy Arena Rotterdam hosts the conclusion of the GLORY heavyweight tournament. Four fighters remain. European kickboxing at its finest.',
          source: 'GLORY Kickboxing',
          sourceIcon: Icons.flash_on,
          timestamp: now.subtract(const Duration(hours: 4)),
          accent: const Color(0xFFFF6B00),
          tags: const [
            'GLORY',
            'Kickboxing',
            'Rotterdam',
            'Europe',
            'heavyweight',
          ],
          isFeatured: true,
          imageUrl: ImageAssets.kickboxingPlaceholder,
          likes: 890,
          comments: 123,
          shares: 76,
        ),

        // ── RIZIN (Japan) ─────────────────────────────────────
        _FeedItem(
          id: 'rizin_japan_1',
          type: _FeedItemType.news,
          title: 'RIZIN 52 Saitama — Stacked Japan Card Confirmed',
          body:
              'Saitama Super Arena hosts the latest RIZIN event with cross-promotional bouts including fighters from UFC, PFL, and ONE. Japan continues to grow its MMA footprint.',
          source: 'RIZIN Fighting Federation',
          sourceIcon: Icons.public,
          timestamp: now.subtract(const Duration(hours: 7)),
          accent: const Color(0xFFE1306C),
          tags: const ['RIZIN', 'Japan', 'MMA', 'Saitama'],
          imageUrl: ImageAssets.muayThaiPlaceholder,
          likes: 1450,
          comments: 267,
          shares: 189,
        ),

        // ── PFL (Global) ─────────────────────────────────────
        _FeedItem(
          id: 'pfl_global_1',
          type: _FeedItemType.news,
          title: 'PFL Pittsburgh: Eblen vs Battle — March 28 LIVE',
          body:
              'Johnny Eblen defends the PFL middleweight title against Fabian Edwards rival Impa Kasanganay while Cleveland\'s Battle looks to make a statement. Stacked card at PPG Paints Arena.',
          source: 'PFL MMA',
          sourceIcon: Icons.public,
          timestamp: now.subtract(const Duration(hours: 11)),
          accent: DesignTokens.neonGreen,
          tags: const ['PFL', 'Pittsburgh', 'Eblen', 'MMA'],
          imageUrl: ImageAssets.ufcPlaceholder,
          likes: 780,
          comments: 112,
          shares: 67,
        ),
        _FeedItem(
          id: 'pfl_global_2',
          type: _FeedItemType.news,
          title: 'PFL Chicago April 11: Pettis vs McKee Headlines',
          body:
              'Anthony Pettis meets A.J. McKee in a must-see lightweight clash. Two former champions with highlight-reel finishes collide at the United Center.',
          source: 'PFL MMA',
          sourceIcon: Icons.public,
          timestamp: now.subtract(const Duration(hours: 14)),
          accent: DesignTokens.neonGreen,
          tags: const ['PFL', 'Chicago', 'Pettis', 'McKee', 'lightweight'],
          imageUrl: ImageAssets.bgEvent,
          likes: 920,
          comments: 145,
          shares: 89,
        ),

        // ── Australian Local Scene ──────────────────────────
        _FeedItem(
          id: 'au_local_1',
          type: _FeedItemType.social,
          title: 'Eternal MMA Perth 80 — WA\'s Biggest Fight Night',
          body:
              'HBF Arena hosts the 80th edition of WA\'s premier MMA promotion. Local talent stepping up with three title fights on the card.',
          source: 'Eternal MMA',
          sourceHandle: '@eternalmma',
          sourceIcon: Icons.sports_mma,
          timestamp: now.subtract(const Duration(hours: 6)),
          accent: DesignTokens.neonGreen,
          tags: const ['EternalMMA', 'Perth', 'Australia', 'MMA'],
          platform: 'instagram',
          imageUrl: ImageAssets.bgAction,
          likes: 560,
          comments: 89,
          shares: 45,
        ),
        _FeedItem(
          id: 'au_local_2',
          type: _FeedItemType.news,
          title: 'Hex Fight Series Brisbane — Fortitude Music Hall',
          body:
              'Queensland\'s Hex Fight Series brings another packed card to Fortitude Valley. Seven bouts including a lightweight title eliminator.',
          source: 'Hex Fight Series',
          sourceIcon: Icons.sports_mma,
          timestamp: now.subtract(const Duration(hours: 15)),
          accent: DesignTokens.neonGreen,
          tags: const ['Hex', 'Brisbane', 'Australia', 'MMA'],
          imageUrl: ImageAssets.bgEvent,
          likes: 340,
          comments: 56,
          shares: 32,
        ),
        _FeedItem(
          id: 'ibc_goldcoast_1',
          type: _FeedItemType.promo,
          title: 'IBC Gold Coast — International Brawling Under the Stars',
          body:
              'International Brawling Champions heads to the Gold Coast for an outdoor arena spectacular. Brawling meets beachside energy. Tickets moving fast.',
          source: 'IBC',
          sourceHandle: '@internationalbrawling',
          sourceIcon: Icons.language,
          timestamp: now.subtract(const Duration(hours: 8)),
          accent: const Color(0xFFFFD700),
          tags: const ['IBC', 'Brawling', 'GoldCoast', 'Australia'],
          isFeatured: true,
          isVerified: true,
          platform: 'instagram',
          imageUrl: ImageAssets.posterForSport('brawling'),
          engagementLabel: 'SELLING',
          likes: 670,
          comments: 98,
          shares: 54,
        ),

        // ── Middle East ──────────────────────────────────────
        _FeedItem(
          id: 'me_event_1',
          type: _FeedItemType.news,
          title: 'UFC Fight Night: Sterling vs Zalal — Abu Dhabi, April 25',
          body:
              'Aljamain Sterling returns to headline against Youssef Zalal at Etihad Arena in Abu Dhabi. The former bantamweight champion looking to climb back to title contention.',
          source: 'UFC Arabia',
          sourceIcon: Icons.sports_mma,
          timestamp: now.subtract(const Duration(hours: 13)),
          accent: DesignTokens.neonRed,
          tags: const ['UFC', 'AbuDhabi', 'Sterling', 'MMA', 'MiddleEast'],
          imageUrl: ImageAssets.bgPromo,
          likes: 1120,
          comments: 198,
          shares: 134,
        ),

        // ── Africa ───────────────────────────────────────────
        _FeedItem(
          id: 'africa_event_1',
          type: _FeedItemType.news,
          title: 'EFC Africa 120 — Cape Town\'s Combat Night',
          body:
              'Extreme Fighting Championship continues to grow African MMA with a 12-fight card at GrandWest Arena Cape Town. Three title fights headline.',
          source: 'EFC Africa',
          sourceIcon: Icons.public,
          timestamp: now.subtract(const Duration(hours: 16)),
          accent: const Color(0xFF00E5FF),
          tags: const ['EFC', 'Africa', 'CapeTown', 'MMA'],
          imageUrl: ImageAssets.bgCentral,
          likes: 450,
          comments: 67,
          shares: 34,
        ),

        // ── South America ────────────────────────────────────
        _FeedItem(
          id: 'brazil_event_1',
          type: _FeedItemType.news,
          title: 'UFC Fight Night: Burns vs Malott — April 18',
          body:
              'Gilbert Burns faces Mike Malott in a welterweight main event. Burns looking to snap a two-fight skid and prove he still belongs in the top 10.',
          source: 'UFC Brasil',
          sourceIcon: Icons.sports_mma,
          timestamp: now.subtract(const Duration(hours: 18)),
          accent: DesignTokens.neonGreen,
          tags: const ['UFC', 'Burns', 'Malott', 'MMA', 'welterweight'],
          imageUrl: ImageAssets.ufcPlaceholder,
          likes: 1890,
          comments: 345,
          shares: 234,
        ),

        // ── Muay Thai Global ─────────────────────────────────
        _FeedItem(
          id: 'mt_global_1',
          type: _FeedItemType.social,
          title: 'IFMA World Muay Thai Championships — Antalya, Turkey',
          body:
              'Over 100 countries competing in the world\'s largest Muay Thai tournament. Team Australia sending a stacked squad across all weight classes.',
          source: 'IFMA Official',
          sourceHandle: '@ifabormuaythai',
          sourceIcon: Icons.public,
          timestamp: now.subtract(const Duration(hours: 5, minutes: 30)),
          accent: const Color(0xFF9C27B0),
          tags: const ['MuayThai', 'IFMA', 'Turkey', 'WorldChampionship'],
          isFeatured: true,
          platform: 'instagram',
          imageUrl: ImageAssets.muayThaiPlaceholder,
          likes: 890,
          comments: 134,
          shares: 76,
        ),
        _FeedItem(
          id: 'mt_global_2',
          type: _FeedItemType.news,
          title: 'Lumpinee Stadium Weekly — Bangkok\'s Sacred Ring',
          body:
              'The birthplace of Muay Thai competition continues its legendary weekly schedule. International fighters travelling to test themselves at the highest level.',
          source: 'Lumpinee News',
          sourceIcon: Icons.temple_buddhist,
          timestamp: now.subtract(const Duration(hours: 20)),
          accent: const Color(0xFF9C27B0),
          tags: const ['MuayThai', 'Lumpinee', 'Bangkok', 'Thailand'],
          imageUrl: ImageAssets.muayThaiPlaceholder,
          likes: 670,
          comments: 89,
          shares: 45,
        ),

        // ── YouTube / Content ────────────────────────────────
        _FeedItem(
          id: 'yt_content_1',
          type: _FeedItemType.social,
          title: 'Morning Kombat: Adesanya vs Pyfer Breakdown & Predictions',
          body:
              'Luke Thomas and Brian Campbell break down the UFC Fight Night 271 main event. Can Adesanya bounce back? Plus: Prochazka vs Ulberg preview and PFL Pittsburgh analysis.',
          source: 'Morning Kombat',
          sourceHandle: '@morningkombat',
          sourceIcon: Icons.play_circle,
          timestamp: now.subtract(const Duration(hours: 3)),
          accent: const Color(0xFFFF0000),
          tags: const ['YouTube', 'MorningKombat', 'preview', 'analysis'],
          platform: 'youtube',
          isReel: true,
          imageUrl: ImageAssets.bgAction,
          likes: 12300,
          comments: 456,
          shares: 234,
        ),
        _FeedItem(
          id: 'yt_content_2',
          type: _FeedItemType.social,
          title: 'The MMA Hour: Della Maddalena, Hooker & P4P Debate',
          body:
              'Ariel Helwani talks to Jack Della Maddalena about headlining Perth, Dan Hooker on the Moicano rematch, and a heated P4P rankings update with real-time fan voting.',
          source: 'The MMA Hour',
          sourceHandle: '@themmahour',
          sourceIcon: Icons.play_circle,
          timestamp: now.subtract(const Duration(hours: 8)),
          accent: const Color(0xFFFF0000),
          tags: const ['YouTube', 'MMAHour', 'interviews', 'UFC'],
          platform: 'youtube',
          isReel: true,
          imageUrl: ImageAssets.bgEvent,
          likes: 8900,
          comments: 345,
          shares: 178,
        ),

        // ── Empire Fight Series (Melbourne) ──────────────────
        _FeedItem(
          id: 'empire_mel_1',
          type: _FeedItemType.promo,
          title: 'Empire Fight Series 5 — Kickboxing Showdown Melbourne',
          body:
              'Empire brings international-level kickboxing to Melbourne with a 10-fight card at Margaret Court Arena. K-1 rules, world-class production.',
          source: 'Empire Fight Series',
          sourceHandle: '@empirefightseries',
          sourceIcon: Icons.flash_on,
          timestamp: now.subtract(const Duration(hours: 4)),
          accent: const Color(0xFFFF6B00),
          tags: const ['Empire', 'Kickboxing', 'Melbourne', 'Australia'],
          isFeatured: true,
          isVerified: true,
          platform: 'facebook',
          imageUrl: ImageAssets.kickboxingPlaceholder,
          likes: 450,
          comments: 67,
          shares: 34,
        ),

        // ── KSW (Poland/Europe) ──────────────────────────────
        _FeedItem(
          id: 'ksw_europe_1',
          type: _FeedItemType.news,
          title: 'KSW 98 Łódź — Poland\'s MMA Powerhouse Returns',
          body:
              'Atlas Arena Łódź sold out in 48 hours. KSW continues to dominate European MMA with stadium-level production and homegrown talent.',
          source: 'KSW MMA',
          sourceIcon: Icons.public,
          timestamp: now.subtract(const Duration(hours: 22)),
          accent: DesignTokens.neonCyan,
          tags: const ['KSW', 'Poland', 'Europe', 'MMA'],
          imageUrl: ImageAssets.bgPromo,
          likes: 670,
          comments: 98,
          shares: 56,
        ),

        // ── Training / Fitness / Wellness ────────────────────
        _FeedItem(
          id: 'training_content_1',
          type: _FeedItemType.community,
          title: 'Coach Sarah Mitchell',
          body:
              'Recovery isn\'t optional — it\'s where the gains happen. Ice baths, mobility work, and proper nutrition between sessions. Your body is your weapon, treat it right. #FighterWellness #Recovery',
          source: 'Coach',
          sourceIcon: Icons.school,
          timestamp: now.subtract(const Duration(hours: 6)),
          accent: DesignTokens.neonCyan,
          tags: const ['wellness', 'recovery', 'training', 'coaching'],
          platform: 'community',
          imageUrl: ImageAssets.wellnessPlaceholder,
          likes: 234,
          comments: 45,
        ),
        _FeedItem(
          id: 'gym_content_1',
          type: _FeedItemType.community,
          title: 'Tiger Muay Thai Phuket',
          body:
              'International training camp is OPEN. Come train with world champions in the birthplace of Muay Thai. 6-week and 12-week programs available. Fighters from 40+ countries training daily.',
          source: 'Gym',
          sourceIcon: Icons.fitness_center,
          timestamp: now.subtract(const Duration(hours: 12)),
          accent: DesignTokens.neonGreen,
          tags: const ['gym', 'MuayThai', 'Thailand', 'training', 'camp'],
          platform: 'community',
          imageUrl: ImageAssets.gymPlaceholder,
          likes: 890,
          comments: 156,
          shares: 98,
        ),
      ];
      // Only add seeds not already in feed (prevents duplicates on reload)
      for (final seed in seeds) {
        if (!seenIds.contains(seed.id)) {
          seenIds.add(seed.id);
          items.add(seed);
        }
      }
    }

    // Re-sort with all items combined while preserving high-value promoter campaigns.
    items.sort((a, b) {
      final strategyDelta = (b.strategicScore ?? 0.0).compareTo(
        a.strategicScore ?? 0.0,
      );
      if (strategyDelta != 0) return strategyDelta;
      if (a.isBreaking && !b.isBreaking) return -1;
      if (!a.isBreaking && b.isBreaking) return 1;
      return b.timestamp.compareTo(a.timestamp);
    });

    // Inject synthetic sponsors only when synthetic mode is enabled.
    if (!_syntheticEnabled) {
      _feed = items;
      return;
    }

    final injected = <_FeedItem>[];
    final sponsors = [
      _FeedItem(
        id: 'sponsor_access_pass',
        type: _FeedItemType.sponsored,
        title: 'Elevate Your Fight Career',
        body:
            'Get real-time analytics, AI coaching, and fighter tracking with DFC Access Pass. Join thousands of fighters leveling up their career.',
        source: 'DFC Platform',
        sourceIcon: Icons.workspace_premium,
        timestamp: DateTime.now(),
        accent: const Color(0xFFFFD700),
        tags: const ['sponsored', 'dfc-pro'],
        platform: 'sponsored',
        url: '/subscription',
      ),
      _FeedItem(
        id: 'sponsor_ai_coach',
        type: _FeedItemType.sponsored,
        title: 'Train Smarter with AI Insights',
        body:
            'AI-powered performance tracking, weight cut guidance, and recovery optimization. Pro fighters\' secret weapon.',
        source: 'DFC Pro Tools',
        sourceIcon: Icons.psychology,
        timestamp: DateTime.now(),
        accent: DesignTokens.neonCyan,
        tags: const ['sponsored', 'ai-coach'],
        platform: 'sponsored',
        url: '/ai-brain',
      ),
      _FeedItem(
        id: 'sponsor_marketplace',
        type: _FeedItemType.sponsored,
        title: 'Get Noticed by Promoters',
        body:
            'Create your fighter card, showcase your record, and connect with promoters worldwide. Your next fight is one click away.',
        source: 'DFC Marketplace',
        sourceIcon: Icons.star,
        timestamp: DateTime.now(),
        accent: AppTheme.neonMagenta,
        tags: const ['sponsored', 'marketplace'],
        platform: 'sponsored',
        url: '/marketplace',
      ),
    ];

    for (var i = 0; i < items.length; i++) {
      injected.add(items[i]);
      // Every 6 posts, inject a sponsored card
      if ((i + 1) % 6 == 0 && i < items.length - 1) {
        injected.add(sponsors[(i ~/ 6) % sponsors.length]);
      }
    }

    _feed = injected;

    // ── Track opportunities in ecosystem for bidirectional feedback ───────
    _recordOpportunitiesInEcosystem(injected);
  }

  /// Record opportunities in ecosystem DISCOVER stage with tracking for bidirectional feedback
  void _recordOpportunitiesInEcosystem(List<_FeedItem> items) {
    for (final item in items) {
      // Only track items with strategic scoring (real opportunities)
      if (item.strategicScore != null && item.strategicScore! > 0.5) {
        try {
          _ecosystemState.addOpportunityToDiscoverStage(
            item.id,
            item.source,
            item.commandSignals,
            item.strategicScore ?? 0.0,
            item.imageUrl,
            item.title,
          );

          // Record campaign signal hits
          for (final signal in item.commandSignals) {
            _ecosystemState.recordCampaignSignalHit(signal);
          }
        } catch (e) {
          debugPrint('Ecosystem tracking error: $e');
        }
      }
    }
  }

  List<_FeedItem> get _filteredFeed {
    // Bare-knuckle / BKFC is sanctioned sport — always visible.
    final base = _feed;
    if (_activeFilter == 'All') {
      return base;
    }
    if (_activeFilter == 'Launch') {
      return base
          .where(
            (f) => _isLaunchPriorityItem(f.commandSignals, f.strategicScore),
          )
          .toList();
    }
    if (_activeFilter == 'Instagram') {
      return base.where((f) => f.platform == 'instagram').toList();
    }
    if (_activeFilter == 'Facebook') {
      return base.where((f) => f.platform == 'facebook').toList();
    }
    if (_activeFilter == 'TikTok') {
      return base.where((f) => f.platform == 'tiktok').toList();
    }
    if (_activeFilter == 'YouTube') {
      return base.where((f) => f.platform == 'youtube').toList();
    }
    if (_activeFilter == 'Twitter') {
      return base.where((f) => f.platform == 'twitter').toList();
    }
    if (_activeFilter == 'Reddit') {
      return base.where((f) => f.platform == 'reddit').toList();
    }
    if (_activeFilter == 'Podcasts') {
      return base.where((f) => f.platform == 'podcast').toList();
    }
    if (_activeFilter == 'DFC Hype') {
      return base.where((f) => f.platform == 'dfc').toList();
    }
    if (_activeFilter == 'Community') {
      return base.where((f) => f.platform == 'community').toList();
    }
    return base
        .where(
          (f) =>
              f.source.toUpperCase().contains(_activeFilter.toUpperCase()) ||
              f.tags.any(
                (t) => t.toUpperCase().contains(_activeFilter.toUpperCase()),
              ),
        )
        .toList();
  }

  bool _isLaunchPriorityItem(List<String> signals, double? strategicScore) {
    if ((strategicScore ?? 0) >= 1.75) {
      return true;
    }

    const launchSignals = {
      'samurai-promotion',
      'joseph-priority',
      'legends-show',
      'main-event-draw',
      'deal-close-ready',
      'sign-seal-deliver',
      'promoter-event-hook',
      'ticket-seller',
      'sell-out-risk',
      'social-seller',
      'stardom-pipeline',
      'jake-paul-effect',
      'contract-ready',
      'single-fight-sell',
      'ppv-ready',
      'contact-now',
    };

    return signals.any(launchSignals.contains);
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPgCtrl.dispose();
    _scrollController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterStrip(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.neonRed,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFeed,
                      color: DesignTokens.neonRed,
                      child: _buildScrollingFeed(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fightwire_compose',
        onPressed: () => _showComposeSheet(context),
        backgroundColor: DesignTokens.neonRed,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // HEADER with LIVE Status
  // ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: DesignTokens.neonRed.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.neonRed.withValues(alpha: 0.15),
                  blurRadius: 25,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              children: [
                Tooltip(
                  message: 'Back',
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _goBackSafely();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Animated LIVE Icon
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, _) {
                    final p = _pulseCtrl.value;
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.neonRed,
                            DesignTokens.neonRed.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.neonRed.withValues(
                              alpha: 0.25 + p * 0.2,
                            ),
                            blurRadius: 15 + p * 10,
                            spreadRadius: p * 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Colors.white,
                        size: 20,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                DesignTokens.neonRed,
                                DesignTokens.neonCyan,
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'FIGHTWIRE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildLiveBadge(),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_feed.length} signals · ${_scanner.bots.length} bots scanning',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DesignTokens.neonCyan.withValues(alpha: 0.2),
                        DesignTokens.neonMagenta.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _loadFeed();
                    },
                    child: const Icon(
                      Icons.refresh,
                      color: DesignTokens.neonCyan,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _headerActionButton(
                  icon: Icons.handshake_outlined,
                  tooltip: 'Deal Desk',
                  onTap: _openDealDesk,
                ),
                const SizedBox(width: 8),
                _headerActionButton(
                  icon: _caseStudyMode
                      ? Icons.insights
                      : Icons.insights_outlined,
                  tooltip: 'Case-Study Mode',
                  onTap: () => setState(() => _caseStudyMode = !_caseStudyMode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // LIVE Badge (reusable)
  Widget _buildLiveBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonRed,
                DesignTokens.neonRed.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.neonRed.withValues(alpha: 0.4 * value),
                blurRadius: 10 * value,
                spreadRadius: 2 * value,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.9 * value),
                      blurRadius: 6 * value,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
      ),
    );
  }

  Widget _buildDevTrustBadge(_FeedItem item) {
    if (!kDebugMode || item.trustScore == null) {
      return const SizedBox.shrink();
    }

    final trustScore = item.trustScore!;
    final rankingWeight = item.rankingWeight ?? 0.0;
    final accent = trustScore >= 0.9
        ? AppTheme.neonGreen
        : trustScore >= 0.8
        ? AppTheme.neonOrange
        : AppTheme.errorColor;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.24)),
        ),
        child: Text(
          'DEV TRUST ${item.trustProfileKey ?? 'unclassified'} ${trustScore.toStringAsFixed(2)} · W ${rankingWeight.toStringAsFixed(2)}',
          style: TextStyle(
            color: accent,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // FILTER STRIP with Glass Effect
  // ─────────────────────────────────────────────────
  Widget _buildFilterStrip() {
    // All sanctioned sport filters are always visible.
    final visibleFilters = _filters;
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: visibleFilters.length,
        itemBuilder: (context, i) {
          final f = visibleFilters[i];
          final sel = f == _activeFilter;
          final isIG = f == 'Instagram';
          final isFB = f == 'Facebook';
          final isCommunity = f == 'Community';
          final isDFC = f == 'DFC Hype';
          final chipColor = isIG
              ? const Color(0xFFE1306C)
              : isFB
              ? const Color(0xFF1877F2)
              : isCommunity
              ? DesignTokens.neonCyan
              : isDFC
              ? DesignTokens.neonMagenta
              : DesignTokens.neonRed;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _activeFilter = f);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: sel ? 12 : 6,
                  sigmaY: sel ? 12 : 6,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: sel
                        ? LinearGradient(
                            colors: [
                              chipColor.withValues(alpha: 0.25),
                              chipColor.withValues(alpha: 0.15),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.white.withValues(alpha: 0.03),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: sel
                          ? chipColor.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.15),
                      width: sel ? 1.5 : 1,
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: chipColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isIG)
                        Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: sel ? chipColor : Colors.white60,
                        ),
                      if (isFB)
                        Icon(
                          Icons.facebook,
                          size: 14,
                          color: sel ? chipColor : Colors.white60,
                        ),
                      if (isCommunity)
                        Icon(
                          Icons.people,
                          size: 14,
                          color: sel ? chipColor : Colors.white60,
                        ),
                      if (isDFC)
                        Icon(
                          Icons.diamond,
                          size: 14,
                          color: sel ? chipColor : Colors.white60,
                        ),
                      if (isIG || isFB || isCommunity || isDFC)
                        const SizedBox(width: 6),
                      Text(
                        f,
                        style: TextStyle(
                          color: sel ? chipColor : Colors.white60,
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: sel ? 0.5 : 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // HERO CAROUSEL — auto-flicks featured stories
  // ─────────────────────────────────────────────────
  Widget _buildHeroCarousel() {
    final featured = _feed.where((f) => f.isFeatured).take(8).toList();
    if (featured.isEmpty) return const SizedBox.shrink();

    final colors = [
      DesignTokens.neonRed,
      DesignTokens.neonCyan,
      AppTheme.neonMagenta,
      const Color(0xFFFFD700),
      const Color(0xFF00E5FF),
      const Color(0xFFE1306C),
      DesignTokens.neonGreen,
      const Color(0xFF9C27B0),
    ];

    return Container(
      height: 190,
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _heroPgCtrl,
              itemCount: featured.length,
              onPageChanged: (i) => setState(() => _heroPage = i),
              itemBuilder: (context, i) {
                final item = featured[i];
                final accent = colors[i % colors.length];
                return GestureDetector(
                  onTap: item.url != null
                      ? () => launchUrl(
                          Uri.parse(item.url!),
                          mode: LaunchMode.externalApplication,
                        )
                      : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.12),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                      image: item.imageUrl != null
                          ? DecorationImage(
                              image: ImageAssets.resolveImage(item.imageUrl!),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.55),
                                BlendMode.darken,
                              ),
                              onError: (_, _) {},
                            )
                          : null,
                      gradient: item.imageUrl == null
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withValues(alpha: 0.18),
                                Colors.white.withValues(alpha: 0.02),
                                accent.withValues(alpha: 0.06),
                              ],
                            )
                          : null,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: 0.25),
                            Colors.transparent,
                            accent.withValues(alpha: 0.10),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      item.sourceIcon,
                                      color: accent,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      item.source.toUpperCase(),
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.isBreaking) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DesignTokens.neonRed.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: DesignTokens.neonRed.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    '🔴 BREAKING',
                                    style: TextStyle(
                                      color: DesignTokens.neonRed,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Text(
                                '${i + 1}/${featured.length}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Headline
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Bottom row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.body,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (item.url != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'READ →',
                                    style: TextStyle(
                                      color: accent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Page dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(featured.length, (i) {
              final active = i == _heroPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? colors[_heroPage % colors.length]
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  List<_FeedItem> _opportunityLeaders(List<_FeedItem> items) {
    final eligible = items
        .where(
          (item) =>
              item.type != _FeedItemType.sponsored &&
              ((item.strategicScore ?? 0.0) >= 1.55 ||
                  (item.promoterOpportunityScore ?? 0.0) >= 0.28),
        )
        .toList();

    eligible.sort((a, b) {
      final strategyDelta = (b.strategicScore ?? 0.0).compareTo(
        a.strategicScore ?? 0.0,
      );
      if (strategyDelta != 0) return strategyDelta;
      return b.timestamp.compareTo(a.timestamp);
    });

    return eligible.take(8).toList();
  }

  Widget _buildPowerhouseOpportunityRail(List<_FeedItem> items) {
    final leaders = _opportunityLeaders(items);
    if (leaders.isEmpty) return const SizedBox.shrink();

    int countRole(String roleKey) {
      return leaders
          .where((item) => item.commandSignals.contains('role-$roleKey'))
          .length;
    }

    final fightersCount = countRole('fighters');
    final gymsCount = countRole('gyms');
    final fansCount = countRole('fans');
    final eventsCount = countRole('events');
    final trainersCount = countRole('trainers');
    final managersCount = countRole('managers');
    final promotersCount = countRole('promoters');

    return Container(
      height: 196,
      margin: const EdgeInsets.fromLTRB(0, 6, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.neonMagenta.withValues(alpha: 0.28),
                        DesignTokens.neonCyan.withValues(alpha: 0.2),
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.neonMagenta.withValues(alpha: 0.55),
                    ),
                  ),
                  child: const Text(
                    'POWERHOUSE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Promoter Opportunities',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${leaders.length} live',
                  style: TextStyle(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildRoleChip('Fighters', fightersCount),
                _buildRoleChip('Gyms', gymsCount),
                _buildRoleChip('Fans', fansCount),
                _buildRoleChip('Events', eventsCount),
                _buildRoleChip('Trainers', trainersCount),
                _buildRoleChip('Managers', managersCount),
                _buildRoleChip('Promoters', promotersCount),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: leaders.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = leaders[index];
                final opp = ((item.promoterOpportunityScore ?? 0.0) * 100)
                    .round();
                final strategy = ((item.strategicScore ?? 0.0) * 33.3)
                    .clamp(0, 100)
                    .round();
                final orderedSignals = _prioritySignals(item.commandSignals);
                final topSignals = orderedSignals.take(2).toList();
                final primarySignal = orderedSignals.isEmpty
                    ? 'launch-opportunity'
                    : orderedSignals.first;

                return GestureDetector(
                  onTap: item.url == null
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          launchUrl(
                            Uri.parse(item.url!),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                  child: Container(
                    width: 260,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          item.accent.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                      ),
                      border: Border.all(
                        color: item.accent.withValues(alpha: 0.45),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: item.accent.withValues(alpha: 0.2),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(item.sourceIcon, size: 14, color: item.accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.source,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '$strategy',
                              style: TextStyle(
                                color: DesignTokens.neonCyan.withValues(
                                  alpha: 0.9,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                        // DFC Fighter Stardom Pipeline arc banner.
                        // Shows promoters exactly where this fighter is on
                        // the journey: DISCOVER → BUILD → WIN → SELL
                        if (item.commandSignals.contains(
                          'stardom-pipeline',
                        )) ...[
                          const SizedBox(height: 6),
                          _buildPipelineArc(item.commandSignals),
                        ] else if (item.commandSignals.contains(
                          'jake-paul-effect',
                        )) ...[
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.withValues(alpha: 0.28),
                                  AppTheme.neonMagenta.withValues(alpha: 0.18),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.55),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Text('⚡', style: TextStyle(fontSize: 10)),
                                SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'JAKE PAUL EFFECT — audience buys tickets because of WHO they are, not their record',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (topSignals.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: topSignals
                                .map(
                                  (signal) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(7),
                                      color: DesignTokens.neonCyan.withValues(
                                        alpha: 0.16,
                                      ),
                                      border: Border.all(
                                        color: DesignTokens.neonCyan.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _signalLabel(signal),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: AppTheme.neonMagenta.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              child: Text(
                                'OPP $opp',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _timeAgo(item.timestamp),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _copyPartnerOnePager(
                                item: item,
                                primarySignal: primarySignal,
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(40, 24),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'BRIEF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _copyYouTubePromptPack(
                                item: item,
                                primarySignal: primarySignal,
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(44, 24),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'PROMPT',
                                style: TextStyle(
                                  color: DesignTokens.neonMagenta.withValues(
                                    alpha: 0.95,
                                  ),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.45,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _routeLaunchAction(
                                signal: primarySignal,
                                source: item.source,
                                signals: item.commandSignals,
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(36, 24),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'ACT',
                                style: TextStyle(
                                  color: DesignTokens.neonCyan.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (item.url != null)
                              Text(
                                'OPEN',
                                style: TextStyle(
                                  color: item.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _signalLabel(String signal) {
    // Convert machine signals into clear labels for non-technical promoters.
    return signal.replaceAll('-', ' ').replaceAll(':', ' ').toUpperCase();
  }

  List<String> _prioritySignals(List<String> signals) {
    const order = {
      'samurai-promotion': 1,
      'joseph-priority': 2,
      'legends-show': 3,
      'main-event-draw': 4,
      'deal-close-ready': 5,
      'sign-seal-deliver': 6,
      'promoter-event-hook': 7,
      'ticket-seller': 8,
      'sell-out-risk': 9,
      'social-seller': 10,
      'stardom-pipeline': 11,
      'jake-paul-effect': 12,
      'contract-ready': 13,
      'single-fight-sell': 14,
      'ppv-ready': 15,
      'contact-now': 16,
    };

    final sorted = [...signals];
    sorted.sort((a, b) => (order[a] ?? 999).compareTo(order[b] ?? 999));
    return sorted;
  }

  void _routeLaunchAction({
    required String signal,
    required String source,
    required List<String> signals,
  }) {
    final isDealSignal =
        signal == 'deal-close-ready' ||
        signal == 'sign-seal-deliver' ||
        signal == 'promoter-event-hook' ||
        signal == 'contract-ready';

    final pitchFocus = _resolvePitchFocus(signals);

    // ── Track stage advancement in ecosystem ──────────────────────────────
    // When ACT is clicked, opportunity moves from DISCOVER to BUILD
    _ecosystemState.advanceOpportunityStage(
      source, // Use source as ID for now
      'discover',
      'build',
      isDealSignal ? 'deal_attempt' : 'outreach_started',
    );

    final uri = Uri(
      path: rc.RouterConfig.inboxPath,
      queryParameters: {
        'action': isDealSignal ? 'deal-close' : 'launch',
        'signal': signal,
        'source': source,
        'pitch': pitchFocus,
      },
    );
    context.push(uri.toString());
  }

  String _resolvePitchFocus(List<String> signals) {
    final hasPromotionSide =
        signals.contains('role-promoters') ||
        signals.contains('role-events') ||
        signals.contains('deal-close-ready') ||
        signals.contains('sign-seal-deliver') ||
        signals.contains('promoter-event-hook');

    final hasFighterSide =
        signals.contains('role-fighters') ||
        signals.contains('role-gyms') ||
        signals.contains('role-trainers') ||
        signals.contains('social-seller') ||
        signals.contains('talent-scout') ||
        signals.contains('stardom-pipeline');

    if (hasPromotionSide && !hasFighterSide) return 'promotion';
    if (hasFighterSide && !hasPromotionSide) return 'fighter';
    return 'dual';
  }

  Future<void> _copyPartnerOnePager({
    required _FeedItem item,
    required String primarySignal,
  }) async {
    final text = _buildPartnerOnePagerText(item, primarySignal);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Partner one-pager copied')));
  }

  Future<void> _copyYouTubePromptPack({
    required _FeedItem item,
    required String primarySignal,
  }) async {
    final text = _buildYouTubePromptPackText(item, primarySignal);
    await Clipboard.setData(ClipboardData(text: text));

    // ── Record YouTube promise generation in ecosystem ───────────────────
    _ecosystemState.recordYouTubeGeneration(item.id, item.source);

    // ── Process feedback: YouTube generation advances opportunity to WIN ──
    try {
      _feedbackEngine.processFeedbackEvent(
        EcosystemFeedbackEvent(
          eventType: 'youtube_brief_generated',
          opportunityId: item.id,
          source: item.source,
          timestamp: DateTime.now(),
          metricDelta: {'youtube_briefs': 1},
        ),
      );
    } catch (e) {
      debugPrint('Feedback processing error: $e');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('YouTube prompt pack copied')));
  }

  String _buildYouTubePromptPackText(_FeedItem item, String primarySignal) {
    final angle = _resolvePitchFocus(item.commandSignals).toUpperCase();
    final trust = (((item.trustScore ?? 0.0) * 100).clamp(0, 100)).round();
    final strategic = (((item.strategicScore ?? 0.0) * 33.3).clamp(
      0,
      100,
    )).round();
    final opportunity = (((item.promoterOpportunityScore ?? 0.0) * 100).clamp(
      0,
      100,
    )).round();
    final hook = item.title;
    final value = item.body;

    return 'DFC YOUTUBE PROMPT PACK\n'
        'Campaign Source: ${item.source}\n'
        'Primary Signal: ${_signalLabel(primarySignal)}\n'
        'Pitch Angle: $angle\n'
        'Scorecard: Strategic $strategic/100 | Opportunity $opportunity/100 | Trust $trust/100\n\n'
        'PROMPT 1 - HERO TRAILER (60s)\n'
        'Create a cinematic combat sports trailer around: "$hook".\n'
        'Use this value line: "$value".\n'
        'Structure: 0-3s hook, 3-20s conflict + stakes, 20-45s social proof + urgency, 45-60s call to action for tickets.\n'
        'Visual style: premium arena lighting, crowd atmosphere, athlete closeups, broadcast-grade motion graphics.\n\n'
        'PROMPT 2 - SOCIAL PROOF SHORT (30s)\n'
        'Generate a vertical short proving momentum for "$hook".\n'
        'Include growth overlays (views, demand, engagement), ticket urgency, and one strong CTA.\n'
        'Tone: high-energy, authentic, no fake claims.\n\n'
        'PROMPT 3 - PROMOTER DEAL CUT (45s)\n'
        'Generate a business-focused promo for events/promoters.\n'
        'Include: audience conversion potential, deal-close readiness, and why this is bankable now.\n'
        'End card: "Sign. Seal. Deliver. Close this card now."\n\n'
        'PROMPT 4 - FIGHTER STARDOM CUT (45s)\n'
        'Generate a fighter ecosystem promo for fighters/gyms/trainers/managers.\n'
        'Include: discover -> build -> win -> sell journey, fan growth, and ticket pull.\n'
        'End card: "Turn momentum into stardom."\n\n'
        'CAPTION OPTIONS\n'
        '1) From signal to sellout. This is where fight business gets done.\n'
        '2) Bankable now. Audience ready. Action today.\n'
        '3) Real momentum, real tickets, real outcomes.\n\n'
        'HASHTAGS\n'
        '#FightBusiness #CombatSports #FightNight #Tickets #Promoter #DFC';
  }

  String _buildPartnerOnePagerText(_FeedItem item, String primarySignal) {
    final strategic = (((item.strategicScore ?? 0.0) * 33.3).clamp(
      0,
      100,
    )).round();
    final opportunity = (((item.promoterOpportunityScore ?? 0.0) * 100).clamp(
      0,
      100,
    )).round();
    final trust = (((item.trustScore ?? 0.0) * 100).clamp(0, 100)).round();
    final pitch = _resolvePitchFocus(item.commandSignals);
    final ticketSignal =
        item.commandSignals.contains('ticket-seller') ||
        item.commandSignals.contains('main-event-draw') ||
        item.commandSignals.contains('sell-out-risk');
    final closeSignal =
        item.commandSignals.contains('deal-close-ready') ||
        item.commandSignals.contains('sign-seal-deliver');

    return 'DFC PARTNER ONE-PAGER\n'
        'Source: ${item.source}\n'
        'Title: ${item.title}\n\n'
        'SCORECARD\n'
        'Audience Size Proxy: ${item.likes + item.comments + item.shares}\n'
        'Ticket Conversion Signal: ${ticketSignal ? 'HIGH' : 'MEDIUM'}\n'
        'Deal-Close Readiness: ${closeSignal ? 'READY' : 'BUILDING'}\n'
        'Trust/Safety Level: $trust/100\n'
        'Strategic Score: $strategic/100\n'
        'Opportunity Score: $opportunity/100\n\n'
        'WHY THIS IS BANKABLE NOW\n'
        '- Primary signal: ${_signalLabel(primarySignal)}\n'
        '- Role angle: ${pitch.toUpperCase()}\n'
        '- Momentum: ${item.engagementLabel ?? 'Live feed momentum'}\n'
        '- Action: Open outreach now and secure terms before market competition.\n';
  }

  void _openDealDesk() {
    final closeItems =
        _feed
            .where(
              (f) =>
                  f.commandSignals.contains('deal-close-ready') ||
                  f.commandSignals.contains('sign-seal-deliver') ||
                  f.commandSignals.contains('promoter-event-hook') ||
                  f.commandSignals.contains('contract-ready'),
            )
            .toList()
          ..sort(
            (a, b) => (b.strategicScore ?? 0).compareTo(a.strategicScore ?? 0),
          );
    final top = closeItems.take(10).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.8,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'DEAL DESK · TOP 10 CLOSE-READY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: top.isEmpty
                          ? null
                          : () async {
                              final csv = _buildDealDeskCsv(top);
                              await Clipboard.setData(ClipboardData(text: csv));
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Deal Desk CSV copied'),
                                ),
                              );
                            },
                      child: const Text(
                        'EXPORT CSV',
                        style: TextStyle(
                          color: DesignTokens.neonCyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: top.isEmpty
                          ? null
                          : () async {
                              final loop = _buildDealDeskFollowUp(top);
                              await Clipboard.setData(
                                ClipboardData(text: loop),
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Follow-up loop copied'),
                                ),
                              );
                            },
                      child: const Text(
                        'FOLLOW-UP',
                        style: TextStyle(
                          color: DesignTokens.neonMagenta,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: top.length,
                  itemBuilder: (_, i) {
                    final item = top[i];
                    final nextAction =
                        item.commandSignals.contains('sign-seal-deliver')
                        ? 'Send final terms + lock date'
                        : item.commandSignals.contains('deal-close-ready')
                        ? 'Issue LOI and confirm venue hold'
                        : 'Open intro and qualify partner fit';
                    final deadline = DateTime.now().add(
                      Duration(days: 3 + i % 4),
                    );

                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i + 1}. ${item.title}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Owner: DFC Deal Ops  |  Next: $nextAction  |  Deadline: ${deadline.day}/${deadline.month}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _buildDealDeskCsv(List<_FeedItem> items) {
    final buffer = StringBuffer();
    buffer.writeln(
      'rank,title,source,primary_signal,owner,next_action,deadline,strategic_score,opportunity_score,trust_score',
    );

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final primarySignal = _prioritySignals(item.commandSignals).isEmpty
          ? 'monitor'
          : _prioritySignals(item.commandSignals).first;
      final nextAction = item.commandSignals.contains('sign-seal-deliver')
          ? 'Send final terms + lock date'
          : item.commandSignals.contains('deal-close-ready')
          ? 'Issue LOI and confirm venue hold'
          : 'Open intro and qualify partner fit';
      final deadline = DateTime.now().add(Duration(days: 3 + i % 4));
      final strategic = (((item.strategicScore ?? 0.0) * 33.3).clamp(
        0,
        100,
      )).round();
      final opportunity = (((item.promoterOpportunityScore ?? 0.0) * 100).clamp(
        0,
        100,
      )).round();
      final trust = (((item.trustScore ?? 0.0) * 100).clamp(0, 100)).round();

      buffer.writeln(
        '${i + 1},${_csv(item.title)},${_csv(item.source)},${_csv(primarySignal)},DFC Deal Ops,${_csv(nextAction)},${deadline.day}/${deadline.month},$strategic,$opportunity,$trust',
      );
    }

    return buffer.toString();
  }

  String _buildDealDeskFollowUp(List<_FeedItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('DFC DEAL DESK FOLLOW-UP LOOP');
    buffer.writeln(
      'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
    );
    buffer.writeln();
    buffer.writeln('Daily Cadence');
    buffer.writeln('- 09:00: Re-rank top opportunities and assign owners');
    buffer.writeln(
      '- 13:00: Send follow-ups, update status, confirm next commitments',
    );
    buffer.writeln(
      '- 18:00: Close-day review and move unresolved deals to tomorrow',
    );
    buffer.writeln();
    buffer.writeln('Top Opportunities');

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final signal = _prioritySignals(item.commandSignals).isEmpty
          ? 'MONITOR'
          : _signalLabel(_prioritySignals(item.commandSignals).first);
      final nextAction = item.commandSignals.contains('sign-seal-deliver')
          ? 'Send final terms and lock event date'
          : item.commandSignals.contains('deal-close-ready')
          ? 'Issue LOI and secure venue hold'
          : 'Open intro and qualify partner scope';
      final strategic = (((item.strategicScore ?? 0.0) * 33.3).clamp(
        0,
        100,
      )).round();
      final deadline = DateTime.now().add(Duration(days: 3 + i % 4));

      buffer.writeln('${i + 1}. ${item.title}');
      buffer.writeln('   Source: ${item.source}');
      buffer.writeln('   Signal: $signal');
      buffer.writeln('   Owner: DFC Deal Ops');
      buffer.writeln('   Next: $nextAction');
      buffer.writeln('   Deadline: ${deadline.day}/${deadline.month}');
      buffer.writeln('   Strategic Score: $strategic/100');
      buffer.writeln();
    }

    buffer.writeln(
      'Status Codes: NEW | CONTACTED | NEGOTIATING | TERMS_SENT | CLOSED',
    );
    return buffer.toString();
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Widget _buildCaseStudyPanel(List<_FeedItem> items) {
    final sample = items
        .where((f) => f.commandSignals.isNotEmpty)
        .take(3)
        .toList();
    if (sample.isEmpty) return const SizedBox.shrink();

    int viewsBefore(_FeedItem item) =>
        ((item.likes + item.comments + item.shares) * 2).clamp(500, 50000);
    int viewsAfter(_FeedItem item) =>
        (viewsBefore(item) * 5).clamp(5000, 250000);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppTheme.neonMagenta.withValues(alpha: 0.16),
            DesignTokens.neonCyan.withValues(alpha: 0.14),
          ],
        ),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CASE-STUDY MODE · BEFORE / AFTER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          ...sample.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${item.source}: Views ${viewsBefore(item)} -> ${viewsAfter(item)} | Ticket Demand: +${(item.promoterOpportunityScore ?? 0) * 100 ~/ 1}% | Engagement: +${(item.strategicScore ?? 0) * 30 ~/ 1}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineArc(List<String> commandSignals) {
    final stage = commandSignals.firstWhere(
      (s) => s.startsWith('pipeline:'),
      orElse: () => 'pipeline:discover',
    );

    final activeIndex = switch (stage) {
      'pipeline:sell' => 3,
      'pipeline:win' => 2,
      'pipeline:build' => 1,
      _ => 0,
    };

    const labels = ['DISCOVER', 'BUILD', 'WIN', 'SELL'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.16),
            AppTheme.neonMagenta.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index <= activeIndex;
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: active
                          ? DesignTokens.neonGreen.withValues(alpha: 0.6)
                          : Colors.white24,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: active
                        ? DesignTokens.neonGreen.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: active
                          ? DesignTokens.neonGreen.withValues(alpha: 0.45)
                          : Colors.white24,
                    ),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: active ? DesignTokens.neonGreen : Colors.white60,
                      fontSize: 7.6,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRoleChip(String label, int count) {
    final active = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: active
            ? DesignTokens.neonGreen.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: active
              ? DesignTokens.neonGreen.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          color: active ? DesignTokens.neonGreen : Colors.white54,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // INFINITE-SCROLL FEED with Premium Loading
  // ─────────────────────────────────────────────────
  Widget _buildScrollingFeed() {
    final items = _filteredFeed;
    if (items.isEmpty) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.radar,
                    size: 56,
                    color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                    ).createShader(bounds),
                    child: Text(
                      'No signals for "$_activeFilter"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bots are scanning the internet...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_activeFilter == 'All') _buildPowerhouseOpportunityRail(items),
        if (_activeFilter == 'Launch' && _caseStudyMode)
          _buildCaseStudyPanel(items),
        // Auto-rotating headline stories carousel
        if (_activeFilter == 'All') _buildHeroCarousel(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
            itemCount: items.length + 1, // +1 for loading indicator
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return _isLoadingMore
                    ? _buildPremiumLoadingIndicator()
                    : _buildLoadMoreButton();
              }

              final item = items[index];

              // Staggered animation for items
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index % 5) * 50),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: item.type == _FeedItemType.sponsored
                    ? _buildSponsoredCard(item)
                    : item.type == _FeedItemType.promo
                    ? _buildPromoCard(item)
                    : item.type == _FeedItemType.community
                    ? _buildCommunityCard(item)
                    : item.type == _FeedItemType.social
                    ? _buildSocialCard(item)
                    : _buildNewsCard(item),
              );
            },
          ), // ListView.builder
        ), // Expanded
      ],
    ); // Column
  }

  // Premium Loading Indicator
  Widget _buildPremiumLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            builder: (context, value, child) {
              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: const [
                      DesignTokens.neonRed,
                      DesignTokens.neonCyan,
                      DesignTokens.neonMagenta,
                      DesignTokens.neonRed,
                    ],
                    stops: [0.0, value * 0.5, value, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.neonRed.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBackground,
                  ),
                  child: const Icon(
                    Icons.radar,
                    color: DesignTokens.neonRed,
                    size: 22,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [DesignTokens.neonRed, DesignTokens.neonCyan],
            ).createShader(bounds),
            child: const Text(
              'Scanning for signals...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Load More Button
  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _loadMore();
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.neonCyan.withValues(alpha: 0.15),
                      DesignTokens.neonMagenta.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.radar,
                      size: 18,
                      color: DesignTokens.neonCyan,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Scan for more signals',
                      style: TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // NEWS CARD — Premium Glass Morphism
  // ─────────────────────────────────────────────────
  Widget _buildNewsCard(_FeedItem item) {
    final isBreakingRecent =
        item.isBreaking &&
        DateTime.now().difference(item.timestamp).inMinutes <= 30;

    return GestureDetector(
      onTap: item.url != null
          ? () {
              HapticFeedback.lightImpact();
              launchUrl(
                Uri.parse(item.url!),
                mode: LaunchMode.externalApplication,
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    item.accent.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: item.accent.withValues(
                    alpha: isBreakingRecent ? 0.5 : 0.2,
                  ),
                  width: isBreakingRecent ? 2 : 1.5,
                ),
                boxShadow: [
                  if (isBreakingRecent)
                    BoxShadow(
                      color: item.accent.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  BoxShadow(
                    color: item.accent.withValues(alpha: 0.1),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(item.sourceIcon, color: item.accent, size: 16),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: item.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: item.accent.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              item.source,
                              style: TextStyle(
                                color: item.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (item.isBreaking) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: DesignTokens.neonRed.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: DesignTokens.neonRed.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'BREAKING',
                                style: TextStyle(
                                  color: DesignTokens.neonRed,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            _timeAgo(item.timestamp),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Hero image
                      if (item.imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 160,
                              width: double.infinity,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  DfcImage(
                                    url: item.imageUrl,
                                    width: double.infinity,
                                    height: 160,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.5),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12.5,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (item.tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: item.tags.take(4).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: item.accent.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      _buildDevTrustBadge(item),
                    ],
                  ),
                  // LIVE Badge
                  if (isBreakingRecent)
                    Positioned(top: 12, right: 16, child: _buildLiveBadge()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // SOCIAL / META CARD — Premium Glass + Platform Colors
  // ─────────────────────────────────────────────────
  Widget _buildSocialCard(_FeedItem item) {
    final isIG = item.platform == 'instagram';
    final platformColor = isIG
        ? const Color(0xFFE1306C)
        : const Color(0xFF1877F2);
    final isPostRecent =
        DateTime.now().difference(item.timestamp).inMinutes <= 15;

    return GestureDetector(
      onTap: item.url != null
          ? () {
              HapticFeedback.lightImpact();
              launchUrl(
                Uri.parse(item.url!),
                mode: LaunchMode.externalApplication,
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    platformColor.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: platformColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: platformColor.withValues(alpha: 0.2),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: platformColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with platform badge
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          platformColor.withValues(alpha: 0.08),
                          platformColor.withValues(alpha: 0.02),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            // Platform icon with gradient
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: isIG
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFFCAF45),
                                          Color(0xFFE1306C),
                                          Color(0xFF5851DB),
                                        ],
                                        begin: Alignment.bottomLeft,
                                        end: Alignment.topRight,
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFF1877F2),
                                          Color(0xFF42A5F5),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: platformColor.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isIG ? Icons.camera_alt : Icons.facebook,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.source,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      // Pulsing verified badge
                                      if (item.isVerified)
                                        ScaleTransition(
                                          scale: Tween(begin: 0.8, end: 1.0)
                                              .animate(
                                                CurvedAnimation(
                                                  parent: _pulseCtrl,
                                                  curve: Curves.easeInOut,
                                                ),
                                              ),
                                          child: Icon(
                                            Icons.verified,
                                            color: platformColor,
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (item.sourceHandle != null)
                                    Text(
                                      item.sourceHandle!,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _timeAgo(item.timestamp),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Badges row (REEL + LIVE)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.isReel)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: platformColor.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: platformColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.play_arrow,
                                        color: platformColor,
                                        size: 11,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'REEL',
                                        style: TextStyle(
                                          color: platformColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (isPostRecent) _buildLiveBadge(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Title (if present)
                  if (item.title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),

                  // Body
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: Text(
                      item.body,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  // Image/Video content
                  if (item.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              DfcImage(
                                url: item.imageUrl,
                                width: double.infinity,
                                height: 200,
                              ),
                              // Video play button overlay for reels
                              if (item.isReel)
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.6),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: platformColor.withValues(
                                          alpha: 0.9,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: platformColor.withValues(
                                              alpha: 0.5,
                                            ),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Glass Tags
                  if (item.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: item.tags.take(4).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: platformColor.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                color: platformColor.withValues(alpha: 0.65),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  if (kDebugMode && item.trustScore != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: _buildDevTrustBadge(item),
                    ),

                  // Glass Engagement bar
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              platformColor.withValues(alpha: 0.05),
                              Colors.white.withValues(alpha: 0.01),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            _engagementChip(
                              Icons.favorite_border,
                              _formatNum(item.likes),
                              platformColor,
                            ),
                            const SizedBox(width: 16),
                            _engagementChip(
                              Icons.chat_bubble_outline,
                              _formatNum(item.comments),
                              DesignTokens.neonCyan,
                            ),
                            const SizedBox(width: 16),
                            _engagementChip(
                              Icons.share,
                              _formatNum(item.shares),
                              DesignTokens.neonMagenta,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: platformColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: platformColor.withValues(alpha: 0.2),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.open_in_new,
                                    color: platformColor,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'View',
                                    style: TextStyle(
                                      color: platformColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // COMMUNITY POST CARD — SocialService posts
  // ─────────────────────────────────────────────────
  Widget _buildCommunityCard(_FeedItem item) {
    final post = item.communityPost;
    final isFightCard = post?.postType == 'fight_card';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: item.accent.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Avatar circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [item.accent, item.accent.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      item.title.isNotEmpty ? item.title[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.source,
                        style: TextStyle(
                          color: item.accent.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFightCard)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.description,
                          color: Color(0xFFFFD700),
                          size: 12,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'FIGHT CARD',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  _timeAgo(item.timestamp),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // ── Body ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              item.body,
              maxLines: isFightCard ? 20 : 6,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: isFightCard ? 0.8 : 0.65),
                fontSize: isFightCard ? 12 : 13,
                height: 1.5,
                fontFamily: isFightCard ? 'monospace' : null,
              ),
            ),
          ),

          // ── Image content ──────────────────────────────────────
          if (item.imageUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: DfcImage(
                    url: item.imageUrl,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
              ),
            ),

          // ── Tags ───────────────────────────────────────────────
          if (item.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.tags.take(5).map((tag) {
                  return Text(
                    '#$tag',
                    style: TextStyle(
                      color: item.accent.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Engagement bar ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                _communityAction(
                  Icons.favorite_border,
                  _formatNum(item.likes),
                  DesignTokens.neonRed,
                  onTap: () => _handleLike(post),
                ),
                const SizedBox(width: 20),
                _communityAction(
                  Icons.chat_bubble_outline,
                  _formatNum(item.comments),
                  DesignTokens.neonCyan,
                  onTap: () => _handleComment(post),
                ),
                const SizedBox(width: 20),
                _communityAction(
                  Icons.repeat,
                  'Repost',
                  Colors.white54,
                  onTap: () => _handleRepost(post),
                ),
                const Spacer(),
                _communityAction(
                  Icons.bookmark_border,
                  '',
                  Colors.white38,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saved to bookmarks'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _communityAction(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleLike(Post? post) async {
    if (post == null) return;
    HapticFeedback.lightImpact();
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign in to like posts')));
      return;
    }
    try {
      await _socialService.toggleLike(post.id, userId);
      await _loadFeed();
    } catch (_) {}
  }

  void _handleComment(Post? post) {
    if (post == null) return;
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign in to comment')));
      return;
    }
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Reply',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Write a reply...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    await _socialService.addComment(
                      post.id,
                      userId,
                      controller.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reply posted')),
                      );
                    }
                  } catch (_) {}
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.neonCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Post Reply',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _handleRepost(Post? post) {
    if (post == null) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reposted to your feed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // SPONSORED CARD — Premium promotional content
  // ─────────────────────────────────────────────────
  Widget _buildSponsoredCard(_FeedItem item) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (item.url != null) {
          context.push(item.url!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.accent.withValues(alpha: 0.08),
              Colors.black.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            width: 2,
            color: item.accent.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: item.accent.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sponsored Badge ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          item.accent.withValues(alpha: 0.25),
                          item.accent.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: item.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign, size: 12, color: item.accent),
                        const SizedBox(width: 4),
                        Text(
                          'SPONSORED',
                          style: TextStyle(
                            color: item.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    item.sourceIcon,
                    size: 16,
                    color: item.accent.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),

            // ── Content ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: item.accent.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── CTA Button ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [item.accent, item.accent.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: item.accent.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Learn More',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // PROMO CARD — AI-generated hype content
  // ─────────────────────────────────────────────────
  Widget _buildPromoCard(_FeedItem item) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (item.url != null && item.url!.isNotEmpty) {
          final uri = YouTubeService.normalizePublicYoutubeUri(
            item.url!,
            fallbackSearchQuery: item.title,
          );
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.neonMagenta.withValues(alpha: 0.06),
              Colors.black.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.neonMagenta.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.neonMagenta.withValues(alpha: 0.2),
                          AppTheme.neonCyan.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.sourceIcon,
                      color: AppTheme.neonMagenta,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.source,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.neonMagenta.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AI HYPE',
                                style: TextStyle(
                                  color: AppTheme.neonMagenta,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _timeAgo(item.timestamp),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Image ───────────────────────────────────────────
            if (item.imageUrl != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: DfcImage(
                      url: item.imageUrl,
                      height: 160,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),

            // ── Content ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tags ───────────────────────────────────────────
            if (item.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: item.tags.take(5).map((tag) {
                    return Text(
                      '#$tag',
                      style: TextStyle(
                        color: AppTheme.neonMagenta.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // COMPOSE SHEET — Post to FightWire
  // ─────────────────────────────────────────────────
  void _showComposeSheet(BuildContext context) {
    final auth = context.read<AuthService>();
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to post on FightWire')),
      );
      return;
    }
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DesignTokens.neonRed, Color(0xFFFF6B35)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.bolt, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Post to FightWire',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText:
                    'What\'s happening in the fight game?\n\nShare training updates, fight results, callouts...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                counterStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: DesignTokens.neonRed.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;

                  // Content safety check
                  final safetySvc = context.read<ContentSafetyService>();
                  final result = safetySvc.checkText(controller.text.trim());
                  if (!result.passed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Content blocked: ${result.flaggedTerms.first}',
                        ),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await _socialService.createPost(
                      authorId: userId,
                      content: controller.text.trim(),
                    );
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Posted to FightWire! 🥊'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                      _loadFeed();
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to post: $e'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.bolt, size: 18),
                label: const Text(
                  'POST',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.neonRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _engagementChip(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          count,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  String _platformFromAuto(AutoFeedItem item) {
    final url = item.linkUrl ?? '';
    if (url.contains('instagram.com')) return 'instagram';
    if (url.contains('facebook.com')) return 'facebook';
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return 'youtube';
    }
    if (item.sourceType == FeedSourceType.news) return 'news';
    if (item.sourceType == FeedSourceType.studio) return 'studio';
    if (item.sourceType == FeedSourceType.partner) return 'partner';
    return 'social';
  }

  IconData _sourceIconFromAuto(AutoFeedItem item, String platform) {
    switch (platform) {
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      case 'youtube':
        return Icons.play_circle;
      case 'studio':
        return Icons.movie_creation_outlined;
      case 'news':
        return Icons.newspaper;
      default:
        return item.sourceType == FeedSourceType.video
            ? Icons.ondemand_video
            : Icons.bolt;
    }
  }

  Color _accentFromAuto(AutoFeedItem item, String platform) {
    switch (platform) {
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'studio':
        return AppTheme.neonPurple;
      case 'partner':
        return AppTheme.neonOrange;
      case 'news':
        return DesignTokens.neonCyan;
      default:
        return item.sourceType == FeedSourceType.video
            ? DesignTokens.neonRed
            : Colors.white70;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FEED ITEM MODEL — Unified item for news + social content
// ═══════════════════════════════════════════════════════════════════════════
enum _FeedItemType { news, social, community, promo, sponsored }

class _FeedItem {
  final String id;
  final _FeedItemType type;
  final String title;
  final String body;
  final String source;
  final String? sourceHandle;
  final IconData sourceIcon;
  final DateTime timestamp;
  final Color accent;
  final List<String> tags;
  final bool isBreaking;
  final bool isFeatured;
  final bool isVerified;
  final String platform;
  final String? url;
  final String? imageUrl;
  final int likes;
  final int comments;
  final int shares;
  final String? engagementLabel;
  final bool isReel;
  final double? trustScore;
  final double? rankingWeight;
  final String? trustProfileKey;
  final double? promoterOpportunityScore;
  final double? strategicScore;
  final List<String> commandSignals;
  final Post? communityPost;

  const _FeedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.source,
    this.sourceHandle,
    required this.sourceIcon,
    required this.timestamp,
    required this.accent,
    this.tags = const [],
    this.isBreaking = false,
    this.isFeatured = false,
    this.isVerified = false,
    this.platform = 'news',
    this.url,
    this.imageUrl,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.engagementLabel,
    this.isReel = false,
    this.trustScore,
    this.rankingWeight,
    this.trustProfileKey,
    this.promoterOpportunityScore,
    this.strategicScore,
    this.commandSignals = const [],
    this.communityPost,
  });
}
