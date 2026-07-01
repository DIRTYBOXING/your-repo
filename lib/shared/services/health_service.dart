import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/genie/genie_api_service.dart';
import '../../features/genie/genie_persona.dart';

/// HealthService monitors app health, performance, and self-maintenance.
/// It can be extended to log errors, check dependencies, and trigger self-repair.
class HealthService with ChangeNotifier {
  bool _isHealthy = true;
  String _lastError = '';
  String _genieAdvice = '';
  Timer? _healthCheckTimer;

  bool get isHealthy => _isHealthy;
  String get lastError => _lastError;
  String get genieAdvice => _genieAdvice;

  HealthService() {
    _startHealthChecks();
  }

  void _startHealthChecks() {
    _healthCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => checkHealth(),
    );
  }

  Future<void> checkHealth() async {
    // Example: Check for errors, outdated packages, performance issues
    _isHealthy = true;
    _lastError = '';
    // Genie-powered health suggestion
    final genieResponse = await GenieApiService.generateCreativeCombo(
      description: 'App health check',
      persona: geniePersonas.first,
    );
    _genieAdvice = genieResponse.hypeText;
    notifyListeners();
  }

  Future<void> logError(String error) async {
    _isHealthy = false;
    _lastError = error;
    // Genie-powered error response
    final genieResponse = await GenieApiService.generateCreativeCombo(
      description: 'Error: $error',
      persona: geniePersonas.first,
    );
    _genieAdvice = genieResponse.hypeText;
    notifyListeners();
    // Optionally send error to remote logging or Genie
  }

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    super.dispose();
  }
}
