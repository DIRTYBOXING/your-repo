import 'package:flutter_test/flutter_test.dart';
import 'package:datafightcentral/shared/models/stats/combat_stats.dart';

void main() {
  group('CombatStats — computed properties', () {
    test('accuracy is (landed / thrown) * 100', () {
      final stats = const CombatStats(
        fighterId: 'f1',
        totalStrikesLanded: 75,
        totalStrikesThrown: 100,
      );
      expect(stats.accuracy, 75.0);
    });

    test('accuracy is 0 when no strikes thrown', () {
      const stats = CombatStats(fighterId: 'f1');
      expect(stats.accuracy, 0.0);
    });

    test('takedownAccuracy is (landed / attempted) * 100', () {
      final stats = const CombatStats(
        fighterId: 'f1',
        totalTakedowns: 3,
        totalTakedownsAttempted: 10,
      );
      expect(stats.takedownAccuracy, 30.0);
    });

    test('takedownAccuracy is 0 when no attempts', () {
      const stats = CombatStats(fighterId: 'f1');
      expect(stats.takedownAccuracy, 0.0);
    });
  });

  group('CombatStats — Equatable', () {
    test('same stats are equal', () {
      const a = CombatStats(
        fighterId: 'f1',
        totalStrikesLanded: 100,
        winRate: 0.75,
      );
      const b = CombatStats(
        fighterId: 'f1',
        totalStrikesLanded: 100,
        winRate: 0.75,
      );
      expect(a, equals(b));
    });

    test('different fighterId are not equal', () {
      const a = CombatStats(fighterId: 'f1');
      const b = CombatStats(fighterId: 'f2');
      expect(a, isNot(equals(b)));
    });
  });

  group('CombatStats — defaults', () {
    test('default values are zero', () {
      const stats = CombatStats(fighterId: 'f1');
      expect(stats.totalSparringTime, Duration.zero);
      expect(stats.totalStrikesLanded, 0);
      expect(stats.totalStrikesThrown, 0);
      expect(stats.totalTakedowns, 0);
      expect(stats.totalTakedownsAttempted, 0);
      expect(stats.winRate, 0.0);
      expect(stats.performanceHistory, isEmpty);
    });
  });

  group('PerformanceDataPoint', () {
    test('equality by date and rating', () {
      final date = DateTime(2026);
      final a = PerformanceDataPoint(date: date, rating: 85.0);
      final b = PerformanceDataPoint(date: date, rating: 85.0);
      expect(a, equals(b));
    });

    test('different rating are not equal', () {
      final date = DateTime(2026);
      final a = PerformanceDataPoint(date: date, rating: 85.0);
      final b = PerformanceDataPoint(date: date, rating: 90.0);
      expect(a, isNot(equals(b)));
    });
  });
}
