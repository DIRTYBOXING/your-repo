import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Types of in-app notifications
enum NotificationType {
  fightOffer,
  matchFound,
  eventInvite,
  socialLike,
  socialComment,
  socialFollow,
  postMention,
  achievement,
  systemAlert,
  promoterMessage,
  trainingReminder,
  safetyAlert,
  databankUpdate,
  friendRequest,
  friendRequestAccepted,
  friendRequestRejected,
  general;

  String get icon {
    switch (this) {
      case NotificationType.fightOffer:
        return '🥊';
      case NotificationType.matchFound:
        return '🤝';
      case NotificationType.eventInvite:
        return '🎪';
      case NotificationType.socialLike:
        return '❤️';
      case NotificationType.socialComment:
        return '💬';
      case NotificationType.socialFollow:
        return '👤';
      case NotificationType.postMention:
        return '📣';
      case NotificationType.achievement:
        return '🏆';
      case NotificationType.systemAlert:
        return '⚙️';
      case NotificationType.promoterMessage:
        return '📩';
      case NotificationType.trainingReminder:
        return '🏋️';
      case NotificationType.safetyAlert:
        return '🛡️';
      case NotificationType.databankUpdate:
        return '📊';
      case NotificationType.friendRequest:
        return '🤝';
      case NotificationType.friendRequestAccepted:
        return '✅';
      case NotificationType.friendRequestRejected:
        return '❌';
      case NotificationType.general:
        return '🔔';
    }
  }

  String get label {
    switch (this) {
      case NotificationType.fightOffer:
        return 'Fight Offer';
      case NotificationType.matchFound:
        return 'Match Found';
      case NotificationType.eventInvite:
        return 'Event Invite';
      case NotificationType.socialLike:
        return 'Like';
      case NotificationType.socialComment:
        return 'Comment';
      case NotificationType.socialFollow:
        return 'New Follower';
      case NotificationType.postMention:
        return 'Mention';
      case NotificationType.achievement:
        return 'Achievement';
      case NotificationType.systemAlert:
        return 'System';
      case NotificationType.promoterMessage:
        return 'Promoter';
      case NotificationType.trainingReminder:
        return 'Training';
      case NotificationType.safetyAlert:
        return 'Safety';
      case NotificationType.databankUpdate:
        return 'DataBank';
      case NotificationType.friendRequest:
        return 'Friend Request';
      case NotificationType.friendRequestAccepted:
        return 'Friend Accepted';
      case NotificationType.friendRequestRejected:
        return 'Friend Declined';
      case NotificationType.general:
        return 'Notification';
    }
  }
}

/// In-app notification model stored in Firestore
class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final String? actionRoute; // GoRouter path to navigate on tap
  final String? senderId; // optional: user who triggered
  final String? senderName;
  final String? senderAvatar;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.actionRoute,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.metadata,
    required this.createdAt,
  });

  /// Firestore → Model
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _parseType(data['type']),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      isRead: data['isRead'] ?? false,
      actionRoute: data['actionRoute'],
      senderId: data['senderId'],
      senderName: data['senderName'],
      senderAvatar: data['senderAvatar'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Model → Firestore
  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'type': type.name,
    'title': title,
    'body': body,
    'isRead': isRead,
    'actionRoute': actionRoute,
    'senderId': senderId,
    'senderName': senderName,
    'senderAvatar': senderAvatar,
    'metadata': metadata,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    bool? isRead,
    String? actionRoute,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Human-friendly time-ago string
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  static NotificationType _parseType(String? raw) {
    if (raw == null) return NotificationType.general;
    return NotificationType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => NotificationType.general,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    title,
    body,
    isRead,
    actionRoute,
    createdAt,
  ];
}
