import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/community/community_models.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/social_service.dart';
import '../../../shared/services/share_service.dart';
import '../../../shared/widgets/dfc_post_media.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// POST DETAILS SCREEN — Full post view with comments and engagement
///
/// • Displays full post content with media
/// • Shows engagement metrics (likes, comments, shares)
/// • Real-time comment stream
/// • Action buttons for like, comment, share
/// ═══════════════════════════════════════════════════════════════════════════
class PostDetailsScreen extends StatefulWidget {
  final String postId;

  const PostDetailsScreen({super.key, required this.postId});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  Post? _post;
  bool _isLoading = true;
  bool _sendingComment = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final social = context.read<SocialService>();
      final post = await social.getPost(widget.postId);
      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load post: $e'),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sendingComment || _post == null) return;

    setState(() => _sendingComment = true);
    HapticFeedback.lightImpact();

    final auth = context.read<AuthService>();
    final social = context.read<SocialService>();
    final user = auth.currentUser;
    final userId =
        user?.uid ?? (auth.isDemoUser ? AuthService.demoUserId : 'anon');

    try {
      await social.addComment(
        _post!.id,
        userId,
        text,
        displayName:
            user?.displayName ?? (auth.isDemoUser ? 'Demo User' : 'Anonymous'),
        role: 'fighter',
        avatarUrl: user?.photoURL,
      );
      _commentController.clear();

      // Refresh post to update comment count
      _loadPost();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💬 Comment posted!'),
            backgroundColor: DesignTokens.neonMagenta,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to post comment: $e'),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;
    HapticFeedback.lightImpact();

    final auth = context.read<AuthService>();
    final social = context.read<SocialService>();
    final userId = auth.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please sign in to like posts'),
          backgroundColor: DesignTokens.error,
        ),
      );
      return;
    }

    try {
      await social.toggleLike(_post!.id, userId);
      // Refresh post
      _loadPost();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to like: $e'),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        foregroundColor: DesignTokens.textPrimary,
        elevation: 0,
        title: const Text(
          'Post Details',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            )
          : _post == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: DesignTokens.error,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Post not found',
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post Content
                        _buildPostContent(),
                        const SizedBox(height: 24),
                        // Engagement Stats
                        _buildEngagementStats(),
                        const SizedBox(height: 24),
                        // Action Buttons
                        _buildActionButtons(),
                        const SizedBox(height: 32),
                        // Comments Section
                        _buildCommentsSection(),
                      ],
                    ),
                  ),
                ),
                // Comment Input
                _buildCommentInput(),
              ],
            ),
    );
  }

  Widget _buildPostContent() {
    if (_post == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Info
          Row(
            children: [
              DfcCircleAvatar(
                imageUrl: _post!.userAvatarUrl,
                radius: 24,
                backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.2),
                fallbackIconColor: DesignTokens.neonCyan,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _post!.userDisplayName ?? 'Anonymous',
                          style: const TextStyle(
                            color: DesignTokens.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_post!.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: DesignTokens.neonCyan,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(_post!.createdAt),
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Post Content
          Text(
            _post!.content,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          // Media (if any)
          if (_post!.hasMedia) ...[
            const SizedBox(height: 16),
            DfcPostMedia(
              post: _post!,
              borderRadius: BorderRadius.circular(12),
              maxHeight: 420,
              galleryHeight: 300,
            ),
          ],
          // Location tag
          if (_post!.location != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: DesignTokens.textMuted,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _post!.location!,
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEngagementStats() {
    if (_post == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatChip(
          Icons.favorite,
          '${_post!.likes}',
          'Likes',
          DesignTokens.error,
        ),
        _buildStatChip(
          Icons.comment,
          '${_post!.commentCount}',
          'Comments',
          DesignTokens.neonCyan,
        ),
        _buildStatChip(
          Icons.share,
          '${_post!.shareCount}',
          'Shares',
          DesignTokens.neonMagenta,
        ),
      ],
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String count,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: DesignTokens.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_post == null) return const SizedBox.shrink();

    final auth = context.read<AuthService>();
    final userId = auth.currentUser?.uid;
    final isLiked = userId != null && _post!.likedBy.contains(userId);

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: 'Like',
            color: isLiked ? DesignTokens.error : DesignTokens.textSecondary,
            onTap: _toggleLike,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.comment_outlined,
            label: 'Comment',
            color: DesignTokens.textSecondary,
            onTap: () {
              // Focus comment input
              FocusScope.of(context).requestFocus(FocusNode());
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            color: DesignTokens.textSecondary,
            onTap: () async {
              HapticFeedback.lightImpact();
              final uid = context.read<AuthService>().currentUser?.uid;
              await ShareService.instance.sharePost(
                postId: _post!.id,
                authorDisplayName: _post!.userDisplayName ?? 'Fighter',
                contentPreview: _post!.content,
              );
              if (!mounted) return;
              if (uid != null) {
                try {
                  await SocialService().sharePost(_post!.id, uid);
                } catch (_) {}
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (_post == null) return const SizedBox.shrink();

    final social = context.read<SocialService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments (${_post!.commentCount})',
          style: const TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: social.getComments(_post!.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: DesignTokens.neonCyan),
              );
            }

            final rawComments = snapshot.data ?? [];
            final comments = rawComments
                .map(
                  (commentMap) => Comment(
                    id: commentMap['id'] as String? ?? '',
                    postId: _post!.id,
                    userId: commentMap['userId'] as String? ?? '',
                    content: commentMap['content'] as String? ?? '',
                    createdAt:
                        (commentMap['createdAt'] as dynamic)?.toDate() ??
                        DateTime.now(),
                    userDisplayName: commentMap['userDisplayName'] as String?,
                    userRole: commentMap['userRole'] as String?,
                    userAvatarUrl: commentMap['userAvatarUrl'] as String?,
                    likes: commentMap['likes'] as int? ?? 0,
                    likedBy: List<String>.from(commentMap['likedBy'] ?? []),
                  ),
                )
                .toList();

            if (comments.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: DesignTokens.textMuted,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No comments yet',
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Be the first to comment!',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final comment = comments[index];
                return _buildCommentItem(comment);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DfcCircleAvatar(
            imageUrl: comment.userAvatarUrl,
            radius: 16,
            backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.2),
            fallbackIconColor: DesignTokens.neonCyan,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.displayName,
                      style: const TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(comment.createdAt),
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: DesignTokens.bgCard,
        border: Border(
          top: BorderSide(color: DesignTokens.borderSubtle),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: DesignTokens.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: const TextStyle(color: DesignTokens.textMuted),
                  filled: true,
                  fillColor: DesignTokens.bgPrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendingComment ? null : _sendComment,
              tooltip: 'Send Comment',
              icon: _sendingComment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DesignTokens.neonCyan,
                      ),
                    )
                  : const Icon(Icons.send, color: DesignTokens.neonCyan),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
