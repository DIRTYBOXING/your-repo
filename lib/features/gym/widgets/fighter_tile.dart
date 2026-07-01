import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class FighterTile extends StatelessWidget {
  final String name;
  final String record;

  const FighterTile({super.key, required this.name, required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.2),
          radius: 24,
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          record,
          style: const TextStyle(
            color: DesignTokens.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: () {},
      ),
    );
  }
}
