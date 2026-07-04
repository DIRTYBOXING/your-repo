import '../entities/event.dart';
import '../entities/fighter.dart';
import '../entities/prediction.dart';
import '../repositories/prediction_repository.dart';

class CalculatePrediction {
  CalculatePrediction(this.repository);

  final PredictionRepository repository;

  Future<Prediction> call(Event event) async {
    final fighters = await repository.getFightersForEvent(event.id);
    final stats = await repository.getStatsForEvent(event.id);

    if (fighters.length < 2) {
      throw StateError('Prediction requires exactly two fighters.');
    }

    final fighterA = fighters[0];
    final fighterB = fighters[1];
    final scoreA = _score(fighterA, stats);
    final scoreB = _score(fighterB, stats);
    final total = (scoreA + scoreB).clamp(0.0001, double.infinity);

    final probabilityA = scoreA / total;
    final probabilityB = scoreB / total;
    final confidence = (probabilityA - probabilityB).abs();

    return Prediction(
      eventId: event.id,
      fighterAId: fighterA.id,
      fighterBId: fighterB.id,
      probabilityA: probabilityA,
      probabilityB: probabilityB,
      confidence: confidence,
      modelVersion: 'dfc-predictor-v1',
    );
  }

  double _score(Fighter fighter, Map<String, double> stats) {
    final pace = stats['pace'] ?? 0.5;
    final defense = stats['defense'] ?? 0.5;
    final consistency = stats['consistency'] ?? 0.5;

    return ((fighter.rankScore * 0.28) +
            (fighter.pastPerformanceScore * 0.24) +
            (fighter.styleMatchupScore * 0.18) +
            (fighter.healthScore * 0.18) +
            (fighter.trainingCampScore * 0.12)) *
        (0.5 + (pace * 0.2) + (defense * 0.15) + (consistency * 0.15));
  }
}
