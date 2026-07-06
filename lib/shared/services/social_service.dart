import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community/community_models.dart';

/// Result of a [SocialService.backfillNormalizedPostMedia] run.
class SocialPostMediaBackfillResult {
  final int scannedCount;
  final int updatedCount;
  final bool dryRun;

  const SocialPostMediaBackfillResult({
    required this.scannedCount,
    required this.updatedCount,
    required this.dryRun,
  });
}

class SocialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentSnapshot? _lastPostDocument;

  // ─── 1. REAL-TIME FEED STREAM ───
  Stream<List<Post>> getFeed() {
    return _db
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return Post(
              id: doc.id,
              userId: data['authorId'] ?? data['userId'] ?? '',
              content: data['content'] ?? '',
              createdAt:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              userDisplayName: data['displayName'],
              userRole: data['userRole'],
              userAvatarUrl: data['userAvatarUrl'],
              isVerified: data['isVerified'] ?? false,
              likes: data['likes'] ?? 0,
              commentCount: data['commentCount'] ?? 0,
              shareCount: data['shareCount'] ?? 0,
              mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
              location: data['location'],
              postType: data['postType'] ?? 'text',
            );
          }).toList(),
        );
  }

  // ─── CREATE / READ SINGLE POST ───
  Future<String> createPost({
    String? postId,
    required String authorId,
    required String content,
    String? displayName,
    String? avatarUrl,
    List<String>? mediaUrls,
    List<String>? mediaAssetIds,
    String postType = 'text',
    String? location,
    String? linkPreviewUrl,
    String? linkPreviewTitle,
    String? linkPreviewDescription,
    String? linkPreviewImage,
    String? linkPreviewDomain,
    String? taggedGymId,
    List<String>? taggedFighterIds,
    String? campaignId,
    String? role,
  }) async {
    final data = <String, dynamic>{
      'authorId': authorId,
      'userId': authorId,
      'content': content,
      'displayName': displayName,
      'userAvatarUrl': avatarUrl,
      if (role != null) 'userRole': role,
      'mediaUrls': mediaUrls ?? <String>[],
      'mediaAssetIds': mediaAssetIds ?? <String>[],
      'postType': postType,
      if (location != null) 'location': location,
      if (linkPreviewUrl != null) 'linkPreviewUrl': linkPreviewUrl,
      if (linkPreviewTitle != null) 'linkPreviewTitle': linkPreviewTitle,
      if (linkPreviewDescription != null)
        'linkPreviewDescription': linkPreviewDescription,
      if (linkPreviewImage != null) 'linkPreviewImage': linkPreviewImage,
      if (linkPreviewDomain != null) 'linkPreviewDomain': linkPreviewDomain,
      if (taggedGymId != null) 'taggedGymId': taggedGymId,
      if (taggedFighterIds != null) 'taggedFighterIds': taggedFighterIds,
      if (campaignId != null) 'campaignId': campaignId,
      'likes': 0,
      'commentCount': 0,
      'shareCount': 0,
      'timestamp': FieldValue.serverTimestamp(),
    };
    if (postId != null) {
      await _db.collection('posts').doc(postId).set(data);
      return postId;
    }
    final ref = await _db.collection('posts').add(data);
    return ref.id;
  }

  Future<Post?> getPost(String postId) async {
    final doc = await _db.collection('posts').doc(postId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return Post(
      id: doc.id,
      userId: data['authorId'] ?? data['userId'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userDisplayName: data['displayName'],
      userRole: data['userRole'],
      userAvatarUrl: data['userAvatarUrl'],
      isVerified: data['isVerified'] ?? false,
      likes: data['likes'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      shareCount: data['shareCount'] ?? 0,
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      location: data['location'],
      postType: data['postType'] ?? 'text',
    );
  }

  // ─── 2. PAGINATED LOAD MORE ───
  Future<List<Post>> getPostsPage({
    bool refresh = false,
    String? userCity,
    String? userState,
    String? userCountry,
  }) async {
    if (refresh) {
      _lastPostDocument = null;
    }

    var query = _db
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(20);

    if (_lastPostDocument != null) {
      query = query.startAfterDocument(_lastPostDocument!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastPostDocument = snapshot.docs.last;
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Post(
        id: doc.id,
        userId: data['authorId'] ?? data['userId'] ?? '',
        content: data['content'] ?? '',
        createdAt:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        userDisplayName: data['displayName'],
        userRole: data['userRole'],
        postType: data['postType'] ?? 'text',
      );
    }).toList();
  }

  // ─── 3. ENGAGEMENT HANDLERS ───
  Future<void> toggleLike(String postId, String userId) async {
    await _db.collection('posts').doc(postId).update({
      'likes': FieldValue.increment(1),
    });
  }

  Future<void> toggleBookmark(String postId, String userId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(postId)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }

  Stream<List<Map<String, dynamic>>> getComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<void> addComment(
    String postId,
    String userId,
    String text, {
    String? displayName,
    String? role,
    String? avatarUrl,
    String? parentCommentId,
    String? replyToName,
  }) async {
    await _db.collection('posts').doc(postId).collection('comments').add({
      'userId': userId,
      'userDisplayName': displayName,
      'userRole': role,
      'userAvatarUrl': avatarUrl,
      'parentCommentId': parentCommentId,
      'replyToName': replyToName,
      'content': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _db.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  Future<void> sharePost(String postId, String userId) async {
    await _db.collection('posts').doc(postId).update({
      'shareCount': FieldValue.increment(1),
    });
  }

  // ─── FOLLOW / UNFOLLOW ───
  Future<void> followUser(String currentUserId, String targetUserId) async {
    final batch = _db.batch();
    batch.set(
      _db
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId),
      {'createdAt': FieldValue.serverTimestamp()},
    );
    batch.set(
      _db
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId),
      {'createdAt': FieldValue.serverTimestamp()},
    );
    await batch.commit();
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final batch = _db.batch();
    batch.delete(
      _db
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId),
    );
    batch.delete(
      _db
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId),
    );
    await batch.commit();
  }

  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    final doc = await _db
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .get();
    return doc.exists;
  }

  /// Fetch the profile summaries of users following [userId].
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('followers')
        .get();
    final ids = snap.docs.map((d) => d.id).toList();
    return _fetchUserSummaries(ids);
  }

  /// Fetch the profile summaries of users [userId] is following.
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('following')
        .get();
    final ids = snap.docs.map((d) => d.id).toList();
    return _fetchUserSummaries(ids);
  }

  /// Count of users following [userId].
  Future<int> getFollowerCount(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('followers')
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Count of users [userId] is following.
  Future<int> getFollowingCount(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('following')
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<List<Map<String, dynamic>>> _fetchUserSummaries(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final docs = await Future.wait(
      ids.map((id) => _db.collection('users').doc(id).get()),
    );
    return docs
        .where((doc) => doc.exists)
        .map((doc) => {'id': doc.id, ...doc.data()!})
        .toList();
  }

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  /// Scan posts for legacy/unnormalized media fields and, unless [dryRun],
  /// migrate them to the current `mediaUrls` schema.
  Future<SocialPostMediaBackfillResult> backfillNormalizedPostMedia({
    bool dryRun = true,
  }) async {
    final snap = await _db.collection('posts').get();
    var updated = 0;
    WriteBatch? batch = dryRun ? null : _db.batch();
    for (final doc in snap.docs) {
      final data = doc.data();
      final hasLegacyMedia =
          data['mediaUrl'] != null && data['mediaUrls'] == null;
      if (!hasLegacyMedia) continue;
      updated++;
      if (!dryRun) {
        batch!.update(doc.reference, {
          'mediaUrls': [data['mediaUrl']],
        });
      }
    }
    if (!dryRun && updated > 0) {
      await batch!.commit();
    }
    return SocialPostMediaBackfillResult(
      scannedCount: snap.docs.length,
      updatedCount: updated,
      dryRun: dryRun,
    );
  }

  // ── Extended API used by feed, post card, and poll widgets ────────────────

  bool get hasMorePosts => _hasMore;
  bool _hasMore = true;

  /// Enable demo/mock mode for testing purposes.
  /// When true, services return fake data without hitting Firestore.
  static bool _demoModeForTests = false;
  static bool get isDemoModeForTests => _demoModeForTests;

  /// Activate demo mode — used as a setUpAll callback in tests.
  static void enableDemoModeForTests() {
    _demoModeForTests = true;
  }

  Future<List<String>> getFollowingIds(String userId) async {
    try {
      final snap = await _db
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .get();
      return snap.docs.map((d) => d.data()['followingId'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> toggleReaction(String postId, String userId, String type) async {
    final ref = _db
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .doc(userId);
    final doc = await ref.get();
    if (doc.exists && doc.data()?['type'] == type) {
      await ref.delete();
    } else {
      await ref.set({
        'type': type,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> editPost(String postId, String newContent) async {
    await _db.collection('posts').doc(postId).update({
      'content': newContent,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> votePoll(String postId, String optionId, String userId) async {
    await _db
        .collection('posts')
        .doc(postId)
        .collection('poll_votes')
        .doc(userId)
        .set({'optionId': optionId, 'votedAt': FieldValue.serverTimestamp()});
    await _db.collection('posts').doc(postId).update({
      'pollOptions.$optionId.votes': FieldValue.increment(1),
    });
  }

  // Named-param overload for poll_display_widget compatibility
  Future<void> votePollByIndex({
    required String postId,
    required int optionIndex,
    required String userId,
  }) async {
    await votePoll(postId, optionIndex.toString(), userId);
  }

  // ── Polls, Hashtags, and Bookmarks ─────────────────────────────────────────

  /// Create a poll post with the given question and options.
  /// Returns the ID of the created poll post.
  Future<String> createPoll({
    required String authorId,
    required String question,
    required List<String> options,
    String? displayName,
    String? avatarUrl,
    Duration? duration,
    String? role,
    bool allowMultiple = false,
  }) async {
    final pollOptions = <String, dynamic>{};
    for (var i = 0; i < options.length; i++) {
      pollOptions['$i'] = {'text': options[i], 'votes': 0};
    }

    final data = <String, dynamic>{
      'authorId': authorId,
      'userId': authorId,
      'content': question,
      'displayName': displayName,
      'userAvatarUrl': avatarUrl,
      'postType': 'poll',
      'pollOptions': pollOptions,
      'pollCreatedAt': FieldValue.serverTimestamp(),
      if (duration != null)
        'pollExpiresAt': Timestamp.fromDate(DateTime.now().add(duration)),
      'likes': 0,
      'commentCount': 0,
      'shareCount': 0,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final ref = await _db.collection('posts').add(data);
    return ref.id;
  }

  /// Fetch posts that contain the given hashtag.
  /// Returns a list of Post objects matching the hashtag.
  Future<List<Post>> getHashtagPosts(String hashtag) async {
    // Normalize hashtag: remove # prefix if present, lowercase
    final normalizedTag = hashtag.startsWith('#')
        ? hashtag.substring(1).toLowerCase()
        : hashtag.toLowerCase();

    final snapshot = await _db
        .collection('posts')
        .where('hashtags', arrayContains: normalizedTag)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Post(
        id: doc.id,
        userId: data['authorId'] ?? data['userId'] ?? '',
        content: data['content'] ?? '',
        createdAt:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        userDisplayName: data['displayName'],
        userRole: data['userRole'],
        userAvatarUrl: data['userAvatarUrl'],
        isVerified: data['isVerified'] ?? false,
        likes: data['likes'] ?? 0,
        commentCount: data['commentCount'] ?? 0,
        shareCount: data['shareCount'] ?? 0,
        mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
        location: data['location'],
        postType: data['postType'] ?? 'text',
      );
    }).toList();
  }

  /// Fetch all posts bookmarked by the given user.
  /// Returns a list of Post objects that the user has bookmarked.
  Future<List<Post>> getBookmarkedPosts(String userId) async {
    // First, get all bookmark document IDs for this user
    final bookmarksSnap = await _db
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .orderBy('timestamp', descending: true)
        .get();

    if (bookmarksSnap.docs.isEmpty) return [];

    final postIds = bookmarksSnap.docs.map((d) => d.id).toList();

    // Fetch all the bookmarked posts
    final posts = <Post>[];
    for (final postId in postIds) {
      final post = await getPost(postId);
      if (post != null) {
        posts.add(post);
      }
    }

    return posts;
  }
}
