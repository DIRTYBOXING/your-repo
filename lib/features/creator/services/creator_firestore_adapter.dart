import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/creator_profile_model.dart';
import '../models/creator_earnings_model.dart';
import '../models/clip_analytics_model.dart';
import '../models/creator_insights_model.dart';

/// Firestore adapter for Creator Dashboard
/// Handles all Firestore reads/writes and stream subscriptions
class CreatorFirestoreAdapter {
  static const String _collectionName = 'creator_dashboards';

  final FirebaseFirestore _firestore;

  CreatorFirestoreAdapter({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Subscribe to creator profile stream
  Stream<CreatorProfile?> profileStream(String creatorId) {
    return _firestore
        .collection(_collectionName)
        .doc(creatorId)
        .collection('profile')
        .doc('info')
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return CreatorProfile.fromFirestore(doc.data() ?? {});
        })
        .handleError((e) {
          debugPrint('❌ Profile stream error: $e');
          return null;
        });
  }

  /// Subscribe to earnings stream for a specific month
  Stream<CreatorEarnings?> earningsStream(
    String creatorId,
    int month,
    int year,
  ) {
    final monthKey = '${month}_$year';
    return _firestore
        .collection(_collectionName)
        .doc(creatorId)
        .collection('earnings')
        .doc(monthKey)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return CreatorEarnings.fromFirestore(doc.data() ?? {});
        })
        .handleError((e) {
          debugPrint('❌ Earnings stream error: $e');
          return null;
        });
  }

  /// Subscribe to clips collection stream (recent clips)
  Stream<List<ClipAnalytics>> clipsStream(String creatorId, {int limit = 20}) {
    return _firestore
        .collection(_collectionName)
        .doc(creatorId)
        .collection('clips')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ClipAnalytics.fromFirestore(doc.data()))
              .toList();
        })
        .handleError((e) {
          debugPrint('❌ Clips stream error: $e');
          return [];
        });
  }

  /// Subscribe to ranking stream
  Stream<Map<String, dynamic>?> rankingStream(String creatorId) {
    return _firestore
        .collection(_collectionName)
        .doc(creatorId)
        .collection('ranking')
        .doc('global')
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return doc.data();
        })
        .handleError((e) {
          debugPrint('❌ Ranking stream error: $e');
          return null;
        });
  }

  /// Subscribe to badges stream
  Stream<List<String>> badgesStream(String creatorId) {
    return _firestore
        .collection(_collectionName)
        .doc(creatorId)
        .collection('badges')
        .doc('unlocked')
        .snapshots()
        .map((doc) {
          if (!doc.exists) return [];
          final data = doc.data() ?? {};
          return List<String>.from(data['badges'] ?? []);
        })
        .handleError((e) {
          debugPrint('❌ Badges stream error: $e');
          return [];
        });
  }

  /// Subscribe to insights stream
  Stream<CreatorInsights?> insightsStream(String creatorId) {
    return _firestore
        .collection(_collectionName)
        .doc(creatorId)
        .collection('insights')
        .doc('latest')
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return CreatorInsights.fromFirestore(doc.data() ?? {});
        })
        .handleError((e) {
          debugPrint('❌ Insights stream error: $e');
          return null;
        });
  }

  /// Check if creator data exists in Firestore
  Future<bool> creatorExists(String creatorId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(creatorId)
          .collection('profile')
          .doc('info')
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error checking creator existence: $e');
      return false;
    }
  }

  /// Record a conversion event (server-side validation required)
  Future<void> recordConversion({
    required String creatorId,
    required String clipId,
    required String conversionValue,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(creatorId)
          .collection('conversions')
          .add({
            'clipId': clipId,
            'value': conversionValue,
            'timestamp': FieldValue.serverTimestamp(),
            'metadata': metadata,
          });
      debugPrint('✅ Conversion recorded: $clipId');
    } catch (e) {
      debugPrint('❌ Error recording conversion: $e');
      rethrow;
    }
  }

  /// Telemetry: Log listener health
  Future<void> logListenerHealth({
    required String creatorId,
    required String status, // 'connected', 'disconnected', 'error'
    String? errorMessage,
  }) async {
    try {
      await _firestore.collection('telemetry/creator_listeners').add({
        'creatorId': creatorId,
        'status': status,
        'errorMessage': errorMessage,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Telemetry log failed: $e');
      // Don't fail the app on telemetry errors
    }
  }
}
