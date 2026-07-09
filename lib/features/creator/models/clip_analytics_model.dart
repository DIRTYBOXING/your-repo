import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Deep analytics for a single clip created by a creator
class ClipAnalytics extends Equatable {
  final String clipId;
  final String creatorId;
  final String clipTitle;
  final String clipType; // knockdown, submission, highlight, etc.
  final DateTime createdAt;
  final int views;
  final int likes;
  final int shares;
  final int comments;
  final int conversions; // PPV conversions from this clip
  final double earningsFromClip;
  final double trendingScore; // 0-10
  final bool isTrending; // trending if score > 7.0
  final double conversionRate; // percentage
  final String fightId;
  final String eventId;
  final int round;
  final DateTime? lastEngagementUpdate;

  const ClipAnalytics({
    required this.clipId,
    required this.creatorId,
    required this.clipTitle,
    required this.clipType,
    required this.createdAt,
    required this.views,
    required this.likes,
    required this.shares,
    required this.comments,
    required this.conversions,
    required this.earningsFromClip,
    required this.trendingScore,
    required this.isTrending,
    required this.conversionRate,
    required this.fightId,
    required this.eventId,
    required this.round,
    this.lastEngagementUpdate,
  });

  /// Calculate engagement ratio
  double get engagementRatio {
    if (views == 0) return 0.0;
    return ((likes + shares + comments) / views) * 100.0;
  }

  /// Get trending status indicator
  String get trendingStatus {
    if (trendingScore >= 9.0) return 'VIRAL 🔥🔥';
    if (trendingScore >= 7.0) return 'TRENDING 🔥';
    if (trendingScore >= 5.0) return 'HOT 🌡️';
    return 'ACTIVE';
  }

  /// Format views as readable string
  String formattedViews() {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  /// Serialize to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'clipId': clipId,
      'creatorId': creatorId,
      'clipTitle': clipTitle,
      'clipType': clipType,
      'createdAt': Timestamp.fromDate(createdAt),
      'views': views,
      'likes': likes,
      'shares': shares,
      'comments': comments,
      'conversions': conversions,
      'earningsFromClip': earningsFromClip,
      'trendingScore': trendingScore,
      'isTrending': isTrending,
      'conversionRate': conversionRate,
      'fightId': fightId,
      'eventId': eventId,
      'round': round,
      'lastEngagementUpdate': lastEngagementUpdate == null
          ? null
          : Timestamp.fromDate(lastEngagementUpdate!),
    };
  }

  /// Deserialize from Firestore
  factory ClipAnalytics.fromFirestore(Map<String, dynamic> doc) {
    return ClipAnalytics(
      clipId: doc['clipId'] ?? '',
      creatorId: doc['creatorId'] ?? '',
      clipTitle: doc['clipTitle'] ?? 'Untitled',
      clipType: doc['clipType'] ?? 'highlight',
      createdAt: doc['createdAt'] is Timestamp
          ? (doc['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      views: doc['views'] ?? 0,
      likes: doc['likes'] ?? 0,
      shares: doc['shares'] ?? 0,
      comments: doc['comments'] ?? 0,
      conversions: doc['conversions'] ?? 0,
      earningsFromClip: (doc['earningsFromClip'] ?? 0.0).toDouble(),
      trendingScore: (doc['trendingScore'] ?? 0.0).toDouble(),
      isTrending: doc['isTrending'] ?? false,
      conversionRate: (doc['conversionRate'] ?? 0.0).toDouble(),
      fightId: doc['fightId'] ?? '',
      eventId: doc['eventId'] ?? '',
      round: doc['round'] ?? 1,
      lastEngagementUpdate: doc['lastEngagementUpdate'] is Timestamp
          ? (doc['lastEngagementUpdate'] as Timestamp).toDate()
          : null,
    );
  }

  /// Copy with modifications
  ClipAnalytics copyWith({
    int? views,
    int? likes,
    int? shares,
    int? comments,
    int? conversions,
    double? earningsFromClip,
    double? trendingScore,
    bool? isTrending,
    double? conversionRate,
    DateTime? lastEngagementUpdate,
  }) {
    return ClipAnalytics(
      clipId: clipId,
      creatorId: creatorId,
      clipTitle: clipTitle,
      clipType: clipType,
      createdAt: createdAt,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      shares: shares ?? this.shares,
      comments: comments ?? this.comments,
      conversions: conversions ?? this.conversions,
      earningsFromClip: earningsFromClip ?? this.earningsFromClip,
      trendingScore: trendingScore ?? this.trendingScore,
      isTrending: isTrending ?? this.isTrending,
      conversionRate: conversionRate ?? this.conversionRate,
      fightId: fightId,
      eventId: eventId,
      round: round,
      lastEngagementUpdate: lastEngagementUpdate ?? this.lastEngagementUpdate,
    );
  }

  @override
  List<Object?> get props => [
    clipId,
    creatorId,
    views,
    likes,
    shares,
    conversions,
    trendingScore,
    isTrending,
  ];
}
