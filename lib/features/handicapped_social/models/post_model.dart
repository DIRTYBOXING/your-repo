import 'package:cloud_firestore/cloud_firestore.dart';

/// Post model for handicapped social workflow
class HandicappedPost {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime postedAt;

  HandicappedPost({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.postedAt,
  });

  factory HandicappedPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HandicappedPost(
      id: doc.id,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      postedAt: (data['postedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'content': content,
      'imageUrl': imageUrl,
      'postedAt': Timestamp.fromDate(postedAt),
    };
  }
}
