import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community/community_models.dart';

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
  }) async {
    await _db.collection('posts').doc(postId).collection('comments').add({
      'userId': userId,
      'userDisplayName': displayName,
      'userRole': role,
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

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  // ── Extended API used by feed, post card, and poll widgets ────────────────

  bool get hasMorePosts => _hasMore;
  bool _hasMore = true;

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
}
