import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'wearable_api_connector_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HEALTH DATA SERVICE - Wearable & Platform Integrations
/// ═══════════════════════════════════════════════════════════════════════════
///
/// This service handles connections to health platforms:
/// - Google Fit (Android)
/// - Apple HealthKit (iOS)
///
/// IMPORTANT: Full integration requires upgrading Firebase to ^3.x
/// The service is fully scaffolded but operates in stub mode until then.
///
/// DATA FLOW:
/// ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
/// │  Google Fit/    │───▶│  Health Data    │───▶│  Health Intel   │
/// │  Apple Health   │    │  Service        │    │  Engine         │
/// └─────────────────┘    └─────────────────┘    └─────────────────┘
/// ═══════════════════════════════════════════════════════════════════════════

/// Supported health platforms
enum HealthPlatform { googleFit, appleHealth }

/// Connection status for health platforms
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  permissionDenied,
  error,
}

/// Health data sync result
class HealthSyncResult {
  final bool success;
  final int dataPointsReceived;
  final String? errorMessage;
  final DateTime syncedAt;

  HealthSyncResult({
    required this.success,
    required this.dataPointsReceived,
    this.errorMessage,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();
}

/// Aggregated health metrics from wearables
class WearableHealthData {
  final int? steps;
  final double? heartRate;
  final double? restingHeartRate;
  final double? hrv; // Heart Rate Variability
  final double? sleepHours;
  final double? weight;
  final double? bodyFatPercent;
  final int? activeCalories;
  final int? totalCalories;
  final double? bloodOxygen;
  final double? respiratoryRate;
  final int? activeMinutes;
  final DateTime dataDate;

  WearableHealthData({
    this.steps,
    this.heartRate,
    this.restingHeartRate,
    this.hrv,
    this.sleepHours,
    this.weight,
    this.bodyFatPercent,
    this.activeCalories,
    this.totalCalories,
    this.bloodOxygen,
    this.respiratoryRate,
    this.activeMinutes,
    required this.dataDate,
  });
}

/// Service for integrating with health platforms and wearables.
///
/// This service delegates real OAuth + sync behavior to
/// WearableApiConnectorService and keeps the existing UI-facing API stable.
class HealthDataService with ChangeNotifier {
  HealthDataService({
    WearableApiConnectorService? connector,
    Future<PermissionStatus> Function()? activityPermissionRequest,
  }) : _connector = connector ?? WearableApiConnectorService(),
       _activityPermissionRequest =
           activityPermissionRequest ??
           (() => Permission.activityRecognition.request());

  final WearableApiConnectorService _connector;
  final Future<PermissionStatus> Function() _activityPermissionRequest;

  ConnectionStatus _googleFitStatus = ConnectionStatus.disconnected;
  ConnectionStatus _appleHealthStatus = ConnectionStatus.disconnected;

  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  String? _lastError;
  String? _googleFitAuthUrl;
  String? _appleHealthAuthUrl;

  ConnectionStatus get googleFitStatus => _googleFitStatus;
  ConnectionStatus get appleHealthStatus => _appleHealthStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  String? get googleFitAuthUrl => _googleFitAuthUrl;
  String? get appleHealthAuthUrl => _appleHealthAuthUrl;

  bool get isGoogleFitConnected =>
      _googleFitStatus == ConnectionStatus.connected;
  bool get isAppleHealthConnected =>
      _appleHealthStatus == ConnectionStatus.connected;

  Future<void> initialize() async {
    if (kIsWeb) {
      _lastError = 'Health integrations are unavailable on web clients.';
      notifyListeners();
      return;
    }

    await _connector.initialize();
    _refreshConnectionStates();
    notifyListeners();
  }

  void _refreshConnectionStates() {
    _googleFitStatus = _connector.isConnected(WearablePlatform.googleFit)
        ? ConnectionStatus.connected
        : ConnectionStatus.disconnected;
    _appleHealthStatus = _connector.isConnected(WearablePlatform.appleHealth)
        ? ConnectionStatus.connected
        : ConnectionStatus.disconnected;
  }

  // ==================== GOOGLE FIT (ANDROID) ====================

  Future<bool> connectGoogleFit() async {
    final authUrl = await beginGoogleFitAuthorization();
    return authUrl == null && isGoogleFitConnected;
  }

  Future<String?> beginGoogleFitAuthorization() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _lastError = 'Google Fit is only available on Android devices.';
      _googleFitStatus = ConnectionStatus.error;
      notifyListeners();
      return null;
    }

    _googleFitStatus = ConnectionStatus.connecting;
    _lastError = null;
    notifyListeners();

    final permission = await _activityPermissionRequest();
    if (!permission.isGranted) {
      _googleFitStatus = ConnectionStatus.permissionDenied;
      _lastError = 'Activity recognition permission denied.';
      notifyListeners();
      return null;
    }

    if (_connector.isConnected(WearablePlatform.googleFit)) {
      _googleFitStatus = ConnectionStatus.connected;
      _googleFitAuthUrl = null;
      notifyListeners();
      return null;
    }

    final authUrl = _connector.getAuthorizationUrl(WearablePlatform.googleFit);
    if (authUrl.isEmpty) {
      _googleFitStatus = ConnectionStatus.error;
      _lastError = 'Google Fit authorization URL is not configured.';
      notifyListeners();
      return null;
    }

    _googleFitAuthUrl = authUrl;
    notifyListeners();
    return authUrl;
  }

  Future<bool> completeGoogleFitAuthorization(String authCode) async {
    if (authCode.trim().isEmpty) {
      _googleFitStatus = ConnectionStatus.error;
      _lastError = 'Authorization code is required.';
      notifyListeners();
      return false;
    }

    final success = await _connector.exchangeAuthCode(
      WearablePlatform.googleFit,
      authCode.trim(),
    );

    if (success) {
      _googleFitStatus = ConnectionStatus.connected;
      _googleFitAuthUrl = null;
      _lastError = null;
    } else {
      _googleFitStatus = ConnectionStatus.error;
      _lastError = 'Google Fit token exchange failed.';
    }

    notifyListeners();
    return success;
  }

  Future<void> disconnectGoogleFit() async {
    await _connector.disconnect(WearablePlatform.googleFit);
    _googleFitStatus = ConnectionStatus.disconnected;
    _googleFitAuthUrl = null;
    notifyListeners();
  }

  // ==================== APPLE HEALTH (IOS) ====================

  Future<bool> connectAppleHealth() async {
    final authUrl = await beginAppleHealthAuthorization();
    return authUrl == null && isAppleHealthConnected;
  }

  Future<String?> beginAppleHealthAuthorization() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      _lastError = 'Apple Health is only available on iOS devices.';
      _appleHealthStatus = ConnectionStatus.error;
      notifyListeners();
      return null;
    }

    _appleHealthStatus = ConnectionStatus.connecting;
    _lastError = null;
    notifyListeners();

    if (_connector.isConnected(WearablePlatform.appleHealth)) {
      _appleHealthStatus = ConnectionStatus.connected;
      _appleHealthAuthUrl = null;
      notifyListeners();
      return null;
    }

    final authUrl = _connector.getAuthorizationUrl(
      WearablePlatform.appleHealth,
    );
    if (authUrl.isEmpty) {
      _appleHealthStatus = ConnectionStatus.error;
      _lastError =
          'Apple Health native authorization is not yet completed for this account.';
      notifyListeners();
      return null;
    }

    _appleHealthAuthUrl = authUrl;
    notifyListeners();
    return authUrl;
  }

  Future<bool> completeAppleHealthAuthorization(String authCode) async {
    if (authCode.trim().isEmpty) {
      _appleHealthStatus = ConnectionStatus.error;
      _lastError = 'Authorization code is required.';
      notifyListeners();
      return false;
    }

    final success = await _connector.exchangeAuthCode(
      WearablePlatform.appleHealth,
      authCode.trim(),
    );

    if (success) {
      _appleHealthStatus = ConnectionStatus.connected;
      _appleHealthAuthUrl = null;
      _lastError = null;
    } else {
      _appleHealthStatus = ConnectionStatus.error;
      _lastError = 'Apple Health token exchange failed.';
    }

    notifyListeners();
    return success;
  }

  Future<void> disconnectAppleHealth() async {
    await _connector.disconnect(WearablePlatform.appleHealth);
    _appleHealthStatus = ConnectionStatus.disconnected;
    _appleHealthAuthUrl = null;
    notifyListeners();
  }

  // ==================== DATA SYNC ====================

  Future<HealthSyncResult> syncHealthData({int days = 7}) async {
    if (_isSyncing) {
      return HealthSyncResult(
        success: false,
        dataPointsReceived: 0,
        errorMessage: 'Sync already in progress',
      );
    }

    if (!isGoogleFitConnected && !isAppleHealthConnected) {
      return HealthSyncResult(
        success: false,
        dataPointsReceived: 0,
        errorMessage: 'No health platform connected',
      );
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _connector.syncAllConnected();
      final successful = result.values.where((entry) => entry != null).length;

      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      _refreshConnectionStates();
      notifyListeners();

      return HealthSyncResult(
        success: successful > 0,
        dataPointsReceived: successful,
        errorMessage: successful > 0 ? null : 'No wearable payloads returned.',
      );
    } catch (e) {
      _isSyncing = false;
      _lastError = e.toString();
      _refreshConnectionStates();
      notifyListeners();

      return HealthSyncResult(
        success: false,
        dataPointsReceived: 0,
        errorMessage: e.toString(),
      );
    }
  }

  Future<WearableHealthData?> getTodayHealthData() async {
    final snapshot = _connector.mergedSnapshot;
    if (snapshot == null) {
      return null;
    }
    return _mapPayload(snapshot);
  }

  Future<List<WearableHealthData>> getHealthDataRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final today = await getTodayHealthData();
    if (today == null) {
      return [];
    }
    if (today.dataDate.isBefore(startDate) || today.dataDate.isAfter(endDate)) {
      return [];
    }
    return [today];
  }

  Future<int> getTodaySteps() async {
    final today = await getTodayHealthData();
    return today?.steps ?? 0;
  }

  WearableHealthData _mapPayload(NormalizedHealthPayload payload) {
    return WearableHealthData(
      steps: payload.steps,
      heartRate: payload.heartRate?.toDouble(),
      restingHeartRate: payload.restingHR?.toDouble(),
      hrv: payload.hrvMs?.toDouble(),
      sleepHours: payload.sleepHours,
      weight: payload.weight,
      bodyFatPercent: payload.bodyFat,
      activeCalories: payload.caloriesBurned?.round(),
      bloodOxygen: payload.spo2?.toDouble(),
      respiratoryRate: payload.respiratoryRate,
      activeMinutes: payload.activeMinutes?.round(),
      dataDate: payload.dataDate,
    );
  }
}
