import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';

/// Social Queue Screen — Buffer-style social media queue.
/// 4 tabs: Pending, Queued, Sent, Failed.
/// Reads from `social_engine_posts` collection.
class SocialQueueScreen extends StatefulWidget {
  const SocialQueueScreen({super.key});

  @override
  State<SocialQueueScreen> createState() => _SocialQueueScreenState();
}

class _SocialQueueScreenState extends State<SocialQueueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _platformFilter;

  final _platforms = [
    'All',
    'instagram',
    'facebook',
    'twitter',
    'tiktok',
    'youtube',
    'linkedin',
    'threads',
    'bluesky',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('SOCIAL QUEUE'),
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: AppTheme.neonMagenta,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonMagenta,
          labelColor: AppTheme.neonMagenta,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'PENDING'),
            Tab(text: 'QUEUED'),
            Tab(text: 'SENT'),
            Tab(text: 'FAILED'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Platform filter
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _platforms.length,
              itemBuilder: (context, i) {
                final p = _platforms[i];
                final isActive =
                    (_platformFilter == null && p == 'All') ||
                    _platformFilter == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      p.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isActive
                            ? AppTheme.primaryBackground
                            : AppTheme.textMuted,
                      ),
                    ),
                    selected: isActive,
                    selectedColor: AppTheme.neonMagenta,
                    backgroundColor: AppTheme.cardBackground,
                    onSelected: (_) {
                      setState(() {
                        _platformFilter = p == 'All' ? null : p;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostList('pending'),
                _buildPostList('queued'),
                _buildPostList('sent'),
                _buildPostList('failed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList(String status) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('social_engine_posts')
        .where('deliveryStatus', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .limit(50);

    if (_platformFilter != null) {
      query = query.where('platform', isEqualTo: _platformFilter);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.neonMagenta),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox, color: AppTheme.textMuted, size: 48),
                const SizedBox(height: 8),
                Text(
                  'No ${status.toUpperCase()} posts',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final docId = docs[index].id;
            return _buildPostCard(data, docId, status);
          },
        );
      },
    );
  }

  Widget _buildPostCard(
    Map<String, dynamic> data,
    String docId,
    String status,
  ) {
    final platform = data['platform'] ?? 'unknown';
    final title = data['title'] ?? data['content']?.toString() ?? 'Untitled';
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final color = _platformColor(platform);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_platformIcon(platform), color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                platform.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${createdAt.day}/${createdAt.month} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title.toString().length > 120
                ? '${title.toString().substring(0, 120)}...'
                : title.toString(),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _updateStatus(docId, 'queued'),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.neonGreen,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _updateStatus(docId, 'failed'),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                ),
              ],
            ),
          ],
          if (status == 'failed') ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => _updateStatus(docId, 'queued'),
              icon: const Icon(Icons.replay, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.neonOrange),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('social_engine_posts')
          .doc(docId)
          .update({
            'deliveryStatus': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post moved to ${newStatus.toUpperCase()}'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Color _platformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return AppTheme.neonMagenta;
      case 'facebook':
        return const Color(0xFF4267B2);
      case 'twitter':
        return AppTheme.neonCyan;
      case 'tiktok':
        return AppTheme.neonGreen;
      case 'youtube':
        return AppTheme.error;
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'threads':
        return AppTheme.textPrimary;
      case 'bluesky':
        return const Color(0xFF00A3FF);
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.tag;
      case 'tiktok':
        return Icons.music_note;
      case 'youtube':
        return Icons.play_circle;
      case 'linkedin':
        return Icons.business;
      case 'threads':
        return Icons.forum;
      case 'bluesky':
        return Icons.cloud;
      default:
        return Icons.share;
    }
  }
}
