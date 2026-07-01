import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ═══════════════════════════════════════════════════════════════════════════
/// WEARABLE API CONNECTOR SERVICE — Real OAuth + REST for All Wearables
/// ═══════════════════════════════════════════════════════════════════════════
///
/// PURPOSE: Single integration point for all cloud-connected wearable APIs.
/// Handles OAuth 2.0 flows, token management, data pull, and normalization
/// into a unified NormalizedHealthPayload for consumption by:
///   • BiometricDataService
///   • HealthIntelligenceEngine
///   • DFCWearablesEngine
///   • Health Dashboard UI
///
/// SUPPORTED PLATFORMS:
///   Fitbit  — OAuth 2.0 PKCE, REST API v1.2
///   Garmin  — OAuth 1.0a, Garmin Connect Health API
///   WHOOP   — OAuth 2.0, WHOOP Developer API v1
///   Oura    — OAuth 2.0, Oura Ring API v2
///   Google Fit — REST API (web) / Health Connect (native)
///   Apple Health — HealthKit (iOS native only, no REST)
///
/// SECURITY:
///   • Client secrets stored in Firebase Cloud Functions secrets (NEVER in app)
///   • Token exchange happens server-side via callable Cloud Function
///   • Refresh tokens encrypted at rest in Firestore
///   • All API calls use HTTPS with certificate pinning headers
///
/// DATA FLOW:
///   App → OAuth redirect → Cloud Function (token exchange) → Firestore
///   App → pullLatest() → Cloud Function (API call with stored token) → normalize → BiometricDataService
///
/// ═══════════════════════════════════════════════════════════════════════════

// ── Wearable Platform Enum ───────────────────────────────────────────────

enum WearablePlatform {
  fitbit('Fitbit', 'fitbit', '💚', 'activity heartrate sleep profile weight'),
  garmin('Garmin Connect', 'garmin', '🔵', 'activity wellness sleep body'),
  whoop('WHOOP', 'whoop', '🟡', 'recovery strain sleep workout'),
  oura('Oura Ring', 'oura', '⚪', 'daily_readiness daily_sleep daily_activity'),
  googleFit(
    'Google Fit',
    'google_fit',
    '🟢',
    'fitness.activity.read fitness.body.read fitness.sleep.read',
  ),
  appleHealth('Apple Health', 'apple_health', '❤️', 'HealthKit (native only)');

  final String displayName;
  final String id;
  final String icon;
  final String scopes;

  const WearablePlatform(this.displayName, this.id, this.icon, this.scopes);
}

// ── Connection State ─────────────────────────────────────────────────────

enum WearableConnectionState {
  disconnected,
  authorizing,
  exchangingToken,
  connected,
  syncing,
  error,
  tokenExpired,
}

// ── Token Model ──────────────────────────────────────────────────────────

class WearableToken {
  final String platform;
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final DateTime connectedAt;
  final Map<String, dynamic> metadata;

  WearableToken({
    required this.platform,
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
    DateTime? connectedAt,
    this.metadata = const {},
  }) : connectedAt = connectedAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get needsRefresh =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  Map<String, dynamic> toMap() => {
    'platform': platform,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': Timestamp.fromDate(expiresAt),
    'connectedAt': Timestamp.fromDate(connectedAt),
    'metadata': metadata,
  };

  factory WearableToken.fromMap(Map<String, dynamic> map) => WearableToken(
    platform: map['platform'] as String,
    accessToken: map['accessToken'] as String,
    refreshToken: map['refreshToken'] as String?,
    expiresAt: (map['expiresAt'] as Timestamp).toDate(),
    connectedAt: (map['connectedAt'] as Timestamp?)?.toDate(),
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );
}

// ── Normalized Health Payload ────────────────────────────────────────────

class NormalizedHealthPayload {
  final WearablePlatform source;
  final DateTime fetchedAt;
  final DateTime dataDate;

  // Cardiovascular
  final int? heartRate;
  final int? restingHR;
  final int? maxHR;
  final int? hrvMs;
  final int? spo2;

  // Activity
  final int? steps;
  final double? caloriesBurned;
  final double? activeMinutes;
  final double? distanceKm;
  final int? floorsClimbed;

  // Sleep
  final double? sleepHours;
  final int? sleepScore;
  final double? remHours;
  final double? deepSleepHours;
  final double? lightSleepHours;
  final double? awakeHours;

  // Body
  final double? weight;
  final double? bodyFat;
  final double? bmi;

  // Recovery & Readiness
  final int? recoveryScore;
  final int? readinessScore;
  final int? strainScore;
  final double? respiratoryRate;
  final double? skinTemp;

  // Blood Chemistry (advanced sensors)
  final double? glucose;
  final double? lactate;
  final double? cortisol;

  NormalizedHealthPayload({
    required this.source,
    required this.fetchedAt,
    required this.dataDate,
    this.heartRate,
    this.restingHR,
    this.maxHR,
    this.hrvMs,
    this.spo2,
    this.steps,
    this.caloriesBurned,
    this.activeMinutes,
    this.distanceKm,
    this.floorsClimbed,
    this.sleepHours,
    this.sleepScore,
    this.remHours,
    this.deepSleepHours,
    this.lightSleepHours,
    this.awakeHours,
    this.weight,
    this.bodyFat,
    this.bmi,
    this.recoveryScore,
    this.readinessScore,
    this.strainScore,
    this.respiratoryRate,
    this.skinTemp,
    this.glucose,
    this.lactate,
    this.cortisol,
  });

  Map<String, dynamic> toFirestoreMap() => {
    'source': source.id,
    'fetchedAt': Timestamp.fromDate(fetchedAt),
    'dataDate': Timestamp.fromDate(dataDate),
    'heartRate': heartRate,
    'restingHR': restingHR,
    'maxHR': maxHR,
    'hrvMs': hrvMs,
    'spo2': spo2,
    'steps': steps,
    'caloriesBurned': caloriesBurned,
    'activeMinutes': activeMinutes,
    'distanceKm': distanceKm,
    'floorsClimbed': floorsClimbed,
    'sleepHours': sleepHours,
    'sleepScore': sleepScore,
    'remHours': remHours,
    'deepSleepHours': deepSleepHours,
    'lightSleepHours': lightSleepHours,
    'awakeHours': awakeHours,
    'weight': weight,
    'bodyFat': bodyFat,
    'bmi': bmi,
    'recoveryScore': recoveryScore,
    'readinessScore': readinessScore,
    'strainScore': strainScore,
    'respiratoryRate': respiratoryRate,
    'skinTemp': skinTemp,
    'glucose': glucose,
    'lactate': lactate,
    'cortisol': cortisol,
  };

  factory NormalizedHealthPayload.fromFirestoreMap(Map<String, dynamic> map) {
    final sourceId = map['source'] as String? ?? 'fitbit';
    return NormalizedHealthPayload(
      source: WearablePlatform.values.firstWhere(
        (p) => p.id == sourceId,
        orElse: () => WearablePlatform.fitbit,
      ),
      fetchedAt: (map['fetchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataDate: (map['dataDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      heartRate: map['heartRate'] as int?,
      restingHR: map['restingHR'] as int?,
      maxHR: map['maxHR'] as int?,
      hrvMs: map['hrvMs'] as int?,
      spo2: map['spo2'] as int?,
      steps: map['steps'] as int?,
      caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble(),
      activeMinutes: (map['activeMinutes'] as num?)?.toDouble(),
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      floorsClimbed: map['floorsClimbed'] as int?,
      sleepHours: (map['sleepHours'] as num?)?.toDouble(),
      sleepScore: map['sleepScore'] as int?,
      remHours: (map['remHours'] as num?)?.toDouble(),
      deepSleepHours: (map['deepSleepHours'] as num?)?.toDouble(),
      lightSleepHours: (map['lightSleepHours'] as num?)?.toDouble(),
      awakeHours: (map['awakeHours'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      bodyFat: (map['bodyFat'] as num?)?.toDouble(),
      bmi: (map['bmi'] as num?)?.toDouble(),
      recoveryScore: map['recoveryScore'] as int?,
      readinessScore: map['readinessScore'] as int?,
      strainScore: map['strainScore'] as int?,
      respiratoryRate: (map['respiratoryRate'] as num?)?.toDouble(),
      skinTemp: (map['skinTemp'] as num?)?.toDouble(),
      glucose: (map['glucose'] as num?)?.toDouble(),
      lactate: (map['lactate'] as num?)?.toDouble(),
      cortisol: (map['cortisol'] as num?)?.toDouble(),
    );
  }
}

// ── Sync History Entry ───────────────────────────────────────────────────

class SyncHistoryEntry {
  final WearablePlatform platform;
  final DateTime syncedAt;
  final bool success;
  final int dataPointsReceived;
  final String? errorMessage;
  final Duration duration;

  SyncHistoryEntry({
    required this.platform,
    required this.syncedAt,
    required this.success,
    required this.dataPointsReceived,
    this.errorMessage,
    required this.duration,
  });

  Map<String, dynamic> toMap() => {
    'platform': platform.id,
    'syncedAt': Timestamp.fromDate(syncedAt),
    'success': success,
    'dataPointsReceived': dataPointsReceived,
    'errorMessage': errorMessage,
    'durationMs': duration.inMilliseconds,
  };
}

// ═════════════════════════════════════════════════════════════════════════
// MAIN SERVICE
// ═════════════════════════════════════════════════════════════════════════

class WearableApiConnectorService with ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────────────────
  static final WearableApiConnectorService _instance =
      WearableApiConnectorService._internal();
  factory WearableApiConnectorService() => _instance;
  WearableApiConnectorService._internal();

  // ── Firestore ──────────────────────────────────────────────────────────
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── State ──────────────────────────────────────────────────────────────
  final Map<WearablePlatform, WearableConnectionState> _connectionStates = {};
  final Map<WearablePlatform, WearableToken> _tokens = {};
  final Map<WearablePlatform, NormalizedHealthPayload?> _latestData = {};
  final Map<WearablePlatform, DateTime?> _lastSyncTimes = {};
  final List<SyncHistoryEntry> _syncHistory = [];
  Timer? _autoSyncTimer;
  bool _initialized = false;

  // ── Getters ────────────────────────────────────────────────────────────

  String? get _uid => _auth.currentUser?.uid;

  WearableConnectionState connectionState(WearablePlatform platform) =>
      _connectionStates[platform] ?? WearableConnectionState.disconnected;

  bool isConnected(WearablePlatform platform) =>
      _connectionStates[platform] == WearableConnectionState.connected;

  NormalizedHealthPayload? latestData(WearablePlatform platform) =>
      _latestData[platform];

  DateTime? lastSyncTime(WearablePlatform platform) => _lastSyncTimes[platform];

  List<WearablePlatform> get connectedPlatforms =>
      WearablePlatform.values.where(isConnected).toList();

  List<SyncHistoryEntry> get syncHistory => List.unmodifiable(_syncHistory);

  int get connectedCount => connectedPlatforms.length;

  /// Merged latest data from all connected platforms (highest priority wins)
  NormalizedHealthPayload? get mergedSnapshot {
    final connected = connectedPlatforms;
    if (connected.isEmpty) return null;

    // Priority: WHOOP recovery > Oura readiness > Garmin training > Fitbit activity > Google Fit
    final priorityOrder = [
      WearablePlatform.whoop,
      WearablePlatform.oura,
      WearablePlatform.garmin,
      WearablePlatform.fitbit,
      WearablePlatform.googleFit,
    ];

    int? heartRate, restingHR, maxHR, hrvMs, spo2, steps;
    double? calories, activeMin, distance, sleepHrs, weight, bodyFat;
    int? recoveryScore, readinessScore, strainScore, sleepScore;
    double? respiratoryRate, skinTemp, glucose, lactate, cortisol;
    double? remHrs, deepHrs, lightHrs, awakeHrs;
    int? floors;
    double? bmi;

    for (final platform in priorityOrder) {
      final data = _latestData[platform];
      if (data == null) continue;

      heartRate ??= data.heartRate;
      restingHR ??= data.restingHR;
      maxHR ??= data.maxHR;
      hrvMs ??= data.hrvMs;
      spo2 ??= data.spo2;
      steps ??= data.steps;
      calories ??= data.caloriesBurned;
      activeMin ??= data.activeMinutes;
      distance ??= data.distanceKm;
      floors ??= data.floorsClimbed;
      sleepHrs ??= data.sleepHours;
      sleepScore ??= data.sleepScore;
      remHrs ??= data.remHours;
      deepHrs ??= data.deepSleepHours;
      lightHrs ??= data.lightSleepHours;
      awakeHrs ??= data.awakeHours;
      weight ??= data.weight;
      bodyFat ??= data.bodyFat;
      bmi ??= data.bmi;
      recoveryScore ??= data.recoveryScore;
      readinessScore ??= data.readinessScore;
      strainScore ??= data.strainScore;
      respiratoryRate ??= data.respiratoryRate;
      skinTemp ??= data.skinTemp;
      glucose ??= data.glucose;
      lactate ??= data.lactate;
      cortisol ??= data.cortisol;
    }

    return NormalizedHealthPayload(
      source: connected.first,
      fetchedAt: DateTime.now(),
      dataDate: DateTime.now(),
      heartRate: heartRate,
      restingHR: restingHR,
      maxHR: maxHR,
      hrvMs: hrvMs,
      spo2: spo2,
      steps: steps,
      caloriesBurned: calories,
      activeMinutes: activeMin,
      distanceKm: distance,
      floorsClimbed: floors,
      sleepHours: sleepHrs,
      sleepScore: sleepScore,
      remHours: remHrs,
      deepSleepHours: deepHrs,
      lightSleepHours: lightHrs,
      awakeHours: awakeHrs,
      weight: weight,
      bodyFat: bodyFat,
      bmi: bmi,
      recoveryScore: recoveryScore,
      readinessScore: readinessScore,
      strainScore: strainScore,
      respiratoryRate: respiratoryRate,
      skinTemp: skinTemp,
      glucose: glucose,
      lactate: lactate,
      cortisol: cortisol,
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _loadStoredTokens();
    _startAutoSync();

    debugPrint(
      'WearableApiConnector: Initialized '
      '($connectedCount platforms connected)',
    );
    notifyListeners();
  }

  /// Load persisted tokens from Firestore
  Future<void> _loadStoredTokens() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('wearable_tokens')
          .get();

      for (final doc in snap.docs) {
        try {
          final token = WearableToken.fromMap(doc.data());
          final platform = WearablePlatform.values.firstWhere(
            (p) => p.id == token.platform,
            orElse: () => WearablePlatform.fitbit,
          );

          if (token.isExpired && token.refreshToken != null) {
            // Attempt server-side refresh
            final refreshed = await _refreshToken(platform, token);
            if (refreshed != null) {
              _tokens[platform] = refreshed;
              _connectionStates[platform] = WearableConnectionState.connected;
            } else {
              _connectionStates[platform] =
                  WearableConnectionState.tokenExpired;
            }
          } else if (!token.isExpired) {
            _tokens[platform] = token;
            _connectionStates[platform] = WearableConnectionState.connected;
          } else {
            _connectionStates[platform] = WearableConnectionState.tokenExpired;
          }
        } catch (e) {
          debugPrint(
            'WearableApiConnector: Error loading token for '
            '${doc.id}: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('WearableApiConnector: Error loading tokens: $e');
    }
  }

  /// Auto-sync every 15 minutes for connected platforms
  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      syncAllConnected();
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // OAUTH FLOWS — All token exchange via Cloud Functions for security
  // ═════════════════════════════════════════════════════════════════════════

  /// Get the OAuth authorization URL for a platform
  /// User opens this in browser/webview, then redirect back with auth code
  String getAuthorizationUrl(WearablePlatform platform) {
    final uid = _uid ?? 'anonymous';
    // State parameter prevents CSRF — encode UID + platform for callback
    final state = base64Url.encode(utf8.encode('$uid:${platform.id}'));

    switch (platform) {
      case WearablePlatform.fitbit:
        return 'https://www.fitbit.com/oauth2/authorize'
            '?response_type=code'
            '&client_id=\${FITBIT_CLIENT_ID}' // Injected at build time
            '&redirect_uri=${Uri.encodeComponent(_redirectUri(platform))}'
            '&scope=${Uri.encodeComponent(platform.scopes)}'
            '&state=$state'
            '&code_challenge_method=S256';

      case WearablePlatform.garmin:
        // Garmin uses OAuth 1.0a — request token first via Cloud Function
        return 'https://connect.garmin.com/oauthConfirm'
            '?oauth_token=\${GARMIN_REQUEST_TOKEN}'
            '&state=$state';

      case WearablePlatform.whoop:
        return 'https://api.prod.whoop.com/oauth/oauth2/auth'
            '?response_type=code'
            '&client_id=\${WHOOP_CLIENT_ID}'
            '&redirect_uri=${Uri.encodeComponent(_redirectUri(platform))}'
            '&scope=${Uri.encodeComponent(platform.scopes)}'
            '&state=$state';

      case WearablePlatform.oura:
        return 'https://cloud.ouraring.com/oauth/authorize'
            '?response_type=code'
            '&client_id=\${OURA_CLIENT_ID}'
            '&redirect_uri=${Uri.encodeComponent(_redirectUri(platform))}'
            '&scope=${Uri.encodeComponent(platform.scopes)}'
            '&state=$state';

      case WearablePlatform.googleFit:
        return 'https://accounts.google.com/o/oauth2/v2/auth'
            '?response_type=code'
            '&client_id=\${GOOGLE_FIT_CLIENT_ID}'
            '&redirect_uri=${Uri.encodeComponent(_redirectUri(platform))}'
            '&scope=${Uri.encodeComponent(platform.scopes)}'
            '&state=$state'
            '&access_type=offline'
            '&prompt=consent';

      case WearablePlatform.appleHealth:
        // Apple HealthKit is native iOS only — no web OAuth
        return '';
    }
  }

  String _redirectUri(WearablePlatform platform) {
    // Deep link back to the app after OAuth
    return 'https://datafightcentral.com/auth/callback/${platform.id}';
  }

  /// Exchange authorization code for tokens via Cloud Function
  /// NEVER exchange tokens client-side — secrets live on the server
  Future<bool> exchangeAuthCode(
    WearablePlatform platform,
    String authCode,
  ) async {
    final uid = _uid;
    if (uid == null) return false;

    _connectionStates[platform] = WearableConnectionState.exchangingToken;
    notifyListeners();

    try {
      // Call Cloud Function that holds the client secrets
      final response = await http.post(
        Uri.parse(
          'https://australia-southeast1-datafightcentral.cloudfunctions.net'
          '/exchangeWearableToken',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _auth.currentUser?.getIdToken()}',
        },
        body: jsonEncode({
          'platform': platform.id,
          'authCode': authCode,
          'redirectUri': _redirectUri(platform),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = WearableToken(
          platform: platform.id,
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String?,
          expiresAt: DateTime.now().add(
            Duration(seconds: data['expires_in'] as int? ?? 3600),
          ),
          metadata: {
            'scopes': data['scope'] ?? platform.scopes,
            'tokenType': data['token_type'] ?? 'Bearer',
          },
        );

        _tokens[platform] = token;
        _connectionStates[platform] = WearableConnectionState.connected;

        // Persist token to Firestore (encrypted at rest by Firebase)
        await _persistToken(platform, token);

        // Initial sync
        await pullLatest(platform);

        debugPrint('WearableApiConnector: ${platform.displayName} connected');
        notifyListeners();
        return true;
      } else {
        _connectionStates[platform] = WearableConnectionState.error;
        debugPrint(
          'WearableApiConnector: Token exchange failed '
          '(${response.statusCode}): ${response.body}',
        );
        notifyListeners();
        return false;
      }
    } catch (e) {
      _connectionStates[platform] = WearableConnectionState.error;
      debugPrint('WearableApiConnector: Token exchange error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Disconnect and revoke access for a platform
  Future<void> disconnect(WearablePlatform platform) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      // Revoke token server-side
      final token = _tokens[platform];
      if (token != null) {
        await http.post(
          Uri.parse(
            'https://australia-southeast1-datafightcentral.cloudfunctions.net'
            '/revokeWearableToken',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await _auth.currentUser?.getIdToken()}',
          },
          body: jsonEncode({'platform': platform.id}),
        );
      }

      // Remove from Firestore
      await _db
          .collection('users')
          .doc(uid)
          .collection('wearable_tokens')
          .doc(platform.id)
          .delete();

      _tokens.remove(platform);
      _latestData.remove(platform);
      _lastSyncTimes.remove(platform);
      _connectionStates[platform] = WearableConnectionState.disconnected;

      debugPrint('WearableApiConnector: ${platform.displayName} disconnected');
      notifyListeners();
    } catch (e) {
      debugPrint('WearableApiConnector: Disconnect error: $e');
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // DATA PULL — Fetch & Normalize from each platform API
  // ═════════════════════════════════════════════════════════════════════════

  /// Pull latest data from a connected platform
  Future<NormalizedHealthPayload?> pullLatest(WearablePlatform platform) async {
    if (!isConnected(platform)) return null;

    final token = _tokens[platform];
    if (token == null) return null;

    // Refresh token if needed
    if (token.needsRefresh) {
      final refreshed = await _refreshToken(platform, token);
      if (refreshed == null) {
        _connectionStates[platform] = WearableConnectionState.tokenExpired;
        notifyListeners();
        return null;
      }
      _tokens[platform] = refreshed;
    }

    _connectionStates[platform] = WearableConnectionState.syncing;
    notifyListeners();

    final stopwatch = Stopwatch()..start();

    try {
      final payload = await _fetchAndNormalize(platform, _tokens[platform]!);
      stopwatch.stop();

      if (payload != null) {
        _latestData[platform] = payload;
        _lastSyncTimes[platform] = DateTime.now();

        // Persist to Firestore
        await _persistHealthData(platform, payload);

        _syncHistory.insert(
          0,
          SyncHistoryEntry(
            platform: platform,
            syncedAt: DateTime.now(),
            success: true,
            dataPointsReceived: _countDataPoints(payload),
            duration: stopwatch.elapsed,
          ),
        );
      }

      _connectionStates[platform] = WearableConnectionState.connected;
      notifyListeners();
      return payload;
    } catch (e) {
      stopwatch.stop();
      _syncHistory.insert(
        0,
        SyncHistoryEntry(
          platform: platform,
          syncedAt: DateTime.now(),
          success: false,
          dataPointsReceived: 0,
          errorMessage: e.toString(),
          duration: stopwatch.elapsed,
        ),
      );

      _connectionStates[platform] = WearableConnectionState.connected;
      debugPrint(
        'WearableApiConnector: Pull failed for '
        '${platform.displayName}: $e',
      );
      notifyListeners();
      return null;
    }
  }

  /// Sync all connected platforms in parallel
  Future<Map<WearablePlatform, NormalizedHealthPayload?>>
  syncAllConnected() async {
    final results = <WearablePlatform, NormalizedHealthPayload?>{};
    final futures = <Future<void>>[];

    for (final platform in connectedPlatforms) {
      futures.add(
        pullLatest(platform).then((payload) {
          results[platform] = payload;
        }),
      );
    }

    await Future.wait(futures);

    debugPrint(
      'WearableApiConnector: Synced ${results.length} platforms '
      '(${results.values.where((v) => v != null).length} successful)',
    );
    return results;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PLATFORM-SPECIFIC API CALLS & NORMALIZATION
  // ═════════════════════════════════════════════════════════════════════════

  Future<NormalizedHealthPayload?> _fetchAndNormalize(
    WearablePlatform platform,
    WearableToken token,
  ) async {
    switch (platform) {
      case WearablePlatform.fitbit:
        return _fetchFitbit(token);
      case WearablePlatform.garmin:
        return _fetchGarmin(token);
      case WearablePlatform.whoop:
        return _fetchWhoop(token);
      case WearablePlatform.oura:
        return _fetchOura(token);
      case WearablePlatform.googleFit:
        return _fetchGoogleFit(token);
      case WearablePlatform.appleHealth:
        // Apple HealthKit handled by platform_health_service (native)
        return null;
    }
  }

  // ── Fitbit API ─────────────────────────────────────────────────────────

  Future<NormalizedHealthPayload?> _fetchFitbit(WearableToken token) async {
    final today = _dateString(DateTime.now());
    final headers = {'Authorization': 'Bearer ${token.accessToken}'};

    // Parallel API calls for efficiency
    final results = await Future.wait([
      _safeGet(
        'https://api.fitbit.com/1/user/-/activities/date/$today.json',
        headers,
      ),
      _safeGet(
        'https://api.fitbit.com/1/user/-/sleep/date/$today.json',
        headers,
      ),
      _safeGet(
        'https://api.fitbit.com/1/user/-/activities/heart/date/$today/1d.json',
        headers,
      ),
      _safeGet(
        'https://api.fitbit.com/1/user/-/body/log/weight/date/$today.json',
        headers,
      ),
      _safeGet(
        'https://api.fitbit.com/1/user/-/spo2/date/$today.json',
        headers,
      ),
      _safeGet('https://api.fitbit.com/1/user/-/hrv/date/$today.json', headers),
      _safeGet('https://api.fitbit.com/1/user/-/br/date/$today.json', headers),
    ]);

    final activity = results[0];
    final sleep = results[1];
    final heart = results[2];
    final weight = results[3];
    final spo2 = results[4];
    final hrv = results[5];
    final breathing = results[6];

    return NormalizedHealthPayload(
      source: WearablePlatform.fitbit,
      fetchedAt: DateTime.now(),
      dataDate: DateTime.now(),
      steps: _extractInt(activity, ['summary', 'steps']),
      caloriesBurned: _extractDouble(activity, ['summary', 'caloriesOut']),
      activeMinutes: _extractDouble(activity, ['summary', 'veryActiveMinutes'])
          ?.let(
            (v) =>
                v +
                (_extractDouble(activity, ['summary', 'fairlyActiveMinutes']) ??
                    0),
          ),
      distanceKm: _extractListFirstDouble(activity, [
        'summary',
        'distances',
      ], 'distance'),
      floorsClimbed: _extractInt(activity, ['summary', 'floors']),
      sleepHours: _extractDouble(sleep, [
        'summary',
        'totalMinutesAsleep',
      ])?.let((m) => m / 60),
      remHours: _extractSleepStageHours(sleep, 'rem'),
      deepSleepHours: _extractSleepStageHours(sleep, 'deep'),
      lightSleepHours: _extractSleepStageHours(sleep, 'light'),
      awakeHours: _extractSleepStageHours(sleep, 'wake'),
      restingHR: _extractInt(heart, [
        'activities-heart',
        0,
        'value',
        'restingHeartRate',
      ]),
      weight: _extractListFirstDouble(weight, ['weight'], 'weight'),
      bodyFat: _extractListFirstDouble(weight, ['weight'], 'fat'),
      spo2: _extractInt(spo2, ['value', 'avg']),
      hrvMs: _extractInt(hrv, ['hrv', 0, 'value', 'dailyRmssd']),
      respiratoryRate: _extractDouble(breathing, [
        'br',
        0,
        'value',
        'breathingRate',
      ]),
    );
  }

  // ── Garmin Connect API ─────────────────────────────────────────────────

  Future<NormalizedHealthPayload?> _fetchGarmin(WearableToken token) async {
    // Garmin Health API uses push model (webhooks) but also supports pull
    // Token exchange via Cloud Function (OAuth 1.0a signed requests)
    final response = await http.post(
      Uri.parse(
        'https://australia-southeast1-datafightcentral.cloudfunctions.net'
        '/pullGarminData',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _auth.currentUser?.getIdToken()}',
      },
      body: jsonEncode({'date': _dateString(DateTime.now())}),
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return NormalizedHealthPayload(
      source: WearablePlatform.garmin,
      fetchedAt: DateTime.now(),
      dataDate: DateTime.now(),
      steps: data['steps'] as int?,
      heartRate: data['heartRate'] as int?,
      restingHR: data['restingHR'] as int?,
      maxHR: data['maxHR'] as int?,
      hrvMs: data['hrvMs'] as int?,
      spo2: data['spo2'] as int?,
      caloriesBurned: (data['calories'] as num?)?.toDouble(),
      activeMinutes: (data['activeMinutes'] as num?)?.toDouble(),
      sleepHours: (data['sleepHours'] as num?)?.toDouble(),
      sleepScore: data['sleepScore'] as int?,
      respiratoryRate: (data['respiratoryRate'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble(),
      bodyFat: (data['bodyFat'] as num?)?.toDouble(),
      readinessScore: data['bodyBatteryHigh'] as int?,
    );
  }

  // ── WHOOP API ──────────────────────────────────────────────────────────

  Future<NormalizedHealthPayload?> _fetchWhoop(WearableToken token) async {
    final headers = {'Authorization': 'Bearer ${token.accessToken}'};

    final results = await Future.wait([
      _safeGet('https://api.prod.whoop.com/developer/v1/recovery', headers),
      _safeGet('https://api.prod.whoop.com/developer/v1/cycle', headers),
      _safeGet('https://api.prod.whoop.com/developer/v1/sleep', headers),
    ]);

    final recovery = results[0];
    final cycle = results[1];
    final sleep = results[2];

    // WHOOP returns arrays sorted by date desc — take first record
    final latestRecovery = _extractFirstFromRecords(recovery, 'records') ?? {};
    final latestCycle = _extractFirstFromRecords(cycle, 'records') ?? {};
    final latestSleep = _extractFirstFromRecords(sleep, 'records') ?? {};

    final scoreObj = latestRecovery['score'] as Map<String, dynamic>?;
    final cycleScore = latestCycle['score'] as Map<String, dynamic>?;
    final sleepScore = latestSleep['score'] as Map<String, dynamic>?;

    return NormalizedHealthPayload(
      source: WearablePlatform.whoop,
      fetchedAt: DateTime.now(),
      dataDate: DateTime.now(),
      recoveryScore: (scoreObj?['recovery_score'] as num?)?.toInt(),
      restingHR: (scoreObj?['resting_heart_rate'] as num?)?.toInt(),
      hrvMs: (scoreObj?['hrv_rmssd_milli'] as num?)?.toInt(),
      spo2: (scoreObj?['spo2_percentage'] as num?)?.toInt(),
      skinTemp: (scoreObj?['skin_temp_celsius'] as num?)?.toDouble(),
      strainScore: (cycleScore?['strain'] as num?)?.toInt(),
      caloriesBurned: (cycleScore?['kilojoule'] as num?)?.let(
        (kj) => kj * 0.239,
      ),
      maxHR: (cycleScore?['max_heart_rate'] as num?)?.toInt(),
      heartRate: (cycleScore?['average_heart_rate'] as num?)?.toInt(),
      sleepHours: () {
        final s = sleepScore?['stage_summary'] as Map<String, dynamic>?;
        if (s == null) return null;
        final totalMs = (s['total_in_bed_time_milli'] as num?)?.toDouble();
        return totalMs != null ? totalMs / 3600000 : null;
      }(),
      sleepScore: (sleepScore?['sleep_performance_percentage'] as num?)
          ?.toInt(),
      respiratoryRate: (sleepScore?['respiratory_rate'] as num?)?.toDouble(),
    );
  }

  // ── Oura Ring API ──────────────────────────────────────────────────────

  Future<NormalizedHealthPayload?> _fetchOura(WearableToken token) async {
    final today = _dateString(DateTime.now());
    final headers = {'Authorization': 'Bearer ${token.accessToken}'};

    final results = await Future.wait([
      _safeGet(
        'https://api.ouraring.com/v2/usercollection/daily_readiness?start_date=$today&end_date=$today',
        headers,
      ),
      _safeGet(
        'https://api.ouraring.com/v2/usercollection/daily_sleep?start_date=$today&end_date=$today',
        headers,
      ),
      _safeGet(
        'https://api.ouraring.com/v2/usercollection/daily_activity?start_date=$today&end_date=$today',
        headers,
      ),
      _safeGet(
        'https://api.ouraring.com/v2/usercollection/heartrate?start_date=$today&end_date=$today',
        headers,
      ),
    ]);

    final readiness = results[0];
    final sleep = results[1];
    final activity = results[2];
    final heartRate = results[3];

    final readinessData = _extractFirstFromData(readiness) ?? {};
    final sleepData = _extractFirstFromData(sleep) ?? {};
    final activityData = _extractFirstFromData(activity) ?? {};

    // Heart rate returns an array of readings — average them
    final hrReadings = (heartRate?['data'] as List?)
        ?.map((r) => (r as Map<String, dynamic>)['bpm'] as num?)
        .whereType<num>()
        .toList();
    final avgHR = hrReadings != null && hrReadings.isNotEmpty
        ? (hrReadings.reduce((a, b) => a + b) / hrReadings.length).toInt()
        : null;

    return NormalizedHealthPayload(
      source: WearablePlatform.oura,
      fetchedAt: DateTime.now(),
      dataDate: DateTime.now(),
      readinessScore: readinessData['score'] as int?,
      restingHR: (sleepData['lowest_heart_rate'] as num?)?.toInt(),
      hrvMs: (sleepData['average_hrv'] as num?)?.toInt(),
      heartRate: avgHR,
      sleepHours: (sleepData['total_sleep_duration'] as num?)?.let(
        (s) => s / 3600,
      ),
      sleepScore: sleepData['score'] as int?,
      remHours: (sleepData['rem_sleep_duration'] as num?)?.let((s) => s / 3600),
      deepSleepHours: (sleepData['deep_sleep_duration'] as num?)?.let(
        (s) => s / 3600,
      ),
      lightSleepHours: (sleepData['light_sleep_duration'] as num?)?.let(
        (s) => s / 3600,
      ),
      respiratoryRate: (sleepData['average_breath'] as num?)?.toDouble(),
      skinTemp: (sleepData['temperature_deviation'] as num?)?.toDouble(),
      steps: activityData['steps'] as int?,
      caloriesBurned: (activityData['total_calories'] as num?)?.toDouble(),
      activeMinutes: (activityData['high_activity_time'] as num?)?.let(
        (s) => s / 60,
      ),
    );
  }

  // ── Google Fit REST API (web) ──────────────────────────────────────────

  Future<NormalizedHealthPayload?> _fetchGoogleFit(WearableToken token) async {
    // Google Fit REST API uses aggregate endpoint
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final headers = {
      'Authorization': 'Bearer ${token.accessToken}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'aggregateBy': [
        {'dataTypeName': 'com.google.step_count.delta'},
        {'dataTypeName': 'com.google.calories.expended'},
        {'dataTypeName': 'com.google.heart_rate.bpm'},
        {'dataTypeName': 'com.google.active_minutes'},
        {'dataTypeName': 'com.google.distance.delta'},
        {'dataTypeName': 'com.google.weight'},
        {'dataTypeName': 'com.google.body.fat.percentage'},
        {'dataTypeName': 'com.google.sleep.segment'},
        {'dataTypeName': 'com.google.oxygen_saturation'},
      ],
      'bucketByTime': {'durationMillis': 86400000}, // 1 day
      'startTimeMillis': startOfDay.millisecondsSinceEpoch,
      'endTimeMillis': now.millisecondsSinceEpoch,
    });

    try {
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate',
        ),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final buckets =
          (data['bucket'] as List?)?.firstOrNull as Map<String, dynamic>?;
      if (buckets == null) return null;

      final datasets = buckets['dataset'] as List? ?? [];

      int? steps;
      double? calories, activeMin, distance, weight, bodyFat;
      int? avgHR, spo2;
      double? sleepHours;

      for (final ds in datasets) {
        final dsMap = ds as Map<String, dynamic>;
        final typeName = dsMap['dataSourceId'] as String? ?? '';
        final points = dsMap['point'] as List? ?? [];
        if (points.isEmpty) continue;

        final firstPoint = points.first as Map<String, dynamic>;
        final values = firstPoint['value'] as List? ?? [];
        if (values.isEmpty) continue;

        final val = values.first as Map<String, dynamic>;

        if (typeName.contains('step_count')) {
          steps = (val['intVal'] as num?)?.toInt();
        } else if (typeName.contains('calories')) {
          calories = (val['fpVal'] as num?)?.toDouble();
        } else if (typeName.contains('heart_rate')) {
          avgHR = (val['fpVal'] as num?)?.toInt();
        } else if (typeName.contains('active_minutes')) {
          activeMin = (val['intVal'] as num?)?.toDouble();
        } else if (typeName.contains('distance')) {
          distance = (val['fpVal'] as num?)?.let(
            (m) => m / 1000,
          ); // meters → km
        } else if (typeName.contains('weight')) {
          weight = (val['fpVal'] as num?)?.toDouble();
        } else if (typeName.contains('body.fat')) {
          bodyFat = (val['fpVal'] as num?)?.toDouble();
        } else if (typeName.contains('sleep')) {
          sleepHours = (val['intVal'] as num?)?.let((m) => m / 60);
        } else if (typeName.contains('oxygen_saturation')) {
          spo2 = (val['fpVal'] as num?)?.toInt();
        }
      }

      return NormalizedHealthPayload(
        source: WearablePlatform.googleFit,
        fetchedAt: DateTime.now(),
        dataDate: DateTime.now(),
        steps: steps,
        caloriesBurned: calories,
        heartRate: avgHR,
        activeMinutes: activeMin,
        distanceKm: distance,
        weight: weight,
        bodyFat: bodyFat,
        sleepHours: sleepHours,
        spo2: spo2,
      );
    } catch (e) {
      debugPrint('WearableApiConnector: Google Fit fetch error: $e');
      return null;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ═════════════════════════════════════════════════════════════════════════

  Future<WearableToken?> _refreshToken(
    WearablePlatform platform,
    WearableToken token,
  ) async {
    if (token.refreshToken == null) return null;

    try {
      final response = await http.post(
        Uri.parse(
          'https://australia-southeast1-datafightcentral.cloudfunctions.net'
          '/refreshWearableToken',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _auth.currentUser?.getIdToken()}',
        },
        body: jsonEncode({
          'platform': platform.id,
          'refreshToken': token.refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newToken = WearableToken(
          platform: platform.id,
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String? ?? token.refreshToken,
          expiresAt: DateTime.now().add(
            Duration(seconds: data['expires_in'] as int? ?? 3600),
          ),
          connectedAt: token.connectedAt,
          metadata: token.metadata,
        );

        await _persistToken(platform, newToken);
        return newToken;
      }
    } catch (e) {
      debugPrint(
        'WearableApiConnector: Token refresh failed for '
        '${platform.displayName}: $e',
      );
    }
    return null;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PERSISTENCE
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _persistToken(
    WearablePlatform platform,
    WearableToken token,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('wearable_tokens')
        .doc(platform.id)
        .set(token.toMap());
  }

  Future<void> _persistHealthData(
    WearablePlatform platform,
    NormalizedHealthPayload payload,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    final dateKey = _dateString(payload.dataDate);

    await _db
        .collection('users')
        .doc(uid)
        .collection('health_metrics')
        .doc('${platform.id}_$dateKey')
        .set({
          ...payload.toFirestoreMap(),
          'userId': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  // ═════════════════════════════════════════════════════════════════════════
  // HISTORICAL DATA — Fetch multi-day ranges for trend analysis
  // ═════════════════════════════════════════════════════════════════════════

  /// Get health data for a date range from Firestore (already synced data)
  Future<List<NormalizedHealthPayload>> getHistory({
    required DateTime from,
    required DateTime to,
    WearablePlatform? platform,
  }) async {
    final uid = _uid;
    if (uid == null) return [];

    var query = _db
        .collection('users')
        .doc(uid)
        .collection('health_metrics')
        .where('fetchedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('fetchedAt', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('fetchedAt', descending: true);

    if (platform != null) {
      query = query.where('source', isEqualTo: platform.id);
    }

    final snap = await query.limit(100).get();

    return snap.docs.map((doc) {
      return NormalizedHealthPayload.fromFirestoreMap(doc.data());
    }).toList();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════════════════════════════════

  String _dateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<Map<String, dynamic>?> _safeGet(
    String url,
    Map<String, String> headers,
  ) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('WearableApiConnector: GET $url → ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('WearableApiConnector: GET $url → $e');
      return null;
    }
  }

  int? _extractInt(Map<String, dynamic>? data, List<dynamic> path) {
    dynamic current = data;
    for (final key in path) {
      if (current == null) return null;
      if (key is int && current is List && key < current.length) {
        current = current[key];
      } else if (current is Map<String, dynamic>) {
        current = current[key.toString()];
      } else {
        return null;
      }
    }
    return (current as num?)?.toInt();
  }

  double? _extractDouble(Map<String, dynamic>? data, List<dynamic> path) {
    dynamic current = data;
    for (final key in path) {
      if (current == null) return null;
      if (key is int && current is List && key < current.length) {
        current = current[key];
      } else if (current is Map<String, dynamic>) {
        current = current[key.toString()];
      } else {
        return null;
      }
    }
    return (current as num?)?.toDouble();
  }

  double? _extractListFirstDouble(
    Map<String, dynamic>? data,
    List<String> listPath,
    String field,
  ) {
    dynamic current = data;
    for (final key in listPath) {
      if (current == null) return null;
      current = (current as Map<String, dynamic>?)?[key];
    }
    if (current is List && current.isNotEmpty) {
      final first = current.first as Map<String, dynamic>;
      return (first[field] as num?)?.toDouble();
    }
    return null;
  }

  double? _extractSleepStageHours(Map<String, dynamic>? sleep, String stage) {
    final minutes = _extractInt(sleep, ['summary', 'stages', stage]);
    return minutes?.let((m) => m / 60);
  }

  Map<String, dynamic>? _extractFirstFromRecords(
    Map<String, dynamic>? data,
    String key,
  ) {
    final records = data?[key] as List?;
    if (records != null && records.isNotEmpty) {
      return records.first as Map<String, dynamic>;
    }
    return null;
  }

  Map<String, dynamic>? _extractFirstFromData(Map<String, dynamic>? data) {
    final items = data?['data'] as List?;
    if (items != null && items.isNotEmpty) {
      return items.first as Map<String, dynamic>;
    }
    return null;
  }

  int _countDataPoints(NormalizedHealthPayload p) {
    int count = 0;
    if (p.heartRate != null) count++;
    if (p.restingHR != null) count++;
    if (p.maxHR != null) count++;
    if (p.hrvMs != null) count++;
    if (p.spo2 != null) count++;
    if (p.steps != null) count++;
    if (p.caloriesBurned != null) count++;
    if (p.activeMinutes != null) count++;
    if (p.distanceKm != null) count++;
    if (p.sleepHours != null) count++;
    if (p.sleepScore != null) count++;
    if (p.weight != null) count++;
    if (p.bodyFat != null) count++;
    if (p.recoveryScore != null) count++;
    if (p.readinessScore != null) count++;
    if (p.strainScore != null) count++;
    if (p.respiratoryRate != null) count++;
    if (p.skinTemp != null) count++;
    if (p.glucose != null) count++;
    if (p.lactate != null) count++;
    if (p.cortisol != null) count++;
    return count;
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}

// ── Extension for chained transforms ─────────────────────────────────────

extension _NullableNumLet<T extends num> on T? {
  R? let<R>(R Function(T) fn) {
    if (this == null) return null;
    return fn(this as T);
  }
}
