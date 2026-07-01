import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/web_route_test_hook.dart';
import '../../../shared/models/community/community_models.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/models/ppv_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/social_service.dart';
import '../../../shared/services/fight_news_service.dart';
import '../../../shared/services/story_engine.dart';
import '../widgets/dfc_post_card.dart';
import '../widgets/dfc_event_card.dart';
import '../widgets/dfc_news_card.dart';
import '../widgets/dfc_hero_banner.dart';
import '../widgets/dfc_live_carousel.dart';
import '../widgets/create_post_bar.dart';
import '../../../shared/widgets/dfc_skeletons.dart';
import '../widgets/feed_ppv_card.dart';
import '../../../shared/widgets/dfc_network_image.dart';

class DFCFeedScreen extends StatefulWidget {
  const DFCFeedScreen({super.key});

  @override
  State<DFCFeedScreen> createState() => _DFCFeedScreenState();
}

class _DFCFeedScreenState extends State<DFCFeedScreen>
    with AutomaticKeepAliveClientMixin {
  late final SocialService _socialService;
  late final ScrollController _scrollController;

  final List<dynamic> _items = []; // Mixed: Post + EventModel
  bool _depsInitialized = false;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _initialLoaded = false;
  String _selectedLane = 'all';

  // Feed tab: 0 = For You (all), 1 = Following
  int _feedTab = 0;
  Set<String> _followingIds = {};
  List<PPVEvent> _ppvEvents = [];

  // User location for event prioritization
  String? _userCity;
  String? _userState;
  String? _userCountry;

  // Real-time new-post detection (Facebook-style)
  StreamSubscription<List<Post>>? _newPostSub;
  bool _newPostsAvailable = false;
  int _lastKnownPostCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    setWebRouteTestHook('social-card');
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      _depsInitialized = true;
      _socialService = context.read<SocialService>();

      // Get user location from auth metadata
      final user = context.read<AuthService>().userModel;
      if (user?.metadata != null) {
        _userCity = user!.metadata?['city'] as String?;
        _userState = user.metadata?['state'] as String?;
        _userCountry = user.metadata?['country'] as String?;
      }

      _loadInitial();
      _loadFollowingIds();
      _loadPPVEvents();
      _startNewPostListener();
    }
  }

  @override
  void dispose() {
    _newPostSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Listens to the Firestore posts stream in real-time.
  /// When new posts arrive after initial load, shows a "New posts" banner.
  void _startNewPostListener() {
    _newPostSub = _socialService.getFeed().listen(
      (posts) {
        if (!mounted) return;
        if (_lastKnownPostCount == 0) {
          // First emission — just record the baseline count
          _lastKnownPostCount = posts.length;
          return;
        }
        if (posts.length > _lastKnownPostCount) {
          setState(() => _newPostsAvailable = true);
          _lastKnownPostCount = posts.length;
        }
      },
      onError: (_) {
        // Non-blocking — feed still works via manual refresh
      },
    );
  }

  Future<void> _loadInitial() => loadInitial();

  void _onScroll() => onScroll();

  Future<void> _loadFollowingIds() => loadFollowingIds();

  void _loadPPVEvents() => loadPPVEvents();

  void onNewPostsTapped() {
    HapticFeedback.mediumImpact();
    setState(() => _newPostsAvailable = false);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    refresh();
  }

  // Data: Loaders
  Future<void> loadInitial() async {
    setState(() => _isLoading = true);
    final items = await _socialService.getPostsPage(
      refresh: true,
      userCity: _userCity,
      userState: _userState,
      userCountry: _userCountry,
    );
    if (mounted) {
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _isLoading = false;
        _initialLoaded = true;
      });
    }
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();
    final items = await _socialService.getPostsPage(
      refresh: true,
      userCity: _userCity,
      userState: _userState,
      userCountry: _userCountry,
    );
    if (mounted) {
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _isRefreshing = false;
      });
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_socialService.hasMorePosts) return;
    setState(() => _isLoading = true);
    final moreItems = await _socialService.getPostsPage(
      userCity: _userCity,
      userState: _userState,
      userCountry: _userCountry,
    );
    if (mounted) {
      setState(() {
        _items.addAll(moreItems);
        _isLoading = false;
      });
    }
  }

  void onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      loadMore();
    }
  }

  Future<void> loadFollowingIds() async {
    final uid = context.read<AuthService>().firebaseUser?.uid;
    if (uid == null) return;
    try {
      final ids = await _socialService.getFollowingIds(uid);
      // Also include social_graph follows (auto-seeded by SocialOnboardingService)
      if (mounted) {
        setState(() => _followingIds = ids.toSet());
      }
    } catch (_) {
      // Non-blocking — For You tab works without this
    }
  }

  void loadPPVEvents() {
    try {
      PPVService()
          .getUpcomingPPVEvents()
          .take(1)
          .listen(
            (events) {
              if (mounted) setState(() => _ppvEvents = events.take(2).toList());
            },
            onError: (_) {
              // Non-blocking — feed works without PPV cards
            },
          );
    } catch (_) {
      // Non-blocking — feed works without PPV cards
    }
  }

  // UI: Live & Upcoming carousel (extracts events from feed items)
  Widget buildLiveCarousel() {
    final events = _items
        .whereType<EventModel>()
        .where(isRealHomeEvent)
        .toList();
    if (events.isEmpty) return const SizedBox.shrink();
    return DFCLiveUpcomingCarousel(
      events: events,
      onEventTap: (event) {
        HapticFeedback.lightImpact();
        context.push('/event/${event.id}', extra: event);
      },
    );
  }

  // UI: Section header
  bool isRealHomeEvent(EventModel event) {
    if (event.id.startsWith('demo_') || event.id.startsWith('demo-')) {
      return false;
    }
    if (event.source != 'manual') {
      return true;
    }
    return event.createdAt != null || event.updatedAt != null;
  }

  // UI: Section header (Kayo style)
  Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: DesignTokens.textPrimary,
          fontSize: DesignTokens.fontSizeTitleLarge,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  bool matchesLane(dynamic item) {
    switch (_selectedLane) {
      case 'live':
        return item is EventModel && item.status == EventStatus.live;
      case 'events':
        return item is EventModel;
      case 'community':
        return item is Post && item.postType != 'article';
      case 'news':
        return item is FightNewsArticle ||
            (item is Post && item.postType == 'article');
      default:
        return true;
    }
  }

  int laneCount(String lane) {
    if (lane == 'all') return _items.length;
    return _items.where((item) {
      switch (lane) {
        case 'live':
          return item is EventModel && item.status == EventStatus.live;
        case 'events':
          return item is EventModel;
        case 'community':
          return item is Post && item.postType != 'article';
        case 'news':
          return item is FightNewsArticle ||
              (item is Post && item.postType == 'article');
        default:
          return true;
      }
    }).length;
  }

  Widget buildSectionBridge({
    required String eyebrow,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.24),
                  accent.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFlowRail() {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 380;
    final liveCount = _items
        .whereType<EventModel>()
        .where((event) => event.status == EventStatus.live)
        .length;
    final upcomingCount = _items
        .whereType<EventModel>()
        .where((event) => event.status == EventStatus.upcoming)
        .length;
    final postCount = _items.whereType<Post>().length;
    final newsCount = _items.whereType<FightNewsArticle>().length;
    final storyCount = StoryEngine.instance
        .buildFeed(viewerId: 'current_user', followingIds: const {})
        .groups
        .length;

    final cards = [
      (
        icon: Icons.sensors_rounded,
        title: liveCount > 0 ? '$liveCount live now' : 'Live coverage',
        subtitle: liveCount > 0
            ? '$upcomingCount upcoming cards queued behind the live slate'
            : '$upcomingCount upcoming fight cards on the schedule',
        accent: DesignTokens.neonRed,
        onTap: () => context.push('/events'),
      ),
      (
        icon: Icons.radio_button_checked_rounded,
        title: storyCount > 0 ? '$storyCount quick updates' : 'Update reel',
        subtitle: 'Short-form updates from camps, fighters, and partners',
        accent: DesignTokens.neonCyan,
        onTap: () => context.push('/user-search'),
      ),
      (
        icon: Icons.edit_note_rounded,
        title: postCount > 0 ? '$postCount community posts' : 'Open the desk',
        subtitle: 'Publish a clip, result, statement, or camp update',
        accent: DesignTokens.neonAmber,
        onTap: openCompose,
      ),
      (
        icon: Icons.newspaper_rounded,
        title: newsCount > 0
            ? '$newsCount editorial headlines'
            : 'Editorial desk',
        subtitle: 'News and event drops ranked alongside the social feed',
        accent: DesignTokens.neonMagenta,
        onTap: () => context.push('/write-article'),
      ),
    ];

    return SizedBox(
      height: isNarrow ? 216 : 154,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemBuilder: (context, index) {
          final card = cards[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              card.onTap();
            },
            child: Container(
              width: isNarrow ? 204 : 224,
              padding: EdgeInsets.all(isNarrow ? 11 : 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF102033),
                    DesignTokens.bgCard.withValues(alpha: 0.96),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isNarrow ? 30 : 34,
                    height: isNarrow ? 30 : 34,
                    decoration: BoxDecoration(
                      color: card.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      card.icon,
                      color: card.accent,
                      size: isNarrow ? 16 : 18,
                    ),
                  ),
                  SizedBox(height: isNarrow ? 8 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: DesignTokens.textPrimary,
                            fontSize: isNarrow ? 13 : 15,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.subtitle,
                          maxLines: isNarrow ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: isNarrow ? 10.5 : 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemCount: cards.length,
      ),
    );
  }

  // ── Trending Topics (neon pill chips) ──
  Widget buildTrendingTopics() {
    const topics = [
      'UFC 320',
      'Main Event',
      'Title Picture',
      'Bare Knuckle',
      'Knockout Watch',
      'BKFC Australia',
      'Prospect Radar',
      'Fight Business',
    ];
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final label = topics[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/user-search');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1C2C),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Story Ring Tray (Instagram-style ephemeral stories) ──
  Widget buildStoryTray() {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 380;
    final feed = StoryEngine.instance.buildFeed(
      viewerId: 'current_user',
      followingIds: const {},
    );
    final groups = feed.groups;

    return Container(
      height: isNarrow ? 104 : 110,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.bgPrimary.withValues(alpha: 0.8),
            DesignTokens.bgPrimary.withValues(alpha: 0.4),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: groups.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isNarrow ? 58 : 64,
                    height: isNarrow ? 58 : 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.35),
                        width: 2,
                      ),
                      color: DesignTokens.bgCard.withValues(alpha: 0.6),
                    ),
                    child: Icon(
                      Icons.add,
                      color: DesignTokens.neonCyan.withValues(alpha: 0.8),
                      size: isNarrow ? 24 : 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add Update',
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }
          final group = groups[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isNarrow ? 58 : 64,
                  height: isNarrow ? 58 : 64,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: group.hasUnviewed
                        ? const LinearGradient(
                            colors: [
                              DesignTokens.neonCyan,
                              DesignTokens.neonOrange,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: group.hasUnviewed
                        ? null
                        : Border.all(
                            color: DesignTokens.textDisabled,
                            width: 2,
                          ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: DesignTokens.bgCard,
                    child: Text(
                      group.displayName.isNotEmpty
                          ? group.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: DesignTokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 64,
                  child: Text(
                    group.displayName.length > 8
                        ? '${group.displayName.substring(0, 8)}...'
                        : group.displayName,
                    style: TextStyle(
                      color: group.hasUnviewed
                          ? DesignTokens.textPrimary
                          : DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontWeight: group.hasUnviewed
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // UI: Enhanced Compose Prompt with Glass & Neon
  Widget buildComposePrompt() {
    return CreatePostBar(onPostCreated: refresh);
  }

  Widget buildLaneFilters() {
    final lanes = [
      ('all', 'All', Icons.layers_rounded, DesignTokens.neonCyan),
      ('live', 'Live', Icons.sensors_rounded, DesignTokens.neonRed),
      (
        'events',
        'Events',
        Icons.event_available_rounded,
        DesignTokens.neonAmber,
      ),
      ('community', 'Community', Icons.forum_rounded, DesignTokens.neonCyan),
      ('news', 'News', Icons.newspaper_rounded, DesignTokens.neonMagenta),
    ];

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: lanes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (laneKey, label, icon, accent) = lanes[index];
          final isSelected = laneKey == _selectedLane;
          final count = laneCount(laneKey);

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedLane = laneKey);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isSelected
                    ? const Color(0xFF132338)
                    : const Color(0xFF0D1826),
                border: Border.all(
                  color: isSelected
                      ? accent.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.07),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? accent : Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.78),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: isSelected
                            ? accent
                            : Colors.white.withValues(alpha: 0.72),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── In-feed PPV cards (zero-friction buy) ──
  Widget buildPPVSection() {
    if (_ppvEvents.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Icon(
                Icons.live_tv,
                size: 16,
                color: DesignTokens.neonCyan.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              const Text(
                'PPV EVENTS',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/ppv'),
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final event in _ppvEvents) FeedPPVCard(event: event),
      ],
    );
  }

  // ── "For You" / "Following" tab bar (Facebook/Instagram-style) ──
  Widget buildFeedTabs() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          buildTabButton(
            label: 'For You',
            icon: Icons.auto_awesome,
            isActive: _feedTab == 0,
            onTap: () {
              if (_feedTab != 0) {
                HapticFeedback.lightImpact();
                setState(() => _feedTab = 0);
              }
            },
          ),
          buildTabButton(
            label: 'Following',
            icon: Icons.people_outline,
            isActive: _feedTab == 1,
            onTap: () {
              if (_feedTab != 1) {
                HapticFeedback.lightImpact();
                setState(() => _feedTab = 1);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget buildTabButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      DesignTokens.neonCyan.withValues(alpha: 0.2),
                      DesignTokens.neonMagenta.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
            border: isActive
                ? Border.all(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.4),
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? DesignTokens.neonCyan
                    : Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? DesignTokens.neonCyan
                      : Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI: Feed List with Infinite Scroll
  List<Widget> buildFeedItems() {
    if (!_initialLoaded) {
      return [
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: DFCFeedSkeleton(itemCount: 5),
        ),
      ];
    }

    if (_items.isEmpty) {
      return [
        SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildGlassPanel(
                  child: Column(
                    children: [
                      Icon(
                        Icons.sports_mma,
                        size: 64,
                        color: DesignTokens.neonCyan.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            DesignTokens.neonCyan,
                            DesignTokens.neonMagenta,
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'No Posts Yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share fight news, event updates, or training clips',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.diamond,
                            size: 14,
                            color: DesignTokens.neonGold.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Premium visibility for promoters',
                            style: TextStyle(
                              color: DesignTokens.neonGold.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
      ];
    }

    // Filter items based on active tab
    final displayItems = _feedTab == 1 && _followingIds.isNotEmpty
        ? _items.where((item) {
            if (item is Post) return _followingIds.contains(item.userId);
            return true; // Events always show
          }).toList()
        : _items;

    if (displayItems.isEmpty && _feedTab == 1) {
      return [
        SizedBox(
          height: 300,
          child: Center(
            child: buildGlassPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: DesignTokens.neonCyan.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                    ).createShader(bounds),
                    child: const Text(
                      'Follow fighters & fans',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Content from people you follow will appear here',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    for (int index = 0; index <= displayItems.length; index++) {
      // Add shimmer loading at bottom when fetching more
      if (index == displayItems.length) {
        if (_isLoading && _socialService.hasMorePosts) {
          widgets.add(buildLoadingIndicator());
        } else {
          // End of feed badge
          widgets.add(buildEndOfFeedBadge());
        }
        break;
      }

      final item = displayItems[index];

      // Render event card with glass effect
      if (item is EventModel) {
        widgets.add(buildEnhancedEventCard(item, index));
      } else if (item is Post) {
        widgets.add(buildEnhancedPostCard(item, index));
      } else if (item is FightNewsArticle) {
        widgets.add(buildEnhancedNewsCard(item, index));
      }
    }
    return widgets;
  }

  // Premium Glass Panel Wrapper
  Widget buildGlassPanel({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: kIsWeb
                ? [
                    const Color(0xFF0A1628).withValues(alpha: 0.92),
                    const Color(0xFF0A1628).withValues(alpha: 0.85),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.neonCyan.withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: -5,
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  // Enhanced Event Card with Glass & Neon
  Widget buildEnhancedEventCard(EventModel item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: kIsWeb
                        ? [
                            const Color(0xFF0A1628).withValues(alpha: 0.9),
                            const Color(0xFF0A1628).withValues(alpha: 0.82),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.03),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: DesignTokens.neonAmber.withValues(alpha: 0.3),
                  ),
                ),
                child: Semantics(
                  label: 'data-test=event-feed-item-${item.id}',
                  child: DFCEventCard(
                    event: item,
                    userCity: _userCity,
                    userState: _userState,
                    userCountry: _userCountry,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/event/${item.id}', extra: item);
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Enhanced Post Card with Glass & Neon
  Widget buildEnhancedPostCard(Post item, int index) {
    final isNew = DateTime.now().difference(item.createdAt).inMinutes < 15;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: kIsWeb
                            ? [
                                const Color(0xFF0A1628).withValues(alpha: 0.9),
                                const Color(0xFF0A1628).withValues(alpha: 0.82),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.08),
                                Colors.white.withValues(alpha: 0.03),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isNew
                            ? DesignTokens.neonCyan.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                        width: isNew ? 1.5 : 1,
                      ),
                      boxShadow: isNew
                          ? [
                              BoxShadow(
                                color: DesignTokens.neonCyan.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 15,
                              ),
                            ]
                          : null,
                    ),
                    child: Semantics(
                      label: 'data-test=social-card-${item.id}',
                      child: DFCPostCard(
                        post: item,
                        onComment: () => openComments(item),
                        onPostDeleted: () {
                          setState(() {
                            _items.removeWhere(
                              (entry) => entry is Post && entry.id == item.id,
                            );
                          });
                        },
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/post/${item.id}');
                        },
                      ),
                    ),
                  ),
                ),
                // LIVE badge for new posts
                if (isNew)
                  Positioned(top: 16, right: 18, child: buildLiveBadge()),
              ],
            ),
          ),
        );
      },
    );
  }

  // Enhanced News Card with Glass & Neon
  Widget buildEnhancedNewsCard(FightNewsArticle article, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: kIsWeb
                        ? [
                            const Color(0xFF0A1628).withValues(alpha: 0.9),
                            const Color(0xFF0A1628).withValues(alpha: 0.82),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.03),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: article.isBreaking
                        ? DesignTokens.neonRed.withValues(alpha: 0.5)
                        : article.isFeatured
                        ? DesignTokens.neonGold.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.1),
                    width: article.isBreaking ? 1.5 : 1,
                  ),
                  boxShadow: article.isBreaking
                      ? [
                          BoxShadow(
                            color: DesignTokens.neonRed.withValues(alpha: 0.15),
                            blurRadius: 15,
                          ),
                        ]
                      : null,
                ),
                child: DFCNewsCard(article: article),
              ),
            ),
          ),
        );
      },
    );
  }

  // LIVE Badge with Pulsing Animation
  Widget buildLiveBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonRed,
                DesignTokens.neonRed.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.neonRed.withValues(alpha: 0.3 * value),
                blurRadius: 8 * value,
                spreadRadius: 2 * value,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8 * value),
                      blurRadius: 4 * value,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Loading Indicator for Infinite Scroll — shimmer skeleton
  Widget buildLoadingIndicator() {
    return const DFCFeedSkeleton(itemCount: 2);
  }

  // End of Feed Badge
  Widget buildEndOfFeedBadge() {
    if (_isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: kIsWeb
                ? [
                    const Color(0xFF0A1628).withValues(alpha: 0.9),
                    const Color(0xFF0A1628).withValues(alpha: 0.82),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.03),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: DesignTokens.neonCyan.withValues(alpha: 0.7),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              "You're all caught up!",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation: Compose & Comments
  Future<void> openCompose() async {
    final posted = await context.push<bool>('/compose-post');
    if (posted == true && mounted) {
      await refresh();
    }
  }

  void openComments(Post post) {
    context.push('/comment-thread', extra: post);
  }

  // ── Streaming Power Strip (live intelligence feed widget) ──
  Widget buildStreamingPowerStrip() {
    final liveEvents = _items.whereType<EventModel>().where(
      (e) =>
          e.isLive ||
          (e.eventDate.isBefore(DateTime.now()) &&
              e.eventDate
                  .add(const Duration(hours: 6))
                  .isAfter(DateTime.now())),
    );
    final ppvCount = _ppvEvents.length;
    final hasLive = liveEvents.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: hasLive
              ? [
                  Colors.red.withValues(alpha: 0.08),
                  DesignTokens.neonCyan.withValues(alpha: 0.04),
                ]
              : [
                  DesignTokens.neonCyan.withValues(alpha: 0.06),
                  DesignTokens.neonMagenta.withValues(alpha: 0.03),
                ],
        ),
        border: Border.all(
          color: hasLive
              ? Colors.red.withValues(alpha: 0.2)
              : DesignTokens.neonCyan.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasLive ? Icons.sensors : Icons.radar,
            color: hasLive ? Colors.redAccent : DesignTokens.neonCyan,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: hasLive ? 'LIVE NOW ' : 'STREAMING ',
                    style: TextStyle(
                      color: hasLive ? Colors.redAccent : DesignTokens.neonCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  TextSpan(
                    text: hasLive
                        ? '${liveEvents.length} event${liveEvents.length == 1 ? '' : 's'} streaming · $ppvCount PPV available'
                        : '$ppvCount PPV events · ${_items.length} posts · All feeds active',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasLive)
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Semantics(
      label: 'data-test=social-card',
      child: Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        body: Stack(
          children: [
            if (kDebugMode)
              Positioned(
                top: 0,
                left: 0,
                child: Semantics(
                  label: 'data-test=social-feed',
                  child: const SizedBox(width: 1, height: 1),
                ),
              ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Facebook-style: cap feed width on wide screens, center it
                  final feedMaxWidth = constraints.maxWidth > 680
                      ? 680.0
                      : constraints.maxWidth;
                  return RefreshIndicator(
                    onRefresh: refresh,
                    color: AppTheme.neonCyan.withValues(alpha: 0.8),
                    backgroundColor: AppTheme.cardBackground,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: feedMaxWidth),
                        child: ListView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            // ── Top spacing for HomeScreen overlay icons ──
                            const SizedBox(height: 56),
                            // ── Hero banner ──
                            DFCHeroBanner(
                              onGetStarted: () => context.push('/events'),
                            ),
                            buildSectionBridge(
                              eyebrow: 'DFC SIGNAL NETWORK',
                              title: 'The Fight Graph Is Live',
                              subtitle:
                                  'Real-time event momentum, creator updates, and monetization-ready story lanes in one scroll.',
                              icon: Icons.hub_rounded,
                              accent: DesignTokens.neonCyan,
                            ),
                            buildFlowRail(),
                            // ── Live Streaming Power Strip ──
                            buildStreamingPowerStrip(),
                            // ── Story Ring Tray (Instagram-style) ──
                            buildStoryTray(),
                            // ── Live & Upcoming horizontal carousel ──
                            buildLiveCarousel(),
                            // ── "Feed" section header ──
                            buildSectionHeader('Latest Updates'),
                            buildComposePrompt(),
                            // ── Trending Topics ──
                            buildTrendingTopics(),
                            // ── In-feed PPV buy cards ──
                            buildPPVSection(),
                            // ── For You / Following tabs ──
                            buildFeedTabs(),
                            // ── Real-time "New posts" banner (Facebook/Twitter-style) ──
                            if (_newPostsAvailable)
                              GestureDetector(
                                onTap: onNewPostsTapped,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 60,
                                    vertical: 8,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        DesignTokens.neonCyan,
                                        DesignTokens.neonMagenta,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: DesignTokens.neonCyan.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'New posts',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ...buildFeedItems(),
                            if (_isLoading && _initialLoaded)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: DesignTokens.neonCyan,
                                    ),
                                  ),
                                ),
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
        ),
      ),
    );
  }
}

// ─── Trending, Featured, Story Bar & Search Widgets ───

class TrendingBar extends StatelessWidget {
  final List<Post> trendingPosts;
  const TrendingBar({super.key, required this.trendingPosts});
  @override
  Widget build(BuildContext context) {
    if (trendingPosts.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: trendingPosts.length,
        itemBuilder: (context, idx) {
          final post = trendingPosts[idx];
          final label = post.content.length > 20
              ? post.content.substring(0, 20)
              : post.content;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Chip(
              label: Text(label),
              avatar: DfcCircleAvatar(
                imageUrl: post.userAvatarUrl,
                radius: 12,
                fallbackText: post.displayName.isNotEmpty
                    ? post.displayName[0].toUpperCase()
                    : '?',
              ),
            ),
          );
        },
      ),
    );
  }
}

class StoryBar extends StatelessWidget {
  final List<Post> stories;
  const StoryBar({super.key, required this.stories});
  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, idx) {
          final post = stories[idx];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                DfcCircleAvatar(
                  imageUrl: post.userAvatarUrl,
                  radius: 28,
                  fallbackText: post.displayName.isNotEmpty
                      ? post.displayName[0].toUpperCase()
                      : '?',
                ),
                const SizedBox(height: 4),
                Text(post.displayName, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FeaturedBar extends StatelessWidget {
  final List<Post> featuredPosts;
  const FeaturedBar({super.key, required this.featuredPosts});
  @override
  Widget build(BuildContext context) {
    if (featuredPosts.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: featuredPosts.length,
        itemBuilder: (context, idx) {
          final post = featuredPosts[idx];
          final label = post.content.length > 20
              ? post.content.substring(0, 20)
              : post.content;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Chip(
              label: Text(label),
              avatar: DfcCircleAvatar(
                imageUrl: post.userAvatarUrl,
                radius: 12,
                fallbackText: post.displayName.isNotEmpty
                    ? post.displayName[0].toUpperCase()
                    : '?',
              ),
            ),
          );
        },
      ),
    );
  }
}

class FeedSearchBar extends StatelessWidget {
  final ValueChanged<String> onSearch;
  const FeedSearchBar({super.key, required this.onSearch});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search feed...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onChanged: onSearch,
      ),
    );
  }
}
