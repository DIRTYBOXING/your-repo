import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'message_bubble.dart';
import 'chat_input_bar.dart';
import 'typing_indicator.dart';

class ChatThreadScreen extends StatelessWidget {
  final String conversationId;
  final String otherName;
  final String otherPhotoUrl;
  final String otherUserId;

  const ChatThreadScreen({
    super.key,
    required this.conversationId,
    this.otherName = "Chat",
    this.otherPhotoUrl = "",
    this.otherUserId = "",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: DesignTokens.bgCard,
              child: Text(
                otherName.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                otherName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.videocam_outlined,
              color: DesignTokens.neonCyan,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: const [
                MessageBubble(
                  text: "Are you ready for the weigh-ins tomorrow?",
                  isMe: false,
                  time: "10:42 AM",
                ),
                MessageBubble(
                  text: "On weight. Feeling sharp.",
                  isMe: true,
                  time: "10:45 AM",
                ),
                MessageBubble(
                  text: "Perfect. See you at 8am sharp.",
                  isMe: false,
                  time: "10:46 AM",
                ),
                TypingIndicator(),
              ],
            ),
          ),
          const ChatInputBar(),
        ],
      ),
    );
  }
}
