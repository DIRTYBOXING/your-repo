import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SalesService {
  final HttpsCallable _calcSplit = FirebaseFunctions.instance.httpsCallable(
    'calcRevenueSplit',
  );
  final HttpsCallable _createEntitlement = FirebaseFunctions.instance
      .httpsCallable('createEntitlement');
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> purchase({
    required String eventId,
    required String userId,
    required int amountCents,
    required String tierId,
    String purchaseType = 'ppv',
    String? promotionId,
    Map<String, dynamic>? metadata,
  }) async {
    final splitResult = await _calcSplit.call({
      'eventId': eventId,
      'saleAmount': amountCents,
      'tierId': tierId,
    });

    final split = Map<String, dynamic>.from(splitResult.data as Map);

    final purchaseRef = _db.collection('ppv_checkout_sessions').doc();
    final requestId = purchaseRef.id;
    await purchaseRef.set({
      'userId': userId,
      'eventId': eventId,
      'purchaseType': purchaseType,
      'amountCents': amountCents,
      'platformShare': split['platformShare'],
      'promoterShare': split['promoterShare'],
      'tierId': tierId,
      'promotionId': promotionId,
      'metadata': metadata ?? const <String, dynamic>{},
      'requestId': requestId,
      'createdBy': 'SalesService.purchase',
      'source': metadata?['source'] ?? 'app_checkout',
      'status': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': FieldValue.serverTimestamp(),
    });

    final entitlementResult = await _createEntitlement.call({
      'userId': userId,
      'eventId': eventId,
      'amountCents': amountCents,
      'tierId': tierId,
      'purchaseType': purchaseType,
      'platformShare': split['platformShare'],
      'promoterShare': split['promoterShare'],
      'purchaseId': purchaseRef.id,
      'requestId': requestId,
      'promotionId': promotionId,
      'metadata': {'source': 'app_checkout', ...?metadata},
    });

    await _db.collection('analytics').add({
      'event': 'purchase_completed',
      'userId': userId,
      'meta': {
        'eventId': eventId,
        'tierId': tierId,
        'purchaseType': purchaseType,
        'promotionId': promotionId,
      },
      'ts': FieldValue.serverTimestamp(),
    });

    final entitlementData = Map<String, dynamic>.from(
      entitlementResult.data as Map,
    );

    return {
      'entitlementId': entitlementData['entitlementId'],
      'purchaseId': purchaseRef.id,
      'split': split,
    };
  }

  Future<List<Map<String, dynamic>>> bootstrapEventSalesEngine({
    required String eventId,
    required String promoterId,
    required String title,
    required String description,
    required DateTime eventDate,
    required int basePriceCents,
    String sportType = 'MMA',
    String? posterUrl,
  }) async {
    final variants = _defaultOfferVariants(
      eventId: eventId,
      title: title,
      description: description,
      eventDate: eventDate,
      basePriceCents: basePriceCents,
      sportType: sportType,
      posterUrl: posterUrl,
    );

    final batch = _db.batch();
    for (final variant in variants) {
      final doc = _db.collection('promotions').doc(variant['id'] as String);
      batch.set(doc, {
        ...variant,
        'eventId': eventId,
        'promoterId': promoterId,
        'active': true,
        'requiresReview': true,
        'reviewStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    batch.set(_db.collection('analytics').doc(), {
      'event': 'sales_engine_bootstrap',
      'userId': promoterId,
      'meta': {
        'eventId': eventId,
        'variantCount': variants.length,
        'basePriceCents': basePriceCents,
      },
      'ts': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return variants;
  }

  List<Map<String, dynamic>> _defaultOfferVariants({
    required String eventId,
    required String title,
    required String description,
    required DateTime eventDate,
    required int basePriceCents,
    required String sportType,
    String? posterUrl,
  }) {
    final fullShowPrice = basePriceCents;
    final highlightPrice = (basePriceCents * 0.35).round();
    final bundlePrice = (basePriceCents * 1.55).round();
    final isoDate = eventDate.toIso8601String();

    return [
      {
        'id': 'offer-$eventId-full-show',
        'type': 'ppv_full_show',
        'title': '$title Full Show',
        'description': description,
        'priceCents': fullShowPrice,
        'uiLabel': 'Buy Full Show',
        'templateKey': 'neon_arena',
        'aiScore': 0.82,
        'predictedConversion': 0.11,
        'requiresReview': true,
        'reviewStatus': 'pending',
        'metadata': {
          'eventDate': isoDate,
          'sportType': sportType,
          'posterUrl': posterUrl,
        },
      },
      {
        'id': 'offer-$eventId-highlight-pack',
        'type': 'highlight_pack',
        'title': '$title Highlights',
        'description':
            'Fast replay package for viewers who want every finish and shareable clip.',
        'priceCents': highlightPrice,
        'uiLabel': 'Buy Highlights',
        'templateKey': 'velocity_stripes',
        'aiScore': 0.71,
        'predictedConversion': 0.16,
        'requiresReview': true,
        'reviewStatus': 'pending',
        'metadata': {
          'eventDate': isoDate,
          'sportType': sportType,
          'posterUrl': posterUrl,
        },
      },
      {
        'id': 'offer-$eventId-vip-bundle',
        'type': 'vip_bundle',
        'title': '$title VIP Bundle',
        'description':
            'PPV access, poster drop, sponsor perks, and backstage-style premium upsell.',
        'priceCents': bundlePrice,
        'uiLabel': 'Unlock VIP Bundle',
        'templateKey': 'legacy_gold',
        'aiScore': 0.88,
        'predictedConversion': 0.07,
        'requiresReview': true,
        'reviewStatus': 'pending',
        'metadata': {
          'eventDate': isoDate,
          'sportType': sportType,
          'posterUrl': posterUrl,
        },
      },
    ];
  }
}
