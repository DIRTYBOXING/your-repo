import 'package:flutter_test/flutter_test.dart';
import 'package:datafightcentral/shared/services/wearable_api_connector_service.dart';

void main() {
  // ── WearablePlatform enum ──────────────────────────────────────────────

  group('WearablePlatform', () {
    test('has 6 platforms', () {
      expect(WearablePlatform.values.length, 6);
    });

    test('each platform has unique id', () {
      final ids = WearablePlatform.values.map((p) => p.id).toSet();
      expect(ids.length, WearablePlatform.values.length);
    });

    test('fitbit properties', () {
      expect(WearablePlatform.fitbit.displayName, 'Fitbit');
      expect(WearablePlatform.fitbit.id, 'fitbit');
      expect(WearablePlatform.fitbit.scopes, contains('activity'));
    });

    test('whoop properties', () {
      expect(WearablePlatform.whoop.displayName, 'WHOOP');
      expect(WearablePlatform.whoop.id, 'whoop');
      expect(WearablePlatform.whoop.scopes, contains('recovery'));
    });
  });

  // ── WearableToken ─────────────────────────────────────────────────────

  group('WearableToken', () {
    test('isExpired returns true for past date', () {
      final token = WearableToken(
        platform: 'fitbit',
        accessToken: 'abc123',
        refreshToken: 'refresh456',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(token.isExpired, isTrue);
    });

    test('isExpired returns false for future date', () {
      final token = WearableToken(
        platform: 'fitbit',
        accessToken: 'abc123',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(token.isExpired, isFalse);
    });

    test('needsRefresh true within 5-minute buffer', () {
      final token = WearableToken(
        platform: 'whoop',
        accessToken: 'abc',
        expiresAt: DateTime.now().add(const Duration(minutes: 3)),
      );
      expect(token.needsRefresh, isTrue);
    });

    test('needsRefresh false when plenty of time remains', () {
      final token = WearableToken(
        platform: 'oura',
        accessToken: 'abc',
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );
      expect(token.needsRefresh, isFalse);
    });

    test('toMap / fromMap round-trip', () {
      final original = WearableToken(
        platform: 'garmin',
        accessToken: 'garmin_token',
        refreshToken: 'garmin_refresh',
        expiresAt: DateTime(2026, 6, 15, 12),
        connectedAt: DateTime(2026, 6, 14, 8),
        metadata: {'deviceId': 'gv4'},
      );

      final map = original.toMap();
      final restored = WearableToken.fromMap(map);

      expect(restored.platform, original.platform);
      expect(restored.accessToken, original.accessToken);
      expect(restored.refreshToken, original.refreshToken);
      expect(restored.expiresAt, original.expiresAt);
      expect(restored.connectedAt, original.connectedAt);
      expect(restored.metadata['deviceId'], 'gv4');
    });

    test('toMap contains required keys', () {
      final token = WearableToken(
        platform: 'fitbit',
        accessToken: 'tok',
        expiresAt: DateTime(2026),
      );
      final map = token.toMap();
      expect(map, containsPair('platform', 'fitbit'));
      expect(map, containsPair('accessToken', 'tok'));
      expect(map, contains('expiresAt'));
    });
  });

  // ── NormalizedHealthPayload ────────────────────────────────────────────

  group('NormalizedHealthPayload', () {
    NormalizedHealthPayload makeFullPayload() => NormalizedHealthPayload(
      source: WearablePlatform.whoop,
      fetchedAt: DateTime(2026, 4, 3, 10),
      dataDate: DateTime(2026, 4, 3),
      heartRate: 72,
      restingHR: 55,
      maxHR: 185,
      hrvMs: 62,
      spo2: 98,
      steps: 8500,
      caloriesBurned: 2400.0,
      activeMinutes: 45.0,
      distanceKm: 6.2,
      floorsClimbed: 12,
      sleepHours: 7.5,
      sleepScore: 85,
      remHours: 1.8,
      deepSleepHours: 2.1,
      lightSleepHours: 3.0,
      awakeHours: 0.6,
      weight: 77.5,
      bodyFat: 12.5,
      bmi: 24.2,
      recoveryScore: 78,
      readinessScore: 82,
      strainScore: 14,
      respiratoryRate: 16.0,
      skinTemp: 36.8,
      glucose: 95.0,
      lactate: 1.2,
      cortisol: 12.0,
    );

    test('stores all fields correctly', () {
      final p = makeFullPayload();
      expect(p.source, WearablePlatform.whoop);
      expect(p.heartRate, 72);
      expect(p.restingHR, 55);
      expect(p.maxHR, 185);
      expect(p.hrvMs, 62);
      expect(p.spo2, 98);
      expect(p.steps, 8500);
      expect(p.caloriesBurned, 2400.0);
      expect(p.activeMinutes, 45.0);
      expect(p.distanceKm, 6.2);
      expect(p.floorsClimbed, 12);
      expect(p.sleepHours, 7.5);
      expect(p.sleepScore, 85);
      expect(p.remHours, 1.8);
      expect(p.deepSleepHours, 2.1);
      expect(p.weight, 77.5);
      expect(p.bodyFat, 12.5);
      expect(p.recoveryScore, 78);
      expect(p.readinessScore, 82);
      expect(p.strainScore, 14);
      expect(p.respiratoryRate, 16.0);
      expect(p.skinTemp, 36.8);
      expect(p.glucose, 95.0);
      expect(p.lactate, 1.2);
      expect(p.cortisol, 12.0);
    });

    test('toFirestoreMap / fromFirestoreMap round-trip', () {
      final original = makeFullPayload();
      final map = original.toFirestoreMap();
      final restored = NormalizedHealthPayload.fromFirestoreMap(map);

      expect(restored.source, original.source);
      expect(restored.heartRate, original.heartRate);
      expect(restored.restingHR, original.restingHR);
      expect(restored.hrvMs, original.hrvMs);
      expect(restored.spo2, original.spo2);
      expect(restored.steps, original.steps);
      expect(restored.sleepHours, original.sleepHours);
      expect(restored.sleepScore, original.sleepScore);
      expect(restored.weight, original.weight);
      expect(restored.bodyFat, original.bodyFat);
      expect(restored.recoveryScore, original.recoveryScore);
      expect(restored.readinessScore, original.readinessScore);
      expect(restored.glucose, original.glucose);
      expect(restored.cortisol, original.cortisol);
    });

    test('toFirestoreMap contains source as string', () {
      final p = makeFullPayload();
      final map = p.toFirestoreMap();
      expect(map['source'], 'whoop');
    });

    test('handles null fields gracefully', () {
      final p = NormalizedHealthPayload(
        source: WearablePlatform.oura,
        fetchedAt: DateTime.now(),
        dataDate: DateTime.now(),
      );
      expect(p.heartRate, isNull);
      expect(p.steps, isNull);
      expect(p.sleepHours, isNull);
      expect(p.glucose, isNull);

      final map = p.toFirestoreMap();
      final restored = NormalizedHealthPayload.fromFirestoreMap(map);
      expect(restored.heartRate, isNull);
      expect(restored.steps, isNull);
    });
  });

  // ── SyncHistoryEntry ──────────────────────────────────────────────────

  group('SyncHistoryEntry', () {
    test('stores fields correctly', () {
      final entry = SyncHistoryEntry(
        platform: WearablePlatform.fitbit,
        syncedAt: DateTime(2026, 4, 3),
        success: true,
        dataPointsReceived: 42,
        duration: const Duration(seconds: 3),
      );
      expect(entry.platform, WearablePlatform.fitbit);
      expect(entry.success, isTrue);
      expect(entry.dataPointsReceived, 42);
      expect(entry.duration, const Duration(seconds: 3));
      expect(entry.errorMessage, isNull);
    });

    test('toMap contains all fields', () {
      final entry = SyncHistoryEntry(
        platform: WearablePlatform.garmin,
        syncedAt: DateTime(2026, 4, 3, 14, 30),
        success: false,
        dataPointsReceived: 0,
        errorMessage: 'Token expired',
        duration: const Duration(milliseconds: 800),
      );
      final map = entry.toMap();
      expect(map['platform'], 'garmin');
      expect(map['success'], isFalse);
      expect(map['errorMessage'], 'Token expired');
      expect(map['dataPointsReceived'], 0);
    });

    test('successful sync has no error message', () {
      final entry = SyncHistoryEntry(
        platform: WearablePlatform.whoop,
        syncedAt: DateTime.now(),
        success: true,
        dataPointsReceived: 15,
        duration: const Duration(seconds: 2),
      );
      expect(entry.errorMessage, isNull);
      expect(entry.success, isTrue);
    });
  });
}
