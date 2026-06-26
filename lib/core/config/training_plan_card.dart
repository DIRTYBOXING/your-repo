import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class TrainingPlanCard extends StatelessWidget {
  const TrainingPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: DesignTokens.neonGold, size: 20),
              SizedBox(width: 8),
              Text(
                'TODAY\'S AI DIRECTIVE',
                style: TextStyle(
                  color: DesignTokens.neonGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _PlanItem(
            time: 'Morning',
            task: 'Active Recovery & Mobility',
            duration: '30 mins',
            isDone: true,
          ),
          _PlanItem(
            time: 'Afternoon',
            task: 'High-Intensity Striking',
            duration: '5 Rounds',
            isDone: false,
          ),
          _PlanItem(
            time: 'Evening',
            task: 'CNS Down-Regulation',
            duration: '15 mins',
            isDone: false,
          ),
        ],
      ),
    );
  }
}

class _PlanItem extends StatelessWidget {
  final String time;
  final String task;
  final String duration;
  final bool isDone;

  const _PlanItem({
    required this.time,
    required this.task,
    required this.duration,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.circle_outlined,
            color: isDone ? DesignTokens.neonGreen : DesignTokens.textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task,
                  style: TextStyle(
                    color: isDone ? DesignTokens.textMuted : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$time • $duration',
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
