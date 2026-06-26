import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/social_service.dart';
import '../../../shared/models/community/community_models.dart';
import '../widgets/dfc_post_card.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HASHTAG FEED SCREEN — Filtered feed for a single #hashtag
///
/// • Queries posts containing the hashtag
/// • Same card rendering as main feed
/// • Pull-to-refresh + infinite scroll
/// • Neon pill showing hashtag + post count
/// ═══════════════════════════════════════════════════════════════════════════
class HashtagFeedScreen extends StatefulWidget {
  final String hashtag;

  const HashtagFeedScreen({super.key, required this.hashtag});

  @override
  State<HashtagFeedScreen> createState() => _HashtagFeedScreenState();
}

class _HashtagFeedScreenState extends State<HashtagFeedScreen> {
  late final SocialService _socialService;
  final List<Post> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _socialService = context.read<SocialService>();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final posts = await _socialService.getHashtagPosts(widget.hashtag);
      if (mounted) {
        setState(() {
          _posts
            ..clear()
            ..addAll(posts);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignTokens.neonCyan.withValues(alpha: 0.2),
                    DesignTokens.neonCyan.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                border: Border.all(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tag, color: DesignTokens.neonCyan, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.hashtag,
                    style: const TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            )
          : _posts.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: DesignTokens.neonCyan,
              backgroundColor: DesignTokens.bgCard,
              onRefresh: _loadPosts,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: _posts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildHeader();
                  final post = _posts[index - 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: DFCPostCard(
                      post: post,
                      onTap: HapticFeedback.lightImpact,
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.neonCyan.withValues(alpha: 0.3),
                  DesignTokens.neonCyan.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tag,
              color: DesignTokens.neonCyan,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${widget.hashtag}',
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_posts.length} post${_posts.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tag,
            size: 64,
            color: DesignTokens.neonCyan.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No posts with #${widget.hashtag}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to post with this hashtag!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
