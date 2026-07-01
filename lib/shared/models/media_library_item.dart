import 'package:equatable/equatable.dart';

/// MediaLibraryItem — represents a single piece of ingested media in the DFC Media Library.
class MediaLibraryItem extends Equatable {
  final String id;
  final String mediaUrl;
  final String thumbnailUrl;
  final String caption;
  final DateTime postedAt;
  final int engagement;
  final String platform; // e.g. 'facebook', 'instagram', 'youtube'
  final List<String> tags;
  final String type; // e.g. 'video', 'image', 'reel', 'post'

  const MediaLibraryItem({
    required this.id,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.postedAt,
    required this.engagement,
    required this.platform,
    required this.tags,
    required this.type,
  });

  @override
  List<Object?> get props => [
    id,
    mediaUrl,
    thumbnailUrl,
    caption,
    postedAt,
    engagement,
    platform,
    tags,
    type,
  ];

  factory MediaLibraryItem.fromMap(Map<String, dynamic> map) {
    return MediaLibraryItem(
      id: map['id'] as String,
      mediaUrl: map['mediaUrl'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String,
      caption: map['caption'] as String,
      postedAt: DateTime.parse(map['postedAt'] as String),
      engagement: map['engagement'] as int,
      platform: map['platform'] as String,
      tags: List<String>.from(map['tags'] ?? []),
      type: map['type'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'postedAt': postedAt.toIso8601String(),
      'engagement': engagement,
      'platform': platform,
      'tags': tags,
      'type': type,
    };
  }
}
