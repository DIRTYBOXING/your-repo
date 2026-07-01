import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../shared/services/watch_history_service.dart';

/// "Continue Watching" horizontal rail — like Netflix/Paramount+/DAZN.
/// Shows resumable events with progress bars.
class ContinueWatchingRail extends StatelessWidget {
  final VoidCallback? onSeeAll;
  final void Function(WatchEntry entry)? onTap;
  final void Function(WatchEntry entry)? onRemove;

  const ContinueWatchingRail({
    super.key,
    this.onSeeAll,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WatchHistoryService(),
      builder: (context, _) {
        final items = WatchHistoryService().continueWatching;
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Continue Watching',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (onSeeAll != null)
                    GestureDetector(
                      onTap: onSeeAll,
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Horizontal scroll
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildCard(context, items[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, WatchEntry entry) {
    return GestureDetector(
      onTap: () => onTap?.call(entry),
      child: Container(
        width: 220,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF0D1117),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            SizedBox(
              height: 100,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  if (entry.thumbnailUrl != null &&
                      entry.thumbnailUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: entry.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _placeholderImage(),
                    )
                  else
                    _placeholderImage(),

                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(180),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Play button
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Color(0xFF00E5FF),
                      size: 36,
                    ),
                  ),

                  // Remove button
                  if (onRemove != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemove?.call(entry),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(140),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 14,
                          ),
                        ),
                      ),
                    ),

                  // Sport badge
                  if (entry.sportType != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.sportType!,
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Progress bar
            LinearProgressIndicator(
              value: entry.progress,
              backgroundColor: Colors.white.withAlpha(15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00E5FF),
              ),
              minHeight: 3,
            ),

            // Title + time remaining
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _remainingLabel(entry),
                      style: TextStyle(
                        color: Colors.white.withAlpha(130),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFF1A1F2E),
      child: const Center(
        child: Icon(Icons.sports_mma, color: Colors.white24, size: 32),
      ),
    );
  }

  String _remainingLabel(WatchEntry entry) {
    final remaining = entry.duration - entry.position;
    if (remaining.inMinutes < 1) return 'Less than 1 min left';
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m left';
    }
    return '${remaining.inMinutes}m left';
  }
}
