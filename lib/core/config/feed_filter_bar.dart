import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';

class FeedFilterBar extends StatelessWidget {
  final int selected;
  final Function(int) onSelect;

  const FeedFilterBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ["GLOBAL", "FIGHTERS", "EVENTS"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(labels.length, (i) {
        final active = selected == i;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onSelect(i);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: active
                  ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? DesignTokens.neonCyan.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                color: active ? DesignTokens.neonCyan : DesignTokens.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      }),
    );
  }
}
