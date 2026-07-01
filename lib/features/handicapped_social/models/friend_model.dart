import 'package:cloud_firestore/cloud_firestore.dart';

/// Friend model for handicapped social workflow
class HandicappedFriend {
  final String id;
  final String name;
  final String userId;

  HandicappedFriend({
    required this.id,
    required this.name,
    required this.userId,
  });

  factory HandicappedFriend.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HandicappedFriend(
      id: doc.id,
      name: data['name'] ?? '',
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'userId': userId};
  }
}
