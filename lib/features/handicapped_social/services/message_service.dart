import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

/// Backend service for messages
class HandicappedMessageService {
  final CollectionReference messagesRef = FirebaseFirestore.instance.collection(
    'handicapped_messages',
  );

  Future<List<HandicappedMessage>> fetchInbox(String userId) async {
    final query = await messagesRef
        .where('receiverId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .get();
    return query.docs
        .map(HandicappedMessage.fromFirestore)
        .toList();
  }

  Future<List<HandicappedMessage>> fetchOutbox(String userId) async {
    final query = await messagesRef
        .where('senderId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .get();
    return query.docs
        .map(HandicappedMessage.fromFirestore)
        .toList();
  }

  Future<void> sendMessage(HandicappedMessage message) async {
    await messagesRef.add(message.toFirestore());
  }

  Future<void> markAsRead(String messageId) async {
    await messagesRef.doc(messageId).update({'isRead': true});
  }
}
