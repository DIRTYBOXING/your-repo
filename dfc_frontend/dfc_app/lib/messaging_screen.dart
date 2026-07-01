import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../dfc_theme.dart';
import '../controllers/messaging_controller.dart';
import '../widgets/conversation_list_item.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  late final MessagingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MessagingController()..loadConversations();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SECURE MESSAGING', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.5)),
              ),
              child: const Text('NEW CHAT', style: TextStyle(color: AppColors.accentBlue, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const TextField(
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: AppColors.textMuted),
                  hintText: 'Search athletes, coaches...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          // CONVERSATIONS
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoadingConversations) return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  itemCount: _controller.conversations.length,
                  itemBuilder: (context, index) {
                    final c = _controller.conversations[index];
                    return ConversationListItem(conversation: c, onTap: () => context.push('/chat/${c.id}?name=${c.name}'));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}