import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC Messaging — Data Models
/// Conversation = thread between 2+ users
/// Message = single chat message in a conversation
/// ═══════════════════════════════════════════════════════════════════════════

class Conversation extends Equatable {
  final String id;
  final List<String> participants; // user IDs
  final Map<String, String> participantNames; // uid → display name
  final Map<String, String> participantPhotoUrls; // uid → photo url
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final Map<String, int> unreadCounts; // uid → unread count
  final DateTime createdAt;
  final bool isGroup;
  final String? groupName;
  final String? groupPhotoUrl;
  final Map<String, DateTime> typingUsers; // uid → timestamp of last typing event

  const Conversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.participantPhotoUrls = const {},
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
    this.unreadCounts = const {},
    required this.createdAt,
    this.isGroup = false,
    this.groupName,
    this.groupPhotoUrl,
    this.typingUsers = const {},
  });

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final rawParticipants = d['participants'];
    final participants = rawParticipants is Iterable
        ? rawParticipants
              .map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];

    final rawParticipantNames = d['participantNames'];
    final participantNames = <String, String>{};
    if (rawParticipantNames is Map) {
      for (final entry in rawParticipantNames.entries) {
        final key = entry.key?.toString() ?? '';
        if (key.isEmpty) continue;
        participantNames[key] = entry.value?.toString() ?? 'User';
      }
    }

    final rawParticipantPhotoUrls = d['participantPhotoUrls'];
    final participantPhotoUrls = <String, String>{};
    if (rawParticipantPhotoUrls is Map) {
      for (final entry in rawParticipantPhotoUrls.entries) {
        final key = entry.key?.toString() ?? '';
        if (key.isEmpty) continue;
        participantPhotoUrls[key] = entry.value?.toString() ?? '';
      }
    }

    final rawUnreadCounts = d['unreadCounts'];
    final unreadCounts = <String, int>{};
    if (rawUnreadCounts is Map) {
      for (final entry in rawUnreadCounts.entries) {
        final key = entry.key?.toString() ?? '';
        if (key.isEmpty) continue;
        final value = entry.value;
        if (value is int) {
          unreadCounts[key] = value;
        } else if (value is num) {
          unreadCounts[key] = value.toInt();
        } else {
          unreadCounts[key] = int.tryParse(value?.toString() ?? '') ?? 0;
        }
      }
    }

    // Parse typing users
    final rawTyping = d['typingUsers'];
    final typingUsers = <String, DateTime>{};
    if (rawTyping is Map) {
      for (final entry in rawTyping.entries) {
        final key = entry.key?.toString() ?? '';
        if (key.isEmpty) continue;
        if (entry.value is Timestamp) {
          typingUsers[key] = (entry.value as Timestamp).toDate();
        }
      }
    }

    return Conversation(
      id: doc.id,
      participants: participants,
      participantNames: participantNames,
      participantPhotoUrls: participantPhotoUrls,
      lastMessage: d['lastMessage']?.toString(),
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
      lastSenderId: d['lastSenderId']?.toString(),
      unreadCounts: unreadCounts,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGroup: d['isGroup'] ?? false,
      groupName: d['groupName']?.toString(),
      groupPhotoUrl: d['groupPhotoUrl']?.toString(),
      typingUsers: typingUsers,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'participants': participants,
    'participantNames': participantNames,
    'participantPhotoUrls': participantPhotoUrls,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt != null
        ? Timestamp.fromDate(lastMessageAt!)
        : null,
    'lastSenderId': lastSenderId,
    'unreadCounts': unreadCounts,
    'createdAt': Timestamp.fromDate(createdAt),
    'isGroup': isGroup,
    if (groupName != null) 'groupName': groupName,
    if (groupPhotoUrl != null) 'groupPhotoUrl': groupPhotoUrl,
  };

  @override
  List<Object?> get props => [
    id,
    participants,
    participantNames,
    participantPhotoUrls,
    lastMessage,
    lastMessageAt,
    isGroup,
    groupName,
  ];
}

class Message extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;
  final bool read;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final String? replyToId; // ID of message being replied to
  final String? replyToText; // snippet preview of replied message
  final String? attachmentType; // image | file | voice_note | video_message
  final String? attachmentUrl;
  final String? attachmentName;
  final int? attachmentSize;
  final int? voiceDurationMs; // duration of voice note in milliseconds
  final Map<String, String> reactions; // userId → emoji reaction
  final String status; // sent | delivered | read

  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
    this.read = false,
    this.readAt,
    this.deliveredAt,
    this.replyToId,
    this.replyToText,
    this.attachmentType,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.voiceDurationMs,
    this.reactions = const {},
    this.status = 'sent',
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final rawAttachmentSize = d['attachmentSize'];
    int? attachmentSize;
    if (rawAttachmentSize is int) {
      attachmentSize = rawAttachmentSize;
    } else if (rawAttachmentSize is num) {
      attachmentSize = rawAttachmentSize.toInt();
    } else if (rawAttachmentSize != null) {
      attachmentSize = int.tryParse(rawAttachmentSize.toString());
    }

    // Parse reactions map
    final rawReactions = d['reactions'];
    final reactions = <String, String>{};
    if (rawReactions is Map) {
      for (final entry in rawReactions.entries) {
        final key = entry.key?.toString() ?? '';
        if (key.isEmpty) continue;
        reactions[key] = entry.value?.toString() ?? '';
      }
    }

    // Parse voiceDurationMs
    int? voiceDurationMs;
    final rawDuration = d['voiceDurationMs'];
    if (rawDuration is int) {
      voiceDurationMs = rawDuration;
    } else if (rawDuration is num) {
      voiceDurationMs = rawDuration.toInt();
    }

    return Message(
      id: doc.id,
      senderId: d['senderId']?.toString() ?? '',
      senderName: d['senderName']?.toString() ?? '',
      text: d['text']?.toString() ?? '',
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: d['read'] ?? false,
      readAt: (d['readAt'] as Timestamp?)?.toDate(),
      deliveredAt: (d['deliveredAt'] as Timestamp?)?.toDate(),
      replyToId: d['replyToId']?.toString(),
      replyToText: d['replyToText']?.toString(),
      attachmentType: d['attachmentType']?.toString(),
      attachmentUrl: d['attachmentUrl']?.toString(),
      attachmentName: d['attachmentName']?.toString(),
      attachmentSize: attachmentSize,
      voiceDurationMs: voiceDurationMs,
      reactions: reactions,
      status: d['status']?.toString() ?? 'sent',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'sentAt': Timestamp.fromDate(sentAt),
    'read': read,
    if (readAt != null) 'readAt': Timestamp.fromDate(readAt!),
    if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
    'replyToId': replyToId,
    'replyToText': replyToText,
    'attachmentType': attachmentType,
    'attachmentUrl': attachmentUrl,
    'attachmentName': attachmentName,
    'attachmentSize': attachmentSize,
    if (voiceDurationMs != null) 'voiceDurationMs': voiceDurationMs,
    if (reactions.isNotEmpty) 'reactions': reactions,
    'status': status,
  };

  @override
  List<Object?> get props => [
    id,
    senderId,
    text,
    sentAt,
    attachmentType,
    attachmentUrl,
    attachmentName,
    attachmentSize,
    voiceDurationMs,
    reactions,
    status,
  ];
}
