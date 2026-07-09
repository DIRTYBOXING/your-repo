import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// AI-generated insights and recommendations for a creator
class CreatorInsights extends Equatable {
  final String creatorId;
  final List<String>
  topClipTypes; // e.g., ['knockdown', 'submission', 'highlight']
  final List<int> bestPostHours; // e.g., [7, 8, 9, 20, 21] for best times
  final double avgConversionRate; // Creator's average conversion rate
  final double platformAvgConversionRate; // Platform average for comparison
  final List<String> recommendations; // AI recommendations
  final List<String> opportunities; // Trending opportunities
  final double
  benchmarkVsCreators; // Performance vs. similar creators (-100 to +100)
  final int recommendationScore; // 0-100 AI confidence in recommendations
  final DateTime lastUpdated;

  const CreatorInsights({
    required this.creatorId,
    required this.topClipTypes,
    required this.bestPostHours,
    required this.avgConversionRate,
    required this.platformAvgConversionRate,
    required this.recommendations,
    required this.opportunities,
    required this.benchmarkVsCreators,
    required this.recommendationScore,
    required this.lastUpdated,
  });

  /// Performance multiplier (how much better than average)
  double get performanceMultiplier {
    if (platformAvgConversionRate == 0) return 1.0;
    return avgConversionRate / platformAvgConversionRate;
  }

  /// Is creator above average?
  bool get isAboveAverage => performanceMultiplier > 1.0;

  /// Performance status for display
  String get performanceStatus {
    final multiplier = performanceMultiplier;
    if (multiplier >= 2.0) return 'TOP TIER 🌟';
    if (multiplier >= 1.5) return 'EXCELLENT ⭐';
    if (multiplier >= 1.0) return 'AVERAGE 👌';
    return 'DEVELOPING 📈';
  }

  /// Serialize to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'creatorId': creatorId,
      'topClipTypes': topClipTypes,
      'bestPostHours': bestPostHours,
      'avgConversionRate': avgConversionRate,
      'platformAvgConversionRate': platformAvgConversionRate,
      'recommendations': recommendations,
      'opportunities': opportunities,
      'benchmarkVsCreators': benchmarkVsCreators,
      'recommendationScore': recommendationScore,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Deserialize from Firestore
  factory CreatorInsights.fromFirestore(Map<String, dynamic> doc) {
    return CreatorInsights(
      creatorId: doc['creatorId'] ?? '',
      topClipTypes: List<String>.from(doc['topClipTypes'] ?? []),
      bestPostHours: List<int>.from(doc['bestPostHours'] ?? []),
      avgConversionRate: (doc['avgConversionRate'] ?? 0.0).toDouble(),
      platformAvgConversionRate: (doc['platformAvgConversionRate'] ?? 2.0)
          .toDouble(),
      recommendations: List<String>.from(doc['recommendations'] ?? []),
      opportunities: List<String>.from(doc['opportunities'] ?? []),
      benchmarkVsCreators: (doc['benchmarkVsCreators'] ?? 0.0).toDouble(),
      recommendationScore: doc['recommendationScore'] ?? 0,
      lastUpdated: doc['lastUpdated'] is Timestamp
          ? (doc['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Get best post hour formatted
  String bestPostHourFormatted() {
    if (bestPostHours.isEmpty) return 'Anytime';
    final hour = bestPostHours.first;
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  /// Get top clip type
  String get topClipType =>
      topClipTypes.isNotEmpty ? topClipTypes.first : 'Any';

  @override
  List<Object?> get props => [
    creatorId,
    topClipTypes,
    bestPostHours,
    avgConversionRate,
    platformAvgConversionRate,
    recommendations,
    opportunities,
    benchmarkVsCreators,
    recommendationScore,
    lastUpdated,
  ];
}
