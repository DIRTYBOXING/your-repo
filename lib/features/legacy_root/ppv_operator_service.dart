import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'ppv_live_stats_model.dart';
import 'ppv_incident_model.dart';
import 'ppv_entitlement_log_model.dart';

class PpvOperatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Stream<PpvLiveStats> getLiveStats(String eventId) {
    return _firestore
        .collection('ppv_events')
        .doc(eventId)
        .collection('metrics')
        .doc('live')
        .snapshots()
        .map((snapshot) => PpvLiveStats.fromMap(snapshot.data()!));
  }

  Stream<List<PpvIncident>> getIncidents(String eventId) {
    return _firestore
        .collection('ppv_events')
        .doc(eventId)
        .collection('incidents')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PpvIncident.fromMap(doc.data()))
            .toList());
  }

  Stream<List<PpvEntitlementLog>> getEntitlementLogs(String eventId) {
    return _firestore
        .collection('ppv_events')
        .doc(eventId)
        .collection('entitlement_logs')
        .orderBy('timestamp', descending: true)
        .limit(20) // For performance, we only show the last 20 logs
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PpvEntitlementLog.fromMap(doc.data()))
            .toList());
  }

  Future<HttpsCallableResult> forceEntitlement(String eventId, String userId) {
    final callable = _functions.httpsCallable('forceEntitlement');
    return callable.call({'eventId': eventId, 'userId': userId});
  }

  Future<HttpsCallableResult> revokeEntitlement(String eventId, String userId) {
    final callable = _functions.httpsCallable('revokeEntitlement');
    return callable.call({'eventId': eventId, 'userId': userId});
  }

  Future<HttpsCallableResult> resendWebhook(String eventId, String transactionId) {
    final callable = _functions.httpsCallable('resendWebhook');
    return callable.call({'eventId': eventId, 'transactionId': transactionId});
  }

  Future<HttpsCallableResult> pushEmergencyBanner(String eventId, String message, int duration) {
    final callable = _functions.httpsCallable('pushEmergencyBanner');
    return callable.call({'eventId': eventId, 'message': message, 'duration': duration});
  }

  Future<HttpsCallableResult> enableBackupStream(String eventId, String streamUrl) {
    final callable = _functions.httpsCallable('enableBackupStream');
    return callable.call({'eventId': eventId, 'streamUrl': streamUrl});
  }

  Future<HttpsCallableResult> resolveIncident(String eventId, String incidentId, String operatorId) {
    final callable = _functions.httpsCallable('resolveIncident');
    return callable.call({'eventId': eventId, 'incidentId': incidentId, 'operatorId': operatorId});
  }
}
