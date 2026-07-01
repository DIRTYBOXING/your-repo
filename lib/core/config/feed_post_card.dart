import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/feed_post.dart';
import '../../features/feed/widgets/safety_flag.dart';
import '../../features/feed/widgets/reaction_bar.dart';
import '../../features/feed/widgets/comments_drawer.dart';

class FeedPostCard extends StatelessWidget {
  final FeedPost post;
  const FeedPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(post.authorRole);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roleColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: roleColor.withValues(alpha: 0.2),
                  radius: 20,
                  child: Text(
                    post.authorName[0].toUpperCase(),
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              post.authorRole.toUpperCase(),
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(post.createdAt),
                            style: const TextStyle(
                              color: DesignTokens.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: DesignTokens.textMuted),
              ],
            ),
            const SizedBox(height: 14),
            SafetyFlag(safe: post.passedSafety),
            Text(
              post.content,
              style: const TextStyle(
                color: DesignTokens.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (post.isEventLinked) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DesignTokens.neonAmber.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event,
                      color: DesignTokens.neonAmber,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Linked to Event: ${post.eventId}',
                      style: const TextStyle(
                        color: DesignTokens.neonAmber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const ReactionBar(),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const CommentsDrawer(
                  comments: [
                    {
                      "author": "FightFan99",
                      "text": "Absolutely insane performance. Pure heart!",
                    },
                    {
                      "author": "CoachMike",
                      "text":
                          "Looked sharp out there, but keep those hands up next time.",
                    },
                  ],
                ),
              ),
              child: const Text(
                "View all comments",
                style: TextStyle(color: DesignTokens.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'fighter':
        return DesignTokens.neonMagenta;
      case 'coach':
        return DesignTokens.neonGreen;
      case 'org':
      case 'promoter':
        return DesignTokens.neonCyan;
      default:
        return Colors.white54;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
