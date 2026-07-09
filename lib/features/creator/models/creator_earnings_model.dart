import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Monthly earnings breakdown for a creator
class CreatorEarnings extends Equatable {
  final String creatorId;
  final int month; // 1-12
  final int year; // 2026, 2027, etc
  final double totalEarnings;
  final int clipsGenerated;
  final int totalViews;
  final int totalLikes;
  final int totalShares;
  final int totalConversions;
  final double conversionRate; // percentage: 0.0-100.0
  final double avgEarningsPerClip;
  final DateTime nextPayoutDate;
  final bool payoutProcessed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreatorEarnings({
    required this.creatorId,
    required this.month,
    required this.year,
    required this.totalEarnings,
    required this.clipsGenerated,
    required this.totalViews,
    required this.totalLikes,
    required this.totalShares,
    required this.totalConversions,
    required this.conversionRate,
    required this.avgEarningsPerClip,
    required this.nextPayoutDate,
    required this.payoutProcessed,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate conversion rate from conversions and views
  static double calculateConversionRate(int conversions, int views) {
    if (views == 0) return 0.0;
    return (conversions / views) * 100.0;
  }

  /// Calculate average earnings per clip
  static double calculateAvgEarningsPerClip(
    double totalEarnings,
    int clipsCount,
  ) {
    if (clipsCount == 0) return 0.0;
    return totalEarnings / clipsCount;
  }

  /// Serialize to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'creatorId': creatorId,
      'month': month,
      'year': year,
      'totalEarnings': totalEarnings,
      'clipsGenerated': clipsGenerated,
      'totalViews': totalViews,
      'totalLikes': totalLikes,
      'totalShares': totalShares,
      'totalConversions': totalConversions,
      'conversionRate': conversionRate,
      'avgEarningsPerClip': avgEarningsPerClip,
      'nextPayoutDate': Timestamp.fromDate(nextPayoutDate),
      'payoutProcessed': payoutProcessed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Deserialize from Firestore
  factory CreatorEarnings.fromFirestore(Map<String, dynamic> doc) {
    return CreatorEarnings(
      creatorId: doc['creatorId'] ?? '',
      month: doc['month'] ?? 1,
      year: doc['year'] ?? 2026,
      totalEarnings: (doc['totalEarnings'] ?? 0.0).toDouble(),
      clipsGenerated: doc['clipsGenerated'] ?? 0,
      totalViews: doc['totalViews'] ?? 0,
      totalLikes: doc['totalLikes'] ?? 0,
      totalShares: doc['totalShares'] ?? 0,
      totalConversions: doc['totalConversions'] ?? 0,
      conversionRate: (doc['conversionRate'] ?? 0.0).toDouble(),
      avgEarningsPerClip: (doc['avgEarningsPerClip'] ?? 0.0).toDouble(),
      nextPayoutDate: doc['nextPayoutDate'] is Timestamp
          ? (doc['nextPayoutDate'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 7)),
      payoutProcessed: doc['payoutProcessed'] ?? false,
      createdAt: doc['createdAt'] is Timestamp
          ? (doc['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: doc['updatedAt'] is Timestamp
          ? (doc['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Format earnings as currency string
  String formattedEarnings() {
    return '\$${totalEarnings.toStringAsFixed(2)}';
  }

  /// Format conversion rate as percentage
  String formattedConversionRate() {
    return '${conversionRate.toStringAsFixed(1)}%';
  }

  @override
  List<Object?> get props => [
    creatorId,
    month,
    year,
    totalEarnings,
    clipsGenerated,
    totalViews,
    totalConversions,
    payoutProcessed,
  ];
}
