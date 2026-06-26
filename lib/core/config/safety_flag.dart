import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class SafetyFlag extends StatelessWidget {
  final bool safe;

  const SafetyFlag({super.key, required this.safe});

  @override
  Widget build(BuildContext context) {
    if (safe) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignTokens.neonRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DesignTokens.neonRed.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: DesignTokens.neonRed, size: 14),
          SizedBox(width: 8),
          Text(
            "Content under review",
            style: TextStyle(
              color: DesignTokens.neonRed,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
