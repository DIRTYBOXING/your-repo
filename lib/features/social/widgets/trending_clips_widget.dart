import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/social_clip_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// TRENDING CLIPS WIDGET — "Viral Right Now" Carousel
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Horizontal scrolling carousel of top trending clips.
/// Displays:
///   - Clip thumbnail
///   - Trending rank (#1, #2, etc.)
///   - Clip title
///   - View count
///   - Engagement metrics
///   - Tap to preview
///
/// ═══════════════════════════════════════════════════════════════════════════

class TrendingClipsWidget extends StatelessWidget {
  final List<SocialClip> clips;
  final void Function(SocialClip) onClipTap;

  const TrendingClipsWidget({
    super.key,
    required this.clips,
    required this.onClipTap,
  });

  @override
  Widget build(BuildContext context) {
    if (clips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No viral clips yet',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                '🔥 VIRAL RIGHT NOW',
                style: TextStyle(
                  color: DesignTokens.neonRed,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${clips.length} trending',
                style: TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: clips.length,
            itemBuilder: (context, index) {
              final clip = clips[index];
              return _TrendingClipCard(
                clip: clip,
                rank: index + 1,
                onTap: () => onClipTap(clip),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual trending clip card
class _TrendingClipCard extends StatelessWidget {
  final SocialClip clip;
  final int rank;
  final VoidCallback onTap;

  const _TrendingClipCard({
    required this.clip,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          border: Border.all(
            color: _getRankColor().withOpacity(0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: rank <= 3
              ? [
                  BoxShadow(
                    color: _getRankColor().withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            // ── Thumbnail Placeholder ──
            Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(Icons.play_circle, color: Colors.white30, size: 32),
              ),
            ),

            // ── Rank Badge ──
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _getRankColor(),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getRankColor().withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // ── Info Overlay ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      clip.displayTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.play_arrow, color: Colors.white60, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          clip.formattedViews,
                          style: TextStyle(color: Colors.white60, fontSize: 9),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.favorite,
                          color: DesignTokens.neonRed,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${clip.engagement.likes}',
                          style: TextStyle(
                            color: DesignTokens.neonRed,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Clip Type Badge ──
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  border: Border.all(
                    color: _getRankColor().withOpacity(0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'R${clip.round}',
                  style: TextStyle(
                    color: _getRankColor(),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return DesignTokens.neonCyan;
    }
  }
}
