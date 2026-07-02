import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community/community_models.dart';

class SocialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentSnapshot? _lastPostDocument;
  bool _hasMorePosts = true;

  /// Whether a previous [getPostsPage] call indicated more pages are
  /// available (i.e. the last page returned a full page of results).
  bool get hasMorePosts => _hasMorePosts;

  Post _postFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Post(
      id: doc.id,
      userId: data['authorId'] ?? data['userId'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      shareCount: data['shareCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      bookmarkedBy: List<String>.from(data['bookmarkedBy'] ?? []),
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      mediaTypes: List<String>.from(data['mediaTypes'] ?? []),
      mediaAssetIds: List<String>.from(data['mediaAssetIds'] ?? []),
      thumbnailUrl: data['thumbnailUrl'],
      externalVideoUrl: data['externalVideoUrl'],
      userDisplayName: data['displayName'] ?? data['userDisplayName'],
      userRole: data['userRole'] ?? data['role'],
      userAvatarUrl: data['userAvatarUrl'] ?? data['avatarUrl'],
      postType: data['postType'] ?? 'text',
      isVerified: data['isVerified'] ?? false,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      location: data['location'],
      reactions: (data['reactions'] as Map?)?.map(
            (k, v) => MapEntry(k as String, List<String>.from(v ?? [])),
          ) ??
          const {},
      pollQuestion: data['pollQuestion'],
      pollOptions: List<String>.from(data['pollOptions'] ?? []),
      pollVotes: (data['pollVotes'] as Map?)?.map(
            (k, v) => MapEntry(k as String, List<String>.from(v ?? [])),
          ) ??
          const {},
      pollExpiresAt: (data['pollExpiresAt'] as Timestamp?)?.toDate(),
      pollAllowMultiple: data['pollAllowMultiple'] ?? false,
      linkPreviewUrl: data['linkPreviewUrl'],
      linkPreviewTitle: data['linkPreviewTitle'],
      linkPreviewDescription: data['linkPreviewDescription'],
      linkPreviewImage: data['linkPreviewImage'],
      linkPreviewDomain: data['linkPreviewDomain'],
    );
  }

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

  // ─── 2. PAGINATED LOAD MORE ───
  // userCity/userState/userCountry are accepted for forward-compatible
  // geo-aware feed ranking; not yet used to filter results.
  Future<List<Post>> getPostsPage({
    bool refresh = false,
    String? userCity,
    String? userState,
    String? userCountry,
  }) async {
    if (refresh) {
      _lastPostDocument = null;
      _hasMorePosts = true;
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
    _hasMorePosts = snapshot.docs.length >= 20;

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
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(postId);
    final existing = await ref.get();
    if (existing.exists) {
      await ref.delete();
    } else {
      await ref.set({'timestamp': FieldValue.serverTimestamp()});
    }
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
      'content': text,
      'parentCommentId': parentCommentId,
      'replyToName': replyToName,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _db.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
    // Track reply count on the parent comment for threaded views.
    if (parentCommentId != null) {
      await _db
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(parentCommentId)
          .update({'replyCount': FieldValue.increment(1)})
          .catchError((_) {});
    }
  }

  Future<void> sharePost(String postId, String userId) async {
    await _db.collection('posts').doc(postId).update({
      'shareCount': FieldValue.increment(1),
    });
  }

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  // ─── FOLLOW / FOLLOWERS ───
  // Schema: users/{userId}/followers/{followerId} and
  //         users/{userId}/following/{followingId}
  // Both sides are written together so counts and lookups stay in sync.

  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    final doc = await _db
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId)
        .get();
    return doc.exists;
  }

  Future<void> followUser(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) return;
    final batch = _db.batch();
    batch.set(
      _db
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId),
      {'createdAt': FieldValue.serverTimestamp()},
    );
    batch.set(
      _db
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId),
      {'createdAt': FieldValue.serverTimestamp()},
    );
    await batch.commit();
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final batch = _db.batch();
    batch.delete(
      _db
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId),
    );
    batch.delete(
      _db
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId),
    );
    await batch.commit();
  }

  Future<int> getFollowerCount(String userId) async {
    final agg = await _db
        .collection('users')
        .doc(userId)
        .collection('followers')
        .count()
        .get();
    return agg.count ?? 0;
  }

  Future<int> getFollowingCount(String userId) async {
    final agg = await _db
        .collection('users')
        .doc(userId)
        .collection('following')
        .count()
        .get();
    return agg.count ?? 0;
  }

  /// Resolves the user documents for everyone following [userId].
  /// Returns lightweight maps (`id`, `displayName`, `role`, `photoUrl`, ...)
  /// suitable for list rendering.
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    final ids = await _subcollectionIds(userId, 'followers');
    return _resolveUserSummaries(ids);
  }

  /// Resolves the user documents for everyone [userId] follows.
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    final ids = await _subcollectionIds(userId, 'following');
    return _resolveUserSummaries(ids);
  }

  /// Just the following user IDs (cheap, used for feed "is-following" checks).
  Future<List<String>> getFollowingIds(String userId) {
    return _subcollectionIds(userId, 'following');
  }

  Future<List<String>> _subcollectionIds(
    String userId,
    String subcollection,
  ) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection(subcollection)
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  Future<List<Map<String, dynamic>>> _resolveUserSummaries(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final results = <Map<String, dynamic>>[];
    // Firestore whereIn is capped at 30 entries per query.
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final snap = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snap.docs.map((d) => {'id': d.id, ...d.data()}));
    }
    return results;
  }

  // ─── POST CREATION / EDITING ───

  Future<void> createPost({
    String? postId,
    required String authorId,
    required String content,
    String? displayName,
    String? role,
    String? avatarUrl,
    List<String> mediaUrls = const [],
    List<String> mediaAssetIds = const [],
    String postType = 'text',
    String? location,
    String? taggedGymId,
    List<String> taggedFighterIds = const [],
    String? campaignId,
    String? linkPreviewUrl,
    String? linkPreviewTitle,
    String? linkPreviewDescription,
    String? linkPreviewImage,
    String? linkPreviewDomain,
  }) async {
    final data = <String, dynamic>{
      'authorId': authorId,
      'content': content,
      'displayName': displayName,
      'userRole': role,
      'userAvatarUrl': avatarUrl,
      'mediaUrls': mediaUrls,
      'mediaAssetIds': mediaAssetIds,
      'postType': postType,
      'location': location,
      'taggedGymId': taggedGymId,
      'taggedFighterIds': taggedFighterIds,
      'campaignId': campaignId,
      'linkPreviewUrl': linkPreviewUrl,
      'linkPreviewTitle': linkPreviewTitle,
      'linkPreviewDescription': linkPreviewDescription,
      'linkPreviewImage': linkPreviewImage,
      'linkPreviewDomain': linkPreviewDomain,
      'likes': 0,
      'commentCount': 0,
      'shareCount': 0,
      'timestamp': FieldValue.serverTimestamp(),
    };
    if (postId != null) {
      await _db.collection('posts').doc(postId).set(data);
    } else {
      await _db.collection('posts').add(data);
    }
  }

  Future<void> createPoll({
    required String authorId,
    required String question,
    required List<String> options,
    String? displayName,
    String? role,
    String? avatarUrl,
    bool allowMultiple = false,
    Duration duration = const Duration(hours: 24),
  }) async {
    await _db.collection('posts').add({
      'authorId': authorId,
      'content': question,
      'displayName': displayName,
      'userRole': role,
      'userAvatarUrl': avatarUrl,
      'postType': 'poll',
      'pollQuestion': question,
      'pollOptions': options,
      'pollVotes': <String, List<String>>{},
      'pollAllowMultiple': allowMultiple,
      'pollExpiresAt': Timestamp.fromDate(DateTime.now().add(duration)),
      'likes': 0,
      'commentCount': 0,
      'shareCount': 0,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editPost(String postId, String content) async {
    await _db.collection('posts').doc(postId).update({
      'content': content,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggles [userId]'s reaction of [reactionType] on a post. Reaction
  /// membership is tracked in `reactions.<type>` as a list of user IDs.
  Future<void> toggleReaction(
    String postId,
    String userId,
    String reactionType,
  ) async {
    final ref = _db.collection('posts').doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};
      final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
      final current = List<String>.from(reactions[reactionType] ?? []);
      if (current.contains(userId)) {
        current.remove(userId);
      } else {
        current.add(userId);
      }
      reactions[reactionType] = current;
      tx.update(ref, {'reactions': reactions});
    });
  }

  Future<void> votePoll({
    required String postId,
    required int optionIndex,
    required String userId,
  }) async {
    final ref = _db.collection('posts').doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};
      final pollVotes = Map<String, dynamic>.from(data['pollVotes'] ?? {});
      final allowMultiple = data['pollAllowMultiple'] == true;
      final key = optionIndex.toString();

      if (!allowMultiple) {
        // Remove any existing vote from this user across all options.
        for (final entry in pollVotes.entries) {
          final voters = List<String>.from(entry.value ?? []);
          voters.remove(userId);
          pollVotes[entry.key] = voters;
        }
      }
      final voters = List<String>.from(pollVotes[key] ?? []);
      if (!voters.contains(userId)) voters.add(userId);
      pollVotes[key] = voters;

      tx.update(ref, {'pollVotes': pollVotes});
    });
  }

  // ─── QUERIES ───

  Future<Post?> getPost(String postId) async {
    final doc = await _db.collection('posts').doc(postId).get();
    if (!doc.exists) return null;
    return _postFromDoc(doc);
  }

  Future<List<Post>> getHashtagPosts(String hashtag) async {
    final tag = hashtag.startsWith('#') ? hashtag.substring(1) : hashtag;
    final snap = await _db
        .collection('posts')
        .where('hashtags', arrayContains: tag)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    return snap.docs.map(_postFromDoc).toList();
  }

  Future<List<Post>> getBookmarkedPosts(String userId) async {
    final bookmarkIds = await _subcollectionIds(userId, 'bookmarks');
    if (bookmarkIds.isEmpty) return [];
    final posts = <Post>[];
    for (var i = 0; i < bookmarkIds.length; i += 30) {
      final chunk = bookmarkIds.sublist(
        i,
        i + 30 > bookmarkIds.length ? bookmarkIds.length : i + 30,
      );
      final snap = await _db
          .collection('posts')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      posts.addAll(snap.docs.map(_postFromDoc));
    }
    return posts;
  }
}
