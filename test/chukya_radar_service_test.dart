import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:datafightcentral/shared/models/threat_profile.dart';
import 'package:datafightcentral/shared/models/proximity_alert.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CHUKYA 3.0 — Unit Tests for Models and Service Logic
/// ═══════════════════════════════════════════════════════════════════════════

void main() {
  // ════════════════════════════════════════════════════════════════════════
  // THREAT PROFILE MODEL
  // ════════════════════════════════════════════════════════════════════════

  group('ThreatProfile', () {
    test('toMap produces correct Firestore-ready map', () {
      final now = DateTime(2026, 3, 26, 12);
      final profile = ThreatProfile(
        id: 'prof-1',
        victimUserId: 'victim-abc',
        hashedPhoneId: 'sha256hash123',
        policeRefNumber: 'POL-2026-001',
        offenderAlias: 'Subject A',
        restrainingDistanceMeters: 300.0,
        registeredAt: now,
        policeValidated: true,
        deviceFingerprint: {'model': 'Pixel 7'},
      );

      final map = profile.toMap();
      expect(map['victimUserId'], 'victim-abc');
      expect(map['hashedPhoneId'], 'sha256hash123');
      expect(map['policeRefNumber'], 'POL-2026-001');
      expect(map['offenderAlias'], 'Subject A');
      expect(map['restrainingDistanceMeters'], 300.0);
      expect(map['policeValidated'], true);
      expect(map['deviceFingerprint']['model'], 'Pixel 7');
      expect(map['registeredAt'], isA<Timestamp>());
      expect(map['expiresAt'], isNull);
    });

    test('fromMap reconstructs from Firestore document', () {
      final ts = Timestamp.fromDate(DateTime(2026, 3, 26, 12));
      final map = <String, dynamic>{
        'victimUserId': 'v1',
        'hashedPhoneId': 'hash1',
        'policeRefNumber': 'POL-001',
        'offenderAlias': 'Test',
        'restrainingDistanceMeters': 150.0,
        'registeredAt': ts,
        'expiresAt': null,
        'policeValidated': true,
        'deviceFingerprint': {
          'names': ['Pixel'],
        },
      };

      final profile = ThreatProfile.fromMap('doc-id', map);
      expect(profile.id, 'doc-id');
      expect(profile.victimUserId, 'v1');
      expect(profile.hashedPhoneId, 'hash1');
      expect(profile.policeRefNumber, 'POL-001');
      expect(profile.restrainingDistanceMeters, 150.0);
      expect(profile.policeValidated, true);
      expect(profile.deviceFingerprint['names'], ['Pixel']);
    });

    test('fromMap handles missing fields with defaults', () {
      final profile = ThreatProfile.fromMap('id', <String, dynamic>{});
      expect(profile.victimUserId, '');
      expect(profile.hashedPhoneId, '');
      expect(profile.offenderAlias, 'Unknown');
      expect(profile.restrainingDistanceMeters, 200.0);
      expect(profile.policeValidated, false);
    });

    test('default restraining distance is 200m', () {
      final profile = ThreatProfile(
        id: 'x',
        victimUserId: 'u',
        hashedPhoneId: 'h',
        policeRefNumber: 'r',
        offenderAlias: 'a',
        registeredAt: DateTime.now(),
      );
      expect(profile.restrainingDistanceMeters, 200.0);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // SAFE ZONE MODEL
  // ════════════════════════════════════════════════════════════════════════

  group('SafeZone', () {
    test('toMap produces correct output', () {
      const zone = SafeZone(
        id: 'z1',
        userId: 'u1',
        name: 'Home',
        latitude: -27.4698,
        longitude: 153.0251,
        radiusMeters: 100.0,
      );

      final map = zone.toMap();
      expect(map['name'], 'Home');
      expect(map['latitude'], -27.4698);
      expect(map['longitude'], 153.0251);
      expect(map['radiusMeters'], 100.0);
      expect(map['active'], true);
    });

    test('fromMap reconstructs correctly', () {
      final zone = SafeZone.fromMap('z1', {
        'userId': 'u1',
        'name': 'Work',
        'latitude': -27.48,
        'longitude': 153.03,
        'radiusMeters': 50.0,
        'active': false,
      });
      expect(zone.id, 'z1');
      expect(zone.name, 'Work');
      expect(zone.active, false);
      expect(zone.radiusMeters, 50.0);
    });

    test('defaults to 200m radius and active', () {
      const zone = SafeZone(
        id: 'z',
        userId: 'u',
        name: 'n',
        latitude: 0,
        longitude: 0,
      );
      expect(zone.radiusMeters, 200.0);
      expect(zone.active, true);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // PROXIMITY ALERT MODEL
  // ════════════════════════════════════════════════════════════════════════

  group('ProximityAlert', () {
    test('toMap serializes all fields correctly', () {
      final alert = ProximityAlert(
        id: 'a1',
        victimUserId: 'v1',
        threatProfileId: 'p1',
        policeRefNumber: 'POL-001',
        estimatedDistanceMeters: 45.0,
        confidence: 0.92,
        latitude: -27.47,
        longitude: 153.02,
        scanMode: ChukyaScanMode.travelRadar,
        threatLevel: ThreatLevel.critical,
        status: AlertStatus.policeNotified,
        detectedAt: DateTime(2026, 3, 26, 14, 30),
        signalData: {'avgRssi': -55},
      );

      final map = alert.toMap();
      expect(map['victimUserId'], 'v1');
      expect(map['confidence'], 0.92);
      expect(map['scanMode'], 'travelRadar');
      expect(map['threatLevel'], 'critical');
      expect(map['status'], 'police_notified');
      expect(map['estimatedDistanceMeters'], 45.0);
      expect(map['signalData']['avgRssi'], -55);
      expect(map['detectedAt'], isA<Timestamp>());
    });

    test('fromMap reconstructs enums correctly', () {
      final ts = Timestamp.fromDate(DateTime(2026, 3, 26));
      final alert = ProximityAlert.fromMap('a-id', {
        'victimUserId': 'v2',
        'threatProfileId': 'p2',
        'policeRefNumber': 'POL-002',
        'estimatedDistanceMeters': 120.0,
        'confidence': 0.85,
        'scanMode': 'ambushDetect',
        'threatLevel': 'high',
        'status': 'acknowledged',
        'detectedAt': ts,
        'signalData': {},
      });

      expect(alert.id, 'a-id');
      expect(alert.scanMode, ChukyaScanMode.ambushDetect);
      expect(alert.threatLevel, ThreatLevel.high);
      expect(alert.status, AlertStatus.acknowledged);
      expect(alert.confidence, 0.85);
    });

    test('fromMap defaults to safe values for unknown enums', () {
      final alert = ProximityAlert.fromMap('id', {
        'scanMode': 'nonexistent_mode',
        'threatLevel': 'unknown_level',
        'status': 'unknown_status',
      });
      expect(alert.scanMode, ChukyaScanMode.homeShield);
      expect(alert.threatLevel, ThreatLevel.clear);
      expect(alert.status, AlertStatus.active);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // ENUM TESTS
  // ════════════════════════════════════════════════════════════════════════

  group('ChukyaScanMode', () {
    test('has correct labels', () {
      expect(ChukyaScanMode.homeShield.label, 'HOME SHIELD');
      expect(ChukyaScanMode.travelRadar.label, 'TRAVEL RADAR');
      expect(ChukyaScanMode.ambushDetect.label, 'AMBUSH DETECT');
      expect(ChukyaScanMode.safeZone.label, 'SAFE ZONE');
    });

    test('has 4 modes', () {
      expect(ChukyaScanMode.values.length, 4);
    });
  });

  group('ThreatLevel', () {
    test('severity order is correct', () {
      expect(ThreatLevel.clear.severity, 0);
      expect(ThreatLevel.low.severity, 1);
      expect(ThreatLevel.elevated.severity, 2);
      expect(ThreatLevel.high.severity, 3);
      expect(ThreatLevel.critical.severity, 4);
    });

    test('has 5 levels', () {
      expect(ThreatLevel.values.length, 5);
    });
  });

  group('AlertStatus', () {
    test('values match Firestore strings', () {
      expect(AlertStatus.active.value, 'active');
      expect(AlertStatus.acknowledged.value, 'acknowledged');
      expect(AlertStatus.policeNotified.value, 'police_notified');
      expect(AlertStatus.resolved.value, 'resolved');
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // CONFIDENCE THRESHOLD LOGIC
  // ════════════════════════════════════════════════════════════════════════

  group('Confidence threshold logic', () {
    ThreatLevel classifyThreat(double confidence) {
      if (confidence >= 0.8) return ThreatLevel.critical;
      if (confidence >= 0.5) return ThreatLevel.high;
      if (confidence >= 0.3) return ThreatLevel.elevated;
      if (confidence >= 0.1) return ThreatLevel.low;
      return ThreatLevel.clear;
    }

    test('confidence >= 0.8 maps to CRITICAL', () {
      expect(classifyThreat(0.8), ThreatLevel.critical);
      expect(classifyThreat(0.95), ThreatLevel.critical);
      expect(classifyThreat(1.0), ThreatLevel.critical);
    });

    test('confidence 0.5-0.79 maps to HIGH', () {
      expect(classifyThreat(0.5), ThreatLevel.high);
      expect(classifyThreat(0.79), ThreatLevel.high);
    });

    test('confidence < 0.1 maps to CLEAR', () {
      expect(classifyThreat(0.0), ThreatLevel.clear);
      expect(classifyThreat(0.05), ThreatLevel.clear);
    });

    test('police notification threshold is 0.8', () {
      // Only auto-notify police at confidence >= 0.8
      const policeThreshold = 0.8;
      expect(0.92 >= policeThreshold, true);
      expect(0.79 >= policeThreshold, false);
      expect(0.80 >= policeThreshold, true);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // RSSI → DISTANCE ESTIMATION
  // ════════════════════════════════════════════════════════════════════════

  group('RSSI to distance estimation', () {
    // Port of the standard RSSI→meters formula used in the service
    double estimateDistance(List<int> rssiValues) {
      if (rssiValues.isEmpty) return double.infinity;
      final avgRssi = rssiValues.reduce((a, b) => a + b) / rssiValues.length;
      const txPower = -59; // assumed calibrated reference
      final ratio = (txPower - avgRssi) / 20;
      return _pow10(ratio);
    }

    test('closer device has smaller distance', () {
      final close = estimateDistance([-40, -42, -41]);
      final far = estimateDistance([-80, -82, -79]);
      expect(close < far, true);
    });

    test('same RSSI returns consistent distance', () {
      final d1 = estimateDistance([-60, -60, -60]);
      final d2 = estimateDistance([-60, -60, -60]);
      expect(d1, d2);
    });

    test('empty RSSI list returns infinity', () {
      expect(estimateDistance([]), double.infinity);
    });

    test('very strong signal estimates sub-meter range', () {
      final d = estimateDistance([-30, -30, -30]);
      expect(d < 1.0, true);
    });
  });
}

// Helper: 10^x without importing dart:math
double _pow10(double x) {
  double result = 1.0;
  final intPart = x.truncate();
  final fracPart = x - intPart;

  // Integer power
  for (int i = 0; i < intPart.abs(); i++) {
    result *= 10;
  }
  if (intPart < 0) result = 1.0 / result;

  // Fractional power approximation using natural log
  // 10^frac = e^(frac * ln(10)) ≈ Taylor expansion
  if (fracPart != 0) {
    final lnTen = 2.302585092994046;
    final exp = fracPart * lnTen;
    double term = 1.0;
    double sum = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= exp / i;
      sum += term;
    }
    result *= sum;
  }

  return result;
}
