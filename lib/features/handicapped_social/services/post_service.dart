import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

/// Backend service for posts
class HandicappedPostService {
  final CollectionReference postsRef = FirebaseFirestore.instance.collection(
    'handicapped_posts',
  );

  Future<List<HandicappedPost>> fetchPosts(String userId) async {
    final query = await postsRef
        .where('userId', isEqualTo: userId)
        .orderBy('postedAt', descending: true)
        .get();
    return query.docs.map(HandicappedPost.fromFirestore).toList();
  }

  Future<void> createPost(HandicappedPost post) async {
    await postsRef.add(post.toFirestore());
  }
}
