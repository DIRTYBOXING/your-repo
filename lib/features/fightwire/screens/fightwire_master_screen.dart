import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/fight_news_feed.dart';
import '../widgets/talk_hub.dart';
import '../../../shared/widgets/ad_components.dart';
import '../../../shared/services/dfc_ai_powerhouse.dart';
import '../../../shared/services/content_scanner_engine.dart';
import '../../../shared/services/promoter_ai_service.dart';
import '../../../shared/services/ai_eso_engine_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/social_media_template_sizes.dart';
import '../../../shared/widgets/dfc_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTWIRE TAB - Promotion Engine & SignalCards
/// Role-aware feeds, urgency levels, lifecycle management
/// ═══════════════════════════════════════════════════════════════════════════
class FightWireMasterScreen extends StatefulWidget {
  const FightWireMasterScreen({super.key});

  @override
  State<FightWireMasterScreen> createState() => _FightWireMasterScreenState();
}

class _FightWireMasterScreenState extends State<FightWireMasterScreen>
    with TickerProviderStateMixin {
  bool get _syntheticEnabled => AppConstants.syntheticContentEnabled;

  late TabController _tabController;
  late PageController _carouselController;
  Timer? _carouselTimer;
  int _carouselIndex = 0;
  String _selectedRole = 'All';
  String _selectedRegion = 'Global';
  String _selectedMissionFilter = 'All';

  // ─── AI Engine Links ───────────────────────────────────────────────────
  late DFCAIPowerhouse _powerhouse;
  late ContentScannerEngine _scanner;
  late PromoterAIService _promoter;
  late AIEsoEngineService _eso;

  bool _enginesBooted = false;
  bool _isLoadingMore = false;
  int _signalPage = 0;
  bool _depsInitialized = false;

  // Live scanner-powered signals
  List<PowerhouseSignal> _liveSignals = [];
  List<KimikInsight> _kimikInsights = [];

  final List<String> _roles = [
    'All',
    'Fighter',
    'Coach',
    'Promoter',
    'Gym',
    'Fan',
  ];
  final List<String> _regions = [
    'Global',
    'North America',
    'Europe',
    'Asia',
    'Australia',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      _depsInitialized = true;
      _powerhouse = context.read<DFCAIPowerhouse>();
      _scanner = context.read<ContentScannerEngine>();
      _promoter = context.read<PromoterAIService>();
      _eso = context.read<AIEsoEngineService>();
      // Defer engine boot to avoid setState-during-build
      WidgetsBinding.instance.addPostFrameCallback((_) => _bootEngines());
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _carouselController = PageController(viewportFraction: 0.92);
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_carouselController.hasClients) return;
      final next = (_carouselIndex + 1) % _dynamicCarouselItems.length;
      _carouselController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Boot the AI Powerhouse — links ESO + Kimik2.5 + Scanner + Promoter
  Future<void> _bootEngines() async {
    if (!_syntheticEnabled) {
      if (mounted) {
        setState(() {
          _enginesBooted = false;
          _liveSignals = [];
          _kimikInsights = [];
        });
      }
      return;
    }
    if (!_powerhouse.initialized) {
      await _powerhouse.bootAllEngines();
    }
    await _powerhouse.educateEngines();
    _liveSignals = _powerhouse.getLiveSignals(limit: 100);
    _kimikInsights = _powerhouse.insights;
    if (mounted) setState(() => _enginesBooted = true);
  }

  /// Load more signals for infinite scroll
  Future<void> _loadMoreSignals() async {
    if (!_syntheticEnabled) {
      return;
    }
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _signalPage++;

    await _scanner.forceRefresh();
    await _promoter.forceGenerate();
    await _powerhouse.educateEngines();

    _liveSignals = _powerhouse.getLiveSignals(limit: 50 + _signalPage * 30);
    _kimikInsights = _powerhouse.insights;

    if (mounted) setState(() => _isLoadingMore = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // ── Header scrolls away ──
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildFilters()),
            SliverToBoxAdapter(child: _buildFightCarousel()),
            // ── Tab bar PINS at top ──
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  child: _buildTabBar(),
                  color: AppTheme.primaryBackground,
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              const FightWireTalkHub(),
              _buildSignalCardList(_allSignals),
              _buildNewsTab(),
              _buildSignalCardList(_eventSignals),
              _buildMarketTab(),
              _buildSignalCardList(_shortNoticeSignals),
              _buildSignalCardList(_opportunitySignals),
              _buildSignalCardList(_gymSignals),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fightwire_fab',
        onPressed: _showCreateSignal,
        backgroundColor: AppTheme.neonCyan,
        child: const Icon(Icons.bolt, color: Colors.black),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonCyan,
                  AppTheme.neonCyan.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.bolt, color: Colors.black, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIGHTWIRE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Powered by Genie AI · Promotional Engine',
                  style: TextStyle(color: AppTheme.neonCyan, fontSize: 11),
                ),
              ],
            ),
          ),
          // Kimik2.5 engine pulse indicator
          if (_enginesBooted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DesignTokens.neonGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: DesignTokens.neonGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.neonGreen.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_scanner.bots.length + _promoter.bots.length} bots',
                    style: const TextStyle(
                      color: DesignTokens.neonGreen,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () => context.push('/notification-settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      dropdownColor: AppTheme.cardBackground,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppTheme.neonCyan,
                      ),
                      items: _roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(
                            role,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedRole = value!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRegion,
                      dropdownColor: AppTheme.cardBackground,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppTheme.neonCyan,
                      ),
                      items: _regions.map((region) {
                        return DropdownMenuItem(
                          value: region,
                          child: Text(
                            region,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedRegion = value!),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMissionChip('All'),
              const SizedBox(width: 8),
              _buildMissionChip('OPS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionChip(String value) {
    final selected = _selectedMissionFilter == value;
    return ChoiceChip(
      selected: selected,
      label: Text(
        value == 'OPS' ? 'OPS Missions' : 'All Signals',
        style: TextStyle(
          color: selected ? Colors.black : Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: AppTheme.cardBackground,
      selectedColor: AppTheme.neonCyan,
      side: BorderSide(
        color: selected
            ? AppTheme.neonCyan.withValues(alpha: 0.8)
            : Colors.white24,
      ),
      onSelected: (_) => setState(() => _selectedMissionFilter = value),
    );
  }

  Widget _buildFightCarousel() {
    final carouselItems = _dynamicCarouselItems;
    return Column(
      children: [
        SizedBox(
          height: 110,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: carouselItems.length,
            onPageChanged: (index) => setState(() => _carouselIndex = index),
            itemBuilder: (context, index) {
              final item = carouselItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _CarouselCard(item: item),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(carouselItems.length, (index) {
            final isActive = _carouselIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 14 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.neonCyan : Colors.white24,
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.neonCyan,
              AppTheme.neonCyan.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: const [
          Tab(text: 'TALK'),
          Tab(text: 'ALL'),
          Tab(text: 'NEWS'),
          Tab(text: 'MARKET'),
          Tab(text: 'EVENTS'),
          Tab(text: 'SHORT NOTICE'),
          Tab(text: 'OPPORTUNITIES'),
          Tab(text: 'GYM'),
        ],
      ),
    );
  }

  Widget _buildSignalCardList(List<SignalCard> signals) {
    // Combine hardcoded + live AI-powered signals
    final liveConverted = _applyMissionFilter(_convertLiveSignals(signals));
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 400) {
          _loadMoreSignals();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount:
            liveConverted.length + 2, // +1 insight header, +1 loading footer
        itemBuilder: (context, index) {
          // First item: Kimik2.5 insight card
          if (index == 0 && _kimikInsights.isNotEmpty) {
            return _buildKimikInsightBanner();
          }
          if (index == 0) return const SizedBox.shrink();

          // Last item: infinite scroll loader
          if (index > liveConverted.length) {
            if (_isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DesignTokens.neonCyan,
                  ),
                ),
              );
            }
            return const SizedBox(height: 80);
          }

          return _buildSignalCard(liveConverted[index - 1]);
        },
      ),
    );
  }

  List<SignalCard> _applyMissionFilter(List<SignalCard> signals) {
    if (_selectedMissionFilter != 'OPS') return signals;
    return signals.where((signal) => signal.category == 'OPS').toList();
  }

  /// Convert live PowerhouseSignals → local SignalCard objects + merge with originals
  List<SignalCard> _convertLiveSignals(List<SignalCard> originals) {
    if (!_enginesBooted) return originals;

    final combined = <SignalCard>[...originals];

    // Add live signals from the AI Powerhouse
    for (final s in _liveSignals.take(40)) {
      combined.add(
        SignalCard(
          title: s.title,
          category: s.category,
          description: s.description,
          location: s.location,
          timeAgo: s.timeAgo,
          icon: _iconFromName(s.iconName),
          urgency: _mapUrgency(s.urgency),
          ctaLabel: s.isBreaking ? 'Read Now' : null,
        ),
      );
    }

    // Sort: critical first, then timestamp
    combined.sort((a, b) => b.urgency.index.compareTo(a.urgency.index));
    return combined;
  }

  IconData _iconFromName(String name) {
    return switch (name) {
      'camera_alt' => Icons.camera_alt,
      'facebook' => Icons.facebook,
      'music_note' => Icons.music_note,
      'play_circle' => Icons.play_circle,
      'tag' => Icons.tag,
      'forum' => Icons.forum,
      'podcasts' => Icons.podcasts,
      'auto_awesome' => Icons.auto_awesome,
      'newspaper' => Icons.newspaper,
      _ => Icons.language,
    };
  }

  SignalUrgency _mapUrgency(SignalPriority p) {
    return switch (p) {
      SignalPriority.critical => SignalUrgency.critical,
      SignalPriority.high => SignalUrgency.high,
      SignalPriority.normal => SignalUrgency.normal,
      SignalPriority.low => SignalUrgency.low,
    };
  }

  /// Kimik2.5 insight banner at top of signal lists
  Widget _buildKimikInsightBanner() {
    final insight = _kimikInsights.isNotEmpty ? _kimikInsights.first : null;
    if (insight == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.08),
            DesignTokens.neonMagenta.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: DesignTokens.neonCyan,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'KIMIK 2.5 INTELLIGENCE',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(insight.confidence * 100).toInt()}%',
                  style: const TextStyle(
                    color: DesignTokens.neonGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            insight.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalCard(SignalCard signal) {
    final isBreaking = signal.urgency == SignalUrgency.critical;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: signal.urgencyColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: signal.urgencyColor,
            width: isBreaking ? 3.5 : 2.5,
          ),
          top: BorderSide(
            color: signal.urgencyColor.withValues(alpha: 0.15),
            width: 0.5,
          ),
          right: BorderSide(
            color: signal.urgencyColor.withValues(alpha: 0.15),
            width: 0.5,
          ),
          bottom: BorderSide(
            color: signal.urgencyColor.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon + badges + time/expiry
            Row(
              children: [
                Icon(signal.icon, color: signal.urgencyColor, size: 16),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: signal.urgencyColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    signal.urgencyLabel,
                    style: TextStyle(
                      color: signal.urgencyColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
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
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    signal.category,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                if (signal.expiresIn != null)
                  _ExpiryTimer(expiresIn: signal.expiresIn!)
                else
                  Text(
                    signal.timeAgo,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Signal image
            if (signal.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  height: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DfcImage(
                        url: signal.imageUrl,
                        width: double.infinity,
                        height: 120,
                      ),
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
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Title
            Text(
              signal.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Description
            Text(
              signal.description,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Footer: location + actions
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white30, size: 12),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    signal.location,
                    style: const TextStyle(color: Colors.white30, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildInlineAction(Icons.info_outline, 'Details'),
                _buildInlineAction(Icons.bookmark_border, 'Save'),
                if (signal.ctaLabel != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: signal.urgencyColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: signal.urgencyColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      signal.ctaLabel!,
                      style: TextStyle(
                        color: signal.urgencyColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineAction(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: () {
          final msg = label == 'Details'
              ? 'Loading signal details...'
              : 'Saved to your watchlist';
          final color = label == 'Details'
              ? const Color(0xFF00E5FF)
              : const Color(0xFF00E676);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    label == 'Details'
                        ? Icons.info_outline
                        : Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(msg),
                ],
              ),
              duration: const Duration(seconds: 1),
              backgroundColor: color.withValues(alpha: 0.9),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Icon(icon, color: Colors.white38, size: 16),
      ),
    );
  }

  /// Build the News tab with FightNewsFeed and ads
  Widget _buildNewsTab() {
    return const CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(child: BreakingNewsTicker()),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: AdCard(
              title: 'FightWire Pro',
              subtitle: 'Real-time alerts & breaking news',
              ctaText: 'Unlock',
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(child: FightNewsFeed(maxItems: 15)),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          sliver: SliverToBoxAdapter(
            child: AdCard(
              size: AdSize.large,
              title: 'Get Fight Intel First',
              subtitle: 'Premium members get breaking news 24 hours early',
              ctaText: 'Go Premium',
              isSponsored: true,
              accent: AppTheme.neonMagenta,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 60)),
      ],
    );
  }

  Widget _buildMarketTab() {
    final events = <_FightEvent>[
      // === AUSTRALIAN SERIES — DFC PPV PIPELINE TO USA ===
      const _FightEvent(
        title: 'IBC 03: Cutler vs Modini',
        promotion: 'International Brawling Championship · via FightPipe',
        mainEvent: 'Jay Cutler vs Luke Modini — LHW Title (5 Rounds)',
        date: 'March 7, 2026',
        location: 'Gold Coast Sports & Leisure Centre, QLD',
        fightCount: 11,
        imageUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
        accentColor: Color(0xFFFF3B30),
        tag: '🔥 PPV · SINGLES AVAIL',
      ),
      const _FightEvent(
        title: 'IBC 03: Hardman vs Tuhu',
        promotion: 'International Brawling Championship · via FightPipe',
        mainEvent: 'Isaac Hardman vs Jonathan Tuhu — IBC Championship',
        date: 'March 7, 2026',
        location: 'Gold Coast Sports & Leisure Centre, QLD',
        fightCount: 11,
        imageUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
        template: SocialMediaTemplateSizes.instagramPostPortrait,
        accentColor: Color(0xFFFF6A00),
        tag: '🥊 BUY SINGLE FIGHT',
      ),
      const _FightEvent(
        title: 'IBC 03: Full Card Replay',
        promotion: 'International Brawling Championship · FightPipe Replay',
        mainEvent: 'Kapua, Loulanting, Stevens, Vaotusa + More',
        date: 'March 7, 2026',
        location: 'Gold Coast Sports & Leisure Centre, QLD',
        fightCount: 11,
        imageUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
        template: SocialMediaTemplateSizes.tiktokVideoStory,
        accentColor: Color(0xFF00E5FF),
        tag: '📺 REPLAY ON FIGHTPIPE',
      ),
      // === DOWN UNDER DOMINO EFFECT — AU→US DISTRIBUTION ===
      const _FightEvent(
        title: 'Ultimate Legends: WBC Silver Australian Title',
        promotion: 'Ultimate Legends Promotions · Founded by John Scida',
        mainEvent:
            'Ultimate Legends presents Elite Ultimate Muay Thai. WBC Silver Australian Title fight. 15+ years of world-class fight promotion backed by DFC.',
        date: 'April 24, 2026',
        location: 'Cranbourne Pavilion, VIC · Streaming to USA',
        fightCount: 12,
        imageUrl: 'assets/dfc_backgrounds/datafightlogo.png',
        accentColor: Color(0xFFFFD740),
        tag: '🏆 AU→US PPV',
      ),
      const _FightEvent(
        title: 'Pacific MMA 10 — Kalgoorlie',
        promotion: 'Pacific MMA · Regional WA fight show returns',
        mainEvent:
            'Pacific MMA\'s 10th event brings local and international talent to the Goldfields',
        date: 'March 29, 2026',
        location: 'Kalgoorlie, WA, Australia',
        fightCount: 10,
        imageUrl: 'assets/dfc_backgrounds/dfc2_image.png',
        template: SocialMediaTemplateSizes.instagramPostPortrait,
        accentColor: Color(0xFF00E5FF),
        tag: '🇦🇺 REGIONAL AU',
      ),
      // === GLOBAL EVENTS — DFC AS THE PIPELINE ===
      const _FightEvent(
        title: 'UFC 313: Santos vs Aliyev',
        promotion: 'UFC · Watch via FightPipe',
        mainEvent: 'Santos vs. Aliyev — Light Heavyweight Title',
        date: 'March 8, 2026',
        location: 'T-Mobile Arena, Las Vegas',
        fightCount: 14,
        imageUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
        accentColor: Color(0xFFFF3366),
        tag: '🔴 PPV LIVE',
      ),
      const _FightEvent(
        title: 'ONE 170: Narong vs Apichai',
        promotion: 'ONE Championship · FightPipe Distribution',
        mainEvent: 'Narong vs. Apichai — Muay Thai Grand Prix',
        date: 'March 21, 2026',
        location: 'Impact Arena, Bangkok',
        fightCount: 12,
        imageUrl: 'assets/dfc_backgrounds/dfc2_image_.png',
        template: SocialMediaTemplateSizes.instagramPostPortrait,
        accentColor: AppTheme.neonCyan,
        tag: '🥊 PPV · PAYPAL',
      ),
      const _FightEvent(
        title: 'PFL SUPER FIGHTS: RIYADH',
        promotion: 'PFL · Singles + Full Card on FightPipe',
        mainEvent: 'Ngannou vs. Ferreira',
        date: 'April 12, 2026',
        location: 'Kingdom Arena, Riyadh',
        fightCount: 10,
        imageUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
        template: SocialMediaTemplateSizes.facebookFeedImage,
        accentColor: Color(0xFFFFB800),
        tag: '🏆 \$2M · PAYMENT PLANS',
      ),
      const _FightEvent(
        title: 'BKFC 68: London',
        promotion: 'BKFC · FightPipe Exclusive PPV',
        mainEvent: 'World Bare Knuckle Championship',
        date: 'March 29, 2026',
        location: 'O2 Arena, London',
        fightCount: 11,
        imageUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
        template: SocialMediaTemplateSizes.xPostLandscape,
        accentColor: Color(0xFFE17055),
        tag: '🇬🇧 PPV · SINGLES',
      ),
      const _FightEvent(
        title: 'GLORY 92: Amsterdam',
        promotion: 'GLORY Kickboxing · via FightPipe',
        mainEvent: 'Heavyweight Grand Prix Final',
        date: 'April 5, 2026',
        location: 'Ahoy Rotterdam, Netherlands',
        fightCount: 9,
        imageUrl: 'assets/dfc_backgrounds/dfc_logo_resized.png',
        template: SocialMediaTemplateSizes.pinterestStandardPin,
        accentColor: Color(0xFFFF8C00),
        tag: '🇳🇱 KICKBOXING PPV',
      ),
      const _FightEvent(
        title: 'Bellator Champions Series: Wembley',
        promotion: 'Bellator MMA · FightPipe Distribution',
        mainEvent: '15-Fight Mega Card — UK vs World',
        date: 'April 19, 2026',
        location: 'Wembley Arena, London',
        fightCount: 15,
        imageUrl: 'assets/dfc_backgrounds/datafightlogo.png',
        template: SocialMediaTemplateSizes.linkedInPostImage,
        accentColor: AppTheme.neonMagenta,
        tag: '🎟️ SOLD OUT',
      ),
      const _FightEvent(
        title: 'RIZIN 50: Tokyo',
        promotion: 'RIZIN FF · AU + US distribution via FightPipe',
        mainEvent: 'Japan vs USA Super Card — Tokyo Dome',
        date: 'June 14, 2026',
        location: 'Tokyo Dome, Japan',
        fightCount: 13,
        imageUrl: 'assets/dfc_backgrounds/dfc_logo_resized.png',
        template: SocialMediaTemplateSizes.tiktokVideoStory,
        accentColor: Color(0xFFFF6B6B),
        tag: '🇯🇵 PPV · PAYPAL',
      ),
      const _FightEvent(
        title: 'Matchroom Boxing: AJ vs Zhang II',
        promotion: 'Matchroom · Stream on FightPipe',
        mainEvent: 'Joshua vs. Zhang — Heavyweight Rematch',
        date: 'April 12, 2026',
        location: 'Wembley Stadium, London',
        fightCount: 8,
        imageUrl: 'assets/dfc_backgrounds/dfc2_image_.png',
        template: SocialMediaTemplateSizes.instagramPostSquare,
        accentColor: Color(0xFF00B4D8),
        tag: '🥊 80,000 · PPV',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length + 1, // +1 for header
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UPCOMING FIGHT CARDS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${events.length} events worldwide — tap for tickets & details',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          );
        }
        final e = events[i - 1];
        return _buildFightEventCard(e);
      },
    );
  }

  Widget _buildFightEventCard(_FightEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: event.accentColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: event.accentColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // === EVENT POSTER IMAGE ===
          LayoutBuilder(
            builder: (context, constraints) {
              final mediaHeight = _eventMediaHeightFor(
                template: event.template,
                width: constraints.maxWidth,
              );
              return SizedBox(
                height: mediaHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DfcImage(
                      url: event.imageUrl,
                      width: constraints.maxWidth,
                      height: mediaHeight,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: event.accentColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          event.tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: event.accentColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${event.fightCount} FIGHTS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 14,
                      right: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: event.accentColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event.promotion.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            event.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(blurRadius: 8, color: Colors.black87),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // === EVENT DETAILS ===
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Location + Date row
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.calendar_today,
                      color: event.accentColor,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.date,
                      style: TextStyle(
                        color: event.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Main Event
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: event.accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: event.accentColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.stadium, color: event.accentColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MAIN EVENT',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event.mainEvent,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSignal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Create Signal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildSignalTypeOption(
                '📅',
                'Event',
                'Announce a fight card or tournament',
              ),
              const SizedBox(height: 12),
              _buildSignalTypeOption(
                '⚡',
                'Short Notice',
                'Urgent replacement needed',
              ),
              const SizedBox(height: 12),
              _buildSignalTypeOption(
                '💼',
                'Opportunity',
                'Job posting or collaboration',
              ),
              const SizedBox(height: 12),
              _buildSignalTypeOption(
                '🏋️',
                'Gym Update',
                'Training session or announcement',
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  double _eventMediaHeightFor({
    required SocialTemplateSize template,
    required double width,
  }) {
    final rawHeight = width / template.aspectRatio;
    return rawHeight.clamp(180.0, 340.0).toDouble();
  }

  Widget _buildSignalTypeOption(String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  List<_CarouselItem> get _dynamicCarouselItems {
    if (!_syntheticEnabled) {
      return const [
        _CarouselItem(
          label: 'LIVE DATA ONLY',
          title: 'Synthetic feeds are disabled',
          subtitle: 'Connect your live sources to populate FightWire',
          accent: DesignTokens.neonCyan,
          icon: Icons.shield,
        ),
      ];
    }

    final items = <_CarouselItem>[
      // AI Powerhouse status card
      _CarouselItem(
        label: 'AI POWERHOUSE',
        title: _enginesBooted
            ? '${_powerhouse.status.activeEngines}/${_powerhouse.status.totalEngines} Engines Online'
            : 'Booting AI Engines...',
        subtitle: _enginesBooted
            ? '${_powerhouse.status.totalBotsActive} bots active · ${_liveSignals.length} signals'
            : 'Initializing Kimik2.5 + ESO + Scanner',
        accent: DesignTokens.neonCyan,
        icon: Icons.psychology,
      ),
    ];

    // Add breaking news from scanner
    final breaking = _enginesBooted ? _scanner.getBreaking() : [];
    for (final b in breaking.take(2)) {
      items.add(
        _CarouselItem(
          label: '🚨 BREAKING',
          title: b.title,
          subtitle:
              '${b.sourceIcon} ${b.sourceName} · ${_powerhouse.status.totalBotsActive} bots scanning',
          accent: Colors.red,
          icon: Icons.bolt,
        ),
      );
    }

    // Add Kimik2.5 insight card
    if (_kimikInsights.isNotEmpty) {
      final insight = _kimikInsights.first;
      items.add(
        _CarouselItem(
          label: 'KIMIK 2.5',
          title: insight.title,
          subtitle:
              'Confidence: ${(insight.confidence * 100).toInt()}% · ${insight.engine}',
          accent: DesignTokens.neonMagenta,
          icon: Icons.auto_awesome,
        ),
      );
    }

    // Add ESO wellness card if available
    final wellness = _eso.currentWellness;
    if (wellness != null) {
      items.add(
        _CarouselItem(
          label: 'ESO ENGINE',
          title: wellness.trainingRecommendation,
          subtitle:
              'Readiness: ${wellness.readinessScore.toInt()}% · Recovery: ${wellness.recoveryScore.toInt()}%',
          accent: DesignTokens.neonGreen,
          icon: Icons.monitor_heart,
        ),
      );
    }

    // Keep a static promo card
    items.add(
      const _CarouselItem(
        label: 'Sponsored',
        title: 'Hydration Lab — Fight Week Kit',
        subtitle: 'Claim 20% off • Partner Offer',
        accent: Colors.purple,
        icon: Icons.local_offer,
      ),
    );

    // Real event spotlight cards
    items.addAll([
      const _CarouselItem(
        label: '🔴 IBC III',
        title: 'International Brawling Championship',
        subtitle: 'Gold Coast Sports & Leisure · Mar 7 · TOMORROW',
        accent: Color(0xFFFF0000),
        icon: Icons.sports_mma,
      ),
      const _CarouselItem(
        label: '🏆 ULTIMATE LEGENDS',
        title: 'WBC Silver Australian Title — Joey Demicoli',
        subtitle: 'Ultimate Legends × DFC · April 24 · Est. 1992',
        accent: Color(0xFFFFD700),
        icon: Icons.emoji_events,
      ),
      const _CarouselItem(
        label: '☕ DFC',
        title: 'Buy a Coffee, Not a Coffin',
        subtitle: 'Donate to give someone hurting a moment of hope',
        accent: Color(0xFF6D4C41),
        icon: Icons.favorite,
      ),
      const _CarouselItem(
        label: 'UFC 325',
        title: 'Santos vs Aliyev — LHW Title',
        subtitle: 'Farmasi Arena São Paulo · ESPN+ PPV · Apr 12',
        accent: Color(0xFF00F5FF),
        icon: Icons.sports_mma,
      ),
      const _CarouselItem(
        label: '🥊 TRILOGY',
        title: 'Reyes vs Brennan III — 80K in Dublin',
        subtitle: 'Croke Park · DAZN PPV · May 17',
        accent: Color(0xFFFFD700),
        icon: Icons.sports_mma,
        // Trilogy event poster — use branded asset when available
      ),
      const _CarouselItem(
        label: 'SHIELDS',
        title: 'Night of Champions — Detroit Boxing',
        subtitle: 'Little Caesars Arena · Showtime · Jun 7',
        accent: Color(0xFFFF00FF),
        icon: Icons.emoji_events,
      ),
      const _CarouselItem(
        label: 'GLORY 92',
        title: 'HW Grand Prix Finals — Amsterdam',
        subtitle: 'Ahoy Rotterdam · GLORY TV · Mar 22',
        accent: Color(0xFFFF8C00),
        icon: Icons.sports_kabaddi,
      ),
      const _CarouselItem(
        label: 'CANELO',
        title: 'Undisputed 168 — AT&T Stadium 70K',
        subtitle: 'Dallas · DAZN PPV · Sep 13',
        accent: Color(0xFFFF0000),
        icon: Icons.sports_mma,
      ),
      const _CarouselItem(
        label: 'BKFC KM6',
        title: 'KnuckleMania VI — Super Card',
        subtitle: 'Hard Rock Hollywood · BKFC App · Mar 29',
        accent: Color(0xFFFF5252),
        icon: Icons.front_hand,
      ),
      const _CarouselItem(
        label: 'ONE SAMURAI',
        title: 'Stamp vs Ji-Yeon Park — Tokyo',
        subtitle: 'Tokyo Dome · Amazon Prime · Apr 5',
        accent: Color(0xFFFF0080),
        icon: Icons.sports_kabaddi,
      ),
    ]);

    return items;
  }

  // ─── Live Signal Getters (AI-powered) ─────────────────────────────────
  List<SignalCard> get _allSignals {
    // Always show base signals, even if synthetic AI is disabled
    final combined = <SignalCard>[
      ..._baseEventSignals,
      ..._baseShortNoticeSignals,
      ..._baseOpportunitySignals,
      ..._baseGymSignals,
    ];

    // Add AI-generated signals only if synthetic content is enabled
    if (_syntheticEnabled && _enginesBooted) {
      for (final s in _liveSignals.take(50)) {
        combined.add(
          SignalCard(
            title: s.title,
            category: s.category,
            description: s.description,
            location: s.location,
            timeAgo: s.timeAgo,
            icon: _iconFromName(s.iconName),
            urgency: _mapUrgency(s.urgency),
            ctaLabel: s.isBreaking ? 'Read Now' : null,
            imageUrl: s.imageUrl,
          ),
        );
      }
    }
    combined.sort((a, b) => b.urgency.index.compareTo(a.urgency.index));
    return combined;
  }

  List<SignalCard> get _eventSignals {
    // Always show base event signals
    final signals = <SignalCard>[..._baseEventSignals];

    // Add AI-generated events only if synthetic is enabled
    if (_syntheticEnabled && _enginesBooted) {
      final live = _powerhouse.getEventSignals(limit: 20);
      signals.addAll(
        live.map(
          (s) => SignalCard(
            title: s.title,
            category: s.category,
            description: s.description,
            location: s.location,
            timeAgo: s.timeAgo,
            icon: _iconFromName(s.iconName),
            urgency: _mapUrgency(s.urgency),
            ctaLabel: s.isBreaking ? 'Get Tickets' : null,
            imageUrl: s.imageUrl,
          ),
        ),
      );
    }
    return signals..sort((a, b) => b.urgency.index.compareTo(a.urgency.index));
  }

  List<SignalCard> get _shortNoticeSignals {
    // Always show base short notice signals
    final signals = <SignalCard>[..._baseShortNoticeSignals];

    // Add AI-generated short notice signals only if synthetic is enabled
    if (_syntheticEnabled && _enginesBooted) {
      final live = _powerhouse.getShortNoticeSignals(limit: 15);
      signals.addAll(
        live.map(
          (s) => SignalCard(
            title: s.title,
            category: 'SHORT NOTICE',
            description: s.description,
            location: s.location,
            timeAgo: s.timeAgo,
            icon: Icons.warning_amber,
            urgency: _mapUrgency(s.urgency),
            expiresIn: s.isBreaking ? const Duration(hours: 24) : null,
            ctaLabel: 'Apply Now',
            imageUrl: s.imageUrl,
          ),
        ),
      );
    }
    return signals..sort((a, b) => b.urgency.index.compareTo(a.urgency.index));
  }

  List<SignalCard> get _opportunitySignals {
    // Always show base opportunity signals
    final signals = <SignalCard>[..._baseOpportunitySignals];

    // Add AI-generated opportunities only if synthetic is enabled
    if (_syntheticEnabled && _enginesBooted) {
      final live = _powerhouse.getOpportunitySignals(limit: 15);
      signals.addAll(
        live.map(
          (s) => SignalCard(
            title: s.title,
            category: s.category,
            description: s.description,
            location: s.location,
            timeAgo: s.timeAgo,
            icon: _iconFromName(s.iconName),
            urgency: _mapUrgency(s.urgency),
            ctaLabel: 'Apply',
            imageUrl: s.imageUrl,
          ),
        ),
      );
    }
    return signals..sort((a, b) => b.urgency.index.compareTo(a.urgency.index));
  }

  List<SignalCard> get _gymSignals {
    // Always show base gym signals
    final signals = <SignalCard>[..._baseGymSignals];

    // Add AI-generated gym signals only if synthetic is enabled
    if (_syntheticEnabled && _enginesBooted) {
      final live = _powerhouse.getGymSignals(limit: 15);
      signals.addAll(
        live.map(
          (s) => SignalCard(
            title: s.title,
            category: 'GYM',
            description: s.description,
            location: s.location,
            timeAgo: s.timeAgo,
            icon: _iconFromName(s.iconName),
            urgency: _mapUrgency(s.urgency),
            imageUrl: s.imageUrl,
          ),
        ),
      );
    }
    return signals..sort((a, b) => b.urgency.index.compareTo(a.urgency.index));
  }

  // ─── Base Signal Data (original hardcoded) ─────────────────────────────

  List<SignalCard> get _baseEventSignals => [
    // ── DFC PARTNER: Ultimate Legends (Joey Demicoli × John Scida) ──
    SignalCard(
      title: '🏆 Ultimate Legends: WBC Silver Australian Title',
      category: 'DFC PARTNER',
      description:
          'Joey Demicoli & John Scida present Ultimate Legends (est. 1992) — Elite Ultimate Muay Thai. WBC Silver Australian Title fight. 15+ years of world-class fight promotion backed by DFC.',
      location: 'Australia',
      timeAgo: '30m ago',
      icon: Icons.emoji_events,
      eventDate: DateTime(
        2026,
        4,
        24,
      ), // April 24, 2026 — Auto-calculates to HIGH urgency (45 days out)
      ctaLabel: 'Get Tickets',
      imageUrl: 'assets/dfc_backgrounds/dfc2_image.png',
    ),
    SignalCard(
      title: 'Cage Titans 180',
      category: 'EVENT',
      description:
          'Main card featuring European championship bouts. Live from Manchester Arena with 8 professional fights.',
      location: 'Manchester, UK',
      timeAgo: '2h ago',
      icon: Icons.event,
      eventDate: DateTime(2026, 3, 28), // 18 days out — NORMAL urgency
      ctaLabel: 'Get Tickets',
      imageUrl: 'assets/dfc_backgrounds/datafightlogo.png',
    ),
    SignalCard(
      title: 'Local Amateur Night',
      category: 'EVENT',
      description:
          'Amateur boxing event looking for fighters 66-84 kg (145-185 lbs). Great exposure opportunity.',
      location: 'Denver, CO',
      timeAgo: '5h ago',
      icon: Icons.sports_mma,
      eventDate: DateTime(2026, 4, 10), // 31 days out — LOW urgency
      imageUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
    ),
    SignalCard(
      title: 'PFL Australia: Sydney Showdown',
      category: 'EVENT',
      description:
          'Professional Fighters League making its Australian debut with 12 bouts. Headlined by local favorite vs international contender.',
      location: 'ICC Sydney, Australia',
      timeAgo: '1h ago',
      icon: Icons.event,
      eventDate: DateTime(2026, 3, 15), // 5 days out — CRITICAL urgency
      ctaLabel: 'Get Tickets',
      imageUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
    ),
    SignalCard(
      title: 'GLORY 96: Amsterdam',
      category: 'EVENT',
      description:
          'Elite kickboxing event featuring Heavyweight Grand Prix semi-finals. 10 fights confirmed.',
      location: 'Amsterdam, Netherlands',
      timeAgo: '3h ago',
      icon: Icons.event,
      eventDate: DateTime(2026, 3, 22), // 12 days out — HIGH urgency
      ctaLabel: 'Watch Live',
      imageUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
    ),
    SignalCard(
      title: 'Hex Fight Series 26',
      category: 'EVENT',
      description:
          'Australia\'s premier MMA promotion returns to Brisbane with 14 bouts including 3 title fights.',
      location: 'Brisbane Convention Centre',
      timeAgo: '4h ago',
      icon: Icons.sports_mma,
      eventDate: DateTime(2026, 4, 5), // 26 days out — NORMAL urgency
      imageUrl: 'assets/dfc_backgrounds/dfc_logo_resized.png',
    ),
    SignalCard(
      title: 'UFC Fight Night: Perth',
      category: 'EVENT',
      description:
          'First-ever UFC Fight Night in Perth! Jack Della Maddalena vs Carlos Prates headlines at RAC Arena. 12 bouts confirmed.',
      location: 'RAC Arena, Perth, WA',
      timeAgo: '1h ago',
      icon: Icons.sports_mma,
      eventDate: DateTime(2026, 3, 14), // 4 days out — CRITICAL urgency
      ctaLabel: 'Get Tickets',
      imageUrl: 'assets/dfc_backgrounds/dfc2_image.png',
    ),
    SignalCard(
      title: 'Eternal MMA 80: Perth',
      category: 'EVENT',
      description:
          'Eternal MMA brings a stacked 16-fight card to HBF Stadium. WA vs QLD superfight series headlines.',
      location: 'HBF Stadium, Perth, WA',
      timeAgo: '3h ago',
      icon: Icons.sports_mma,
      eventDate: DateTime(2026, 3, 29), // 19 days out — NORMAL urgency
      imageUrl: 'assets/dfc_backgrounds/datafightlogo.png',
    ),
    SignalCard(
      title: 'Empire Fight Series: Inception 5',
      category: 'EVENT',
      description:
          'WA vs QLD Muay Thai national showdown at Claremont Showground. Lougheed vs Chan main event.',
      location: 'Claremont Showground, Perth, WA',
      timeAgo: '5h ago',
      icon: Icons.event,
      urgency: SignalUrgency.normal,
      imageUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
    ),
    SignalCard(
      title: 'West Coast Fight Shows 12',
      category: 'EVENT',
      description:
          'Perth\'s grassroots combat sports showcase — Muay Thai, MMA & Boxing triple header. 20 bouts at Metro City.',
      location: 'Metro City, Perth, WA',
      timeAgo: '6h ago',
      icon: Icons.event,
      urgency: SignalUrgency.normal,
      imageUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
    ),
    SignalCard(
      title: 'IBC 03: International Brawling Championship',
      category: 'EVENT',
      description:
          'Australia\'s hottest new combat sport! Closed-fist hybrid format — no grappling, all action. IBC 03 TOMORROW on Gold Coast. Live on TrillerTV+ & Kayo Sports PPV.',
      location: 'Gold Coast, QLD, Australia',
      timeAgo: '30m ago',
      icon: Icons.sports_mma,
      urgency: SignalUrgency.critical,
      ctaLabel: 'Get Tickets',
      imageUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
    ),
    SignalCard(
      title: 'IBC Goes Global — Las Vegas Announced',
      category: 'EVENT',
      description:
          'Danny Mac confirms IBC heading to Las Vegas. \$1B brawling dream goes international. First AU combat sport to break into the US market.',
      location: 'Las Vegas, NV (TBA)',
      timeAgo: '2h ago',
      icon: Icons.public,
      urgency: SignalUrgency.high,
      imageUrl: 'assets/dfc_backgrounds/dfc_logo_resized.png',
    ),
    // ── Ultimate Legends — WBC Silver Australian Title ──
    SignalCard(
      title: 'ULTIMATE LEGENDS: WBC Silver Australian Title',
      category: 'EVENT',
      description:
          'Melbourne\'s premier fight promotion returns April 24th! WBC Silver Australian Title headlines — Jordan Roesler main event. Pro Boxing, K1, Kickboxing & Muay Thai at Melbourne Pavilion. Founded 1992 by John Scida. Live on Live Combat Sports.',
      location: 'Melbourne Pavilion, VIC, Australia',
      timeAgo: '45m ago',
      icon: Icons.emoji_events,
      urgency: SignalUrgency.critical,
      ctaLabel: 'Get Tickets',
      imageUrl: 'assets/dfc_backgrounds/dfc2_image.png',
    ),
    SignalCard(
      title: 'Joey Demicoli x DFC — Ultimate Legends Partnership',
      category: 'PARTNERSHIP',
      description:
          'DataFightCentral officially partners with Ultimate Legends Promotions (est. 1992). Joey Demicoli brings 15+ years of fight promotion to the DFC Promotional Engine. First event: WBC Silver Australian Title, April 24th.',
      location: 'Melbourne, VIC, Australia',
      timeAgo: '1h ago',
      icon: Icons.handshake,
      urgency: SignalUrgency.high,
      imageUrl: 'assets/dfc_backgrounds/datafightlogo.png',
    ),
    SignalCard(
      title: 'Elite Fight Series: Cairns',
      category: 'EVENT',
      description:
          'North QLD\'s explosive fight show returns. MMA, Muay Thai & Boxing livestreamed by Cairns Post. 12 bouts confirmed.',
      location: 'Cairns, QLD, Australia',
      timeAgo: '4h ago',
      icon: Icons.sports_mma,
      urgency: SignalUrgency.normal,
      imageUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
    ),
    SignalCard(
      title: 'Adrenalyn Fight Circuit: MFC 8',
      category: 'EVENT',
      description:
          'Brisbane Southside grassroots fight show. 16 bouts of Muay Thai, Boxing & MMA from Logan. AU\'s next generation of fighters.',
      location: 'Logan, QLD, Australia',
      timeAgo: '5h ago',
      icon: Icons.sports_mma,
      urgency: SignalUrgency.normal,
      imageUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
    ),
    SignalCard(
      title: 'Pacific MMA 10 — Kalgoorlie',
      category: 'EVENT',
      description:
          'Regional WA fight show returns. Pacific MMA\'s 10th event brings local and travelling fighters to the Goldfields.',
      location: 'Kalgoorlie, WA, Australia',
      timeAgo: '8h ago',
      icon: Icons.sports_mma,
      urgency: SignalUrgency.low,
      imageUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
    ),
    SignalCard(
      title: 'Rajadamnern World Series',
      category: 'EVENT',
      description:
          'Premier Muay Thai event at the legendary Rajadamnern Stadium. 8-man tournament bracket.',
      location: 'Bangkok, Thailand',
      timeAgo: '6h ago',
      icon: Icons.event,
      urgency: SignalUrgency.normal,
      imageUrl: 'assets/dfc_backgrounds/dfc_logo_resized.png',
    ),
    SignalCard(
      title: 'Karate Combat Season 6',
      category: 'EVENT',
      description:
          'Full-contact karate returns with Hollywood production. Bas Rutten on commentary.',
      location: 'Hollywood, CA',
      timeAgo: '8h ago',
      icon: Icons.event,
      urgency: SignalUrgency.low,
      imageUrl: 'assets/dfc_backgrounds/dfc2_image.png',
    ),
    SignalCard(
      title: 'BKFC 72: Bare Knuckle Brawl',
      category: 'EVENT',
      description:
          'Bare Knuckle Fighting Championship brings 11 fights. Main event: former UFC veterans collide.',
      location: 'Biloxi, MS',
      timeAgo: '30m ago',
      icon: Icons.sports_mma,
      urgency: SignalUrgency.high,
      ctaLabel: 'Buy PPV',
      imageUrl: 'assets/dfc_backgrounds/datafightlogo.png',
    ),
  ];

  List<SignalCard> get _baseShortNoticeSignals => [
    SignalCard(
      title: '🚨 61 kg / 135 lbs Replacement Needed',
      category: 'SHORT NOTICE',
      description:
          'URGENT: Fighter dropped out 48 hours before weigh-ins. Looking for experienced bantamweight. Purse: \$5,000.',
      location: 'Las Vegas, NV',
      timeAgo: '15m ago',
      icon: Icons.warning_amber,
      urgency: SignalUrgency.critical,
      expiresIn: const Duration(hours: 12),
      ctaLabel: 'Apply Now',
      imageUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
    ),
    SignalCard(
      title: 'Middleweight Needed',
      category: 'SHORT NOTICE',
      description:
          'Looking for 185lb fighter for Saturday card. Must have pro record.',
      location: 'Phoenix, AZ',
      timeAgo: '1h ago',
      icon: Icons.warning_amber,
      urgency: SignalUrgency.high,
      expiresIn: const Duration(days: 2),
      ctaLabel: 'Apply Now',
      imageUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
    ),
    SignalCard(
      title: '🚨 Welterweight Needed — 24 Hours',
      category: 'SHORT NOTICE',
      description:
          'Co-main event fighter injured. 170lb replacement needed ASAP. \$8,000 purse + win bonus. Professional record required.',
      location: 'Atlanta, GA',
      timeAgo: '45m ago',
      icon: Icons.warning_amber,
      urgency: SignalUrgency.critical,
      expiresIn: const Duration(hours: 24),
      ctaLabel: 'Apply Now',
      imageUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
    ),
    SignalCard(
      title: 'Lightweight Replacement — Cage Warriors',
      category: 'SHORT NOTICE',
      description:
          'Cage Warriors card needs 155lb replacement. International exposure opportunity. Travel covered.',
      location: 'Manchester, UK',
      timeAgo: '3h ago',
      icon: Icons.warning_amber,
      urgency: SignalUrgency.high,
      expiresIn: const Duration(days: 3),
      ctaLabel: 'Apply Now',
      imageUrl: 'assets/dfc_backgrounds/dfc_logo_resized.png',
    ),
    SignalCard(
      title: '🚨 Featherweight Bout — Tonight',
      category: 'SHORT NOTICE',
      description:
          'SAME DAY: 145lb fighter needed for tonight\'s BKFC card. Bare knuckle experience preferred. \$3,000 show money.',
      location: 'Tampa, FL',
      timeAgo: '2h ago',
      icon: Icons.warning_amber,
      urgency: SignalUrgency.critical,
      expiresIn: const Duration(hours: 6),
      ctaLabel: 'Contact Now',
      imageUrl: 'assets/dfc_backgrounds/dfc2_image.png',
    ),
    SignalCard(
      title: 'Heavyweight Needed — PFL Regional',
      category: 'SHORT NOTICE',
      description:
          'PFL regional card seeking heavyweight (205-265). 1 week notice. \$6,000 purse.',
      location: 'Dallas, TX',
      timeAgo: '5h ago',
      icon: Icons.warning_amber,
      urgency: SignalUrgency.high,
      expiresIn: const Duration(days: 5),
      ctaLabel: 'Apply Now',
      imageUrl: 'assets/dfc_backgrounds/datafightlogo.png',
    ),
    SignalCard(
      title: 'Muay Thai 63.5kg — Rajadamnern',
      category: 'SHORT NOTICE',
      description:
          'International fighter needed for Rajadamnern Stadium undercard. Flights + accommodation provided.',
      location: 'Bangkok, Thailand',
      timeAgo: '4h ago',
      icon: Icons.warning_amber,
      urgency: SignalUrgency.normal,
      expiresIn: const Duration(days: 7),
      ctaLabel: 'Apply',
      imageUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
    ),
    SignalCard(
      title: '🚨 Kickboxing 70kg — Glory',
      category: 'SHORT NOTICE',
      description:
          'GLORY Kickboxing needs 70kg replacement for Amsterdam card. Must have top-level record. \$10,000 purse.',
      location: 'Amsterdam, NL',
      timeAgo: '1h ago',
      icon: Icons.warning_amber,
      urgency: SignalUrgency.critical,
      expiresIn: const Duration(hours: 48),
      ctaLabel: 'Apply Now',
      imageUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
    ),
  ];

  List<SignalCard> get _baseOpportunitySignals => [
    SignalCard(
      title: 'Samurai Ops: Research Daily Fight Intel',
      category: 'OPS',
      description:
          'Track local cards, gym openings, prospects, and sponsor activity. Verify sources and submit a clean brief before 18:00 local time.',
      location: 'Global • Remote',
      timeAgo: '10m ago',
      icon: Icons.travel_explore,
      urgency: SignalUrgency.critical,
      ctaLabel: 'Research',
      imageUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
    ),
    SignalCard(
      title: 'Samurai Ops: Find Fighters, Coaches, Promoters',
      category: 'OPS',
      description:
          'Use the new intel to identify the right people fast: fighters who need opportunities, coaches who can teach, and promoters ready to move.',
      location: 'Field + DFC Network',
      timeAgo: '12m ago',
      icon: Icons.person_search,
      urgency: SignalUrgency.high,
      ctaLabel: 'Find Leads',
      imageUrl: 'assets/dfc_backgrounds/dfc_logo_resized.png',
    ),
    SignalCard(
      title: 'Samurai Ops: Deploy Campaigns in 24h',
      category: 'OPS',
      description:
          'Convert approved leads into live posts, outreach threads, and event pushes. Goal: publish and activate every qualified opportunity within 24 hours.',
      location: 'DFC Launch Grid',
      timeAgo: '15m ago',
      icon: Icons.rocket_launch,
      urgency: SignalUrgency.critical,
      ctaLabel: 'Deploy Now',
      imageUrl: 'assets/dfc_backgrounds/dfc2_image.png',
    ),
    SignalCard(
      title: 'Samurai Mentors Needed — Teach the Next Wave',
      category: 'OPPORTUNITY',
      description:
          'Experienced fighters and coaches needed to run weekly fundamentals sessions for rising amateurs. Focus: discipline, defense, and ring IQ.',
      location: 'Global • Hybrid',
      timeAgo: '20m ago',
      icon: Icons.school,
      urgency: SignalUrgency.high,
      ctaLabel: 'Teach Now',
      imageUrl: 'assets/dfc_backgrounds/datafightlogo.png',
    ),
    SignalCard(
      title: 'Samurai Curriculum Drop — Footwork to Fight IQ',
      category: 'COACHING',
      description:
          'Build and share 4-week curriculum blocks for beginner-to-intermediate fighters. Selected mentors get featured in DFC creator spots.',
      location: 'Remote',
      timeAgo: '35m ago',
      icon: Icons.menu_book,
      urgency: SignalUrgency.normal,
      ctaLabel: 'Submit Program',
      imageUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
    ),
    SignalCard(
      title: 'Seeking Striking Coach',
      category: 'OPPORTUNITY',
      description:
          'Professional MMA gym looking for experienced striking coach. Must have competitive background and coaching certifications.',
      location: 'Miami, FL',
      timeAgo: '1d ago',
      icon: Icons.work,
      urgency: SignalUrgency.normal,
      ctaLabel: 'Apply',
      imageUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
    ),
    SignalCard(
      title: 'Sponsor Opportunity',
      category: 'SPONSOR',
      description:
          'Supplement brand seeking fighters for NIL deals. Open to all weight classes with social media presence.',
      location: 'Remote',
      timeAgo: '3h ago',
      icon: Icons.handshake,
      urgency: SignalUrgency.normal,
      imageUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
    ),
    SignalCard(
      title: 'Venum Ambassador Program',
      category: 'SPONSOR',
      description:
          'Venum seeking 10 up-and-coming fighters for 2026 ambassador program. Free gear + monthly stipend + social media features.',
      location: 'Global',
      timeAgo: '6h ago',
      icon: Icons.handshake,
      urgency: SignalUrgency.high,
      ctaLabel: 'Apply',
      imageUrl: 'assets/dfc_backgrounds/dfc_logo_resized.png',
    ),
    SignalCard(
      title: 'BJJ Head Coach — Sydney Academy',
      category: 'OPPORTUNITY',
      description:
          'Growing BJJ academy in Sydney CBD seeking head coach. Competitive salary + profit share. Must be purple belt or above.',
      location: 'Sydney, Australia',
      timeAgo: '12h ago',
      icon: Icons.work,
      urgency: SignalUrgency.normal,
      ctaLabel: 'Apply',
      imageUrl: 'assets/dfc_backgrounds/dfc2_image.png',
    ),
    SignalCard(
      title: 'MMA Coach Wanted — Perth Academy',
      category: 'OPPORTUNITY',
      description:
          'Established Perth MMA gym seeking head striking coach. Muay Thai or boxing background required. Full-time role with fight team access.',
      location: 'Perth, WA, Australia',
      timeAgo: '8h ago',
      icon: Icons.work,
      urgency: SignalUrgency.normal,
      ctaLabel: 'Apply',
      imageUrl: 'assets/dfc_backgrounds/datafightlogo.png',
    ),
    SignalCard(
      title: 'Fight Commentary Analyst',
      category: 'OPPORTUNITY',
      description:
          'DAZN seeking freelance fight analysts for boxing and MMA coverage. Remote position, per-event compensation.',
      location: 'Remote',
      timeAgo: '1d ago',
      icon: Icons.mic,
      urgency: SignalUrgency.low,
      ctaLabel: 'Apply',
      imageUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
    ),
    SignalCard(
      title: 'Podcast Host — Combat Sports',
      category: 'OPPORTUNITY',
      description:
          'Major sports network launching combat sports podcast. Seeking charismatic host with fight experience. Full-time role.',
      location: 'New York, NY',
      timeAgo: '2d ago',
      icon: Icons.podcasts,
      urgency: SignalUrgency.normal,
      imageUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
    ),
    SignalCard(
      title: 'Hayabusa Product Tester',
      category: 'SPONSOR',
      description:
          'Hayabusa seeking active fighters to test new T4 MMA gloves and provide feedback. Free products + feature on social media.',
      location: 'Ship Worldwide',
      timeAgo: '8h ago',
      icon: Icons.handshake,
      urgency: SignalUrgency.normal,
      ctaLabel: 'Sign Up',
      imageUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
    ),
    SignalCard(
      title: 'S&C Coach — Elite Fight Gym',
      category: 'OPPORTUNITY',
      description:
          'Top-tier MMA gym seeking experienced S&C coach for pro fighters. CSCS certification required. Full-time with benefits.',
      location: 'Las Vegas, NV',
      timeAgo: '4h ago',
      icon: Icons.fitness_center,
      urgency: SignalUrgency.normal,
      ctaLabel: 'Apply',
      imageUrl: 'assets/dfc_backgrounds/dfc_logo_resized.png',
    ),
    SignalCard(
      title: 'Teach-a-Samurai Live Clinic — Saturday',
      category: 'COACHING',
      description:
          'Open live clinic for coaches to teach combinations, cage craft, and composure under pressure. Fighters can join as students or assistant coaches.',
      location: 'DFC Live + Local Partner Gyms',
      timeAgo: '1h ago',
      icon: Icons.groups,
      urgency: SignalUrgency.high,
      ctaLabel: 'Join Clinic',
      imageUrl: 'assets/dfc_backgrounds/dfc2_image.png',
    ),
  ];

  List<SignalCard> get _baseGymSignals => [
    SignalCard(
      title: 'Samurai Dojo Session — Teach One, Learn One',
      category: 'GYM',
      description:
          'Community training block where every advanced fighter pairs with a developing athlete for skills transfer and sparring IQ rounds.',
      location: 'Gold Coast, QLD',
      timeAgo: '50m ago',
      icon: Icons.sports_martial_arts,
      urgency: SignalUrgency.high,
      ctaLabel: 'Join Dojo',
      imageUrl: 'assets/dfc_backgrounds/datafightlogo.png',
    ),
    SignalCard(
      title: 'Open Mat Session',
      category: 'GYM',
      description:
          'Free open mat session this Saturday. All skill levels welcome. Bring your gear!',
      location: 'Elite MMA Gym, Chicago',
      timeAgo: '6h ago',
      icon: Icons.fitness_center,
      urgency: SignalUrgency.low,
      imageUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
    ),
    SignalCard(
      title: 'Pro Sparring Day',
      category: 'GYM',
      description:
          'Looking for pro sparring partners for fight camp. Welterweight and up preferred.',
      location: 'Elite Combat Team, FL',
      timeAgo: '8h ago',
      icon: Icons.sports_mma,
      urgency: SignalUrgency.normal,
      imageUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
    ),
    SignalCard(
      title: 'Free Trial Week — Tiger Muay Thai',
      category: 'GYM',
      description:
          'Tiger Muay Thai Phuket offering free week for international fighters. Accommodation packages available.',
      location: 'Phuket, Thailand',
      timeAgo: '2h ago',
      icon: Icons.fitness_center,
      urgency: SignalUrgency.high,
      ctaLabel: 'Book Now',
      imageUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
    ),
    SignalCard(
      title: 'New Gym Opening — BJJ + MMA',
      category: 'GYM',
      description:
          'Brand new 5,000 sqft facility opening in Melbourne CBD. First 50 members get 50% off annual membership.',
      location: 'Melbourne, Australia',
      timeAgo: '1d ago',
      icon: Icons.store,
      urgency: SignalUrgency.normal,
      ctaLabel: 'Join Waitlist',
      imageUrl: 'assets/dfc_backgrounds/dfc_logo_resized.png',
    ),
    SignalCard(
      title: 'New Muay Thai Gym — Perth, WA',
      category: 'GYM',
      description:
          '5 Star Fight & Fitness expanding with new Muay Thai + MMA facility in Northbridge, Perth. Grand opening sale — first month free.',
      location: 'Perth, WA, Australia',
      timeAgo: '6h ago',
      icon: Icons.store,
      urgency: SignalUrgency.normal,
      ctaLabel: 'Visit',
      imageUrl: 'assets/dfc_backgrounds/dfc2_image.png',
    ),
    SignalCard(
      title: 'Pacific MMA — Kalgoorlie Open',
      category: 'GYM',
      description:
          'Pacific MMA hosting open sparring session in Kalgoorlie. All levels welcome. Fight series scouts attending.',
      location: 'Kalgoorlie, WA, Australia',
      timeAgo: '4h ago',
      icon: Icons.fitness_center,
      urgency: SignalUrgency.normal,
      imageUrl: 'assets/dfc_backgrounds/datafightlogo.png',
    ),
    SignalCard(
      title: 'Wrestling Camp with Olympian',
      category: 'GYM',
      description:
          'Olympic wrestler hosting 3-day wrestling camp. Limited to 30 spots. All levels welcome.',
      location: 'American Top Team, FL',
      timeAgo: '12h ago',
      icon: Icons.school,
      urgency: SignalUrgency.high,
      ctaLabel: 'Register',
      imageUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
    ),
    SignalCard(
      title: 'Women\'s Self-Defense Workshop',
      category: 'GYM',
      description:
          'Free self-defense class taught by pro MMA fighters. Beginners encouraged. Every Saturday 10am.',
      location: 'Tristar Gym, Montreal',
      timeAgo: '3h ago',
      icon: Icons.shield,
      urgency: SignalUrgency.normal,
      imageUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
    ),
    SignalCard(
      title: 'Boxing Masterclass — World Champion',
      category: 'GYM',
      description:
          'Former world champion offering exclusive boxing technique workshop. 2 sessions: beginners + advanced.',
      location: 'Wild Card Gym, LA',
      timeAgo: '5h ago',
      icon: Icons.sports_mma,
      urgency: SignalUrgency.normal,
      ctaLabel: 'Book Spot',
      imageUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
    ),
    SignalCard(
      title: 'Kids MMA Program Launch',
      category: 'GYM',
      description:
          'Safe, structured MMA program for ages 8-14. Focus on discipline, fitness and anti-bullying. Free first month.',
      location: 'Jackson-Wink, ABQ',
      timeAgo: '1d ago',
      icon: Icons.child_care,
      urgency: SignalUrgency.low,
      imageUrl: 'assets/dfc_backgrounds/dfc_logo_resized.png',
    ),
    SignalCard(
      title: 'Corner Mastery Workshop — Samurai Coach Track',
      category: 'GYM',
      description:
          'Hands-on corner coaching workshop: between-round strategy, emergency cut protocol, and athlete communication under stress.',
      location: 'Perth, WA, Australia',
      timeAgo: '2h ago',
      icon: Icons.record_voice_over,
      urgency: SignalUrgency.normal,
      ctaLabel: 'Reserve Seat',
      imageUrl: 'assets/dfc_backgrounds/dfc2_image.png',
    ),
  ];
}

class _FightEvent {
  final String title;
  final String promotion;
  final String mainEvent;
  final String date;
  final String location;
  final int fightCount;
  final String imageUrl;
  final Color accentColor;
  final String tag;
  final SocialTemplateSize template;

  const _FightEvent({
    required this.title,
    required this.promotion,
    required this.mainEvent,
    required this.date,
    required this.location,
    required this.fightCount,
    required this.imageUrl,
    required this.accentColor,
    required this.tag,
    this.template = SocialMediaTemplateSizes.youtubeThumbnail,
  });
}

class _CarouselItem {
  final String label;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _CarouselItem({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });
}

class _CarouselCard extends StatelessWidget {
  final _CarouselItem item;

  const _CarouselCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.accent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: item.accent.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.accent.withValues(alpha: 0.18),
                  AppTheme.cardBackground,
                ],
              ),
            ),
          ),
          // Dark overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.accent.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.label.toUpperCase(),
                          style: TextStyle(
                            color: item.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Expiry Timer Widget with Countdown
class _ExpiryTimer extends StatefulWidget {
  final Duration expiresIn;
  const _ExpiryTimer({required this.expiresIn});

  @override
  State<_ExpiryTimer> createState() => _ExpiryTimerState();
}

class _ExpiryTimerState extends State<_ExpiryTimer> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresIn;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds > 0) {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes % 60;
    final isUrgent = _remaining.inHours < 12;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent
            ? Colors.red.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUrgent ? Colors.red : Colors.orange,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isUrgent ? Colors.red : Colors.orange,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${hours}h ${minutes}m',
            style: TextStyle(
              color: isUrgent ? Colors.red : Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// SignalCard Data Model
class SignalCard {
  final String title;
  final String category;
  final String description;
  final String location;
  final String timeAgo;
  final IconData icon;
  final SignalUrgency urgency;
  final Duration? expiresIn;
  final String? ctaLabel;
  final String? imageUrl;
  final DateTime? eventDate;

  SignalCard({
    required this.title,
    required this.category,
    required this.description,
    required this.location,
    required this.timeAgo,
    required this.icon,
    SignalUrgency? urgency,
    this.expiresIn,
    this.ctaLabel,
    this.imageUrl,
    this.eventDate,
  }) : urgency =
           urgency ??
           (eventDate != null
               ? _calculateUrgency(eventDate)
               : SignalUrgency.normal);

  /// Auto-calculate urgency based on event date (conveyor belt system)
  /// Build-up: 4 weeks → Critical
  /// Wind-down: Critical → 3 weeks fade
  static SignalUrgency _calculateUrgency(DateTime eventDate) {
    final now = DateTime.now();
    final diff = eventDate.difference(now);
    final daysUntil = diff.inDays;

    // BEFORE event (build-up phase)
    if (daysUntil >= 28) return SignalUrgency.low; // 4+ weeks: Low urgency
    if (daysUntil >= 14) {
      return SignalUrgency.normal; // 2-4 weeks: Normal urgency
    }
    if (daysUntil >= 7) {
      return SignalUrgency.high; // 1-2 weeks: High urgency
    }
    if (daysUntil >= 0) {
      return SignalUrgency.critical; // Event week: CRITICAL
    }

    // AFTER event (wind-down phase with results/recap)
    if (daysUntil >= -7) {
      return SignalUrgency.high; // 1 week after: High (recap)
    }
    if (daysUntil >= -14) {
      return SignalUrgency.normal; // 2 weeks after: Normal (recap)
    }
    if (daysUntil >= -21) {
      return SignalUrgency.low; // 3 weeks after: Low (fade)
    }

    return SignalUrgency.low; // More than 3 weeks past: fade out
  }

  Color get urgencyColor {
    switch (urgency) {
      case SignalUrgency.critical:
        return Colors.red;
      case SignalUrgency.high:
        return Colors.orange;
      case SignalUrgency.normal:
        return AppTheme.neonCyan;
      case SignalUrgency.low:
        return Colors.blueGrey;
    }
  }

  String get urgencyLabel {
    switch (urgency) {
      case SignalUrgency.critical:
        return 'CRITICAL';
      case SignalUrgency.high:
        return 'URGENT';
      case SignalUrgency.normal:
        return 'ACTIVE';
      case SignalUrgency.low:
        return 'INFO';
    }
  }
}

enum SignalUrgency { critical, high, normal, low }

/// ── Sticky tab bar delegate for NestedScrollView ──────────────────────────
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color color;

  _StickyTabBarDelegate({required this.child, required this.color});

  // Use 60 to stay within common viewport paint constraints and avoid
  // the SliverGeometry "layoutExtent exceeds paintExtent" assertion.
  static const double _kHeight = 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: Container(color: color, child: child),
    );
  }

  @override
  double get maxExtent => _kHeight;

  @override
  double get minExtent => _kHeight;

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) =>
      child != oldDelegate.child || color != oldDelegate.color;
}
