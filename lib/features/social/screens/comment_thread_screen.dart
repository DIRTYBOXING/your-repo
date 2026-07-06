import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/community/community_models.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/social_service.dart';
import '../../../shared/widgets/dfc_profile_identity.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// COMMENT THREAD SCREEN — Bottom-sheet threaded comment view
///
/// • Streams comments in real time via SocialService.getComments()
/// • Shows avatar, name, role badge, relative time
/// • Compose bar with send button + haptics
/// ═══════════════════════════════════════════════════════════════════════════
class CommentThreadScreen extends StatefulWidget {
  final Post post;

  const CommentThreadScreen({super.key, required this.post});

  @override
  State<CommentThreadScreen> createState() => _CommentThreadScreenState();
}

class _CommentThreadScreenState extends State<CommentThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  /// Reply state — when non-null the compose bar targets a parent comment
  String? _replyToCommentId;
  String? _replyToName;

  /// Track which root comments have their replies expanded
  final Set<String> _expandedReplies = {};

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startReply(Comment parent) {
    setState(() {
      _replyToCommentId = parent.id;
      _replyToName = parent.displayName;
    });
    _controller.clear();
    // Focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToName = null;
    });
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    HapticFeedback.lightImpact();

    final auth = context.read<AuthService>();
    final social = context.read<SocialService>();
    final user = auth.currentUser;
    final userId = user?.uid ?? 'anon';

    try {
      await social.addComment(
        widget.post.id,
        userId,
        text,
        displayName: user?.displayName ?? 'Anonymous',
        role: 'fighter',
        avatarUrl: user?.photoURL,
        parentCommentId: _replyToCommentId,
        replyToName: _replyToName,
      );
      _controller.clear();
      _cancelReply();
      // Scroll to bottom after a short delay so new comment renders
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final social = context.read<SocialService>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: DesignTokens.bgPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Handle + header ──
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Comments',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),

            // ── Comments stream ──
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: social.getComments(widget.post.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.neonCyan,
                      ),
                    );
                  }
                  final rawComments = snapshot.data ?? [];
                  final comments = rawComments
                      .map(
                        (m) => Comment(
                          id: m['id'] as String? ?? '',
                          postId: widget.post.id,
                          userId: m['userId'] as String? ?? '',
                          content: m['content'] as String? ?? '',
                          createdAt:
                              (m['createdAt'] as dynamic)?.toDate() ??
                              DateTime.now(),
                          userDisplayName: m['userDisplayName'] as String?,
                          userRole: m['userRole'] as String?,
                          userAvatarUrl: m['userAvatarUrl'] as String?,
                          likes: m['likes'] as int? ?? 0,
                          likedBy: List<String>.from(m['likedBy'] ?? []),
                          parentCommentId: m['parentCommentId'] as String?,
                          replyToName: m['replyToName'] as String?,
                          replyCount: m['replyCount'] as int? ?? 0,
                        ),
                      )
                      .toList();

                  // Separate root comments from replies
                  final roots = comments.where((c) => !c.isReply).toList();
                  final repliesByParent = <String, List<Comment>>{};
                  for (final c in comments.where((c) => c.isReply)) {
                    repliesByParent
                        .putIfAbsent(c.parentCommentId!, () => [])
                        .add(c);
                  }
                  if (roots.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 40,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No comments yet',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be first to comment',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.15),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    itemCount: roots.length,
                    itemBuilder: (_, i) {
                      final root = roots[i];
                      final replies = repliesByParent[root.id] ?? [];
                      final isExpanded = _expandedReplies.contains(root.id);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CommentTile(
                            comment: root,
                            onReply: () => _startReply(root),
                          ),
                          // "View N replies" toggle
                          if (replies.isNotEmpty && !isExpanded)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _expandedReplies.add(root.id)),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 40,
                                  bottom: 4,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 1,
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'View ${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                                      style: TextStyle(
                                        color: DesignTokens.neonCyan.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Expanded replies — indented
                          if (isExpanded)
                            ...replies.map(
                              (reply) => Padding(
                                padding: const EdgeInsets.only(left: 40),
                                child: _CommentTile(
                                  comment: reply,
                                  onReply: () => _startReply(root),
                                  isReply: true,
                                ),
                              ),
                            ),
                          if (isExpanded && replies.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(
                                () => _expandedReplies.remove(root.id),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 40,
                                  bottom: 4,
                                ),
                                child: Text(
                                  'Hide replies',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // ── Reply indicator banner ──
            if (_replyToCommentId != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 14,
                      color: DesignTokens.neonCyan.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Replying to $_replyToName',
                        style: TextStyle(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: _cancelReply,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Compose bar ──
            Container(
              padding: EdgeInsets.fromLTRB(12, 8, 8, 12 + bottomInset),
              decoration: BoxDecoration(
                color: DesignTokens.bgCard,
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) {
                      final photoUrl = ctx
                          .read<AuthService>()
                          .userModel
                          ?.photoUrl;
                      return DfcProfileIdentityAvatar(
                        imageUrl: photoUrl,
                        displayName:
                            ctx.read<AuthService>().currentUser?.displayName ??
                            'Anonymous',
                        radius: 16,
                        backgroundColor: DesignTokens.neonCyan.withValues(
                          alpha: 0.12,
                        ),
                        ringPadding: 1,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: DesignTokens.neonCyan,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedOpacity(
                    opacity: _controller.text.trim().isNotEmpty ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 150),
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DesignTokens.neonCyan,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: DesignTokens.neonCyan,
                              size: 22,
                            ),
                      onPressed: _controller.text.trim().isNotEmpty
                          ? _sendComment
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Single comment tile ───────────────────────────────────────────────────
class _CommentTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onReply;
  final bool isReply;

  const _CommentTile({
    required this.comment,
    this.onReply,
    this.isReply = false,
  });

  Color get _roleColor {
    switch (comment.userRole) {
      case 'fighter':
        return DesignTokens.neonCyan;
      case 'coach':
        return DesignTokens.neonGreen;
      case 'promoter':
        return DesignTokens.neonMagenta;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = comment.displayName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DfcProfileIdentityAvatar(
            imageUrl: comment.userAvatarUrl,
            displayName: name,
            radius: 15,
            accentColor: _roleColor,
            ringPadding: 1.5,
            gradientColors: [_roleColor, _roleColor.withValues(alpha: 0.3)],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + role + time
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (comment.userRole != null &&
                        comment.userRole!.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _roleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusPill,
                          ),
                        ),
                        child: Text(
                          comment.userRole!,
                          style: TextStyle(
                            color: _roleColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Reply-to indicator for nested replies
                if (comment.isReply && comment.replyToName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '@${comment.replyToName}',
                      style: TextStyle(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                // Content
                Text(
                  comment.content,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                // Like / Reply row
                Row(
                  children: [
                    Text(
                      '${comment.likes} likes',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: onReply,
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: onReply != null
                              ? DesignTokens.neonCyan.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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
