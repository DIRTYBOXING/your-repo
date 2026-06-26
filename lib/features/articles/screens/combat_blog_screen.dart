import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/dfc_article_model.dart';
import '../../../shared/services/combat_blog_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// COMBAT BLOG SCREEN — Curated editorial content hub for DFC
///
/// Tab-driven layout: All | Events | Fighters | BKFC | Campaigns
/// Uses DfcArticleModel from dfc_articles Firestore collection.
/// Falls back to demo content when Firestore is empty.
/// ═══════════════════════════════════════════════════════════════════════════
class CombatBlogScreen extends StatefulWidget {
  const CombatBlogScreen({super.key});

  @override
  State<CombatBlogScreen> createState() => _CombatBlogScreenState();
}

class _CombatBlogScreenState extends State<CombatBlogScreen>
    with SingleTickerProviderStateMixin {
  final _service = CombatBlogService.instance;
  late TabController _tabCtrl;
  List<DfcArticleModel> _articles = [];
  bool _isLoading = true;

  static const _tabs = [
    'All',
    'Events',
    'Fighters',
    'BKFC',
    'Campaigns',
    'Recaps',
  ];

  static const _tabTypeMap = <String, DfcArticleType?>{
    'All': null,
    'Events': DfcArticleType.eventHypeFeature,
    'Fighters': DfcArticleType.fighterStory,
    'BKFC': DfcArticleType.bkfcSpecial,
    'Campaigns': DfcArticleType.cityFeature,
    'Recaps': DfcArticleType.resultsRecap,
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this)
      ..addListener(_onTabChanged);
    _loadArticles();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabCtrl.indexIsChanging) _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    final type = _tabTypeMap[_tabs[_tabCtrl.index]];

    // Try Firestore first, fall back to demo
    try {
      final stream = _service.publishedStream(limit: 30, type: type);
      final snap = await stream.first;
      if (snap.isNotEmpty) {
        if (mounted) {
          setState(() {
            _articles = snap;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {
      // Firestore unavailable — use demo
    }

    // Filter demo content for selected tab
    var demo = _service.demoArticles;
    if (type != null) {
      demo = demo.where((a) => a.type == type).toList();
    }
    if (mounted) {
      setState(() {
        _articles = demo;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: NestedScrollView(
        headerSliverBuilder: (context, inner) => [
          _buildAppBar(),
          _buildTabBar(),
        ],
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF2D55)),
              )
            : _articles.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                color: const Color(0xFFFF2D55),
                onRefresh: _loadArticles,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _articles.length,
                  itemBuilder: (ctx, i) {
                    if (i == 0) return _buildHeroCard(_articles[i]);
                    return _buildArticleCard(_articles[i]);
                  },
                ),
              ),
      ),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: const Color(0xFF0A0A0F),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'COMBAT BLOG',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white70),
          onPressed: () {}, // Search pending
        ),
      ],
    );
  }

  // ─── TAB BAR ─────────────────────────────────────────────────────────

  SliverPersistentHeader _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: const Color(0xFFFF2D55),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
    );
  }

  // ─── HERO CARD ───────────────────────────────────────────────────────

  Widget _buildHeroCard(DfcArticleModel article) {
    return GestureDetector(
      onTap: () => _openArticle(article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0F)],
          ),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2D55).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background glow
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF2D55).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _typeBadge(article.type),
                      const Spacer(),
                      if (article.publishedAt != null)
                        Text(
                          DateFormat.MMMd().format(article.publishedAt!),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  if (article.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      article.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      _tagChip(
                        article.tags.isNotEmpty ? article.tags.first : 'DFC',
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFFFF2D55),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'READ',
                        style: TextStyle(
                          color: Color(0xFFFF2D55),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1,
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

  // ─── LIST CARD ───────────────────────────────────────────────────────

  Widget _buildArticleCard(DfcArticleModel article) {
    return GestureDetector(
      onTap: () => _openArticle(article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _typeBadge(article.type, small: true),
                      const SizedBox(width: 8),
                      if (article.publishedAt != null)
                        Text(
                          DateFormat.MMMd().format(article.publishedAt!),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.subtitle ??
                        article.bodyMarkdown.substring(
                          0,
                          article.bodyMarkdown.length.clamp(0, 80),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: _typeColors(article.type)),
              ),
              child: Icon(
                _typeIcon(article.type),
                color: Colors.white.withValues(alpha: 0.7),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── EMPTY STATE ─────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No articles yet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for combat sports content',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────

  void _openArticle(DfcArticleModel article) {
    // Navigate to article reader with the article ID
    context.push('/article/${article.id}');
  }

  Widget _typeBadge(DfcArticleType type, {bool small = false}) {
    final colors = _typeColors(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _typeLabel(type),
        style: TextStyle(
          color: Colors.white,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _tagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _typeLabel(DfcArticleType type) {
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
        return 'CAMPAIGN';
      case DfcArticleType.bkfcSpecial:
        return 'BKFC';
    }
  }

  List<Color> _typeColors(DfcArticleType type) {
    switch (type) {
      case DfcArticleType.eventAnnouncement:
      case DfcArticleType.eventHypeFeature:
        return const [Color(0xFFFF2D55), Color(0xFFFF6B35)];
      case DfcArticleType.resultsRecap:
        return const [Color(0xFF00C9FF), Color(0xFF0066FF)];
      case DfcArticleType.fighterStory:
        return const [Color(0xFF7C3AED), Color(0xFF4F46E5)];
      case DfcArticleType.promoterProfile:
        return const [Color(0xFFFF9500), Color(0xFFFF6B00)];
      case DfcArticleType.cityFeature:
        return const [Color(0xFFFF2D78), Color(0xFFFF6B9D)];
      case DfcArticleType.bkfcSpecial:
        return const [Color(0xFFDC2626), Color(0xFF991B1B)];
    }
  }

  IconData _typeIcon(DfcArticleType type) {
    switch (type) {
      case DfcArticleType.eventAnnouncement:
      case DfcArticleType.eventHypeFeature:
        return Icons.event;
      case DfcArticleType.resultsRecap:
        return Icons.emoji_events;
      case DfcArticleType.fighterStory:
        return Icons.person;
      case DfcArticleType.promoterProfile:
        return Icons.business;
      case DfcArticleType.cityFeature:
        return Icons.campaign;
      case DfcArticleType.bkfcSpecial:
        return Icons.sports_mma;
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB BAR PERSISTENT HEADER DELEGATE
// ═════════════════════════════════════════════════════════════════════════════
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

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
    return Container(color: const Color(0xFF0A0A0F), child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => false;
}
