import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import 'chat_tile.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        title: const Text(
          "MESSAGES",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => context.push('/messaging/search'),
          ),
          IconButton(
            icon: const Icon(
              Icons.add_box_outlined,
              color: DesignTokens.neonCyan,
            ),
            onPressed: () => context.push('/messaging/new-group'),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          ChatTile(
            name: "Coach Stone",
            lastMessage: "Review the tape from round 2.",
            time: "2m ago",
            unreadCount: 1,
            isOnline: true,
            onTap: () => context.push(
              '/messaging/chat/1',
              extra: {'otherName': 'Coach Stone'},
            ),
          ),
          ChatTile(
            name: "Promoter Apex",
            lastMessage: "Contract is ready for signature.",
            time: "1h ago",
            unreadCount: 3,
            isOnline: false,
            onTap: () => context.push(
              '/messaging/chat/2',
              extra: {'otherName': 'Promoter Apex'},
            ),
          ),
          ChatTile(
            name: "Fight Camp Chat (4)",
            lastMessage: "Marcus: I'll be at the gym in 10.",
            time: "Yesterday",
            isOnline: true,
            onTap: () => context.push(
              '/messaging/chat/3',
              extra: {'otherName': 'Fight Camp Chat (4)'},
            ),
          ),
        ],
      ),
    );
  }
}
