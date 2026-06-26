import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class ScheduleTile extends StatelessWidget {
  final String day;
  final String time;
  final String session;

  const ScheduleTile({
    super.key,
    required this.day,
    required this.time,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DesignTokens.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              day.toUpperCase(),
              style: const TextStyle(
                color: DesignTokens.neonGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              session,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
