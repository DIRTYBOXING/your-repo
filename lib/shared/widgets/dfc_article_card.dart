import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../shared/models/news_model.dart';
import 'dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC ARTICLE CARD — Feed-ready card for articles (like ESPN / Bleacher Report)
///
/// Two variants:
///   DFCArticleCard.hero()   — Large hero card (featured articles)
///   DFCArticleCard.compact() — Compact horizontal card (feed list)
/// ═══════════════════════════════════════════════════════════════════════════
class DFCArticleCard extends StatelessWidget {
  final NewsModel article;
  final bool isHero;

  const DFCArticleCard({super.key, required this.article, this.isHero = false});

  const DFCArticleCard.hero({super.key, required this.article}) : isHero = true;

  const DFCArticleCard.compact({super.key, required this.article})
    : isHero = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/article/${article.id}');
      },
      child: isHero ? _buildHeroCard(context) : _buildCompactCard(context),
    );
  }

  // ── Hero variant: large image top, title below ────────────────────────
  Widget _buildHeroCard(BuildContext context) {
    final cat = article.categories.isNotEmpty ? article.categories.first : '';
    final colors = _colorsForCategory(cat);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DfcNetworkImage(
                    url: article.featuredImageUrl ?? '',
                  ),
                  // Bottom gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            DesignTokens.bgCard.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Breaking badge
                  if (article.isBreakingNews)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BREAKING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  // Category pill
                  if (cat.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      left: 12,
                      child: _categoryPill(cat, colors),
                    ),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                _metaRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Compact variant: horizontal with thumbnail ────────────────────────
  Widget _buildCompactCard(BuildContext context) {
    final cat = article.categories.isNotEmpty ? article.categories.first : '';
    final colors = _colorsForCategory(cat);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DfcNetworkImage(
                    url: article.featuredImageUrl ?? '',
                  ),
                  if (article.isBreakingNews)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonRed,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cat.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      cat.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: colors.$1,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                _metaRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared meta row: source + time + read time ────────────────────────
  Widget _metaRow() {
    final dateStr = article.publishedAt != null
        ? _timeAgo(article.publishedAt!)
        : '';
    return Row(
      children: [
        Text(
          article.sourceName ?? 'DFC',
          style: TextStyle(
            color: DesignTokens.neonCyan.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (dateStr.isNotEmpty) ...[
          _dot(),
          Text(
            dateStr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
            ),
          ),
        ],
        if (article.readTime != null) ...[
          _dot(),
          Text(
            article.readTime!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '·',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.25),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _categoryPill(String cat, (Color, Color) colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.$1, colors.$2]),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        cat.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return DateFormat('MMM d').format(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

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
}
