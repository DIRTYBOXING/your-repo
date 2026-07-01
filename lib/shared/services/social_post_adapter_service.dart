import '../models/community/community_models.dart';

class NormalizedPostMedia {
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final String? externalVideoUrl;
  final String? thumbnailUrl;

  const NormalizedPostMedia({
    this.mediaUrls = const [],
    this.mediaTypes = const [],
    this.externalVideoUrl,
    this.thumbnailUrl,
  });

  List<PostMediaAttachment> get attachments {
    final resolvedAttachments = <PostMediaAttachment>[];

    for (var index = 0; index < mediaUrls.length; index++) {
      final url = mediaUrls[index];
      final type = index < mediaTypes.length && mediaTypes[index].isNotEmpty
          ? mediaTypes[index]
          : PostMediaAttachment.inferType(url);
      resolvedAttachments.add(
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
    if (videoUrl != null &&
        videoUrl.isNotEmpty &&
        !resolvedAttachments.any((attachment) => attachment.url == videoUrl)) {
      resolvedAttachments.add(
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

    return resolvedAttachments;
  }

  List<PostMediaAttachment> get imageAttachments =>
      attachments.where((attachment) => attachment.isImage).toList();

  List<PostMediaAttachment> get videoAttachments =>
      attachments.where((attachment) => attachment.isVideo).toList();

  bool get hasMedia => attachments.isNotEmpty;

  String? get primaryImageUrl =>
      imageAttachments.isEmpty ? null : imageAttachments.first.url;

  String? get primaryVideoUrl =>
      videoAttachments.isEmpty ? null : videoAttachments.first.url;

  String? get primaryMediaUrl => primaryVideoUrl ?? primaryImageUrl;

  Map<String, dynamic> toFirestorePatch({bool includeNullValues = false}) {
    final patch = <String, dynamic>{
      'mediaUrls': mediaUrls,
      'mediaTypes': mediaTypes,
    };

    final safeThumbnail = thumbnailUrl?.trim();
    if (includeNullValues ||
        (safeThumbnail != null && safeThumbnail.isNotEmpty)) {
      patch['thumbnailUrl'] = safeThumbnail;
    }

    final safeVideoUrl = externalVideoUrl?.trim();
    if (includeNullValues ||
        (safeVideoUrl != null && safeVideoUrl.isNotEmpty)) {
      patch['externalVideoUrl'] = safeVideoUrl;
      patch['videoUrl'] = safeVideoUrl;
    }

    return patch;
  }
}

class OutboundPlatformPayload {
  final String platform;
  final String caption;
  final List<String> hashtags;
  final String postType;
  final String? mediaUrl;
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final String? thumbnailUrl;
  final Map<String, dynamic> metadata;

  const OutboundPlatformPayload({
    required this.platform,
    required this.caption,
    this.hashtags = const [],
    required this.postType,
    this.mediaUrl,
    this.mediaUrls = const [],
    this.mediaTypes = const [],
    this.thumbnailUrl,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'caption': caption,
      'hashtags': hashtags,
      'postType': postType,
      if (mediaUrl != null && mediaUrl!.isNotEmpty) 'mediaUrl': mediaUrl,
      if (mediaUrls.isNotEmpty) 'mediaUrls': mediaUrls,
      if (mediaTypes.isNotEmpty) 'mediaTypes': mediaTypes,
      if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
        'thumbnailUrl': thumbnailUrl,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}

class OutboundPostDraft {
  final String caption;
  final List<String> hashtags;
  final NormalizedPostMedia media;
  final Map<String, OutboundPlatformPayload> platformPayloads;

  const OutboundPostDraft({
    required this.caption,
    this.hashtags = const [],
    required this.media,
    this.platformPayloads = const {},
  });

  OutboundPlatformPayload? payloadFor(String platform) {
    return platformPayloads[SocialPostMediaAdapter.canonicalizePlatform(
      platform,
    )];
  }

  Map<String, dynamic> toCallablePayload({
    required List<String> targetPlatforms,
    DateTime? scheduledAt,
  }) {
    final canonicalPlatforms = SocialPostMediaAdapter._canonicalizePlatforms(
      targetPlatforms,
    );
    final resolvedPayloads = <String, Map<String, dynamic>>{};

    for (final platform in canonicalPlatforms) {
      final payload = payloadFor(platform);
      if (payload != null) {
        resolvedPayloads[platform] = payload.toMap();
      }
    }

    final commonPayload = _selectCommonPayload(canonicalPlatforms);
    final callablePayload = <String, dynamic>{
      'caption': commonPayload.caption,
      'hashtags': commonPayload.hashtags,
      'platforms': canonicalPlatforms,
      'postType': commonPayload.postType,
      'platformPayloads': resolvedPayloads,
      if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
    };

    if (commonPayload.mediaUrl != null && commonPayload.mediaUrl!.isNotEmpty) {
      callablePayload['mediaUrl'] = commonPayload.mediaUrl;
      if (SocialPostMediaAdapter._isVideoPostType(commonPayload.postType)) {
        callablePayload['videoUrl'] = commonPayload.mediaUrl;
      }
    }

    if (commonPayload.mediaUrls.isNotEmpty) {
      callablePayload['mediaUrls'] = commonPayload.mediaUrls;
    }

    return callablePayload;
  }

  OutboundPlatformPayload _selectCommonPayload(
    List<String> canonicalPlatforms,
  ) {
    for (final platform in canonicalPlatforms) {
      final payload = payloadFor(platform);
      if (payload != null) {
        return payload;
      }
    }

    if (platformPayloads.isNotEmpty) {
      return platformPayloads.values.first;
    }

    return const OutboundPlatformPayload(
      platform: 'facebook',
      caption: '',
      postType: 'text',
    );
  }
}

class SocialPostMediaAdapter {
  static NormalizedPostMedia normalizeFields({
    List<String> mediaUrls = const [],
    List<String> mediaTypes = const [],
    String? externalVideoUrl,
    String? thumbnailUrl,
  }) {
    final resolvedMediaUrls = mediaUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    final resolvedExternalVideoUrl = _trimOrNull(externalVideoUrl);
    final resolvedMediaTypes = resolvedMediaUrls.isEmpty
        ? const <String>[]
        : List<String>.generate(resolvedMediaUrls.length, (index) {
            final candidate = index < mediaTypes.length
                ? mediaTypes[index].trim()
                : '';
            return candidate.isNotEmpty
                ? candidate
                : PostMediaAttachment.inferType(resolvedMediaUrls[index]);
          }, growable: false);

    return NormalizedPostMedia(
      mediaUrls: resolvedMediaUrls,
      mediaTypes: resolvedMediaTypes,
      externalVideoUrl: resolvedExternalVideoUrl,
      thumbnailUrl: _resolveThumbnailUrl(
        mediaUrls: resolvedMediaUrls,
        mediaTypes: resolvedMediaTypes,
        externalVideoUrl: resolvedExternalVideoUrl,
        thumbnailUrl: thumbnailUrl,
      ),
    );
  }

  static NormalizedPostMedia normalizeFromMap(Map<String, dynamic> data) {
    final legacyImageUrl = _trimOrNull(data['imageUrl'] as String?);
    final rawMediaUrls =
        List<String>.from(data['mediaUrls'] ?? const <String>[])
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList(growable: false);
    final resolvedMediaUrls = rawMediaUrls.isNotEmpty
        ? rawMediaUrls
        : legacyImageUrl == null
        ? const <String>[]
        : <String>[legacyImageUrl];

    return normalizeFields(
      mediaUrls: resolvedMediaUrls,
      mediaTypes: List<String>.from(data['mediaTypes'] ?? const <String>[]),
      externalVideoUrl:
          data['externalVideoUrl'] as String? ?? data['videoUrl'] as String?,
      thumbnailUrl:
          data['thumbnailUrl'] as String? ??
          data['linkPreviewImage'] as String? ??
          legacyImageUrl,
    );
  }

  static NormalizedPostMedia normalizeFromPost(Post post) {
    return normalizeFields(
      mediaUrls: post.mediaUrls,
      mediaTypes: post.mediaTypes,
      externalVideoUrl: post.externalVideoUrl,
      thumbnailUrl: post.thumbnailUrl,
    );
  }

  static OutboundPostDraft buildOutboundDraft({
    required String caption,
    List<String> hashtags = const [],
    required NormalizedPostMedia media,
    List<String> targetPlatforms = const [],
    Map<String, String> platformCaptions = const {},
  }) {
    final canonicalPlatforms = _canonicalizePlatforms(targetPlatforms);
    final resolvedPlatforms = canonicalPlatforms.isEmpty
        ? const <String>['facebook', 'instagram', 'tiktok']
        : canonicalPlatforms;
    final resolvedHashtags = hashtags
        .map((tag) => tag.trim().replaceFirst(RegExp(r'^#'), ''))
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
    final captionOverrides = <String, String>{};

    for (final entry in platformCaptions.entries) {
      final normalizedCaption = entry.value.trim();
      if (normalizedCaption.isEmpty) {
        continue;
      }
      captionOverrides[canonicalizePlatform(entry.key)] = normalizedCaption;
    }

    final payloads = <String, OutboundPlatformPayload>{};
    for (final platform in resolvedPlatforms) {
      final postType = _resolvePlatformPostType(platform, media);
      final platformMediaUrls = _resolvePlatformMediaUrls(
        platform,
        media,
        postType,
      );
      final platformMediaUrl = _resolvePlatformMediaUrl(
        media,
        postType,
        platformMediaUrls,
      );

      payloads[platform] = OutboundPlatformPayload(
        platform: platform,
        caption: captionOverrides[platform] ?? caption.trim(),
        hashtags: resolvedHashtags,
        postType: postType,
        mediaUrl: platformMediaUrl,
        mediaUrls: platformMediaUrls,
        mediaTypes: platformMediaUrls
            .map(PostMediaAttachment.inferType)
            .toList(growable: false),
        thumbnailUrl: media.thumbnailUrl,
        metadata: {
          'source': 'dfc_normalized_post_media',
          'canonicalPlatform': platform,
          if (media.externalVideoUrl != null &&
              media.externalVideoUrl!.isNotEmpty)
            'externalVideoUrl': media.externalVideoUrl,
        },
      );
    }

    return OutboundPostDraft(
      caption: caption.trim(),
      hashtags: resolvedHashtags,
      media: media,
      platformPayloads: payloads,
    );
  }

  static String canonicalizePlatform(String platform) {
    switch (platform.trim().toLowerCase()) {
      case 'meta':
      case 'facebook':
        return 'facebook';
      case 'instagram':
        return 'instagram';
      case 'tiktok':
        return 'tiktok';
      case 'youtube':
      case 'shorts':
      case 'youtube_shorts':
        return 'youtube';
      case 'x':
      case 'xtwitter':
      case 'x/twitter':
      case 'twitter':
        return 'twitter';
      case 'linkedin':
        return 'linkedin';
      case 'threads':
        return 'threads';
      case 'bluesky':
        return 'bluesky';
      case 'pinterest':
        return 'pinterest';
      case 'snapchat':
        return 'snapchat';
      case 'whatsapp':
        return 'whatsapp';
      default:
        return platform.trim().toLowerCase();
    }
  }

  static List<String> _canonicalizePlatforms(List<String> platforms) {
    final resolved = <String>[];
    for (final platform in platforms) {
      final canonical = canonicalizePlatform(platform);
      if (canonical.isEmpty || resolved.contains(canonical)) {
        continue;
      }
      resolved.add(canonical);
    }
    return resolved;
  }

  static String _resolvePlatformPostType(
    String platform,
    NormalizedPostMedia media,
  ) {
    final canonicalPlatform = canonicalizePlatform(platform);
    final imageCount = media.imageAttachments.length;
    final hasVideo = media.videoAttachments.isNotEmpty;

    switch (canonicalPlatform) {
      case 'instagram':
        if (hasVideo) return 'reel';
        if (imageCount > 1) return 'carousel';
        if (imageCount == 1) return 'image';
        return 'text';
      case 'tiktok':
        if (hasVideo) return 'video';
        if (imageCount > 1) return 'carousel';
        if (imageCount == 1) return 'image';
        return 'text';
      case 'youtube':
        if (hasVideo) return 'short';
        if (imageCount > 0) return 'image';
        return 'text';
      case 'facebook':
      case 'threads':
      case 'linkedin':
      case 'twitter':
      case 'bluesky':
      case 'pinterest':
      case 'snapchat':
      case 'whatsapp':
      default:
        if (hasVideo) return 'video';
        if (imageCount > 1) return 'carousel';
        if (imageCount == 1) return 'image';
        return 'text';
    }
  }

  static List<String> _resolvePlatformMediaUrls(
    String platform,
    NormalizedPostMedia media,
    String postType,
  ) {
    if (postType != 'carousel') {
      return const <String>[];
    }

    final imageUrls = media.imageAttachments
        .map((attachment) => attachment.url)
        .toList(growable: false);
    final maxItems = switch (canonicalizePlatform(platform)) {
      'twitter' => 4,
      'pinterest' => 5,
      'threads' => 10,
      'instagram' => 10,
      'facebook' => 10,
      _ => imageUrls.length,
    };
    return imageUrls.take(maxItems).toList(growable: false);
  }

  static String? _resolvePlatformMediaUrl(
    NormalizedPostMedia media,
    String postType,
    List<String> platformMediaUrls,
  ) {
    if (_isVideoPostType(postType)) {
      return media.primaryVideoUrl ?? media.primaryMediaUrl;
    }
    if (postType == 'image') {
      return media.primaryImageUrl ?? media.primaryMediaUrl;
    }
    if (postType == 'carousel') {
      return platformMediaUrls.isEmpty ? null : platformMediaUrls.first;
    }
    return null;
  }

  static String? _resolveThumbnailUrl({
    required List<String> mediaUrls,
    required List<String> mediaTypes,
    required String? externalVideoUrl,
    String? thumbnailUrl,
  }) {
    final safeThumbnail = _trimOrNull(thumbnailUrl);
    if (safeThumbnail != null) {
      return safeThumbnail;
    }

    for (var index = 0; index < mediaUrls.length; index++) {
      final url = mediaUrls[index];
      final type = index < mediaTypes.length && mediaTypes[index].isNotEmpty
          ? mediaTypes[index]
          : PostMediaAttachment.inferType(url);
      final preview = PostMediaAttachment.derivePreviewUrl(
        url,
        thumbnailUrl: type == 'image' ? null : safeThumbnail,
      );
      if (preview != null && preview.isNotEmpty) {
        return preview;
      }
    }

    if (externalVideoUrl != null && externalVideoUrl.isNotEmpty) {
      final preview = PostMediaAttachment.derivePreviewUrl(externalVideoUrl);
      if (preview != null && preview.isNotEmpty) {
        return preview;
      }
    }

    return null;
  }

  static bool _isVideoPostType(String postType) {
    return postType == 'video' ||
        postType == 'reel' ||
        postType == 'short' ||
        postType == 'story';
  }

  static String? _trimOrNull(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
