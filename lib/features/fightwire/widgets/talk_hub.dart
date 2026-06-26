import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/fightwire_post.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/fightwire_feed_service.dart';
import '../../../shared/services/nightchill_integration_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTWIRE TALK HUB — Facebook-style social feed
/// Create posts, like, comment, share, follow, subscribe, hashtags
/// ═══════════════════════════════════════════════════════════════════════════

class FightWireTalkHub extends StatefulWidget {
  const FightWireTalkHub({super.key});

  @override
  State<FightWireTalkHub> createState() => _FightWireTalkHubState();
}

class _FightWireTalkHubState extends State<FightWireTalkHub> {
  final ScrollController _scrollController = ScrollController();
  final FightWireFeedService _feedService = FightWireFeedService();
  final NightChillIntegrationService _nightChillService =
      NightChillIntegrationService();

  String _feedFilter = 'For You';
  List<FightWirePost> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  // DocumentSnapshot? _lastDoc; // Reserved for pagination
  // UserModel? _currentUser; // Reserved for user profile context

  String _activeUserId() =>
      FirebaseAuth.instance.currentUser?.uid ?? 'current_user';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // _loadCurrentUser(); // Reserved for future user profile context
    _loadFeed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Reserved for future user profile context
  // ignore: unused_element
  Future<void> _loadCurrentUser() async {
    // final uid = FirebaseAuth.instance.currentUser?.uid;
    // if (uid != null) {
    //   final doc = await FirebaseFirestore.instance
    //       .collection('users')
    //       .doc(uid)
    //       .get();
    //   if (doc.exists && mounted) {
    //     setState(() => _currentUser = UserModel.fromFirestore(doc));
    //   }
    // }
  }

  Future<void> _loadFeed() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<FightWirePost> loadedPosts = [];

      switch (_feedFilter) {
        case 'For You':
          loadedPosts = await _feedService.getPersonalizedFeed(
            userId: _activeUserId(),
          );
          break;
        case 'Following':
          // Filter by following relationships
          loadedPosts = await _feedService.getPersonalizedFeed(
            userId: _activeUserId(),
          );
          break;
        case 'Trending':
          loadedPosts = await _feedService.getTrendingFeed();
          break;
        case 'Nearby':
          loadedPosts = await _feedService.getPersonalizedFeed(
            userId: _activeUserId(),
          );
          break;
        case 'NightChill':
          loadedPosts = await _nightChillService.fetchNightChillContent();
          break;
        default:
          loadedPosts = await _feedService.getPersonalizedFeed(
            userId: _activeUserId(),
          );
      }

      if (mounted) {
        setState(() {
          _posts = loadedPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading feed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || _isLoading) return;
    setState(() => _isLoadingMore = true);

    try {
      final morePosts = await _feedService.getPersonalizedFeed(
        userId: _activeUserId(),
        limit: 10,
      );
      if (mounted) {
        setState(() {
          _posts.addAll(morePosts);
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more posts: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: DesignTokens.neonCyan,
      backgroundColor: const Color(0xFF1A1A2E),
      onRefresh: _loadFeed,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Feed filters
          SliverToBoxAdapter(child: _buildFeedFilters()),
          // Composer
          SliverToBoxAdapter(child: _buildPostComposer()),
          // Stories row
          SliverToBoxAdapter(child: _buildStoriesRow()),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          // Feed posts — lazy built
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(
                    color: DesignTokens.neonCyan,
                  ),
                ),
              ),
            )
          else if (_posts.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.feed_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No posts yet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index < _posts.length) {
                  return RealFightWirePostCard(post: _posts[index]);
                } else if (_isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.neonCyan,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }, childCount: _posts.length + (_isLoadingMore ? 1 : 0)),
            ),
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildFeedFilters() {
    final filters = [
      'For You',
      'Following',
      'Trending',
      'Nearby',
      'NightChill',
    ];
    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, i) {
          final selected = _feedFilter == filters[i];
          return GestureDetector(
            onTap: () {
              setState(() => _feedFilter = filters[i]);
              _loadFeed();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected
                    ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? DesignTokens.neonCyan.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                filters[i],
                style: TextStyle(
                  color: selected
                      ? DesignTokens.neonCyan
                      : Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostComposer() {
    return GestureDetector(
      onTap: () => _showFullComposer(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // User avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'Y',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      "What's on your mind, champ?",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _composerAction(Icons.videocam, 'Live', DesignTokens.neonRed),
                _dividerDot(),
                _composerAction(
                  Icons.photo_library,
                  'Photo',
                  DesignTokens.neonGreen,
                ),
                _dividerDot(),
                _composerAction(
                  Icons.sports_mma,
                  'Highlight',
                  DesignTokens.neonAmber,
                ),
                _dividerDot(),
                _composerAction(Icons.poll, 'Poll', DesignTokens.neonMagenta),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _composerAction(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _dividerDot() {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
    );
  }

  /// Converts hex color string to Color
  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Widget _buildStoriesRow() {
    // Load stories from Firestore — edit in Firebase Console anytime!
    return SizedBox(
      height: 90,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          // Fallback stories if Firestore empty/loading
          final fallbackStories = [
            const _Story(
              name: 'Your Story',
              color: DesignTokens.neonCyan,
              isAdd: true,
            ),
            const _Story(
              name: 'DFC Official',
              color: DesignTokens.neonGold,
              badge: '⚡',
            ),
          ];

          List<_Story> stories;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            stories = snapshot.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return _Story(
                name: d['name'] ?? 'Story',
                color: _hexToColor(d['color'] ?? '#00E5FF'),
                isAdd: d['isAdd'] ?? false,
                badge: d['badge'],
              );
            }).toList();
          } else {
            stories = fallbackStories;
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stories.length,
            itemBuilder: (context, i) {
              final s = stories[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [s.color, s.color.withValues(alpha: 0.5)],
                        ),
                        border: s.isAdd
                            ? null
                            : Border.all(color: s.color, width: 2),
                      ),
                      child: s.isAdd
                          ? const Icon(Icons.add, color: Colors.white, size: 24)
                          : Center(
                              child: Text(
                                s.badge ?? s.name[0],
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.name,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFullComposer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12121A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FullPostComposer(),
    );
  }

  // Deprecated mock data - reserved for testing
  // ignore: unused_element
  List<_PostData> _mockPosts() => [
    const _PostData(
      userName: 'Coach Ray Mitchell',
      userHandle: '@raymitchell',
      userRole: 'Coach',
      roleColor: DesignTokens.neonGreen,
      isVerified: true,
      isFollowing: false,
      timeAgo: '12m',
      content:
          'Morning session was FIRE 🔥 Working on head movement and counter-punching combos today. These fighters are putting in the work.\n\nRemember — you don\'t rise to the level of your goals, you fall to the level of your training. 💪\n\n#FightCamp #Boxing #DFC',
      mediaType: 'image',
      mediaUrl: 'training_session.jpg',
      likes: 142,
      comments: 28,
      shares: 15,
      isLiked: false,
      isSaved: false,
      hashtags: ['FightCamp', 'Boxing', 'DFC'],
    ),
    const _PostData(
      userName: 'DataFightCentral',
      userHandle: '@datafightcentral',
      userRole: 'Official',
      roleColor: DesignTokens.neonCyan,
      isVerified: true,
      isFollowing: true,
      timeAgo: '1h',
      content:
          '📢 ANNOUNCEMENT: DFC Pro subscriptions now include AI fight analysis!\n\nGet personalized training insights powered by combat intelligence. Your data, your edge.\n\n🔗 Upgrade now in Settings → Subscription\n\n#DFC2026 #WeAllGotSomeFight',
      likes: 892,
      comments: 156,
      shares: 234,
      isLiked: true,
      isSaved: true,
      hashtags: ['DFC2026', 'WeAllGotSomeFight'],
    ),
    const _PostData(
      userName: 'Marcus Torres',
      userHandle: '@marcustorres',
      userRole: 'Fighter',
      roleColor: DesignTokens.neonRed,
      isVerified: true,
      isFollowing: false,
      timeAgo: '2h',
      content:
          'Weight cut on track. 12 days out. 3.4 kg to go.\n\nFeeling strong, staying disciplined. Ice baths, clean eating, mental reps. Saturday Night Showdown — we\'re coming for that belt. 🏆\n\nBig thank you to @raymitchell and the team.\n\n#FightWeek #WeightCut #MMA',
      mediaType: 'image',
      mediaUrl: 'weight_cut.jpg',
      likes: 456,
      comments: 89,
      shares: 42,
      isLiked: false,
      isSaved: false,
      hashtags: ['FightWeek', 'WeightCut', 'MMA'],
    ),
    const _PostData(
      userName: 'Golden Dragon Muay Thai',
      userHandle: '@tigermuaythai',
      userRole: 'Gym',
      roleColor: DesignTokens.neonAmber,
      isVerified: false,
      isFollowing: true,
      timeAgo: '3h',
      content:
          '🥊 NEW CLASS ALERT: Women\'s self-defense starting next Monday!\n\nFree trial class for all DFC members. Bring a friend, get a free month.\n\nSign up: link in bio\n📍 Golden Dragon Muay Thai, Phuket\n\n#SelfDefense #WomenInMMA #TigerMuayThai #SheFights',
      mediaType: 'image',
      mediaUrl: 'gym_class.jpg',
      likes: 234,
      comments: 45,
      shares: 78,
      isLiked: false,
      isSaved: false,
      hashtags: ['SelfDefense', 'WomenInMMA', 'TigerMuayThai', 'SheFights'],
    ),
    const _PostData(
      userName: 'The MMA Hour',
      userHandle: '@themmahour',
      userRole: 'Media',
      roleColor: DesignTokens.neonMagenta,
      isVerified: true,
      isFollowing: false,
      timeAgo: '4h',
      content:
          '🎙️ NEW EPISODE OUT NOW:\n\n"The Future of Combat Sports Tech"\n\nFeaturing an exclusive interview with the DFC team on how AI is changing fight preparation.\n\nListen on Spotify, Apple Podcasts, or right here on FightWire.\n\n🔊 What tech do YOU use in training? Drop your answers below 👇\n\n#Podcast #MMA #FightTech',
      mediaType: 'poll',
      likes: 189,
      comments: 67,
      shares: 31,
      isLiked: false,
      isSaved: false,
      hashtags: ['Podcast', 'MMA', 'FightTech'],
      pollQuestion: 'What training tech do you use?',
      pollOptions: [
        'Heart Rate Monitor',
        'Video Analysis',
        'AI Coach',
        'None yet',
      ],
      pollVotes: [234, 189, 156, 78],
    ),
    const _PostData(
      userName: 'Jake Morrison Strength',
      userHandle: '@phildarustrong',
      userRole: 'Trainer',
      roleColor: DesignTokens.neonGreen,
      isVerified: false,
      isFollowing: false,
      timeAgo: '5h',
      content:
          'Recovery check-in ✅\n\n✅ 8hrs sleep\n✅ 1 gallon water\n✅ Protein targets hit\n✅ Foam rolling done\n✅ Mental visualization\n\nThe grind doesn\'t stop when you leave the gym. Recovery IS training. 🧠💤\n\n#Recovery #FighterLife #DFC',
      likes: 312,
      comments: 34,
      shares: 56,
      isLiked: true,
      isSaved: false,
      hashtags: ['Recovery', 'FighterLife', 'DFC'],
    ),
  ];
}

// ═══════════════════════════════════════════════════════
// POST CARD — Full Facebook-style engagement card
// ═══════════════════════════════════════════════════════

class _FightWirePostCard extends StatefulWidget {
  final _PostData post;
  const _FightWirePostCard({required this.post});

  @override
  State<_FightWirePostCard> createState() => _FightWirePostCardState();
}

class _FightWirePostCardState extends State<_FightWirePostCard> {
  late bool _isLiked;
  late bool _isSaved;
  late int _likeCount;
  bool _showFullText = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _isSaved = widget.post.isSaved;
    _likeCount = widget.post.likes;
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 2),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(post),
          const SizedBox(height: 6),
          _buildPostContent(post),
          if (post.mediaType == 'image') ...[
            const SizedBox(height: 6),
            _buildMediaPlaceholder(post),
          ],
          if (post.mediaType == 'poll') ...[
            const SizedBox(height: 6),
            _buildPollCard(post),
          ],
          if (post.hashtags.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildHashtags(post),
          ],
          const SizedBox(height: 6),
          _buildActionBar(post),
        ],
      ),
    );
  }

  Widget _buildPostHeader(_PostData post) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: post.roleColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: post.roleColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              post.userName[0],
              style: TextStyle(
                color: post.roleColor,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Name + handle + role
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      post.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (post.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      color: DesignTokens.neonCyan,
                      size: 14,
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Text(
                    post.userHandle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: post.roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      post.userRole,
                      style: TextStyle(
                        color: post.roleColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${post.timeAgo}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Follow / More
        if (!post.isFollowing)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Following ${post.userName}'),
                  backgroundColor: const Color(0xFF1A1A2E),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: const Text(
                'Follow',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => _showPostOptions(context),
          child: Icon(
            Icons.more_horiz,
            color: Colors.white.withValues(alpha: 0.3),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildPostContent(_PostData post) {
    final maxLines = _showFullText ? 100 : 3;
    final text = post.content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            height: 1.35,
          ),
          maxLines: maxLines,
          overflow: _showFullText
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
        ),
        if (!_showFullText && text.length > 200)
          GestureDetector(
            onTap: () => setState(() => _showFullText = true),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'See more',
                style: TextStyle(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaPlaceholder(_PostData post) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              post.roleColor.withValues(alpha: 0.15),
              post.roleColor.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(color: post.roleColor.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.image,
                color: post.roleColor.withValues(alpha: 0.3),
                size: 48,
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.fullscreen,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'View',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
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

  Widget _buildPollCard(_PostData post) {
    if (post.pollQuestion == null) return const SizedBox.shrink();
    final totalVotes = post.pollVotes?.fold<int>(0, (a, b) => a + b) ?? 1;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll, color: DesignTokens.neonMagenta, size: 16),
              const SizedBox(width: 6),
              Text(
                post.pollQuestion!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...List.generate(post.pollOptions?.length ?? 0, (i) {
            final votes = post.pollVotes?[i] ?? 0;
            final pct = totalVotes > 0 ? votes / totalVotes : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: DesignTokens.neonMagenta.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              post.pollOptions![i],
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '${(pct * 100).round()}%',
                            style: const TextStyle(
                              color: DesignTokens.neonMagenta,
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
            );
          }),
          Text(
            '$totalVotes votes',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtags(_PostData post) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: post.hashtags.map((tag) {
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Searching #$tag...'),
                backgroundColor: const Color(0xFF1A1A2E),
              ),
            );
          },
          child: Text(
            '#$tag',
            style: TextStyle(
              color: DesignTokens.neonCyan.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionBar(_PostData post) {
    return Row(
      children: [
        _actionButton(
          icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
          label: _likeCount > 0 ? _formatCount(_likeCount) : 'Like',
          color: _isLiked
              ? DesignTokens.neonCyan
              : Colors.white.withValues(alpha: 0.45),
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _isLiked = !_isLiked;
              _likeCount += _isLiked ? 1 : -1;
            });
          },
          onLongPress: _showReactionPicker,
        ),
        _actionButton(
          icon: Icons.chat_bubble_outline,
          label: post.comments > 0 ? _formatCount(post.comments) : '',
          color: Colors.white.withValues(alpha: 0.45),
          onTap: () => _showCommentsSheet(context, post),
        ),
        _actionButton(
          icon: Icons.share_outlined,
          label: post.shares > 0 ? _formatCount(post.shares) : '',
          color: Colors.white.withValues(alpha: 0.45),
          onTap: () => _showShareSheet(context, post),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _isSaved = !_isSaved);
          },
          child: Icon(
            _isSaved ? Icons.bookmark : Icons.bookmark_border,
            size: 18,
            color: _isSaved
                ? DesignTokens.neonGold
                : Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 3),
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
      ),
    );
  }

  void _showReactionPicker() {
    final reactions = ['👍', '❤️', '🔥', '🥊', '💪', '😂'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: reactions.map((r) {
            return GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  if (!_isLiked) _likeCount++;
                  _isLiked = true;
                });
                Navigator.pop(ctx);
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(r, style: const TextStyle(fontSize: 28)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCommentsSheet(BuildContext context, _PostData post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12121A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CommentsSheet(post: post),
    );
  }

  void _showShareSheet(BuildContext context, _PostData post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12121A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ShareSheet(post: post),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12121A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _optionTile(
              Icons.bookmark_border,
              'Save Post',
              DesignTokens.neonGold,
            ),
            _optionTile(
              Icons.notifications_outlined,
              'Turn on notifications',
              DesignTokens.neonCyan,
            ),
            _optionTile(Icons.link, 'Copy Link', Colors.white70),
            _optionTile(
              Icons.report_outlined,
              'Report Post',
              DesignTokens.neonRed,
            ),
            _optionTile(Icons.visibility_off, 'Hide Post', Colors.white70),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String title, Color color) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 14,
        ),
      ),
      onTap: () => Navigator.pop(context),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

// ═══════════════════════════════════════════════════════
// COMMENTS SHEET
// ═══════════════════════════════════════════════════════

class _CommentsSheet extends StatefulWidget {
  final _PostData post;
  const _CommentsSheet({required this.post});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final List<_CommentData> _comments = [];

  @override
  void initState() {
    super.initState();
    _comments.addAll(_mockComments());
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF12121A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.post.comments}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.06)),
              // Comment list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _comments.length,
                  itemBuilder: (context, i) => _commentTile(_comments[i]),
                ),
              ),
              // Input
              _buildCommentInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _commentTile(_CommentData c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                c.name[0],
                style: TextStyle(
                  color: c.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
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
                      c.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      c.time,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  c.text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reaction captured.')),
                        );
                      },
                      child: Text(
                        'Like',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () {
                        _commentController.text = '@${c.name} ';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Replying to ${c.name}')),
                        );
                      },
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (c.likes > 0) ...[
                      const Spacer(),
                      Icon(
                        Icons.thumb_up,
                        size: 10,
                        color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${c.likes}',
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
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'Y',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: DesignTokens.neonCyan,
                    width: 0.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _commentController.text =
                            '${_commentController.text.trim()} 🔥 '.trimLeft();
                      },
                      child: Icon(
                        Icons.emoji_emotions_outlined,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Attach photo from composer in next patch.',
                            ),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              if (_commentController.text.trim().isEmpty) return;
              setState(() {
                _comments.insert(
                  0,
                  _CommentData(
                    name: 'You',
                    text: _commentController.text.trim(),
                    time: 'now',
                    likes: 0,
                    color: DesignTokens.neonCyan,
                  ),
                );
                _commentController.clear();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: DesignTokens.neonCyan,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_CommentData> _mockComments() => [
    const _CommentData(
      name: 'Alex V.',
      text: 'This is exactly what the fight community needs. Keep building! 🔥',
      time: '2h',
      likes: 24,
      color: DesignTokens.neonRed,
    ),
    const _CommentData(
      name: 'Coach Mike',
      text: 'Great work. Technique over everything. Respect. 👊',
      time: '3h',
      likes: 18,
      color: DesignTokens.neonGreen,
    ),
    const _CommentData(
      name: 'FightFan88',
      text: 'When is this available in Australia?',
      time: '4h',
      likes: 5,
      color: DesignTokens.neonAmber,
    ),
    const _CommentData(
      name: 'Sarah K.',
      text: 'Love the recovery focus. So important!',
      time: '5h',
      likes: 12,
      color: DesignTokens.neonMagenta,
    ),
    const _CommentData(
      name: 'DFC User',
      text:
          'The AI features are game-changing. Already seeing results in my training.',
      time: '6h',
      likes: 8,
      color: DesignTokens.neonCyan,
    ),
  ];
}

// ═══════════════════════════════════════════════════════
// SHARE SHEET
// ═══════════════════════════════════════════════════════

class _ShareSheet extends StatelessWidget {
  final _PostData post;
  const _ShareSheet({required this.post});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareOption(
                  Icons.repeat,
                  'Repost',
                  DesignTokens.neonGreen,
                  context,
                ),
                _shareOption(
                  Icons.edit_note,
                  'Quote',
                  DesignTokens.neonCyan,
                  context,
                ),
                _shareOption(
                  Icons.send,
                  'DM',
                  DesignTokens.neonMagenta,
                  context,
                ),
                _shareOption(
                  Icons.link,
                  'Copy Link',
                  DesignTokens.neonAmber,
                  context,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareExternal(Icons.message, 'SMS', Colors.green, context),
                _shareExternal(Icons.email, 'Email', Colors.blue, context),
                _shareExternal(Icons.share, 'More', Colors.white70, context),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _shareOption(
    IconData icon,
    String label,
    Color color,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label — shared!'),
            backgroundColor: const Color(0xFF1A1A2E),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _shareExternal(
    IconData icon,
    String label,
    Color color,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// FULL POST COMPOSER
// ═══════════════════════════════════════════════════════

class _FullPostComposer extends StatefulWidget {
  const _FullPostComposer();

  @override
  State<_FullPostComposer> createState() => _FullPostComposerState();
}

class _FullPostComposerState extends State<_FullPostComposer> {
  final TextEditingController _postController = TextEditingController();
  String _visibility = 'Public';
  bool _hasMedia = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF12121A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Create Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (_postController.text.trim().isEmpty) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Post published to FightWire! 🔥'),
                            backgroundColor: Color(0xFF1A1A2E),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: DesignTokens.neonCyan.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'Post',
                          style: TextStyle(
                            color: DesignTokens.neonCyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.06)),
              // User info + visibility
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.neonCyan,
                            DesignTokens.neonMagenta,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'Y',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _visibility = _visibility == 'Public'
                                  ? 'Followers'
                                  : 'Public';
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _visibility == 'Public'
                                      ? Icons.public
                                      : Icons.group,
                                  color: DesignTokens.neonCyan,
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _visibility,
                                  style: const TextStyle(
                                    color: DesignTokens.neonCyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: DesignTokens.neonCyan,
                                  size: 14,
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
              // Text input
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _postController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          "What's on your mind, champ?\n\nShare a training update, fight reaction, highlight reel, or just talk fight...",
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 15,
                        height: 1.5,
                      ),
                      border: InputBorder.none,
                    ),
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
              ),
              // Media attachment area
              if (_hasMedia)
                Container(
                  height: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo,
                          color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                          size: 30,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Media attached',
                          style: TextStyle(
                            color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Bottom toolbar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _toolbarIcon(
                      Icons.photo_library,
                      DesignTokens.neonGreen,
                      () => setState(() => _hasMedia = true),
                    ),
                    _toolbarIcon(Icons.videocam, DesignTokens.neonRed, () {}),
                    _toolbarIcon(Icons.gif_box, DesignTokens.neonAmber, () {}),
                    _toolbarIcon(Icons.poll, DesignTokens.neonMagenta, () {}),
                    _toolbarIcon(
                      Icons.location_on,
                      DesignTokens.neonCyan,
                      () {},
                    ),
                    _toolbarIcon(Icons.tag, Colors.white54, () {}),
                    const Spacer(),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _postController,
                      builder: (_, value, _) {
                        return Text(
                          '${value.text.length}/500',
                          style: TextStyle(
                            color: value.text.length > 450
                                ? DesignTokens.neonRed
                                : Colors.white.withValues(alpha: 0.3),
                            fontSize: 11,
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
      },
    );
  }

  Widget _toolbarIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// REAL FIGHTWIRE POST CARD (Uses FightWirePost model)
// ═══════════════════════════════════════════════════════

class RealFightWirePostCard extends StatefulWidget {
  final FightWirePost post;
  const RealFightWirePostCard({super.key, required this.post});

  @override
  State<RealFightWirePostCard> createState() => _RealFightWirePostCardState();
}

class _RealFightWirePostCardState extends State<RealFightWirePostCard> {
  final FightWireFeedService _feedService = FightWireFeedService();
  late FightWirePost _post;
  bool _showFullText = false;
  UserModel? _authorProfile;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadAuthorProfile();
    _incrementViews();
  }

  Future<void> _loadAuthorProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_post.authorId)
          .get();
      if (doc.exists && mounted) {
        setState(() => _authorProfile = UserModel.fromFirestore(doc));
      }
    } catch (e) {
      debugPrint('Error loading author profile: $e');
    }
  }

  Future<void> _incrementViews() async {
    try {
      await _feedService.incrementViews(_post.id);
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 2),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(),
          const SizedBox(height: 6),
          _buildPostContent(),
          if (_post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildMediaPreview(),
          ],
          if (_post.campaignId != null) ...[
            const SizedBox(height: 6),
            _buildCampaignBadge(),
          ],
          const SizedBox(height: 6),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    final authorName = _authorProfile?.displayName ?? _post.authorName;
    final authorRole = _authorProfile?.role.displayName ?? _post.authorRole;
    final isVerified = _authorProfile?.isVerified ?? false;

    Color roleColor = DesignTokens.neonCyan;
    if (authorRole == 'Fighter') roleColor = DesignTokens.neonRed;
    if (authorRole == 'Coach') roleColor = DesignTokens.neonGreen;
    if (authorRole == 'Gym') roleColor = DesignTokens.neonAmber;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: roleColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: roleColor,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Name + role
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      authorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      color: DesignTokens.neonCyan,
                      size: 14,
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      authorRole,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${_formatTimeAgo(_post.createdAt)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // More options
        GestureDetector(
          onTap: () => _showPostOptions(context),
          child: Icon(
            Icons.more_horiz,
            color: Colors.white.withValues(alpha: 0.3),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildPostContent() {
    final maxLines = _showFullText ? 100 : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _post.content,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            height: 1.35,
          ),
          maxLines: maxLines,
          overflow: _showFullText
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
        ),
        if (!_showFullText && _post.content.length > 200)
          GestureDetector(
            onTap: () => setState(() => _showFullText = true),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'See more',
                style: TextStyle(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.image,
            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignBadge() {
    String emoji = '⚡';
    String label = 'Campaign';
    Color color = DesignTokens.neonCyan;

    if (_post.campaignId == 'gold_coin_drive') {
      emoji = '🪙';
      label = 'Gold Coin Drive';
      color = DesignTokens.neonGold;
    } else if (_post.campaignId == 'pink_shield') {
      emoji = '🛡️';
      label = 'Pink Shield';
      color = DesignTokens.neonMagenta;
    } else if (_post.campaignId == 'coffee_campaign') {
      emoji = '☕';
      label = 'Coffee Campaign';
      color = DesignTokens.neonAmber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    // Calculate total reactions
    final totalReactions =
        _post.respectCount +
        _post.warriorCount +
        _post.championCount +
        _post.strongCount;

    return Row(
      children: [
        _actionButton(
          icon: Icons.thumb_up_outlined,
          label: totalReactions > 0 ? _formatCount(totalReactions) : '',
          color: Colors.white.withValues(alpha: 0.45),
          onTap: _showReactionPicker,
          onLongPress: _showReactionPicker,
        ),
        _actionButton(
          icon: Icons.chat_bubble_outline,
          label: _post.commentsCount > 0
              ? _formatCount(_post.commentsCount)
              : '',
          color: Colors.white.withValues(alpha: 0.45),
          onTap: () {},
        ),
        _actionButton(
          icon: Icons.share_outlined,
          label: _post.sharesCount > 0 ? _formatCount(_post.sharesCount) : '',
          color: Colors.white.withValues(alpha: 0.45),
          onTap: () {},
        ),
        const Spacer(),
        Text(
          '👁️ ${_formatCount(_post.likesCount + _post.commentsCount + _post.sharesCount)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 3),
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
      ),
    );
  }

  void _showReactionPicker() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: DesignTokens.neonCyan.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Combat Reactions',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _reactionOption(
                    ctx,
                    '🙏',
                    'Respect',
                    'respect',
                    DesignTokens.neonCyan,
                  ),
                  _reactionOption(
                    ctx,
                    '⚔️',
                    'Warrior',
                    'warrior',
                    DesignTokens.neonRed,
                  ),
                  _reactionOption(
                    ctx,
                    '🏆',
                    'Champion',
                    'champion',
                    DesignTokens.neonGold,
                  ),
                  _reactionOption(
                    ctx,
                    '💪',
                    'Strong',
                    'strong',
                    DesignTokens.neonGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reactionOption(
    BuildContext ctx,
    String emoji,
    String label,
    String type,
    Color color,
  ) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          try {
            await _feedService.addReaction(
              postId: _post.id,
              userId: uid,
              reactionType: type,
            );
            // Refresh post data
            final doc = await FirebaseFirestore.instance
                .collection('posts')
                .doc(_post.id)
                .get();
            if (doc.exists && mounted) {
              setState(() => _post = FightWirePost.fromFirestore(doc));
            }
          } catch (e) {
            debugPrint('Error adding reaction: $e');
          }
        }
        if (ctx.mounted) Navigator.pop(ctx);
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12121A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.report_outlined,
                color: DesignTokens.neonRed,
              ),
              title: Text(
                'Report Post',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${(difference.inDays / 7).floor()}w';
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

// ═══════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════

class _PostData {
  final String userName, userHandle, userRole, timeAgo, content;
  final Color roleColor;
  final bool isVerified, isFollowing, isLiked, isSaved;
  final int likes, comments, shares;
  final String? mediaType, mediaUrl;
  final List<String> hashtags;
  final String? pollQuestion;
  final List<String>? pollOptions;
  final List<int>? pollVotes;

  const _PostData({
    required this.userName,
    required this.userHandle,
    required this.userRole,
    required this.roleColor,
    required this.isVerified,
    required this.isFollowing,
    required this.timeAgo,
    required this.content,
    this.mediaType,
    this.mediaUrl,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.isLiked,
    required this.isSaved,
    this.hashtags = const [],
    this.pollQuestion,
    this.pollOptions,
    this.pollVotes,
  });
}

class _Story {
  final String name;
  final Color color;
  final bool isAdd;
  final String? badge;
  const _Story({
    required this.name,
    required this.color,
    this.isAdd = false,
    this.badge,
  });
}

class _CommentData {
  final String name, text, time;
  final int likes;
  final Color color;
  const _CommentData({
    required this.name,
    required this.text,
    required this.time,
    required this.likes,
    required this.color,
  });
}
