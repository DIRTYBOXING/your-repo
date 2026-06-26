import 'package:flutter/material.dart';
import '../../analytics/widgets/ai_matchmaking_panel.dart';
import '../../../shared/models/fighter_model.dart';

/// Dashboard widget to show AI matchmaking for the current user
class AiDashboardMatchmakingPanel extends StatelessWidget {
  final FighterModel currentFighter;
  final List<FighterModel> allFighters;

  const AiDashboardMatchmakingPanel({
    super.key,
    required this.currentFighter,
    required this.allFighters,
  });

  @override
  Widget build(BuildContext context) {
    // Exclude self from candidates
    final candidates = allFighters
        .where((f) => f.id != currentFighter.id)
        .toList();
    return AiMatchmakingPanel(fighter: currentFighter, candidates: candidates);
  }
}
