import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/fight_news_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT NEWS FEED WIDGET
/// Auto-updating news aggregator with 2026 glass design
/// ═══════════════════════════════════════════════════════════════════════════

class FightNewsFeed extends StatefulWidget {
  final int maxItems;
  final NewsSource? filterCategory;
  final bool showBreakingOnly;
  final bool compact;
  final bool infiniteScroll;

  const FightNewsFeed({
    super.key,
    this.maxItems = 10,
    this.filterCategory,
    this.showBreakingOnly = false,
    this.compact = false,
    this.infiniteScroll = false,
  });

  @override
  State<FightNewsFeed> createState() => _FightNewsFeedState();
}

class _FightNewsFeedState extends State<FightNewsFeed> {
  FightNewsService? _newsService;
  StreamSubscription<List<FightNewsArticle>>? _newsSub;
  bool _depsReady = false;
  List<FightNewsArticle> _news = [];
  bool _isLoading = true;
  NewsSource? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.filterCategory;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_depsReady) return;
    _newsService = context.read<FightNewsService>();
    _newsService!.startAutoRefresh();
    _newsSub = _newsService!.newsStream.listen((news) {
      if (mounted) setState(() => _news = _filterNews(news));
    });
    _loadNews();
    _depsReady = true;
  }

  @override
  void dispose() {
    _newsSub?.cancel();
    _newsSub = null;
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() => _isLoading = true);
    final news = await _newsService!.refreshNews();
    if (mounted) {
      setState(() {
        _news = _filterNews(news);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreNews() async {
    setState(() => _isLoading = true);
    final moreNews = await _newsService!.fetchMoreNews();
    if (mounted) {
      setState(() {
        _news.addAll(_filterNews(moreNews));
        _isLoading = false;
      });
    }
  }

  List<FightNewsArticle> _filterNews(List<FightNewsArticle> news) {
    var filtered = news;
    if (_selectedCategory != null) {
      filtered = filtered
          .where((n) => n.category == _selectedCategory)
          .toList();
    }
    if (widget.showBreakingOnly) {
      filtered = filtered.where((n) => n.isBreaking).toList();
    }
    return filtered.take(widget.maxItems).toList();
  }

  DateTime? _lastLoadMore;

  @override
  Widget build(BuildContext context) {
    if (widget.infiniteScroll) {
      return NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          final now = DateTime.now();
          if (!_isLoading &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            if (_lastLoadMore == null ||
                now.difference(_lastLoadMore!).inMilliseconds > 1000) {
              _lastLoadMore = now;
              _loadMoreNews();
            }
          }
          return false;
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            if (!widget.compact) ...[
              _buildCategoryChips(),
              const SizedBox(height: 16),
            ],
            if (_isLoading)
              _buildLoadingState()
            else if (_news.isEmpty)
              _buildEmptyState()
            else
              _buildNewsList(),
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          if (!widget.compact) ...[
            _buildCategoryChips(),
            const SizedBox(height: 16),
          ],
          if (_isLoading)
            _buildLoadingState()
          else if (_news.isEmpty)
            _buildEmptyState()
          else
            _buildNewsList(),
        ],
      );
    }
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignTokens.neonCyan.withValues(alpha: 0.3),
                    DesignTokens.neonMagenta.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              ),
              child: const Icon(
                Icons.newspaper,
                color: DesignTokens.neonCyan,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Fight Wire',
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: DesignTokens.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                border: Border.all(
                  color: DesignTokens.success.withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: DesignTokens.success, size: 6),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: DesignTokens.success,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: _loadNews,
          icon: const Icon(Icons.refresh, color: DesignTokens.textMuted, size: 20),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      (null, 'All', Icons.grid_view),
      (NewsSource.ufc, 'UFC', Icons.sports_mma),
      (NewsSource.boxing, 'Boxing', Icons.sports),
      (NewsSource.muayThai, 'Muay Thai', Icons.sports_martial_arts),
      (NewsSource.kickboxing, 'Kickboxing', Icons.sports_kabaddi),
      (NewsSource.mma, 'MMA', Icons.fitness_center),
      (NewsSource.bareKnuckle, 'BKFC', Icons.back_hand),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final (source, label, icon) = cat;
          final isSelected = _selectedCategory == source;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = source;
                  _news = _filterNews(_newsService?.cachedNews ?? []);
                });
              },
              child: AnimatedContainer(
                duration: DesignTokens.animFast,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DesignTokens.neonCyan.withValues(alpha: 0.2)
                      : DesignTokens.bgSecondary,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  border: Border.all(
                    color: isSelected
                        ? DesignTokens.neonCyan.withValues(alpha: 0.5)
                        : DesignTokens.borderSubtle,
                    width: DesignTokens.borderThin,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: isSelected
                          ? DesignTokens.neonCyan
                          : DesignTokens.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? DesignTokens.neonCyan
                            : DesignTokens.textMuted,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: DesignTokens.bgSecondary,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: DesignTokens.bgSecondary,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.borderSubtle),
      ),
      child: const Column(
        children: [
          Icon(Icons.newspaper, color: DesignTokens.textMuted, size: 40),
          SizedBox(height: 12),
          Text(
            'No news available',
            style: TextStyle(color: DesignTokens.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList() {
    // Tiered card hierarchy:
    // [0]     → Hero card (featured, large)
    // [1..2]  → Compact pair (side-by-side)
    // then every 7th item → trending section break
    // rest    → Standard cards with left accent bar

    final widgets = <Widget>[];

    for (int i = 0; i < _news.length; i++) {
      // Hero card — first article
      if (i == 0) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HeroNewsCard(article: _news[i]),
          ),
        );
        continue;
      }

      // Compact pair — articles 1 & 2 side-by-side
      if (i == 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _CompactNewsCard(article: _news[i])),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < _news.length
                      ? _CompactNewsCard(article: _news[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
        continue;
      }
      if (i == 2) continue; // already rendered in the pair

      // Trending section break every 7 items
      if (i > 3 && (i - 3) % 7 == 0) {
        widgets.add(_buildTrendingSectionBreak());
      }

      // Standard cards with left accent bar
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _NewsArticleCard(article: _news[i], compact: widget.compact),
        ),
      );
    }

    return Column(children: widgets);
  }

  Widget _buildTrendingSectionBreak() {
    final tags = [
      '#TitleFight',
      '#UFC',
      '#Boxing',
      '#KnockOut',
      '#Champion',
      '#MMA',
      '#FightWeek',
      '#PFL',
      '#GLORY',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up,
                color: DesignTokens.neonMagenta,
                size: 14,
              ),
              SizedBox(width: 6),
              Text(
                'TRENDING NOW',
                style: TextStyle(
                  color: DesignTokens.neonMagenta,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tags.map((tag) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonMagenta.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusPill,
                      ),
                      border: Border.all(
                        color: DesignTokens.neonMagenta.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: DesignTokens.neonMagenta.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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
}

// ─────────────────────────────────────────────────────────────
// Hero news card — large featured card for top story
// ─────────────────────────────────────────────────────────────
class _HeroNewsCard extends StatelessWidget {
  final FightNewsArticle article;
  const _HeroNewsCard({required this.article});

  Color get _accentColor {
    if (article.isBreaking) return DesignTokens.neonRed;
    return switch (article.category) {
      NewsSource.ufc => DesignTokens.neonRed,
      NewsSource.boxing => DesignTokens.neonGold,
      NewsSource.muayThai => DesignTokens.neonCyan,
      NewsSource.kickboxing => DesignTokens.neonMagenta,
      NewsSource.bareKnuckle => DesignTokens.warning,
      _ => DesignTokens.neonCyan,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentColor.withValues(alpha: 0.18),
            DesignTokens.bgCard.withValues(alpha: 0.9),
            DesignTokens.bgSecondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top accent bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentColor,
                  _accentColor.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source + badges row
                Row(
                  children: [
                    // Source avatar circle
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          article.sourceDisplay.isNotEmpty
                              ? article.sourceDisplay[0]
                              : '?',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      article.sourceDisplay,
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (article.isBreaking) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, color: Colors.white, size: 10),
                            SizedBox(width: 2),
                            Text(
                              'BREAKING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      article.timeAgo,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Large title
                Text(
                  article.title,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),

                // Summary
                Text(
                  article.summary,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Engagement row + Read
                Row(
                  children: [
                    if (article.viewCount != null) ...[
                      const Icon(
                        Icons.remove_red_eye_outlined,
                        color: DesignTokens.textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(article.viewCount!),
                        style: const TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    const Icon(
                      Icons.mode_comment_outlined,
                      color: DesignTokens.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      article.source,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Read Full Story',
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

// ─────────────────────────────────────────────────────────────
// Compact news card — small card for side-by-side pair
// ─────────────────────────────────────────────────────────────
class _CompactNewsCard extends StatelessWidget {
  final FightNewsArticle article;
  const _CompactNewsCard({required this.article});

  Color get _accentColor {
    return switch (article.category) {
      NewsSource.ufc => DesignTokens.neonRed,
      NewsSource.boxing => DesignTokens.neonGold,
      NewsSource.muayThai => DesignTokens.neonCyan,
      NewsSource.kickboxing => DesignTokens.neonMagenta,
      NewsSource.bareKnuckle => DesignTokens.warning,
      _ => DesignTokens.neonCyan,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DesignTokens.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: _accentColor, width: 3),
          top: BorderSide(
            color: _accentColor.withValues(alpha: 0.15),
            width: 0.5,
          ),
          right: BorderSide(
            color: _accentColor.withValues(alpha: 0.15),
            width: 0.5,
          ),
          bottom: BorderSide(
            color: _accentColor.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Source line
          Row(
            children: [
              Text(
                article.sourceDisplay,
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (article.isBreaking)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'BREAKING',
                    style: TextStyle(
                      color: DesignTokens.neonRed,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Title
          Text(
            article.title,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Time
          Text(
            article.timeAgo,
            style: const TextStyle(color: DesignTokens.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Individual news article card widget
// ─────────────────────────────────────────────────────────────
class _NewsArticleCard extends StatefulWidget {
  final FightNewsArticle article;
  final bool compact;

  const _NewsArticleCard({required this.article, this.compact = false});

  @override
  State<_NewsArticleCard> createState() => _NewsArticleCardState();
}

class _NewsArticleCardState extends State<_NewsArticleCard> {
  bool _isHovered = false;

  Color get _categoryColor {
    switch (widget.article.category) {
      case NewsSource.ufc:
        return DesignTokens.neonRed;
      case NewsSource.boxing:
        return DesignTokens.neonGold;
      case NewsSource.muayThai:
        return DesignTokens.neonCyan;
      case NewsSource.kickboxing:
        return DesignTokens.neonMagenta;
      case NewsSource.bareKnuckle:
        return DesignTokens.warning;
      case NewsSource.mma:
        return DesignTokens.neonCyan;
      default:
        return DesignTokens.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) return _buildCompact();
    return _buildFull();
  }

  Widget _buildCompact() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: DesignTokens.animFast,
        padding: const EdgeInsets.all(DesignTokens.cardPaddingSmall),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _isHovered ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(
            color: _categoryColor.withValues(alpha: _isHovered ? 0.3 : 0.15),
            width: DesignTokens.borderThin,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _categoryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article.title,
                    style: const TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.article.sourceDisplay} • ${widget.article.timeAgo}',
                    style: const TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.article.isBreaking)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.neonRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: DesignTokens.neonRed,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: DesignTokens.animFast,
        decoration: BoxDecoration(
          color: DesignTokens.bgSecondary.withValues(
            alpha: _isHovered ? 0.9 : 0.7,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: _categoryColor, width: 3),
            top: BorderSide(
              color: _categoryColor.withValues(alpha: _isHovered ? 0.3 : 0.12),
              width: 0.5,
            ),
            right: BorderSide(
              color: _categoryColor.withValues(alpha: _isHovered ? 0.3 : 0.12),
              width: 0.5,
            ),
            bottom: BorderSide(
              color: _categoryColor.withValues(alpha: _isHovered ? 0.3 : 0.12),
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source + badges + time — single row
              Row(
                children: [
                  // Source avatar
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _categoryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.article.sourceDisplay.isNotEmpty
                            ? widget.article.sourceDisplay[0]
                            : '?',
                        style: TextStyle(
                          color: _categoryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.article.sourceDisplay,
                    style: TextStyle(
                      color: _categoryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.article.isBreaking) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonRed.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'BREAKING',
                        style: TextStyle(
                          color: DesignTokens.neonRed,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  if (widget.article.isFeatured) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.star, color: DesignTokens.neonGold, size: 12),
                  ],
                  const Spacer(),
                  Text(
                    widget.article.timeAgo,
                    style: const TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                widget.article.title,
                style: const TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Summary
              Text(
                widget.article.summary,
                style: const TextStyle(
                  color: DesignTokens.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Inline engagement footer
              if (widget.article.viewCount != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.remove_red_eye_outlined,
                      color: DesignTokens.textMuted,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatCount(widget.article.viewCount!),
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.source_outlined,
                      color: DesignTokens.textMuted,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      widget.article.source,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: _categoryColor.withValues(alpha: 0.5),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

/// Breaking news ticker
class BreakingNewsTicker extends StatefulWidget {
  const BreakingNewsTicker({super.key});

  @override
  State<BreakingNewsTicker> createState() => _BreakingNewsTickerState();
}

class _BreakingNewsTickerState extends State<BreakingNewsTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  FightNewsService? _newsService;
  bool _depsReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _animation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: const Offset(-1.0, 0.0),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_depsReady) return;
    _newsService = context.read<FightNewsService>();
    _newsService!.startAutoRefresh();
    _depsReady = true;
  }

  @override
  Widget build(BuildContext context) {
    final newsService = _newsService ?? context.read<FightNewsService>();
    return StreamBuilder<List<FightNewsArticle>>(
      stream: newsService.newsStream,
      initialData: newsService.cachedNews,
      builder: (context, snapshot) {
        final breaking = (snapshot.data ?? const [])
            .where((article) => article.isBreaking)
            .toList();
        if (breaking.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonRed.withValues(alpha: 0.2),
                DesignTokens.neonMagenta.withValues(alpha: 0.1),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: DesignTokens.neonRed.withValues(alpha: 0.3),
              ),
              bottom: BorderSide(
                color: DesignTokens.neonRed.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: DesignTokens.neonRed,
                child: const Center(
                  child: Text(
                    'BREAKING',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SlideTransition(
                  position: _animation,
                  child: Row(
                    children: breaking.map((article) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 48),
                        child: Text(
                          article.title,
                          style: const TextStyle(
                            color: DesignTokens.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
