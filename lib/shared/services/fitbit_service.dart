import 'package:flutter/foundation.dart';
import 'wearable_api_connector_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FITBIT SERVICE — Facade over WearableApiConnectorService
/// ═══════════════════════════════════════════════════════════════════════════
///
/// SECURITY: All OAuth credentials and token exchange happen server-side
/// via Cloud Functions. This class delegates to WearableApiConnectorService.
///
/// NEVER store client_id / client_secret in client code.
/// ═══════════════════════════════════════════════════════════════════════════
class FitBitService {
  final WearableApiConnectorService _connector = WearableApiConnectorService();

  bool get isConnected => _connector.isConnected(WearablePlatform.fitbit);

  NormalizedHealthPayload? get latestData =>
      _connector.latestData(WearablePlatform.fitbit);

  DateTime? get lastSyncTime =>
      _connector.lastSyncTime(WearablePlatform.fitbit);

  /// Get the Fitbit OAuth authorization URL
  /// User opens this in browser/webview → redirect back with auth code
  String getAuthorizationUrl() =>
      _connector.getAuthorizationUrl(WearablePlatform.fitbit);

  /// Exchange auth code for tokens (server-side via Cloud Function)
  Future<bool> exchangeAuthCode(String code) =>
      _connector.exchangeAuthCode(WearablePlatform.fitbit, code);

  /// Pull latest activity, sleep, heart rate, SpO2, HRV data
  Future<NormalizedHealthPayload?> fetchActivityData() async {
    final payload = await _connector.pullLatest(WearablePlatform.fitbit);
    if (payload == null) {
      debugPrint('FitBitService: No data returned from Fitbit API');
    }
    return payload;
  }

  /// Disconnect and revoke Fitbit access
  Future<void> disconnect() => _connector.disconnect(WearablePlatform.fitbit);
}
