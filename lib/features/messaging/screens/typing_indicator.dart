import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/glass_panel.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: BorderRadius.circular(16),
        backgroundColor: DesignTokens.bgCard,
        borderColor: Colors.white10,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * 0.2;
                final value = (_controller.value - delay) % 1.0;
                final opacity = value < 0.5
                    ? value * 2
                    : 1.0 - ((value - 0.5) * 2);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Opacity(
                    opacity: opacity.clamp(0.2, 1.0),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: DesignTokens.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
      ),
    );
  }
}
