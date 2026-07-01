// ═══════════════════════════════════════════════════════════════════════════
// DFC NEWS FEED SCREEN
// ═══════════════════════════════════════════════════════════════════════════
// Aggregated combat sports news with filtering and personalization
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/news_aggregator_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsFeedScreen extends StatefulWidget {
  final String? userId;

  const NewsFeedScreen({super.key, this.userId});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen>
    with SingleTickerProviderStateMixin {
  final _service = NewsAggregatorService();
  late TabController _tabController;

  // Filters
  final Set<NewsSource> _selectedSources = {};
  final Set<String> _selectedSports = {'MMA', 'Boxing', 'Bare Knuckle'};
  String _searchQuery = '';

  final List<String> _sportFilters = [
    'MMA',
    'Boxing',
    'Bare Knuckle',
    'Kickboxing',
    'Muay Thai',
    'BJJ',
    'Wrestling',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: true,
            backgroundColor: AppTheme.backgroundDark,
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(background: _buildHeader()),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Column(
                children: [
                  _buildSearchBar(),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppTheme.neonCyan,
                    labelColor: AppTheme.neonCyan,
                    unselectedLabelColor: Colors.white60,
                    tabs: const [
                      Tab(text: '🔥 For You'),
                      Tab(text: '📢 Breaking'),
                      Tab(text: '📈 Trending'),
                      Tab(text: '⭐ Featured'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildForYouFeed(),
            _buildBreakingFeed(),
            _buildTrendingFeed(),
            _buildFeaturedFeed(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FIGHT NEWS',
            style: TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'All sources, one feed',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 12),

          // Sport filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sportFilters.map((sport) {
                final isSelected = _selectedSports.contains(sport);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      sport,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSports.add(sport);
                        } else {
                          _selectedSports.remove(sport);
                        }
                      });
                    },
                    backgroundColor: Colors.white12,
                    selectedColor: AppTheme.neonCyan,
                    checkmarkColor: Colors.black,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search news, fighters, events...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white60,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _showSourceFilter,
            icon: Stack(
              children: [
                const Icon(Icons.tune, color: Colors.white),
                if (_selectedSources.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.neonCyan,
                        shape: BoxShape.circle,
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

  Widget _buildForYouFeed() {
    return StreamBuilder<List<AggregatedNewsItem>>(
      stream: _service.getNewsFeed(
        sources: _selectedSources.isNotEmpty ? _selectedSources.toList() : null,
        sportFilters: _selectedSports.toList(),
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return _buildEmptyState(
            'No news found',
            'Try adjusting your filters',
          );
        }

        return _buildNewsList(items);
      },
    );
  }

  Widget _buildBreakingFeed() {
    return StreamBuilder<List<AggregatedNewsItem>>(
      stream: _service.getBreakingNews(limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return _buildEmptyState('No breaking news', 'Check back soon');
        }

        return _buildNewsList(items, showBreakingBadge: false);
      },
    );
  }

  Widget _buildTrendingFeed() {
    return StreamBuilder<List<AggregatedNewsItem>>(
      stream: _service.getTrendingNews(limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return _buildEmptyState('No trending news', 'Nothing trending yet');
        }

        return _buildNewsList(items, showRank: true);
      },
    );
  }

  Widget _buildFeaturedFeed() {
    return StreamBuilder<List<AggregatedNewsItem>>(
      stream: _service.getFeaturedStories(limit: 10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return _buildEmptyState(
            'No featured stories',
            'Curated picks coming soon',
          );
        }

        return _buildFeaturedList(items);
      },
    );
  }

  Widget _buildNewsList(
    List<AggregatedNewsItem> items, {
    bool showBreakingBadge = true,
    bool showRank = false,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildNewsCard(
          item,
          rank: showRank ? index + 1 : null,
          showBreakingBadge: showBreakingBadge,
        );
      },
    );
  }

  Widget _buildFeaturedList(List<AggregatedNewsItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildFeaturedCard(items[index]);
      },
    );
  }

  Widget _buildNewsCard(
    AggregatedNewsItem item, {
    int? rank,
    bool showBreakingBadge = true,
  }) {
    final sourceConfig = NewsAggregatorService.getSourceConfig(item.source);

    return GestureDetector(
      onTap: () => _openArticle(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: item.isBreaking && showBreakingBadge
              ? Border.all(color: Colors.red.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (item.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    DfcNetworkImage(
                      url: item.imageUrl!,
                      height: 180,
                      width: double.infinity,
                    ),
                    // Rank badge
                    if (rank != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.neonCyan,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '#$rank',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    // Breaking badge
                    if (item.isBreaking && showBreakingBadge)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '🔥 BREAKING',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and category
                  Row(
                    children: [
                      Text(
                        sourceConfig?.name ?? item.source.name,
                        style: TextStyle(
                          color: Color(
                            NewsAggregatorService.getTrustBadgeColor(
                              sourceConfig?.trustLevel ?? TrustLevel.unverified,
                            ),
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: Colors.white30),
                      ),
                      Text(
                        '${NewsAggregatorService.getCategoryIcon(item.category)} ${NewsAggregatorService.getCategoryDisplayName(item.category)}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTimeAgo(item.publishedAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Title
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (item.summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.summary,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Tags
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.tags
                          .take(4)
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  // Fighter mentions
                  if (item.mentionedFighters.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.mentionedFighters.take(3).join(', '),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(AggregatedNewsItem item) {
    return GestureDetector(
      onTap: () => _openArticle(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppTheme.surfaceColor,
          image: item.imageUrl != null
              ? DecorationImage(
                  image: ImageAssets.resolveImage(item.imageUrl!),
                  fit: BoxFit.cover,
                  onError: (_, _) {},
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Featured badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '⭐ EDITOR\'S PICK',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    NewsAggregatorService.getSourceConfig(item.source)?.name ??
                        item.source.name,
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      fontSize: 12,
                    ),
                  ),
                  const Text(' • ', style: TextStyle(color: Colors.white30)),
                  Text(
                    _formatTimeAgo(item.publishedAt),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.neonCyan),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.article_outlined, size: 64, color: Colors.white30),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showSourceFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter by Source',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedSources.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setModalState(_selectedSources.clear);
                        setState(() {});
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: AppTheme.neonCyan),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: NewsAggregatorService.sourceConfigs.map((config) {
                  final isSelected = _selectedSources.contains(config.source);
                  return FilterChip(
                    avatar: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(
                          NewsAggregatorService.getTrustBadgeColor(
                            config.trustLevel,
                          ),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    label: Text(
                      config.name,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          _selectedSources.add(config.source);
                        } else {
                          _selectedSources.remove(config.source);
                        }
                      });
                      setState(() {});
                    },
                    backgroundColor: Colors.white12,
                    selectedColor: AppTheme.neonCyan,
                    checkmarkColor: Colors.black,
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openArticle(AggregatedNewsItem item) async {
    // Track view
    _service.trackArticleView(item.id);

    // Open URL
    final uri = Uri.tryParse(item.articleUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open article')),
          );
        }
      }
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
