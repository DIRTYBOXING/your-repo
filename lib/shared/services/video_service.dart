import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// 🎥 VIDEO SERVICE — Creator Studio Backend
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Handles video uploads, analytics, and creator content management.
///
/// Features:
/// • Video upload and storage
/// • View tracking
/// • Engagement analytics
/// • Trending algorithm
/// • Creator metrics
/// • Video discovery
///
/// ═══════════════════════════════════════════════════════════════════════════
class VideoService {
  final FirebaseFirestore _firestore;

  VideoService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // VIDEO UPLOAD & MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create video post
  Future<String> createVideo({
    required String ownerId,
    required String ownerName,
    required String title,
    required String description,
    required String videoUrl,
    String? thumbnailUrl,
    List<String> tags = const [],
    String? gymId,
    String? eventId,
    String? campaignId,
  }) async {
    final doc = await _firestore.collection('videos').add({
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'tags': tags,
      'gymId': gymId,
      'eventId': eventId,
      'campaignId': campaignId,
      'views': 0,
      'likes': 0,
      'comments': 0,
      'shares': 0,
      'watchTime': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'published',
    });

    // Also create a post in feed
    final resolvedThumbnailUrl = thumbnailUrl ?? '';
    await _firestore.collection('posts').add({
      'userId': ownerId,
      'userDisplayName': ownerName,
      'content': '$title\n\n$description',
      'postType': 'video',
      'mediaUrls': [videoUrl],
      'thumbnailUrl': resolvedThumbnailUrl.isNotEmpty
          ? resolvedThumbnailUrl
          : null,
      'imageUrl': resolvedThumbnailUrl.isNotEmpty ? resolvedThumbnailUrl : null,
      'videoId': doc.id,
      'likes': 0,
      'commentCount': 0,
      'shareCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      ...?(gymId == null ? null : {'taggedGymId': gymId}),
      ...?(campaignId == null ? null : {'campaignId': campaignId}),
    });

    return doc.id;
  }

  /// Get creator's videos
  Stream<List<VideoData>> streamCreatorVideos(String creatorId) {
    return _firestore
        .collection('videos')
        .where('ownerId', isEqualTo: creatorId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VideoData.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Get video by ID
  Future<VideoData?> getVideo(String videoId) async {
    final doc = await _firestore.collection('videos').doc(videoId).get();
    if (!doc.exists) return null;
    return VideoData.fromFirestore(doc.id, doc.data()!);
  }

  /// Record video view
  Future<void> recordView(String videoId, String userId) async {
    await _firestore.collection('videos').doc(videoId).update({
      'views': FieldValue.increment(1),
    });

    // Track unique view
    await _firestore.collection('video_views').add({
      'videoId': videoId,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Update watch time
  Future<void> updateWatchTime(String videoId, int secondsWatched) async {
    await _firestore.collection('videos').doc(videoId).update({
      'watchTime': FieldValue.increment(secondsWatched),
    });
  }

  /// Delete video
  Future<void> deleteVideo(String videoId) async {
    await _firestore.collection('videos').doc(videoId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get creator analytics
  Future<CreatorAnalytics> getCreatorAnalytics(String creatorId) async {
    // Get all creator's videos
    final videosSnapshot = await _firestore
        .collection('videos')
        .where('ownerId', isEqualTo: creatorId)
        .get();

    int totalViews = 0;
    int totalLikes = 0;
    int totalComments = 0;
    int totalShares = 0;
    int totalWatchTime = 0;

    for (final doc in videosSnapshot.docs) {
      final data = doc.data();
      totalViews += (data['views'] as int? ?? 0);
      totalLikes += (data['likes'] as int? ?? 0);
      totalComments += (data['comments'] as int? ?? 0);
      totalShares += (data['shares'] as int? ?? 0);
      totalWatchTime += (data['watchTime'] as int? ?? 0);
    }

    // Get follower count
    final userDoc = await _firestore.collection('users').doc(creatorId).get();
    final followers = (userDoc.data()?['followers'] as List?)?.length ?? 0;

    // Calculate engagement rate
    final engagementRate = totalViews > 0
        ? ((totalLikes + totalComments + totalShares) / totalViews * 100)
        : 0.0;

    return CreatorAnalytics(
      totalVideos: videosSnapshot.size,
      totalViews: totalViews,
      totalLikes: totalLikes,
      totalComments: totalComments,
      totalShares: totalShares,
      totalWatchTime: totalWatchTime,
      followers: followers,
      engagementRate: engagementRate,
    );
  }

  /// Get video performance (last 7 days)
  Future<List<DailyStats>> getVideoPerformance(String videoId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final viewsSnapshot = await _firestore
        .collection('video_views')
        .where('videoId', isEqualTo: videoId)
        .where('timestamp', isGreaterThan: weekAgo)
        .get();

    // Group by day
    final dailyViews = <String, int>{};
    for (final doc in viewsSnapshot.docs) {
      final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
      final dateKey = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
      dailyViews[dateKey] = (dailyViews[dateKey] ?? 0) + 1;
    }

    return dailyViews.entries
        .map((e) => DailyStats(date: e.key, views: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get trending videos
  Stream<List<VideoData>> streamTrendingVideos({int limit = 20}) {
    return _firestore
        .collection('videos')
        .where('status', isEqualTo: 'published')
        .orderBy('views', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VideoData.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Search videos by tags
  Future<List<VideoData>> searchVideosByTag(String tag) async {
    final snapshot = await _firestore
        .collection('videos')
        .where('tags', arrayContains: tag)
        .where('status', isEqualTo: 'published')
        .orderBy('views', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => VideoData.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SPONSORSHIP SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get sponsorship offers for creator
  Stream<List<SponsorshipOffer>> streamSponsorshipOffers(String creatorId) {
    return _firestore
        .collection('sponsorship_offers')
        .where('targetCreatorId', isEqualTo: creatorId)
        .where('status', isEqualTo: 'pending')
        .orderBy('offerAmount', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SponsorshipOffer.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Accept sponsorship offer
  Future<void> acceptSponsorshipOffer(String offerId, String creatorId) async {
    await _firestore.collection('sponsorship_offers').doc(offerId).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    // Create notification for brand
    final offer = await _firestore
        .collection('sponsorship_offers')
        .doc(offerId)
        .get();
    final brandId = offer.data()?['brandId'];

    if (brandId != null) {
      await _firestore
          .collection('notifications')
          .doc(brandId)
          .collection('items')
          .add({
            'type': 'sponsorship_accepted',
            'title': 'Sponsorship Accepted',
            'body': 'A creator accepted your sponsorship offer',
            'offerId': offerId,
            'creatorId': creatorId,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
    }
  }

  /// Decline sponsorship offer
  Future<void> declineSponsorshipOffer(String offerId) async {
    await _firestore.collection('sponsorship_offers').doc(offerId).update({
      'status': 'declined',
      'declinedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRAINING JOURNAL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create training log
  Future<void> logTrainingSession({
    required String fighterId,
    required String discipline,
    required int rounds,
    required int conditioningMinutes,
    String? notes,
    double? weight,
  }) async {
    await _firestore.collection('training_logs').add({
      'fighterId': fighterId,
      'discipline': discipline,
      'rounds': rounds,
      'conditioningMinutes': conditioningMinutes,
      'notes': notes,
      'weight': weight,
      'date': FieldValue.serverTimestamp(),
    });
  }

  /// Get training logs (last 30 days)
  Future<List<TrainingLog>> getTrainingLogs(String fighterId) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final snapshot = await _firestore
        .collection('training_logs')
        .where('fighterId', isEqualTo: fighterId)
        .where('date', isGreaterThan: thirtyDaysAgo)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TrainingLog.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class VideoData {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final String videoUrl;
  final String? thumbnailUrl;
  final List<String> tags;
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final DateTime createdAt;

  VideoData({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.tags,
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.createdAt,
  });

  factory VideoData.fromFirestore(String id, Map<String, dynamic> data) {
    return VideoData(
      id: id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      shares: data['shares'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class CreatorAnalytics {
  final int totalVideos;
  final int totalViews;
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final int totalWatchTime;
  final int followers;
  final double engagementRate;

  CreatorAnalytics({
    required this.totalVideos,
    required this.totalViews,
    required this.totalLikes,
    required this.totalComments,
    required this.totalShares,
    required this.totalWatchTime,
    required this.followers,
    required this.engagementRate,
  });

  String get watchTimeFormatted {
    final hours = totalWatchTime ~/ 3600;
    final minutes = (totalWatchTime % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }
}

class DailyStats {
  final String date;
  final int views;

  DailyStats({required this.date, required this.views});
}

class SponsorshipOffer {
  final String id;
  final String brandId;
  final String brandName;
  final String brandLogo;
  final double offerAmount;
  final String description;
  final String requirements;
  final String status;

  SponsorshipOffer({
    required this.id,
    required this.brandId,
    required this.brandName,
    required this.brandLogo,
    required this.offerAmount,
    required this.description,
    required this.requirements,
    required this.status,
  });

  factory SponsorshipOffer.fromFirestore(String id, Map<String, dynamic> data) {
    return SponsorshipOffer(
      id: id,
      brandId: data['brandId'] ?? '',
      brandName: data['brandName'] ?? '',
      brandLogo: data['brandLogo'] ?? '',
      offerAmount: (data['offerAmount'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      requirements: data['requirements'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }
}

class TrainingLog {
  final String id;
  final String discipline;
  final int rounds;
  final int conditioningMinutes;
  final String? notes;
  final double? weight;
  final DateTime date;

  TrainingLog({
    required this.id,
    required this.discipline,
    required this.rounds,
    required this.conditioningMinutes,
    this.notes,
    this.weight,
    required this.date,
  });

  factory TrainingLog.fromFirestore(String id, Map<String, dynamic> data) {
    return TrainingLog(
      id: id,
      discipline: data['discipline'] ?? '',
      rounds: data['rounds'] ?? 0,
      conditioningMinutes: data['conditioningMinutes'] ?? 0,
      notes: data['notes'],
      weight: (data['weight'] as num?)?.toDouble(),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
