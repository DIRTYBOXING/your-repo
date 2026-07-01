import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../shared/models/media_library_item.dart';

/// DFC Media Library Screen — displays all ingested media with filters.
class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  String _filter = 'All';
  static const _filters = ['All', 'video', 'image', 'reel', 'post'];

  Stream<List<MediaLibraryItem>> _mediaStream() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('media_library')
        .orderBy('postedAt', descending: true)
        .limit(50);
    if (_filter != 'All') {
      q = q.where('type', isEqualTo: _filter);
    }
    return q.snapshots().map(
      (snap) => snap.docs
          .map((d) {
            try {
              return MediaLibraryItem.fromMap(d.data());
            } catch (_) {
              return null;
            }
          })
          .whereType<MediaLibraryItem>()
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        title: const Text(
          'DFC Media Library',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: DesignTokens.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final selected = f == _filter;
                return ChoiceChip(
                  label: Text(f[0].toUpperCase() + f.substring(1)),
                  selected: selected,
                  selectedColor: DesignTokens.neonCyan.withValues(alpha: 0.2),
                  backgroundColor: DesignTokens.bgCard,
                  labelStyle: TextStyle(
                    color: selected
                        ? DesignTokens.neonCyan
                        : DesignTokens.textSecondary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selected
                        ? DesignTokens.neonCyan
                        : DesignTokens.textDisabled,
                  ),
                  onSelected: (_) => setState(() => _filter = f),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Media grid
          Expanded(
            child: StreamBuilder<List<MediaLibraryItem>>(
              stream: _mediaStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: DesignTokens.neonCyan,
                    ),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return _buildEmptyState();
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _MediaCard(item: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            color: DesignTokens.textDisabled,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No media yet',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Media from fight events, promos, and social channels will appear here once ingested.',
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final MediaLibraryItem item;
  const _MediaCard({required this.item});

  Color get _platformColor {
    switch (item.platform.toLowerCase()) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'tiktok':
        return DesignTokens.neonCyan;
      default:
        return DesignTokens.textSecondary;
    }
  }

  IconData get _typeIcon {
    switch (item.type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_fill;
      case 'reel':
        return Icons.slow_motion_video;
      case 'image':
        return Icons.image;
      default:
        return Icons.article;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _platformColor.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                item.thumbnailUrl.isNotEmpty
                    ? DfcNetworkImage(url: item.thumbnailUrl)
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _platformColor.withValues(alpha: 0.2),
                              DesignTokens.bgCard,
                            ],
                          ),
                        ),
                      ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_typeIcon, color: _platformColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          item.platform,
                          style: TextStyle(
                            color: _platformColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.thumb_up,
                      color: DesignTokens.textMuted,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.engagement}',
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    if (item.tags.isNotEmpty)
                      Text(
                        '#${item.tags.first}',
                        style: TextStyle(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
