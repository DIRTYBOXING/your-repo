import 'package:flutter/material.dart';

/// Health Score Card Widget
/// Displays a composite score (0.0-1.0) with visual progress indicator
/// Used in the health intelligence dashboard for recovery, readiness, etc.
class HealthScoreCard extends StatelessWidget {
  final String title;
  final double score;
  final IconData icon;
  final Color color;
  final bool isInverted;

  const HealthScoreCard({
    super.key,
    required this.title,
    required this.score,
    required this.icon,
    required this.color,
    this.isInverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).toInt();
    final displayScore = isInverted ? 100 - percentage : percentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                '$displayScore%',
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}
