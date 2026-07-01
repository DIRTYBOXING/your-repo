import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FRIEND MODEL — Represents a bidirectional friendship
/// ═══════════════════════════════════════════════════════════════════════════
class Friend extends Equatable {
  final String id; // Connection ID
  final String userId; // Current user
  final String friendId; // Friend's user ID
  final String friendName;
  final String friendPhotoUrl;
  final String friendRole; // fighter, coach, promoter, etc.
  final bool isOnline;
  final DateTime? lastActive;
  final DateTime connectedAt;
  final int connectionStrength; // 0-100 score
  final int mutualFriends;
  final List<String> sharedInterests; // gyms, fighting styles, etc.
  final Map<String, dynamic>? metadata;

  const Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendName,
    this.friendPhotoUrl = '',
    this.friendRole = 'fighter',
    this.isOnline = false,
    this.lastActive,
    required this.connectedAt,
    this.connectionStrength = 50,
    this.mutualFriends = 0,
    this.sharedInterests = const [],
    this.metadata,
  });

  factory Friend.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friend(
      id: doc.id,
      userId: data['userId'] ?? '',
      friendId: data['friendId'] ?? '',
      friendName: data['friendName'] ?? 'Unknown',
      friendPhotoUrl: data['friendPhotoUrl'] ?? '',
      friendRole: data['friendRole'] ?? 'fighter',
      isOnline: data['isOnline'] ?? false,
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] as Timestamp).toDate()
          : null,
      connectedAt: data['connectedAt'] != null
          ? (data['connectedAt'] as Timestamp).toDate()
          : DateTime.now(),
      connectionStrength: data['connectionStrength'] ?? 50,
      mutualFriends: data['mutualFriends'] ?? 0,
      sharedInterests: List<String>.from(data['sharedInterests'] ?? []),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'friendId': friendId,
      'friendName': friendName,
      'friendPhotoUrl': friendPhotoUrl,
      'friendRole': friendRole,
      'isOnline': isOnline,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'connectedAt': Timestamp.fromDate(connectedAt),
      'connectionStrength': connectionStrength,
      'mutualFriends': mutualFriends,
      'sharedInterests': sharedInterests,
      'metadata': metadata,
    };
  }

  Friend copyWith({
    String? id,
    String? userId,
    String? friendId,
    String? friendName,
    String? friendPhotoUrl,
    String? friendRole,
    bool? isOnline,
    DateTime? lastActive,
    DateTime? connectedAt,
    int? connectionStrength,
    int? mutualFriends,
    List<String>? sharedInterests,
    Map<String, dynamic>? metadata,
  }) {
    return Friend(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      friendName: friendName ?? this.friendName,
      friendPhotoUrl: friendPhotoUrl ?? this.friendPhotoUrl,
      friendRole: friendRole ?? this.friendRole,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      connectedAt: connectedAt ?? this.connectedAt,
      connectionStrength: connectionStrength ?? this.connectionStrength,
      mutualFriends: mutualFriends ?? this.mutualFriends,
      sharedInterests: sharedInterests ?? this.sharedInterests,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    friendId,
    friendName,
    friendPhotoUrl,
    friendRole,
    isOnline,
    lastActive,
    connectedAt,
    connectionStrength,
    mutualFriends,
    sharedInterests,
  ];
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FRIEND REQUEST MODEL — Pending connection request
/// ═══════════════════════════════════════════════════════════════════════════
class FriendRequest extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final String senderRole;
  final String recipientId;
  final String status; // pending, accepted, rejected, expired
  final String? message;
  final int mutualFriendsCount;
  final List<String> mutualFriendIds;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime expiresAt;

  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl = '',
    this.senderRole = 'fighter',
    required this.recipientId,
    this.status = 'pending',
    this.message,
    this.mutualFriendsCount = 0,
    this.mutualFriendIds = const [],
    required this.createdAt,
    this.respondedAt,
    required this.expiresAt,
  });

  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      senderPhotoUrl: data['senderPhotoUrl'] ?? '',
      senderRole: data['senderRole'] ?? 'fighter',
      recipientId: data['recipientId'] ?? '',
      status: data['status'] ?? 'pending',
      message: data['message'],
      mutualFriendsCount: data['mutualFriendsCount'] ?? 0,
      mutualFriendIds: List<String>.from(data['mutualFriendIds'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 30)),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'senderRole': senderRole,
      'recipientId': recipientId,
      'status': status,
      'message': message,
      'mutualFriendsCount': mutualFriendsCount,
      'mutualFriendIds': mutualFriendIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == 'pending' && !isExpired;

  @override
  List<Object?> get props => [
    id,
    senderId,
    senderName,
    recipientId,
    status,
    mutualFriendsCount,
    createdAt,
    respondedAt,
    expiresAt,
  ];
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FRIEND ACTIVITY MODEL — Recent friend activity for feed
/// ═══════════════════════════════════════════════════════════════════════════
class FriendActivity extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String activityType; // post, fight, training, achievement, check_in
  final String title;
  final String description;
  final String? imageUrl;
  final Map<String, dynamic>? activityData;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByMe;

  const FriendActivity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl = '',
    required this.activityType,
    required this.title,
    this.description = '',
    this.imageUrl,
    this.activityData,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByMe = false,
  });

  factory FriendActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendActivity(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      activityType: data['activityType'] ?? 'post',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      activityData: data['activityData'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      isLikedByMe: data['isLikedByMe'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'activityType': activityType,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'activityData': activityData,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'isLikedByMe': isLikedByMe,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    activityType,
    title,
    createdAt,
    likesCount,
    commentsCount,
  ];
}
