import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../shared/models/community/short_video_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/short_video_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// Bottom sheet displaying real-time comments on a reel / short video.
class ReelCommentsSheet extends StatefulWidget {
  final String videoId;

  const ReelCommentsSheet({super.key, required this.videoId});

  @override
  State<ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends State<ReelCommentsSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    setState(() => _sending = true);
    try {
      await context.read<ShortVideoService>().addComment(
        videoId: widget.videoId,
        userId: uid,
        userName: auth.userModel?.displayName ?? 'Anonymous',
        userAvatarUrl: auth.userModel?.photoUrl ?? '',
        text: text,
      );
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return GlassPanel(
          padding: EdgeInsets.zero,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          backgroundColor: DesignTokens.bgSecondary,
          hasBorder: false,
          child: Column(
            children: [
              // Handle + title
              _buildHeader(),
              const Divider(color: Colors.white12, height: 1),

              // Comment list
              Expanded(
                child: StreamBuilder<List<ReelComment>>(
                  stream: context.read<ShortVideoService>().commentsStream(
                    widget.videoId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: DesignTokens.neonCyan,
                          strokeWidth: 2,
                        ),
                      );
                    }

                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          'No comments yet — be the first!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: comments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _CommentTile(
                        comment: comments[index],
                        videoId: widget.videoId,
                      ),
                    );
                  },
                ),
              ),

              const Divider(color: Colors.white12, height: 1),

              // Input bar
              _buildInputBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Comments',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add a comment…',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: DesignTokens.bgCard,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _submit,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: DesignTokens.neonCyan,
                child: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DesignTokens.bgPrimary,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: DesignTokens.bgPrimary,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Single Comment Tile ────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final ReelComment comment;
  final String videoId;

  const _CommentTile({required this.comment, required this.videoId});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser?.uid ?? '';
    final isOwn = comment.userId == uid;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        DfcCircleAvatar(
          imageUrl: comment.userAvatarUrl,
          radius: 16,
          backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.2),
          fallbackText: comment.userName.isNotEmpty
              ? comment.userName[0].toUpperCase()
              : '?',
          fallbackTextStyle: const TextStyle(
            color: DesignTokens.neonCyan,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 10),

        // Body
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _timeAgo(comment.createdAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                comment.text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // Delete (own comments only)
        if (isOwn)
          GestureDetector(
            onTap: () {
              context.read<ShortVideoService>().deleteComment(
                videoId,
                comment.id,
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
      ],
    );
  }
}
