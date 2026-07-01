import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/image_assets.dart';
import '../../core/constants/market_expansion_playbook.dart';
import '../../core/utils/image_url_sanitizer.dart';
import 'dfc_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../services/youtube_service.dart';
import '../services/fight_news_service.dart';
import '../services/content_rotation_engine.dart';
import '../services/content_priority_service.dart';
import '../services/sponsor_feed_engine.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTWIRE FEED - The Promoter Love Engine
/// Live fight videos, breaking news, opportunities, and community signals
/// Unified combat sports intelligence feed for promoters, fighters & fans
/// ═══════════════════════════════════════════════════════════════════════════
class FightWireFeed extends StatefulWidget {
  final bool previewMode;

  const FightWireFeed({super.key, this.previewMode = false});

  @override
  State<FightWireFeed> createState() => _FightWireFeedState();
}

class _FightWireFeedState extends State<FightWireFeed> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _signals = [];
  final List<YouTubeVideo> _videos = [];
  final List<FightNewsArticle> _news = [];
  bool _isLoadingMore = false;
  bool _isLoadingVideos = true;
  bool _isLoadingNews = true;
  String _selectedCategory = 'All';
  final YouTubeService _ytService = YouTubeService();
  final FightNewsService _newsService = FightNewsService();
  final ContentRotationEngine _rotationEngine = ContentRotationEngine();
  final ContentPriorityService _priorityService = ContentPriorityService();
  final SponsorFeedEngine _sponsorEngine = SponsorFeedEngine();

  @override
  void initState() {
    super.initState();
    _loadInitialSignals();
    _loadYouTubeVideos();
    _loadFightNews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialSignals() {
    setState(() {
      _signals.addAll(_getLiveSignals());
    });
  }

  Future<void> _loadYouTubeVideos() async {
    try {
      final videos = await _ytService.fetchCombatVideos(maxResults: 10);
      if (mounted) {
        setState(() {
          _videos.addAll(videos);
          _isLoadingVideos = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingVideos = false);
    }
  }

  Future<void> _loadFightNews() async {
    try {
      final allNews = await _newsService.refreshNews();

      // Apply 12-hour content rotation — show full pool
      final rotated = _rotationEngine.rotateContent(allNews, maxItems: 50);

      // Apply priority sorting (pinned/boosted content rises to top)
      final prioritized = _priorityService.sortByPriority<FightNewsArticle>(
        rotated,
        (article) => article.id,
      );

      if (mounted) {
        setState(() {
          _news.addAll(prioritized);
          _isLoadingNews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingNews = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreContent();
    }
  }

  Future<void> _loadMoreContent() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final moreNews = await _newsService.fetchMoreNews(offset: _news.length);
      final moreSignals = _getMoreSignals(_signals.length);
      if (mounted) {
        setState(() {
          _news.addAll(moreNews);
          _signals.addAll(moreSignals);
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  /// Filter news by selected category
  List<FightNewsArticle> get _filteredNews {
    if (_selectedCategory == 'All') return _news;
    if (_selectedCategory == 'Breaking') {
      return _news.where((n) => n.isBreaking).toList();
    }
    final categoryMap = {
      'UFC': NewsSource.ufc,
      'Boxing': NewsSource.boxing,
      'MMA': NewsSource.mma,
      'Muay Thai': NewsSource.muayThai,
      'Kickboxing': NewsSource.kickboxing,
      'BKFC': NewsSource.bareKnuckle,
      'Brawling': NewsSource.brawling,
      'IBC': NewsSource.brawling,
      'RIZIN': NewsSource.rizin,
      'Local': NewsSource.local,
    };
    final source = categoryMap[_selectedCategory];
    if (source != null) {
      return _news.where((n) => n.category == source).toList();
    }
    return _news;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.previewMode) {
      return Column(
        children: [
          // Breaking news first — hero treatment
          if (_news.where((n) => n.isBreaking).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FightNewsCard(
                article: _news.firstWhere((n) => n.isBreaking),
                isHero: true,
              ),
            ),
          // Then a YouTube video
          if (_videos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _YouTubeVideoCard(video: _videos.first),
            ),
          // Then one signal
          if (_signals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FightWireSignalCard(signal: _signals.first),
            ),
        ],
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Category Filter Chips ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            height: 50,
            margin: const EdgeInsets.only(top: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('All'),
                _buildCategoryChip('Breaking'),
                _buildCategoryChip('UFC'),
                _buildCategoryChip('Boxing'),
                _buildCategoryChip('MMA'),
                _buildCategoryChip('Muay Thai'),
                _buildCategoryChip('Kickboxing'),
                _buildCategoryChip('BKFC'),
                _buildCategoryChip('RIZIN'),
                _buildCategoryChip('Local'),
              ],
            ),
          ),
        ),

        // ── Live Signal Banner ──────────────────────────────────────────
        SliverToBoxAdapter(child: _buildLiveSignalBanner(context)),

        // ── Breaking News Section ───────────────────────────────────────
        if (_isLoadingNews)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.neonCyan,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        if (_filteredNews.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.newspaper,
                      color: DesignTokens.neonCyan,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCategory == 'Breaking'
                              ? 'Breaking News'
                              : 'Fight News & Analysis',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Stories from across the combat sports world',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusPill,
                      ),
                      border: Border.all(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${_filteredNews.length}',
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Build a sponsored feed — inject sponsor cards every 3 items
                  final sponsoredFeed = _sponsorEngine
                      .buildSponsoredFeed<FightNewsArticle>(_filteredNews);
                  if (index >= sponsoredFeed.length) return null;

                  final item = sponsoredFeed[index];
                  if (item.isSponsored && item.sponsoredPost != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SponsoredPostCard(post: item.sponsoredPost!),
                    );
                  }
                  if (item.organicContent != null) {
                    // First organic article gets hero card treatment
                    final isFirst =
                        sponsoredFeed
                            .where((s) => !s.isSponsored)
                            .toList()
                            .indexOf(item) ==
                        0;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isFirst ? 14 : 10),
                      child: _FightNewsCard(
                        article: item.organicContent!,
                        isHero: isFirst || item.organicContent!.isFeatured,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                childCount:
                    _filteredNews.length + _sponsorEngine.activePosts.length,
              ),
            ),
          ),
        ],

        // ── YouTube Video Feed ──────────────────────────────────────────
        if (_isLoadingVideos)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.neonCyan,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        if (_videos.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.red.shade400,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fight Videos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Technique breakdowns, highlights & training',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: YouTubeService().hasApiKey
                          ? DesignTokens.neonGreen.withValues(alpha: 0.1)
                          : DesignTokens.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusPill,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: YouTubeService().hasApiKey
                                ? DesignTokens.neonGreen
                                : DesignTokens.neonCyan,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          YouTubeService().hasApiKey ? 'Live' : 'Curated',
                          style: TextStyle(
                            color: YouTubeService().hasApiKey
                                ? DesignTokens.neonGreen
                                : DesignTokens.neonCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index >= _videos.length) return null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _YouTubeVideoCard(video: _videos[index]),
                );
              }, childCount: _videos.length),
            ),
          ),
        ],

        // ── (Motivational banner removed — pro feed only) ──

        // ── Opportunities & Signals ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: DesignTokens.neonAmber,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Signals & Opportunities',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Events, jobs, and community updates',
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
        ),

        // Signal List
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index >= _signals.length) return null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FightWireSignalCard(signal: _signals[index]),
              );
            }, childCount: _signals.length),
          ),
        ),

        // Loading indicator
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.neonCyan.withValues(alpha: 0.15)
              : DesignTokens.bgCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
          border: Border.all(
            color: isSelected
                ? DesignTokens.neonCyan.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? DesignTokens.neonCyan
                : Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildLiveSignalBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.3),
            Colors.red.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.circle, color: Colors.red, size: 12),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔴 LIVE: Short Notice Replacement — 77 kg / 170 lbs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Welterweight • Cage Titans 180 • Manchester UK • Mar 15',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reach promoters via the Promotion Contacts page or email partners@datafightcentral.com'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Contact'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getLiveSignals() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final countryCode = (locale.countryCode?.isNotEmpty == true)
        ? locale.countryCode!
        : 'US';
    final langCode = locale.languageCode;
    final marketScript = MarketExpansionPlaybook.scriptFor(
      countryCode: countryCode,
      languageCode: langCode,
    );

    return [
      {
        'type': 'opportunity',
        'urgency': 'high',
        'title': marketScript.gatewayHeadline,
        'subtitle':
            '${marketScript.gatewaySubtitle} • Popular in your region: ${marketScript.prominentFightBrand}',
        'source': 'DFC FightPipe Opportunities Desk',
        'action': 'Apply Now',
        'icon': Icons.flight_takeoff,
        'color': DesignTokens.neonGold,
        'ctaUrl': 'https://datafightcentral.com/down-under-gateway',
      },
      {
        'type': 'opportunity',
        'urgency': 'medium',
        'title': 'Gym Ticket Domino Offer',
        'subtitle':
            '${marketScript.gymOffer} • ${marketScript.creatorAmplifier}',
        'source': 'DFC Revenue Expansion Desk',
        'action': 'View Offer',
        'icon': Icons.confirmation_num_outlined,
        'color': AppTheme.neonCyan,
        'ctaUrl': 'https://datafightcentral.com/gym-ticket-domino-offer',
      },
      {
        'type': 'opportunity',
        'urgency': 'medium',
        'title': 'Open Partner Shows — International Talent Intake',
        'subtitle':
            'Promoters can request verified contenders from global regions for any approved card',
        'source': 'DFC Partner Growth Desk',
        'action': 'Partner Intake',
        'icon': Icons.handshake,
        'color': AppTheme.neonCyan,
        'ctaUrl': 'https://datafightcentral.com/partner-intake',
      },
      {
        'type': 'safety',
        'urgency': 'high',
        'title': 'Eligibility Gate — Fight Ready Only',
        'subtitle':
            'Required: active training camp, coach reference, medical clearance, weight-class readiness, and valid travel documents',
        'source': 'DFC Compliance + Match Team',
        'action': 'Check Criteria',
        'icon': Icons.verified_user,
        'color': Colors.blue,
        'ctaUrl': 'https://datafightcentral.com/down-under-gateway/eligibility',
      },
      {
        'type': 'event',
        'urgency': 'high',
        'title': 'BKFC KnuckleMania VI',
        'subtitle': 'Mar 29 • Hard Rock, Hollywood FL',
        'source': 'Verified Promoter',
        'action': 'Watch',
        'icon': Icons.live_tv,
        'color': Colors.red,
      },
      {
        'type': 'opportunity',
        'urgency': 'medium',
        'title': 'Corner Work Needed — UFC Sydney',
        'subtitle': 'Mar 22 • Qudos Bank Arena, Sydney',
        'source': 'Team Request',
        'action': 'Apply',
        'icon': Icons.work_outline,
        'color': AppTheme.neonCyan,
      },
      {
        'type': 'camp',
        'urgency': 'low',
        'title': 'Fight Camp Opening',
        'subtitle': '8-week camp • Golden Dragon Muay Thai, Phuket',
        'source': 'Verified Gym',
        'action': 'Details',
        'icon': Icons.fitness_center,
        'color': Colors.green,
      },
      {
        'type': 'mentor',
        'urgency': 'low',
        'title': 'Mental Performance Coach Available',
        'subtitle': 'Remote sessions • Dr. Julie Tran, Sports Psych',
        'source': 'Verified Mentor',
        'action': 'Connect',
        'icon': Icons.psychology,
        'color': Colors.purple,
      },
      {
        'type': 'event',
        'urgency': 'medium',
        'title': 'ONE Championship 170: Bangkok',
        'subtitle': 'Mar 21 • Impact Arena, Bangkok',
        'source': 'Verified Promoter',
        'action': 'Watch',
        'icon': Icons.live_tv,
        'color': AppTheme.neonCyan,
      },
      {
        'type': 'opportunity',
        'urgency': 'high',
        'title': 'Sparring Partners Wanted',
        'subtitle': 'Heavyweight • Fortis MMA, Dallas TX',
        'source': 'Fighter Request',
        'action': 'Contact',
        'icon': Icons.sports_mma,
        'color': Colors.orange,
      },
      {
        'type': 'safety',
        'urgency': 'low',
        'title': 'Weight Cut Safety Protocol',
        'subtitle': '2026 updated guidelines • DFC Medics',
        'source': 'DataFightCentral',
        'action': 'Learn More',
        'icon': Icons.health_and_safety,
        'color': Colors.blue,
      },
    ];
  }

  /// Generate more signals for infinite scroll — cycles through real opportunities
  List<Map<String, dynamic>> _getMoreSignals(int currentCount) {
    final extraSignals = <Map<String, dynamic>>[
      {
        'type': 'event',
        'urgency': 'high',
        'title': 'UFC Fight Night — Nashville',
        'subtitle': 'Apr 5 • Bridgestone Arena, Nashville TN',
        'source': 'Verified Promoter',
        'action': 'Watch',
        'icon': Icons.live_tv,
        'color': Colors.red,
      },
      {
        'type': 'opportunity',
        'urgency': 'medium',
        'title': 'Referee Needed — Eternal MMA 85',
        'subtitle': 'Apr 12 • Brisbane Convention Centre',
        'source': 'Promoter Request',
        'action': 'Apply',
        'icon': Icons.work_outline,
        'color': AppTheme.neonCyan,
      },
      {
        'type': 'camp',
        'urgency': 'low',
        'title': 'BJJ Intensive — Legacy Grappling NYC',
        'subtitle': '6-week camp • New York City',
        'source': 'Verified Gym',
        'action': 'Details',
        'icon': Icons.fitness_center,
        'color': Colors.green,
      },
      {
        'type': 'event',
        'urgency': 'medium',
        'title': 'Cage Titans 181 — London',
        'subtitle': 'Apr 19 • Indigo at The O2, London',
        'source': 'Verified Promoter',
        'action': 'Watch',
        'icon': Icons.live_tv,
        'color': AppTheme.neonCyan,
      },
      {
        'type': 'opportunity',
        'urgency': 'high',
        'title': 'Cutman — PFL World Championship',
        'subtitle': 'Apr 26 • Madison Square Garden, NYC',
        'source': 'Team Request',
        'action': 'Apply',
        'icon': Icons.sports_mma,
        'color': Colors.orange,
      },
      {
        'type': 'mentor',
        'urgency': 'low',
        'title': 'Strength & Conditioning Coach',
        'subtitle': 'Remote • Jake Morrison, Combat Sports S&C',
        'source': 'Verified Coach',
        'action': 'Connect',
        'icon': Icons.psychology,
        'color': Colors.purple,
      },
      {
        'type': 'event',
        'urgency': 'high',
        'title': 'GLORY 95 — Rotterdam',
        'subtitle': 'May 3 • Ahoy Rotterdam, Netherlands',
        'source': 'Verified Promoter',
        'action': 'Watch',
        'icon': Icons.live_tv,
        'color': Colors.red,
      },
      {
        'type': 'opportunity',
        'urgency': 'medium',
        'title': 'Ring Card Medic — BKFC 68',
        'subtitle': 'May 10 • Seminole Hard Rock, FL',
        'source': 'Medical Team',
        'action': 'Apply',
        'icon': Icons.local_hospital,
        'color': Colors.blue,
      },
      {
        'type': 'camp',
        'urgency': 'low',
        'title': 'Wrestling Camp — Elite Combat Team',
        'subtitle': '4-week intensive • Coconut Creek FL',
        'source': 'Verified Gym',
        'action': 'Details',
        'icon': Icons.fitness_center,
        'color': Colors.green,
      },
      {
        'type': 'event',
        'urgency': 'medium',
        'title': 'Bellator Champions Series — Paris',
        'subtitle': 'May 17 • Accor Arena, Paris',
        'source': 'Verified Promoter',
        'action': 'Watch',
        'icon': Icons.live_tv,
        'color': AppTheme.neonCyan,
      },
      {
        'type': 'safety',
        'urgency': 'low',
        'title': 'Ringside Physician Standards 2026',
        'subtitle': 'Updated protocols • Association of Ringside Physicians',
        'source': 'DataFightCentral',
        'action': 'Learn More',
        'icon': Icons.health_and_safety,
        'color': Colors.blue,
      },
      {
        'type': 'opportunity',
        'urgency': 'high',
        'title': 'Short Notice — 70 kg / 155 lbs Lightweight',
        'subtitle': 'Apr 8 • Hex Fight Series, Melbourne',
        'source': 'Fighter Request',
        'action': 'Contact',
        'icon': Icons.sports_mma,
        'color': Colors.orange,
      },
      {
        'type': 'opportunity',
        'urgency': 'high',
        'title': 'Open Tryouts — Future International Stars',
        'subtitle':
            'Lagos • Nairobi • Mumbai • Auckland • Port Moresby • Honiara qualifiers spotlight world-class talent for Melbourne, Gold Coast, and Tokyo events',
        'source': 'DFC Open Network',
        'action': 'Enter',
        'icon': Icons.emoji_events_outlined,
        'color': DesignTokens.neonGold,
        'ctaUrl': 'https://datafightcentral.com/international-contenders',
      },
      {
        'type': 'event',
        'urgency': 'medium',
        'title': 'Open Global Showcase Nights',
        'subtitle':
            'Destination cards built from verified regional pathways and partner promotions',
        'source': 'DFC Event Network',
        'action': 'View Calendar',
        'icon': Icons.public,
        'color': Colors.green,
        'ctaUrl': 'https://datafightcentral.com/global-showcase-calendar',
      },
    ];
    // Cycle through extra signals based on current count
    final startIdx = currentCount % extraSignals.length;
    final batch = <Map<String, dynamic>>[];
    for (int i = 0; i < 5; i++) {
      batch.add(
        Map<String, dynamic>.from(
          extraSignals[(startIdx + i) % extraSignals.length],
        ),
      );
    }
    return batch;
  }
}

/// Individual FightWire Signal Card
class _FightWireSignalCard extends StatelessWidget {
  final Map<String, dynamic> signal;

  const _FightWireSignalCard({required this.signal});

  @override
  Widget build(BuildContext context) {
    final Color color = signal['color'] as Color;
    final bool isUrgent = signal['urgency'] == 'high';

    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: isUrgent
              ? color.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: DesignTokens.glassBorderOpacity),
          width: isUrgent ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${signal['title']} — tap action for details'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    signal['icon'] as IconData,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'URGENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              signal['title'] as String,
                              style: TextStyle(
                                color: DesignTokens.textPrimary.withValues(
                                  alpha: 0.95,
                                ),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        signal['subtitle'] as String,
                        style: const TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusPill,
                              ),
                            ),
                            child: Icon(Icons.verified, color: color, size: 10),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            signal['source'] as String,
                            style: TextStyle(
                              color: color.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Button
                OutlinedButton(
                  onPressed: () async {
                    final rawUrl = signal['ctaUrl'] as String?;
                    if (rawUrl != null && rawUrl.isNotEmpty) {
                      final uri = YouTubeService.normalizePublicYoutubeUri(
                        rawUrl,
                        fallbackSearchQuery: signal['title'] as String?,
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                        return;
                      }
                    }

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${signal['action']} — application link coming soon',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    signal['action'] as String,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// ═══════════════════════════════════════════════════════════════════════════
/// Sponsored Post Card — Paid sponsor content injected into the feed
/// ═══════════════════════════════════════════════════════════════════════════
class _SponsoredPostCard extends StatelessWidget {
  final SponsoredPost post;

  const _SponsoredPostCard({required this.post});

  Color get _tierColor {
    switch (post.tier) {
      case SponsorTier.diamond:
        return const Color(0xFF00F5FF); // neonCyan
      case SponsorTier.gold:
        return const Color(0xFFFFD700); // neonGold
      case SponsorTier.silver:
        return Colors.white70;
      case SponsorTier.promoted:
        return const Color(0xFFFF00FF); // neonMagenta
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        SponsorFeedEngine().trackClick(post.id);
        if (post.ctaUrl != null && post.ctaUrl!.isNotEmpty) {
          final uri = YouTubeService.normalizePublicYoutubeUri(
            post.ctaUrl!,
            fallbackSearchQuery: post.title,
          );
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _tierColor.withValues(alpha: 0.08),
              AppTheme.cardBackground,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _tierColor.withValues(alpha: 0.3),
            width: post.tier == SponsorTier.diamond ? 2 : 1,
          ),
        ),
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
                    color: _tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post.tier == SponsorTier.diamond
                            ? Icons.diamond
                            : post.tier == SponsorTier.gold
                            ? Icons.workspace_premium
                            : Icons.campaign,
                        size: 12,
                        color: _tierColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.tier == SponsorTier.diamond
                            ? 'Diamond Sponsor'
                            : post.tier == SponsorTier.gold
                            ? 'Gold Sponsor'
                            : post.tier == SponsorTier.silver
                            ? 'Silver Sponsor'
                            : 'Promoted',
                        style: TextStyle(
                          color: _tierColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            if (post.body != null && post.body!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                post.body!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
            if (post.ctaText != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _tierColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _tierColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  post.ctaText!,
                  style: TextStyle(
                    color: _tierColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Fight News Card — MMA Junkie / Sherdog / DAZN–grade news card
/// Two modes: hero (first card) and compact (subsequent cards)
/// ═══════════════════════════════════════════════════════════════════════════
class _FightNewsCard extends StatelessWidget {
  final FightNewsArticle article;
  final bool isHero;

  const _FightNewsCard({required this.article, this.isHero = false});

  Color get _categoryColor {
    switch (article.category) {
      case NewsSource.ufc:
        return const Color(0xFFD20A0A);
      case NewsSource.boxing:
        return const Color(0xFFFFB300);
      case NewsSource.muayThai:
        return const Color(0xFFFF6D00);
      case NewsSource.kickboxing:
        return const Color(0xFFFF3D00);
      case NewsSource.bareKnuckle:
        return const Color(0xFFFF1744);
      case NewsSource.brawling:
        return const Color(0xFFFF6600);
      case NewsSource.mma:
        return const Color(0xFF00E5FF);
      case NewsSource.rizin:
        return const Color(0xFFFF1744);
      case NewsSource.wrestling:
        return const Color(0xFF2979FF);
      case NewsSource.ringMagazine:
        return const Color(0xFFFFD600);
      case NewsSource.internationalKickboxer:
        return const Color(0xFFAA00FF);
      case NewsSource.espn:
        return const Color(0xFFC62828);
      case NewsSource.local:
        return const Color(0xFF00E676);
      case NewsSource.social:
        return const Color(0xFFFF4081);
    }
  }

  @override
  Widget build(BuildContext context) {
    return isHero ? _buildHeroCard(context) : _buildCompactCard(context);
  }

  // ── HERO CARD: Full-width image, overlay headline — top story treatment ──
  Widget _buildHeroCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _openArticle(context),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(12),
          border: article.isBreaking
              ? Border.all(
                  color: const Color(0xFFD20A0A).withValues(alpha: 0.6),
                  width: 2,
                )
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed image (always renders — sanitizer provides fallback)
            Builder(
              builder: (context) {
                final url = ImageUrlSanitizer.sanitize(article.imageUrl);
                if (ImageAssets.isLocalAsset(url)) {
                  return Image.asset(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(color: const Color(0xFF0D1117)),
                  );
                }
                return DfcNetworkImage(url: url);
              },
            ),

            // Dark gradient overlay for text legibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Top badges row
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  // Source badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _categoryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article.sourceDisplay.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (article.isBreaking) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD20A0A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 6),
                          SizedBox(width: 4),
                          Text(
                            'BREAKING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Time
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article.timeAgo,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom text
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.summary,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Byline row
                    Row(
                      children: [
                        Text(
                          (article.authorName ?? article.source).toUpperCase(),
                          style: TextStyle(
                            color: _categoryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        if (article.viewCount != null) ...[
                          const Icon(
                            Icons.remove_red_eye_outlined,
                            color: Colors.white54,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatCount(article.viewCount!),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (article.commentCount > 0) ...[
                          const Icon(
                            Icons.mode_comment_outlined,
                            color: Colors.white54,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${article.commentCount}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── COMPACT CARD: Dense headline + right thumbnail — MMA Junkie list style ──
  Widget _buildCompactCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _openArticle(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source + time row
                  Row(
                    children: [
                      Text(
                        article.sourceDisplay.toUpperCase(),
                        style: TextStyle(
                          color: _categoryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (article.isBreaking) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD20A0A),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        article.timeAgo,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Headline
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Byline + engagement
                  Row(
                    children: [
                      Text(
                        article.authorName ?? article.source,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      if (article.commentCount > 0) ...[
                        Icon(
                          Icons.mode_comment_outlined,
                          color: Colors.white.withValues(alpha: 0.25),
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${article.commentCount}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Right: thumbnail (always renders — sanitizer provides fallback)
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Builder(
                builder: (context) {
                  final url = ImageUrlSanitizer.sanitize(article.imageUrl);
                  if (ImageAssets.isLocalAsset(url)) {
                    return Image.asset(
                      url,
                      width: 100,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 100,
                        height: 72,
                        color: const Color(0xFF1A1A2E),
                      ),
                    );
                  }
                  return DfcNetworkImage(
                    url: url,
                    width: 100,
                    height: 72,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  Future<void> _openArticle(BuildContext context) async {
    if (article.url != null && article.url!.isNotEmpty) {
      final uri = Uri.parse(article.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(article.title),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// YouTube Video Card — Real combat sports content
/// ═══════════════════════════════════════════════════════════════════════════
class _YouTubeVideoCard extends StatelessWidget {
  final YouTubeVideo video;

  const _YouTubeVideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: DesignTokens.glassBorderOpacity,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openVideo(context),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with play overlay
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DesignTokens.radiusMedium),
                ),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Builder(
                        builder: (context) {
                          final thumbUrl = ImageUrlSanitizer.sanitize(
                            video.thumbnailUrl,
                            fallback: ImageAssets.fightPlaceholder,
                          );
                          if (ImageAssets.isLocalAsset(thumbUrl)) {
                            return Image.asset(
                              thumbUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: Colors.grey.shade900,
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    color: Colors.white54,
                                    size: 48,
                                  ),
                                ),
                              ),
                            );
                          }
                          return DfcNetworkImage(
                            url: thumbUrl,
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Positioned.fill(
                      child: Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                    // Time ago badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          video.timeAgo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // YouTube badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'YouTube',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Video info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: DesignTokens.neonRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusPill,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: DesignTokens.neonRed,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            video.channelTitle,
                            style: TextStyle(
                              color: DesignTokens.neonRed.withValues(
                                alpha: 0.85,
                              ),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusPill,
                            ),
                            border: Border.all(
                              color: DesignTokens.neonRed.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow,
                                color: DesignTokens.neonRed,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Watch',
                                style: TextStyle(
                                  color: DesignTokens.neonRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.parse(video.videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening: ${video.title}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
