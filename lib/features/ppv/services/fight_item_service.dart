import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/fight_item_model.dart';
import 'ppv_access_service.dart';

/// Service for managing individual fight purchases
class FightItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PPVAccessService _ppvAccessService = PPVAccessService();

  /// Create individual fight item
  Future<String> createFightItem(FightItem fightItem) async {
    final docRef = await _firestore
        .collection('fight_items')
        .add(fightItem.toFirestore());
    return docRef.id;
  }

  /// Get all fights for a specific event
  Stream<List<FightItem>> getEventFights(String ppvEventId) {
    return _firestore
        .collection('fight_items')
        .where('ppvEventId', isEqualTo: ppvEventId)
        .orderBy('priority', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(FightItem.fromFirestore).toList(),
        );
  }

  /// Get single fight item
  Future<FightItem?> getFightItem(String fightItemId) async {
    final doc = await _firestore
        .collection('fight_items')
        .doc(fightItemId)
        .get();

    if (!doc.exists) return null;
    return FightItem.fromFirestore(doc);
  }

  /// Purchase individual fight
  Future<FightItemPurchase> purchaseFight({
    required String fightItemId,
    required String stripePaymentId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final fightItem = await getFightItem(fightItemId);
    if (fightItem == null) throw Exception('Fight not found');

    // Check if already purchased
    final hasAccess = await hasFightAccess(currentUser.uid, fightItemId);
    if (hasAccess) {
      throw Exception('Already purchased this fight');
    }

    // Create purchase record
    final purchase = FightItemPurchase(
      id: '',
      fightItemId: fightItemId,
      ppvEventId: fightItem.ppvEventId,
      userId: currentUser.uid,
      userEmail: currentUser.email ?? '',
      amountPaid: fightItem.price,
      stripePaymentId: stripePaymentId,
      purchasedAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection('fight_item_purchases')
        .add(purchase.toFirestore());

    // Update fight stats
    await _firestore.collection('fight_items').doc(fightItemId).update({
      'purchaseCount': FieldValue.increment(1),
    });

    return purchase.copyWith(id: docRef.id);
  }

  /// Check if user has access to specific fight
  Future<bool> hasFightAccess(String userId, String fightItemId) async {
    // Check individual purchase
    final individualPurchase = await _firestore
        .collection('fight_item_purchases')
        .where('userId', isEqualTo: userId)
        .where('fightItemId', isEqualTo: fightItemId)
        .limit(1)
        .get();

    if (individualPurchase.docs.isNotEmpty) return true;

    // Check if user owns full event (which includes all fights)
    final fightItem = await getFightItem(fightItemId);
    if (fightItem == null) return false;

    return _ppvAccessService.hasAccessForUser(userId, fightItem.ppvEventId);
  }

  /// Get user's purchased fights
  Stream<List<FightItemPurchase>> getUserFightPurchases(String userId) {
    return _firestore
        .collection('fight_item_purchases')
        .where('userId', isEqualTo: userId)
        .orderBy('purchasedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(FightItemPurchase.fromFirestore)
              .toList(),
        );
  }

  /// Get video URL if user has access
  Future<String?> getFightVideoUrl(String userId, String fightItemId) async {
    final hasAccess = await hasFightAccess(userId, fightItemId);
    if (!hasAccess) return null;

    final fightItem = await getFightItem(fightItemId);
    return fightItem?.videoUrl;
  }

  /// Create PPV package
  Future<String> createPackage(PPVPackage package) async {
    final docRef = await _firestore
        .collection('ppv_packages')
        .add(package.toFirestore());
    return docRef.id;
  }

  /// Get active packages
  Stream<List<PPVPackage>> getActivePackages() {
    return _firestore
        .collection('ppv_packages')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PPVPackage.fromFirestore)
              .toList(),
        );
  }

  /// Get recommended price for fight based on priority
  static double getRecommendedPrice(FightPriority priority) {
    switch (priority) {
      case FightPriority.mainEvent:
        return 15.0;
      case FightPriority.coMain:
        return 10.0;
      case FightPriority.featured:
        return 7.0;
      case FightPriority.undercard:
        return 5.0;
    }
  }

  /// Bulk create fights for an event
  Future<List<String>> createEventFights({
    required String ppvEventId,
    required List<Map<String, dynamic>> fightsData,
  }) async {
    final fightIds = <String>[];

    for (final fightData in fightsData) {
      final fightItem = FightItem(
        id: '',
        ppvEventId: ppvEventId,
        fightNumber: fightData['fightNumber'],
        fighter1Name: fightData['fighter1Name'],
        fighter1Id: fightData['fighter1Id'] ?? '',
        fighter2Name: fightData['fighter2Name'],
        fighter2Id: fightData['fighter2Id'] ?? '',
        weightClass: fightData['weightClass'] ?? 'Open',
        title: fightData['title'],
        description: fightData['description'] ?? '',
        price: fightData['price'] ?? getRecommendedPrice(fightData['priority']),
        videoUrl: fightData['videoUrl'],
        thumbnailUrl: fightData['thumbnailUrl'],
        durationSeconds: fightData['durationSeconds'] ?? 0,
        result: fightData['result'],
        priority: fightData['priority'] ?? FightPriority.undercard,
        createdAt: DateTime.now(),
      );

      final id = await createFightItem(fightItem);
      fightIds.add(id);
    }

    return fightIds;
  }

  /// Calculate bundle savings
  double calculateBundleSavings(List<FightItem> fights, double bundlePrice) {
    final individualTotal = fights.fold<double>(
      0,
      (runningTotal, fight) => runningTotal + fight.price,
    );
    return individualTotal - bundlePrice;
  }
}

// Extension methods
extension FightItemPurchaseExtension on FightItemPurchase {
  FightItemPurchase copyWith({
    String? id,
    String? fightItemId,
    String? ppvEventId,
    String? userId,
    String? userEmail,
    double? amountPaid,
    String? stripePaymentId,
    DateTime? purchasedAt,
  }) {
    return FightItemPurchase(
      id: id ?? this.id,
      fightItemId: fightItemId ?? this.fightItemId,
      ppvEventId: ppvEventId ?? this.ppvEventId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      amountPaid: amountPaid ?? this.amountPaid,
      stripePaymentId: stripePaymentId ?? this.stripePaymentId,
      purchasedAt: purchasedAt ?? this.purchasedAt,
    );
  }
}
