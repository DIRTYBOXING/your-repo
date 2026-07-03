import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Placeholder for DeviceInfo, assuming it provides static device type and platform.
class DeviceInfo {
  static String get type => kIsWeb ? 'web' : 'mobile';
  static String get platform =>
      kIsWeb ? 'web' : 'mobile'; // Or more specific like 'android', 'ios'
}

// Placeholder for Session, assuming it provides a static session ID.
class Session {
  static String get id => DateTime.now().microsecondsSinceEpoch.toString();
}

/// DFC PPV Analytics Spine
///
/// Emits structured PPV funnel events + maintains a live metrics document
/// for the Operator Dashboard.
class Analytics {
  Analytics._();

  static String _region() {
    // Replace with geo IP / device region later.
    return 'unknown';
  }

  static Future<void> ppvEvent({
    required String funnelStep,
    required String eventId,
    required String userId, // Changed to required
    String? promoterId,
    String? fighterId,
    String? affiliateId,
    String? campaignId, // Added campaignId
    String? entitlementSource,
    double? funnelLatencyMs,
    double? price,
    String? currency,
    String? paymentProvider,
    Map<String, dynamic>? extra,
  }) async {
    // userId is now required, so no null check needed here.
    // If FirebaseAuth.instance.currentUser?.uid is used, it must be passed explicitly.

    final payload = <String, dynamic>{
      'event_id': eventId,
      'user_id': userId,
      'funnel_step': funnelStep,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'device_type': DeviceInfo.type, // Using DeviceInfo
      'platform': DeviceInfo.platform, // Using DeviceInfo
      'region': _region(),
      'session_id': Session.id, // Using Session
      'promoter_id': ?promoterId,
      'fighter_id': ?fighterId,
      'affiliate_id': ?affiliateId,
      'campaign_id': ?campaignId, // Added campaign_id
      'entitlement_source': ?entitlementSource,
      'funnel_latency_ms': ?funnelLatencyMs,
      'price': ?price,
      'currency': ?currency,
      'payment_provider': ?paymentProvider,
      ...?extra,
    };

    final firestore = FirebaseFirestore.instance;

    // 1) Append to the event stream (immutable log)
    await firestore.collection('ppv_events/$eventId/events').add(payload);

    // 2) Update a live metrics doc for dashboard consumption
    // NOTE: This is intentionally minimal. Operator dashboard can compute
    // more from the event stream later.
    final doc = firestore
        .collection('ppv_events/$eventId/metrics/live')
        .doc('stats');

    final updates = <String, dynamic>{
      'updated_at': FieldValue.serverTimestamp(),
      if (funnelStep == 'watch_start')
        'unique_viewers': FieldValue.increment(1), // Added unique_viewers
      if (funnelStep == 'watch_start') 'live_viewers': FieldValue.increment(1),
      if (funnelStep == 'watch_complete')
        'live_viewers': FieldValue.increment(-1),
      if (funnelStep == 'gate_access_granted')
        'purchases': FieldValue.increment(1),
      if (funnelStep == 'gate_access_granted' && price != null)
        'revenue': FieldValue.increment(price),
    };

    // Merge so we don't clobber documents.
    await doc.set(updates, SetOptions(merge: true));
  }
}
