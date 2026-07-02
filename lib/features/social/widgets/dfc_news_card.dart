import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../shared/services/fight_news_service.dart';

/// Professional fight news article card — Boxing News 24 / Sherdog / DAZN style.
/// Renders FightNewsArticle with hero gradient, bold headline, source badge,
/// author byline, date, comment count, and summary.
class DFCNewsCard extends StatelessWidget {
  final FightNewsArticle article;
  final VoidCallback? onTap;

  const DFCNewsCard({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: GlassPanel(
        padding: EdgeInsets.zero,
        backgroundColor: kIsWeb
            ? const Color(0xFF0A1628).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderColor: article.isBreaking
            ? DesignTokens.neonRed.withValues(alpha: 0.5)
            : article.isFeatured
            ? DesignTokens.neonGold.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        borderWidth: article.isBreaking ? 1.5 : 1,
        shadows: article.isBreaking
            ? [
                BoxShadow(
                  color: DesignTokens.neonRed.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ]
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero gradient area with sport icon + source badge
            _buildHeroArea(),
            // Content area — summary + engagement
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.summary,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildHeroArea() {
    final gradient = _sportGradient(article.category);
    return LayoutBuilder(
      builder: (context, constraints) {
      // 16:9 aspect ratio, clamped 140-260px
      final h = (constraints.maxWidth * 9 / 16).clamp(140.0, 260.0);
      return Container(
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        image: DecorationImage(
          image: ImageAssets.safeProvider(article.imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.35),
            BlendMode.darken,
          ),
          onError: (_, _) {},
        ),
      ),
      child: Stack(
        children: [
          // Bottom gradient for text legibility
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
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
          ),
          // Top badges
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _buildCategoryBadge(),
                const SizedBox(width: 6),
                if (article.isBreaking) _buildBreakingBadge(),
                if (article.isFeatured && !article.isBreaking)
                  _buildFeaturedBadge(),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    article.timeAgo,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom headline overlay
          Positioned(
            bottom: 10,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      article.source.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (article.authorName != null) ...[
                      Text(
                        ' \u2022 ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          article.authorName!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
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
      },
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        article.sourceDisplay.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildBreakingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: DesignTokens.neonRed,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 10, color: Colors.white),
          SizedBox(width: 2),
          Text(
            'BREAKING',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: DesignTokens.neonGold.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 10, color: Colors.black),
          SizedBox(width: 2),
          Text(
            'FEATURED',
            style: TextStyle(
              color: Colors.black,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        // Author
        if (article.authorName != null) ...[
          Icon(
            Icons.person_outline,
            size: 13,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              article.authorName!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
        ],
        // Date
        Icon(
          Icons.schedule,
          size: 12,
          color: Colors.white.withValues(alpha: 0.35),
        ),
        const SizedBox(width: 3),
        Text(
          _formatDate(article.publishedAt),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
          ),
        ),
        // Comment count
        if (article.commentCount > 0) ...[
          const SizedBox(width: 10),
          Icon(
            Icons.chat_bubble_outline,
            size: 12,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          const SizedBox(width: 3),
          Text(
            '${article.commentCount}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
        const Spacer(),
        // Read more
        Text(
          'Read more \u203A',
          style: TextStyle(
            color: DesignTokens.neonCyan.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  List<Color> _sportGradient(NewsSource category) {
    switch (category) {
      case NewsSource.ufc:
        return [const Color(0xFF8B0000), const Color(0xFF2D0000)];
      case NewsSource.boxing:
        return [const Color(0xFF1B5E20), const Color(0xFF0A2410)];
      case NewsSource.mma:
        return [const Color(0xFF4A148C), const Color(0xFF1A0530)];
      case NewsSource.bareKnuckle:
        return [const Color(0xFFB71C1C), const Color(0xFF3E0000)];
      case NewsSource.brawling:
        return [const Color(0xFF880E4F), const Color(0xFF2D0018)];
      case NewsSource.muayThai:
        return [const Color(0xFFE65100), const Color(0xFF4E1A00)];
      case NewsSource.kickboxing:
        return [const Color(0xFFFF6F00), const Color(0xFF4E2200)];
      case NewsSource.wrestling:
        return [const Color(0xFF0D47A1), const Color(0xFF041830)];
      case NewsSource.rizin:
        return [const Color(0xFFC62828), const Color(0xFF3E0000)];
      case NewsSource.ringMagazine:
        return [const Color(0xFF827717), const Color(0xFF2A2800)];
      case NewsSource.espn:
        return [const Color(0xFFCC0000), const Color(0xFF400000)];
      default:
        return [const Color(0xFF263238), const Color(0xFF0D1418)];
    }
  }
}
