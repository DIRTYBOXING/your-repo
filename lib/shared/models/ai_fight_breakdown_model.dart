import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:equatable/equatable.dart';

/// AI Fight Breakdown Result
class AIFightBreakdown {
  final String fighterAId;
  final String fighterBId;
  final double winProbabilityA;
  final double winProbabilityB;
  final List<String>
  roundByRoundSimulation; // e.g. ["Round 1: ...", "Round 2: ..."]
  final String howAFighterBeatsB;
  final String howBFighterBeatsA;
  final String fightIQInsights;
  final DateTime generatedAt;

  const AIFightBreakdown({
    required this.fighterAId,
    required this.fighterBId,
    required this.winProbabilityA,
    required this.winProbabilityB,
    required this.roundByRoundSimulation,
    required this.howAFighterBeatsB,
    required this.howBFighterBeatsA,
    required this.fightIQInsights,
    required this.generatedAt,
  });

  factory AIFightBreakdown.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIFightBreakdown(
      fighterAId: data['fighterAId'],
      fighterBId: data['fighterBId'],
      winProbabilityA: (data['winProbabilityA'] as num).toDouble(),
      winProbabilityB: (data['winProbabilityB'] as num).toDouble(),
      roundByRoundSimulation: List<String>.from(
        data['roundByRoundSimulation'] ?? [],
      ),
      howAFighterBeatsB: data['howAFighterBeatsB'] ?? '',
      howBFighterBeatsA: data['howBFighterBeatsA'] ?? '',
      fightIQInsights: data['fightIQInsights'] ?? '',
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fighterAId': fighterAId,
      'fighterBId': fighterBId,
      'winProbabilityA': winProbabilityA,
      'winProbabilityB': winProbabilityB,
      'roundByRoundSimulation': roundByRoundSimulation,
      'howAFighterBeatsB': howAFighterBeatsB,
      'howBFighterBeatsA': howBFighterBeatsA,
      'fightIQInsights': fightIQInsights,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }
}
