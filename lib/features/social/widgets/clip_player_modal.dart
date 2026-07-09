import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/social_clip_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CLIP PLAYER MODAL — Clip Preview/Playback
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Full-screen or bottom-sheet clip player showing:
///   - Video player placeholder
///   - Clip metadata
///   - Fighter info
///   - Engagement metrics
///   - Share/like buttons
///   - "Watch Full Fight" button (PPV)
///
/// ═══════════════════════════════════════════════════════════════════════════

class ClipPlayerModal extends StatefulWidget {
  final SocialClip clip;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onWatchFullFight;
  final VoidCallback onClose;

  const ClipPlayerModal({
    super.key,
    required this.clip,
    required this.onLike,
    required this.onShare,
    required this.onWatchFullFight,
    required this.onClose,
  });

  @override
  State<ClipPlayerModal> createState() => _ClipPlayerModalState();
}

class _ClipPlayerModalState extends State<ClipPlayerModal> {
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _isLiked = false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DesignTokens.bgPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Video Player ──
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Stack(
              children: [
                // ── Player Placeholder ──
                Center(
                  child: Icon(
                    Icons.play_circle,
                    color: Colors.white30,
                    size: 64,
                  ),
                ),

                // ── Close Button ──
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 1),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Clip Duration ──
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${widget.clip.durationSeconds}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // ── Trending Badge ──
                if (widget.clip.isTrending)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonAmber.withOpacity(0.3),
                        border: Border.all(
                          color: DesignTokens.neonAmber,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.neonAmber.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        '🔥 TRENDING',
                        style: TextStyle(
                          color: DesignTokens.neonAmber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Clip Info ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title & Type ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.clip.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getClipTypeColor().withOpacity(0.2),
                        border: Border.all(
                          color: _getClipTypeColor().withOpacity(0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'R${widget.clip.round}',
                        style: TextStyle(
                          color: _getClipTypeColor(),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Fighter Info ──
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white05,
                    border: Border.all(color: Colors.white10, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.clip.fighter1Name,
                              style: TextStyle(
                                color: DesignTokens.neonGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'vs',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.clip.fighter2Name,
                              style: TextStyle(
                                color: DesignTokens.neonAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Engagement Metrics ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildEngagementStat(
                      icon: Icons.play_arrow,
                      label: 'Views',
                      value: widget.clip.formattedViews,
                    ),
                    _buildEngagementStat(
                      icon: Icons.favorite,
                      label: 'Likes',
                      value: '${widget.clip.engagement.likes}',
                      color: DesignTokens.neonRed,
                    ),
                    _buildEngagementStat(
                      icon: Icons.share,
                      label: 'Shares',
                      value: '${widget.clip.engagement.shares}',
                      color: DesignTokens.neonGreen,
                    ),
                    _buildEngagementStat(
                      icon: Icons.message,
                      label: 'Comments',
                      value: '${widget.clip.engagement.comments}',
                      color: DesignTokens.neonCyan,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Action Buttons ──
                Row(
                  children: [
                    // Like Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _isLiked = !_isLiked);
                          widget.onLike();
                        },
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                        ),
                        label: const Text('LIKE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLiked
                              ? DesignTokens.neonRed.withOpacity(0.3)
                              : Colors.white10,
                          foregroundColor: _isLiked
                              ? DesignTokens.neonRed
                              : Colors.white60,
                          side: BorderSide(
                            color: _isLiked
                                ? DesignTokens.neonRed.withOpacity(0.5)
                                : Colors.white20,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Share Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onShare,
                        icon: const Icon(Icons.share),
                        label: const Text('SHARE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white60,
                          side: BorderSide(color: Colors.white20, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Watch Full Fight Button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onWatchFullFight,
                    icon: const Icon(Icons.play_circle),
                    label: const Text('WATCH FULL FIGHT ON PPV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.neonGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // ── Description ──
                if (widget.clip.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      widget.clip.description!,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        height: 1.4,
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

  Widget _buildEngagementStat({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    color ??= Colors.white60;
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white30, fontSize: 8)),
      ],
    );
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
