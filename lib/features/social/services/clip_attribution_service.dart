import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CLIP ATTRIBUTION SERVICE — Revenue Attribution & Creator Analytics
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Records user conversions from social clips → PPV purchases.
///
/// Tracks:
///   - Which clip drove the user to PPV
///   - Clip creator (if applicable)
///   - Fight purchased
///   - Timestamp of conversion
///   - Revenue value
///
/// Stored in:
///   ppv_events/{eventId}/event_sessions/{sessionId}/clip_conversions/{conversionId}
///
/// Later used for:
///   - Creator earnings calculation
///   - Clip ROI analysis
///   - Trending algorithm refinement
///   - Promoter analytics
///
/// ═══════════════════════════════════════════════════════════════════════════

class ClipAttributionService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Record a PPV conversion from a clip
  /// Called when user taps "Watch Full Fight on PPV" and completes purchase
  Future<String?> recordClipConversion(
    String eventId,
    String sessionId,
    String clipId,
    String fightId,
    String userId, {
    String? creatorId,
    double conversionValue = 14.99, // Default PPV price
  }) async {
    try {
      final conversionData = {
        'clipId': clipId,
        'fightId': fightId,
        'eventId': eventId,
        'sessionId': sessionId,
        'userId': userId,
        'creatorId': creatorId,
        'conversionValue': conversionValue,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
      };

      // Add to clip_conversions subcollection
      final conversionRef = _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('clip_conversions')
          .doc();

      await conversionRef.set(conversionData);

      // Increment PPV conversion count on the clip
      await _incrementClipPPVConversions(eventId, sessionId, clipId);

      // Track creator earnings if applicable
      if (creatorId != null) {
        await _recordCreatorEarning(creatorId, clipId, conversionValue);
      }

      debugPrint(
        '💰 [ATTRIBUTION] PPV conversion recorded:\n'
        '  ├─ Clip: $clipId\n'
        '  ├─ Fight: $fightId\n'
        '  ├─ User: $userId\n'
        '  ├─ Creator: ${creatorId ?? "N/A"}\n'
        '  └─ Value: \$${conversionValue.toStringAsFixed(2)}',
      );

      notifyListeners();
      return conversionRef.id;
    } catch (e) {
      debugPrint('❌ [ATTRIBUTION] Error recording conversion: $e');
      return null;
    }
  }

  /// Increment PPV conversion counter on clip engagement
  Future<void> _incrementClipPPVConversions(
    String eventId,
    String sessionId,
    String clipId,
  ) async {
    try {
      final clipPath =
          'ppv_events/$eventId/event_sessions/$sessionId/social_clips/$clipId';

      await _firestore.doc(clipPath).update({
        'engagement.ppvConversions': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        '📈 [ATTRIBUTION] PPV conversion incremented for clip: $clipId',
      );
    } catch (e) {
      debugPrint('❌ [ATTRIBUTION] Error incrementing PPV conversions: $e');
    }
  }

  /// Record creator earnings (for revenue sharing)
  Future<void> _recordCreatorEarning(
    String creatorId,
    String clipId,
    double amount,
  ) async {
    try {
      const creatorEarningsCollection = 'creator_earnings';

      await _firestore.runTransaction((transaction) async {
        final creatorEarningsRef = _firestore
            .collection(creatorEarningsCollection)
            .doc(creatorId);

        final snapshot = await transaction.get(creatorEarningsRef);

        if (!snapshot.exists) {
          transaction.set(creatorEarningsRef, {
            'creatorId': creatorId,
            'totalEarnings': amount,
            'clipCount': 1,
            'totalConversions': 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(creatorEarningsRef, {
            'totalEarnings': FieldValue.increment(amount),
            'totalConversions': FieldValue.increment(1),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      debugPrint(
        '👤 [ATTRIBUTION] Creator earnings recorded for $creatorId: \$$amount',
      );
    } catch (e) {
      debugPrint('❌ [ATTRIBUTION] Error recording creator earnings: $e');
    }
  }

  /// Get all conversions for a specific clip
  Future<List<Map<String, dynamic>>> getClipConversions(
    String eventId,
    String sessionId,
    String clipId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('clip_conversions')
          .where('clipId', isEqualTo: clipId)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ [ATTRIBUTION] Error getting clip conversions: $e');
      return [];
    }
  }

  /// Get all conversions for a specific creator
  Future<List<Map<String, dynamic>>> getCreatorConversions(
    String creatorId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('creator_conversions')
          .doc(creatorId)
          .collection('conversions')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ [ATTRIBUTION] Error getting creator conversions: $e');
      return [];
    }
  }

  /// Get conversion rate for a clip (conversions / views)
  Future<double> getClipConversionRate(
    String eventId,
    String sessionId,
    String clipId,
  ) async {
    try {
      final clipPath =
          'ppv_events/$eventId/event_sessions/$sessionId/social_clips/$clipId';
      final doc = await _firestore.doc(clipPath).get();

      if (!doc.exists) return 0.0;

      final data = doc.data() as Map<String, dynamic>;
      final views = (data['engagement']?['views'] ?? 0) as int;
      final ppvConversions =
          (data['engagement']?['ppvConversions'] ?? 0) as int;

      if (views == 0) return 0.0;
      return (ppvConversions / views) * 100; // Return as percentage
    } catch (e) {
      debugPrint('❌ [ATTRIBUTION] Error calculating conversion rate: $e');
      return 0.0;
    }
  }

  /// Get total revenue attributed to clips in an event
  Future<double> getEventClipRevenue(String eventId, String sessionId) async {
    try {
      final snapshot = await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('clip_conversions')
          .get();

      double totalRevenue = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['conversionValue'] ?? 0.0) as double;
      }

      debugPrint(
        '💵 [ATTRIBUTION] Total clip revenue for event: \$$totalRevenue',
      );
      return totalRevenue;
    } catch (e) {
      debugPrint('❌ [ATTRIBUTION] Error getting event revenue: $e');
      return 0.0;
    }
  }

  /// Get creator earnings summary
  Future<Map<String, dynamic>?> getCreatorEarnings(String creatorId) async {
    try {
      const creatorEarningsCollection = 'creator_earnings';
      final doc = await _firestore
          .collection(creatorEarningsCollection)
          .doc(creatorId)
          .get();

      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('❌ [ATTRIBUTION] Error getting creator earnings: $e');
      return null;
    }
  }

  /// Stream of conversion updates for real-time dashboard
  Stream<QuerySnapshot> getConversionsStream(String eventId, String sessionId) {
    return _firestore
        .collection('ppv_events')
        .doc(eventId)
        .collection('event_sessions')
        .doc(sessionId)
        .collection('clip_conversions')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  /// Check if user already converted from this clip
  Future<bool> hasUserConverted(
    String eventId,
    String sessionId,
    String clipId,
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('clip_conversions')
          .where('clipId', isEqualTo: clipId)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('⚠️ [ATTRIBUTION] Error checking user conversion: $e');
      return false;
    }
  }
}
