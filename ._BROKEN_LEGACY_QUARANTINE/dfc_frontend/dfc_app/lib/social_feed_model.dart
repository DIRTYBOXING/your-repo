class SocialFeedModel {
  final String id;
  final String type;
  final String creatorName;
  final String creatorTier;
  final String gymName;
  final List<String> aiTags;
  final String mediaUrl;
  final String caption;
  final int likes;
  final int comments;
  final int shares;
  final bool isLive;
  final String? ppvRibbon;
  final Map<String, dynamic>? aiMetrics;

  SocialFeedModel({
    required this.id,
    required this.type,
    required this.creatorName,
    required this.creatorTier,
    required this.gymName,
    required this.aiTags,
    required this.mediaUrl,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.isLive,
    this.ppvRibbon,
    this.aiMetrics,
  });

  factory SocialFeedModel.fromJson(Map<String, dynamic> json) {
    return SocialFeedModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'post',
      creatorName: json['creatorName'] ?? '',
      creatorTier: json['creatorTier'] ?? 'BASIC',
      gymName: json['gymName'] ?? '',
      aiTags: List<String>.from(json['aiTags'] ?? []),
      mediaUrl: json['mediaUrl'] ?? '',
      caption: json['caption'] ?? '',
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      isLive: json['isLive'] ?? false,
      ppvRibbon: json['ppvRibbon'],
      aiMetrics: json['aiMetrics'],
    );
  }
}
