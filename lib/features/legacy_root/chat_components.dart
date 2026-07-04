import 'package:flutter/material.dart';
import 'message_model.dart';

class ChatBubble extends StatelessWidget {
  final Message msg;
  final bool isMe;

  const ChatBubble({super.key, required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.pinkAccent : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          msg.text,
          style: TextStyle(color: isMe ? Colors.white : Colors.white70),
        ),
      ),
    );
  }
}
