import 'package:flutter_test/flutter_test.dart';

import 'package:datafightcentral/domain/entities/event.dart';
import 'package:datafightcentral/domain/entities/fighter.dart';
import 'package:datafightcentral/domain/entities/prediction.dart';
import 'package:datafightcentral/domain/repositories/prediction_repository.dart';
import 'package:datafightcentral/domain/usecases/calculate_prediction.dart';

class _FakePredictionRepository implements PredictionRepository {
  @override
  Future<List<Fighter>> getFightersForEvent(String eventId) async {
    return <Fighter>[
      Fighter(
        id: 'fighter_a',
        name: 'Alpha',
        rankScore: 82,
        pastPerformanceScore: 79,
        styleMatchupScore: 76,
        healthScore: 80,
        trainingCampScore: 78,
      ),
      Fighter(
        id: 'fighter_b',
        name: 'Bravo',
        rankScore: 74,
        pastPerformanceScore: 72,
        styleMatchupScore: 71,
        healthScore: 73,
        trainingCampScore: 70,
      ),
    ];
  }

  @override
  Future<Map<String, double>> getStatsForEvent(String eventId) async {
    return <String, double>{
      'pace': 0.6,
      'defense': 0.55,
      'consistency': 0.58,
    };
  }
}

void main() {
  group('CalculatePrediction', () {
    test('returns bounded probabilities and confidence', () async {
      final usecase = CalculatePrediction(_FakePredictionRepository());
      final event = Event(
        id: 'event_001',
        title: 'Main Event',
        startAt: DateTime.utc(2026, 1, 1, 10),
        endAt: DateTime.utc(2026, 1, 1, 14),
      );

      final Prediction result = await usecase(event);

      expect(result.eventId, equals('event_001'));
      expect(result.probabilityA, greaterThan(0));
      expect(result.probabilityA, lessThan(1));
      expect(result.probabilityB, greaterThan(0));
      expect(result.probabilityB, lessThan(1));
      expect((result.probabilityA + result.probabilityB), closeTo(1.0, 0.0001));
      expect(result.confidence, greaterThanOrEqualTo(0));
      expect(result.confidence, lessThanOrEqualTo(1));
    });
  });
}
