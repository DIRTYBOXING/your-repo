class PostMediaAttachment {
  final String url;
  final String type;
  final String? previewUrl;

  const PostMediaAttachment({
    required this.url,
    required this.type,
    this.previewUrl,
  });

  bool get isImage => type == 'image';
  bool get isVideo => type == 'video' || type == 'external_video';
  bool get isExternalVideo => type == 'external_video';
  bool get isEmbeddableVideo => type == 'video';

  static String inferType(String url) {
    final normalized = url.trim().toLowerCase();
    final uri = Uri.tryParse(normalized);
    final host = uri?.host.toLowerCase() ?? '';
    final path = uri?.path.toLowerCase() ?? normalized;

    const directVideoExtensions = [
      '.m3u8',
      '.mpd',
      '.mp4',
      '.mov',
      '.m4v',
      '.webm',
      '.avi',
      '.mkv',
    ];
    if (directVideoExtensions.any(path.endsWith)) {
      return 'video';
    }

    if (host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('vimeo.com') ||
        host.contains('tiktok.com') ||
        host.contains('instagram.com') ||
        host.contains('facebook.com') ||
        host.contains('fb.watch')) {
      return 'external_video';
    }

    return 'image';
  }

  static String? derivePreviewUrl(String url, {String? thumbnailUrl}) {
    final normalizedUrl = url.trim();
    if (normalizedUrl.isEmpty) {
      return null;
    }

    final safeThumbnail = thumbnailUrl?.trim();
    if (safeThumbnail != null && safeThumbnail.isNotEmpty) {
      return safeThumbnail;
    }

    final inferredType = inferType(normalizedUrl);
    if (inferredType == 'image') {
      return normalizedUrl;
    }

    final videoId = _extractYouTubeId(normalizedUrl);
    if (videoId != null) {
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }

    return null;
  }

  static String? _extractYouTubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      final segment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
      return segment.isEmpty ? null : segment;
    }

    if (host.contains('youtube.com')) {
      final queryValue = uri.queryParameters['v'];
      if (queryValue != null && queryValue.isNotEmpty) {
        return queryValue;
      }
      if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'embed') {
        return uri.pathSegments[1];
      }
    }

    return null;
  }
}

class Post {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;

  /// Engagement fields
  final int likes;
  final int commentCount;
  final int shareCount;
  final List<String> likedBy;
  final List<String> bookmarkedBy;

  /// Media fields
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final List<String> mediaAssetIds;
  final String? thumbnailUrl;
  final String? externalVideoUrl;

  /// Display fields
  final String? userDisplayName;
  final String? userRole;
  final String? userAvatarUrl;
  final String postType; // 'text', 'fight_card', 'announcement', 'media'

  /// Social graph
  final bool isVerified;

  /// Edit tracking
  final DateTime? editedAt;

  /// Location tag
  final String? location;

  /// Audience visibility: 'public', 'followers', 'private'
  final String visibility;

  // Combat-specific reactions (DFC 2030)
  final int respectCount; // 🥋 Respect
  final int strongCount; // 💪 Power
  final int supportCount; // ❤️ Support
  final int warriorCount; // 🔥 Fire
  final int championCount; // 👑 Legend
  final Map<String, List<String>> reactions; // {reactionType: [userId, ...]}

  // Poll fields (postType == 'poll')
  final String? pollQuestion;
  final List<String> pollOptions;
  final Map<String, List<String>> pollVotes; // {optionIndex: [userId, ...]}
  final DateTime? pollExpiresAt;
  final bool pollAllowMultiple;

  // Link preview fields (Open Graph — client-side)
  final String? linkPreviewUrl;
  final String? linkPreviewTitle;
  final String? linkPreviewDescription;
  final String? linkPreviewImage;
  final String? linkPreviewDomain;

  // Server-side OG metadata (populated by fetchOgMetadata Cloud Function)
  final Map<String, dynamic>? ogPreview;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.likedBy = const [],
    this.bookmarkedBy = const [],
    this.mediaUrls = const [],
    this.mediaTypes = const [],
    this.mediaAssetIds = const [],
    this.thumbnailUrl,
    this.externalVideoUrl,
    this.userDisplayName,
    this.userRole,
    this.userAvatarUrl,
    this.postType = 'text',
    this.isVerified = false,
    this.editedAt,
    this.location,
    this.visibility = 'public',
    this.respectCount = 0,
    this.strongCount = 0,
    this.supportCount = 0,
    this.warriorCount = 0,
    this.championCount = 0,
    this.reactions = const {},
    this.pollQuestion,
    this.pollOptions = const [],
    this.pollVotes = const {},
    this.pollExpiresAt,
    this.pollAllowMultiple = false,
    this.linkPreviewUrl,
    this.linkPreviewTitle,
    this.linkPreviewDescription,
    this.linkPreviewImage,
    this.linkPreviewDomain,
    this.ogPreview,
  });

  /// Total reaction count across all 5 combat reactions
  int get totalReactions =>
      respectCount + strongCount + supportCount + warriorCount + championCount;

  /// Formatted display name — falls back to prettified userId
  String get displayName {
    if (userDisplayName != null && userDisplayName!.isNotEmpty) {
      return userDisplayName!;
    }
    return userId
        .split('_')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  /// Role badge label
  String get roleBadge {
    switch (userRole) {
      case 'fighter':
        return '🥊 Fighter';
      case 'coach':
        return '🎯 Coach';
      case 'promoter':
        return '📣 Promoter';
      case 'gym':
        return '🏋️ Gym';
      case 'media':
        return '📰 Media';
      case 'admin':
        return '⚡ Official';
      default:
        return '👤 Member';
    }
  }

  List<PostMediaAttachment> get mediaAttachments {
    final attachments = <PostMediaAttachment>[];
    for (var index = 0; index < mediaUrls.length; index++) {
      final url = mediaUrls[index];
      final type = index < mediaTypes.length && mediaTypes[index].isNotEmpty
          ? mediaTypes[index]
          : PostMediaAttachment.inferType(url);
      attachments.add(
        PostMediaAttachment(
          url: url,
          type: type,
          previewUrl: PostMediaAttachment.derivePreviewUrl(
            url,
            thumbnailUrl: type == 'image' ? null : thumbnailUrl,
          ),
        ),
      );
    }

    final videoUrl = externalVideoUrl?.trim();
    if (videoUrl != null && videoUrl.isNotEmpty) {
      final alreadyIncluded = attachments.any(
        (attachment) => attachment.url == videoUrl,
      );
      if (!alreadyIncluded) {
        attachments.add(
          PostMediaAttachment(
            url: videoUrl,
            type: PostMediaAttachment.inferType(videoUrl),
            previewUrl: PostMediaAttachment.derivePreviewUrl(
              videoUrl,
              thumbnailUrl: thumbnailUrl,
            ),
          ),
        );
      }
    }

    return attachments;
  }

  PostMediaAttachment? get primaryAttachment =>
      mediaAttachments.isEmpty ? null : mediaAttachments.first;

  String? get primaryMediaType => primaryAttachment?.type;

  /// Whether post has any media attachments
  bool get hasMedia => mediaAttachments.isNotEmpty;

  /// Whether post has a link preview (client-side fields)
  bool get hasLinkPreview =>
      linkPreviewUrl != null && linkPreviewUrl!.isNotEmpty;

  /// Whether post has server-populated OG metadata
  bool get hasOgPreview =>
      ogPreview != null &&
      ogPreview!.isNotEmpty &&
      (ogPreview!['og:title'] != null || ogPreview!['og:description'] != null);

  /// Whether the post was edited after creation
  bool get isEdited => editedAt != null;

  /// Time ago display
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7}w';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  Post copyWith({
    String? id,
    String? userId,
    String? content,
    DateTime? createdAt,
    int? likes,
    int? commentCount,
    int? shareCount,
    List<String>? likedBy,
    List<String>? bookmarkedBy,
    List<String>? mediaUrls,
    List<String>? mediaTypes,
    List<String>? mediaAssetIds,
    String? thumbnailUrl,
    String? externalVideoUrl,
    String? userDisplayName,
    String? userRole,
    String? userAvatarUrl,
    String? postType,
    bool? isVerified,
    DateTime? editedAt,
    String? location,
    String? visibility,
    int? respectCount,
    int? strongCount,
    int? supportCount,
    int? warriorCount,
    int? championCount,
    Map<String, List<String>>? reactions,
    String? pollQuestion,
    List<String>? pollOptions,
    Map<String, List<String>>? pollVotes,
    DateTime? pollExpiresAt,
    bool? pollAllowMultiple,
    String? linkPreviewUrl,
    String? linkPreviewTitle,
    String? linkPreviewDescription,
    String? linkPreviewImage,
    String? linkPreviewDomain,
    Map<String, dynamic>? ogPreview,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      likedBy: likedBy ?? this.likedBy,
      bookmarkedBy: bookmarkedBy ?? this.bookmarkedBy,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaTypes: mediaTypes ?? this.mediaTypes,
      mediaAssetIds: mediaAssetIds ?? this.mediaAssetIds,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      externalVideoUrl: externalVideoUrl ?? this.externalVideoUrl,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userRole: userRole ?? this.userRole,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      postType: postType ?? this.postType,
      isVerified: isVerified ?? this.isVerified,
      editedAt: editedAt ?? this.editedAt,
      location: location ?? this.location,
      visibility: visibility ?? this.visibility,
      respectCount: respectCount ?? this.respectCount,
      strongCount: strongCount ?? this.strongCount,
      supportCount: supportCount ?? this.supportCount,
      warriorCount: warriorCount ?? this.warriorCount,
      championCount: championCount ?? this.championCount,
      reactions: reactions ?? this.reactions,
      pollQuestion: pollQuestion ?? this.pollQuestion,
      pollOptions: pollOptions ?? this.pollOptions,
      pollVotes: pollVotes ?? this.pollVotes,
      pollExpiresAt: pollExpiresAt ?? this.pollExpiresAt,
      pollAllowMultiple: pollAllowMultiple ?? this.pollAllowMultiple,
      linkPreviewUrl: linkPreviewUrl ?? this.linkPreviewUrl,
      linkPreviewTitle: linkPreviewTitle ?? this.linkPreviewTitle,
      linkPreviewDescription:
          linkPreviewDescription ?? this.linkPreviewDescription,
      linkPreviewImage: linkPreviewImage ?? this.linkPreviewImage,
      linkPreviewDomain: linkPreviewDomain ?? this.linkPreviewDomain,
      ogPreview: ogPreview ?? this.ogPreview,
    );
  }
}

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? userDisplayName;
  final String? userRole;
  final String? userAvatarUrl;
  final int likes;
  final List<String> likedBy;
  final String? parentCommentId;
  final String? replyToName;
  final int replyCount;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userDisplayName,
    this.userRole,
    this.userAvatarUrl,
    this.likes = 0,
    this.likedBy = const [],
    this.parentCommentId,
    this.replyToName,
    this.replyCount = 0,
  });

  bool get isReply => parentCommentId != null;

  String get displayName {
    if (userDisplayName != null && userDisplayName!.isNotEmpty) {
      return userDisplayName!;
    }
    return userId
        .split('_')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7}w';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}

class Job {
  final String id;
  final String title;
  final String description;
  final String location;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
  });
}

class News {
  final String id;
  final String title;
  final String content;
  final String source;
  final DateTime publishedAt;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.source,
    required this.publishedAt,
  });
}
