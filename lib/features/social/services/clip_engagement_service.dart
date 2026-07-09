import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/social_clip_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CLIP ENGAGEMENT SERVICE — Track User Interactions & Viral Metrics
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Records all user engagement with social clips:
///   - View tracking (auto on clip preview open)
///   - Likes (manual button tap)
///   - Shares (manual button tap)
///   - Comments (future: reply system)
///   - Watch CTA (leads to PPV)
///
/// Engagement drives trending score:
///   trendingScore = (views × 0.3) + (likes × 0.4) + (shares × 1.0) + (ppvConversions × 2.0)
///
/// ═══════════════════════════════════════════════════════════════════════════

class ClipEngagementService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Record a view on a clip (auto-called when modal opens)
  Future<void> recordView(
    String eventId,
    String sessionId,
    String clipId,
  ) async {
    try {
      final clipPath =
          'ppv_events/$eventId/event_sessions/$sessionId/social_clips/$clipId';
      final clipDoc = _firestore.doc(clipPath);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(clipDoc);
        if (!snapshot.exists) {
          debugPrint('⚠️ [ENGAGEMENT] Clip not found: $clipId');
          return;
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final currentEngagement =
            data['engagement'] as Map<String, dynamic>? ?? {};
        final currentViews = (currentEngagement['views'] ?? 0) as int;

        transaction.update(clipDoc, {
          'engagement.views': currentViews + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('👁️ [ENGAGEMENT] View recorded for clip: $clipId');
    } catch (e) {
      debugPrint('❌ [ENGAGEMENT] Error recording view: $e');
    }
  }

  /// Record a like on a clip
  Future<void> recordLike(
    String eventId,
    String sessionId,
    String clipId,
    String userId,
  ) async {
    try {
      final clipPath =
          'ppv_events/$eventId/event_sessions/$sessionId/social_clips/$clipId';
      final clipDoc = _firestore.doc(clipPath);
      final likeTrackerPath = '$clipPath/likes/$userId';

      // Use batch to atomically update clip engagement and track user like
      final batch = _firestore.batch();

      // Increment like count
      batch.update(clipDoc, {
        'engagement.likes': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Record user as liker (for deduplication)
      batch.set(_firestore.doc(likeTrackerPath), {
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      debugPrint(
        '❤️ [ENGAGEMENT] Like recorded for clip: $clipId by user: $userId',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [ENGAGEMENT] Error recording like: $e');
    }
  }

  /// Record a share on a clip
  Future<void> recordShare(
    String eventId,
    String sessionId,
    String clipId,
    String userId,
  ) async {
    try {
      final clipPath =
          'ppv_events/$eventId/event_sessions/$sessionId/social_clips/$clipId';
      final clipDoc = _firestore.doc(clipPath);
      final shareTrackerPath = '$clipPath/shares/$userId';

      final batch = _firestore.batch();

      // Increment share count
      batch.update(clipDoc, {
        'engagement.shares': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Record user as sharer
      batch.set(_firestore.doc(shareTrackerPath), {
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      debugPrint(
        '📤 [ENGAGEMENT] Share recorded for clip: $clipId by user: $userId',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [ENGAGEMENT] Error recording share: $e');
    }
  }

  /// Record a comment on a clip
  Future<void> recordComment(
    String eventId,
    String sessionId,
    String clipId,
    String userId,
    String commentText,
  ) async {
    try {
      final clipPath =
          'ppv_events/$eventId/event_sessions/$sessionId/social_clips/$clipId';
      final clipDoc = _firestore.doc(clipPath);
      final commentsPath = '$clipPath/comments';

      final batch = _firestore.batch();

      // Increment comment count
      batch.update(clipDoc, {
        'engagement.comments': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add comment document
      batch.set(
        _firestore
            .collection('ppv_events')
            .doc(eventId)
            .collection('event_sessions')
            .doc(sessionId)
            .collection('social_clips')
            .doc(clipId)
            .collection('comments')
            .doc(),
        {
          'userId': userId,
          'text': commentText,
          'timestamp': FieldValue.serverTimestamp(),
          'likes': 0,
        },
      );

      await batch.commit();

      debugPrint(
        '💬 [ENGAGEMENT] Comment recorded for clip: $clipId by user: $userId',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [ENGAGEMENT] Error recording comment: $e');
    }
  }

  /// Check if user already liked this clip
  Future<bool> hasUserLiked(
    String eventId,
    String sessionId,
    String clipId,
    String userId,
  ) async {
    try {
      final likeTrackerPath =
          'ppv_events/$eventId/event_sessions/$sessionId/social_clips/$clipId/likes/$userId';
      final likeDoc = await _firestore.doc(likeTrackerPath).get();
      return likeDoc.exists;
    } catch (e) {
      debugPrint('⚠️ [ENGAGEMENT] Error checking if user liked: $e');
      return false;
    }
  }

  /// Batch increment engagement (for seeding test data)
  Future<void> incrementEngagementMetrics(
    String eventId,
    String sessionId,
    String clipId, {
    int viewsToAdd = 0,
    int likesToAdd = 0,
    int sharesToAdd = 0,
  }) async {
    try {
      final clipPath =
          'ppv_events/$eventId/event_sessions/$sessionId/social_clips/$clipId';

      await _firestore.doc(clipPath).update({
        if (viewsToAdd > 0)
          'engagement.views': FieldValue.increment(viewsToAdd),
        if (likesToAdd > 0)
          'engagement.likes': FieldValue.increment(likesToAdd),
        if (sharesToAdd > 0)
          'engagement.shares': FieldValue.increment(sharesToAdd),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        '📊 [ENGAGEMENT] Bulk update for $clipId: +$viewsToAdd views, +$likesToAdd likes, +$sharesToAdd shares',
      );
    } catch (e) {
      debugPrint('❌ [ENGAGEMENT] Error incrementing engagement: $e');
    }
  }

  /// Remove a like (user unliked)
  Future<void> removeLike(
    String eventId,
    String sessionId,
    String clipId,
    String userId,
  ) async {
    try {
      final clipPath =
          'ppv_events/$eventId/event_sessions/$sessionId/social_clips/$clipId';
      final clipDoc = _firestore.doc(clipPath);
      final likeTrackerPath = '$clipPath/likes/$userId';

      final batch = _firestore.batch();

      // Decrement like count
      batch.update(clipDoc, {
        'engagement.likes': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove user from likers
      batch.delete(_firestore.doc(likeTrackerPath));

      await batch.commit();

      debugPrint(
        '🤍 [ENGAGEMENT] Like removed for clip: $clipId by user: $userId',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [ENGAGEMENT] Error removing like: $e');
    }
  }

  /// Get engagement stats for a clip
  Future<ClipEngagement?> getEngagementStats(
    String eventId,
    String sessionId,
    String clipId,
  ) async {
    try {
      final clipPath =
          'ppv_events/$eventId/event_sessions/$sessionId/social_clips/$clipId';
      final doc = await _firestore.doc(clipPath).get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return ClipEngagement(
        views: data['engagement']?['views'] ?? 0,
        likes: data['engagement']?['likes'] ?? 0,
        shares: data['engagement']?['shares'] ?? 0,
        comments: data['engagement']?['comments'] ?? 0,
        ppvConversions: data['engagement']?['ppvConversions'] ?? 0,
      );
    } catch (e) {
      debugPrint('❌ [ENGAGEMENT] Error getting engagement stats: $e');
      return null;
    }
  }
}
