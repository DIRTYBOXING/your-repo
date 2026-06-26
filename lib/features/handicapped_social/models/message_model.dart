import 'package:cloud_firestore/cloud_firestore.dart';

/// Message model for handicapped social workflow
class HandicappedMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  HandicappedMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    required this.isRead,
  });

  factory HandicappedMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HandicappedMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
    };
  }
}
