import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ENHANCED DFC MESSAGING — Flow States + Rich Attachments
/// ═══════════════════════════════════════════════════════════════════════════

/// Message workflow states
enum MessageStatus {
  draft, // Saved but not sent
  sending, // In progress
  sent, // Delivered to server
  delivered, // Received by recipient's device
  read, // Opened by recipient
  failed, // Send failed
  archived, // User archived
  deleted, // Soft delete
}

/// Inbox categories for auto-sorting
enum InboxCategory {
  primary, // Personal/direct messages
  social, // Social media, community
  promotions, // Marketing, announcements
  updates, // System notifications
  spam, // Filtered
}

/// Message priority
enum MessagePriority { low, normal, high, urgent }

/// Enhanced attachment with metadata
class MessageAttachment extends Equatable {
  final String id;
  final String type; // image, video, audio, document, pdf, other
  final String url;
  final String name;
  final int size; // bytes
  final String? mimeType;
  final String? thumbnailUrl;
  final int? width; // for images/videos
  final int? height;
  final int? duration; // for audio/video (seconds)
  final DateTime uploadedAt;
  final String uploadedBy;
  final bool scanned; // virus/malware scan status
  final Map<String, dynamic>? metadata;

  const MessageAttachment({
    required this.id,
    required this.type,
    required this.url,
    required this.name,
    required this.size,
    this.mimeType,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.duration,
    required this.uploadedAt,
    required this.uploadedBy,
    this.scanned = false,
    this.metadata,
  });

  factory MessageAttachment.fromMap(Map<String, dynamic> d) {
    return MessageAttachment(
      id: d['id'] ?? '',
      type: d['type'] ?? 'file',
      url: d['url'] ?? '',
      name: d['name'] ?? 'Untitled',
      size: d['size'] ?? 0,
      mimeType: d['mimeType'],
      thumbnailUrl: d['thumbnailUrl'],
      width: d['width'],
      height: d['height'],
      duration: d['duration'],
      uploadedAt: (d['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      uploadedBy: d['uploadedBy'] ?? '',
      scanned: d['scanned'] ?? false,
      metadata: d['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'url': url,
    'name': name,
    'size': size,
    'mimeType': mimeType,
    'thumbnailUrl': thumbnailUrl,
    'width': width,
    'height': height,
    'duration': duration,
    'uploadedAt': Timestamp.fromDate(uploadedAt),
    'uploadedBy': uploadedBy,
    'scanned': scanned,
    'metadata': metadata,
  };

  @override
  List<Object?> get props => [id, url, name, size, uploadedAt];
}

/// Enhanced message with workflow states
class EnhancedMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final DateTime sentAt;
  final MessageStatus status;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final MessagePriority priority;
  final InboxCategory category;

  // Threading
  final String? replyToId;
  final String? replyToText;
  final String? threadId; // Group related messages

  // Attachments (multiple)
  final List<MessageAttachment> attachments;

  // Actions
  final bool starred;
  final bool flagged;
  final bool archived;
  final List<String> labels; // custom tags

  // Reactions
  final Map<String, List<String>> reactions; // emoji → [userIds]

  // Edit history
  final bool edited;
  final DateTime? editedAt;
  final String? originalText;

  // Scheduled send
  final DateTime? scheduledFor;

  // Metadata
  final Map<String, dynamic>? metadata;

  const EnhancedMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    required this.sentAt,
    this.status = MessageStatus.sent,
    this.deliveredAt,
    this.readAt,
    this.priority = MessagePriority.normal,
    this.category = InboxCategory.primary,
    this.replyToId,
    this.replyToText,
    this.threadId,
    this.attachments = const [],
    this.starred = false,
    this.flagged = false,
    this.archived = false,
    this.labels = const [],
    this.reactions = const {},
    this.edited = false,
    this.editedAt,
    this.originalText,
    this.scheduledFor,
    this.metadata,
  });

  factory EnhancedMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // Parse attachments
    final rawAttachments = d['attachments'] as List?;
    final attachments =
        rawAttachments
            ?.map((a) => MessageAttachment.fromMap(a as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse labels
    final rawLabels = d['labels'];
    final labels = rawLabels is Iterable
        ? rawLabels.map((e) => e.toString()).toList()
        : <String>[];

    // Parse reactions
    final rawReactions = d['reactions'] as Map?;
    final reactions = <String, List<String>>{};
    if (rawReactions != null) {
      for (final entry in rawReactions.entries) {
        final emoji = entry.key;
        final userIds = entry.value is Iterable
            ? (entry.value as Iterable).map((e) => e.toString()).toList()
            : <String>[];
        reactions[emoji] = userIds;
      }
    }

    return EnhancedMessage(
      id: doc.id,
      conversationId: d['conversationId'] ?? '',
      senderId: d['senderId'] ?? '',
      senderName: d['senderName'] ?? '',
      senderPhotoUrl: d['senderPhotoUrl'],
      text: d['text'] ?? '',
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => MessageStatus.sent,
      ),
      deliveredAt: (d['deliveredAt'] as Timestamp?)?.toDate(),
      readAt: (d['readAt'] as Timestamp?)?.toDate(),
      priority: MessagePriority.values.firstWhere(
        (e) => e.name == d['priority'],
        orElse: () => MessagePriority.normal,
      ),
      category: InboxCategory.values.firstWhere(
        (e) => e.name == d['category'],
        orElse: () => InboxCategory.primary,
      ),
      replyToId: d['replyToId'],
      replyToText: d['replyToText'],
      threadId: d['threadId'],
      attachments: attachments,
      starred: d['starred'] ?? false,
      flagged: d['flagged'] ?? false,
      archived: d['archived'] ?? false,
      labels: labels,
      reactions: reactions,
      edited: d['edited'] ?? false,
      editedAt: (d['editedAt'] as Timestamp?)?.toDate(),
      originalText: d['originalText'],
      scheduledFor: (d['scheduledFor'] as Timestamp?)?.toDate(),
      metadata: d['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'conversationId': conversationId,
    'senderId': senderId,
    'senderName': senderName,
    'senderPhotoUrl': senderPhotoUrl,
    'text': text,
    'sentAt': Timestamp.fromDate(sentAt),
    'status': status.name,
    'deliveredAt': deliveredAt != null
        ? Timestamp.fromDate(deliveredAt!)
        : null,
    'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    'priority': priority.name,
    'category': category.name,
    'replyToId': replyToId,
    'replyToText': replyToText,
    'threadId': threadId,
    'attachments': attachments.map((a) => a.toMap()).toList(),
    'starred': starred,
    'flagged': flagged,
    'archived': archived,
    'labels': labels,
    'reactions': reactions,
    'edited': edited,
    'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    'originalText': originalText,
    'scheduledFor': scheduledFor != null
        ? Timestamp.fromDate(scheduledFor!)
        : null,
    'metadata': metadata,
  };

  EnhancedMessage copyWith({
    MessageStatus? status,
    DateTime? deliveredAt,
    DateTime? readAt,
    bool? starred,
    bool? flagged,
    bool? archived,
    List<String>? labels,
    Map<String, List<String>>? reactions,
    bool? edited,
    DateTime? editedAt,
    String? originalText,
    String? text,
  }) {
    return EnhancedMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      text: text ?? this.text,
      sentAt: sentAt,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      priority: priority,
      category: category,
      replyToId: replyToId,
      replyToText: replyToText,
      threadId: threadId,
      attachments: attachments,
      starred: starred ?? this.starred,
      flagged: flagged ?? this.flagged,
      archived: archived ?? this.archived,
      labels: labels ?? this.labels,
      reactions: reactions ?? this.reactions,
      edited: edited ?? this.edited,
      editedAt: editedAt ?? this.editedAt,
      originalText: originalText ?? this.originalText,
      scheduledFor: scheduledFor,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [id, text, sentAt, status, attachments];
}

/// Enhanced conversation with categories
class EnhancedConversation extends Equatable {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotoUrls;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final Map<String, int> unreadCounts;
  final DateTime createdAt;

  // Enhanced properties
  final InboxCategory category;
  final bool muted;
  final bool pinned;
  final bool archived;
  final List<String> labels;
  final String? draftMessage;
  final List<MessageAttachment> draftAttachments;
  final Map<String, dynamic>? metadata;

  const EnhancedConversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.participantPhotoUrls = const {},
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
    this.unreadCounts = const {},
    required this.createdAt,
    this.category = InboxCategory.primary,
    this.muted = false,
    this.pinned = false,
    this.archived = false,
    this.labels = const [],
    this.draftMessage,
    this.draftAttachments = const [],
    this.metadata,
  });

  factory EnhancedConversation.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final rawParticipants = d['participants'];
    final participants = rawParticipants is Iterable
        ? rawParticipants
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];

    final rawParticipantNames = d['participantNames'];
    final participantNames = <String, String>{};
    if (rawParticipantNames is Map) {
      for (final entry in rawParticipantNames.entries) {
        final key = entry.key?.toString() ?? '';
        if (key.isNotEmpty) {
          participantNames[key] = entry.value?.toString() ?? 'User';
        }
      }
    }

    final rawParticipantPhotoUrls = d['participantPhotoUrls'];
    final participantPhotoUrls = <String, String>{};
    if (rawParticipantPhotoUrls is Map) {
      for (final entry in rawParticipantPhotoUrls.entries) {
        final key = entry.key?.toString() ?? '';
        if (key.isNotEmpty) {
          participantPhotoUrls[key] = entry.value?.toString() ?? '';
        }
      }
    }

    final rawUnreadCounts = d['unreadCounts'];
    final unreadCounts = <String, int>{};
    if (rawUnreadCounts is Map) {
      for (final entry in rawUnreadCounts.entries) {
        final key = entry.key?.toString() ?? '';
        if (key.isNotEmpty) {
          final value = entry.value;
          unreadCounts[key] = (value is int)
              ? value
              : (value is num)
              ? value.toInt()
              : int.tryParse(value?.toString() ?? '') ?? 0;
        }
      }
    }

    final rawLabels = d['labels'];
    final labels = rawLabels is Iterable
        ? rawLabels.map((e) => e.toString()).toList()
        : <String>[];

    final rawDraftAttachments = d['draftAttachments'] as List?;
    final draftAttachments =
        rawDraftAttachments
            ?.map((a) => MessageAttachment.fromMap(a as Map<String, dynamic>))
            .toList() ??
        [];

    return EnhancedConversation(
      id: doc.id,
      participants: participants,
      participantNames: participantNames,
      participantPhotoUrls: participantPhotoUrls,
      lastMessage: d['lastMessage']?.toString(),
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
      lastSenderId: d['lastSenderId']?.toString(),
      unreadCounts: unreadCounts,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: InboxCategory.values.firstWhere(
        (e) => e.name == d['category'],
        orElse: () => InboxCategory.primary,
      ),
      muted: d['muted'] ?? false,
      pinned: d['pinned'] ?? false,
      archived: d['archived'] ?? false,
      labels: labels,
      draftMessage: d['draftMessage'],
      draftAttachments: draftAttachments,
      metadata: d['metadata'] as Map<String, dynamic>?,
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
    'category': category.name,
    'muted': muted,
    'pinned': pinned,
    'archived': archived,
    'labels': labels,
    'draftMessage': draftMessage,
    'draftAttachments': draftAttachments.map((a) => a.toMap()).toList(),
    'metadata': metadata,
  };

  @override
  List<Object?> get props => [
    id,
    participants,
    lastMessage,
    lastMessageAt,
    pinned,
    archived,
  ];
}
