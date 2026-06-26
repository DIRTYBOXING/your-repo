import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/payment_event_model.dart';
import '../models/paid_promotion_model.dart';
import 'ugc_consent_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC PAYMENT AUDIT SERVICE — Stripe Events, Promotions & Fairness
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Manages the paid-promotion lifecycle and payment event audit trail.
///
/// Architecture:
///   - DFC never custodially holds funds (Stripe Connect Direct charges)
///   - Platform fee collected via application_fee_amount
///   - All Stripe webhook events stored immutably for 90+ days
///   - Fairness rules enforced: max 25% single-promoter share / 24h window
///
/// Firestore collections:
///   paid_promotions/{promotionId}    — Active promotions
///   payment_events/{eventId}         — Stripe webhook audit log
///   prediction_audit/{predictionId}  — Neural prediction audit trail
///
/// ═══════════════════════════════════════════════════════════════════════════
class PaymentAuditService {
  final FirebaseFirestore _firestore;
  final UgcConsentService _consentService;

  PaymentAuditService({
    FirebaseFirestore? firestore,
    UgcConsentService? consentService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _consentService = consentService ?? UgcConsentService();

  // ── Collection references ─────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _promotions =>
      _firestore.collection('paid_promotions');

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('payment_events');

  CollectionReference<Map<String, dynamic>> get _predictionAudit =>
      _firestore.collection('prediction_audit');

  // ── Fairness constants ────────────────────────────────────────────
  /// No single promoter may occupy more than 25% of promoted impressions
  /// in a 24-hour window.
  static const double maxPromoterSharePercent = 0.25;

  /// Baseline minimum impressions allocated even to lowest-tier promoters.
  static const int baselineMinImpressions = 500;

  // ═══════════════════════════════════════════════════════════════════
  // CREATE PAID PROMOTION
  // ═══════════════════════════════════════════════════════════════════

  /// Create a new paid promotion after verifying UGC consent.
  /// Returns the promotion ID, or null if consent check fails.
  Future<String?> createPromotion({
    required String contentId,
    required String promoterId,
    required String promoterName,
    required int amountCents,
    required int applicationFeeCents,
    String currency = 'AUD',
    required PromotionSpendTier spendTier,
    required DateTime startTs,
    required DateTime endTs,
    String? stripeSessionId,
    String? stripePaymentIntentId,
    bool brainSignalUsed = false,
    String? rankingInputsHash,
  }) async {
    try {
      // ── Verify UGC consent before allowing promotion ──
      final consent = await _consentService.getActiveConsent(contentId);
      if (consent == null || !consent.allowsPaidPromotion) {
        debugPrint(
          'PaymentAuditService: content $contentId lacks paid-promotion consent',
        );
        return null;
      }

      // ── Check fairness: 24h promoter share cap ──
      final withinCap = await _checkPromoterFairness(promoterId);
      if (!withinCap) {
        debugPrint(
          'PaymentAuditService: promoter $promoterId exceeds 25% share cap',
        );
        return null;
      }

      final now = DateTime.now();
      final impressions = _calculateImpressionAllocation(spendTier);

      final promotion = PaidPromotionModel(
        id: '',
        contentId: contentId,
        promoterId: promoterId,
        promoterName: promoterName,
        stripeSessionId: stripeSessionId,
        stripePaymentIntentId: stripePaymentIntentId,
        amountCents: amountCents,
        applicationFeeCents: applicationFeeCents,
        currency: currency,
        spendTier: spendTier,
        status: PaidPromotionStatus.active,
        brainSignalUsed: brainSignalUsed,
        startTs: startTs,
        endTs: endTs,
        impressionsAllocated: impressions,
        rankingInputsHash: rankingInputsHash,
        ugcConsentId: consent.id,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _promotions.add(promotion.toFirestore());

      debugPrint(
        'PaymentAuditService: promotion created ${docRef.id} for content $contentId',
      );
      return docRef.id;
    } catch (e) {
      debugPrint('PaymentAuditService.createPromotion error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // RECORD STRIPE WEBHOOK EVENT
  // ═══════════════════════════════════════════════════════════════════

  /// Store a Stripe webhook event for audit.
  /// Idempotent — deduplicates by stripeEventId.
  Future<bool> recordPaymentEvent({
    required String stripeEventId,
    required PaymentEventType eventType,
    required Map<String, dynamic> payload,
    String? promotionId,
    String? connectedAccountId,
  }) async {
    try {
      // Idempotency: check if event already recorded
      final existing = await _events
          .where('stripeEventId', isEqualTo: stripeEventId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return true; // Already stored

      final event = PaymentEventModel(
        id: '',
        promotionId: promotionId,
        stripeEventId: stripeEventId,
        eventType: eventType,
        payload: payload,
        connectedAccountId: connectedAccountId,
        receivedTs: DateTime.now(),
      );

      await _events.add(event.toFirestore());
      return true;
    } catch (e) {
      debugPrint('PaymentAuditService.recordPaymentEvent error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // RECORD PREDICTION AUDIT
  // ═══════════════════════════════════════════════════════════════════

  /// Store a neural prediction audit record for transparency.
  Future<bool> recordPredictionAudit({
    required String userId,
    required String modelVersion,
    required String inputFeaturesHash,
    required String predictionLabel,
    required double confidence,
    bool usedForRanking = false,
    double? rankingConfidence,
    String? consentToken,
  }) async {
    try {
      final record = PredictionAuditModel(
        id: '',
        userId: userId,
        modelVersion: modelVersion,
        inputFeaturesHash: inputFeaturesHash,
        predictionLabel: predictionLabel,
        confidence: confidence,
        usedForRanking: usedForRanking,
        rankingConfidence: rankingConfidence,
        consentToken: consentToken,
        timestamp: DateTime.now(),
      );

      await _predictionAudit.add(record.toFirestore());
      return true;
    } catch (e) {
      debugPrint('PaymentAuditService.recordPredictionAudit error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONSENT REVOCATION → FORCE-STOP PROMOTIONS
  // ═══════════════════════════════════════════════════════════════════

  /// When UGC consent is revoked, force-stop all active promotions
  /// for that content within the 48-hour SLA.
  Future<int> forceStopPromotionsForContent(String contentId) async {
    try {
      final snap = await _promotions
          .where('contentId', isEqualTo: contentId)
          .where('status', isEqualTo: PaidPromotionStatus.active.name)
          .get();

      if (snap.docs.isEmpty) return 0;

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final doc in snap.docs) {
        batch.update(doc.reference, {
          'status': PaidPromotionStatus.consentRevoked.name,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      await batch.commit();

      debugPrint(
        'PaymentAuditService: force-stopped ${snap.docs.length} promotions for content $contentId',
      );
      return snap.docs.length;
    } catch (e) {
      debugPrint('PaymentAuditService.forceStopPromotionsForContent error: $e');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // QUERIES
  // ═══════════════════════════════════════════════════════════════════

  /// Get all active promotions (for feed badge rendering).
  Future<List<PaidPromotionModel>> getActivePromotions() async {
    try {
      final snap = await _promotions
          .where('status', isEqualTo: PaidPromotionStatus.active.name)
          .get();

      return snap.docs
          .map(PaidPromotionModel.fromFirestore)
          .where((p) => p.isLive)
          .toList();
    } catch (e) {
      debugPrint('PaymentAuditService.getActivePromotions error: $e');
      return [];
    }
  }

  /// Check if a specific content item has an active paid promotion.
  /// Returns the promotion model if found (for badge rendering).
  Future<PaidPromotionModel?> getActivePromotionForContent(
    String contentId,
  ) async {
    try {
      final snap = await _promotions
          .where('contentId', isEqualTo: contentId)
          .where('status', isEqualTo: PaidPromotionStatus.active.name)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      final promo = PaidPromotionModel.fromFirestore(snap.docs.first);
      return promo.isLive ? promo : null;
    } catch (e) {
      debugPrint('PaymentAuditService.getActivePromotionForContent error: $e');
      return null;
    }
  }

  /// Get promoter's promotion history.
  Future<List<PaidPromotionModel>> getPromoterHistory(String promoterId) async {
    try {
      final snap = await _promotions
          .where('promoterId', isEqualTo: promoterId)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs
          .map(PaidPromotionModel.fromFirestore)
          .toList();
    } catch (e) {
      debugPrint('PaymentAuditService.getPromoterHistory error: $e');
      return [];
    }
  }

  /// Get payment events for a specific promotion (audit trail).
  Future<List<PaymentEventModel>> getEventsForPromotion(
    String promotionId,
  ) async {
    try {
      final snap = await _events
          .where('promotionId', isEqualTo: promotionId)
          .orderBy('receivedTs', descending: true)
          .get();

      return snap.docs
          .map(PaymentEventModel.fromFirestore)
          .toList();
    } catch (e) {
      debugPrint('PaymentAuditService.getEventsForPromotion error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // FAIRNESS ENFORCEMENT
  // ═══════════════════════════════════════════════════════════════════

  /// Verify that a promoter hasn't exceeded the 25% share cap
  /// in the last 24 hours.
  Future<bool> _checkPromoterFairness(String promoterId) async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));

      // Get total impressions in last 24h
      final allSnap = await _promotions
          .where('status', isEqualTo: PaidPromotionStatus.active.name)
          .where('startTs', isGreaterThan: Timestamp.fromDate(cutoff))
          .get();

      if (allSnap.docs.isEmpty) return true; // No active promotions

      int totalImpressions = 0;
      int promoterImpressions = 0;

      for (final doc in allSnap.docs) {
        final data = doc.data();
        final allocated = data['impressionsAllocated'] as int? ?? 0;
        totalImpressions += allocated;
        if (data['promoterId'] == promoterId) {
          promoterImpressions += allocated;
        }
      }

      if (totalImpressions == 0) return true;

      final share = promoterImpressions / totalImpressions;
      return share < maxPromoterSharePercent;
    } catch (e) {
      debugPrint('PaymentAuditService._checkPromoterFairness error: $e');
      return true; // Fail open for now; tighten in production
    }
  }

  /// Calculate impression allocation based on spend tier.
  int _calculateImpressionAllocation(PromotionSpendTier tier) {
    switch (tier) {
      case PromotionSpendTier.grassroots:
        return baselineMinImpressions;
      case PromotionSpendTier.regional:
        return 2500;
      case PromotionSpendTier.national:
        return 10000;
      case PromotionSpendTier.headline:
        return 50000;
    }
  }

  /// Increment impressions served for a promotion.
  Future<void> recordImpressionServed(String promotionId) async {
    try {
      await _promotions.doc(promotionId).update({
        'impressionsServed': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('PaymentAuditService.recordImpressionServed error: $e');
    }
  }
}
