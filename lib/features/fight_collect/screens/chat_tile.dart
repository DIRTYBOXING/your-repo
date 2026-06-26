import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class ChatTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final String? avatarUrl;
  final int unreadCount;
  final bool isOnline;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.avatarUrl,
    this.unreadCount = 0,
    this.isOnline = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: DesignTokens.bgCard,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, color: Colors.white54)
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: DesignTokens.neonGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: DesignTokens.bgPrimary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: hasUnread
                              ? DesignTokens.neonCyan
                              : DesignTokens.textMuted,
                          fontSize: 12,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread
                                ? Colors.white
                                : DesignTokens.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: DesignTokens.neonCyan,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
