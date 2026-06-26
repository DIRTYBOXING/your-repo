import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CHUKYA 3.0 — Threat Profile & Safety Enums
/// ═══════════════════════════════════════════════════════════════════════════

// ── Enums ────────────────────────────────────────────────────────────────

enum ChukyaScanMode {
  homeShield('HOME SHIELD', '🏠', 'Continuous passive scan at home/yard'),
  travelRadar('TRAVEL RADAR', '🚶', 'Active scan while moving'),
  ambushDetect('AMBUSH DETECT', '⚠️', 'Burst scan before entry/exit'),
  safeZone('SAFE ZONE', '📍', 'Auto-activate in registered safe zones');

  final String label;
  final String icon;
  final String description;
  const ChukyaScanMode(this.label, this.icon, this.description);
}

enum ThreatLevel {
  clear('CLEAR', 0),
  low('LOW', 1),
  elevated('ELEVATED', 2),
  high('HIGH', 3),
  critical('CRITICAL', 4);

  final String label;
  final int severity;
  const ThreatLevel(this.label, this.severity);
}

enum AlertStatus {
  active('active'),
  acknowledged('acknowledged'),
  policeNotified('police_notified'),
  resolved('resolved');

  final String value;
  const AlertStatus(this.value);
}

// ── Threat Profile ───────────────────────────────────────────────────────

class ThreatProfile {
  final String id;
  final String victimUserId;
  final String hashedPhoneId; // SHA-256 hashed phone identifier
  final String policeRefNumber;
  final String offenderAlias; // victim's name for them, never real name
  final double restrainingDistanceMeters;
  final DateTime registeredAt;
  final DateTime? expiresAt;
  final bool policeValidated;
  final Map<String, dynamic> deviceFingerprint; // BLE adv patterns, model hints

  const ThreatProfile({
    required this.id,
    required this.victimUserId,
    required this.hashedPhoneId,
    required this.policeRefNumber,
    required this.offenderAlias,
    this.restrainingDistanceMeters = 200.0,
    required this.registeredAt,
    this.expiresAt,
    this.policeValidated = false,
    this.deviceFingerprint = const {},
  });

  Map<String, dynamic> toMap() => {
    'victimUserId': victimUserId,
    'hashedPhoneId': hashedPhoneId,
    'policeRefNumber': policeRefNumber,
    'offenderAlias': offenderAlias,
    'restrainingDistanceMeters': restrainingDistanceMeters,
    'registeredAt': Timestamp.fromDate(registeredAt),
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'policeValidated': policeValidated,
    'deviceFingerprint': deviceFingerprint,
  };

  factory ThreatProfile.fromMap(String id, Map<String, dynamic> m) =>
      ThreatProfile(
        id: id,
        victimUserId: m['victimUserId'] ?? '',
        hashedPhoneId: m['hashedPhoneId'] ?? '',
        policeRefNumber: m['policeRefNumber'] ?? '',
        offenderAlias: m['offenderAlias'] ?? 'Unknown',
        restrainingDistanceMeters:
            (m['restrainingDistanceMeters'] as num?)?.toDouble() ?? 200.0,
        registeredAt: m['registeredAt'] != null
            ? (m['registeredAt'] as Timestamp).toDate()
            : DateTime.now(),
        expiresAt: m['expiresAt'] != null
            ? (m['expiresAt'] as Timestamp).toDate()
            : null,
        policeValidated: m['policeValidated'] ?? false,
        deviceFingerprint: Map<String, dynamic>.from(
          m['deviceFingerprint'] ?? {},
        ),
      );
}

// ── Safe Zone ────────────────────────────────────────────────────────────

class SafeZone {
  final String id;
  final String userId;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool active;

  const SafeZone({
    required this.id,
    required this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200.0,
    this.active = true,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radiusMeters': radiusMeters,
    'active': active,
  };

  factory SafeZone.fromMap(String id, Map<String, dynamic> m) => SafeZone(
    id: id,
    userId: m['userId'] ?? '',
    name: m['name'] ?? '',
    latitude: (m['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (m['longitude'] as num?)?.toDouble() ?? 0.0,
    radiusMeters: (m['radiusMeters'] as num?)?.toDouble() ?? 200.0,
    active: m['active'] ?? true,
  );
}
