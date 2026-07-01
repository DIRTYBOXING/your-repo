import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessengerService {
  Future<List<Message>> fetchInbox(String userId) async {
    final query = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();
    final List<Message> inbox = [];
    for (final doc in query.docs) {
      final messagesSnap = await _firestore
          .collection('conversations')
          .doc(doc.id)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      inbox.addAll(messagesSnap.docs.map(Message.fromFirestore));
    }
    return inbox;
  }

  Future<List<Message>> fetchOutbox(String userId) async {
    final query = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();
    final List<Message> outbox = [];
    for (final doc in query.docs) {
      final messagesSnap = await _firestore
          .collection('conversations')
          .doc(doc.id)
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      outbox.addAll(messagesSnap.docs.map(Message.fromFirestore));
    }
    return outbox;
  }

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<List<Message>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(Message.fromFirestore).toList(),
        );
  }

  Future<void> sendMessage(String conversationId, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
          'senderId': user.uid,
          'content': content,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Stream<List<Conversation>> getUserConversations() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Conversation.fromFirestore)
              .toList(),
        );
  }
}

class Message {
  final String senderId;
  final String content;
  final DateTime? timestamp;

  Message({required this.senderId, required this.content, this.timestamp});

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}

class Conversation {
  final String id;
  final List<String> participants;

  Conversation({required this.id, required this.participants});

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
    );
  }
}
