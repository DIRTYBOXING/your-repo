import 'package:cloud_firestore/cloud_firestore.dart';

/// Visibility levels for short videos
enum VideoVisibility { public, followers, private }

/// Data model for DFC Reels / Short Videos (15-60 seconds fight clips)
class ShortVideoModel {
  final String id;
  final String creatorId;
  final String creatorName;
  final String creatorAvatarUrl;
  final String videoUrl;
  final String? videoAssetId;
  final String thumbnailUrl;
  final String? thumbnailAssetId;
  final String title;
  final String description;
  final List<String> hashtags;
  final List<String> mentions;
  final VideoVisibility visibility;
  final int durationSeconds;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final List<String> likedByIds;
  final List<String> savedByIds;
  final bool isFlagged;
  final String? flagReason;
  final DateTime createdAt;

  ShortVideoModel({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    this.creatorAvatarUrl = '',
    required this.videoUrl,
    this.videoAssetId,
    this.thumbnailUrl = '',
    this.thumbnailAssetId,
    required this.title,
    this.description = '',
    this.hashtags = const [],
    this.mentions = const [],
    this.visibility = VideoVisibility.public,
    this.durationSeconds = 30,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.viewCount = 0,
    this.likedByIds = const [],
    this.savedByIds = const [],
    this.isFlagged = false,
    this.flagReason,
    required this.createdAt,
  });

  factory ShortVideoModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return ShortVideoModel(
      id: documentId,
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      creatorAvatarUrl: data['creatorAvatarUrl'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      videoAssetId: data['videoAssetId'] as String?,
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      thumbnailAssetId: data['thumbnailAssetId'] as String?,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      hashtags: List<String>.from(data['hashtags'] ?? []),
      mentions: List<String>.from(data['mentions'] ?? []),
      visibility: _visibilityFromString(data['visibility'] ?? 'public'),
      durationSeconds: data['durationSeconds'] ?? 30,
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      shareCount: data['shareCount'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      likedByIds: List<String>.from(data['likedByIds'] ?? []),
      savedByIds: List<String>.from(data['savedByIds'] ?? []),
      isFlagged: data['isFlagged'] ?? false,
      flagReason: data['flagReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorAvatarUrl': creatorAvatarUrl,
      'videoUrl': videoUrl,
      'videoAssetId': videoAssetId,
      'thumbnailUrl': thumbnailUrl,
      'thumbnailAssetId': thumbnailAssetId,
      'title': title,
      'description': description,
      'hashtags': hashtags,
      'mentions': mentions,
      'visibility': visibility.name,
      'durationSeconds': durationSeconds,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'viewCount': viewCount,
      'likedByIds': likedByIds,
      'savedByIds': savedByIds,
      'isFlagged': isFlagged,
      'flagReason': flagReason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool isLikedBy(String userId) => likedByIds.contains(userId);
  bool isSavedBy(String userId) => savedByIds.contains(userId);
  bool isOwnedBy(String userId) => creatorId == userId;

  ShortVideoModel copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? creatorAvatarUrl,
    String? videoUrl,
    String? videoAssetId,
    String? thumbnailUrl,
    String? thumbnailAssetId,
    String? title,
    String? description,
    List<String>? hashtags,
    List<String>? mentions,
    VideoVisibility? visibility,
    int? durationSeconds,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    int? viewCount,
    List<String>? likedByIds,
    List<String>? savedByIds,
    bool? isFlagged,
    String? flagReason,
    DateTime? createdAt,
  }) {
    return ShortVideoModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      videoAssetId: videoAssetId ?? this.videoAssetId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      thumbnailAssetId: thumbnailAssetId ?? this.thumbnailAssetId,
      title: title ?? this.title,
      description: description ?? this.description,
      hashtags: hashtags ?? this.hashtags,
      mentions: mentions ?? this.mentions,
      visibility: visibility ?? this.visibility,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      viewCount: viewCount ?? this.viewCount,
      likedByIds: likedByIds ?? this.likedByIds,
      savedByIds: savedByIds ?? this.savedByIds,
      isFlagged: isFlagged ?? this.isFlagged,
      flagReason: flagReason ?? this.flagReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static VideoVisibility _visibilityFromString(String value) {
    switch (value) {
      case 'followers':
        return VideoVisibility.followers;
      case 'private':
        return VideoVisibility.private;
      case 'public':
      default:
        return VideoVisibility.public;
    }
  }
}

/// Comment on a short video / reel.
class ReelComment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String text;
  final DateTime createdAt;
  final int likeCount;

  const ReelComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl = '',
    required this.text,
    required this.createdAt,
    this.likeCount = 0,
  });
}
