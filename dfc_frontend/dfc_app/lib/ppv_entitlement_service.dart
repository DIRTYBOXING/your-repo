import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PpvEntitlementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Listens to the entitlements collection to verify access to a specific PPV scope
  Stream<bool> watchEntitlement(String targetId) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    // Matches the exact string formatted in your stripe_webhooks.ts fulfillment logic
    final scope = 'event:$targetId';

    return _firestore
        .collection('entitlements')
        .where('userId', isEqualTo: user.uid)
        .where('scope', isEqualTo: scope)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }
}