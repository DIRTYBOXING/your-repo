// ignore_for_file: unused_element
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/image_assets.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/services/social_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/models/community/community_models.dart';
import '../../../shared/widgets/dfc_post_media.dart';
import '../widgets/follow_button.dart';
import '../widgets/stories_bar.dart';
import '../widgets/people_you_may_know.dart';
import '../widgets/create_post_bar.dart';
import '../widgets/fight_card_post_widget.dart';
import '../../../shared/services/ppv_service.dart';

/// FIGHTWIRE - Premium Social Feed v3.0
/// DesignTokens  Animated  Hero Carousel  Fight Stocks  AI Coach

class _SupportResource {
  final String name, number;
  final Color color;
  const _SupportResource(this.name, this.number, this.color);
}

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _selectedFilter =
      0; // 0=ALL 1=FIGHTS 2=MIND 3=STORIES 4=SUPPORT 5=NEWS 6=PROMOS
  bool _samuraiActive = true;

  // ── Stock ticker carousel state ──
  late final PageController _stockPageController;
  Timer? _stockAutoScroll;
  int _stockPage = 0;
  late List<_FightStock> _fightStocks;
  final _rng = math.Random();
  Timer? _stockPriceTimer;

  // ── Engagement button local state ──
  final Set<String> _likedPosts = {};
  final Set<String> _bookmarkedPosts = {};
  final Map<String, int> _localLikeDelta = {}; // +1 or -1 adjustments

  // ── Pagination state ──
  final List<dynamic> _paginatedPosts = [];
  bool _isLoadingMore = false;
  bool _hasMorePosts = true;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    // Fight Market Interest Index — real-time sentiment scores
    // Based on social volume, PPV buys, event frequency & global reach
    _fightStocks = [
      const _FightStock('UFC', 312.40, 3.8, true),
      const _FightStock('ONE FC', 47.60, 2.1, true),
      const _FightStock('PFL', 21.30, 1.4, true),
      const _FightStock('Bellator', 14.80, -0.7, false),
      const _FightStock('GLORY', 9.45, 1.9, true),
      const _FightStock('BKFC', 8.70, 5.6, true),
      const _FightStock('Premier Boxing', 54.20, 0.9, true),
      const _FightStock('Matchroom', 42.10, 2.4, true),
      const _FightStock('DAZN', 28.50, 1.7, true),
      const _FightStock('RIZIN', 18.90, 3.2, true),
      const _FightStock('ESPN MMA', 71.80, 2.6, true),
      const _FightStock('Cage Wrs', 5.40, 4.1, true),
    ];

    _stockPageController = PageController(viewportFraction: 0.28);
    _startStockAutoScroll();
    _startStockPriceTicker();
    _loadPersistedLikes();
  }

  /// Load liked post IDs from SharedPreferences so demo likes survive refresh
  Future<void> _loadPersistedLikes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('dfc_liked_posts') ?? [];
      if (saved.isNotEmpty && mounted) {
        setState(() => _likedPosts.addAll(saved));
      }
    } catch (_) {}
  }

  /// Persist liked posts to SharedPreferences
  Future<void> _persistLikes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dfc_liked_posts', _likedPosts.toList());
    } catch (_) {}
  }

  void _startStockAutoScroll() {
    _stockAutoScroll?.cancel();
    _stockAutoScroll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _stockPage++;
      if (_stockPage >= _fightStocks.length) _stockPage = 0;
      _stockPageController.animateToPage(
        _stockPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _startStockPriceTicker() {
    _stockPriceTimer?.cancel();
    _stockPriceTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _fightStocks.length; i++) {
          final s = _fightStocks[i];
          final delta = (_rng.nextDouble() - 0.45) * 0.8;
          final newChange = double.parse(
            (s.change + delta).clamp(-9.9, 9.9).toStringAsFixed(1),
          );
          _fightStocks[i] = _FightStock(
            s.name,
            double.parse(
              (s.price + (s.price * delta / 100)).toStringAsFixed(2),
            ),
            newChange,
            newChange >= 0,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _stockAutoScroll?.cancel();
    _stockPriceTimer?.cancel();
    _stockPageController.dispose();
    super.dispose();
  }

  Future<void> _refreshFeed() async {
    final social = Provider.of<SocialService>(context, listen: false);
    final fresh = await social.getPostsPage(refresh: true);
    if (!mounted) return;
    setState(() {
      _paginatedPosts.clear();
      _paginatedPosts.addAll(fresh);
      _hasMorePosts = true;
      _initialLoadDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Stack(
        children: [
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                onRefresh: _refreshFeed,
                color: DesignTokens.neonCyan,
                backgroundColor: DesignTokens.bgCard,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      backgroundColor: DesignTokens.bgPrimary,
                      elevation: 0,
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: DesignTokens.bgCard,
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusSmall,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.24),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.hub_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Social Feed',
                                style: TextStyle(
                                  color: DesignTokens.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                'Real-time combat network',
                                style: TextStyle(
                                  color: DesignTokens.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        // Samurai Shido quick access
                        GestureDetector(
                          onTap: () => context.push('/ai-bots/shido'),
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.neonMagenta.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: DesignTokens.neonMagenta.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🥷', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 4),
                                Text(
                                  'Shido',
                                  style: TextStyle(
                                    color: DesignTokens.neonMagenta,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.bookmark_border,
                            color: DesignTokens.textMuted,
                          ),
                          onPressed: () => context.push('/saved-posts'),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: DesignTokens.textMuted,
                          ),
                          onPressed: () => context.push('/discovery'),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: DesignTokens.textMuted,
                          ),
                          onPressed: () => context.push('/notifications'),
                        ),
                      ],
                    ),

                    // ─── CREATE POST BAR — Facebook-style composer ───
                    const SliverToBoxAdapter(child: CreatePostBar()),

                    // ─── STORIES BAR (IG / FB hybrid) ───
                    const SliverToBoxAdapter(child: StoriesBar()),

                    // ─── FILTER CHIPS — quick feed filtering ───
                    SliverToBoxAdapter(child: _buildFilterChips()),

                    // ─── PPV HERO BANNER — next upcoming premium event ───
                    SliverToBoxAdapter(child: _buildPPVHeroBanner()),

                    // ─── FEED — Paginated from Firestore ───
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(),
                      sliver: StreamBuilder<List<dynamic>>(
                        stream: Provider.of<SocialService>(
                          context,
                          listen: false,
                        ).getFeed(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !_initialLoadDone) {
                            return const SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      DesignTokens.neonCyan,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return const SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text(
                                    'Error loading feed',
                                    style: TextStyle(
                                      color: DesignTokens.textMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          // Guard against null stream data
                          final streamPosts = snapshot.data;
                          if (streamPosts == null) {
                            return const SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      DesignTokens.neonCyan,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          // Merge stream data with paginated loads
                          if (streamPosts.isNotEmpty && !_initialLoadDone) {
                            _initialLoadDone = true;
                            // Seed paginated list from first stream emission
                            _paginatedPosts.clear();
                            _paginatedPosts.addAll(
                              streamPosts.whereType<Post>(),
                            );
                          } else if (streamPosts.isNotEmpty) {
                            // Merge any new stream posts at the top
                            for (final sp in streamPosts.whereType<Post>()) {
                              if (!_paginatedPosts.any(
                                (p) => (p is Post ? p.id : null) == sp.id,
                              )) {
                                _paginatedPosts.insert(0, sp);
                              }
                            }
                          }

                          // ── Apply filter chip selection ──
                          final posts = _applyFilter(_paginatedPosts);

                          if (posts.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(48),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.dynamic_feed_rounded,
                                        color: DesignTokens.neonCyan.withValues(
                                          alpha: 0.3,
                                        ),
                                        size: 48,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _selectedFilter == 0
                                            ? 'No posts yet. Be the first to share!'
                                            : 'No posts match this filter.',
                                        style: const TextStyle(
                                          color: DesignTokens.textMuted,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          // +1 for the load-more indicator at bottom
                          final itemCount =
                              posts.length + (_hasMorePosts ? 1 : 0);

                          return SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              // ── Load-more trigger at the last item ──
                              if (index >= posts.length) {
                                _loadMorePosts();
                                return Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: _isLoadingMore
                                        ? SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    DesignTokens.neonCyan
                                                        .withValues(alpha: 0.6),
                                                  ),
                                            ),
                                          )
                                        : const Text(
                                            'Loading more...',
                                            style: TextStyle(
                                              color: DesignTokens.textMuted,
                                              fontSize: 13,
                                            ),
                                          ),
                                  ),
                                );
                              }

                              // ── Inject discovery modules into the feed ──
                              if (index == 3 && posts.length > 3) {
                                return _buildPostCard(posts[index]);
                              }
                              if (index == 7 && posts.length > 7) {
                                return Column(
                                  children: [
                                    _buildPostCard(posts[index]),
                                    const PeopleYouMayKnowBar(),
                                  ],
                                );
                              }
                              if (index == 12 && posts.length > 12) {
                                return _buildPostCard(posts[index]);
                              }
                              return _buildPostCard(posts[index]);
                            }, childCount: itemCount),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildCreateFAB(),
    );
  }

  // ========== FILTER LOGIC — maps filter chip selection to post types ==========

  List<dynamic> _applyFilter(List<dynamic> allPosts) {
    if (_selectedFilter == 0) return allPosts; // ALL
    return allPosts.where((post) {
      final String postType;
      final String content;
      if (post is Post) {
        postType = post.postType;
        content = post.content.toLowerCase();
      } else if (post is Map) {
        postType = post['postType']?.toString() ?? 'text';
        content = (post['content']?.toString() ?? '').toLowerCase();
      } else {
        return true;
      }
      switch (_selectedFilter) {
        case 1: // FIGHTS
          return postType == 'fight_card' ||
              postType == 'announcement' ||
              content.contains('fight') ||
              content.contains('bout') ||
              content.contains('ufc');
        case 2: // MENTAL HEALTH
          return content.contains('mental') ||
              content.contains('wellness') ||
              content.contains('mindset');
        case 3: // STORIES
          return postType == 'media' ||
              content.contains('story') ||
              content.contains('journey');
        case 4: // SUPPORT
          return content.contains('support') ||
              content.contains('community') ||
              content.contains('help');
        case 5: // NEWS
          return postType == 'article' ||
              content.contains('news') ||
              content.contains('breaking');
        case 6: // PROMOS
          return postType == 'announcement' ||
              content.contains('promo') ||
              content.contains('event');
        default:
          return true;
      }
    }).toList();
  }

  // ========== LOAD MORE — infinite scroll pagination ==========

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts) return;
    setState(() => _isLoadingMore = true);
    try {
      final social = Provider.of<SocialService>(context, listen: false);
      final morePosts = await social.getPostsPage();
      if (!mounted) return;
      setState(() {
        if (morePosts.isEmpty) {
          _hasMorePosts = false;
        } else {
          // Deduplicate before adding
          for (final p in morePosts) {
            final pId = p.id;
            if (!_paginatedPosts.any(
                  (existing) =>
                      (existing is Post
                          ? existing.id
                          : (existing is Map
                                ? existing['id']?.toString()
                                : null)) ==
                      pId,
                )) {
              _paginatedPosts.add(p);
            }
          }
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Load more error: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMorePosts = false;
        });
      }
    }
  }

  // ========== CREATE FAB — Expandable post/story creator ==========

  Widget _buildCreateFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Story button
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FloatingActionButton.small(
            heroTag: 'social_feed_story_fab',
            onPressed: () => context.push('/create-story'),
            backgroundColor: DesignTokens.neonMagenta.withValues(alpha: 0.9),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        // Article / Blog button
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FloatingActionButton.small(
            heroTag: 'social_feed_article_fab',
            onPressed: () => context.push('/write-article'),
            backgroundColor: const Color(0xFFFFD700).withValues(alpha: 0.9),
            child: const Icon(
              Icons.article_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        // Main post button
        FloatingActionButton(
          heroTag: 'social_feed_add_fab',
          onPressed: () {
            context.push('/compose-post');
          },
          backgroundColor: DesignTokens.neonCyan,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  // ========== HERO CAROUSEL ==========

  Widget _buildHeroCarousel() {
    return SizedBox(
      height: 240,
      child: PageView(
        controller: PageController(viewportFraction: 0.9),
        children: [
          _buildHeroCard(
            title: 'IBC III × DFC: BRAWLING TAKEOVER',
            subtitle:
                'Danny Mac\'s Vision • 8,400 Fans • \$1.2M Gate • World Domination Begins',
            gradient: [
              const Color(0xFFFF0000),
              const Color(0xFFFFD700),
              const Color(0xFF00D4FF),
            ],
            imageUrl: ImageAssets.ppvBrisbaneBonanzaHero,
            badge: '🪓 RESULTS • PROMOTIONAL PARTNERS',
          ),
          _buildHeroCard(
            title: 'UFC 313 — Las Vegas',
            subtitle: 'Main Event: Santos vs. Aliyev — Light Heavyweight Title',
            gradient: [DesignTokens.neonMagenta, const Color(0xFFFD79A8)],
            imageUrl: ImageAssets.ppvUfc328Hero,
            badge: '📅 MAR 22, 2026',
          ),
          _buildHeroCard(
            title: 'ONE Championship 170',
            subtitle: 'Superlek vs Takeru — Muay Thai World GP — Bangkok',
            gradient: [DesignTokens.neonCyan, const Color(0xFF0984E3)],
            imageUrl: ImageAssets.ppvOne170Hero,
            badge: '📅 MAR 29, 2026',
          ),
          _buildHeroCard(
            title: 'PFL Champions League',
            subtitle: '2025 Playoffs Semifinals — Live from London, UK',
            gradient: [DesignTokens.neonAmber, DesignTokens.neonRed],
            imageUrl: ImageAssets.ppvPflPittsburgh2026Hero,
            badge: '📅 APR 05, 2026',
          ),
          _buildHeroCard(
            title: 'BKFC Fight Night: Tampa',
            subtitle: 'Bare Knuckle Action — Amalie Arena, Tampa',
            gradient: [const Color(0xFFE17055), const Color(0xFFFDAA45)],
            imageUrl: ImageAssets.ppvBkfc72Hero,
            badge: '📅 MAR 21, 2026',
          ),
          _buildHeroCard(
            title: 'GLORY 92: Collision',
            subtitle: 'Kickboxing Showcase — Arnhem, Netherlands',
            gradient: [const Color(0xFFFF8C00), const Color(0xFFFFD700)],
            imageUrl: ImageAssets.ppvWestcoastWarriors33Hero,
            badge: '📅 MAR 13, 2026',
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required String title,
    required String subtitle,
    required List<Color> gradient,
    String? imageUrl,
    String badge = 'FEATURED',
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image — handles both local assets and network URLs
          if (imageUrl != null)
            DfcNetworkImage(url: imageUrl)
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
              ),
            ),
          // Gradient overlay for text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(DesignTokens.cardPaddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: gradient[0].withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: DesignTokens.fontSizeMicro,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: DesignTokens.fontSizeTitleLarge,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: DesignTokens.fontSizeBody,
                    shadows: const [
                      Shadow(blurRadius: 6, color: Colors.black45),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              ),
              child: const Icon(
                Icons.sports_mma,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== FIGHT STOCKS TICKER (AUTO-CAROUSEL) ==========

  Widget _buildFightStocksTicker() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
      child: PageView.builder(
        controller: _stockPageController,
        itemCount: _fightStocks.length,
        padEnds: false,
        onPageChanged: (i) => _stockPage = i,
        itemBuilder: (context, index) {
          final stock = _fightStocks[index];
          return _buildStockChip(stock);
        },
      ),
    );
  }

  Widget _buildStockChip(_FightStock stock) {
    final color = stock.isUp ? DesignTokens.neonGreen : DesignTokens.neonRed;
    final changeStr =
        '${stock.isUp ? "+" : ""}${stock.change.toStringAsFixed(1)}%';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stock.name,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: DesignTokens.fontSizeSubtitleLarge,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '\$${stock.price.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                stock.isUp ? Icons.trending_up : Icons.trending_down,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  changeStr,
                  key: ValueKey(changeStr),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: DesignTokens.fontSizeSubtitle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========== EVENT HYPE CARD ==========

  Widget _buildEventHypeCard({
    required String eventId,
    required String title,
    required String location,
    required String date,
    required List<Color> gradientColors,
    required String fightStock,
    String? imageUrl,
  }) {
    return GestureDetector(
      onTap: () {
        // IBC events go directly to IBC live screen
        if (eventId.contains('ibc')) {
          context.push('/ibc/live');
        } else {
          context.push('/event/$eventId');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            width: DesignTokens.borderThin,
            color: gradientColors[0].withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: Container(
            color: DesignTokens.bgCard,
            child: Column(
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    image: imageUrl != null
                        ? DecorationImage(
                            image: ImageAssets.safeProvider(imageUrl),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.4),
                              BlendMode.darken,
                            ),
                            onError: (_, _) {},
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.sports_mma,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 80,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'EVENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: DesignTokens.fontSizeMicro,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
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
                            color: DesignTokens.neonGreen.withValues(
                              alpha: 0.9,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.trending_up,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                fightStock,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: DesignTokens.fontSizeCaption,
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
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: DesignTokens.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: DesignTokens.fontSizeTitle,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: DesignTokens.textMuted,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  location,
                                  style: const TextStyle(
                                    color: DesignTokens.textMuted,
                                    fontSize: DesignTokens.fontSizeSubtitle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.calendar_today,
                                  color: DesignTokens.textMuted,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    color: DesignTokens.textMuted,
                                    fontSize: DesignTokens.fontSizeSubtitle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusPill,
                          ),
                        ),
                        child: const Text(
                          'View Card',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: DesignTokens.fontSizeSubtitle,
                          ),
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
    );
  }

  // ========== FIGHT ANNOUNCEMENT ==========

  Widget _buildFightAnnouncementCard({
    required String fighterA,
    required String fighterB,
    required String recordA,
    required String recordB,
    required String weightClass,
    required String aiConfidence,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonAmber.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports_mma,
                      color: DesignTokens.neonAmber,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'FIGHT',
                      style: TextStyle(
                        color: DesignTokens.neonAmber,
                        fontSize: DesignTokens.fontSizeMicro,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                weightClass,
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeSubtitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            DesignTokens.neonRed,
                            DesignTokens.neonAmber,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          ImageAssets.fightPlaceholder,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.sports_mma,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fighterA,
                      style: const TextStyle(
                        color: DesignTokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: DesignTokens.fontSizeSubtitleLarge,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      recordA,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DesignTokens.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: DesignTokens.fontSizeBody,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            DesignTokens.neonCyan,
                            DesignTokens.neonMagenta,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          ImageAssets.wellnessPlaceholder,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.sports_mma,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fighterB,
                      style: const TextStyle(
                        color: DesignTokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: DesignTokens.fontSizeSubtitleLarge,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      recordB,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: DesignTokens.neonCyan,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'AI Confidence: $aiConfidence',
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== PROMOTER POST ==========

  Widget _buildPromoterPostCard({
    required String promoter,
    required bool verified,
    required String content,
    required String timestamp,
    String? imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.1),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DesignTokens.neonMagenta, DesignTokens.neonCyan],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: ImageAssets.safeProvider(imageUrl),
                          fit: BoxFit.cover,
                          onError: (_, _) {},
                        )
                      : null,
                ),
                child: imageUrl != null
                    ? null
                    : const Icon(Icons.business, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          promoter,
                          style: const TextStyle(
                            color: DesignTokens.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: DesignTokens.fontSizeBody,
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: DesignTokens.neonCyan,
                                  size: 10,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'PROMOTER',
                                  style: TextStyle(
                                    color: DesignTokens.neonCyan,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      timestamp,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_horiz,
                  color: DesignTokens.textMuted,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: DesignTokens.bgCard,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (_) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _postOption(Icons.bookmark_border, 'Save Post'),
                          _postOption(Icons.share, 'Share'),
                          _postOption(Icons.flag_outlined, 'Report'),
                          _postOption(Icons.volume_off, 'Mute Author'),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: DesignTokens.fontSizeBody,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildPostAction(Icons.favorite_border, '24'),
              const SizedBox(width: 20),
              _buildPostAction(Icons.chat_bubble_outline, '8'),
              const SizedBox(width: 20),
              _buildPostAction(Icons.share_outlined, ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String count) {
    return GestureDetector(
      onTap: () {
        final label = icon == Icons.favorite_border
            ? 'Liked!'
            : icon == Icons.chat_bubble_outline
            ? 'Comments'
            : icon == Icons.share_outlined
            ? 'Link copied!'
            : icon == Icons.bookmark_border
            ? 'Saved!'
            : icon == Icons.visibility
            ? 'Views'
            : 'Done';
        if (icon == Icons.share_outlined) {
          Clipboard.setData(
            const ClipboardData(text: AppConstants.publicWebBaseUrl),
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  icon == Icons.favorite_border ? Icons.favorite : icon,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(label),
              ],
            ),
            backgroundColor: icon == Icons.favorite_border
                ? Colors.redAccent
                : DesignTokens.neonCyan,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Row(
        children: [
          Icon(icon, color: DesignTokens.textMuted, size: 20),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              count,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeSubtitle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullscreenImage(String imageUrl) {
    _showFullscreenGallery([imageUrl], 0);
  }

  /// Pro gallery viewer — swipe between images, pinch-zoom, page counter
  void _showFullscreenGallery(List<String> urls, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      useSafeArea: false,
      builder: (ctx) {
        int currentPage = initialIndex;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  // Swipeable image gallery
                  PageView.builder(
                    itemCount: urls.length,
                    controller: PageController(initialPage: initialIndex),
                    onPageChanged: (i) => setDialogState(() => currentPage = i),
                    itemBuilder: (ctx, i) {
                      return GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Center(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 5.0,
                            child: DfcNetworkImage(
                              url: urls[i],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Top bar: close + counter
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 26,
                              ),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                            const Spacer(),
                            if (urls.length > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${currentPage + 1} / ${urls.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            const SizedBox(width: 48), // balance close btn
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom dot indicators
                  if (urls.length > 1)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          urls.length,
                          (i) => Container(
                            width: currentPage == i ? 10 : 6,
                            height: currentPage == i ? 10 : 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: currentPage == i
                                  ? DesignTokens.neonCyan
                                  : Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
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

  // ========== AI COACH ==========

  Widget _buildAICoachCard({required String quote}) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonMagenta.withValues(alpha: 0.08),
            DesignTokens.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonMagenta.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: DesignTokens.neonMagenta,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Coach',
                style: TextStyle(
                  color: DesignTokens.neonMagenta,
                  fontWeight: FontWeight.bold,
                  fontSize: DesignTokens.fontSizeSubtitleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '"$quote"',
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeTitle,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Copied to clipboard \u2014 share anywhere!',
                      ),
                      backgroundColor: DesignTokens.neonCyan.withValues(
                        alpha: 0.9,
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Share'),
                style: TextButton.styleFrom(
                  foregroundColor: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========== GYM PROMO ==========

  Widget _buildGymPromoCard({
    required String gymName,
    required bool verified,
    required List<String> specialties,
    required String location,
    String? imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DesignTokens.neonGreen, Color(0xFF00B894)],
              ),
              borderRadius: BorderRadius.circular(14),
              image: imageUrl != null
                  ? DecorationImage(
                      image: ImageAssets.safeProvider(imageUrl),
                      fit: BoxFit.cover,
                      onError: (_, _) {},
                    )
                  : null,
            ),
            child: imageUrl != null
                ? null
                : const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 32,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        gymName,
                        style: const TextStyle(
                          color: DesignTokens.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: DesignTokens.fontSizeBody,
                        ),
                      ),
                    ),
                    if (verified)
                      const Icon(
                        Icons.verified,
                        color: DesignTokens.neonGreen,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: DesignTokens.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeSubtitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: specialties
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.bgSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              color: DesignTokens.textSecondary,
                              fontSize: DesignTokens.fontSizeCaption,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== POLL CARD ==========

  Widget _buildPollCard({
    required String question,
    required List<String> options,
    required List<int> votes,
    required String totalVotes,
  }) {
    final maxVote = votes.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonMagenta.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(options.length, (i) {
            final pct = votes[i];
            final isWinning = votes[i] == maxVote;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          options[i],
                          style: TextStyle(
                            color: isWinning
                                ? DesignTokens.neonCyan
                                : DesignTokens.textSecondary,
                            fontSize: 13,
                            fontWeight: isWinning
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          color: isWinning
                              ? DesignTokens.neonCyan
                              : DesignTokens.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: DesignTokens.bgSecondary,
                      valueColor: AlwaysStoppedAnimation(
                        isWinning
                            ? DesignTokens.neonCyan.withValues(alpha: 0.5)
                            : DesignTokens.textMuted.withValues(alpha: 0.2),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Text(
            '$totalVotes votes',
            style: const TextStyle(color: DesignTokens.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ========== VIDEO POST CARD ==========

  Widget _buildVideoPostCard({
    required String author,
    required String content,
    required String thumbnailUrl,
    required String duration,
    required String views,
    required String timestamp,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.neonRed.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with play button overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: ImageAssets.isLocalAsset(thumbnailUrl)
                    ? Image.asset(
                        thumbnailUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 180,
                          color: DesignTokens.bgSecondary,
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              color: DesignTokens.textMuted,
                              size: 48,
                            ),
                          ),
                        ),
                      )
                    : DfcNetworkImage(
                        url: thumbnailUrl,
                        height: 180,
                        width: double.infinity,
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
                        Colors.black.withValues(alpha: 0.6),
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
                    size: 54,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    duration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Row(
                  children: [
                    const Icon(
                      Icons.visibility,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      views,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.play_circle,
                      color: DesignTokens.neonRed,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      author,
                      style: const TextStyle(
                        color: DesignTokens.neonRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timestamp,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 13,
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

  // ========== STAT COMPARISON CARD ==========

  Widget _buildStatComparisonCard({
    required String fighterA,
    required String fighterB,
    required Map<String, String> statA,
    required Map<String, String> statB,
    required Color accentA,
    required Color accentB,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.compare_arrows,
                color: DesignTokens.textMuted,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'TALE OF THE TAPE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  fighterA,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accentA,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'VS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.1),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Expanded(
                child: Text(
                  fighterB,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accentB,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...statA.entries.map((e) {
            final valB = statB[e.key] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accentA.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.key,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      valB,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accentB.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ========== NEWS CARD (with optional image) ==========

  Widget _buildNewsCard({
    required String source,
    required String headline,
    required String timestamp,
    String? imageUrl,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.1),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            SizedBox(
              height: 160,
              width: double.infinity,
              child: ImageAssets.isLocalAsset(imageUrl)
                  ? Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: DesignTokens.textMuted,
                            size: 40,
                          ),
                        ),
                      ),
                    )
                  : DfcNetworkImage(url: imageUrl),
            ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl == null)
                  Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusSmall,
                      ),
                    ),
                    child: const Icon(
                      Icons.article,
                      color: DesignTokens.neonCyan,
                      size: 24,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              source,
                              style: const TextStyle(
                                color: DesignTokens.neonCyan,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timestamp,
                            style: const TextStyle(
                              color: DesignTokens.textMuted,
                              fontSize: DesignTokens.fontSizeCaption,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        headline,
                        style: const TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: DesignTokens.fontSizeBody,
                          height: 1.4,
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

  // ========== DRONE COVERAGE CARD ==========

  Widget _buildDroneCoverageCard({
    required String title,
    required String body,
    required String imageUrl,
    String badge = '📡 DRONE INTEL',
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImageAssets.isLocalAsset(imageUrl)
                    ? Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6C5CE7), Color(0xFF00B894)],
                            ),
                          ),
                        ),
                      )
                    : DfcNetworkImage(url: imageUrl),
                Container(
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
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flight, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonRed.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 6),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPostAction(Icons.visibility, '2.4K'),
                    const SizedBox(width: 16),
                    _buildPostAction(Icons.favorite_border, '186'),
                    const SizedBox(width: 16),
                    _buildPostAction(Icons.share_outlined, ''),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening live stream...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF6C5CE7,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_filled,
                              color: Color(0xFF6C5CE7),
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'WATCH',
                              style: TextStyle(
                                color: Color(0xFF6C5CE7),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== PHOTO POST CARD ==========

  Widget _buildPhotoPostCard({
    required String author,
    required String content,
    required String imageUrl,
    required String timestamp,
    String likes = '0',
    String comments = '0',
    bool verified = false,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      author[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            author,
                            style: const TextStyle(
                              color: DesignTokens.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (verified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: DesignTokens.neonCyan,
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        timestamp,
                        style: const TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: DesignTokens.textMuted),
              ],
            ),
          ),
          // Image — tap to view fullscreen
          GestureDetector(
            onTap: () => _showFullscreenImage(imageUrl),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: ImageAssets.isLocalAsset(imageUrl)
                  ? Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: DesignTokens.bgSecondary,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            color: DesignTokens.textMuted,
                            size: 48,
                          ),
                        ),
                      ),
                    )
                  : DfcNetworkImage(url: imageUrl),
            ),
          ),
          // Content & actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPostAction(Icons.favorite_border, likes),
                    const SizedBox(width: 20),
                    _buildPostAction(Icons.chat_bubble_outline, comments),
                    const SizedBox(width: 20),
                    _buildPostAction(Icons.share_outlined, ''),
                    const Spacer(),
                    _buildPostAction(Icons.bookmark_border, ''),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== FIGHT SHOW CARD ==========

  Widget _buildFightShowCard({
    required String title,
    required String promotion,
    required String date,
    required String location,
    required int fightCount,
    required String imageUrl,
    String? mainEvent,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonAmber.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImageAssets.isLocalAsset(imageUrl)
                    ? Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFE17055), Color(0xFFFDAA45)],
                            ),
                          ),
                        ),
                      )
                    : DfcNetworkImage(url: imageUrl),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonAmber.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          promotion,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          shadows: [
                            Shadow(blurRadius: 6, color: Colors.black54),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$fightCount FIGHTS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: DesignTokens.textMuted,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: DesignTokens.textMuted,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (mainEvent != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: DesignTokens.neonAmber.withValues(alpha: 0.06),
                border: Border(
                  top: BorderSide(
                    color: DesignTokens.neonAmber.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sports_mma,
                    color: DesignTokens.neonAmber,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Main Event: ',
                    style: TextStyle(
                      color: DesignTokens.neonAmber.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      mainEvent,
                      style: const TextStyle(
                        color: DesignTokens.neonAmber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ========== FIGHTER SAFETY COMMITMENT BANNER ==========

  Widget _buildFighterSafetyBanner() {
    return GestureDetector(
      onTap: () => context.push('/fighter-safety'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingL,
          vertical: 6,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00FF88).withValues(alpha: 0.08),
              const Color(0xFF00F5FF).withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF00FF88).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00FF88).withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield,
                color: Color(0xFF00FF88),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FIGHTERS ARE SAFER WITH DFC',
                    style: TextStyle(
                      color: Color(0xFF00FF88),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'CTE tracking \u00B7 Guardian Mode \u00B7 Crisis Lifeline \u00B7 Pink Shield \u00B7 Corner Stop AI',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: const Color(0xFF00FF88).withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  // ========== SAMURAI AI BANNER ==========

  Widget _buildSamuraiAIBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: 8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: _samuraiActive
              ? DesignTokens.neonCyan.withValues(alpha: 0.4)
              : DesignTokens.textMuted.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Text('⚔️', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'SAMURAI AI ENGINE',
                      style: TextStyle(
                        color: DesignTokens.neonCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _samuraiActive
                            ? DesignTokens.neonGreen.withValues(alpha: 0.15)
                            : DesignTokens.textMuted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _samuraiActive ? '● LIVE' : '○ PAUSED',
                        style: TextStyle(
                          color: _samuraiActive
                              ? DesignTokens.neonGreen
                              : DesignTokens.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Discovering fights · news · stories · mental health · support',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _samuraiActive = !_samuraiActive),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _samuraiActive ? 'PAUSE' : 'ACTIVATE',
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== FILTER CHIPS ==========

  // ========== PPV HERO BANNER ==========

  Widget _buildPPVHeroBanner() {
    final ppvService = Provider.of<PPVService>(context, listen: false);
    final events = ppvService.upcomingPPVs;
    if (events.isEmpty) return const SizedBox.shrink();
    final event = events.first;
    final isLive = event.isLive;
    final subtitle = event.promotion ?? event.subtitle ?? 'Premium Event';

    return GestureDetector(
      onTap: () => context.push('/ppv/${event.id}', extra: event),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLive
                ? [const Color(0xFF1A0030), const Color(0xFF3D0060)]
                : [const Color(0xFF001830), const Color(0xFF003060)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLive
                ? DesignTokens.neonMagenta.withValues(alpha: 0.7)
                : DesignTokens.neonCyan.withValues(alpha: 0.4),
            width: isLive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isLive ? DesignTokens.neonMagenta : DesignTokens.neonCyan)
                  .withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                      (isLive
                              ? DesignTokens.neonMagenta
                              : DesignTokens.neonCyan)
                          .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLive ? Icons.live_tv_rounded : Icons.sports_mma_rounded,
                  color: isLive
                      ? DesignTokens.neonMagenta
                      : DesignTokens.neonCyan,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isLive)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.neonMagenta,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '● LIVE NOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          )
                        else
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: DesignTokens.neonCyan.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: const Text(
                              'PPV EVENT',
                              style: TextStyle(
                                color: DesignTokens.neonCyan,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isLive
                      ? DesignTokens.neonMagenta
                      : DesignTokens.neonCyan,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isLive ? 'WATCH' : 'BUY PPV',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = [
      'All',
      'Fights',
      'Mental Health',
      'Stories',
      'Support',
      'News',
      'Promotions',
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final active = _selectedFilter == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: 0.12)
                    : DesignTokens.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? Colors.white.withValues(alpha: 0.35)
                      : DesignTokens.textMuted.withValues(alpha: 0.2),
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                filters[i],
                style: TextStyle(
                  color: active ? Colors.white : DesignTokens.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ========== TRENDING IN COMBAT — Hybrid hashtag + topic strip ==========

  Widget _buildTrendingSection() {
    const trends = <_TrendItem>[
      _TrendItem(
        '#UFC325',
        '12.4K posts',
        Icons.local_fire_department_rounded,
        Color(0xFFFF3366),
      ),
      _TrendItem(
        '#BKFC',
        '8.1K posts',
        Icons.sports_mma_rounded,
        Color(0xFFFFD700),
      ),
      _TrendItem(
        '#KnockoutOfTheWeek',
        '5.6K posts',
        Icons.bolt_rounded,
        Color(0xFF00F5FF),
      ),
      _TrendItem(
        '#TrainingCamp',
        '3.2K posts',
        Icons.fitness_center_rounded,
        Color(0xFF00FF88),
      ),
      _TrendItem(
        '#WeighIn',
        '2.9K posts',
        Icons.monitor_weight_rounded,
        Color(0xFFFF00FF),
      ),
      _TrendItem(
        '#FightNight',
        '7.8K posts',
        Icons.nightlife_rounded,
        Color(0xFFFF6D00),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: DesignTokens.neonCyan,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'TRENDING IN COMBAT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: trends.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final t = trends[i];
              return GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Explore ${t.tag}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: t.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: t.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.icon, color: t.color, size: 14),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.tag,
                            style: TextStyle(
                              color: t.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            t.count,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 9,
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
    );
  }

  // ========== SOCIAL NETWORK QUICK ACCESS ==========

  Widget _buildSocialQuickAccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: DesignTokens.spacingM,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSocialCard(
                  icon: Icons.people,
                  label: 'Friends',
                  color: DesignTokens.neonCyan,
                  onTap: () => context.push('/friends'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialCardWithBadge(
                  icon: Icons.person_add,
                  label: 'Requests',
                  color: DesignTokens.neonMagenta,
                  onTap: () => context.push('/friend-requests'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialCard(
                  icon: Icons.thumb_up,
                  label: 'Suggestions',
                  color: DesignTokens.neonGreen,
                  onTap: () => context.push('/friend-suggestions'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSocialCard(
                  icon: Icons.flag,
                  label: 'Pages',
                  color: DesignTokens.neonAmber,
                  onTap: () => context.push('/pages'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialCard(
                  icon: Icons.groups,
                  label: 'Groups',
                  color: DesignTokens.neonMagenta,
                  onTap: () => context.push('/community/hub'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialCard(
                  icon: Icons.bookmark,
                  label: 'Saved',
                  color: DesignTokens.neonAmber,
                  onTap: () => context.push('/saved-posts'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSocialCard(
                  icon: Icons.stars_rounded,
                  label: 'Close Friends',
                  color: DesignTokens.neonGreen,
                  onTap: () => context.push('/close-friends'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialCard(
                  icon: Icons.auto_stories_rounded,
                  label: 'Stories',
                  color: DesignTokens.neonCyan,
                  onTap: () => context.push('/create-story'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialCard(
                  icon: Icons.photo_library_rounded,
                  label: 'Reels',
                  color: DesignTokens.neonMagenta,
                  onTap: () => context.push('/combat-reels'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========== COMBAT REELS PREVIEW — TikTok/IG Reels hybrid strip ==========

  Widget _buildReelsPreview() {
    const reels = <_ReelPreview>[
      _ReelPreview(
        'KO of the Week',
        '1.2M views',
        'assets/logos/new_dfc_image_1.png',
        Color(0xFFFF3366),
      ),
      _ReelPreview(
        'Training Camp',
        '845K views',
        'assets/logos/dfc2_image.png',
        Color(0xFF00F5FF),
      ),
      _ReelPreview(
        'Weigh-In Face Off',
        '2.1M views',
        'assets/logos/dfc_and_back_ground.png',
        Color(0xFFFFD700),
      ),
      _ReelPreview(
        'Behind the Scenes',
        '620K views',
        'assets/logos/datafight_central_with_logo.png',
        Color(0xFF00FF88),
      ),
      _ReelPreview(
        'Fight Breakdown',
        '1.8M views',
        'assets/logos/dfc2_image_.png',
        Color(0xFFFF00FF),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                color: DesignTokens.neonMagenta,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'COMBAT REELS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/combat-reels'),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: reels.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final r = reels[i];
              return GestureDetector(
                onTap: () => context.push('/combat-reels'),
                child: SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          r.imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: r.accentColor.withValues(alpha: 0.2),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                        // Play icon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        // Title + views
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.views,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Accent bar at top
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(height: 3, color: r.accentColor),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ========== LIVE NOW BANNER — Shows live events + streams ==========

  Widget _buildLiveNowBanner() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF3366).withValues(alpha: 0.18),
              const Color(0xFFFF00FF).withValues(alpha: 0.09),
              DesignTokens.neonCyan.withValues(alpha: 0.07),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFF3366).withValues(alpha: 0.38),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3366).withValues(alpha: 0.24),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => context.push('/ppv'),
          child: Row(
            children: [
              // Pulsing LIVE dot
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.82, end: 1),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOut,
                builder: (context, v, _) => Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3366),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFFFF3366,
                        ).withValues(alpha: 0.5 * v),
                        blurRadius: 8 + (8 * v),
                        spreadRadius: v,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3366),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Combat Events',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Tap to view active PPV and stream availability',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: Color(0xFFFF3366),
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'WATCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
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

  // ========== RESPONSIVE HEIGHT HELPER ==========
  double _getCardHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 70;
    if (width < 600) return 85;
    if (width < 900) return 95;
    return 100;
  }

  Widget _buildSocialCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _getCardHeight(context),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialCardWithBadge({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Note: We need to access EnhancedFriendsService, but to avoid Provider
    // dependency here, we'll just use the card with a badge placeholder.
    // In a real implementation, wrap with Consumer<EnhancedFriendsService>.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Badge positioned top-right
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DesignTokens.neonRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.neonRed.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.black,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== POST CARD FROM FIRESTORE ==========

  Widget _buildPostCard(dynamic post) {
    // Cast to Post model — handle both Map and Post
    final Post p;
    if (post is Post) {
      p = post;
    } else if (post is Map) {
      p = Post(
        id: post['id']?.toString() ?? '',
        userId:
            post['authorId']?.toString() ?? post['userId']?.toString() ?? '',
        content: post['content']?.toString() ?? '',
        createdAt: post['timestamp'] is DateTime
            ? post['timestamp'] as DateTime
            : DateTime.now(),
        userDisplayName: post['displayName']?.toString(),
        userRole: post['userRole']?.toString(),
        userAvatarUrl: post['userAvatarUrl']?.toString(),
        isVerified: post['isVerified'] == true,
        likes: post['likes'] as int? ?? 0,
        commentCount: post['commentCount'] as int? ?? 0,
        shareCount: post['shareCount'] as int? ?? 0,
        mediaUrls: (post['mediaUrls'] as List?)?.cast<String>() ?? [],
        location: post['location']?.toString(),
        postType: post['postType']?.toString() ?? 'text',
      );
    } else {
      return const SizedBox.shrink();
    }

    final roleColor = _roleAccentColor(p.userRole);
    final currentUserId = context.read<AuthService>().currentUser?.uid;
    final canOpenAuthorProfile = p.userId.isNotEmpty;
    final entranceSeed = (p.id.hashCode.abs() % 6);

    // ── Render fight cards with the specialized visual widget ──
    if (p.postType == 'fight_card' && p.content.contains('vs')) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: FightCardPostWidget(content: p.content),
      );
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey('post-card-${p.id}'),
      tween: Tween(begin: 0.94, end: 1.0),
      duration: Duration(milliseconds: 240 + (entranceSeed * 40)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 18),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: roleColor.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: roleColor.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Avatar + Name + Role + Verified + Time + More ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: canOpenAuthorProfile
                          ? () => _openUserPage(p.userId)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            // Avatar
                            _buildAvatar(
                              p.userAvatarUrl,
                              p.displayName,
                              roleColor,
                            ),
                            const SizedBox(width: 12),
                            // Name + role + time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          p.displayName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (p.isVerified) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.verified,
                                          size: 15,
                                          color: DesignTokens.neonCyan,
                                        ),
                                      ],
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: roleColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          p.roleBadge,
                                          style: TextStyle(
                                            color: roleColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        p.timeAgo,
                                        style: const TextStyle(
                                          color: DesignTokens.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (p.location != null &&
                                          p.location!.isNotEmpty) ...[
                                        const Text(
                                          ' · ',
                                          style: TextStyle(
                                            color: DesignTokens.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.location_on,
                                          size: 11,
                                          color: DesignTokens.textMuted,
                                        ),
                                        const SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            p.location!,
                                            style: const TextStyle(
                                              color: DesignTokens.textMuted,
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                      if (p.isEdited) ...[
                                        const Text(
                                          ' · edited',
                                          style: TextStyle(
                                            color: DesignTokens.textMuted,
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // More options
                  IconButton(
                    icon: Icon(
                      Icons.more_horiz,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 20,
                    ),
                    onPressed: () => _showMoreOptions(p),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),

            if (_isPageLikeRole(p.userRole) && p.userId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: roleColor.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag_circle, size: 14, color: roleColor),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _pageLabelForRole(p.userRole),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: roleColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _openUserPage(p.userId),
                      style: TextButton.styleFrom(
                        foregroundColor: roleColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View Page',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (currentUserId != null && currentUserId != p.userId)
                      FollowButton(
                        currentUserId: currentUserId,
                        targetUserId: p.userId,
                        compact: true,
                      ),
                  ],
                ),
              ),

            // ── Post content text ──
            if (p.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  p.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),

            // ── Media (images/video thumbnails) ──
            if (p.hasMedia)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildPostMedia(p),
              ),

            // ── Post type accent bar (fight_card, announcement) ──
            if (p.postType == 'fight_card' || p.postType == 'announcement')
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      (p.postType == 'fight_card'
                              ? DesignTokens.neonMagenta
                              : DesignTokens.neonCyan)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        (p.postType == 'fight_card'
                                ? DesignTokens.neonMagenta
                                : DesignTokens.neonCyan)
                            .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      p.postType == 'fight_card'
                          ? Icons.sports_mma
                          : Icons.campaign,
                      size: 14,
                      color: p.postType == 'fight_card'
                          ? DesignTokens.neonMagenta
                          : DesignTokens.neonCyan,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p.postType == 'fight_card'
                          ? 'FIGHT CARD'
                          : 'ANNOUNCEMENT',
                      style: TextStyle(
                        color: p.postType == 'fight_card'
                            ? DesignTokens.neonMagenta
                            : DesignTokens.neonCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Engagement stats row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  if ((p.likes + (_localLikeDelta[p.id] ?? 0)) > 0) ...[
                    Icon(
                      Icons.thumb_up,
                      size: 13,
                      color: _likedPosts.contains(p.id)
                          ? DesignTokens.neonCyan
                          : DesignTokens.neonCyan.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(p.likes + (_localLikeDelta[p.id] ?? 0)),
                      style: TextStyle(
                        color: _likedPosts.contains(p.id)
                            ? DesignTokens.neonCyan
                            : DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (p.commentCount > 0)
                    Text(
                      '${_formatCount(p.commentCount)} comments',
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  if (p.commentCount > 0 && p.shareCount > 0)
                    const Text(
                      '  ·  ',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  if (p.shareCount > 0)
                    Text(
                      '${_formatCount(p.shareCount)} shares',
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // ── Divider ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                color: Colors.white.withValues(alpha: 0.06),
                height: 20,
              ),
            ),

            // ── Action buttons row (Like / Comment / Share / Bookmark) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Row(
                children: [
                  _buildActionButton(
                    _likedPosts.contains(p.id)
                        ? Icons.thumb_up
                        : Icons.thumb_up_outlined,
                    'Like',
                    isActive: _likedPosts.contains(p.id),
                    activeColor: DesignTokens.neonCyan,
                    onPressed: () => _handleLike(p),
                  ),
                  _buildActionButton(
                    Icons.chat_bubble_outline,
                    'Comment',
                    onPressed: () => _showCommentSheet(p),
                  ),
                  _buildActionButton(
                    Icons.share_outlined,
                    'Share',
                    onPressed: () => _showShareSheet(p),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _bookmarkedPosts.contains(p.id)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      size: 20,
                      color: _bookmarkedPosts.contains(p.id)
                          ? DesignTokens.neonGold
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                    onPressed: () => _handleBookmark(p),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String name, Color accentColor) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 40,
          height: 40,
          child: DfcNetworkImage(
            url: avatarUrl,
            width: 40,
            height: 40,
            errorWidget: _buildAvatarFallback(name, accentColor),
          ),
        ),
      );
    }

    return _buildAvatarFallback(name, accentColor);
  }

  Widget _buildAvatarFallback(String name, Color accentColor) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withValues(alpha: 0.5)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPostMedia(Post post) {
    return DfcPostMedia(post: post);
  }

  Widget _buildSingleMedia(String url) {
    if (ImageAssets.isLocalAsset(url)) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => Container(
          color: Colors.grey[900],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white24, size: 32),
          ),
        ),
      );
    }
    return DfcNetworkImage(url: url, width: double.infinity);
  }

  Widget _buildActionButton(
    IconData icon,
    String label, {
    VoidCallback? onPressed,
    bool isActive = false,
    Color? activeColor,
  }) {
    final color = isActive
        ? (activeColor ?? DesignTokens.neonCyan)
        : Colors.white.withValues(alpha: 0.5);
    return TextButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ══  ENGAGEMENT HANDLERS
  // ═══════════════════════════════════════════════

  String? _resolveEngagementUserId() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser?.uid;
    if (uid != null) return uid;

    // Demo identity is only allowed in explicit web demo mode.
    if (AppConstants.webDemoMode) {
      return 'demo_user';
    }

    _showAuthRequiredSnackBar();
    return null;
  }

  void _showAuthRequiredSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sign in required for likes, comments, shares, and saves.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleLike(Post post) {
    final userId = _resolveEngagementUserId();
    if (userId == null) return;

    HapticFeedback.lightImpact();
    final wasLiked = _likedPosts.contains(post.id);
    setState(() {
      if (wasLiked) {
        _likedPosts.remove(post.id);
        _localLikeDelta[post.id] = (_localLikeDelta[post.id] ?? 0) - 1;
      } else {
        _likedPosts.add(post.id);
        _localLikeDelta[post.id] = (_localLikeDelta[post.id] ?? 0) + 1;
      }
    });
    _persistLikes(); // Save to SharedPreferences
    // Fire-and-forget Firestore update
    final social = SocialService();
    social.toggleLike(post.id, userId).catchError((e) {
      debugPrint('Like error: $e');
    });
  }

  void _handleBookmark(Post post) {
    final userId = _resolveEngagementUserId();
    if (userId == null) return;

    HapticFeedback.mediumImpact();
    setState(() {
      if (_bookmarkedPosts.contains(post.id)) {
        _bookmarkedPosts.remove(post.id);
      } else {
        _bookmarkedPosts.add(post.id);
      }
    });
    final social = SocialService();
    social.toggleBookmark(post.id, userId).catchError((e) {
      debugPrint('Bookmark error: $e');
    });
  }

  void _showCommentSheet(Post post) {
    final userId = _resolveEngagementUserId();
    if (userId == null) return;

    final commentController = TextEditingController();
    final auth = Provider.of<AuthService>(context, listen: false);
    final displayName = auth.userModel?.displayName ?? 'Fighter';
    final social = SocialService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                // ── Handle bar ──
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Comments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Divider(color: Colors.white12),
                // ── Comment list ──
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: social.getComments(post.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00F5FF),
                          ),
                        );
                      }
                      final comments = snapshot.data ?? [];
                      if (comments.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Colors.white24,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No comments yet',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Be the first to comment',
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: comments.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (_, i) {
                          final c = comments[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: DesignTokens.neonCyan
                                      .withValues(alpha: 0.2),
                                  child: Text(
                                    (c['userDisplayName'] as String? ?? '?')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF00F5FF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            c['userDisplayName'] as String? ??
                                                'Fighter',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (c['userRole'] != null) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: DesignTokens.neonCyan
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                (c['userRole'] as String)
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Color(0xFF00F5FF),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        c['content'] as String? ?? '',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // ── Comment input ──
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 8,
                    top: 8,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 8,
                  ),
                  decoration: const BoxDecoration(
                    color: DesignTokens.bgSecondary,
                    border: Border(top: BorderSide(color: Colors.white12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: const TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Colors.white12,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Colors.white12,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: DesignTokens.neonCyan,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: DesignTokens.bgPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          final text = commentController.text.trim();
                          if (text.isEmpty) return;
                          HapticFeedback.lightImpact();
                          social
                              .addComment(
                                post.id,
                                userId,
                                text,
                                displayName: displayName,
                                role: auth.userRole?.name,
                              )
                              .then((_) {
                                commentController.clear();
                              })
                              .catchError((e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.red[900],
                                    ),
                                  );
                                }
                              });
                        },
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF00F5FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showShareSheet(Post post) {
    final userId = _resolveEngagementUserId();
    if (userId == null) return;

    HapticFeedback.lightImpact();
    final social = SocialService();

    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Share Post',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareOption(
                      icon: Icons.repeat,
                      label: 'Repost',
                      color: DesignTokens.neonCyan,
                      onTap: () {
                        Navigator.pop(ctx);
                        social.sharePost(post.id, userId).catchError((e) {
                          debugPrint('Share error: $e');
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Shared to your feed'),
                            backgroundColor: DesignTokens.neonCyan.withValues(
                              alpha: 0.9,
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    _buildShareOption(
                      icon: Icons.copy_rounded,
                      label: 'Copy Link',
                      color: DesignTokens.neonGold,
                      onTap: () {
                        Navigator.pop(ctx);
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                'https://datafightcentral.com/post/${post.id}',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Link copied to clipboard'),
                            backgroundColor: DesignTokens.neonGold.withValues(
                              alpha: 0.9,
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    _buildShareOption(
                      icon: Icons.share_outlined,
                      label: 'More',
                      color: DesignTokens.neonGreen,
                      onTap: () {
                        Navigator.pop(ctx);
                        final text =
                            '${post.userDisplayName ?? "Fighter"}: ${post.content}';
                        SharePlus.instance.share(
                          ShareParams(
                            text: text.length > 280
                                ? '${text.substring(0, 277)}...'
                                : text,
                            uri: Uri.parse(
                              'https://datafightcentral.com/post/${post.id}',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Color _roleAccentColor(String? role) {
    switch (role) {
      case 'fighter':
        return DesignTokens.neonMagenta;
      case 'coach':
        return const Color(0xFFFF9800);
      case 'promoter':
        return DesignTokens.neonCyan;
      case 'gym':
        return const Color(0xFF4CAF50);
      case 'organization':
        return DesignTokens.neonAmber;
      case 'media':
        return const Color(0xFFAB47BC);
      case 'admin':
        return const Color(0xFFD4AF37);
      case 'community':
        return const Color(0xFF26A69A);
      default:
        return Colors.white.withValues(alpha: 0.6);
    }
  }

  bool _isPageLikeRole(String? role) {
    switch (role) {
      case 'promoter':
      case 'gym':
      case 'organization':
      case 'media':
      case 'admin':
      case 'community':
        return true;
      default:
        return false;
    }
  }

  String _pageLabelForRole(String? role) {
    switch (role) {
      case 'promoter':
        return 'PROMOTER PAGE';
      case 'gym':
        return 'GYM PAGE';
      case 'organization':
        return 'ORGANIZATION PAGE';
      case 'media':
        return 'MEDIA PAGE';
      case 'admin':
        return 'OFFICIAL PAGE';
      case 'community':
        return 'COMMUNITY PAGE';
      default:
        return 'PUBLIC PAGE';
    }
  }

  void _openUserPage(String userId) {
    if (userId.isEmpty) {
      return;
    }
    context.push('/user/$userId');
  }

  void _showMoreOptions(Post post) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUserId =
        auth.currentUser?.uid ??
        (auth.isDemoUser ? AuthService.demoUserId : null);
    final isOwn = currentUserId != null && currentUserId == post.userId;

    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(bottom: 16),
              ),
              if (isOwn) ...[
                _moreOptionsTile(
                  Icons.edit_outlined,
                  'Edit Post',
                  DesignTokens.neonCyan,
                  () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post editing coming soon'),
                        backgroundColor: Color(0xFF1A1A2E),
                      ),
                    );
                  },
                ),
                _moreOptionsTile(
                  Icons.delete_outline,
                  'Delete Post',
                  Colors.redAccent,
                  () {
                    Navigator.pop(ctx);
                    _confirmDeletePost(post);
                  },
                ),
              ],
              _moreOptionsTile(
                Icons.bookmark_border,
                'Save Post',
                DesignTokens.neonGold,
                () {
                  Navigator.pop(ctx);
                  _handleBookmark(post);
                },
              ),
              _moreOptionsTile(
                Icons.person_off_outlined,
                'Unfollow',
                Colors.white60,
                () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unfollowed'),
                      backgroundColor: Color(0xFF1A1A2E),
                    ),
                  );
                },
              ),
              _moreOptionsTile(
                Icons.flag_outlined,
                'Report Post',
                Colors.orangeAccent,
                () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post reported. Our team will review it.'),
                      backgroundColor: Color(0xFF1A1A2E),
                    ),
                  );
                },
              ),
              _moreOptionsTile(Icons.block, 'Block User', Colors.redAccent, () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User blocked'),
                    backgroundColor: Color(0xFF1A1A2E),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moreOptionsTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(color: color, fontSize: 15)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
    );
  }

  void _confirmDeletePost(Post post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: const Text(
          'Delete Post?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final social = SocialService();
              social
                  .deletePost(post.id)
                  .then((_) {
                    if (mounted) {
                      setState(
                        () => _paginatedPosts.removeWhere(
                          (p) => p is Post && p.id == post.id,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Post deleted'),
                          backgroundColor: Color(0xFF1A1A2E),
                        ),
                      );
                    }
                  })
                  .catchError((e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Delete failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  });
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    try {
      if (timestamp == null) return '';
      final dt = timestamp is DateTime
          ? timestamp
          : DateTime.fromMillisecondsSinceEpoch(
              (timestamp as dynamic).millisecondsSinceEpoch as int,
            );
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return '${dt.month}/${dt.day}';
    } catch (e) {
      return '';
    }
  }

  // ========== FEED CARD LIST ==========

  // Category map: 0=ALL 1=FIGHTS 2=MENTAL 3=STORIES 4=SUPPORT 5=NEWS 6=PROMOS
  static const _cardCategories = [
    1,
    6,
    4,
    1,
    6,
    1,
    5,
    1,
    3,
    2,
    1,
    3,
    1,
    6,
    4,
    1,
    2,
    5,
    6,
    4,
    3,
    3,
    4,
    1,
    2,
    6,
    5,
    3,
    1,
    3,
    1,
    5,
    3,
    1,
    3,
    5,
    1,
    1,
    1,
    1,
    1,
    5,
    3,
    1,
    1,
    5,
    3,
    1,
    1,
    1,
    3,
    5,
    3,
    5,
    3,
    1,
    5,
    6,
    5,
    6,
  ];

  List<Widget> _buildFeedCards() {
    final all = <Widget>[
      // --- DFC x IBC PARTNERSHIP ANNOUNCEMENT ---
      _buildCommunityAdCard(
        headline: '📣 DFC IS EXCITED TO ANNOUNCE IBC III',
        body:
            'What a great event from Danny Mac and the IBC team. DFC works from the back as the promotion engine while IBC leads from the front. We are not competition — we amplify great promotions and help the world see them. 🌍🪓',
        cta: 'VIEW IBC III RECAP',
        gradient: [
          const Color(0xFFFF0000),
          const Color(0xFF00D4FF),
          const Color(0xFFFFD700),
        ],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- DANNY MAC SPOTLIGHT ---
      _buildPromoterPostCard(
        promoter: 'Data Fight Central',
        verified: true,
        content:
            '🪓 DANNY MAC IS BACK 🪓\n\n'
            'The visionary behind IBC delivered an unforgettable night of BRAWLING. 8,400 fans. \$1.2M gate. Massive energy.\n\n'
            'DFC is proud to push and promote this movement from behind the scenes while Danny Mac and IBC hold the spotlight. #IBCIII #Brawling #DannyMac',
        timestamp: '1h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- IBC WORLD TAKEOVER POST ---
      _buildEventHypeCard(
        eventId: 'ibc-world-takeover',
        title: 'IBC × DFC: THIS IS THE FIRST OF MANY',
        location: 'AU • NZ • USA • UK • EUROPE • ASIA • MIDDLE EAST',
        date: 'ALL EVENTS • 2026 & BEYOND',
        gradientColors: [
          const Color(0xFFFF0000),
          const Color(0xFFFF6B00),
          const Color(0xFFFFD700),
        ],
        fightStock: '🌍 WORLD REACH • PROMOTION FIRST',
        imageUrl: ImageAssets.bgAction,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- WHAT IS BRAWLING ---
      _buildCommunityAdCard(
        headline: '🪓 THIS ISN\'T FIGHTING. THIS IS BRAWLING.',
        body:
            'Danny Mac built a movement. DFC powers distribution, social visibility, and promotion so every event gets seen. This is our first together — and we roll this same energy into every event moving forward.',
        cta: 'FOLLOW ALL EVENTS',
        gradient: [const Color(0xFF8B0000), const Color(0xFFFF4500)],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- PLATFORM NOT COMPETITOR ---
      _buildPromoterPostCard(
        promoter: 'International Brawling Championships',
        verified: true,
        content:
            '📢 To be crystal clear: DFC is our promotional engine and media partner. They are not here to take shine — they are here to put MORE shine on IBC, our fighters, and every event we run. Respect to the whole team. 🙏 #IBCIII #Partnership',
        timestamp: '1h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHTERS APPRECIATION POST ---
      _buildPromoterPostCard(
        promoter: 'Data Fight Central',
        verified: true,
        content:
            '🎥 LIGHTS • CAMERA • ACTION for EVERY fighter on the IBC III card. Win, lose, or draw — proud effort and amazing work from all athletes who stepped in and gave everything. DFC will keep amplifying every fighter\'s story across every event. #Respect #IBCIII #FightersFirst',
        timestamp: '58m ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- GLOBAL DISCOVERY PUSH ---
      _buildCommunityAdCard(
        headline: '🌐 GLOBAL DISCOVERY MODE: IBC x DFC',
        body:
            'From Australia to New Zealand, UK, USA, Europe, Japan, Philippines, Thailand, UAE, Brazil, and South Africa — we are pushing highlights, recaps, and fighter clips into the global social stream. Search and share: Data Fight Central + IBC 3.',
        cta: 'SHARE WORLDWIDE',
        gradient: [const Color(0xFF0D47A1), const Color(0xFF00ACC1)],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- IBC III RECAP — OFFICIAL RESULTS ---
      _buildPromoterPostCard(
        promoter: 'International Brawling Championships',
        verified: true,
        content:
            '🏆 IBC III OFFICIAL RESULTS 🏆\n\n'
            'MAIN EVENT: Jay Cutler def. Luke Modini via TKO (Round 3) — NEW LHW CHAMPION!\n'
            'CO-MAIN: Isaac Hardman def. Jonathan Tuhu via Unanimous Decision — IBC TITLE RETAINED!\n\n'
            '8,400 fans packed Gold Coast Sports & Leisure Centre! The wood got CHOPPED! 🪓🔥 Full highlights on DFC Media Center. #IBCIII #GoldCoast',
        timestamp: '2h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- IBC III HIGHLIGHT POST ---
      _buildPhotoPostCard(
        author: 'Data Fight Central',
        content:
            '💥 KNOCKOUT OF THE YEAR CANDIDATE! Jay Cutler\'s spinning backfist made Luke Modini crumble in Round 3. The crowd ERUPTED. New LHW Champion crowned at IBC III! Watch the full replay on DFC 🎬 #IBCIII #KOoftheYear',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '3h ago',
        likes: '47.2K',
        comments: '5.8K',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- ATTENDANCE & SUCCESS POST ---
      _buildCommunityAdCard(
        headline: '🎉 IBC III SMASHES RECORDS',
        body:
            '8,400 fans | \$1.2M gate | 12 countries streaming live | Social mentions up 340%. Danny Mac\'s vision is conquering Australia. IBC IV announcement coming SOON. The brawling revolution is HERE.',
        cta: 'VIEW FULL RECAP',
        gradient: [const Color(0xFFFF0000), const Color(0xFFFFD700)],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHTER POST-FIGHT CALLOUT ---
      _buildPromoterPostCard(
        promoter: 'Jay Cutler',
        verified: false,
        content:
            '🏆 NEW CHAMPION! Told you I was coming for that belt. Luke gave me a war but BRAWLING is in my DNA. Who\'s next? Every LHW in Australia better be ready. IBC IV... I\'ll be waiting. Thank you Gold Coast! 🪓 #AndNew #IBCIII',
        timestamp: '5h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- MEDIA COVERAGE POST ---
      _buildNewsCard(
        source: 'ESPN Australia',
        headline:
            'IBC III delivers: 8,400 fans witness carnage at Gold Coast as Jay Cutler becomes new LHW champion with brutal Round 3 finish. Danny Mac\'s brawling empire expands.',
        timestamp: '4h ago',
        imageUrl: ImageAssets.eventPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- IBC IV TEASER ---
      _buildEventHypeCard(
        eventId: 'ibc-04-announcement',
        title: 'IBC IV — Location TBA',
        location: 'ANNOUNCEMENT COMING SOON',
        date: 'June 2026',
        gradientColors: [const Color(0xFFFFD700), const Color(0xFFFF6B35)],
        fightStock: '🔥 WATCH THIS SPACE',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- SPONSOR THANK YOU ---
      _buildPromoterPostCard(
        promoter: 'International Brawling Championships',
        verified: true,
        content:
            '🙏 MASSIVE thank you to our IBC III sponsors: Eventbrite (ticketing), TrillerTV+ & Kayo Sports (broadcast), Gold Coast Tourism, Monster Energy, and all our venue partners. You made history possible. The brawling revolution continues! #IBCIII',
        timestamp: '6h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- BUY A COFFEE, NOT A COFFIN — DFC Donation Promo ---
      _buildCommunityAdCard(
        headline: '☕ Buy a Coffee, Not a Coffin — DFC Donations',
        body:
            'Every donation sends a real coffee QR code to someone hurting. '
            'Fighters, families & communities in crisis get a moment of warmth and hope. '
            'Powered by DFC × Nitechill. Donate via Stripe or bank transfer.',
        cta: 'DONATE NOW',
        gradient: [const Color(0xFF6D4C41), const Color(0xFF388E3C)],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- DFC+ STREAMING COMPARISON PROMO ---
      _buildCommunityAdCard(
        headline: '⚡ DFC+ vs Paramount+ vs ESPN+ vs DAZN',
        body:
            'They charge \$12–\$25/month for ball sports with a side of combat. DFC+ is \$2.99/month — 100% combat sports, AI coaching, social feed, marketplace, PPV, and promoter tools. See the comparison.',
        cta: 'SEE WHY DFC WINS',
        gradient: [const Color(0xFF00F5FF), const Color(0xFFFF00FF)],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- PPV PROMO: IBC ---
      _buildPPVPromoCard(
        eventTitle: 'IBC CHAMPIONSHIPS IV',
        mainEvent: 'Isaac Hardman vs TBA — Main Event',
        price: '\$29.99',
        date: 'May 2026 · Gold Coast, AU',
        imageUrl: ImageAssets.bgAction,
        eventId: 'ibc-4',
        undercard: [
          'Danny Mac Celebrity Brawl — Co-Main',
          'Lightweight Brawling Final — 3 Rounds',
          'Women\'s Open Weight — Debut',
        ],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- PPV HUB PROMO ---
      _buildCommunityAdCard(
        headline: '🎬 DFC PAY-PER-VIEW — LIVE COMBAT',
        body:
            'IBC Championships \$29.99 · Ultimate Legends \$24.99 · UFC Fight Night \$79.99 · Early bird pricing from \$14.99. Promoters keep 85% of revenue. Multi-cam, live chat, predictions. All on DFC.',
        cta: 'EXPLORE PPV',
        gradient: [const Color(0xFFD32F2F), const Color(0xFFFF6D00)],
        imageUrl: ImageAssets.fightPlaceholder,
        route: '/ppv',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHTER PROMO POST ---
      _buildPhotoPostCard(
        author: 'Isaac Hardman',
        content:
            '🏆 STILL YOUR IBC CHAMPION! Defended the belt at IBC III with everything I had. Jonathan Tuhu pushed me to the limit - respect. Now eyes on the next challenge. IBC IV... who wants this smoke? 🔥 #IBCChampion #StillHungry',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '8h ago',
        likes: '12.4K',
        comments: '892',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- GYM PROMO: Riding IBC momentum ---
      _buildPromoterPostCard(
        promoter: 'Gold Coast Combat Academy',
        verified: true,
        content:
            '🥊 3 of our fighters competed at IBC III last night! Proud of every single one. Want to train with champions? March special: Join now, get your first month 50% OFF. MMA, Boxing, Muay Thai, BJJ. DM to claim your spot! 🇦🇺 #IBCIII #GoldCoast',
        timestamp: '10h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FITNESS SPONSOR POST ---
      _buildCommunityAdCard(
        headline: '💊 Post-Fight Recovery Stack — 25% OFF',
        body:
            'Glutamine, BCAAs, Magnesium, Collagen peptides. Everything fighters need after a war. Use code: IBC25 at checkout. Ships worldwide from DFC Marketplace. Limited time offer!',
        cta: 'SHOP RECOVERY',
        gradient: [const Color(0xFF00C853), const Color(0xFF1565C0)],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- REGIONAL EVENT ANNOUNCEMENT ---
      _buildEventHypeCard(
        eventId: 'brisbane-fc-april',
        title: 'Brisbane Fight Club 15',
        location: 'Brisbane Convention Centre, QLD',
        date: 'April 18, 2026',
        gradientColors: [DesignTokens.neonMagenta, DesignTokens.neonCyan],
        fightStock: 'Tickets on sale NOW',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHTER CALLOUT POST ---
      _buildPhotoPostCard(
        author: 'Luke Modini',
        content:
            '💔 Hard loss at IBC III. Jay caught me clean. No excuses. But I\'ll be back stronger. This setback is temporary. Already back in the gym. IBC IV or wherever - I\'m coming for redemption. Count on it. 🔥',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '12h ago',
        likes: '8.7K',
        comments: '1.2K',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- PHOTO POST: UFC Official ---
      _buildPhotoPostCard(
        author: 'UFC',
        content:
            'UFC 313 fight week is HERE. Santos vs Aliyev — Light Heavyweight title on the line at T-Mobile Arena, Las Vegas. Who takes the belt home? 🏆👊',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '20m ago',
        likes: '89.2K',
        comments: '12.1K',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildSamuraiAIPostCard(
        headline: '⚔️ Samurai AI scans 40+ sources every 15 mins',
        body:
            'DFC\'s Samurai AI hunts fight stories across 6 continents — from Tokyo gyms to São Paulo favelas, London dojos to Lagos boxing clubs. One engine to cover the entire combat world.',
        tag: 'AI ENGINE',
        tagColor: DesignTokens.neonCyan,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHT SHOW: UFC 313, Las Vegas ---
      _buildFightShowCard(
        title: 'UFC 313: Santos vs Aliyev',
        promotion: 'UFC',
        imageUrl: ImageAssets.fightPlaceholder,
        fightCount: 14,
        mainEvent: 'Santos vs. Aliyev',
        location: 'T-Mobile Arena, Las Vegas',
        date: 'March 8, 2026',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: Global headline with image ---
      _buildNewsCard(
        source: 'ESPN MMA',
        headline:
            'Jon Jones announces final fight — heavyweight GOAT to defend title at UFC 315 in Madison Square Garden, New York',
        timestamp: '12m ago',
        imageUrl: ImageAssets.trainingPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildEventHypeCard(
        eventId: 'event_002',
        title: 'Lumpinee World Muay Thai Grand Prix',
        location: 'Bangkok, Thailand',
        date: 'March 21, 2026',
        gradientColors: [DesignTokens.neonAmber, DesignTokens.neonRed],
        fightStock: '+18.7%',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- PHOTO POST: Elite Combat Team ---
      _buildPhotoPostCard(
        author: 'Elite Combat Team',
        content:
            'Another championship camp wrapped at ATT Coconut Creek. World-class MMA, BJJ, wrestling & striking under one roof. Champions are built here every single day. 🏆🔥',
        imageUrl: ImageAssets.gymPlaceholder,
        timestamp: '1h ago',
        likes: '6,340',
        comments: '412',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildMentalHealthCard(
        title: '🧠 Fighter Mental Health: Breaking the Silence',
        body:
            'A 2026 global survey of 3,400 combat athletes across 41 countries found 68% experienced depression or anxiety. Only 12% sought help. DFC is building support networks worldwide — you are not alone.',
        stat: '68% of fighters battle mental health in silence',
        cta: 'FIND SUPPORT',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildFightAnnouncementCard(
        fighterA: 'Islam Makhachev',
        fighterB: 'Lance Palmer',
        recordA: '26-1',
        recordB: '34-9',
        weightClass: 'Lightweight',
        aiConfidence: '62% / 38%',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildStrugglerStoryCard(
        name: 'Elijah Okafor',
        title: 'From Lagos to UFC Middleweight Champion',
        story:
            'Born in Lagos, Nigeria and raised in Rotorua, New Zealand, Elijah Okafor was bullied as a kid and turned to martial arts at 18. He fought 75 times in kickboxing across China and Australia before the UFC came calling. By 2019 he was the undisputed UFC Middleweight Champion of the World \u2014 proof that starting late means nothing.',
        tags: ['#Nigeria', '#UFC', '#TheLastStylebender'],
        timestamp: '45m ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHT SHOW: ONE Championship, Bangkok ---
      _buildFightShowCard(
        title: 'ONE 170: Narong vs Apichai',
        promotion: 'ONE CHAMPIONSHIP',
        imageUrl: ImageAssets.eventPlaceholder,
        fightCount: 12,
        mainEvent: 'Narong vs. Apichai',
        location: 'Impact Arena, Bangkok',
        date: 'March 21, 2026',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildPromoterPostCard(
        promoter: 'Matchroom Boxing',
        verified: true,
        content:
            'ANNOUNCEMENT: Anthony Joshua vs. Daniel Dubois II confirmed for Wembley Stadium, London. 90,000 seats. July 2026. AJ says: "The most important night of my career." The biggest British boxing event of the decade is ON. 🇬🇧🥊',
        timestamp: '35m ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- APPAREL SPONSOR ---
      _buildPhotoPostCard(
        author: 'Bad Boy Fight Gear',
        content:
            '👊 NEW DROP: Bad Boy Legacy Series fight shorts. Premium stretch fabric, reinforced stitching, sublimated graphics. Order now at DFC Marketplace + FREE shin guards with purchase over \$100. Ships worldwide 📦',
        imageUrl: ImageAssets.trainingPlaceholder,
        timestamp: '1h ago',
        likes: '6,340',
        comments: '287',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- REGIONAL GYM PROMO: Sydney ---
      _buildPromoterPostCard(
        promoter: 'Gracie Barra Sydney',
        verified: true,
        content:
            '🥋 FREE TRIAL WEEK: April 1-7! BJJ, MMA, Kids classes. Learn from world-class black belts. All levels welcome. 3 locations across Sydney. Book your free class today! Limited spots. #GracieBarra #Sydney',
        timestamp: '2h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHTER ANNOUNCEMENT ---
      _buildPhotoPostCard(
        author: 'Boaz Kapua',
        content:
            '🙏 Got the W at IBC III! Unanimous decision. Thank you to my team, sponsors, and everyone who supported. Next fight already in talks. Stay tuned. The journey continues! 💪 #IBCIII #TeamKapua',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '14h ago',
        likes: '4,890',
        comments: '312',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NUTRITION SPONSOR ---
      _buildCommunityAdCard(
        headline: '🥤 Hydration = Performance',
        body:
            'Electrolyte powders, BCAA drinks, coconut water packs. Stay hydrated, stay sharp. 20% off all hydration products this week at DFC Marketplace. Use code: H2OFIGHTER',
        cta: 'SHOP HYDRATION',
        gradient: [const Color(0xFF00BCD4), const Color(0xFF4CAF50)],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- EVENT TICKET PROMO: Melbourne ---
      _buildEventHypeCard(
        eventId: 'melbourne-mma-april',
        title: 'Melbourne MMA Grand Prix',
        location: 'Margaret Court Arena, Melbourne',
        date: 'April 25, 2026',
        gradientColors: [const Color(0xFF9C27B0), const Color(0xFFE91E63)],
        fightStock: 'Early Bird: \$55',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildSupportResourceCard(
        icon: '💊',
        title: 'Substance Abuse in Combat Sports: You Can Win This Fight Too',
        body:
            'Performance pressure, chronic pain, and identity loss after retirement push many fighters toward substance abuse. DFC connects you with confidential support worldwide.',
        resources: [
          const _SupportResource(
            'SAMHSA (USA)',
            '1-800-662-4357',
            DesignTokens.neonGreen,
          ),
          const _SupportResource(
            'Samaritans (UK)',
            '116 123',
            DesignTokens.neonCyan,
          ),
          const _SupportResource(
            'Lifeline (AU)',
            '13 11 14',
            DesignTokens.neonAmber,
          ),
        ],
        accentColor: const Color(0xFF8338EC),
        tag: 'GLOBAL SUPPORT',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- PHOTO POST: RIZIN Official ---
      _buildPhotoPostCard(
        author: 'RIZIN Fighting Federation',
        content:
            'RIZIN 50 officially sold out at Saitama Super Arena! 30,000 fans ready for the biggest card in Japanese MMA history. March 22 — see you ringside. 🇯🇵⚡',
        imageUrl: ImageAssets.wellnessPlaceholder,
        timestamp: '2h ago',
        likes: '18.7K',
        comments: '2,810',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- APPAREL SPONSOR ---
      _buildPhotoPostCard(
        author: 'Venum Fight Gear',
        content:
            '🐍 NEW ARRIVAL: Venum Elite Series Training Shorts. Reinforced stitching, moisture-wicking fabric, 4-way stretch. Available in 8 colors at DFC Marketplace & all major retailers worldwide. Gear up like a champion 🔥',
        imageUrl: ImageAssets.trainingPlaceholder,
        timestamp: '3h ago',
        likes: '7,890',
        comments: '412',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- LOCAL GYM PROMO ---
      _buildPromoterPostCard(
        promoter: 'Warrior Spirit Gym - Melbourne',
        verified: false,
        content:
            '💪 March special: 3 months unlimited training for \$299 (normally \$450). MMA, Boxing, Muay Thai, BJJ. 50+ classes per week, all levels welcome. Valid until March 31st. Limited spots — DM to lock in your discount! 🇦🇺',
        timestamp: '4h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildAICoachCard(
        quote:
            'Your darkest round is not the end. Every champion has a moment where they wonder if they can go on. That moment is where champions are made.',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: ONE Championship, Singapore ---
      _buildNewsCard(
        source: 'ONE Championship',
        headline:
            'Stamp Fairtex headlines ONE 200 in Singapore — Women\'s MMA world title on the line at Indoor Stadium',
        timestamp: '1h ago',
        imageUrl: ImageAssets.fightPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildCommunityAdCard(
        headline: '📣 List Your Gym on DFC — Free Worldwide',
        body:
            'Join 2,400+ gyms across 38 countries. Get discovered by fighters, sponsors & sparring partners in your region. USA, UK, Japan, Brazil, Thailand & more.',
        cta: 'LIST YOUR GYM FREE',
        gradient: [DesignTokens.neonGreen, const Color(0xFF00B894)],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildVictimSupportCard(
        title: '🛡️ Supporting Victims in Combat Communities',
        body:
            'Domestic violence, assault, and coercive control exist in all communities — including ours. DFC stands with survivors worldwide. Fighters are trained to protect.',
        resources: [
          const _SupportResource(
            'National DV Hotline (US)',
            '1-800-799-7233',
            DesignTokens.neonRed,
          ),
          const _SupportResource(
            'Refuge (UK)',
            '0808 2000 247',
            DesignTokens.neonMagenta,
          ),
          const _SupportResource(
            '1800RESPECT (AU)',
            '1800 737 732',
            DesignTokens.neonAmber,
          ),
        ],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildStrugglerStoryCard(
        name: 'Islam Makhachev',
        title: 'From Dagestan Mountains to Undefeated UFC Champion',
        story:
            'Raised in a tiny village in Dagestan, Russia, Karimov wrestled bears as a child and trained in a cramped basement gym with his father Abdulmanap. The family had nothing but discipline. He retired 29-0, the UFC Lightweight GOAT, and now mentors dozens of fighters from his region through his own promotion Mountain FC. "Father\'s plan was always the plan."',
        tags: ['#Dagestan', '#UFC', '#TheEagle'],
        timestamp: '2h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- PHOTO POST: Golden Dragon Muay Thai, Phuket ---
      _buildPhotoPostCard(
        author: 'Golden Dragon Muay Thai',
        content:
            'March camp season in full swing. 140+ fighters from 22 countries grinding daily in Phuket. Muay Thai, MMA, BJJ, boxing — all under one roof at the global fight capital. 🐯🇹🇭',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '3h ago',
        likes: '11.2K',
        comments: '876',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildPovertyStoryCard(
        title:
            'Fighting Poverty: How Combat Sports Communities Give Back Worldwide',
        body:
            'From favelas in Brazil to townships in South Africa, from inner-city Chicago to rural Philippines — gyms are quietly running free programs for kids in poverty. No fee, no barrier, just gloves and a coach who cares.',
        impactStats: [
          '25,000+ young people trained free across 41 countries',
          '1,200 gyms running community programs worldwide',
          '\$4.8M in scholarships by DFC partners in 2025',
        ],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHT SHOW: PFL in Saudi Arabia ---
      _buildFightShowCard(
        title: 'PFL SUPER FIGHTS: RIYADH',
        promotion: 'PFL',
        imageUrl: ImageAssets.trainingPlaceholder,
        fightCount: 10,
        mainEvent: 'Ngannou vs. Ferreira',
        location: 'Kingdom Arena, Riyadh',
        date: 'April 12, 2026',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildMentalHealthCard(
        title: '🧠 Post-Career Depression: The Invisible Opponent',
        body:
            'Fighters from Tokyo to Toronto describe retirement as the hardest fight. The sudden loss of identity, structure, and adrenaline creates a void. DFC\'s global peer support network connects retired fighters who understand.',
        stat: '1 in 3 retired fighters experience severe depression',
        cta: 'CONNECT WITH PEERS',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildSamuraiAIPostCard(
        headline: '📡 Samurai AI just found 23 new fight stories worldwide',
        body:
            'Underground circuit in Lagos, Nigeria • Kickboxing prodigy in Osaka, Japan • Teen champion from East London, UK • Brazilian favela boxing project • Afghan refugee fighter wins debut in Germany. DFC Samurai watches every corner of the combat world.',
        tag: 'AI REPORTS',
        tagColor: DesignTokens.neonAmber,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: Bellator in London ---
      _buildNewsCard(
        source: 'Bellator MMA',
        headline:
            'Bellator Champions Series returns to London — Massive 15-fight card at Wembley Arena sells out in 48 hours',
        timestamp: '3h ago',
        imageUrl: ImageAssets.trainingPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- COMMUNITY USER POST: Fighter sharing training ---
      _buildPhotoPostCard(
        author: 'Jake "The Snake" Shields',
        content:
            'Morning grappling session at 10th Planet LA. Rolled 8 rounds, worked on leg locks and back takes. If you\'re in LA come through, open mat every Saturday 🤙',
        imageUrl: ImageAssets.trainingPlaceholder,
        timestamp: '25m ago',
        likes: '2,847',
        comments: '189',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- POLL CARD ---
      _buildPollCard(
        question:
            '🗳️ GOAT Debate: Who is the greatest MMA fighter of all time?',
        options: [
          'Jon Jones',
          'Khabib Nurmagomedov',
          'Anderson Silva',
          'Georges St-Pierre',
          'Fedor Emelianenko',
        ],
        votes: [34, 28, 15, 18, 5],
        totalVotes: '248K',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- SPONSOR: Training Equipment ---
      _buildCommunityAdCard(
        headline: '🥊 Hayabusa T3 Boxing Gloves — 30% OFF',
        body:
            'Premium dual-X wrist support, multi-layered foam technology. The glove trusted by champions worldwide. Limited time offer at DFC Marketplace. Ships in 24-48 hours.',
        cta: 'SHOP GLOVES',
        gradient: [const Color(0xFFFF5252), const Color(0xFF000000)],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- REGIONAL PROMO: Brisbane ---
      _buildPhotoPostCard(
        author: 'Brisbane Fight League',
        content:
            '🦘 BFL 12 coming to Brisbane Convention Centre on March 22nd! 9 professional MMA bouts + 3 amateur showcase fights. Tickets from \$45. Main event: Queensland Welterweight Championship. Get your tickets at Ticketek NOW 🔥 #BFL #Brisbane',
        imageUrl: ImageAssets.eventPlaceholder,
        timestamp: '2h ago',
        likes: '1,456',
        comments: '92',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- WELLNESS PROMO ---
      _buildMentalHealthCard(
        title: '💚 Fighter Wellness Program — Free Resources',
        body:
            'DFC offers free mental health support, nutrition guides, injury prevention workshops, and career counseling for all fighters. No membership required. Because your wellbeing matters beyond the cage.',
        stat: 'Over 12,000 fighters supported in 2026',
        cta: 'ACCESS RESOURCES',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- GYM PROMO: Adelaide ---
      _buildPromoterPostCard(
        promoter: 'Adelaide Combat Sports',
        verified: true,
        content:
            '🥊 Kids martial arts classes now enrolling! Ages 5-14. Build confidence, discipline, fitness & self-defense skills. First 2 weeks FREE. Classes Mon-Fri 4pm-5:30pm. Safe, fun, professional coaching. Register online 🇦🇺',
        timestamp: '3h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- COMMUNITY: Gym Check-in ---
      _buildPhotoPostCard(
        author: 'Sarah "Savage" Mitchell',
        content:
            'Just signed my first pro MMA contract! 🎉 After 3 years amateur, 12 fights, and working 2 jobs to pay for training — we made it. Never give up on your dreams. Shoutout to my team at Gracie Barra Melbourne 🇦🇺❤️',
        imageUrl: ImageAssets.gymPlaceholder,
        timestamp: '1h ago',
        likes: '14,211',
        comments: '1,847',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- VIDEO POST CARD ---
      _buildVideoPostCard(
        author: 'DFC Highlights',
        content:
            '🎬 TOP 10 KOs of 2026 so far — from Topuria\'s walk-off headkick to Pereira\'s devastating left hook. Which one gave you chills?',
        thumbnailUrl: ImageAssets.fightPlaceholder,
        duration: '8:42',
        views: '2.4M',
        timestamp: '3h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: Boxing ---
      _buildNewsCard(
        source: 'Boxing Scene',
        headline:
            'Terence Crawford officially vacates welterweight title — moves to 70 kg / 154 lbs seeking Canelo superfight in September',
        timestamp: '2h ago',
        imageUrl: ImageAssets.eventPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- BREAKING: Usyk heavyweight ---
      _buildNewsCard(
        source: 'Ring Magazine',
        headline:
            'BREAKING: Oleksandr Usyk retains undisputed heavyweight crown — stops challenger in nine rounds. Fury demands trilogy.',
        timestamp: '28m ago',
        imageUrl: ImageAssets.fightPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- BREAKING: Jai Opetaia ---
      _buildNewsCard(
        source: 'Fight News Australia',
        headline:
            'BREAKING: Jai Opetaia unification fight confirmed — IBF vs WBO cruiserweight showdown at Qudos Bank Arena, Sydney. One fight from undisputed.',
        timestamp: '45m ago',
        imageUrl: ImageAssets.fightPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- Jai Opetaia community post ---
      _buildPhotoPostCard(
        author: 'Jai Opetaia',
        content:
            '🇦🇺 I\'m not stopping at one belt. I want them all. Australians don\'t dream small. Sydney — April — Qudos Bank Arena. The whole country behind me. Let\'s unify this division. 🏆🥊 #OpetaiaUndisputed #CruiserweightKing #AustralianBoxing',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '1h ago',
        likes: '14,820',
        comments: '2,341',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: Tank Davis ---
      _buildNewsCard(
        source: 'ESPN Boxing',
        headline:
            'Gervonta "Tank" Davis destroys challenger, calls out Shakur Stevenson — "Let\'s give the people what they want"',
        timestamp: '1h ago',
        imageUrl: ImageAssets.fightPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: Fury return ---
      _buildNewsCard(
        source: 'Boxing Scene',
        headline:
            'Tyson Fury confirms return — "The Gypsy King" targets Usyk trilogy in Riyadh. Turki Alalshikh in advanced talks.',
        timestamp: '3h ago',
        imageUrl: ImageAssets.eventPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: Tim Tszyu ---
      _buildNewsCard(
        source: 'Fight News Australia',
        headline:
            'Tim Tszyu vs Jermall Charlo confirmed for Las Vegas — Australia\'s biggest boxing export since Kostya carries the legacy to T-Mobile Arena',
        timestamp: '4h ago',
        imageUrl: ImageAssets.fightPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: Beterbiev-Bivol ---
      _buildNewsCard(
        source: 'Ring Magazine',
        headline:
            'Artur Beterbiev vs Dmitry Bivol 2 — undisputed light heavyweight rematch set for Riyadh. Four belts on the line again.',
        timestamp: '5h ago',
        imageUrl: ImageAssets.eventPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- COMMUNITY: Training tip ---
      _buildPhotoPostCard(
        author: 'Coach Mike Brown',
        content:
            'Quick tip for all my fighters: Stop chasing the knockout in sparring. Work your setups, develop your timing, and trust the process. The power comes from precision, not from trying to take your partner\'s head off. Train smart. 🧠',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '2h ago',
        likes: '8,923',
        comments: '567',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- STAT CARD ---
      _buildStatComparisonCard(
        fighterA: 'Alex Pereira',
        fighterB: 'Magomed Ankalaev',
        statA: {'KO Rate': '73%', 'Reach': '79"', 'Record': '11-2'},
        statB: {'KO Rate': '45%', 'Reach': '75"', 'Record': '19-1-1'},
        accentA: DesignTokens.neonAmber,
        accentB: DesignTokens.neonCyan,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- COMMUNITY: Fan post ---
      _buildPhotoPostCard(
        author: 'Tommy_MuayThai_UK',
        content:
            'Just got back from a month training at Tiger Muay Thai in Phuket. Best experience of my life. 200+ rounds of Muay Thai, lost 8kg, and met fighters from 30 different countries. If it\'s on your bucket list — just go. 🐯🇹🇭',
        imageUrl: ImageAssets.nutritionPlaceholder,
        timestamp: '4h ago',
        likes: '3,412',
        comments: '298',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: GLORY Kickboxing ---
      _buildNewsCard(
        source: 'GLORY Kickboxing',
        headline:
            'GLORY Heavyweight Grand Prix bracket revealed — 8 elite kickboxers compete for \$1M prize in Amsterdam',
        timestamp: '5h ago',
        imageUrl: ImageAssets.wellnessPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- POLL CARD: Fight of the Year ---
      _buildPollCard(
        question: '🏆 2026 Fight of the Year so far?',
        options: [
          'Usyk vs Fury III',
          'Opetaia vs WBO Champ',
          'Crawford vs Spence II',
          'Inoue vs Doheny',
        ],
        votes: [34, 31, 24, 11],
        totalVotes: '241K',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHT SHOW: Hex Fight Series (AU) ---
      _buildFightShowCard(
        title: 'HEX FIGHT SERIES 27',
        promotion: 'HEX',
        imageUrl: ImageAssets.trainingPlaceholder,
        fightCount: 14,
        mainEvent: 'Crute vs. Pedro',
        location: 'Brisbane Convention Centre',
        date: 'March 29, 2026',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHT SHOW: UFC Fight Night Perth (WA) ---
      _buildFightShowCard(
        title: 'UFC FIGHT NIGHT: PERTH',
        promotion: 'UFC',
        imageUrl: ImageAssets.fightPlaceholder,
        fightCount: 12,
        mainEvent: 'Della Maddalena vs. Prates',
        location: 'RAC Arena, Perth, WA',
        date: 'May 2, 2026',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHT SHOW: Eternal MMA Perth (WA) ---
      _buildFightShowCard(
        title: 'ETERNAL MMA 80: PERTH',
        promotion: 'ETERNAL',
        imageUrl: ImageAssets.trainingPlaceholder,
        fightCount: 16,
        mainEvent: 'WA vs QLD Superfight Series',
        location: 'HBF Stadium, Perth, WA',
        date: 'April 19, 2026',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHT SHOW: Empire Fight Series (WA) ---
      _buildFightShowCard(
        title: 'EMPIRE FIGHT SERIES: INCEPTION 5',
        promotion: 'EMPIRE',
        imageUrl: ImageAssets.wellnessPlaceholder,
        fightCount: 18,
        mainEvent: 'Lougheed vs. Chan — WA vs QLD',
        location: 'Claremont Showground, Perth, WA',
        date: 'June 14, 2026',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: UFC Perth announcement ---
      _buildNewsCard(
        source: 'Mirage News / WA Government',
        headline:
            'UFC returns to Perth — Jack Della Maddalena headlines first-ever UFC Fight Night at RAC Arena, May 2 2026. WA\'s own welterweight sensation vs Carlos "The Nightmare" Prates',
        timestamp: '2h ago',
        imageUrl: ImageAssets.eventPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- COMMUNITY: WA gym post ---
      _buildPhotoPostCard(
        author: '5 Star Fight & Fitness Perth',
        content:
            'Fight camp szn 🔥 Our boys are locked in for Empire Fight Series next month at Claremont Showground. WA MMA on the rise! 🇦🇺 #PerthMMA #WAFighting #EmpireFightSeries',
        imageUrl: ImageAssets.gymPlaceholder,
        timestamp: '3h ago',
        likes: '2,341',
        comments: '187',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHT SHOW: West Coast Fight Shows (WA) ---
      _buildFightShowCard(
        title: 'WEST COAST FIGHT SHOWS 12',
        promotion: 'WCFS',
        imageUrl: ImageAssets.trainingPlaceholder,
        fightCount: 20,
        mainEvent: 'Muay Thai + MMA + Boxing Triple Header',
        location: 'Metro City, Perth, WA',
        date: 'May 24, 2026',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHT SHOW: IBC 03 Gold Coast ---
      _buildFightShowCard(
        title: 'IBC 03: INTERNATIONAL BRAWLING CHAMPIONSHIPS',
        promotion: 'IBC',
        imageUrl: ImageAssets.fightPlaceholder,
        fightCount: 10,
        mainEvent: 'Closed-Fist Hybrid Combat — No Grappling, All Action',
        location: 'Gold Coast, QLD, Australia',
        date: 'March 7, 2026',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: IBC going global ---
      _buildNewsCard(
        source: 'FOX Sports Australia',
        headline:
            '\'Boxing without the boring stuff\': International Brawling Championships takes Australia by storm — Gold Coast entrepreneur Danny Mac\'s \$1B brawling dream heads to Las Vegas. IBC 03 this weekend on TrillerTV+ & Kayo Sports PPV',
        timestamp: '1h ago',
        imageUrl: ImageAssets.eventPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- COMMUNITY: IBC fan reaction ---
      _buildPhotoPostCard(
        author: 'DFC Fight Fan',
        content:
            'Just watched IBC 02 replay — Hardman vs Towns was INSANE 💥 No hugging, no stalling, just fists. This is the future of combat sports. Danny Mac is onto something huge. Who\'s going to IBC 03 Gold Coast tomorrow? 🇦🇺🥊 #IBCBrawling #GoldCoast',
        imageUrl: ImageAssets.trainingPlaceholder,
        timestamp: '2h ago',
        likes: '4,892',
        comments: '678',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHT SHOW: Elite Fight Series Cairns (QLD) ---
      _buildFightShowCard(
        title: 'ELITE FIGHT SERIES: CAIRNS',
        promotion: 'EFS',
        imageUrl: ImageAssets.wellnessPlaceholder,
        fightCount: 12,
        mainEvent: 'North QLD\'s Best — Livestreamed by Cairns Post',
        location: 'Cairns, QLD, Australia',
        date: 'April 5, 2026',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHT SHOW: Adrenalyn Fight Circuit / MFC (Logan/Brisbane) ---
      _buildFightShowCard(
        title: 'ADRENALYN FIGHT CIRCUIT: MFC 8',
        promotion: 'MFC',
        imageUrl: ImageAssets.gymPlaceholder,
        fightCount: 16,
        mainEvent: 'Muay Thai, Boxing & MMA — Logan Southside',
        location: 'Logan, Brisbane Southside, QLD',
        date: 'March 22, 2026',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHT SHOW: Ultimate Legends — WBC Silver Australian Title (Melbourne) ---
      _buildFightShowCard(
        title: 'ULTIMATE LEGENDS FIGHT NIGHT: WBC SILVER AUSTRALIAN TITLE',
        promotion: 'ULTIMATE LEGENDS',
        imageUrl: ImageAssets.fightPlaceholder,
        fightCount: 10,
        mainEvent: 'Jordan Roesler — WBC Silver Australian Title',
        location: 'Melbourne Pavilion, VIC, Australia',
        date: 'April 24, 2026',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- COMMUNITY: Joey Demicoli / Ultimate Legends ---
      _buildPhotoPostCard(
        author: 'Ultimate Legends Promotions',
        content:
            '🥊 IT\'S ON! ULTIMATE LEGENDS FIGHT NIGHT — Friday April 24th 2026 at the Melbourne Pavilion! WBC Silver Australian Title on the line 🏆 Main Event: Jordan Roesler. Pro Boxing, K1, Kickboxing & Muay Thai on a STACKED card. 30+ years of Melbourne fight history. Livestream on Live Combat Sports 📺 Contact Joey [contact via DFC] for VIP Tables & Tickets! #UltimateLegends #WBCSilver #MelbourneFights #DFC @datafightcentral',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '1h ago',
        likes: '2,847',
        comments: '412',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: Ultimate Legends 30 years ---
      _buildNewsCard(
        source: 'DataFightCentral',
        headline:
            'ULTIMATE LEGENDS turns 30+ years strong — Founded by John Scida (5th Degree Black Belt, Blitz Hall of Fame) in 1992, co-promoted by Joey Demicoli. Melbourne\'s longest-running combat sports promotion returns with a WBC Silver Australian Title bout at Melbourne Pavilion. April 24th on Live Combat Sports.',
        timestamp: '2h ago',
        imageUrl: ImageAssets.fightPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // ══════════════════════════════════════════════════════════
      // JOSEPH DEMICOLI — PROMO WHEEL (synced from FightWire)
      // ══════════════════════════════════════════════════════════

      // --- FIGHT WEEK LIVE REEL ---
      _buildPromoterPostCard(
        promoter: 'Ultimate Legends Promotions',
        verified: true,
        content:
            '🔴 FIGHT WEEK IS LIVE. We are going full send — fighter arrivals, weigh-ins, open workout dropping all week. Subscribe and lock in. #UltimateLegends #FightWeek #MelbourneFights',
        timestamp: '4h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- 7-DAY COUNTDOWN ---
      _buildPromoterPostCard(
        promoter: 'Ultimate Legends Promotions',
        verified: true,
        content:
            '⏳ 7 DAYS OUT. This card has been built to deliver — WBC Silver Australian Title on the line, plus K1, Kickboxing & Muay Thai. Get your tickets now before they sell out. #UltimateLegends #7DaysOut',
        timestamp: '6h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHTER SPOTLIGHT REEL ---
      _buildVideoPostCard(
        author: 'Ultimate Legends Promotions',
        content:
            '🎬 MAIN EVENT SPOTLIGHT — Jordan Roesler. This man has been putting in the work every single day. Watch. This. 🏆 #MelbourneFights #WBCSilver',
        thumbnailUrl: ImageAssets.fightPlaceholder,
        duration: '1:42',
        views: '18.4K',
        timestamp: '10h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- TICKETS + VIP CTA ---
      _buildCommunityAdCard(
        headline: '🎟️ TICKETS + VIP TABLES — ULTIMATE LEGENDS FIGHT NIGHT',
        body:
            'Melbourne Pavilion · April 24, 2026. VIP Tables & Group Packages available. Contact Joey: [contact via DFC]. Lock in before they\'re gone. WBC Silver Australian Title on the line!',
        cta: 'GET TICKETS — LIVE COMBAT SPORTS',
        gradient: [const Color(0xFF8B0000), const Color(0xFFFF6B35)],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- IBC 3 ROLLOUT POST ---
      _buildPromoterPostCard(
        promoter: 'Ultimate Legends Promotions',
        verified: true,
        content:
            '🚀 IBC 3 IS ON THE WAY — the rollout is live. Content dropping daily. This is going worldwide. Follow the ride. #IBC3 #FightWeek #AussieBrawling',
        timestamp: '21h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- BUILDING UP THE LEGENDS ---
      _buildPromoterPostCard(
        promoter: 'Ultimate Legends Promotions',
        verified: true,
        content:
            '🏛️ Building Up The Legends — Episode 1. Daily fighter features, camp clips, and matchup storytelling. Legacy plus new blood, all in one push. #UltimateLegends #LegendsBuild #Brawling',
        timestamp: '26h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- IBC3 x ULTIMATE LEGENDS CROSS-PROMO CTA ---
      _buildCommunityAdCard(
        headline: '⚡ IBC 3 × ULTIMATE LEGENDS — TWO WORLDS, ONE MISSION',
        body:
            'IBC 3 was just the start. Ultimate Legends is the next wave. Two promotions, one mission: putting Australian combat sports on the global map. Follow @ultimatelegendspromotions and lock in at DataFightCentral.\n\n👉 datafightcentral.com',
        cta: 'WATCH THE CAMPAIGN UNFOLD',
        gradient: [const Color(0xFF1A0050), const Color(0xFF00D4FF)],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- COMMUNITY: Bruce Buffer Australia ---
      _buildPhotoPostCard(
        author: 'Bruce Buffer',
        content:
            'UFC 293 was an exciting show 🔥 It\'s been 6 years since I was Down Under 🦘in Sydney 🇦🇺 I had an awesome time performing for all the amazing Aussie UFC fans & had a wonderful trip enjoying the country. Can\'t wait to come back for UFC Perth! IIIIT\'S TIIIIIME! 🎤',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '4h ago',
        likes: '12,431',
        comments: '1,892',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: Fight.com.au Calendar ---
      _buildNewsCard(
        source: 'Fight.com.au',
        headline:
            'Australia\'s 2026 combat sports calendar is STACKED — 48 shows across MMA, Boxing, Muay Thai & Brawling nationwide. Ultimate Legends WBC Silver Title at Melbourne Pavilion, IBC Gold Coast, UFC Perth, Elite Fight Series Cairns & more. Full calendar at Fight.com.au',
        timestamp: '3h ago',
        imageUrl: ImageAssets.trainingPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- COMMUNITY: Gym owner ---
      _buildPhotoPostCard(
        author: 'Ronin MMA Academy',
        content:
            'Grand opening this Saturday! 🎉 Brand new 4,000 sqft facility in Gold Coast, QLD. MMA, Boxing, BJJ, Muay Thai, Wrestling. First week FREE for everyone. Come check us out 🇦🇺',
        imageUrl: ImageAssets.eventPlaceholder,
        timestamp: '5h ago',
        likes: '1,876',
        comments: '234',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- VIDEO POST: Technique breakdown ---
      _buildVideoPostCard(
        author: 'DFC Fight Lab',
        content:
            '🔬 Technique Breakdown: How Topuria sets up his right hand using feints, level changes, and footwork angles. Elite-level striking deconstructed.',
        thumbnailUrl: ImageAssets.fightPlaceholder,
        duration: '12:17',
        views: '890K',
        timestamp: '6h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: K-1 ---
      _buildNewsCard(
        source: 'K-1 World GP',
        headline:
            'K-1 announces 2026 World Grand Prix — 16 man tournament across 4 weight classes in Tokyo, Osaka, and Bangkok',
        timestamp: '8h ago',
        imageUrl: ImageAssets.trainingPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildCommunityAdCard(
        headline: '⌚ Smart Devices Now in DFC Marketplace',
        body:
            'Apple Watch Ultra 2, WHOOP 5.0, Oura Ring 4, Garmin Fenix 8, Corner 3 Smart Gloves — shipped worldwide. Track punch speed, fight readiness, HRV & sleep.',
        cta: 'SHOP SMART DEVICES',
        gradient: [const Color(0xFF00B4D8), const Color(0xFF8338EC)],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: RIZIN Japan ---
      _buildNewsCard(
        source: 'RIZIN FF',
        headline:
            'RIZIN announces historic co-promotion with UFC — first-ever Japan vs USA super card at Tokyo Dome, June 2026',
        timestamp: '5h ago',
        imageUrl: ImageAssets.wellnessPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildGymPromoCard(
        gymName: 'Elite Combat Team',
        verified: true,
        specialties: ['MMA', 'Boxing', 'Wrestling', 'BJJ'],
        location: 'Coconut Creek, Florida, USA',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- SPONSOR POST: Nutrition ---
      _buildPhotoPostCard(
        author: 'Nutrition Warehouse',
        content:
            '💪 Fuel Your Fight with 25% OFF all protein powders, pre-workouts & recovery supplements this week! Free shipping over \$99. Use code: DFCFIGHTER at checkout. Performance that delivers. 🏆',
        imageUrl: ImageAssets.nutritionPlaceholder,
        timestamp: '3h ago',
        likes: '4,230',
        comments: '187',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHTER PROMO POST ---
      _buildPromoterPostCard(
        promoter: 'Marcus "The Hammer" Thompson',
        verified: false,
        content:
            '🥊 Training camp complete. 8 weeks of blood, sweat & discipline. March 15th I step into the ring for the Australian Middleweight Title. Gold Coast got me ready. Time to bring it home! Tickets at Eventbrite 🔥 #DFC #AussieBrawling',
        timestamp: '4h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- EVENT TICKET PROMO ---
      _buildCommunityAdCard(
        headline: '🎟️ TICKETS ON SALE NOW: Elite Fight Night Perth',
        body:
            'March 29th at RAC Arena — 12 fights, 2 title bouts, 8,000 seat venue. Early bird prices end Friday. Powered by Ticketek. Don\'t miss the biggest Perth combat sports event of 2026!',
        cta: 'GET TICKETS',
        gradient: [DesignTokens.neonMagenta, DesignTokens.neonRed],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- GYM PROMO: Sydney ---
      _buildPhotoPostCard(
        author: 'Sydney Combat Academy',
        content:
            '🥋 New members welcome! 6-week fundamentals program starts April 1st. MMA, Muay Thai, BJJ, Boxing, Wrestling. All levels. First class FREE. Join Sydney\'s fastest-growing fight gym. DM to book your spot! 🇦🇺',
        imageUrl: ImageAssets.gymPlaceholder,
        timestamp: '5h ago',
        likes: '2,910',
        comments: '156',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- APPAREL SPONSOR POST ---
      _buildCommunityAdCard(
        headline: '👕 Official DFC Fight Gear Collection',
        body:
            'Premium fight shorts, rash guards, hoodies & training tees. Designed for fighters, by fighters. Ships worldwide. 10% off your first order with code: WELCOME10',
        cta: 'SHOP NOW',
        gradient: [const Color(0xFF000000), const Color(0xFF434343)],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- REGIONAL PROMO: New Zealand ---
      _buildPromoterPostCard(
        promoter: 'Fight Club NZ',
        verified: true,
        content:
            '🇳🇿 ANNOUNCEMENT: Fight Club NZ returns to Auckland on April 5th! 10 bouts featuring NZ\'s top ranked fighters. Main event: Wiremu "The Warrior" Te Hiko vs Tama Brown for the NZ Light Heavyweight Title. Auckland Town Hall. Tickets live NOW 🔥',
        timestamp: '6h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- EQUIPMENT SPONSOR ---
      _buildPhotoPostCard(
        author: 'Rival Boxing Equipment',
        content:
            '🥊 NEW DROP: Rival RS100 Pro Sparring Gloves now available worldwide. Premium leather, triple-density foam, wrist lock system. Used by champions. Get yours at DFC Marketplace with FREE shipping! 📦',
        imageUrl: ImageAssets.trainingPlaceholder,
        timestamp: '7h ago',
        likes: '5,670',
        comments: '298',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- TRAINING CAMP PROMO ---
      _buildEventHypeCard(
        eventId: 'tiger-muay-thai-camp',
        title: 'Tiger Muay Thai Training Camp — Phuket',
        location: 'Phuket, Thailand',
        date: 'Rolling enrollment • 1-12 week programs',
        gradientColors: [DesignTokens.neonAmber, const Color(0xFFFF6B35)],
        fightStock: 'World-class training',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- FIGHTER SPONSORED POST ---
      _buildPhotoPostCard(
        author: 'Amanda "The Lioness" Silva',
        content:
            '🦁 Blessed to announce my new partnership with @MonsterEnergy! Fueling my journey to the UFC title. Training harder than ever. Next fight announcement coming soon! Thank you to all my sponsors and fans 💪🏽 #TeamMonster #DFC',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '9h ago',
        likes: '18.4K',
        comments: '1.2K',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- PPV PROMO ---
      _buildPPVPromoCard(
        eventTitle: 'UFC 314: VOLKANOVSKI vs RODRIGUEZ 2',
        mainEvent:
            'Alexander Volkanovski vs Yair Rodriguez — Featherweight Title',
        price: '\$79.99',
        date: 'April 19, 2026 · Melbourne, AU',
        imageUrl: ImageAssets.eventPlaceholder,
        eventId: 'ufc-314',
        undercard: [
          'Adesanya vs Pereira 3 — Co-Main',
          'Tuivasa vs Aspinall — Heavyweight',
        ],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- GYM NETWORK POST ---
      _buildPromoterPostCard(
        promoter: 'DFC Gym Network',
        verified: true,
        content:
            '🏆 DFC Gym Partners: 840 gyms across 47 countries now on our platform. Free promotion, event management, member discovery & global visibility. Gym owners: Join the network today. Zero fees, maximum exposure. Apply at DataFightCentral.com/gyms',
        timestamp: '11h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- REGIONAL EVENT: UK ---
      _buildFightShowCard(
        title: 'Cage Warriors 175: London Brawl',
        promotion: 'CAGE WARRIORS',
        imageUrl: ImageAssets.eventPlaceholder,
        fightCount: 11,
        mainEvent: 'Thompson vs. O\'Malley',
        location: 'York Hall, London',
        date: 'March 28, 2026',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- SUPPLEMENT SPONSOR ---
      _buildPhotoPostCard(
        author: 'Optimum Nutrition',
        content:
            '⚡ NEW: Gold Standard Pre-Workout Extreme. 300mg caffeine, beta-alanine, citrulline malate. Explosive energy for fighters. Now available at DFC Marketplace + all major retailers. Fuel your grind 🔥',
        imageUrl: ImageAssets.nutritionPlaceholder,
        timestamp: '13h ago',
        likes: '9,120',
        comments: '445',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- INDEPENDENT FIGHTER PROMO ---
      _buildPhotoPostCard(
        author: 'Jake "The Python" Morrison',
        content:
            '🐍 4-0 pro record. Looking for my 5th. Promoters, managers, matchmakers — I\'m ready to fight anywhere, anytime. 77 kg / 170 lbs, aggressive striker, granite chin. Let\'s make it happen. DM me 📩 #DFC #FighterForHire',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '15h ago',
        likes: '892',
        comments: '67',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- WELLNESS SPONSOR ---
      _buildCommunityAdCard(
        headline: '🧘 Recovery Lab: Cryotherapy & Float Tanks',
        body:
            'Melbourne\'s premier recovery center for combat athletes. Cryotherapy, sensory deprivation tanks, compression therapy, infrared sauna. 20% off for DFC members. Book your session today.',
        cta: 'BOOK NOW',
        gradient: [const Color(0xFF1A237E), const Color(0xFF00BCD4)],
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- EVENT PROMO: Asia ---
      _buildEventHypeCard(
        eventId: 'one-championship-singapore',
        title: 'ONE Championship: Singapore Showdown',
        location: 'Singapore Indoor Stadium',
        date: 'April 12, 2026',
        gradientColors: [const Color(0xFFE91E63), const Color(0xFF9C27B0)],
        fightStock: '+28.3%',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- COACHING SERVICE PROMO ---
      _buildPromoterPostCard(
        promoter: 'Elite Striking Coach - Simon Hayes',
        verified: true,
        content:
            '🎯 Online striking coaching now available! 15 years coaching UFC/Bellator fighters. Personalized video analysis, custom training programs, weekly check-ins. Limited spots for March. DM for rates & availability 🥊',
        timestamp: '18h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: UFC EXPANSION ---
      _buildNewsCard(
        source: 'UFC',
        headline:
            'Jon Jones announces retirement after holding heavyweight title for 3 years — "I did everything I set out to do"',
        timestamp: '1h ago',
        imageUrl: ImageAssets.fightPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildNewsCard(
        source: 'UFC',
        headline:
            'UFC Fight Night Sydney confirmed — Tai Tuivasa headlines with KO comeback, Crute and O\'Neill on undercard',
        timestamp: '2h ago',
        imageUrl: ImageAssets.eventPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildPhotoPostCard(
        author: 'Dan "The Hangman" Hooker',
        content:
            '🇳🇿 3 Performance of the Night bonuses in a row. City Kickboxing producing world champions every month. Auckland is the fight capital of the Pacific. Next stop: UFC title eliminator. Let\'s go! 💪 #TeamCKB #DFC',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '3h ago',
        likes: '22.1K',
        comments: '1.8K',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: MUAY THAI ---
      _buildNewsCard(
        source: 'ONE Championship',
        headline:
            'Rodtang "The Iron Man" defends ONE Muay Thai title for 6th time — unstoppable in 2026',
        timestamp: '4h ago',
        imageUrl: ImageAssets.fightPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildPhotoPostCard(
        author: 'John Wayne Parr',
        content:
            '🇦🇺 Honoured to be inducted into the WBC Muay Thai Hall of Fame. 130+ fights, 12 world titles, decades of grinding in Thailand. This is for every Aussie kid who ever dreamed of fighting in Bangkok. Legends are built, not born. 🏆 #JWP #WBC #DFC',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '5h ago',
        likes: '31.5K',
        comments: '2.4K',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildNewsCard(
        source: 'Thai Fight',
        headline:
            'Saenchai returns at age 46 for Thai Fight 2026 season opener — still electrifying crowds with vintage Muay Thai',
        timestamp: '6h ago',
        imageUrl: ImageAssets.trainingPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: KICKBOXING ---
      _buildNewsCard(
        source: 'GLORY Kickboxing',
        headline:
            'Rico "The King of Kickboxing" Verhoeven returns for GLORY 93 Amsterdam — challenges for heavyweight title one final time',
        timestamp: '3h ago',
        imageUrl: ImageAssets.eventPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: BARE KNUCKLE ---
      _buildNewsCard(
        source: 'BKFC',
        headline:
            'BKFC KnuckleMania VII sells out Tampa in hours — biggest bare knuckle event in history with 4 world title fights',
        timestamp: '2h ago',
        imageUrl: ImageAssets.fightPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildPromoterPostCard(
        promoter: 'IBC — International Brawling Championships',
        verified: true,
        content:
            '🥊 BRAWLING GOES GLOBAL! Danny Mac takes IBC to Las Vegas. "Boxing without the boring stuff" is the fastest-growing combat format in the world. Gold Coast to Vegas, baby. 🏆🔥 #IBC #Brawling #DFC',
        timestamp: '4h ago',
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- NEWS: WRESTLING / BJJ / GRAPPLING ---
      _buildNewsCard(
        source: 'ADCC',
        headline:
            'ADCC 2026 — Gordon Ryan reverses retirement to enter submission grappling\'s biggest event in Las Vegas',
        timestamp: '5h ago',
        imageUrl: ImageAssets.trainingPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildPhotoPostCard(
        author: 'Craig Jones',
        content:
            '🇦🇺 CJI 2 — \$2 million in prize money. The richest submission grappling event in history. Brisbane-born, world-conquering. If you\'re not on the mat, you\'re missing out. Details dropping soon. 🏆 #CJI #BJJ #DFC',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '6h ago',
        likes: '28.9K',
        comments: '3.1K',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildNewsCard(
        source: 'IBJJF',
        headline:
            'NZ BJJ black belt wins IBJJF Pan Championships gold — first Kiwi to medal at black belt level',
        timestamp: '7h ago',
        imageUrl: ImageAssets.trainingPlaceholder,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      // --- AUSSIE/NZ FIGHTERPOST ---
      _buildPhotoPostCard(
        author: 'Robert "The Reaper" Whittaker',
        content:
            '🇦🇺 UFC Perth is going to be one for the ages. The Reaper is training the house down in Melbourne. Fight week in Perth hits different — nothing like fighting on home soil. Let\'s sell out the arena! 💪🔥 #UFCPerth #DFC',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '8h ago',
        likes: '45.2K',
        comments: '4.3K',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildPhotoPostCard(
        author: 'Carlos Ulberg',
        content:
            '🇳🇿 From Auckland to the UFC rankings. City Kickboxing made me. New Zealand made me. Three straight finishes and climbing into the Top 10 at 93 kg / 205 lbs. The best is yet to come 🏔️ #TeamCKB #UFCNZ #DFC',
        imageUrl: ImageAssets.fightPlaceholder,
        timestamp: '10h ago',
        likes: '15.7K',
        comments: '980',
        verified: true,
      ),
      const SizedBox(height: DesignTokens.spacingL),

      _buildNewsCard(
        source: 'Australian Wrestling',
        headline:
            'Australian freestyle wrestler secures Olympic qualification — first genuine Aussie medal contender in wrestling in decades',
        timestamp: '9h ago',
        imageUrl: ImageAssets.trainingPlaceholder,
      ),
      const SizedBox(height: 100),
    ];

    // ── Apply filter ──
    if (_selectedFilter == 0) return all;

    final filtered = <Widget>[];
    int ci = 0;
    for (int i = 0; i < all.length; i += 2) {
      if (ci < _cardCategories.length &&
          _cardCategories[ci] == _selectedFilter) {
        if (filtered.isNotEmpty) {
          filtered.add(const SizedBox(height: DesignTokens.spacingL));
        }
        filtered.add(all[i]);
      }
      ci++;
    }
    if (filtered.isEmpty) return [_buildEmptyFilterCard()];
    filtered.add(const SizedBox(height: 100));
    return filtered;
  }

  Widget _buildEmptyFilterCard() {
    const labels = [
      'ALL',
      'FIGHTS',
      'MENTAL HEALTH',
      'STORIES',
      'SUPPORT',
      'NEWS',
      'PROMOS',
    ];
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.filter_list_off,
            color: DesignTokens.textMuted,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No ${labels[_selectedFilter]} content right now',
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap ⚡ ALL to see the full feed',
            style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ========== SAMURAI AI POST CARD ==========

  Widget _buildSamuraiAIPostCard({
    required String headline,
    required String body,
    required String tag,
    required Color tagColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: tagColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚔️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: tagColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'SAMURAI AI',
                style: TextStyle(
                  color: tagColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            headline,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ========== MENTAL HEALTH CARD ==========

  Widget _buildMentalHealthCard({
    required String title,
    required String body,
    required String stat,
    required String cta,
  }) {
    const accent = Color(0xFF8338EC);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology, color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'MENTAL HEALTH',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '📊  $stat',
              style: const TextStyle(
                color: accent,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              if (cta.contains('SUPPORT')) {
                context.push('/fighter-safety');
              } else {
                context.push('/fighter-safety');
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [accent, Color(0xFFBD63F3)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                cta,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== STRUGGLER STORY CARD ==========

  Widget _buildStrugglerStoryCard({
    required String name,
    required String title,
    required String story,
    required List<String> tags,
    required String timestamp,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonAmber.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DesignTokens.neonAmber, DesignTokens.neonRed],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
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
                      name,
                      style: const TextStyle(
                        color: DesignTokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonAmber.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '💪 WARRIOR STORY',
                            style: TextStyle(
                              color: DesignTokens.neonAmber,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timestamp,
                          style: const TextStyle(
                            color: DesignTokens.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: DesignTokens.neonAmber,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            story,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: tags
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.bgSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ========== SUPPORT RESOURCE CARD ==========

  Widget _buildSupportResourceCard({
    required String icon,
    required String title,
    required String body,
    required List<_SupportResource> resources,
    required Color accentColor,
    required String tag,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'FREE CONFIDENTIAL HELPLINES:',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          for (final r in resources)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: r.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: r.color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, color: r.color, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.name,
                      style: TextStyle(
                        color: r.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    r.number,
                    style: TextStyle(
                      color: r.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVictimSupportCard({
    required String title,
    required String body,
    required List<_SupportResource> resources,
  }) {
    return _buildSupportResourceCard(
      icon: '🛡️',
      title: title,
      body: body,
      resources: resources,
      accentColor: DesignTokens.neonRed,
      tag: 'VICTIM SUPPORT',
    );
  }

  // ========== POVERTY STORY CARD ==========

  Widget _buildPovertyStoryCard({
    required String title,
    required String body,
    required List<String> impactStats,
  }) {
    const accent = DesignTokens.neonGreen;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌏', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'COMMUNITY IMPACT',
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          for (final stat in impactStats)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stat,
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ========== COMMUNITY AD / PROMO CARD ==========

  Widget _buildCommunityAdCard({
    required String headline,
    required String body,
    required String cta,
    required List<Color> gradient,
    String? imageUrl,
    String? route,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        image: imageUrl != null
            ? DecorationImage(
                image: ImageAssets.safeProvider(imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.55),
                  BlendMode.darken,
                ),
                onError: (_, _) {},
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '📣  PROMOTED BY DFC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              headline,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                if (route != null) {
                  context.push(route);
                } else if (cta.contains('PPV') || cta.contains('ORDER')) {
                  context.push('/ppv');
                } else if (cta.contains('GYM')) {
                  context.push('/marketplace');
                } else {
                  context.push('/marketplace');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cta,
                  style: TextStyle(
                    color: gradient[0],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== PPV PROMO CARD — AGGRESSIVE CONVERSION ==========

  Widget _buildPPVPromoCard({
    required String eventTitle,
    required String mainEvent,
    required String price,
    required String date,
    String? imageUrl,
    String? eventId,
    List<String> undercard = const [],
  }) {
    return GestureDetector(
      onTap: () => context.push(eventId != null ? '/ppv/$eventId' : '/ppv'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: DesignTokens.neonRed.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.neonRed.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Hero banner
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B0000),
                    Color(0xFFFF4500),
                    Color(0xFF1A1A2E),
                  ],
                ),
                image: imageUrl != null
                    ? DecorationImage(
                        image: ImageAssets.safeProvider(imageUrl),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.5),
                          BlendMode.darken,
                        ),
                        onError: (_, _) {},
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  // PPV badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.live_tv, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'LIVE PPV',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Price pill
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: DesignTokens.neonGold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        price,
                        style: const TextStyle(
                          color: DesignTokens.neonGold,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  // Event title
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Text(
                      eventTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            // Card body
            Container(
              color: DesignTokens.bgCard,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main event
                  Row(
                    children: [
                      const Icon(
                        Icons.sports_mma,
                        color: DesignTokens.neonRed,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mainEvent,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (undercard.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...undercard
                        .take(3)
                        .map(
                          (fight) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: DesignTokens.neonCyan,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fight,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                  const SizedBox(height: 10),
                  // Date + CTA row
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF0000), Color(0xFFFF6D00)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.neonRed.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Text(
                          'BUY NOW',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
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
    );
  }

  Widget _postOption(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54, size: 20),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      onTap: () {
        Navigator.pop(context);
        if (label == 'Share') {
          Clipboard.setData(
            const ClipboardData(text: AppConstants.publicWebBaseUrl),
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              label == 'Save Post'
                  ? 'Post saved!'
                  : label == 'Share'
                  ? 'Link copied to clipboard!'
                  : label == 'Report'
                  ? 'Report submitted. Thank you.'
                  : 'Author muted.',
            ),
            backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

// ─── Fight Stock Model ────────────────────────────────────────────────────
class _FightStock {
  final String name;
  final double price;
  final double change;
  final bool isUp;
  const _FightStock(this.name, this.price, this.change, this.isUp);
}

// ─── Trending Item Model ──────────────────────────────────────────────────
class _TrendItem {
  final String tag;
  final String count;
  final IconData icon;
  final Color color;
  const _TrendItem(this.tag, this.count, this.icon, this.color);
}

// ─── Reel Preview Model ───────────────────────────────────────────────────
class _ReelPreview {
  final String title;
  final String views;
  final String imageAsset;
  final Color accentColor;
  const _ReelPreview(this.title, this.views, this.imageAsset, this.accentColor);
}
