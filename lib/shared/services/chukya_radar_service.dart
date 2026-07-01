import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/threat_profile.dart';
import '../models/proximity_alert.dart';

export '../models/threat_profile.dart';
export '../models/proximity_alert.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CHUKYA 3.0 RADAR SERVICE — Proximity Threat Detection Engine
/// ═══════════════════════════════════════════════════════════════════════════
///
/// First-of-its-kind proximity-based restraining order enforcement system.
/// Uses BLE/WiFi scanning to detect when a police-registered threat profile
/// comes within range of a victim's safe zone or person.
///
/// Integration points:
///   • SafetyHubService — panic alerts, emergency contacts, guardian mode
///   • DFCWearablesEngine — BLE 5.3 protocol stack, sensor pipeline
///   • Pink Shield — certification network, safe spaces
///
/// Scan modes:
///   1. HOME SHIELD   — continuous passive scan at home/yard
///   2. TRAVEL RADAR  — active scan while walking/travelling
///   3. AMBUSH DETECT — burst scan before entering car/building
///   4. SAFE ZONE     — geofenced auto-activate at work/gym/school
///
/// Privacy & legal:
///   • Police reference number REQUIRED to add threat profile
///   • Only hashed identifiers stored — no raw phone numbers
///   • Detection is proximity-only — no tracking of offender
///   • All alerts logged to Evidence Vault (timestamped, GPS)
/// ═══════════════════════════════════════════════════════════════════════════

// Models imported from standalone files above (threat_profile.dart, proximity_alert.dart)

// ── Main Service ─────────────────────────────────────────────────────────

class ChukyaRadarService extends ChangeNotifier {
  static final ChukyaRadarService _instance = ChukyaRadarService._internal();
  factory ChukyaRadarService() => _instance;
  ChukyaRadarService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── State ──
  bool _isScanning = false;
  ChukyaScanMode _currentMode = ChukyaScanMode.homeShield;
  ThreatLevel _currentThreatLevel = ThreatLevel.clear;
  Timer? _scanTimer;
  final List<ProximityAlert> _recentAlerts = [];
  final List<ThreatProfile> _watchlist = [];
  final List<SafeZone> _safeZones = [];
  int _scanCount = 0;
  DateTime? _lastScanAt;

  // ── Getters ──
  bool get isScanning => _isScanning;
  ChukyaScanMode get currentMode => _currentMode;
  ThreatLevel get currentThreatLevel => _currentThreatLevel;
  List<ProximityAlert> get recentAlerts => List.unmodifiable(_recentAlerts);
  List<ThreatProfile> get watchlist => List.unmodifiable(_watchlist);
  List<SafeZone> get safeZones => List.unmodifiable(_safeZones);
  int get scanCount => _scanCount;
  DateTime? get lastScanAt => _lastScanAt;

  // ── Scan interval per mode ──
  int _scanIntervalSeconds(ChukyaScanMode mode) {
    switch (mode) {
      case ChukyaScanMode.homeShield:
        return 60; // passive, low battery
      case ChukyaScanMode.travelRadar:
        return 30; // active, moderate
      case ChukyaScanMode.ambushDetect:
        return 5; // burst, intensive
      case ChukyaScanMode.safeZone:
        return 45; // geofenced
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // THREAT WATCHLIST MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════

  /// Register a threat profile (requires police reference number).
  Future<String> registerThreatProfile({
    required String userId,
    required String hashedPhoneId,
    required String policeRefNumber,
    required String offenderAlias,
    double restrainingDistance = 200.0,
    Map<String, dynamic> deviceFingerprint = const {},
  }) async {
    final ref = await _db.collection('threat_watchlist').add({
      'victimUserId': userId,
      'hashedPhoneId': hashedPhoneId,
      'policeRefNumber': policeRefNumber,
      'offenderAlias': offenderAlias,
      'restrainingDistanceMeters': restrainingDistance,
      'registeredAt': FieldValue.serverTimestamp(),
      'expiresAt': null,
      'policeValidated': false, // requires admin/police validation
      'deviceFingerprint': deviceFingerprint,
    });
    await loadWatchlist(userId);
    return ref.id;
  }

  /// Load the victim's threat watchlist from Firestore.
  Future<void> loadWatchlist(String userId) async {
    try {
      final snap = await _db
          .collection('threat_watchlist')
          .where('victimUserId', isEqualTo: userId)
          .get();
      _watchlist.clear();
      for (final doc in snap.docs) {
        _watchlist.add(ThreatProfile.fromMap(doc.id, doc.data()));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ChukyaRadar: failed to load watchlist — $e');
    }
  }

  /// Remove a threat profile.
  Future<void> removeThreatProfile(String profileId, String userId) async {
    await _db.collection('threat_watchlist').doc(profileId).delete();
    await loadWatchlist(userId);
  }

  // ══════════════════════════════════════════════════════════════════════
  // SAFE ZONE MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════

  Future<String> addSafeZone({
    required String userId,
    required String name,
    required double latitude,
    required double longitude,
    double radiusMeters = 200.0,
  }) async {
    final ref = await _db.collection('safe_zones').add({
      'userId': userId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await loadSafeZones(userId);
    return ref.id;
  }

  Future<void> loadSafeZones(String userId) async {
    try {
      final snap = await _db
          .collection('safe_zones')
          .where('userId', isEqualTo: userId)
          .get();
      _safeZones.clear();
      for (final doc in snap.docs) {
        _safeZones.add(SafeZone.fromMap(doc.id, doc.data()));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ChukyaRadar: failed to load safe zones — $e');
    }
  }

  Future<void> removeSafeZone(String zoneId, String userId) async {
    await _db.collection('safe_zones').doc(zoneId).delete();
    await loadSafeZones(userId);
  }

  // ══════════════════════════════════════════════════════════════════════
  // SCANNING ENGINE
  // ══════════════════════════════════════════════════════════════════════

  /// Start proximity scanning in the given mode.
  void startScanning(ChukyaScanMode mode) {
    _scanTimer?.cancel();
    _currentMode = mode;
    _isScanning = true;
    _currentThreatLevel = ThreatLevel.clear;
    notifyListeners();

    final interval = _scanIntervalSeconds(mode);
    _scanTimer = Timer.periodic(Duration(seconds: interval), (_) {
      _performScanCycle();
    });
    // Immediate first scan
    _performScanCycle();
  }

  /// Stop scanning.
  void stopScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;
    _isScanning = false;
    _currentThreatLevel = ThreatLevel.clear;
    notifyListeners();
  }

  /// Switch scan mode while running.
  void switchMode(ChukyaScanMode mode) {
    if (_isScanning) {
      stopScanning();
      startScanning(mode);
    } else {
      _currentMode = mode;
      notifyListeners();
    }
  }

  /// Core scan cycle — checks BLE/WiFi environment against watchlist.
  void _performScanCycle() {
    _scanCount++;
    _lastScanAt = DateTime.now();

    // In production, this method would:
    // 1. Call platform channel to get nearby BLE advertisements
    // 2. Extract device fingerprint patterns (adv intervals, TX power, model hints)
    // 3. Cross-reference against _watchlist device fingerprints
    // 4. Calculate RSSI → estimated distance
    // 5. If match confidence > 0.8, fire ProximityAlert
    //
    // For UI demo, we simulate the scan result:
    _currentThreatLevel = ThreatLevel.clear;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════
  // ALERT MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════

  /// Fire a proximity alert — logs to Firestore Evidence Vault.
  Future<String> fireProximityAlert({
    required String victimUserId,
    required String threatProfileId,
    required String policeRefNumber,
    required double estimatedDistance,
    required double confidence,
    double? latitude,
    double? longitude,
    Map<String, dynamic> signalData = const {},
  }) async {
    final ref = await _db
        .collection('proximity_alerts')
        .add(
          ProximityAlert(
            id: '',
            victimUserId: victimUserId,
            threatProfileId: threatProfileId,
            policeRefNumber: policeRefNumber,
            estimatedDistanceMeters: estimatedDistance,
            confidence: confidence,
            latitude: latitude,
            longitude: longitude,
            scanMode: _currentMode,
            threatLevel: confidence >= 0.8
                ? ThreatLevel.critical
                : confidence >= 0.5
                ? ThreatLevel.high
                : ThreatLevel.elevated,
            detectedAt: DateTime.now(),
            signalData: signalData,
          ).toMap(),
        );

    // Escalate: notify emergency contacts
    await _db.collection('safety_notifications').add({
      'alertId': ref.id,
      'userId': victimUserId,
      'type': 'proximity_threat',
      'policeRefNumber': policeRefNumber,
      'estimatedDistance': estimatedDistance,
      'confidence': confidence,
      'latitude': latitude,
      'longitude': longitude,
      'sentAt': FieldValue.serverTimestamp(),
      'acknowledged': false,
    });

    await loadAlertHistory(victimUserId);
    return ref.id;
  }

  /// Load recent proximity alert history.
  Future<void> loadAlertHistory(String userId) async {
    try {
      final snap = await _db
          .collection('proximity_alerts')
          .where('victimUserId', isEqualTo: userId)
          .orderBy('detectedAt', descending: true)
          .limit(50)
          .get();
      _recentAlerts.clear();
      for (final doc in snap.docs) {
        _recentAlerts.add(ProximityAlert.fromMap(doc.id, doc.data()));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ChukyaRadar: failed to load alert history — $e');
    }
  }

  /// Acknowledge an alert.
  Future<void> acknowledgeAlert(String alertId) async {
    await _db.collection('proximity_alerts').doc(alertId).update({
      'status': AlertStatus.acknowledged.value,
    });
  }

  /// Resolve an alert.
  Future<void> resolveAlert(String alertId) async {
    await _db.collection('proximity_alerts').doc(alertId).update({
      'status': AlertStatus.resolved.value,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════════════════════════════
  // STATS
  // ══════════════════════════════════════════════════════════════════════

  /// Get scan statistics for the radar screen.
  Map<String, dynamic> getScanStats() => {
    'totalScans': _scanCount,
    'lastScan': _lastScanAt?.toIso8601String(),
    'activeMode': _currentMode.label,
    'threatLevel': _currentThreatLevel.label,
    'watchlistCount': _watchlist.length,
    'safeZoneCount': _safeZones.length,
    'alertCount': _recentAlerts.length,
    'isScanning': _isScanning,
  };

  /// Dispose scan timer.
  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }
}
