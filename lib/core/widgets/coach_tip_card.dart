import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// AI-generated coaching tip card shown on the Smart Coach dashboard.
class CoachTipCard extends StatelessWidget {
  const CoachTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.12),
            DesignTokens.bgCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.psychology, color: DesignTokens.neonCyan, size: 20),
              SizedBox(width: 8),
              Text(
                'COACH TIP',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Your recovery is trending up. Prioritise one technical drilling '
            'block today and keep intensity at RPE 7 — save the hard sparring '
            'for tomorrow when your readiness peaks.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
