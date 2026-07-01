import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../../shared/models/fighter_model.dart';

/// AI-driven matchmaking and analytics service — local scoring + Gemini Cloud Functions
class MatchmakingService {
  static final _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  /// Fast local matchup ranking (used for immediate UI rendering).
  static List<FighterModel> suggestMatchups({
    required FighterModel fighter,
    required List<FighterModel> candidates,
  }) {
    final scored = List<FighterModel>.from(candidates);
    scored.sort((a, b) {
      final sameWeightA = a.weightClass == fighter.weightClass ? 0 : 1;
      final sameWeightB = b.weightClass == fighter.weightClass ? 0 : 1;
      final styleScoreA = a.sportType == fighter.sportType ? 0 : 1;
      final styleScoreB = b.sportType == fighter.sportType ? 0 : 1;
      return (sameWeightA + styleScoreA).compareTo(sameWeightB + styleScoreB);
    });
    return scored.take(3).toList();
  }

  /// Generates a local fight prediction (instant, no network).
  static String generateFightPrediction(FighterModel a, FighterModel b) {
    if (a.wins > b.wins && a.knockouts > b.knockouts) {
      return "${a.fullName} is favored due to superior record and finishing ability.";
    } else if (b.wins > a.wins && b.knockouts > a.knockouts) {
      return "${b.fullName} is favored due to superior record and finishing ability.";
    } else {
      return "This is a close matchup. Expect a competitive fight!";
    }
  }

  /// Calls the Gemini-powered suggestMatchup Cloud Function for AI-ranked suggestions.
  static Future<List<Map<String, dynamic>>> suggestMatchupsAI({
    required FighterModel fighter,
    required List<FighterModel> candidates,
    String? discipline,
  }) async {
    try {
      final callable = _functions.httpsCallable('suggestMatchup');
      final result = await callable.call<Map<String, dynamic>>({
        'fighterList': candidates.map((f) => f.fullName).join(', '),
        'recentResults':
            '${fighter.fullName}: ${fighter.wins}W-${fighter.losses}L',
        'weightClass': fighter.weightClass ?? '',
        'discipline': ?discipline,
      });
      final data = result.data;
      final matchups = data['matchups'];
      if (matchups is List) {
        return matchups.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('suggestMatchupsAI error: $e');
      return [];
    }
  }

  /// Calls the Gemini-powered generateFightBreakdown Cloud Function for a deep prediction.
  static Future<String> generateFightPredictionAI(
    FighterModel a,
    FighterModel b, {
    String? event,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateFightBreakdown');
      final result = await callable.call<Map<String, dynamic>>({
        'fighterA': a.fullName,
        'fighterB': b.fullName,
        'fighterAStats':
            '${a.wins}W-${a.losses}L${a.weightClass != null ? ', ${a.weightClass}' : ''}',
        'fighterBStats':
            '${b.wins}W-${b.losses}L${b.weightClass != null ? ', ${b.weightClass}' : ''}',
        'event': ?event,
      });
      final data = result.data;
      final bd = data['breakdown'];
      if (bd is Map<String, dynamic>) {
        final probA = ((bd['winProbabilityA'] as num?) ?? 0.5) * 100;
        final probB = ((bd['winProbabilityB'] as num?) ?? 0.5) * 100;
        return '${a.fullName} ${probA.round()}% vs ${b.fullName} ${probB.round()}%. '
            '${bd['fightIQInsights'] ?? ''} '
            'Predicted: ${bd['predictedMethod'] ?? 'Decision'}.';
      }
      return generateFightPrediction(a, b);
    } catch (e) {
      debugPrint('generateFightPredictionAI error: $e');
      return generateFightPrediction(a, b);
    }
  }
}
