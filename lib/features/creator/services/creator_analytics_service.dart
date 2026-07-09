import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/clip_analytics_model.dart';

/// Deep dive analytics for individual clips
class CreatorAnalyticsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get detailed analytics for a single clip
  Future<ClipAnalytics?> getClipAnalytics(String clipId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('social_clips')
          .where('id', isEqualTo: clipId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return ClipAnalytics.fromFirestore(snapshot.docs.first.data());
    } catch (e) {
      debugPrint('❌ Error getting clip analytics: $e');
      return null;
    }
  }

  /// Get all clips for a creator with analytics
  Future<List<ClipAnalytics>> getCreatorClips(String creatorId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('social_clips')
          .where('creatorId', isEqualTo: creatorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ClipAnalytics.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting creator clips: $e');
      return [];
    }
  }

  /// Get clips by type (knockdown, submission, etc.)
  Future<List<ClipAnalytics>> getClipsByType(
    String creatorId,
    String clipType,
  ) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('social_clips')
          .where('creatorId', isEqualTo: creatorId)
          .where('clipType', isEqualTo: clipType)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ClipAnalytics.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting clips by type: $e');
      return [];
    }
  }

  /// Get trending clips (score > 7.0)
  Future<List<ClipAnalytics>> getTrendingClips(String creatorId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('social_clips')
          .where('creatorId', isEqualTo: creatorId)
          .where('isTrending', isEqualTo: true)
          .orderBy('trendingScore', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ClipAnalytics.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting trending clips: $e');
      return [];
    }
  }

  /// Calculate engagement trend for a clip over time
  Future<Map<String, dynamic>> getClipEngagementTrend(String clipId) async {
    try {
      final clip = await getClipAnalytics(clipId);
      if (clip == null) return {};

      // Return engagement metrics
      return {
        'clipId': clipId,
        'views': clip.views,
        'likes': clip.likes,
        'shares': clip.shares,
        'conversions': clip.conversions,
        'engagementRatio': clip.engagementRatio,
        'conversionRate': clip.conversionRate,
        'trendingScore': clip.trendingScore,
      };
    } catch (e) {
      debugPrint('❌ Error getting engagement trend: $e');
      return {};
    }
  }

  /// Get best performing clip type for creator
  Future<String?> getBestPerformingClipType(String creatorId) async {
    try {
      final clips = await getCreatorClips(creatorId);
      if (clips.isEmpty) return null;

      // Group by clip type and calculate average conversion rate
      final typeStats = <String, List<ClipAnalytics>>{};
      for (final clip in clips) {
        if (!typeStats.containsKey(clip.clipType)) {
          typeStats[clip.clipType] = [];
        }
        typeStats[clip.clipType]!.add(clip);
      }

      // Find best performing type
      String? bestType;
      double bestAvgConversion = 0.0;

      typeStats.forEach((type, typeClips) {
        final avgConversion =
            typeClips.fold<double>(
              0.0,
              (sum, clip) => sum + clip.conversionRate,
            ) /
            typeClips.length;

        if (avgConversion > bestAvgConversion) {
          bestAvgConversion = avgConversion;
          bestType = type;
        }
      });

      return bestType;
    } catch (e) {
      debugPrint('❌ Error getting best clip type: $e');
      return null;
    }
  }

  /// Get average metrics for all creator clips
  Future<Map<String, double>> getAverageClipMetrics(String creatorId) async {
    try {
      final clips = await getCreatorClips(creatorId);
      if (clips.isEmpty) {
        return {
          'avgViews': 0.0,
          'avgLikes': 0.0,
          'avgShares': 0.0,
          'avgConversions': 0.0,
          'avgConversionRate': 0.0,
          'avgTrendingScore': 0.0,
        };
      }

      final avgViews =
          clips.fold<double>(0.0, (sum, clip) => sum + clip.views) /
          clips.length;
      final avgLikes =
          clips.fold<double>(0.0, (sum, clip) => sum + clip.likes) /
          clips.length;
      final avgShares =
          clips.fold<double>(0.0, (sum, clip) => sum + clip.shares) /
          clips.length;
      final avgConversions =
          clips.fold<double>(0.0, (sum, clip) => sum + clip.conversions) /
          clips.length;
      final avgConversionRate =
          clips.fold<double>(0.0, (sum, clip) => sum + clip.conversionRate) /
          clips.length;
      final avgTrendingScore =
          clips.fold<double>(0.0, (sum, clip) => sum + clip.trendingScore) /
          clips.length;

      return {
        'avgViews': avgViews,
        'avgLikes': avgLikes,
        'avgShares': avgShares,
        'avgConversions': avgConversions,
        'avgConversionRate': avgConversionRate,
        'avgTrendingScore': avgTrendingScore,
      };
    } catch (e) {
      debugPrint('❌ Error getting average metrics: $e');
      return {};
    }
  }
}
