import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EXPERIMENT ANALYTICS SERVICE — Module 18 A/B Widget Experiments
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Implements the widget A/B experiment plan from experiments/widget_ab_plan.md
/// - 7 standard experiment events (impression → click → checkout → payment → ticket)
/// - Deterministic hash-based variant assignment (session_id or user_id)
/// - PPV storefront + link-in-bio widget surface integration
/// - Firestore-backed: writes to `experiment_events` collection
///
/// Background aggregation: functions/ab/ab_aggregation.js runs every 15 min.

class ExperimentAnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _eventsCollection = 'experiment_events';

  // ── Active experiment ───────────────────────────────────────────────

  /// The current widget A/B experiment ID.
  static const String widgetExperimentId = 'widget_ab_2026_06';

  /// Variant labels that match the experiment plan.
  static const Map<String, String> variantLabels = {
    'control': 'B0 — Current (baseline)',
    'variant_a': 'A — One-Tap Buy Now',
    'variant_b': 'B — Two-Step Confirmation Modal',
  };

  /// Weight distribution (matches plan: 33/33/33 or 50/50).
  static const Map<String, double> variantWeights = {
    'variant_a': 0.50,
    'variant_b': 0.50,
    // 'control': 0.0,  // disabled until baseline exists
  };

  final _random = Random();

  // ── Deterministic assignment ────────────────────────────────────────

  /// Returns a stable variant assignment for [sessionId] under [experimentId].
  ///
  /// Uses SHA-256 of (experimentId + sessionId) modulo 100,
  /// then maps to the weighted variant bucket.
  /// This guarantees the same session always gets the same variant.
  String assignVariant({
    required String experimentId,
    required String sessionId,
  }) {
    final raw = '$experimentId:$sessionId';
    final hash = sha256.convert(utf8.encode(raw));
    // Take first 4 bytes of the hash as an integer for bucketing
    final bucket = (hash.bytes[0] << 24 |
            hash.bytes[1] << 16 |
            hash.bytes[2] << 8 |
            hash.bytes[3]) %
        100;

    double cumulative = 0;
    for (final entry in variantWeights.entries) {
      cumulative += entry.value * 100;
      if (bucket < cumulative) {
        return entry.key;
      }
    }
    return variantWeights.keys.first;
  }

  // ── Event emitter ───────────────────────────────────────────────────

  /// Emit an experiment event to Firestore.
  ///
  /// Events defined in the plan:
  /// 1. widget_impression
  /// 2. widget_click
  /// 3. checkout_initiated
  /// 4. payment_intent_created
  /// 5. payment_succeeded
  /// 6. ticket_issued
  /// 7. widget_experiment_assignment
  Future<void> emitEvent({
    required String eventType,
    required String variant,
    String? promoterId,
    String? skuId,
    String? refCode,
    required String sessionId,
    String? eventId,
    String? buildInfo,
    String env = 'prod',
    Map<String, dynamic>? extra,
  }) async {
    final doc = {
      'experimentId': widgetExperimentId,
      'eventType': eventType,
      'variant': variant,
      'promoterId': promoterId ?? 'unknown',
      'skuId': skuId ?? 'unknown',
      'refCode': refCode ?? 'unknown',
      'sessionId': sessionId,
      'eventId': eventId ?? 'evt_${DateTime.now().millisecondsSinceEpoch}',
      'buildInfo':
          buildInfo ?? 'module_18_${DateTime.now().toIso8601String()}',
      'env': env,
      'timestamp': DateTime.now().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
      if (extra != null) ...extra,
    };

    await _db.collection(_eventsCollection).add(doc);

    debugPrint(
      '[ExperimentAnalytics] $eventType | variant=$variant | session=$sessionId',
    );
  }

  // ── Convenience wrappers ────────────────────────────────────────────

  Future<void> recordImpression({
    required String variant,
    required String sessionId,
    String? promoterId,
    String? skuId,
    String? refCode,
  }) =>
      emitEvent(
        eventType: 'widget_impression',
        variant: variant,
        promoterId: promoterId,
        skuId: skuId,
        refCode: refCode,
        sessionId: sessionId,
      );

  Future<void> recordClick({
    required String variant,
    required String sessionId,
    String? promoterId,
    String? skuId,
    String? refCode,
  }) =>
      emitEvent(
        eventType: 'widget_click',
        variant: variant,
        promoterId: promoterId,
        skuId: skuId,
        refCode: refCode,
        sessionId: sessionId,
      );

  Future<void> recordCheckoutInitiated({
    required String variant,
    required String sessionId,
    String? promoterId,
    String? skuId,
    String? refCode,
  }) =>
      emitEvent(
        eventType: 'checkout_initiated',
        variant: variant,
        promoterId: promoterId,
        skuId: skuId,
        refCode: refCode,
        sessionId: sessionId,
      );

  Future<void> recordPaymentIntentCreated({
    required String variant,
    required String sessionId,
    String? promoterId,
    String? skuId,
    String? refCode,
    Map<String, dynamic>? extra,
  }) =>
      emitEvent(
        eventType: 'payment_intent_created',
        variant: variant,
        promoterId: promoterId,
        skuId: skuId,
        refCode: refCode,
        sessionId: sessionId,
        extra: extra,
      );

  Future<void> recordPaymentSucceeded({
    required String variant,
    required String sessionId,
    String? promoterId,
    String? skuId,
    String? refCode,
    Map<String, dynamic>? extra,
  }) =>
      emitEvent(
        eventType: 'payment_succeeded',
        variant: variant,
        promoterId: promoterId,
        skuId: skuId,
        refCode: refCode,
        sessionId: sessionId,
        extra: extra,
      );

  Future<void> recordTicketIssued({
    required String variant,
    required String sessionId,
    String? promoterId,
    String? skuId,
    String? refCode,
    Map<String, dynamic>? extra,
  }) =>
      emitEvent(
        eventType: 'ticket_issued',
        variant: variant,
        promoterId: promoterId,
        skuId: skuId,
        refCode: refCode,
        sessionId: sessionId,
        extra: extra,
      );

  Future<void> recordAssignment({
    required String variant,
    required String sessionId,
    String? promoterId,
  }) =>
      emitEvent(
        eventType: 'widget_experiment_assignment',
        variant: variant,
        promoterId: promoterId,
        sessionId: sessionId,
      );

  // ── Create/ensure experiment exists ─────────────────────────────────

  /// Seeds the widget_ab_2026_06 experiment in Firestore if it doesn't exist.
  Future<void> seedExperiment() async {
    final doc = await _db
        .collection('experiments')
        .doc(widgetExperimentId)
        .get();

    if (doc.exists) {
      debugPrint(
        '[ExperimentAnalytics] Experiment $widgetExperimentId already exists',
      );
      return;
    }

    await _db.collection('experiments').doc(widgetExperimentId).set({
      'id': widgetExperimentId,
      'name': 'Widget A/B — One-Click Social Buy',
      'description':
          'Tests one-tap Buy Now (A) vs two-step confirmation modal (B) on '
          'PPV storefront and link-in-bio widgets. Primary metric: '
          'conversion rate (click → paid within 10 min).',
      'status': 'running',
      'active': true,
      'variants': [
        {
          'id': 'variant_a',
          'label': 'A — One-Tap Buy Now',
          'weight': 50,
          'config': <String, dynamic>{
            'ctaText': 'Buy Now — Instant Access',
            'modal': false,
            'skipConfirmation': true,
          },
        },
        {
          'id': 'variant_b',
          'label': 'B — Two-Step Confirmation',
          'weight': 50,
          'config': <String, dynamic>{
            'ctaText': 'View Details & Buy',
            'modal': true,
            'skipConfirmation': false,
          },
        },
      ],
      'targetMetric': 'conversion_click_to_paid_10m',
      'trafficAllocation': 1.0,
      'startedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'targetAudience': 'social_traffic',
      'totalParticipants': 0,
      'aggregatedStats': [],
    });

    debugPrint(
      '[ExperimentAnalytics] Seeded experiment $widgetExperimentId',
    );
  }

  // ── Singleton ───────────────────────────────────────────────────────

  static final ExperimentAnalyticsService _instance =
      ExperimentAnalyticsService._internal();
  factory ExperimentAnalyticsService() => _instance;
  ExperimentAnalyticsService._internal();
}
