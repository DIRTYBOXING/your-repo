import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/config/router_config.dart' as rc;
import '../../../core/constants/app_logos.dart';
import '../../../core/constants/image_assets.dart';
import '../services/promoter_service.dart';
import '../../../shared/models/promotion_model.dart';
import '../widgets/promotion_card.dart';
import '../../../shared/widgets/inline_video_card.dart';
import '../../../shared/widgets/ecosystem_hub.dart';
import '../../../shared/services/fight_news_service.dart';
import '../../../shared/services/event_service.dart';
import '../../../shared/models/event_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../../../shared/services/analytics_service.dart';
import '../../../shared/services/content_scanner_engine.dart';
import '../../../shared/services/referral_link_service.dart';
import '../../../shared/services/referral_points_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTER COMMAND CENTRE — The Ultimate Fight Show Builder
/// Revenue · Tickets · Matchmaker · Marketing · Fight Card · Analytics
/// ═══════════════════════════════════════════════════════════════════════════

const _kMagenta = Color(0xFFE040FB);
const _kCyan = Color(0xFF00E5FF);
const _kGreen = Color(0xFF00E676);
const _kOrange = Color(0xFFFF9100);
const _kRed = Color(0xFFFF1744);
const _kGold = Color(0xFFFFD740);
const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);

class PromoterDashboardScreen extends StatefulWidget {
  const PromoterDashboardScreen({super.key});
  @override
  State<PromoterDashboardScreen> createState() =>
      _PromoterDashboardScreenState();
}

class _PromoterDashboardScreenState extends State<PromoterDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late PromoterService _service;
  late FightNewsService _newsService;
  late EventService _eventService;
  late ContentScannerEngine _scannerEngine;
  bool _depsReady = false;
  late Future<List<PromotionModel>> _promotionsFuture;
  late Future<Map<String, dynamic>> _statsFuture;

  // Mock sliding revenue data (12 months)
  final _revenueData = <double>[
    4200,
    5800,
    7200,
    6100,
    8400,
    9600,
    11200,
    10800,
    13400,
    12100,
    15800,
    18200,
  ];
  final _ticketData = <double>[
    120,
    180,
    220,
    190,
    310,
    350,
    420,
    380,
    490,
    450,
    580,
    640,
  ];
  final _months = [
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
    'Jan',
    'Feb',
  ];

  // Matchmaker state
  int? _selectedFighterA;
  int? _selectedFighterB;

  // Referral share state
  String _referralCode = '';
  final _referralLinkService = ReferralLinkService();

  // Fighter roster for matchmaker
  static final _roster = <_RosterFighter>[
    const _RosterFighter(
      name: 'Marcus Torres',
      record: '25-7',
      weight: 'Middleweight',
      style: 'MMA',
      rating: 94,
      trend: 1,
    ),
    const _RosterFighter(
      name: 'Mako Tua',
      record: '15-8',
      weight: 'Heavyweight',
      style: 'Brawler',
      rating: 85,
      trend: -1,
      isSuspended: true,
      suspensionReason: 'Concussion Protocol (22 Days Rem.)',
    ),
    const _RosterFighter(
      name: 'Tyler Reid',
      record: '26-4',
      weight: 'Featherweight',
      style: 'MMA',
      rating: 96,
      trend: 1,
    ),
    const _RosterFighter(
      name: 'Elijah Okafor',
      record: '24-4',
      weight: 'Middleweight',
      style: 'Striker',
      rating: 93,
      trend: 1,
    ),
    const _RosterFighter(
      name: 'Tama Rawiri',
      record: '24-11',
      weight: 'Flyweight',
      style: 'Striker',
      rating: 87,
      trend: 0,
    ),
    const _RosterFighter(
      name: 'Nathan Cross',
      record: '24-12',
      weight: 'Lightweight',
      style: 'MMA',
      rating: 86,
      trend: 1,
    ),
    const _RosterFighter(
      name: 'Jack Della Maddalena',
      record: '17-2',
      weight: 'Welterweight',
      style: 'Striker',
      rating: 91,
      trend: 1,
    ),
    const _RosterFighter(
      name: 'Tyson Pedro',
      record: '10-4',
      weight: 'Light Heavyweight',
      style: 'MMA',
      rating: 84,
      trend: -1,
    ),
    const _RosterFighter(
      name: 'Casey O\'Neill',
      record: '10-2',
      weight: 'Flyweight',
      style: 'Grappler',
      rating: 88,
      trend: 1,
    ),
    const _RosterFighter(
      name: 'Jimmy Crute',
      record: '14-4',
      weight: 'Light Heavyweight',
      style: 'MMA',
      rating: 85,
      trend: 0,
    ),
  ];

  // Show builder — fight card slots
  final _fightCard = <_FightSlot>[
    const _FightSlot(
      label: 'MAIN EVENT',
      fighterA: 'Marcus Torres',
      fighterB: 'Elijah Okafor',
      rounds: 5,
      isTitle: true,
    ),
    const _FightSlot(
      label: 'CO-MAIN',
      fighterA: 'Tyler Reid',
      fighterB: 'Nathan Cross',
      rounds: 3,
      isTitle: false,
    ),
    const _FightSlot(
      label: 'FEATURED',
      fighterA: 'Jack Della Maddalena',
      fighterB: 'Mako Tua',
      rounds: 3,
      isTitle: false,
    ),
    const _FightSlot(
      label: 'UNDERCARD',
      fighterA: 'Tyson Pedro',
      fighterB: 'Jimmy Crute',
      rounds: 3,
      isTitle: false,
    ),
    const _FightSlot(
      label: 'PRELIM',
      fighterA: 'Tama Rawiri',
      fighterB: 'Casey O\'Neill',
      rounds: 3,
      isTitle: false,
    ),
  ];

  // Promotions feed (Bellator, UFC, PFL, etc.)
  static const _promoFeed = <_PromotionItem>[
    _PromotionItem(
      org: 'BELLATOR',
      title: 'Timur Karimov defends Lightweight Title — 19-0!',
      source: 'BellatorMMA',
      time: '2 hours ago',
      imageAsset: ImageAssets.ufcPlaceholder,
      icon: Icons.sports_mma,
      color: _kMagenta,
    ),
    _PromotionItem(
      org: 'UFC',
      title: 'UFC 312 — 5 title fights on one card. History in the making.',
      source: '@UFC',
      time: '4 hours ago',
      imageAsset: ImageAssets.fightPlaceholder,
      icon: Icons.local_fire_department,
      color: _kRed,
    ),
    _PromotionItem(
      org: 'PFL',
      title: 'PFL Champions vs Bellator Champions super fight card confirmed',
      source: '@PFLmma',
      time: '6 hours ago',
      imageAsset: ImageAssets.bgAction,
      icon: Icons.emoji_events,
      color: _kGold,
    ),
    _PromotionItem(
      org: 'GLORY',
      title: 'Kickboxing Grand Prix Bracket Revealed for Year-End Event',
      source: 'GLORY Staff',
      time: '8 hours ago',
      imageAsset: ImageAssets.kickboxingPlaceholder,
      icon: Icons.flash_on,
      color: _kOrange,
    ),
    _PromotionItem(
      org: 'ONE',
      title: 'ONE Championship signs 3 new Muay Thai world champions',
      source: '@ONEChampionship',
      time: '12 hours ago',
      imageAsset: ImageAssets.muayThaiPlaceholder,
      icon: Icons.public,
      color: _kCyan,
    ),
    _PromotionItem(
      org: 'BKFC',
      title:
          'Bare Knuckle FC announces London card — 15K tickets sold in 1 hour',
      source: '@BKFC',
      time: '1 day ago',
      imageAsset: ImageAssets.bkfcPlaceholder,
      icon: Icons.front_hand,
      color: _kGreen,
    ),
  ];

  // Social metrics
  static const _socialMetrics = <_SocialMetric>[
    _SocialMetric(
      platform: 'Instagram',
      followers: '24.8K',
      reach: '142K',
      engagement: '4.2%',
      icon: Icons.camera_alt,
      color: Color(0xFFE1306C),
    ),
    _SocialMetric(
      platform: 'TikTok',
      followers: '18.3K',
      reach: '890K',
      engagement: '8.7%',
      icon: Icons.music_video,
      color: Color(0xFF00F2EA),
    ),
    _SocialMetric(
      platform: 'X / Twitter',
      followers: '12.1K',
      reach: '67K',
      engagement: '2.1%',
      icon: Icons.share,
      color: Color(0xFF1DA1F2),
    ),
    _SocialMetric(
      platform: 'Facebook',
      followers: '31.5K',
      reach: '210K',
      engagement: '3.5%',
      icon: Icons.facebook,
      color: Color(0xFF1877F2),
    ),
    _SocialMetric(
      platform: 'YouTube',
      followers: '8.9K',
      reach: '340K',
      engagement: '6.1%',
      icon: Icons.play_circle,
      color: Color(0xFFFF0000),
    ),
  ];

  final _aiSuggestions = const [
    'Your next event is 12 days away — launch ticket promo NOW for 20% more sales.',
    'Kai Tanaka vs Marcus Williams is trending at 94% hype — feature it in all ads.',
    'Friday night events outsell Saturday by 15% in your region. Consider rescheduling.',
    'Video highlights get 3x more engagement. Upload last fight`s best KO clips.',
    'Offer early-bird 2-for-1 tickets — promoters who do this see 40% faster sellouts.',
    'Your Instagram engagement dropped 12% this week. Post behind-the-scenes training content.',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_depsReady) return;
    _service = context.read<PromoterService>();
    _newsService = FightNewsService();
    _eventService = context.read<EventService>();
    _scannerEngine = ContentScannerEngine();
    _refresh();
    // Load promoter's referral code for UTM link generation.
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      ReferralPointsService().getUserPoints(uid).then((summary) {
        if (mounted) setState(() => _referralCode = summary.referralCode);
      });
    }
    _depsReady = true;
  }

  void _refresh() {
    setState(() {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      _promotionsFuture = _service.getPromotions(uid);
      _statsFuture = _service.getDashboardStats(uid);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          _buildAppBar(),
          _buildCommandStats(),
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedTabBar(
              tabBar: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                indicatorColor: _kMagenta,
                indicatorWeight: 3,
                labelColor: _kMagenta,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.4),
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'OVERVIEW'),
                  Tab(text: 'FIGHT CARD'),
                  Tab(text: 'MATCHMAKER'),
                  Tab(text: 'ANALYTICS'),
                  Tab(text: 'MARKETING'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildOverviewTab(),
            _buildFightCardTab(),
            _buildMatchmakerTab(),
            _buildAnalyticsTab(),
            _buildMarketingTab(),
          ],
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _kBg.withValues(alpha: 0.95),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.canPop() ? context.pop() : null,
      ),
      title: Row(
        children: [
          Image.asset(
            AppLogos.icon,
            width: 26,
            height: 26,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.sports_mma, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 10),
          const Text(
            'PROMOTER HQ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kMagenta, Color(0xFFAB47BC)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No new notifications — check back after your next event',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          onPressed: _refresh,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Command Stats Bar ────────────────────────────────────────────────
  SliverToBoxAdapter _buildCommandStats() {
    return SliverToBoxAdapter(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (ctx, snap) {
          final stats =
              snap.data ??
              {
                'totalImpressions': 12500,
                'activeCampaigns': 3,
                'ticketSales': 450,
                'revenue': 12500.00,
              };
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A0A30), Color(0xFF0C1226)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kMagenta.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        context.push(
                          '${rc.RouteConstants.financePromoterById.replaceFirst(':id', uid)}',
                        );
                      }
                    },
                    child: _MiniStat(
                      label: 'REVENUE',
                      value: '\$${_formatNum(stats['revenue'])}',
                      icon: Icons.attach_money,
                      color: _kGreen,
                    ),
                  ),
                ),
                _divider(),
                _MiniStat(
                  label: 'TICKETS',
                  value: '${stats['ticketSales'] ?? 450}',
                  icon: Icons.confirmation_number,
                  color: _kCyan,
                ),
                _divider(),
                _MiniStat(
                  label: 'REACH',
                  value: _formatNum(stats['totalImpressions']),
                  icon: Icons.visibility,
                  color: _kOrange,
                ),
                _divider(),
                _MiniStat(
                  label: 'ADS',
                  value: '${stats['activeCampaigns'] ?? 3}',
                  icon: Icons.campaign,
                  color: _kMagenta,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 36,
    color: Colors.white.withValues(alpha: 0.06),
  );

  String _formatNum(dynamic n) {
    if (n == null) return '0';
    final d = (n is num) ? n.toDouble() : double.tryParse(n.toString()) ?? 0;
    if (d >= 1000000) return '${(d / 1000000).toStringAsFixed(1)}M';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(1)}K';
    return d.toStringAsFixed(0);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 1 — OVERVIEW
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // AI Suggestions (revamped)
        const _SectionHeader(
          title: 'AI FIGHT ADVISOR',
          icon: Icons.psychology,
          color: _kCyan,
        ),
        const SizedBox(height: 8),
        _buildAIAdvisor(),
        const SizedBox(height: 20),

        // Revenue mini-graph
        const _SectionHeader(
          title: 'REVENUE TREND',
          icon: Icons.trending_up,
          color: _kGreen,
        ),
        const SizedBox(height: 8),
        _buildMiniGraph(_revenueData, _kGreen, prefix: '\$'),
        const SizedBox(height: 20),

        // DFC Ecosystem Hub
        const _SectionHeader(
          title: 'DFC ECOSYSTEM',
          icon: Icons.hub,
          color: _kMagenta,
        ),
        const SizedBox(height: 8),
        EcosystemHub(
          centerLabel: 'PROMOTER',
          centerIcon: Icons.hub,
          nodes: [
            EcosystemHubNode(
              label: 'Event\nManager',
              icon: Icons.view_kanban,
              accentColor: _kCyan,
              onTap: () => context.push(rc.RouteConstants.eventManagerPath),
            ),
            EcosystemHubNode(
              label: 'PosterBoy',
              icon: Icons.auto_awesome,
              accentColor: _kMagenta,
              onTap: () => context.push('/creative-hub'),
            ),
            EcosystemHubNode(
              label: 'Events',
              icon: Icons.event,
              accentColor: _kGreen,
              onTap: () => context.push(rc.RouteConstants.eventsPath),
            ),
            EcosystemHubNode(
              label: 'Marketing',
              icon: Icons.campaign,
              accentColor: _kOrange,
              onTap: () => context.push(rc.RouteConstants.marketingHQPath),
            ),
            EcosystemHubNode(
              label: 'Social\nLinks',
              icon: Icons.share,
              accentColor: _kCyan,
              onTap: () => context.push(rc.RouteConstants.socialConnectorsPath),
            ),
            EcosystemHubNode(
              label: 'Ads\nSpotlight',
              icon: Icons.trending_up,
              accentColor: _kMagenta,
              onTap: () => context.push(rc.RouteConstants.adsSpotlightPath),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Promotions Feed (Bellator, UFC, PFL, etc.)
        const _SectionHeader(
          title: 'FIGHT WORLD FEED',
          icon: Icons.rss_feed,
          color: _kOrange,
        ),
        const SizedBox(height: 8),
        ..._promoFeed.map((p) => _PromotionFeedCard(item: p)),
        const SizedBox(height: 20),

        // Quick Tools
        const _SectionHeader(
          title: 'QUICK TOOLS',
          icon: Icons.build,
          color: _kGold,
        ),
        const SizedBox(height: 8),
        _buildQuickToolsGrid(),
        const SizedBox(height: 20),

        // Tutorial
        const InlineVideoCard(
          assetPath: 'assets/videos/ipad_tutorial.mp4',
          title: 'How to Run a Show',
          subtitle: 'Event tools walkthrough — venues, cards, weigh-ins',
          icon: Icons.live_tv,
          accentColor: _kGold,
          height: 210,
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildAIAdvisor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kCyan.withValues(alpha: 0.08), _kPanel],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: _aiSuggestions
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: _kCyan.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Mini Graph ───────────────────────────────────────────────────────
  Widget _buildMiniGraph(List<double> data, Color color, {String prefix = ''}) {
    final maxVal = data.reduce(math.max);
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Graph
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, box) {
                final barW =
                    (box.maxWidth - (data.length - 1) * 4) / data.length;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(data.length, (i) {
                    final pct = maxVal > 0 ? data[i] / maxVal : 0.0;
                    final isLast = i == data.length - 1;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: i < data.length - 1 ? 4 : 0,
                      ),
                      child: SizedBox(
                        width: barW,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isLast)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '$prefix${_formatNum(data[i])}',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            Flexible(
                              child: FractionallySizedBox(
                                heightFactor: pct.clamp(0.05, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isLast
                                        ? color
                                        : color.withValues(alpha: 0.3),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          // Month labels
          Row(
            children: List.generate(data.length, (i) {
              return Expanded(
                child: Text(
                  _months[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 9,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToolsGrid() {
    final tools = [
      _QuickTool(
        'Create Event',
        Icons.add_circle,
        _kGreen,
        () => context.push(rc.RouteConstants.eventManagerPath),
      ),
      _QuickTool(
        'PosterBoy',
        Icons.auto_awesome,
        _kMagenta,
        () => context.push('/creative-hub'),
      ),
      _QuickTool(
        'New Campaign',
        Icons.campaign,
        _kCyan,
        () => context.push('/promoter/create-campaign'),
      ),
      _QuickTool('Sell Tickets', Icons.confirmation_number, _kOrange, () {}),
      _QuickTool('Weigh-In', Icons.monitor_weight, _kGold, () {}),
      _QuickTool('Live Stream', Icons.live_tv, _kRed, () {}),
      _QuickTool(
        'Fighter DB',
        Icons.people,
        _kCyan,
        () => context.push(rc.RouteConstants.fighterDatabankPath),
      ),
      _QuickTool('Sponsors', Icons.handshake, _kGreen, () {}),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: tools.length,
      itemBuilder: (ctx, i) {
        final t = tools[i];
        return GestureDetector(
          onTap: t.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: t.color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.color.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(t.icon, color: t.color, size: 26),
                const SizedBox(height: 6),
                Text(
                  t.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 2 — FIGHT CARD BUILDER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildFightCardTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Event header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kMagenta.withValues(alpha: 0.12), _kPanel],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kMagenta.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.event, color: _kMagenta, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'DFC FIGHT NIGHT 12',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'MAR 8, 2026',
                      style: TextStyle(
                        color: _kGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Sydney Convention Centre  |  Doors 6PM  |  10 Bouts',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Fight card slots
        ..._fightCard.asMap().entries.map(
          (e) => _FightCardSlot(slot: e.value, index: e.key),
        ),

        const SizedBox(height: 16),
        // Add fight button
        GestureDetector(
          onTap: () {
            context.push('/promoter-template');
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: _kMagenta.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  color: _kMagenta.withValues(alpha: 0.6),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'ADD FIGHT TO CARD',
                  style: TextStyle(
                    color: _kMagenta.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        // Ticket projections
        const _SectionHeader(
          title: 'TICKET PROJECTIONS',
          icon: Icons.confirmation_number,
          color: _kCyan,
        ),
        const SizedBox(height: 8),
        _buildMiniGraph(_ticketData, _kCyan),
        const SizedBox(height: 80),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 3 — MATCHMAKER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildMatchmakerTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const _SectionHeader(
          title: 'AI MATCHMAKER',
          icon: Icons.compare_arrows,
          color: _kGold,
        ),
        const SizedBox(height: 8),
        Text(
          'Select two fighters to generate a matchup analysis. The AI evaluates fairness, hype potential, and fan interest.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),

        // Fighter grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _roster.length,
          itemBuilder: (ctx, i) {
            final f = _roster[i];
            final isA = _selectedFighterA == i;
            final isB = _selectedFighterB == i;
            final selected = isA || isB;
            return GestureDetector(
              onTap: () {
                if (f.isSuspended) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${f.name} is medically suspended: ${f.suspensionReason}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: _kRed,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                setState(() {
                  if (_selectedFighterA == i) {
                    _selectedFighterA = null;
                    return;
                  }
                  if (_selectedFighterB == i) {
                    _selectedFighterB = null;
                    return;
                  }
                  if (_selectedFighterA == null) {
                    _selectedFighterA = i;
                  } else if (_selectedFighterB == null) {
                    _selectedFighterB = i;
                  } else {
                    _selectedFighterA = i;
                    _selectedFighterB = null;
                  }
                });
              },
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isA ? _kCyan : _kMagenta).withValues(alpha: 0.12)
                          : _kPanel,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? (isA ? _kCyan : _kMagenta).withValues(alpha: 0.5)
                            : _kBorder,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            if (selected)
                              Container(
                                width: 18,
                                height: 18,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: isA ? _kCyan : _kMagenta,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    isA ? 'A' : 'B',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                f.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${f.record}  •  ${f.weight}  •  ⭐${f.rating}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (f.isSuspended)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  if (f.isSuspended)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _kRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SUSPENDED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Matchup analysis
        if (_selectedFighterA != null && _selectedFighterB != null)
          _buildMatchupAnalysis(
            _roster[_selectedFighterA!],
            _roster[_selectedFighterB!],
          ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildMatchupAnalysis(_RosterFighter a, _RosterFighter b) {
    final fairness = 100 - (a.rating - b.rating).abs();
    final hype = ((a.rating + b.rating) / 2).round();
    final Color fairColor = fairness >= 90
        ? _kGreen
        : fairness >= 75
        ? _kOrange
        : _kRed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kCyan.withValues(alpha: 0.05),
            _kMagenta.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Text(
            'MATCHUP ANALYSIS',
            style: TextStyle(
              color: _kGold,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // VS Header
          Row(
            children: [
              Expanded(
                child: _FighterSide(
                  fighter: a,
                  color: _kCyan,
                  align: CrossAxisAlignment.end,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: _kGold.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Expanded(
                child: _FighterSide(
                  fighter: b,
                  color: _kMagenta,
                  align: CrossAxisAlignment.start,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bars
          _AnalysisBar(label: 'FAIRNESS', value: fairness, color: fairColor),
          _AnalysisBar(label: 'HYPE SCORE', value: hype, color: _kMagenta),
          _AnalysisBar(
            label: 'FAN INTEREST',
            value: math.min(hype + 5, 100),
            color: _kCyan,
          ),
          _AnalysisBar(
            label: 'PPV POTENTIAL',
            value: math.min(fairness + hype ~/ 2, 100),
            color: _kGold,
          ),
          const SizedBox(height: 12),
          // Verdict
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fairColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: fairColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  fairness >= 90
                      ? '✅ EXCELLENT MATCHUP'
                      : fairness >= 75
                      ? '⚠️ COMPETITIVE MATCHUP'
                      : '❌ MISMATCH WARNING',
                  style: TextStyle(
                    color: fairColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fairness >= 90
                      ? 'This is a near-perfect matchup. Both fighters are evenly rated and will deliver a competitive, sellable fight.'
                      : fairness >= 75
                      ? 'Decent matchup. Some rating gap but still competitive. Fans will tune in.'
                      : 'Significant skill gap detected. Consider adjusting the card for fighter safety and fan satisfaction.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 4 — ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const _SectionHeader(
          title: 'REVENUE (12 MONTHS)',
          icon: Icons.attach_money,
          color: _kGreen,
        ),
        const SizedBox(height: 8),
        _buildMiniGraph(_revenueData, _kGreen, prefix: '\$'),
        const SizedBox(height: 20),

        const _SectionHeader(
          title: 'TICKET SALES',
          icon: Icons.confirmation_number,
          color: _kCyan,
        ),
        const SizedBox(height: 8),
        _buildMiniGraph(_ticketData, _kCyan),
        const SizedBox(height: 20),

        // KPI Cards
        const _SectionHeader(
          title: 'KEY METRICS',
          icon: Icons.dashboard,
          color: _kOrange,
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: const [
            _KPICard(
              title: 'Avg Ticket Price',
              value: '\$85',
              change: '+12%',
              up: true,
              color: _kGreen,
            ),
            _KPICard(
              title: 'Sellout Rate',
              value: '78%',
              change: '+5%',
              up: true,
              color: _kCyan,
            ),
            _KPICard(
              title: 'Cost Per Attendee',
              value: '\$14.20',
              change: '-8%',
              up: true,
              color: _kOrange,
            ),
            _KPICard(
              title: 'Return on Ad Spend',
              value: '3.4x',
              change: '+0.6x',
              up: true,
              color: _kMagenta,
            ),
            _KPICard(
              title: 'Social Impressions',
              value: '1.2M',
              change: '+34%',
              up: true,
              color: _kGold,
            ),
            _KPICard(
              title: 'Email Open Rate',
              value: '42%',
              change: '-2%',
              up: false,
              color: _kRed,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Social metrics
        const _SectionHeader(
          title: 'SOCIAL REACH',
          icon: Icons.share,
          color: _kMagenta,
        ),
        const SizedBox(height: 8),
        ..._socialMetrics.map((m) => _SocialReachRow(metric: m)),

        const SizedBox(height: 80),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 5 — MARKETING
  // ═══════════════════════════════════════════════════════════════════════

  // ── UTM Referral Share ─────────────────────────────────────────────────

  Widget _buildReferralSharePanel() {
    final code = _referralCode.isEmpty ? '...' : _referralCode;
    final storeLink = _referralCode.isEmpty
        ? ''
        : _referralLinkService.generateStoreLink(refCode: _referralCode);

    return Container(
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _kMagenta.withValues(alpha: 0.45),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kMagenta.withValues(alpha: 0.08), _kPanel],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.link, color: _kMagenta, size: 18),
              const SizedBox(width: 8),
              const Text(
                'REFERRAL LINKS',
                style: TextStyle(
                  color: _kMagenta,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kMagenta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    color: _kMagenta,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Share UTM links that track clicks & award you 25 pts per share.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),

          // Store link row
          if (storeLink.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      storeLink,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _copyLink(storeLink),
                    child: const Icon(Icons.copy, color: _kCyan, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ShareLinkButton(
                  label: 'SHARE STORE',
                  icon: Icons.storefront,
                  color: _kMagenta,
                  onTap: _referralCode.isEmpty ? null : _showShareSheet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareLinkButton(
                  label: 'SHARE EVENT',
                  icon: Icons.local_fire_department,
                  color: _kCyan,
                  onTap: _referralCode.isEmpty
                      ? null
                      : () => _showShareSheet(eventId: 'dfc-fight-night'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyLink(String url) {
    Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showShareSheet({String? eventId}) {
    final analytics = context.read<AnalyticsService>();
    final url = eventId != null
        ? _referralLinkService.generateEventLink(
            eventId: eventId,
            refCode: _referralCode,
          )
        : _referralLinkService.generateStoreLink(refCode: _referralCode);

    showModalBottomSheet(
      context: context,
      backgroundColor: _kPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ShareBottomSheet(
        url: url,
        refCode: _referralCode,
        analytics: analytics,
        referralLinkService: _referralLinkService,
        eventId: eventId,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  Widget _buildMarketingTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // DFC Octane Promo Engine Entry
        GestureDetector(
          onTap: () => context.push('/creative-hub'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kMagenta.withValues(alpha: 0.2), _kPanel],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kMagenta.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.movie_creation, color: _kMagenta, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DFC OCTANE VIDEO ENGINE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create 15s cinematic promos from 6 images.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _kMagenta),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // UTM Referral Share Panel
        _buildReferralSharePanel(),
        const SizedBox(height: 20),

        // Active Campaigns
        _SectionHeader(
          title: 'ACTIVE CAMPAIGNS',
          icon: Icons.campaign,
          color: _kMagenta,
          trailing: GestureDetector(
            onTap: () => context
                .push('/promoter/create-campaign')
                .then((_) => _refresh()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kMagenta.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '+ NEW',
                style: TextStyle(
                  color: _kMagenta,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildCampaignList(),
        const SizedBox(height: 20),

        // Scanned content feed
        const _SectionHeader(
          title: 'LIVE FIGHT CONTENT',
          icon: Icons.rss_feed,
          color: _kOrange,
        ),
        const SizedBox(height: 8),
        _buildScannedContentFeed(),
        const SizedBox(height: 20),

        // Trending news
        const _SectionHeader(
          title: 'TRENDING NEWS',
          icon: Icons.newspaper,
          color: _kCyan,
        ),
        const SizedBox(height: 8),
        _buildFightNewsFeed(),
        const SizedBox(height: 20),

        // Upcoming cross-promote events
        const _SectionHeader(
          title: 'CROSS-PROMOTE EVENTS',
          icon: Icons.event,
          color: _kGreen,
        ),
        const SizedBox(height: 8),
        _buildUpcomingEvents(),

        const SizedBox(height: 80),
      ],
    );
  }

  // ── Existing data builders (kept from original) ──────────────────────
  Widget _buildCampaignList() {
    return FutureBuilder<List<PromotionModel>>(
      future: _promotionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'No Active Campaigns',
            'Launch a promotion to reach more fighters and fans.',
          );
        }
        final allowedKeywords = [
          'fightgym',
          'mma',
          'fighting',
          'fight',
          'combat gym',
          'boxing gym',
          'boxing',
          'kickboxing',
          'martial arts',
          'self-defense',
          'self defence',
          'wrestling',
        ];
        final allowedTypes = [PromotionType.gymPromo, PromotionType.eventBoost];
        final filtered = snapshot.data!.where((promo) {
          final title = promo.title.toLowerCase();
          final desc = promo.description.toLowerCase();
          final hasKw =
              allowedKeywords.any(title.contains) ||
              allowedKeywords.any(desc.contains);
          return allowedTypes.contains(promo.type) && hasKw;
        }).toList();
        if (filtered.isEmpty) {
          return _buildEmptyState(
            'No Active Campaigns',
            'Launch a promotion to reach more fighters and fans.',
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (context, index) =>
              PromotionCard(promotion: filtered[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_graph,
            size: 38,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedContentFeed() {
    return FutureBuilder<List<ScannedContent>>(
      future: Future.delayed(
        const Duration(milliseconds: 100),
        () => Future.value(_scannerEngine.getLatest(limit: 6)),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final content = snapshot.data ?? [];
        if (content.isEmpty) return const SizedBox.shrink();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: content.length,
          itemBuilder: (context, index) {
            final item = content[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kPanel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item.videoUrl != null
                      ? _kOrange.withValues(alpha: 0.2)
                      : _kBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(
                            item.category,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getCategoryLabel(item.category),
                          style: TextStyle(
                            color: _getCategoryColor(item.category),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.sportLabel,
                          style: const TextStyle(
                            color: _kGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.sourceName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 9,
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
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getCategoryColor(ContentCategory cat) {
    switch (cat) {
      case ContentCategory.breakingNews:
        return _kOrange;
      case ContentCategory.fightResult:
      case ContentCategory.fightAnnouncement:
        return _kMagenta;
      case ContentCategory.highlight:
      case ContentCategory.trainingClip:
        return _kCyan;
      case ContentCategory.eventPromo:
        return _kGreen;
      case ContentCategory.fighterSpotlight:
        return _kGold;
      default:
        return Colors.white38;
    }
  }

  String _getCategoryLabel(ContentCategory cat) {
    switch (cat) {
      case ContentCategory.breakingNews:
        return 'BREAKING';
      case ContentCategory.fightResult:
        return 'RESULT';
      case ContentCategory.fightAnnouncement:
        return 'ANNOUNCE';
      case ContentCategory.highlight:
        return 'HIGHLIGHT';
      case ContentCategory.trainingClip:
        return 'TRAINING';
      case ContentCategory.eventPromo:
        return 'EVENT';
      case ContentCategory.fighterSpotlight:
        return 'SPOTLIGHT';
      case ContentCategory.interview:
        return 'INTERVIEW';
      case ContentCategory.analysis:
        return 'ANALYSIS';
      default:
        return 'NEWS';
    }
  }

  Widget _buildFightNewsFeed() {
    return FutureBuilder<List<FightNewsArticle>>(
      future: Future.value(_newsService.cachedNews.take(4).toList()),
      builder: (context, snapshot) {
        final news =
            snapshot.data ?? _newsService.getFeatured().take(4).toList();
        if (news.isEmpty) return const SizedBox.shrink();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: news.length,
          itemBuilder: (context, index) {
            final article = news[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kPanel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _kMagenta.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          article.sourceDisplay,
                          style: const TextStyle(
                            color: _kMagenta,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        article.timeAgo,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUpcomingEvents() {
    return FutureBuilder<List<EventModel>>(
      future: _eventService.getUpcomingEvents(limit: 4),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        if (events.isEmpty) return const SizedBox.shrink();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final days = event.eventDate.difference(DateTime.now()).inDays;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kPanel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (event.sportType ?? 'Event').replaceAll('_', ' '),
                          style: const TextStyle(
                            color: _kGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        days == 0
                            ? 'TODAY'
                            : days == 1
                            ? 'TOMORROW'
                            : '${days}d away',
                        style: TextStyle(
                          color: days <= 3 ? _kOrange : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.fightIds.length} fights',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        event.fullLocation,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class _RosterFighter {
  final String name, record, weight, style;
  final int rating;
  final int trend; // 1=up, 0=same, -1=down
  final bool isSuspended;
  final String? suspensionReason;
  const _RosterFighter({
    required this.name,
    required this.record,
    required this.weight,
    required this.style,
    required this.rating,
    required this.trend,
    this.isSuspended = false,
    this.suspensionReason,
  });
}

class _FightSlot {
  final String label, fighterA, fighterB;
  final int rounds;
  final bool isTitle;
  const _FightSlot({
    required this.label,
    required this.fighterA,
    required this.fighterB,
    required this.rounds,
    required this.isTitle,
  });
}

class _PromotionItem {
  final String org, title, source, time;
  final String? imageAsset;
  final IconData icon;
  final Color color;
  const _PromotionItem({
    required this.org,
    required this.title,
    required this.source,
    required this.time,
    this.imageAsset,
    required this.icon,
    required this.color,
  });
}

class _SocialMetric {
  final String platform, followers, reach, engagement;
  final IconData icon;
  final Color color;
  const _SocialMetric({
    required this.platform,
    required this.followers,
    required this.reach,
    required this.engagement,
    required this.icon,
    required this.color,
  });
}

class _QuickTool {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickTool(this.label, this.icon, this.color, this.onTap);
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

// ── Share Link Button ────────────────────────────────────────────────────

class _ShareLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ShareLinkButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap != null ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Share Bottom Sheet ───────────────────────────────────────────────────

class _ShareBottomSheet extends StatelessWidget {
  final String url;
  final String refCode;
  final AnalyticsService analytics;
  final ReferralLinkService referralLinkService;
  final String? eventId;

  const _ShareBottomSheet({
    required this.url,
    required this.refCode,
    required this.analytics,
    required this.referralLinkService,
    this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2744),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Row(
              children: [
                Icon(Icons.link, color: _kMagenta, size: 18),
                SizedBox(width: 8),
                Text(
                  'YOUR UTM REFERRAL LINK',
                  style: TextStyle(
                    color: _kMagenta,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Share this link and earn 25 pts each time a fan clicks through.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),

            // Referral code badge
            Row(
              children: [
                const Icon(Icons.badge, color: _kGold, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Your code: ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _kGold.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    refCode,
                    style: const TextStyle(
                      color: _kGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Link display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF060A14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1A2744)),
              ),
              child: SelectableText(
                url,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Copy button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kMagenta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text(
                  'COPY LINK',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                onPressed: () async {
                  await referralLinkService.copyAndTrack(
                    context: context,
                    url: url,
                    refCode: refCode,
                    analytics: analytics,
                    eventId: eventId,
                  );
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? trailing;
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _PromotionFeedCard extends StatelessWidget {
  final _PromotionItem item;
  const _PromotionFeedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1226),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Promotion poster image
          if (item.imageAsset != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.asset(
                item.imageAsset!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 12, color: item.color),
                    const SizedBox(width: 4),
                    Text(
                      item.org,
                      style: TextStyle(
                        color: item.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                item.time,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.source,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _FightCardSlot extends StatelessWidget {
  final _FightSlot slot;
  final int index;
  const _FightCardSlot({required this.slot, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1226),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: slot.isTitle
              ? _kGold.withValues(alpha: 0.3)
              : const Color(0xFF1A2744),
          width: slot.isTitle ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: slot.isTitle
                      ? _kGold.withValues(alpha: 0.15)
                      : _kMagenta.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  slot.label,
                  style: TextStyle(
                    color: slot.isTitle ? _kGold : _kMagenta,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              if (slot.isTitle)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TITLE FIGHT',
                    style: TextStyle(
                      color: _kGold,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '${slot.rounds}R',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  slot.fighterA,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: _kMagenta.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  slot.fighterB,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FighterSide extends StatelessWidget {
  final _RosterFighter fighter;
  final Color color;
  final CrossAxisAlignment align;
  const _FighterSide({
    required this.fighter,
    required this.color,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.person, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          fighter.name.split(' ').last,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          fighter.record,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
        Text(
          fighter.weight,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _AnalysisBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _AnalysisBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '$value%',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title, value, change;
  final bool up;
  final Color color;
  const _KPICard({
    required this.title,
    required this.value,
    required this.change,
    required this.up,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1226),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                up ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: up ? _kGreen : _kRed,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  color: up ? _kGreen : _kRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialReachRow extends StatelessWidget {
  final _SocialMetric metric;
  const _SocialReachRow({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1226),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: metric.color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(metric.icon, color: metric.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.platform,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${metric.followers} followers',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                metric.reach,
                style: TextStyle(
                  color: metric.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'reach',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                metric.engagement,
                style: const TextStyle(
                  color: _kGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'engage',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pinned Tab Bar Delegate ─────────────────────────────────────────────
class _PinnedTabBar extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _PinnedTabBar({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(color: _kBg.withValues(alpha: 0.9), child: tabBar),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBar old) => false;
}
