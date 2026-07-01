import 'package:flutter/foundation.dart';
import '../services/oauth_service.dart';
import '../../api_service.dart';

enum WearableState { disconnected, authenticating, syncing, connected, error }

/// V12 CONTROLLER: OAUTH WEARABLE SYNC PIPELINE
class WearableController extends ChangeNotifier {
  final OAuthWearableService oauthService;
  final ApiService apiService;

  WearableState _state = WearableState.disconnected;
  WearableState get state => _state;

  Map<String, dynamic>? _latestMetrics;
  Map<String, dynamic>? get latestMetrics => _latestMetrics;

  WearableController({required this.oauthService, required this.apiService});

  Future<void> connectWhoop() async {
    _state = WearableState.authenticating;
    notifyListeners();

    try {
      final authenticated = await oauthService.authenticateWhoop();
      if (authenticated) {
        await syncData();
      }
    } catch (e) {
      _state = WearableState.error;
      notifyListeners();
    }
  }

  Future<void> syncData() async {
    _state = WearableState.syncing;
    notifyListeners();

    try {
      _latestMetrics = await oauthService.fetchLatestRecovery();

      // Push synced data to GOLD layer to update the global dashboard readiness score
      await apiService.callFunction('ingestWearableSync', {
        'metrics': _latestMetrics,
      });

      _state = WearableState.connected;
    } catch (e) {
      _state = WearableState.error;
    } finally {
      notifyListeners();
    }
  }
}
