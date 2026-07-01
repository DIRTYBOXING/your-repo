import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/community/short_video_model.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// Compact thumbnail card for displaying a reel in lists, search results,
/// profile grids, and explore sections.
class ShortVideoCard extends StatelessWidget {
  final ShortVideoModel video;
  final VoidCallback? onTap;

  const ShortVideoCard({super.key, required this.video, this.onTap});

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail area
            Expanded(child: _buildThumbnail()),

            // Info footer
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail image or placeholder
        if (video.thumbnailUrl.isNotEmpty)
          DfcNetworkImage(
            url: video.thumbnailUrl,
            errorWidget: _placeholderThumb(),
          )
        else
          _placeholderThumb(),

        // Gradient scrim
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),

        // Play icon
        const Center(
          child: Icon(
            Icons.play_circle_fill_rounded,
            size: 40,
            color: Colors.white70,
          ),
        ),

        // View count badge
        Positioned(
          left: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow, size: 12, color: Colors.white70),
                const SizedBox(width: 2),
                Text(
                  _formatCount(video.viewCount),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ),

        // Duration badge
        Positioned(
          right: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _formatDuration(video.durationSeconds),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            video.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              DfcCircleAvatar(
                imageUrl: video.creatorAvatarUrl,
                radius: 10,
                backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.2),
                fallbackText: video.creatorName.isNotEmpty
                    ? video.creatorName[0].toUpperCase()
                    : '?',
                fallbackTextStyle: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  video.creatorName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.favorite,
                size: 12,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 3),
              Text(
                _formatCount(video.likeCount),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chat_bubble,
                size: 12,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 3),
              Text(
                _formatCount(video.commentCount),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      color: DesignTokens.bgSecondary,
      child: const Center(
        child: Icon(
          Icons.slow_motion_video_rounded,
          size: 32,
          color: Colors.white24,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
