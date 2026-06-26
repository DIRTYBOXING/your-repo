import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ECONOMY SERVICE
/// Fetches revenue events and payout statements for specific roles.
/// ═══════════════════════════════════════════════════════════════════════════
class EconomyService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getRevenueEventsForOwner(
    String ownerType,
    String ownerId,
  ) async {
    final snap = await _firestore
        .collection('revenueEvents')
        .where('participants.$ownerType', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  Future<Map<String, dynamic>?> getPayoutBalance(
    String ownerType,
    String ownerId,
  ) async {
    final id = '${ownerType}_$ownerId';
    final doc = await _firestore.collection('payoutBalances').doc(id).get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> getPayoutStatements(
    String ownerType,
    String ownerId,
  ) async {
    final snap = await _firestore
        .collection('payoutStatements')
        .where('ownerType', isEqualTo: ownerType)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('periodEnd', descending: true)
        .limit(50)
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }
}
