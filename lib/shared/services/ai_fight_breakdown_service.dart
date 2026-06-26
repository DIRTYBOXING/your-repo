import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/ai_fight_breakdown_model.dart';
import '../models/fighter_model.dart';

/// Service to handle AI Fight Breakdown logic — powered by Gemini via Cloud Functions
class AIFightBreakdownService {
  static final _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  /// Fetches a cached breakdown from Firestore, or generates a fresh one via Gemini.
  Future<AIFightBreakdown?> getFightBreakdown({
    required String fighterAId,
    required String fighterBId,
  }) async {
    final docId = '${fighterAId}_vs_$fighterBId';
    final doc = await FirebaseFirestore.instance
        .collection('ai_fight_breakdowns')
        .doc(docId)
        .get();
    if (doc.exists) {
      return AIFightBreakdown.fromFirestore(doc);
    }
    return null;
  }

  /// Saves an AI fight breakdown to Firestore for caching.
  Future<void> saveFightBreakdown(AIFightBreakdown breakdown) async {
    final docId = '${breakdown.fighterAId}_vs_${breakdown.fighterBId}';
    await FirebaseFirestore.instance
        .collection('ai_fight_breakdowns')
        .doc(docId)
        .set(breakdown.toFirestore());
  }

  /// Calls the Gemini-powered Cloud Function to generate a real breakdown.
  /// Falls back to a local stub if the function call fails.
  Future<AIFightBreakdown> generateBreakdown({
    required FighterModel fighterA,
    required FighterModel fighterB,
    String? event,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateFightBreakdown');
      final result = await callable.call<Map<String, dynamic>>({
        'fighterA': fighterA.fullName,
        'fighterB': fighterB.fullName,
        'fighterAStats':
            '${fighterA.wins}W-${fighterA.losses}L${fighterA.weightClass != null ? ', ${fighterA.weightClass}' : ''}',
        'fighterBStats':
            '${fighterB.wins}W-${fighterB.losses}L${fighterB.weightClass != null ? ', ${fighterB.weightClass}' : ''}',
        'event': ?event,
      });

      final data = result.data;
      final bd = data['breakdown'] as Map<String, dynamic>? ?? data;

      final breakdown = AIFightBreakdown(
        fighterAId: fighterA.id,
        fighterBId: fighterB.id,
        winProbabilityA: (bd['winProbabilityA'] as num?)?.toDouble() ?? 0.5,
        winProbabilityB: (bd['winProbabilityB'] as num?)?.toDouble() ?? 0.5,
        roundByRoundSimulation: List<String>.from(
          bd['roundByRoundSimulation'] ?? [],
        ),
        howAFighterBeatsB: bd['howABeatsB'] ?? bd['howAFighterBeatsB'] ?? '',
        howBFighterBeatsA: bd['howBBeatsA'] ?? bd['howBFighterBeatsA'] ?? '',
        fightIQInsights: bd['fightIQInsights'] ?? '',
        generatedAt: DateTime.now(),
      );

      // Cache it
      await saveFightBreakdown(breakdown);
      return breakdown;
    } catch (e) {
      debugPrint('generateBreakdown CF error: $e');
      return _localFallback(fighterA, fighterB);
    }
  }

  AIFightBreakdown _localFallback(
    FighterModel fighterA,
    FighterModel fighterB,
  ) {
    return AIFightBreakdown(
      fighterAId: fighterA.id,
      fighterBId: fighterB.id,
      winProbabilityA: 0.5,
      winProbabilityB: 0.5,
      roundByRoundSimulation: [
        'Round 1: Feeling-out process, both fighters measuring range.',
        'Round 2: Tempo increases, exchanges in the pocket.',
        'Round 3: Championship rounds \u2014 who wants it more?',
      ],
      howAFighterBeatsB:
          '${fighterA.fullName} pressures with volume and ring control.',
      howBFighterBeatsA:
          '${fighterB.fullName} counters off the back foot and clinches.',
      fightIQInsights:
          'Both fighters bring solid fundamentals. '
          'The decisive factor will be cardio management and adjustments between rounds.',
      generatedAt: DateTime.now(),
    );
  }
}
