import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Recommendation Card Widget
/// Displays actionable recommendations from the health intelligence engine
class RecommendationCard extends StatelessWidget {
  final String recommendation;

  const RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final category = _categorize(recommendation);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: category.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category.icon, color: category.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _RecommendationCategory _categorize(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('hydrat') ||
        lower.contains('water') ||
        lower.contains('fluid')) {
      return _RecommendationCategory(
        icon: Icons.water_drop,
        color: Colors.blue,
      );
    }
    if (lower.contains('sleep') ||
        lower.contains('rest') ||
        lower.contains('recover')) {
      return _RecommendationCategory(icon: Icons.bedtime, color: Colors.purple);
    }
    if (lower.contains('train') ||
        lower.contains('workout') ||
        lower.contains('exercise')) {
      return _RecommendationCategory(
        icon: Icons.fitness_center,
        color: AppTheme.neonCyan,
      );
    }
    if (lower.contains('nutrition') ||
        lower.contains('eat') ||
        lower.contains('fuel')) {
      return _RecommendationCategory(
        icon: Icons.restaurant,
        color: Colors.orange,
      );
    }
    if (lower.contains('stress') ||
        lower.contains('mental') ||
        lower.contains('focus')) {
      return _RecommendationCategory(
        icon: Icons.psychology,
        color: Colors.teal,
      );
    }
    if (lower.contains('professional') ||
        lower.contains('doctor') ||
        lower.contains('consult')) {
      return _RecommendationCategory(
        icon: Icons.medical_services,
        color: Colors.red,
      );
    }

    return _RecommendationCategory(
      icon: Icons.lightbulb_outline,
      color: Colors.amber,
    );
  }
}

class _RecommendationCategory {
  final IconData icon;
  final Color color;

  _RecommendationCategory({required this.icon, required this.color});
}
