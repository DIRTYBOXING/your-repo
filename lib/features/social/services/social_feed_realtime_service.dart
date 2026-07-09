import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/social_clip_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SOCIAL FEED REALTIME SERVICE — Live Clip & Engagement Streaming
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Streams real-time updates:
///   - New clips as they're generated
///   - Engagement updates (likes, shares, views, comments)
///   - Trending score recalculation
///   - Live fight indicators
///
/// Usage:
///   final realtimeService = SocialFeedRealtimeService();
///   realtimeService.getNewClipsStream(eventId, sessionId).listen((clips) {
///     // Feed updated with new clips
///   });
///
/// ═══════════════════════════════════════════════════════════════════════════

class SocialFeedRealtimeService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get stream of new clips for a fight
  Stream<List<SocialClip>> getNewClipsStream(String eventId, String sessionId) {
    return _firestore
        .collection('ppv_events')
        .doc(eventId)
        .collection('event_sessions')
        .doc(sessionId)
        .collection('social_clips')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SocialClip.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get stream of trending clips with live recalculation
  Stream<List<SocialClip>> getTrendingClipsStream(
    String eventId,
    String sessionId,
  ) {
    return _firestore
        .collection('ppv_events')
        .doc(eventId)
        .collection('event_sessions')
        .doc(sessionId)
        .collection('social_clips')
        .where(
          'createdAt',
          isGreaterThan: DateTime.now().subtract(Duration(hours: 24)),
        )
        .snapshots()
        .map((snapshot) {
          final clips = snapshot.docs
              .map((doc) => SocialClip.fromFirestore(doc.data(), doc.id))
              .toList();

          // Sort by trending score
          clips.sort(
            (a, b) => b.calculateTrendingScore().compareTo(
              a.calculateTrendingScore(),
            ),
          );

          return clips.take(20).toList();
        });
  }

  /// Get stream of clips by type (knockdown, submission, etc.)
  Stream<List<SocialClip>> getClipsByTypeStream(
    String eventId,
    String sessionId,
    ClipType clipType,
  ) {
    return _firestore
        .collection('ppv_events')
        .doc(eventId)
        .collection('event_sessions')
        .doc(sessionId)
        .collection('social_clips')
        .where('clipType', isEqualTo: clipType.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SocialClip.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get stream of engagement updates for a specific clip
  Stream<ClipEngagement> getEngagementUpdatesStream(
    String eventId,
    String sessionId,
    String clipId,
  ) {
    return _firestore
        .collection('ppv_events')
        .doc(eventId)
        .collection('event_sessions')
        .doc(sessionId)
        .collection('social_clips')
        .doc(clipId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return ClipEngagement.empty();
          }
          final data = doc.data() as Map<String, dynamic>;
          return ClipEngagement(
            views: data['engagement']?['views'] ?? 0,
            likes: data['engagement']?['likes'] ?? 0,
            shares: data['engagement']?['shares'] ?? 0,
            comments: data['engagement']?['comments'] ?? 0,
            ppvConversions: data['engagement']?['ppvConversions'] ?? 0,
          );
        });
  }

  /// Get stream of clips by creator
  Stream<List<SocialClip>> getClipsByCreatorStream(
    String eventId,
    String sessionId,
    String creatorId,
  ) {
    return _firestore
        .collection('ppv_events')
        .doc(eventId)
        .collection('event_sessions')
        .doc(sessionId)
        .collection('social_clips')
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SocialClip.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get stream of recent live fight indicators
  Stream<Map<String, dynamic>> getLiveFightIndicatorsStream(
    String eventId,
    String sessionId,
  ) {
    return _firestore
        .collection('ppv_events')
        .doc(eventId)
        .collection('event_sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return {};
          return doc.data() as Map<String, dynamic>;
        });
  }

  /// Get stream of viral clips (trending + recent)
  Stream<List<SocialClip>> getViralClipsStream(
    String eventId,
    String sessionId,
  ) {
    return getTrendingClipsStream(eventId, sessionId);
  }

  /// Get stream of highlight clips
  Stream<List<SocialClip>> getHighlightClipsStream(
    String eventId,
    String sessionId,
  ) {
    return _firestore
        .collection('ppv_events')
        .doc(eventId)
        .collection('event_sessions')
        .doc(sessionId)
        .collection('social_clips')
        .where('clipType', isEqualTo: 'highlight')
        .orderBy('trendingScore', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SocialClip.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get stream of recent clips
  Stream<List<SocialClip>> getRecentClipsStream(
    String eventId,
    String sessionId,
  ) {
    return _firestore
        .collection('ppv_events')
        .doc(eventId)
        .collection('event_sessions')
        .doc(sessionId)
        .collection('social_clips')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SocialClip.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get stream of live action clips (generated in real-time)
  Stream<List<SocialClip>> getLiveActionClipsStream(
    String eventId,
    String sessionId,
  ) {
    final now = DateTime.now();
    final fiveMinutesAgo = now.subtract(Duration(minutes: 5));

    return _firestore
        .collection('ppv_events')
        .doc(eventId)
        .collection('event_sessions')
        .doc(sessionId)
        .collection('social_clips')
        .where('createdAt', isGreaterThan: fiveMinutesAgo)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SocialClip.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }
}
