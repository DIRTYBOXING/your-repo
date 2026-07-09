import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/creator_insights_model.dart';

/// AI-driven insights engine
/// Generates recommendations, identifies trending opportunities, provides benchmarking
class CreatorInsightsEngine extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get or generate insights for a creator
  Future<CreatorInsights?> getInsights(String creatorId) async {
    try {
      final doc = await _firestore
          .collection('creator_dashboards')
          .doc(creatorId)
          .collection('insights')
          .doc('latest')
          .get();

      if (doc.exists) {
        return CreatorInsights.fromFirestore(doc.data() ?? {});
      }

      // Generate new insights if not found
      return await generateInsights(creatorId);
    } catch (e) {
      debugPrint('❌ Error getting insights: $e');
      return null;
    }
  }

  /// Generate fresh insights for a creator
  Future<CreatorInsights?> generateInsights(String creatorId) async {
    try {
      // Fetch creator's clips
      final clipsSnapshot = await _firestore
          .collectionGroup('social_clips')
          .where('creatorId', isEqualTo: creatorId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      if (clipsSnapshot.docs.isEmpty) {
        return null;
      }

      final clips = clipsSnapshot.docs;

      // Analyze best clip types
      final typePerformance = <String, List<double>>{};
      final postHourFrequency = <int, int>{};

      for (final clipDoc in clips) {
        final data = clipDoc.data();
        final clipType = data['clipType'] ?? 'unknown';
        final conversionRate = (data['conversionRate'] ?? 0.0).toDouble();
        final createdAt = data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now();

        // Track conversion rates by type
        if (!typePerformance.containsKey(clipType)) {
          typePerformance[clipType] = [];
        }
        typePerformance[clipType]!.add(conversionRate);

        // Track post hours
        final hour = createdAt.hour;
        postHourFrequency[hour] = (postHourFrequency[hour] ?? 0) + 1;
      }

      // Find top clip types (by average conversion)
      final topTypes = _getTopClipTypes(typePerformance);

      // Find best post hours
      final bestHours = _getBestPostHours(postHourFrequency);

      // Calculate average conversion rate
      final avgConversionRate = _calculateAverageConversion(clips);

      // Get platform average for benchmarking
      final platformAvg = await _getPlatformAverageConversion();

      // Generate recommendations
      final recommendations = _generateRecommendations(
        topTypes,
        avgConversionRate,
        platformAvg,
      );

      // Identify trending opportunities
      final opportunities = await _identifyTrendingOpportunities();

      // Calculate benchmark vs. peers
      final benchmark = _calculateBenchmark(avgConversionRate, platformAvg);

      // Calculate recommendation confidence
      final confidence = _calculateRecommendationConfidence(clips.length);

      final insights = CreatorInsights(
        creatorId: creatorId,
        topClipTypes: topTypes,
        bestPostHours: bestHours,
        avgConversionRate: avgConversionRate,
        platformAvgConversionRate: platformAvg,
        recommendations: recommendations,
        opportunities: opportunities,
        benchmarkVsCreators: benchmark,
        recommendationScore: confidence,
        lastUpdated: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('creator_dashboards')
          .doc(creatorId)
          .collection('insights')
          .doc('latest')
          .set(insights.toFirestore());

      return insights;
    } catch (e) {
      debugPrint('❌ Error generating insights: $e');
      return null;
    }
  }

  /// Get top performing clip types
  List<String> _getTopClipTypes(Map<String, List<double>> typePerformance) {
    final sorted = typePerformance.entries.toList()
      ..sort((a, b) {
        final avgA =
            a.value.fold<double>(0, (sum, val) => sum + val) / a.value.length;
        final avgB =
            b.value.fold<double>(0, (sum, val) => sum + val) / b.value.length;
        return avgB.compareTo(avgA);
      });

    return sorted.take(3).map((e) => e.key).toList();
  }

  /// Get best post hours based on frequency
  List<int> _getBestPostHours(Map<int, int> hourFrequency) {
    final sorted = hourFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => e.key).toList();
  }

  /// Calculate average conversion rate
  double _calculateAverageConversion(List<QueryDocumentSnapshot> clips) {
    if (clips.isEmpty) return 0.0;

    final total = clips.fold<double>(0, (sum, doc) {
      return sum + ((doc.data() as Map)['conversionRate'] ?? 0.0).toDouble();
    });

    return total / clips.length;
  }

  /// Get platform average conversion rate
  Future<double> _getPlatformAverageConversion() async {
    try {
      final doc = await _firestore
          .collection('platform_metrics')
          .doc('global')
          .get();

      return ((doc.data()?['avgConversionRate'] ?? 2.0) as num).toDouble();
    } catch (e) {
      return 2.0; // Default fallback
    }
  }

  /// Generate recommendations based on data
  List<String> _generateRecommendations(
    List<String> topTypes,
    double avgConversion,
    double platformAvg,
  ) {
    final recs = <String>[];

    if (topTypes.isNotEmpty) {
      recs.add('Focus on ${topTypes.first} clips — your best performer');
    }

    if (avgConversion > platformAvg * 1.5) {
      recs.add('You convert 50%+ better than average creators — keep it up!');
    } else if (avgConversion < platformAvg * 0.5) {
      recs.add('Try analyzing top creator content to improve your conversion');
    }

    if (topTypes.length > 1) {
      recs.add(
        'Experiment with ${topTypes[1]} clips — your 2nd best type is also strong',
      );
    }

    return recs;
  }

  /// Identify currently trending opportunities
  Future<List<String>> _identifyTrendingOpportunities() async {
    try {
      final snapshot = await _firestore
          .collection('trending_topics')
          .where('isActive', isEqualTo: true)
          .orderBy('trendingScore', descending: true)
          .limit(5)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['topic'] as String? ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
    } catch (e) {
      return ['Knockdown moments', 'Submission technique', 'Comeback stories'];
    }
  }

  /// Calculate benchmark vs. similar creators
  double _calculateBenchmark(double creatorAvg, double platformAvg) {
    if (platformAvg == 0) return 0;
    return ((creatorAvg - platformAvg) / platformAvg) * 100;
  }

  /// Calculate confidence in recommendations (0-100)
  int _calculateRecommendationConfidence(int clipsCount) {
    if (clipsCount < 5) return 40;
    if (clipsCount < 20) return 60;
    if (clipsCount < 50) return 80;
    return 95;
  }
}
