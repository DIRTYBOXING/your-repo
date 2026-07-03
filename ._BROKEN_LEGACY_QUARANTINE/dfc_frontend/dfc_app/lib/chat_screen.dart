import 'package:flutter/material.dart';
lib/
  modules/
    notifications/
      screens/
        notifications_screen.dart
      widgets/
        notification_list_item.dart
      models/
        notification_item_model.dart
      services/
        notification_service.dart
      controllers/
        notification_controller.dart
import '../../../../dfc_theme.dart';
import '../controllers/messaging_controller.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String name;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.name,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final MessagingController _controller;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = MessagingController()..loadMessages(widget.conversationId);
  }

  @override
  void dispose() {
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.name,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoadingMessages) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentCyan,
                    ),
                  );
                }

                return ListView.builder(
                  reverse: false, // In real app, reverse and insert at index 0
                  padding: const EdgeInsets.all(16),
                  itemCount: _controller.activeMessages.length,
                  itemBuilder: (context, index) =>
                      ChatBubble(message: _controller.activeMessages[index]),
                );
              },
            ),
          ),
          ChatInputBar(
            controller: _textController,
            onSend: () {
              _controller.sendMessage(
                widget.conversationId,
                _textController.text,
              );
              _textController.clear();
            },
          ),
        ],
      ),
    );
  }
}
