import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Today's training plan summary card shown on the Smart Coach dashboard.
class TrainingPlanCard extends StatelessWidget {
  const TrainingPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.fitness_center,
                color: DesignTokens.neonGreen,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "TODAY'S PLAN",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _planItem('Technical drilling', '35 min', DesignTokens.neonCyan),
          _planItem('Conditioning intervals', '18 min', DesignTokens.neonGold),
          _planItem('Mobility + breathing', '10 min', DesignTokens.neonGreen),
        ],
      ),
    );
  }

  Widget _planItem(String title, String duration, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Text(
            duration,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
