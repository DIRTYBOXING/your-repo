import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Post content type for FightWire 2.0
enum PostContentType { text, photo, video, article, promo }

/// Social post model for community content
class PostModel extends Equatable {
  final String id;
  final String authorId;
  final String authorType; // fighter, coach, gym, promoter, fan
  final String? regionId;
  final String? eventId;
  final PostContentType postType;
  final String content;
  final List<String> mediaUrls;
  final String? mediaType; // image, video, mixed
  final List<String> hashtags;
  final List<String> mentions;
  final String? linkedFighterId;
  final String? linkedEventId;
  final String? linkedGymId;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final bool isSponsored;
  final String? sponsorId;
  final bool isPinned;
  final bool isEdited;
  final DateTime? editedAt;
  final String visibility; // public, followers, private
  final bool allowComments;
  final bool allowShares;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostModel({
    required this.id,
    required this.authorId,
    required this.authorType,
    this.regionId,
    this.eventId,
    this.postType = PostContentType.text,
    required this.content,
    this.mediaUrls = const [],
    this.mediaType,
    this.hashtags = const [],
    this.mentions = const [],
    this.linkedFighterId,
    this.linkedEventId,
    this.linkedGymId,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.isSponsored = false,
    this.sponsorId,
    this.isPinned = false,
    this.isEdited = false,
    this.editedAt,
    this.visibility = 'public',
    this.allowComments = true,
    this.allowShares = true,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Has media content
  bool get hasMedia => mediaUrls.isNotEmpty;

  /// Total engagement count
  int get engagementCount => likesCount + commentsCount + sharesCount;

  /// Engagement rate
  double get engagementRate {
    if (viewsCount == 0) return 0;
    return (engagementCount / viewsCount) * 100;
  }

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorType: data['authorType'] ?? 'fan',
      regionId: data['regionId'],
      eventId: data['eventId'],
      postType: PostContentType.values.firstWhere(
        (t) => t.name == data['postType'],
        orElse: () => PostContentType.text,
      ),
      content: data['content'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      mediaType: data['mediaType'],
      hashtags: List<String>.from(data['hashtags'] ?? []),
      mentions: List<String>.from(data['mentions'] ?? []),
      linkedFighterId: data['linkedFighterId'],
      linkedEventId: data['linkedEventId'],
      linkedGymId: data['linkedGymId'],
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      sharesCount: data['sharesCount'] ?? 0,
      viewsCount: data['viewsCount'] ?? 0,
      isSponsored: data['isSponsored'] ?? false,
      sponsorId: data['sponsorId'],
      isPinned: data['isPinned'] ?? false,
      isEdited: data['isEdited'] ?? false,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      visibility: data['visibility'] ?? 'public',
      allowComments: data['allowComments'] ?? true,
      allowShares: data['allowShares'] ?? true,
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorType': authorType,
      'regionId': regionId,
      'eventId': eventId,
      'postType': postType.name,
      'content': content,
      'mediaUrls': mediaUrls,
      'mediaType': mediaType,
      'hashtags': hashtags,
      'mentions': mentions,
      'linkedFighterId': linkedFighterId,
      'linkedEventId': linkedEventId,
      'linkedGymId': linkedGymId,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'viewsCount': viewsCount,
      'isSponsored': isSponsored,
      'sponsorId': sponsorId,
      'isPinned': isPinned,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'visibility': visibility,
      'allowComments': allowComments,
      'allowShares': allowShares,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorType,
    String? regionId,
    String? eventId,
    PostContentType? postType,
    String? content,
    List<String>? mediaUrls,
    String? mediaType,
    List<String>? hashtags,
    List<String>? mentions,
    String? linkedFighterId,
    String? linkedEventId,
    String? linkedGymId,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
    bool? isSponsored,
    String? sponsorId,
    bool? isPinned,
    bool? isEdited,
    DateTime? editedAt,
    String? visibility,
    bool? allowComments,
    bool? allowShares,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorType: authorType ?? this.authorType,
      regionId: regionId ?? this.regionId,
      eventId: eventId ?? this.eventId,
      postType: postType ?? this.postType,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      hashtags: hashtags ?? this.hashtags,
      mentions: mentions ?? this.mentions,
      linkedFighterId: linkedFighterId ?? this.linkedFighterId,
      linkedEventId: linkedEventId ?? this.linkedEventId,
      linkedGymId: linkedGymId ?? this.linkedGymId,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isSponsored: isSponsored ?? this.isSponsored,
      sponsorId: sponsorId ?? this.sponsorId,
      isPinned: isPinned ?? this.isPinned,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      visibility: visibility ?? this.visibility,
      allowComments: allowComments ?? this.allowComments,
      allowShares: allowShares ?? this.allowShares,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, authorId, content, createdAt];
}

/// Comment moderation status
enum CommentStatus { approved, filtered, removed }

/// Comment model for post comments
class CommentModel extends Equatable {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final String? parentCommentId;
  final int likesCount;
  final int repliesCount;
  final bool isEdited;
  final DateTime? editedAt;
  final List<String> mentions;
  final bool isPinned; // Promoters can pin fight info
  final CommentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    this.parentCommentId,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.isEdited = false,
    this.editedAt,
    this.mentions = const [],
    this.isPinned = false,
    this.status = CommentStatus.approved,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Is this a reply to another comment
  bool get isReply => parentCommentId != null;

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      content: data['content'] ?? '',
      parentCommentId: data['parentCommentId'],
      likesCount: data['likesCount'] ?? 0,
      repliesCount: data['repliesCount'] ?? 0,
      isEdited: data['isEdited'] ?? false,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      mentions: List<String>.from(data['mentions'] ?? []),
      isPinned: data['isPinned'] ?? false,
      status: CommentStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => CommentStatus.approved,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'content': content,
      'parentCommentId': parentCommentId,
      'likesCount': likesCount,
      'repliesCount': repliesCount,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isPinned': isPinned,
      'status': status.name,
      'mentions': mentions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CommentModel copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? content,
    String? parentCommentId,
    int? likesCount,
    int? repliesCount,
    bool? isEdited,
    DateTime? editedAt,
    List<String>? mentions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      mentions: mentions ?? this.mentions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, postId, authorId, content];
}
