import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// Message composer bar shown at the bottom of a chat thread.
class ChatInputBar extends StatefulWidget {
  final ValueChanged<String>? onSend;

  const ChatInputBar({super.key, this.onSend});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend?.call(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: DesignTokens.textMuted),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  hintText: 'Message…',
                  hintStyle: const TextStyle(color: DesignTokens.textMuted),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: DesignTokens.neonCyan,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
