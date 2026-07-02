import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/glass_panel.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: DesignTokens.bgPrimary,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.add_photo_alternate_outlined,
              color: DesignTokens.textMuted,
            ),
            onPressed: () {},
          ),
          Expanded(
            child: GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(24),
              backgroundColor: DesignTokens.bgCard,
              borderColor: DesignTokens.neonCyan.withValues(alpha: 0.15),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Message...",
                  hintStyle: TextStyle(color: DesignTokens.textMuted),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.mic_none_outlined,
              color: DesignTokens.neonCyan,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
