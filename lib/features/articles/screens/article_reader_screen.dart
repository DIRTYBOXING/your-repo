import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/dfc_network_image.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/news_model.dart';
import '../../../shared/services/article_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/share_service.dart';
import '../../../shared/widgets/dfc_shimmer.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC ARTICLE READER — Full-page immersive article experience
///
/// BKFC / ESPN / Bleacher Report quality:
/// • Hero image with gradient overlay
/// • Category pill + read time + publish date
/// • Rich sectioned body with emoji headers
/// • Engagement bar (like, share, bookmark)
/// • Related fighters / events links
/// • Parallax-style hero on scroll
/// ═══════════════════════════════════════════════════════════════════════════
class ArticleReaderScreen extends StatefulWidget {
  final String articleId;

  const ArticleReaderScreen({super.key, required this.articleId});

  @override
  State<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends State<ArticleReaderScreen> {
  NewsModel? _article;
  bool _isLoading = true;
  bool _hasLiked = false;
  bool _isBookmarked = false;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    final svc = context.read<ArticleService>();
    final article = await svc.getArticle(widget.articleId);
    if (article != null) {
      svc.recordView(widget.articleId);
      if (!mounted) return;
      final uid = context.read<AuthService>().currentUser?.uid;
      bool liked = false;
      if (uid != null) {
        liked = await svc.hasLiked(widget.articleId, uid);
      }
      if (mounted) {
        setState(() {
          _article = article;
          _hasLiked = liked;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike() async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null || _article == null) return;
    HapticFeedback.lightImpact();
    setState(() => _hasLiked = !_hasLiked);
    await context.read<ArticleService>().toggleLike(widget.articleId, uid);
  }

  Future<void> _shareArticle() async {
    if (_article == null) return;
    HapticFeedback.mediumImpact();
    context.read<ArticleService>().recordShare(widget.articleId);
    ShareService.instance.shareGeneric(
      text: '${_article!.title}\n\nRead on DFC FightMedia',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();
    if (_article == null) return _buildNotFound();
    return _buildReader();
  }

  // ── Full article reader ───────────────────────────────────────────────
  Widget _buildReader() {
    final a = _article!;
    final screenWidth = MediaQuery.of(context).size.width;
    final heroHeight = screenWidth * 0.56; // 16:9 ratio

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollUpdateNotification) {
            setState(() => _scrollOffset = n.metrics.pixels);
          }
          return false;
        },
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── Hero image with parallax ──
                SliverToBoxAdapter(child: _buildHero(a, heroHeight)),

                // ── Article metadata ──
                SliverToBoxAdapter(child: _buildMetaBar(a)),

                // ── Title ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      a.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),

                // ── Author + date row ──
                SliverToBoxAdapter(child: _buildAuthorRow(a)),

                // ── Engagement bar ──
                SliverToBoxAdapter(child: _buildEngagementBar(a)),

                // ── Divider ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                      height: 1,
                    ),
                  ),
                ),

                // ── Article body sections ──
                SliverToBoxAdapter(child: _buildBody(a)),

                // ── Tags ──
                if (a.tags.isNotEmpty) SliverToBoxAdapter(child: _buildTags(a)),

                // ── Related links ──
                if (a.hasRelatedContent)
                  SliverToBoxAdapter(child: _buildRelatedSection(a)),

                // ── Bottom padding ──
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // ── Floating back button ──
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: _floatingButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
            ),

            // ── Floating share button ──
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: _floatingButton(
                icon: Icons.ios_share,
                onTap: _shareArticle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero image with gradient ──────────────────────────────────────────
  Widget _buildHero(NewsModel a, double heroHeight) {
    final parallax = (_scrollOffset * 0.3).clamp(-50.0, 100.0);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image with parallax
          Transform.translate(
            offset: Offset(0, parallax),
            child: a.featuredImageUrl != null && a.featuredImageUrl!.isNotEmpty
                ? DfcNetworkImage(
                    url: a.featuredImageUrl!,
                    height: heroHeight + 50,
                  )
                : _heroPlaceholder(a),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  DesignTokens.bgPrimary.withValues(alpha: 0.6),
                  DesignTokens.bgPrimary,
                ],
                stops: const [0.3, 0.7, 1.0],
              ),
            ),
          ),
          // Category pill overlay (bottom-left)
          if (a.categories.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 20,
              child: _categoryPill(a.categories.first),
            ),
          // Breaking badge
          if (a.isBreakingNews)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'BREAKING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _heroPlaceholder(NewsModel a) {
    // Combat-themed gradient placeholder
    final cat = a.categories.isNotEmpty ? a.categories.first : 'general';
    final colors = _colorsForCategory(cat);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.$1, colors.$2],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_mma,
          color: Colors.white.withValues(alpha: 0.15),
          size: 120,
        ),
      ),
    );
  }

  // ── Meta bar: read time + date + views ────────────────────────────────
  Widget _buildMetaBar(NewsModel a) {
    final dateStr = a.publishedAt != null
        ? DateFormat('MMM d, yyyy').format(a.publishedAt!)
        : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          if (a.readTime != null) ...[
            Icon(
              Icons.schedule,
              size: 14,
              color: DesignTokens.neonCyan.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              a.readTime!,
              style: TextStyle(
                color: DesignTokens.neonCyan.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            _dot(),
          ],
          Text(
            dateStr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
          _dot(),
          Icon(
            Icons.visibility_outlined,
            size: 14,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          const SizedBox(width: 4),
          Text(
            _formatCount(a.viewsCount),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Author row ────────────────────────────────────────────────────────
  Widget _buildAuthorRow(NewsModel a) {
    final authorDisplay = a.sourceName ?? 'DFC FightMedia';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
              ),
            ),
            child: const Center(
              child: Text(
                'DFC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authorDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'DFC Editorial',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Featured star
          if (a.isFeatured)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: DesignTokens.neonGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: DesignTokens.neonGold.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 12, color: DesignTokens.neonGold),
                  SizedBox(width: 4),
                  Text(
                    'FEATURED',
                    style: TextStyle(
                      color: DesignTokens.neonGold,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Engagement bar (like / comment / share / bookmark) ────────────────
  Widget _buildEngagementBar(NewsModel a) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          _engagementChip(
            icon: _hasLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(a.likesCount + (_hasLiked ? 1 : 0)),
            color: _hasLiked ? DesignTokens.neonRed : Colors.white54,
            onTap: _toggleLike,
          ),
          const SizedBox(width: 16),
          _engagementChip(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(a.commentsCount),
            color: Colors.white54,
            onTap: () {},
          ),
          const SizedBox(width: 16),
          _engagementChip(
            icon: Icons.share_outlined,
            label: _formatCount(a.sharesCount),
            color: Colors.white54,
            onTap: _shareArticle,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isBookmarked = !_isBookmarked);
            },
            child: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked
                  ? DesignTokens.neonGold
                  : Colors.white.withValues(alpha: 0.4),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _engagementChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Article body — parses sections by emoji headers ───────────────────
  Widget _buildBody(NewsModel a) {
    final sections = _parseSections(a.content);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections.map((section) {
          if (section.isHeader) {
            return Padding(
              padding: const EdgeInsets.only(top: 28, bottom: 12),
              child: Text(
                section.text,
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              section.text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 16,
                height: 1.65,
                letterSpacing: 0.1,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Tags ──────────────────────────────────────────────────────────────
  Widget _buildTags(NewsModel a) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: a.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.15),
              ),
            ),
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
      ),
    );
  }

  // ── Related section ───────────────────────────────────────────────────
  Widget _buildRelatedSection(NewsModel a) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RELATED',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          if (a.relatedFighterIds.isNotEmpty)
            ...a.relatedFighterIds.map(
              (fId) => _relatedChip(
                Icons.sports_mma,
                fId,
                DesignTokens.neonCyan,
                () => context.push('/fighter/$fId'),
              ),
            ),
          if (a.relatedEventIds.isNotEmpty)
            ...a.relatedEventIds.map(
              (eId) => _relatedChip(
                Icons.event,
                eId,
                DesignTokens.neonMagenta,
                () => context.push('/event/$eId'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _relatedChip(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Skeleton loader ───────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DFCShimmer.card(height: 220),
              const SizedBox(height: 20),
              const DFCShimmer.line(width: 100, height: 14),
              const SizedBox(height: 16),
              const DFCShimmer.line(width: double.infinity, height: 24),
              const SizedBox(height: 8),
              const DFCShimmer.line(width: 250, height: 24),
              const SizedBox(height: 20),
              Row(
                children: [
                  DFCShimmer.circle(size: 32),
                  const SizedBox(width: 12),
                  const DFCShimmer.line(height: 14),
                ],
              ),
              const SizedBox(height: 24),
              const DFCShimmer.line(width: double.infinity, height: 14),
              const SizedBox(height: 10),
              const DFCShimmer.line(width: double.infinity, height: 14),
              const SizedBox(height: 10),
              const DFCShimmer.line(width: 200, height: 14),
            ],
          ),
        ),
      ),
    );
  }

  // ── Not found ─────────────────────────────────────────────────────────
  Widget _buildNotFound() {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            Text(
              'Article not found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Go Back',
                style: TextStyle(color: DesignTokens.neonCyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Floating circular button ──────────────────────────────────────────
  Widget _floatingButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: DesignTokens.bgPrimary.withValues(alpha: 0.8),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // ── Category pill ─────────────────────────────────────────────────────
  Widget _categoryPill(String category) {
    final colors = _colorsForCategory(category);
    final label = category.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.$1, colors.$2]),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '·',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 14,
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  (Color, Color) _colorsForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'boxing':
        return (const Color(0xFFFF3366), const Color(0xFFFF6B35));
      case 'mma':
        return (DesignTokens.neonCyan, const Color(0xFF00A3CC));
      case 'muay_thai':
        return (const Color(0xFFFF8800), const Color(0xFFFFAA00));
      case 'bkfc':
      case 'brawling':
      case 'bare_knuckle':
        return (const Color(0xFFCC0000), const Color(0xFFFF4444));
      case 'wrestling':
        return (const Color(0xFF8B5CF6), const Color(0xFFA78BFA));
      case 'kickboxing':
        return (DesignTokens.neonGreen, const Color(0xFF00CC66));
      case 'local':
        return (DesignTokens.neonGold, const Color(0xFFFFAA00));
      default:
        return (DesignTokens.neonCyan, DesignTokens.neonMagenta);
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  /// Parse content into sections. Lines starting with emoji (Unicode > 0x1F000)
  /// or common section markers are treated as headers.
  List<_Section> _parseSections(String content) {
    final lines = content.split('\n');
    final sections = <_Section>[];
    final buffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        if (buffer.isNotEmpty) {
          sections.add(_Section(text: buffer.toString().trim()));
          buffer.clear();
        }
        continue;
      }
      // Detect section headers (emoji-prefixed or all-caps with special chars)
      if (_isSectionHeader(trimmed)) {
        if (buffer.isNotEmpty) {
          sections.add(_Section(text: buffer.toString().trim()));
          buffer.clear();
        }
        sections.add(_Section(text: trimmed, isHeader: true));
      } else {
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(trimmed);
      }
    }
    if (buffer.isNotEmpty) {
      sections.add(_Section(text: buffer.toString().trim()));
    }
    return sections;
  }

  bool _isSectionHeader(String line) {
    if (line.isEmpty) return false;
    // Starts with emoji (Unicode range)
    final firstCodeUnit = line.codeUnits.first;
    if (firstCodeUnit > 0xD800) return true; // Surrogate pair = emoji
    // Common emoji bytes
    if (line.startsWith('🌏') ||
        line.startsWith('🥊') ||
        line.startsWith('🔥') ||
        line.startsWith('🌟') ||
        line.startsWith('🐉') ||
        line.startsWith('⚡') ||
        line.startsWith('💪') ||
        line.startsWith('🏆')) {
      return true;
    }
    // All-caps lines that look like headers
    if (line.length < 80 &&
        line == line.toUpperCase() &&
        line.contains(RegExp(r'[A-Z]{3,}'))) {
      return true;
    }
    return false;
  }
}

class _Section {
  final String text;
  final bool isHeader;
  const _Section({required this.text, this.isHeader = false});
}
