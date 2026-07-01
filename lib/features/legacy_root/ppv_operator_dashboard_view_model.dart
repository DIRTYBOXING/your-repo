import 'package:flutter/material.dart';
import 'ppv_operator_service.dart';
import 'ppv_live_stats_model.dart';
import 'ppv_incident_model.dart';
import 'ppv_entitlement_log_model.dart';

class PpvOperatorDashboardViewModel extends ChangeNotifier {
  final PpvOperatorService _ppvOperatorService = PpvOperatorService();
  final String eventId;

  PpvOperatorDashboardViewModel(this.eventId);

  Stream<PpvLiveStats> get liveStatsStream => _ppvOperatorService.getLiveStats(eventId);
  Stream<List<PpvIncident>> get incidentsStream => _ppvOperatorService.getIncidents(eventId);
  Stream<List<PpvEntitlementLog>> get entitlementLogsStream => _ppvOperatorService.getEntitlementLogs(eventId);

  Future<void> forceEntitlement(String userId) async {
    await _ppvOperatorService.forceEntitlement(eventId, userId);
    notifyListeners();
  }

  Future<void> revokeEntitlement(String userId) async {
    await _ppvOperatorService.revokeEntitlement(eventId, userId);
    notifyListeners();
  }

  Future<void> resendWebhook(String transactionId) async {
    await _ppvOperatorService.resendWebhook(eventId, transactionId);
    notifyListeners();
  }

  Future<void> pushEmergencyBanner(String message, int duration) async {
    await _ppvOperatorService.pushEmergencyBanner(eventId, message, duration);
    notifyListeners();
  }

  Future<void> enableBackupStream(String streamUrl) async {
    await _ppvOperatorService.enableBackupStream(eventId, streamUrl);
    notifyListeners();
  }

  Future<void> resolveIncident(String incidentId, String operatorId) async {
    await _ppvOperatorService.resolveIncident(eventId, incidentId, operatorId);
    notifyListeners();
  }
}
