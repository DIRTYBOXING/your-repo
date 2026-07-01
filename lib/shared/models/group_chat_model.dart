import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// GROUP CHAT MODEL — Multi-user group conversation
/// ═══════════════════════════════════════════════════════════════════════════
class GroupChat extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? avatarUrl;
  final List<String> memberIds;
  final Map<String, String> memberNames; // userId -> displayName
  final Map<String, String> memberPhotoUrls; // userId -> photoUrl
  final Map<String, String> memberRoles; // userId -> role (admin, member)
  final String createdBy;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final Map<String, int> unreadCounts; // userId -> count
  final bool isActive;
  final String groupType; // training, gym, event, sparring, general
  final Map<String, dynamic>? settings; // mute, permissions, etc.

  const GroupChat({
    required this.id,
    required this.name,
    this.description = '',
    this.avatarUrl,
    required this.memberIds,
    required this.memberNames,
    this.memberPhotoUrls = const {},
    this.memberRoles = const {},
    required this.createdBy,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
    this.unreadCounts = const {},
    this.isActive = true,
    this.groupType = 'general',
    this.settings,
  });

  factory GroupChat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupChat(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Group',
      description: data['description'] ?? '',
      avatarUrl: data['avatarUrl'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberNames: Map<String, String>.from(data['memberNames'] ?? {}),
      memberPhotoUrls: Map<String, String>.from(data['memberPhotoUrls'] ?? {}),
      memberRoles: Map<String, String>.from(data['memberRoles'] ?? {}),
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastMessage: data['lastMessage'],
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastSenderId: data['lastSenderId'],
      unreadCounts: Map<String, int>.from(
        (data['unreadCounts'] ?? {}).map((k, v) => MapEntry(k, v as int)),
      ),
      isActive: data['isActive'] ?? true,
      groupType: data['groupType'] ?? 'general',
      settings: data['settings'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'memberPhotoUrls': memberPhotoUrls,
      'memberRoles': memberRoles,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'lastSenderId': lastSenderId,
      'unreadCounts': unreadCounts,
      'isActive': isActive,
      'groupType': groupType,
      'settings': settings,
    };
  }

  bool isAdmin(String userId) {
    return memberRoles[userId] == 'admin' || createdBy == userId;
  }

  bool isMember(String userId) {
    return memberIds.contains(userId);
  }

  int getMemberCount() => memberIds.length;

  String getMemberNamesDisplay({int maxShow = 3}) {
    if (memberNames.isEmpty) return 'No members';
    final names = memberNames.values.take(maxShow).join(', ');
    final remaining = memberNames.length - maxShow;
    return remaining > 0 ? '$names +$remaining more' : names;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    memberIds,
    createdAt,
    lastMessageAt,
    isActive,
    groupType,
  ];
}

/// ═══════════════════════════════════════════════════════════════════════════
/// GROUP MESSAGE MODEL — Message in a group chat
/// ═══════════════════════════════════════════════════════════════════════════
class GroupMessage extends Equatable {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final String text;
  final DateTime sentAt;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSender;
  final String? attachmentType; // image, video, audio, file
  final String? attachmentUrl;
  final String? attachmentName;
  final int? attachmentSize;
  final Map<String, DateTime> readBy; // userId -> read timestamp
  final bool isSystemMessage; // member joined/left, etc.
  final Map<String, dynamic>? metadata;

  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl = '',
    required this.text,
    required this.sentAt,
    this.replyToId,
    this.replyToText,
    this.replyToSender,
    this.attachmentType,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.readBy = const {},
    this.isSystemMessage = false,
    this.metadata,
  });

  factory GroupMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMessage(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      senderPhotoUrl: data['senderPhotoUrl'] ?? '',
      text: data['text'] ?? '',
      sentAt: data['sentAt'] != null
          ? (data['sentAt'] as Timestamp).toDate()
          : DateTime.now(),
      replyToId: data['replyToId'],
      replyToText: data['replyToText'],
      replyToSender: data['replyToSender'],
      attachmentType: data['attachmentType'],
      attachmentUrl: data['attachmentUrl'],
      attachmentName: data['attachmentName'],
      attachmentSize: data['attachmentSize'],
      readBy: Map<String, DateTime>.from(
        (data['readBy'] ?? {}).map(
          (k, v) => MapEntry(k, (v as Timestamp).toDate()),
        ),
      ),
      isSystemMessage: data['isSystemMessage'] ?? false,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'sentAt': Timestamp.fromDate(sentAt),
      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToSender': replyToSender,
      'attachmentType': attachmentType,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'attachmentSize': attachmentSize,
      'readBy': readBy.map((k, v) => MapEntry(k, Timestamp.fromDate(v))),
      'isSystemMessage': isSystemMessage,
      'metadata': metadata,
    };
  }

  bool isReadBy(String userId) {
    return readBy.containsKey(userId);
  }

  int getReadCount() => readBy.length;

  @override
  List<Object?> get props => [
    id,
    groupId,
    senderId,
    text,
    sentAt,
    isSystemMessage,
  ];
}
