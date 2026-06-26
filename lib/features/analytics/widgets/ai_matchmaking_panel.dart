import 'package:flutter/material.dart';
import '../../../shared/models/fighter_model.dart';
import '../services/matchmaking_service.dart';

/// Widget to display AI-driven matchup suggestions and fight predictions
class AiMatchmakingPanel extends StatelessWidget {
  final FighterModel fighter;
  final List<FighterModel> candidates;

  const AiMatchmakingPanel({
    super.key,
    required this.fighter,
    required this.candidates,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = MatchmakingService.suggestMatchups(
      fighter: fighter,
      candidates: candidates,
    );
    return Card(
      color: Colors.black87,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Matchup Suggestions',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...suggestions.map(
              (FighterModel opponent) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${opponent.fullName} (${opponent.weightClass ?? "Unknown"})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    MatchmakingService.generateFightPrediction(
                      fighter,
                      opponent,
                    ),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const Divider(color: Colors.white24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
