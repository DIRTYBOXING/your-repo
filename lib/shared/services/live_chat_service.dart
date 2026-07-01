import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// LIVE CHAT SERVICE — Enhanced Real-Time Fight Chat with AI Moderation
/// ═══════════════════════════════════════════════════════════════════════════

final _firestore = FirebaseFirestore.instance;
final _functions = FirebaseFunctions.instanceFor(
  region: 'australia-southeast1',
);

enum MessageType { text, gif, emoji, prediction, celebration, system }

enum ChatReaction { fire, knockout, champion, skull, money, respect }

class ChatMessage {
  final String id;
  final String roomId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final MessageType type;
  final Map<ChatReaction, int> reactions;
  final bool isVerified;
  final bool isPremium;
  final DateTime sentAt;
  final String? replyToId;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.type,
    this.reactions = const {},
    this.isVerified = false,
    this.isPremium = false,
    required this.sentAt,
    this.replyToId,
    this.metadata,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'] ?? '',
    roomId: map['roomId'] ?? '',
    userId: map['userId'] ?? '',
    username: map['username'] ?? 'Anonymous',
    avatarUrl: map['avatarUrl'],
    content: map['content'] ?? '',
    type: MessageType.values.firstWhere(
      (t) => t.name == map['type'],
      orElse: () => MessageType.text,
    ),
    reactions: _parseReactions(map['reactions']),
    isVerified: map['isVerified'] ?? false,
    isPremium: map['isPremium'] ?? false,
    sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    replyToId: map['replyToId'],
    metadata: map['metadata'],
  );

  static Map<ChatReaction, int> _parseReactions(dynamic data) {
    if (data == null) return {};
    final result = <ChatReaction, int>{};
    for (final entry in (data as Map).entries) {
      final reaction = ChatReaction.values.firstWhere(
        (r) => r.name == entry.key,
        orElse: () => ChatReaction.fire,
      );
      result[reaction] = entry.value as int;
    }
    return result;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'roomId': roomId,
    'userId': userId,
    'username': username,
    'avatarUrl': avatarUrl,
    'content': content,
    'type': type.name,
    'reactions': reactions.map((k, v) => MapEntry(k.name, v)),
    'isVerified': isVerified,
    'isPremium': isPremium,
    'replyToId': replyToId,
    'metadata': metadata,
  };
}

class ChatRoom {
  final String id;
  final String name;
  final String? fightId;
  final int activeUsers;
  final bool isSlowMode;
  final int slowModeDelay;

  const ChatRoom({
    required this.id,
    required this.name,
    this.fightId,
    this.activeUsers = 0,
    this.isSlowMode = false,
    this.slowModeDelay = 5,
  });
  factory ChatRoom.fromMap(Map<String, dynamic> map) => ChatRoom(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    fightId: map['fightId'],
    activeUsers: map['activeUsers'] ?? 0,
    isSlowMode: map['isSlowMode'] ?? false,
    slowModeDelay: map['slowModeDelay'] ?? 5,
  );
}

class LiveChatService with ChangeNotifier {
  static final LiveChatService _instance = LiveChatService._internal();
  factory LiveChatService() => _instance;
  LiveChatService._internal();

  StreamSubscription<QuerySnapshot>? _messageSubscription;
  final List<ChatMessage> _messages = [];
  ChatRoom? _currentRoom;
  DateTime? _lastMessageSent;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  ChatRoom? get currentRoom => _currentRoom;
  int get messageCount => _messages.length;
  bool get canSendMessage {
    if (_currentRoom?.isSlowMode != true) return true;
    if (_lastMessageSent == null) return true;
    return DateTime.now().difference(_lastMessageSent!).inSeconds >=
        (_currentRoom?.slowModeDelay ?? 5);
  }

  Future<void> joinRoom(String roomId) async {
    await leaveRoom();
    debugPrint('💬 LiveChatService: Joining room $roomId...');
    try {
      final roomDoc = await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .get();
      if (roomDoc.exists) {
        _currentRoom = ChatRoom.fromMap({...roomDoc.data()!, 'id': roomDoc.id});
      }
      _messageSubscription = _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('sentAt', descending: true)
          .limit(100)
          .snapshots()
          .listen((snapshot) {
            _messages.clear();
            for (final doc in snapshot.docs.reversed) {
              _messages.add(ChatMessage.fromMap({...doc.data(), 'id': doc.id}));
            }
            notifyListeners();
          });
      await _firestore.collection('chat_rooms').doc(roomId).update({
        'activeUsers': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('LiveChatService: joinRoom failed: $e');
    }
  }

  Future<void> leaveRoom() async {
    if (_currentRoom != null) {
      await _firestore.collection('chat_rooms').doc(_currentRoom!.id).update({
        'activeUsers': FieldValue.increment(-1),
      });
    }
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    _messages.clear();
    _currentRoom = null;
    notifyListeners();
  }

  Future<bool> sendMessage({
    required String userId,
    required String username,
    required String content,
    MessageType type = MessageType.text,
    String? avatarUrl,
    String? replyToId,
  }) async {
    if (_currentRoom == null || !canSendMessage) return false;
    try {
      final modResult = await _functions
          .httpsCallable('moderateChatMessage')
          .call<Map<String, dynamic>>({
            'content': content,
            'userId': userId,
            'roomId': _currentRoom!.id,
          });
      if (modResult.data['blocked'] == true) {
        debugPrint('LiveChatService: Message blocked by moderation');
        return false;
      }
      await _firestore
          .collection('chat_rooms')
          .doc(_currentRoom!.id)
          .collection('messages')
          .add({
            'roomId': _currentRoom!.id,
            'userId': userId,
            'username': username,
            'avatarUrl': avatarUrl,
            'content': modResult.data['cleanContent'] ?? content,
            'type': type.name,
            'reactions': {},
            'isVerified': false,
            'isPremium': false,
            'replyToId': replyToId,
            'sentAt': FieldValue.serverTimestamp(),
          });
      _lastMessageSent = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('LiveChatService: Send failed: $e');
      return false;
    }
  }

  Future<void> addReaction(String messageId, ChatReaction reaction) async {
    if (_currentRoom == null) return;
    await _firestore
        .collection('chat_rooms')
        .doc(_currentRoom!.id)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.${reaction.name}': FieldValue.increment(1)});
  }

  Future<void> reportMessage(String messageId, String reason) async {
    if (_currentRoom == null) return;
    await _firestore.collection('chat_reports').add({
      'messageId': messageId,
      'roomId': _currentRoom!.id,
      'reason': reason,
      'reportedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    leaveRoom();
    super.dispose();
  }
}
