import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SYSTEM HEALTH SERVICE
/// Streams the output of the Cloud Integrity Scanner to the Admin Console.
/// ═══════════════════════════════════════════════════════════════════════════
class SystemHealthService {
  final _firestore = FirebaseFirestore.instance;

  Stream<Map<String, dynamic>?> streamLatestReport() {
    return _firestore
        .collection('selfCheckReports')
        .doc('latest')
        .snapshots()
        .map((doc) {
          return doc.exists ? doc.data() : null;
        });
  }
}
