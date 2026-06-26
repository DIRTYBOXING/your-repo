import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_model.dart';

/// Backend service for friends
class HandicappedFriendService {
  final CollectionReference friendsRef = FirebaseFirestore.instance.collection(
    'handicapped_friends',
  );

  Future<List<HandicappedFriend>> fetchFriends(String userId) async {
    final query = await friendsRef.where('userId', isEqualTo: userId).get();
    return query.docs
        .map(HandicappedFriend.fromFirestore)
        .toList();
  }

  Future<void> addFriend(HandicappedFriend friend) async {
    await friendsRef.add(friend.toFirestore());
  }
}
