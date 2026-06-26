import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/services/combat_blog_service.dart';
import '../../../shared/models/dfc_article_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT STORIES — Professional editorial magazine for combat sports
///
/// ESPN / Sherdog / MMA Junkie grade:
/// • Featured cover story with full-bleed hero
/// • Fighter profile stories with pull quotes
/// • Breaking news ticker
/// • Category filters (All, Fighters, Events, BKFC, Recaps)
/// • Shareable card format
/// • Magazine-quality typography & layout
/// ═══════════════════════════════════════════════════════════════════════════

const _kBg = Color(0xFF050A14);
const _kCard = Color(0xFF0D1B2A);
const _kBorderDim = Color(0xFF1A2744);
const _kCyan = Color(0xFF00F5FF);
const _kRed = Color(0xFFFF3366);
const _kGold = Color(0xFFFFD700);
const _kMagenta = Color(0xFFFF00FF);

class FightStoriesScreen extends StatefulWidget {
  const FightStoriesScreen({super.key});

  @override
  State<FightStoriesScreen> createState() => _FightStoriesScreenState();
}

class _FightStoriesScreenState extends State<FightStoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<DfcArticleModel> _articles = [];
  bool _loading = true;
  int _selectedCategory = 0;

  static const _categories = [
    _Category('ALL', Icons.grid_view_rounded, null),
    _Category('FIGHTERS', Icons.person, DfcArticleType.fighterStory),
    _Category('EVENTS', Icons.event, DfcArticleType.eventHypeFeature),
    _Category('BKFC', Icons.local_fire_department, DfcArticleType.bkfcSpecial),
    _Category('RECAPS', Icons.emoji_events, DfcArticleType.resultsRecap),
    _Category('CITIES', Icons.location_city, DfcArticleType.cityFeature),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _categories.length, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          setState(() => _selectedCategory = _tabCtrl.index);
          _load();
        }
      });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final svc = CombatBlogService.instance;
    final type = _categories[_selectedCategory].type;

    try {
      final stream = svc.publishedStream(limit: 30, type: type);
      final snap = await stream.first;
      if (snap.isNotEmpty && mounted) {
        setState(() {
          _articles = snap;
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback to demo
    var demo = svc.demoArticles;
    if (type != null) {
      demo = demo.where((a) => a.type == type).toList();
    }
    if (mounted) {
      setState(() {
        _articles = demo;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          _buildAppBar(),
          _buildCategoryBar(),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _kRed))
            : _articles.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                color: _kRed,
                onRefresh: _load,
                child: CustomScrollView(
                  slivers: [
                    // Cover story
                    if (_articles.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildCoverStory(_articles.first),
                      ),

                    // Breaking ticker
                    SliverToBoxAdapter(child: _buildBreakingTicker()),

                    // Section: Latest
                    SliverToBoxAdapter(child: _sectionHeader('LATEST')),

                    // Editorial cards
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final idx = i + 1; // skip cover story
                            if (idx >= _articles.length) return null;
                            // Alternate between wide and compact layouts
                            if (i % 5 == 0 && idx + 1 < _articles.length) {
                              return _buildDualCard(
                                _articles[idx],
                                _articles[idx + 1],
                              );
                            }
                            return _buildEditorialCard(_articles[idx]);
                          },
                          childCount: (_articles.length - 1).clamp(
                            0,
                            _articles.length,
                          ),
                        ),
                      ),
                    ),

                    // Fighter spotlight (if fighter stories exist)
                    if (_hasFighterStories) ...[
                      SliverToBoxAdapter(
                        child: _sectionHeader('FIGHTER SPOTLIGHT'),
                      ),
                      SliverToBoxAdapter(child: _buildFighterSpotlightRow()),
                    ],

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
    );
  }

  bool get _hasFighterStories =>
      _articles.any((a) => a.type == DfcArticleType.fighterStory);

  // ═══════════════════════════════════════════════════════════════════════
  // APP BAR — Magazine masthead
  // ═══════════════════════════════════════════════════════════════════════
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: _kBg,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white70, size: 18),
        ),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kRed, Color(0xFFFF6B35)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _kRed.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'DFC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FIGHT STORIES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'COMBAT SPORTS EDITORIAL',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white54),
          onPressed: () {},
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: _kCyan.withValues(alpha: 0.1),
              border: Border.all(color: _kCyan.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.edit_note, color: _kCyan, size: 16),
          ),
          onPressed: () => context.push('/write-article'),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CATEGORY FILTER BAR
  // ═══════════════════════════════════════════════════════════════════════
  SliverPersistentHeader _buildCategoryBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedBarDelegate(
        height: 52,
        child: Container(
          color: _kBg,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final cat = _categories[i];
              final selected = i == _selectedCategory;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _tabCtrl.animateTo(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: selected
                        ? _kRed.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: selected
                          ? _kRed.withValues(alpha: 0.6)
                          : Colors.white10,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.icon,
                        size: 14,
                        color: selected ? _kRed : Colors.white38,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.label,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // COVER STORY — Full-bleed magazine hero
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildCoverStory(DfcArticleModel article) {
    return GestureDetector(
      onTap: () => _openArticle(article),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        height: 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1028), Color(0xFF0A0E1A)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: _kRed.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative accent
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _typeAccent(article.type).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TypeBadge(type: article.type),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: _kRed.withValues(alpha: 0.15),
                          border: Border.all(
                            color: _kRed.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: _kRed,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'COVER STORY',
                              style: TextStyle(
                                color: _kRed,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Title — magazine-grade typography
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (article.subtitle != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      article.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Bottom bar
                  Row(
                    children: [
                      // Tags
                      if (article.tags.isNotEmpty) _TagPill(article.tags.first),
                      if (article.tags.length > 1) ...[
                        const SizedBox(width: 6),
                        _TagPill(article.tags[1]),
                      ],
                      const Spacer(),
                      // Read CTA
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              _typeAccent(article.type),
                              _typeAccent(article.type).withValues(alpha: 0.7),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _typeAccent(
                                article.type,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'READ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 14,
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BREAKING TICKER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildBreakingTicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _kRed.withValues(alpha: 0.08),
        border: Border.all(color: _kRed.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _kRed,
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _articles.isNotEmpty
                  ? _articles.take(3).map((a) => a.title).join('  •  ')
                  : 'No breaking stories',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EDITORIAL CARD — Sherdog / ESPN quality
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildEditorialCard(DfcArticleModel article) {
    return GestureDetector(
      onTap: () => _openArticle(article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorderDim.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TypeBadge(type: article.type, small: true),
                      const SizedBox(width: 8),
                      if (article.publishedAt != null)
                        Text(
                          _formatDate(article.publishedAt!),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.subtitle ??
                        article.bodyMarkdown.substring(
                          0,
                          article.bodyMarkdown.length.clamp(0, 100),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Share + read row
                  Row(
                    children: [
                      if (article.tags.isNotEmpty) _TagPill(article.tags.first),
                      const Spacer(),
                      Icon(
                        Icons.share_outlined,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.bookmark_border,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Thumbnail placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _typeGradient(article.type),
                ),
              ),
              child: Center(
                child: Icon(
                  _typeIcon(article.type),
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DUAL CARD — Side-by-side compact format
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildDualCard(DfcArticleModel a, DfcArticleModel b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(child: _buildCompactCard(a)),
          const SizedBox(width: 12),
          Expanded(child: _buildCompactCard(b)),
        ],
      ),
    );
  }

  Widget _buildCompactCard(DfcArticleModel article) {
    return GestureDetector(
      onTap: () => _openArticle(article),
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorderDim.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeBadge(type: article.type, small: true),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
            Row(
              children: [
                if (article.tags.isNotEmpty) _TagPill(article.tags.first),
                const Spacer(),
                Icon(
                  Icons.arrow_forward,
                  size: 12,
                  color: _typeAccent(article.type).withValues(alpha: 0.6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FIGHTER SPOTLIGHT ROW — Horizontal scrollable
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildFighterSpotlightRow() {
    final fighters = _articles
        .where((a) => a.type == DfcArticleType.fighterStory)
        .toList();
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: fighters.length.clamp(0, 8),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) => _buildFighterCard(fighters[i]),
      ),
    );
  }

  Widget _buildFighterCard(DfcArticleModel article) {
    return GestureDetector(
      onTap: () => _openArticle(article),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0A2E), Color(0xFF0A0E1A)],
          ),
          border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.person, color: Colors.white70, size: 22),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const _TypeBadge(
                  type: DfcArticleType.fighterStory,
                  small: true,
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward,
                  size: 12,
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: _kRed,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories,
            size: 56,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 16),
          Text(
            'No stories in this category',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back for new editorial content',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════
  void _openArticle(DfcArticleModel article) {
    HapticFeedback.lightImpact();
    context.push('/article/${article.id}');
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  static Color _typeAccent(DfcArticleType type) {
    switch (type) {
      case DfcArticleType.eventAnnouncement:
      case DfcArticleType.eventHypeFeature:
        return _kRed;
      case DfcArticleType.resultsRecap:
        return _kCyan;
      case DfcArticleType.fighterStory:
        return const Color(0xFF7C3AED);
      case DfcArticleType.promoterProfile:
        return _kGold;
      case DfcArticleType.cityFeature:
        return _kMagenta;
      case DfcArticleType.bkfcSpecial:
        return const Color(0xFFDC2626);
    }
  }

  static List<Color> _typeGradient(DfcArticleType type) {
    switch (type) {
      case DfcArticleType.eventAnnouncement:
      case DfcArticleType.eventHypeFeature:
        return const [Color(0xFF3D0A0A), Color(0xFF1A0808)];
      case DfcArticleType.resultsRecap:
        return const [Color(0xFF0A2A3D), Color(0xFF081A22)];
      case DfcArticleType.fighterStory:
        return const [Color(0xFF1A0A3D), Color(0xFF0D0822)];
      case DfcArticleType.promoterProfile:
        return const [Color(0xFF3D2A0A), Color(0xFF221A08)];
      case DfcArticleType.cityFeature:
        return const [Color(0xFF3D0A2A), Color(0xFF220818)];
      case DfcArticleType.bkfcSpecial:
        return const [Color(0xFF3D0000), Color(0xFF220000)];
    }
  }

  static IconData _typeIcon(DfcArticleType type) {
    switch (type) {
      case DfcArticleType.eventAnnouncement:
      case DfcArticleType.eventHypeFeature:
        return Icons.event;
      case DfcArticleType.resultsRecap:
        return Icons.emoji_events;
      case DfcArticleType.fighterStory:
        return Icons.person;
      case DfcArticleType.promoterProfile:
        return Icons.business_center;
      case DfcArticleType.cityFeature:
        return Icons.location_city;
      case DfcArticleType.bkfcSpecial:
        return Icons.local_fire_department;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _Category {
  final String label;
  final IconData icon;
  final DfcArticleType? type;
  const _Category(this.label, this.icon, this.type);
}

class _TypeBadge extends StatelessWidget {
  final DfcArticleType type;
  final bool small;
  const _TypeBadge({required this.type, this.small = false});

  @override
  Widget build(BuildContext context) {
    final accent = _FightStoriesScreenState._typeAccent(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: accent.withValues(alpha: 0.15),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: accent,
          fontSize: small ? 9 : 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String get _label {
    switch (type) {
      case DfcArticleType.eventAnnouncement:
        return 'EVENT';
      case DfcArticleType.eventHypeFeature:
        return 'HYPE';
      case DfcArticleType.resultsRecap:
        return 'RECAP';
      case DfcArticleType.fighterStory:
        return 'FIGHTER';
      case DfcArticleType.promoterProfile:
        return 'PROMOTER';
      case DfcArticleType.cityFeature:
        return 'CITY';
      case DfcArticleType.bkfcSpecial:
        return 'BKFC';
    }
  }
}

class _TagPill extends StatelessWidget {
  final String tag;
  const _TagPill(this.tag);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.06),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PinnedBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _PinnedBarDelegate({required this.height, required this.child});

  @override
  Widget build(BuildContext ctx, double shrink, bool overlap) => child;
  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(_PinnedBarDelegate old) => false;
}
