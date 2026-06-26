import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/fightwire_post.dart';
import '../../core/constants/app_constants.dart';
import 'feed_ranking_engine.dart';

/// FightWire Feed Service - Multi-source content aggregator
///
/// Aggregates content from multiple sources :
/// - DFC native posts (users, gyms, fighters, promoters)
/// - NightChill partnership content (trauma recovery, sobriety support)
/// - IBC integration (boxing events, rankings)
/// - ESPN RSS feeds (combat sports news)
/// - Partner gyms and promoters
/// - AI-generated insights
///
/// Implements the "Instagram + LinkedIn + ESPN + Discord" hybrid feed
/// that spreads opportunity, not toxicity.
class FightWireFeedService {
  final FirebaseFirestore _firestore;
  final FeedRankingEngine _rankingEngine;

  FightWireFeedService({
    FirebaseFirestore? firestore,
    FeedRankingEngine? rankingEngine,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _rankingEngine = rankingEngine ?? FeedRankingEngine();

  /// Get personalized feed for user with multi-source aggregation
  Future<List<FightWirePost>> getPersonalizedFeed({
    required String userId,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    List<PostSource>? sourcesFilter,
    List<FightWirePostType>? typesFilter,
  }) async {
    try {
      // In demo mode, skip Firestore — no authenticated user
      if (kIsWeb && AppConstants.webDemoMode) return [];

      // Use ranking engine to get personalized feed
      final rankedPosts = await _rankingEngine.getPersonalizedFeed(
        userId: userId,
        limit: limit * 2, // Fetch more for filtering
        startAfter: startAfter,
      );

      // Apply filters if specified
      var filteredPosts = rankedPosts;

      if (sourcesFilter != null && sourcesFilter.isNotEmpty) {
        filteredPosts = filteredPosts
            .where((post) => sourcesFilter.contains(post.source))
            .toList();
      }

      if (typesFilter != null && typesFilter.isNotEmpty) {
        filteredPosts = filteredPosts
            .where((post) => typesFilter.contains(post.type))
            .toList();
      }

      return filteredPosts.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching personalized feed: $e');
      return [];
    }
  }

  /// Get posts from specific source
  Future<List<FightWirePost>> getPostsBySource({
    required PostSource source,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('posts')
          .where('source', isEqualTo: source.toString().split('.').last)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map(FightWirePost.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching posts by source: $e');
      return [];
    }
  }

  /// Get campaign-specific posts
  Future<List<FightWirePost>> getCampaignFeed({
    required String campaignId,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('campaignId', isEqualTo: campaignId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(FightWirePost.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching campaign feed: $e');
      return [];
    }
  }

  /// Get NightChill partnership content
  Future<List<FightWirePost>> getNightChillFeed({int limit = 10}) async {
    return getPostsBySource(source: PostSource.nightchill, limit: limit);
  }

  /// Get livestream posts (active and upcoming)
  Future<List<FightWirePost>> getLivestreamFeed({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('type', isEqualTo: 'livestream')
          .where('livestreamEnded', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(FightWirePost.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching livestream feed: $e');
      return [];
    }
  }

  /// Get event posts (upcoming events)
  Future<List<FightWirePost>> getEventsFeed({int limit = 20}) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('posts')
          .where('type', isEqualTo: 'event')
          .where('eventDate', isGreaterThan: now)
          .orderBy('eventDate')
          .limit(limit)
          .get();

      return snapshot.docs.map(FightWirePost.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching events feed: $e');
      return [];
    }
  }

  /// Get opportunity posts (jobs, sponsorships, seminars)
  Future<List<FightWirePost>> getOpportunitiesFeed({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('type', isEqualTo: 'opportunity')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(FightWirePost.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching opportunities feed: $e');
      return [];
    }
  }

  /// Get sparring requests near user
  Future<List<FightWirePost>> getSparringRequests({
    required String userId,
    int limit = 20,
  }) async {
    try {
      // Fetch user data to get weight class and location
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData == null) return [];

      final userWeightClass = userData['weightClass'] as String?;

      // Get sparring requests, optionally filtered by weight class
      Query<Map<String, dynamic>> query = _firestore
          .collection('posts')
          .where('type', isEqualTo: 'sparringRequest')
          .orderBy('timestamp', descending: true);

      if (userWeightClass != null) {
        query = query.where('metadata.weightClass', isEqualTo: userWeightClass);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map(FightWirePost.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching sparring requests: $e');
      return [];
    }
  }

  /// Get gym-specific feed
  Future<List<FightWirePost>> getGymFeed({
    required String gymId,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('gymId', isEqualTo: gymId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(FightWirePost.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching gym feed: $e');
      return [];
    }
  }

  /// Create a new post
  Future<String?> createPost(FightWirePost post) async {
    try {
      final docRef = await _firestore
          .collection('posts')
          .add(post.toFirestore());

      // Update user's post count
      await _firestore.collection('users').doc(post.authorId).update({
        'postCount': FieldValue.increment(1),
        'lastPostTimestamp': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }

  /// Add reaction to post
  Future<bool> addReaction({
    required String postId,
    required String userId,
    required String reactionType, // 'respect', 'warrior', 'champion', 'strong'
  }) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);

      // Check if user already reacted
      final userReactionDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('reactions')
          .doc(userId)
          .get();

      if (userReactionDoc.exists) {
        // Remove old reaction and add new one
        final oldReaction = userReactionDoc.data()!['type'] as String;
        await postRef.update({
          '${oldReaction}Count': FieldValue.increment(-1),
          '${reactionType}Count': FieldValue.increment(1),
        });

        await userReactionDoc.reference.update({'type': reactionType});
      } else {
        // Add new reaction
        await postRef.update({'${reactionType}Count': FieldValue.increment(1)});

        await postRef.collection('reactions').doc(userId).set({
          'type': reactionType,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      return false;
    }
  }

  /// Remove reaction from post
  Future<bool> removeReaction({
    required String postId,
    required String userId,
  }) async {
    try {
      final userReactionDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('reactions')
          .doc(userId)
          .get();

      if (!userReactionDoc.exists) return false;

      final reactionType = userReactionDoc.data()!['type'] as String;

      await _firestore.collection('posts').doc(postId).update({
        '${reactionType}Count': FieldValue.increment(-1),
      });

      await userReactionDoc.reference.delete();

      return true;
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      return false;
    }
  }

  /// Increment view count
  Future<void> incrementViews(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  /// Get trending posts (high engagement in last 48 hours)
  Future<List<FightWirePost>> getTrendingFeed({int limit = 20}) async {
    try {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));

      final snapshot = await _firestore
          .collection('posts')
          .where('timestamp', isGreaterThan: twoDaysAgo)
          .orderBy('timestamp', descending: true)
          .limit(limit * 3) // Fetch more to calculate trending score
          .get();

      final posts = snapshot.docs.map(FightWirePost.fromFirestore).toList();

      // Sort by engagement rate
      posts.sort((a, b) {
        final aEngagement =
            a.respectCount +
            a.warriorCount +
            a.championCount +
            a.strongCount +
            a.commentsCount;
        final bEngagement =
            b.respectCount +
            b.warriorCount +
            b.championCount +
            b.strongCount +
            b.commentsCount;
        final aRate =
            aEngagement / (a.likesCount + a.commentsCount + a.sharesCount + 1);
        final bRate =
            bEngagement / (b.likesCount + b.commentsCount + b.sharesCount + 1);
        return bRate.compareTo(aRate);
      });

      return posts.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching trending feed: $e');
      return [];
    }
  }

  /// Stream feed updates in real-time
  Stream<List<FightWirePost>> streamPersonalizedFeed({
    required String userId,
    int limit = 20,
  }) {
    // For real-time updates, stream recent posts
    // and let the ranking engine sort them client-side
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(limit * 2)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(FightWirePost.fromFirestore).toList(),
        );
  }
}
