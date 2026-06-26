import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/fight_news_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ACTION ZONE — Fight News, Show Cards, Live Action Feed
/// The pulse of combat sports — breaking news, upcoming cards, results
/// ═══════════════════════════════════════════════════════════════════════════
class ActionZoneScreen extends StatefulWidget {
  const ActionZoneScreen({super.key});

  @override
  State<ActionZoneScreen> createState() => _ActionZoneScreenState();
}

class _ActionZoneScreenState extends State<ActionZoneScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseCtrl;
  late FightNewsService _newsService;
  Timer? _tickerTimer;
  List<FightNewsArticle> _allNews = [];
  String _activeFilter = 'All';
  bool _isLoading = true;
  bool _depsInitialized = false;
  int _tickerIndex = 0;

  static const _filters = [
    'All',
    'UFC',
    'Boxing',
    'MMA',
    'Muay Thai',
    'Kickboxing',
    'BKFC',
    'Run It',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      _depsInitialized = true;
      _newsService = context.read<FightNewsService>();
      _loadNews();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _tickerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final breakingCount = _allNews.where((n) => n.isBreaking).length;
      if (breakingCount <= 1) return;
      setState(() {
        _tickerIndex = (_tickerIndex + 1) % breakingCount;
      });
    });
  }

  Future<void> _loadNews() async {
    final news = await _newsService.refreshNews();
    if (mounted) {
      setState(() {
        _allNews = news;
        _isLoading = false;
      });
    }
  }

  List<FightNewsArticle> get _filteredNews {
    if (_activeFilter == 'All') return _allNews;
    return _allNews
        .where(
          (n) => n.sourceDisplay.toUpperCase() == _activeFilter.toUpperCase(),
        )
        .toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseCtrl.dispose();
    _tickerTimer?.cancel();
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
            _buildBreakingTicker(),
            _buildFilterChips(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNewsFeed(),
                  _buildShowCards(),
                  _buildLiveAction(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                        alpha: 0.2 + p * 0.15,
                      ),
                      blurRadius: 10 + p * 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 22,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTION ZONE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '${_allNews.length} stories · ${_allNews.where((n) => n.isBreaking).length} breaking',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: DesignTokens.neonCyan),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadNews();
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BREAKING NEWS TICKER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBreakingTicker() {
    final breaking = _allNews.where((n) => n.isBreaking).toList();
    if (breaking.isEmpty) return const SizedBox.shrink();
    final current = breaking[_tickerIndex % breaking.length];

    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: DesignTokens.neonRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DesignTokens.neonRed.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: DesignTokens.neonRed.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
            ),
            child: const Center(
              child: Text(
                'BREAKING',
                style: TextStyle(
                  color: DesignTokens.neonRed,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: Text(
                current.title,
                key: ValueKey(current.title),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FILTER CHIPS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final f = _filters[i];
          final sel = f == _activeFilter;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel
                    ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel
                      ? DesignTokens.neonCyan.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: sel ? DesignTokens.neonCyan : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: DesignTokens.neonRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: DesignTokens.neonRed,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'NEWS FEED'),
          Tab(text: 'SHOW CARDS'),
          Tab(text: 'LIVE ACTION'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1 — NEWS FEED
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNewsFeed() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: DesignTokens.neonCyan),
      );
    }
    final news = _filteredNews;
    if (news.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.newspaper,
              size: 48,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 8),
            Text(
              'No stories for "$_activeFilter"',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: news.length,
      itemBuilder: (context, i) => _buildNewsCard(news[i]),
    );
  }

  Widget _buildNewsCard(FightNewsArticle article) {
    // Color based on category
    final catColor = _categoryColor(article.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            catColor.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: catColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image
          if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DfcNetworkImage(url: article.imageUrl!),
                    // Gradient overlay for readability
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppTheme.primaryBackground.withValues(
                                alpha: 0.85,
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
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.sourceDisplay,
                        style: TextStyle(
                          color: catColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (article.isBreaking) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BREAKING',
                          style: TextStyle(
                            color: DesignTokens.neonRed,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
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
                const SizedBox(height: 8),
                Text(
                  article.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (article.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: article.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 9,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2 — SHOW CARDS (Upcoming fight cards)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildShowCards() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: DesignTokens.neonCyan),
      );
    }

    final news = _filteredNews;
    final Map<String, List<FightNewsArticle>> grouped = {};
    for (final n in news.take(24)) {
      grouped.putIfAbsent(n.sourceDisplay, () => <FightNewsArticle>[]).add(n);
    }
    final groups = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (groups.isNotEmpty) ...[
          _sectionTitle('Live Card Stack'),
          ...groups.take(4).map((entry) {
            final lead = entry.value.first;
            final accent = _categoryColor(lead.category);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stadium, color: accent, size: 15),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${entry.key} ACTION CARD',
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value.length} items',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...entry.value
                      .take(3)
                      .map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '- ${a.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          _sectionTitle('Upcoming Showcase'),
        ] else ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'No live show cards for "$_activeFilter" yet',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
        _showCard(
          'UFC 315',
          'Feb 22, 2026',
          'T-Mobile Arena, Las Vegas',
          [
            _bout(
              'Alex Pereira',
              'Magomed Ankalaev',
              'Light Heavyweight Title',
              true,
            ),
            _bout(
              'Sean O\'Malley',
              'Merab Dvalishvili',
              'Bantamweight Title',
              true,
            ),
            _bout('Paddy Pimblett', 'Nathan Cross', 'Lightweight', false),
            _bout('Bo Nickal', 'Brendan Allen', 'Middleweight', false),
            _bout('Raul Rosas Jr', 'Song Yadong', 'Bantamweight', false),
          ],
          DesignTokens.neonRed,
        ),
        _showCard(
          'PFL Champions vs Bellator',
          'Mar 8, 2026',
          'Madison Square Garden, NY',
          [
            _bout(
              'Patricio Pitbull',
              'Movlid Khaybulaev',
              'Featherweight',
              true,
            ),
            _bout(
              'Larissa Pacheco',
              'Valeria Cruz',
              'Women\'s Featherweight',
              true,
            ),
            _bout('Sadibou Sy', 'Jason Jackson', 'Welterweight', false),
          ],
          const Color(0xFFFFD700),
        ),
        _showCard(
          'ONE Championship 170',
          'Mar 15, 2026',
          'Singapore Indoor Stadium',
          [
            _bout(
              'Apichai PK',
              'Narong',
              'Muay Thai Featherweight Title',
              true,
            ),
            _bout('Stamp Fairtex', 'Angela Lee', 'Atomweight MMA', true),
            _bout('Somsak', 'Whitfield', 'Flyweight Muay Thai', false),
          ],
          DesignTokens.neonCyan,
        ),
        _showCard(
          'Bare Knuckle FC 58',
          'Feb 28, 2026',
          'KnuckleMania IV, Hollywood FL',
          [
            _bout('Mike Perry', 'Luke Rockhold', 'Middleweight', true),
            _bout(
              'Christine Ferea',
              'Bec Rawlings',
              'Women\'s Flyweight',
              false,
            ),
            _bout('Dat Nguyen', 'Isaac Doolittle', 'Lightweight', false),
          ],
          DesignTokens.neonAmber,
        ),
      ],
    );
  }

  Map<String, String> _bout(String a, String b, String weight, bool isMain) {
    return {'a': a, 'b': b, 'weight': weight, 'main': isMain.toString()};
  }

  String _showCardImageUrl(Color accent) {
    if (accent == DesignTokens.neonRed) {
      return ImageAssets.bgHero;
    } else if (accent == DesignTokens.neonCyan) {
      return ImageAssets.bgAction;
    } else if (accent == DesignTokens.neonAmber) {
      return ImageAssets.bgPromo;
    }
    return ImageAssets.bgEvent;
  }

  Widget _showCard(
    String title,
    String date,
    String venue,
    List<Map<String, String>> bouts,
    Color accent,
  ) {
    final bannerUrl = _showCardImageUrl(accent);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    bannerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: accent.withValues(alpha: 0.08),
                      child: Icon(
                        Icons.sports_mma,
                        color: accent.withValues(alpha: 0.3),
                        size: 48,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.primaryBackground.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event, color: accent, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$date  ·  $venue',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Bouts
          ...bouts.map((bout) {
            final isMain = bout['main'] == 'true';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (isMain)
                    Container(
                      width: 3,
                      height: 28,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  if (!isMain) const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                bout['a']!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMain ? 13 : 12,
                                  fontWeight: isMain
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              'VS',
                              style: TextStyle(
                                color: accent.withValues(alpha: 0.5),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                bout['b']!,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMain ? 13 : 12,
                                  fontWeight: isMain
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bout['weight']!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 3 — LIVE ACTION (Results & Highlights)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLiveAction() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: DesignTokens.neonCyan),
      );
    }

    final dynamicItems = _filteredNews.where((n) => n.isBreaking).toList();
    final fallbackItems = _filteredNews;
    final feed = dynamicItems.isNotEmpty ? dynamicItems : fallbackItems;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Live Wire'),
        if (feed.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'No live action updates for "$_activeFilter" right now',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 12,
              ),
            ),
          ),
        ...feed.take(6).map((item) {
          final c = _categoryColor(item.category);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.sourceDisplay}  ·  ${item.timeAgo}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
        _sectionTitle('🔴 Recent Results'),
        _resultCard(
          'Alexander Volkanovski',
          'Ilia Topuria',
          'KO R3 2:45',
          'UFC 314 · Feb 8',
          DesignTokens.neonRed,
        ),
        _resultCard(
          'Artur Beterbiev',
          'Dmitry Bivol',
          'UD 12 Rounds',
          'Crown Jewel · Feb 1',
          DesignTokens.neonAmber,
        ),
        _resultCard(
          'Islam Makhachev',
          'Lance Palmer',
          'Sub R4 3:12',
          'UFC 313 · Jan 18',
          DesignTokens.neonGreen,
        ),
        const SizedBox(height: 16),
        _sectionTitle('⚡ Trending Highlights'),
        _highlightCard(
          'Santos\'s Devastating Left Hook KO',
          '14.2M views · Trending #1',
          Icons.play_circle_filled,
          DesignTokens.neonRed,
        ),
        _highlightCard(
          'O\'Malley Sugar Show Round 1 Finish',
          '8.7M views · Trending #3',
          Icons.play_circle_filled,
          DesignTokens.neonCyan,
        ),
        _highlightCard(
          'ONE Championship: Somsak Elbow Highlight Reel',
          '5.1M views · Trending #5',
          Icons.play_circle_filled,
          DesignTokens.neonAmber,
        ),
        const SizedBox(height: 16),
        _sectionTitle('📊 Power Rankings Update'),
        _rankingRow(1, 'Islam Makhachev', 'P4P King', DesignTokens.neonCyan),
        _rankingRow(2, 'Alex Pereira', 'LHW Champion', DesignTokens.neonRed),
        _rankingRow(
          3,
          'Alexander Volkanovski',
          'FW Champion',
          DesignTokens.neonGreen,
        ),
        _rankingRow(
          4,
          'Jai Opetaia',
          'IBF Cruiserweight',
          DesignTokens.neonAmber,
        ),
        _rankingRow(
          5,
          'Merab Dvalishvili',
          'BW Champion',
          const Color(0xFFFF00FF),
        ),
      ],
    );
  }

  Widget _resultCard(
    String winner,
    String loser,
    String method,
    String event,
    Color c,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Image.asset(
                ImageAssets.bgAction,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.withValues(alpha: 0.12),
                  ),
                  child: Icon(Icons.emoji_events, color: c, size: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$winner ',
                        style: TextStyle(
                          color: c,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: 'def. $loser',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$method  ·  $event',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightCard(String title, String meta, IconData icon, Color c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.withValues(alpha: 0.06), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Image.asset(
                ImageAssets.bgEvent,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: c.withValues(alpha: 0.08),
                  child: Icon(icon, color: c, size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankingRow(int rank, String name, String title, Color c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: c,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _categoryColor(NewsSource cat) {
    switch (cat) {
      case NewsSource.ufc:
        return DesignTokens.neonRed;
      case NewsSource.boxing:
        return DesignTokens.neonAmber;
      case NewsSource.muayThai:
        return DesignTokens.neonCyan;
      case NewsSource.kickboxing:
        return const Color(0xFFFF9500);
      case NewsSource.bareKnuckle:
        return const Color(0xFFFF3366);
      case NewsSource.brawling:
        return const Color(0xFFFF6600);
      case NewsSource.mma:
        return DesignTokens.neonGreen;
      case NewsSource.espn:
        return const Color(0xFFFFD700);
      default:
        return Colors.white54;
    }
  }
}
