import 'package:cloud_firestore/cloud_firestore.dart';
import 'threat_profile.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CHUKYA 3.0 — Proximity Alert Model
/// ═══════════════════════════════════════════════════════════════════════════

class ProximityAlert {
  final String id;
  final String victimUserId;
  final String threatProfileId;
  final String policeRefNumber;
  final double estimatedDistanceMeters;
  final double confidence; // 0.0 – 1.0
  final double? latitude;
  final double? longitude;
  final ChukyaScanMode scanMode;
  final ThreatLevel threatLevel;
  final AlertStatus status;
  final DateTime detectedAt;
  final Map<String, dynamic> signalData; // RSSI, device hints

  const ProximityAlert({
    required this.id,
    required this.victimUserId,
    required this.threatProfileId,
    required this.policeRefNumber,
    required this.estimatedDistanceMeters,
    required this.confidence,
    this.latitude,
    this.longitude,
    required this.scanMode,
    required this.threatLevel,
    this.status = AlertStatus.active,
    required this.detectedAt,
    this.signalData = const {},
  });

  Map<String, dynamic> toMap() => {
    'victimUserId': victimUserId,
    'threatProfileId': threatProfileId,
    'policeRefNumber': policeRefNumber,
    'estimatedDistanceMeters': estimatedDistanceMeters,
    'confidence': confidence,
    'latitude': latitude,
    'longitude': longitude,
    'scanMode': scanMode.name,
    'threatLevel': threatLevel.name,
    'status': status.value,
    'detectedAt': Timestamp.fromDate(detectedAt),
    'signalData': signalData,
  };

  factory ProximityAlert.fromMap(String id, Map<String, dynamic> m) =>
      ProximityAlert(
        id: id,
        victimUserId: m['victimUserId'] ?? '',
        threatProfileId: m['threatProfileId'] ?? '',
        policeRefNumber: m['policeRefNumber'] ?? '',
        estimatedDistanceMeters:
            (m['estimatedDistanceMeters'] as num?)?.toDouble() ?? 0.0,
        confidence: (m['confidence'] as num?)?.toDouble() ?? 0.0,
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        scanMode: ChukyaScanMode.values.firstWhere(
          (e) => e.name == m['scanMode'],
          orElse: () => ChukyaScanMode.homeShield,
        ),
        threatLevel: ThreatLevel.values.firstWhere(
          (e) => e.name == m['threatLevel'],
          orElse: () => ThreatLevel.clear,
        ),
        status: AlertStatus.values.firstWhere(
          (e) => e.value == m['status'],
          orElse: () => AlertStatus.active,
        ),
        detectedAt: m['detectedAt'] != null
            ? (m['detectedAt'] as Timestamp).toDate()
            : DateTime.now(),
        signalData: Map<String, dynamic>.from(m['signalData'] ?? {}),
      );
}
