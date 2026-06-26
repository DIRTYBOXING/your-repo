import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AISuggestionsPanel extends StatelessWidget {
  final List<String> suggestions;
  const AISuggestionsPanel({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Card(
      color: AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: AppTheme.neonCyan, size: 20),
                SizedBox(width: 8),
                Text(
                  'AI Suggestions',
                  style: TextStyle(
                    color: AppTheme.neonCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(color: AppTheme.neonCyan),
                    ),
                    Expanded(
                      child: Text(
                        s,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
