import 'package:flutter/material.dart';
import '../../../../dfc_theme.dart';
import '../models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isMe
              ? AppColors.accentCyan.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isMe
                ? const Radius.circular(0)
                : const Radius.circular(16),
            bottomLeft: !message.isMe
                ? const Radius.circular(0)
                : const Radius.circular(16),
          ),
          border: Border.all(
            color: message.isMe
                ? AppColors.accentCyan.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: message.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.timestamp,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
