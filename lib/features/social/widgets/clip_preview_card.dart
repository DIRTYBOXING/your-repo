import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/social_clip_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CLIP PREVIEW CARD — Individual Clip Card for Social Feed
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Full-width or grid clip card displaying:
///   - Clip thumbnail/placeholder
///   - Clip title
///   - Fighter names
///   - Round & duration
///   - Engagement metrics (views, likes, shares)
///   - Engagement buttons (like, share, comment, watch)
///   - Tap to preview
///
/// ═══════════════════════════════════════════════════════════════════════════

class ClipPreviewCard extends StatefulWidget {
  final SocialClip clip;
  final VoidCallback onTap;
  final void Function() onLike;
  final void Function() onShare;
  final void Function() onComment;
  final void Function() onWatch;

  const ClipPreviewCard({
    super.key,
    required this.clip,
    required this.onTap,
    required this.onLike,
    required this.onShare,
    required this.onComment,
    required this.onWatch,
  });

  @override
  State<ClipPreviewCard> createState() => _ClipPreviewCardState();
}

class _ClipPreviewCardState extends State<ClipPreviewCard> {
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _isLiked = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        border: Border.all(color: Colors.white12, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Clip Thumbnail ──
          GestureDetector(
            onTap: widget.onTap,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Stack(
                children: [
                  // ── Thumbnail Placeholder ──
                  Center(
                    child: Icon(
                      Icons.play_circle,
                      color: Colors.white30,
                      size: 48,
                    ),
                  ),

                  // ── Clip Type Badge ──
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        border: Border.all(
                          color: _getClipTypeColor().withOpacity(0.7),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${widget.clip.clipType.emoji} ${widget.clip.clipType.label}',
                        style: TextStyle(
                          color: _getClipTypeColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // ── View Count ──
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_arrow,
                            color: Colors.white60,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.clip.formattedViews,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Duration ──
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${widget.clip.durationSeconds}s',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Clip Info ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ──
                Text(
                  widget.clip.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // ── Fighter Info ──
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.clip.fighter1Name} vs ${widget.clip.fighter2Name}',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white05,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'R${widget.clip.round}',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Engagement Metrics ──
                Row(
                  children: [
                    _buildMetric(
                      icon: Icons.play_arrow,
                      count: widget.clip.engagement.views,
                    ),
                    const SizedBox(width: 12),
                    _buildMetric(
                      icon: Icons.favorite,
                      count: widget.clip.engagement.likes,
                      color: DesignTokens.neonRed,
                    ),
                    const SizedBox(width: 12),
                    _buildMetric(
                      icon: Icons.share,
                      count: widget.clip.engagement.shares,
                      color: DesignTokens.neonGreen,
                    ),
                    const Spacer(),
                    if (widget.clip.isTrending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonAmber.withOpacity(0.2),
                          border: Border.all(
                            color: DesignTokens.neonAmber.withOpacity(0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '🔥 TRENDING',
                          style: TextStyle(
                            color: DesignTokens.neonAmber,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Action Buttons ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10, width: 1)),
            ),
            child: Row(
              children: [
                // Like Button
                _buildActionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: 'Like',
                  color: _isLiked ? DesignTokens.neonRed : Colors.white60,
                  onTap: () {
                    setState(() => _isLiked = !_isLiked);
                    widget.onLike();
                  },
                ),

                // Share Button
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: widget.onShare,
                ),

                // Comment Button
                _buildActionButton(
                  icon: Icons.message,
                  label: 'Comment',
                  onTap: widget.onComment,
                ),

                const Spacer(),

                // Watch Button
                ElevatedButton.icon(
                  onPressed: widget.onWatch,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('WATCH'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonGreen.withOpacity(0.2),
                    foregroundColor: DesignTokens.neonGreen,
                    side: BorderSide(
                      color: DesignTokens.neonGreen.withOpacity(0.5),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
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

  Widget _buildMetric({
    required IconData icon,
    required int count,
    Color? color,
  }) {
    color ??= Colors.white60;
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          _formatCount(count),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    color ??= Colors.white60;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Color _getClipTypeColor() {
    switch (widget.clip.clipType) {
      case ClipType.knockdown:
        return DesignTokens.neonRed;
      case ClipType.submission:
        return DesignTokens.neonGreen;
      case ClipType.roundEnd:
        return DesignTokens.neonAmber;
      case ClipType.highlight:
        return DesignTokens.neonCyan;
      case ClipType.comeback:
        return DesignTokens.neonRed;
      case ClipType.statsReel:
        return DesignTokens.neonCyan;
    }
  }
}
