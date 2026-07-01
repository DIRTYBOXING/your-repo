/// Per-platform media specs, character limits, and rate limits.
///
/// Source: Blotato documentation + official platform APIs (April 2026).
/// Used by [CrossPlatformPostingService] and the compose screen
/// to validate media BEFORE upload and warn on caption truncation.
library;

import '../services/cross_platform_posting_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  POST TYPE
// ─────────────────────────────────────────────────────────────────────────────

enum PostType { text, image, video, carousel, story, reel, short_ }

// ─────────────────────────────────────────────────────────────────────────────
//  PLATFORM SPEC — one per platform, immutable
// ─────────────────────────────────────────────────────────────────────────────

class PlatformSpec {
  final SocialPlatform platform;

  // ── Text ──
  final int maxCaptionLength;

  // ── Images ──
  final List<String> imageFormats; // lowercase extensions
  final int maxImageSizeMb;
  final int? maxImageWidthPx;
  final int? minImageWidthPx;
  final double? minAspectRatio; // width / height
  final double? maxAspectRatio;

  // ── Video ──
  final List<String> videoFormats;
  final int maxVideoSizeMb;
  final int? maxVideoDurationSec;
  final int? minVideoDurationSec;
  final int? maxVideoWidthPx;
  final int? minVideoWidthPx;
  final int? maxFps;

  // ── Carousel ──
  final int? minCarouselItems;
  final int? maxCarouselItems;

  // ── Rate limits (Blotato enforced) ──
  final int maxPostsPerDay;

  // ── Attachments ──
  final int maxImagesPerPost;
  final bool supportsGif;

  const PlatformSpec({
    required this.platform,
    required this.maxCaptionLength,
    this.imageFormats = const ['jpg', 'jpeg', 'png'],
    this.maxImageSizeMb = 5,
    this.maxImageWidthPx,
    this.minImageWidthPx,
    this.minAspectRatio,
    this.maxAspectRatio,
    this.videoFormats = const ['mp4'],
    this.maxVideoSizeMb = 500,
    this.maxVideoDurationSec,
    this.minVideoDurationSec,
    this.maxVideoWidthPx,
    this.minVideoWidthPx,
    this.maxFps,
    this.minCarouselItems,
    this.maxCarouselItems,
    this.maxPostsPerDay = 50,
    this.maxImagesPerPost = 1,
    this.supportsGif = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  TWITTER / X
// ─────────────────────────────────────────────────────────────────────────────

const twitterSpec = PlatformSpec(
  platform: SocialPlatform.xTwitter,
  maxCaptionLength: 280, // 25 000 for Premium, default to standard
  imageFormats: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
  maxImagesPerPost: 4,
  supportsGif: true,
  maxVideoSizeMb: 512,
  maxVideoDurationSec: 140,
  minVideoDurationSec: 1,
  maxVideoWidthPx: 1280,
  minVideoWidthPx: 32,
  maxFps: 60,
  maxPostsPerDay: 100, // Twitter API: 100 requests / 24 h
);

// ─────────────────────────────────────────────────────────────────────────────
//  INSTAGRAM
// ─────────────────────────────────────────────────────────────────────────────

const instagramSpec = PlatformSpec(
  platform: SocialPlatform.instagram,
  maxCaptionLength: 2200,
  maxImageSizeMb: 8,
  maxImageWidthPx: 1440,
  minImageWidthPx: 320,
  minAspectRatio: 4 / 5, // portrait
  maxAspectRatio: 1.91, // landscape
  videoFormats: ['mp4', 'mov'],
  maxVideoSizeMb: 100,
  maxVideoDurationSec: 900, // 15 min reels
  minVideoDurationSec: 3,
  maxVideoWidthPx: 1440,
  minVideoWidthPx: 320,
  minCarouselItems: 2,
  maxCarouselItems: 10,
  maxImagesPerPost: 10, // carousels
);

// ─────────────────────────────────────────────────────────────────────────────
//  FACEBOOK
// ─────────────────────────────────────────────────────────────────────────────

const facebookSpec = PlatformSpec(
  platform: SocialPlatform.facebook,
  maxCaptionLength: 63206, // Graph API limit
  imageFormats: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff'],
  maxImageSizeMb: 30,
  supportsGif: true,
  videoFormats: ['mp4', 'mov'],
  maxVideoSizeMb: 4096, // 4 GB
  maxVideoDurationSec: 14400, // 240 min
  minVideoDurationSec: 3,
  maxVideoWidthPx: 4096,
  minVideoWidthPx: 256,
  maxFps: 30,
  maxPostsPerDay: 35, // upper API limit; FB recommends ≤ 5
  maxImagesPerPost: 10,
);

// ─────────────────────────────────────────────────────────────────────────────
//  TIKTOK
// ─────────────────────────────────────────────────────────────────────────────

const tiktokSpec = PlatformSpec(
  platform: SocialPlatform.tiktok,
  maxCaptionLength: 2200,
  imageFormats: ['jpg', 'jpeg', 'webp'], // NO PNG — must convert
  maxImageSizeMb: 20,
  maxImageWidthPx: 1080,
  videoFormats: ['mp4', 'webm', 'mov'],
  maxVideoSizeMb: 4096,
  maxVideoDurationSec: 600, // 10 min
  minVideoDurationSec: 1,
  maxVideoWidthPx: 4096,
  minVideoWidthPx: 360,
  maxFps: 60,
  maxPostsPerDay: 10, // Blotato Starter: 10 per account / 24 h
);

// ─────────────────────────────────────────────────────────────────────────────
//  YOUTUBE
// ─────────────────────────────────────────────────────────────────────────────

const youtubeSpec = PlatformSpec(
  platform: SocialPlatform.youtube,
  maxCaptionLength: 5000, // description
  imageFormats: ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
  maxImageSizeMb: 6, // channel art / thumbnail
  maxImageWidthPx: 2560,
  videoFormats: ['mp4', 'mov', 'avi', 'wmv', 'flv', 'webm'],
  maxVideoSizeMb: 262144, // 256 GB verified accounts
  maxVideoDurationSec: 43200, // 12 h verified
  minVideoDurationSec: 1,
  maxVideoWidthPx: 3840,
  minVideoWidthPx: 426,
  maxFps: 60,
  maxPostsPerDay: 10, // Blotato Starter API limit
);

// ─────────────────────────────────────────────────────────────────────────────
//  LINKEDIN
// ─────────────────────────────────────────────────────────────────────────────

const linkedinSpec = PlatformSpec(
  platform: SocialPlatform.linkedin,
  maxCaptionLength: 3000,
  imageFormats: ['jpg', 'jpeg', 'gif', 'png'],
  supportsGif: true,
  maxVideoDurationSec: 1800, // 30 min
  minVideoDurationSec: 3,
  maxVideoWidthPx: 4096,
  minVideoWidthPx: 256,
  maxFps: 60,
);

// ─────────────────────────────────────────────────────────────────────────────
//  THREADS
// ─────────────────────────────────────────────────────────────────────────────

const threadsSpec = PlatformSpec(
  platform: SocialPlatform.threads,
  maxCaptionLength: 500,
  maxImageSizeMb: 8,
  maxImageWidthPx: 1440,
  minImageWidthPx: 320,
  minAspectRatio: 0.1, // 1:10
  maxAspectRatio: 10, // 10:1
  videoFormats: ['mp4', 'mov'],
  maxVideoSizeMb: 1024, // 1 GB
  maxVideoDurationSec: 300, // 5 min
  minVideoDurationSec: 1,
  maxVideoWidthPx: 1920,
  maxFps: 60,
  minCarouselItems: 2,
  maxCarouselItems: 20,
  maxImagesPerPost: 20,
);

// ─────────────────────────────────────────────────────────────────────────────
//  BLUESKY
// ─────────────────────────────────────────────────────────────────────────────

const blueskySpec = PlatformSpec(
  platform: SocialPlatform.bluesky,
  maxCaptionLength: 300,
  maxImageWidthPx: 1200,
  maxImagesPerPost: 4,
);

// ─────────────────────────────────────────────────────────────────────────────
//  PINTEREST
// ─────────────────────────────────────────────────────────────────────────────

const pinterestSpec = PlatformSpec(
  platform: SocialPlatform.pinterest,
  maxCaptionLength: 800, // description
  maxImageSizeMb: 20,
  videoFormats: ['mp4', 'mov'],
  maxVideoSizeMb: 2048, // 2 GB
  maxVideoDurationSec: 300, // 5 min
  minVideoDurationSec: 4,
  minCarouselItems: 2,
  maxCarouselItems: 5,
  maxPostsPerDay: 10, // Blotato enforced
);

// ─────────────────────────────────────────────────────────────────────────────
//  LOOKUP MAP
// ─────────────────────────────────────────────────────────────────────────────

const Map<SocialPlatform, PlatformSpec> platformSpecs = {
  SocialPlatform.xTwitter: twitterSpec,
  SocialPlatform.instagram: instagramSpec,
  SocialPlatform.facebook: facebookSpec,
  SocialPlatform.tiktok: tiktokSpec,
  SocialPlatform.youtube: youtubeSpec,
  SocialPlatform.linkedin: linkedinSpec,
  SocialPlatform.threads: threadsSpec,
  SocialPlatform.bluesky: blueskySpec,
  SocialPlatform.pinterest: pinterestSpec,
};

// ─────────────────────────────────────────────────────────────────────────────
//  VALIDATION
// ─────────────────────────────────────────────────────────────────────────────

class MediaValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const MediaValidationResult({
    this.isValid = true,
    this.errors = const [],
    this.warnings = const [],
  });
}

class PlatformValidator {
  const PlatformValidator._();

  /// Validate caption length against all selected platforms.
  /// Returns the TIGHTEST limit that will be exceeded.
  static Map<SocialPlatform, int> captionOverflows(
    String caption,
    List<SocialPlatform> platforms,
  ) {
    final overflows = <SocialPlatform, int>{};
    for (final p in platforms) {
      final spec = platformSpecs[p];
      if (spec != null && caption.length > spec.maxCaptionLength) {
        overflows[p] = caption.length - spec.maxCaptionLength;
      }
    }
    return overflows;
  }

  /// Shortest caption limit among selected platforms.
  static int tightestCaptionLimit(List<SocialPlatform> platforms) {
    if (platforms.isEmpty) return 280;
    return platforms
        .map((p) => platformSpecs[p]?.maxCaptionLength ?? 280)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Validate an image file against a platform's spec.
  static MediaValidationResult validateImage({
    required SocialPlatform platform,
    required String extension,
    required int fileSizeBytes,
    int? widthPx,
    int? heightPx,
  }) {
    final spec = platformSpecs[platform];
    if (spec == null) return const MediaValidationResult();

    final errors = <String>[];
    final warnings = <String>[];
    final ext = extension.toLowerCase().replaceAll('.', '');

    // Format check
    if (!spec.imageFormats.contains(ext)) {
      if (platform == SocialPlatform.tiktok && ext == 'png') {
        warnings.add('TikTok does not accept PNG — will auto-convert to JPEG');
      } else {
        errors.add(
          '${platform.label} does not support .$ext images. '
          'Use: ${spec.imageFormats.join(", ")}',
        );
      }
    }

    // Size check
    final sizeMb = fileSizeBytes / (1024 * 1024);
    if (sizeMb > spec.maxImageSizeMb) {
      errors.add(
        'Image is ${sizeMb.toStringAsFixed(1)} MB — '
        '${platform.label} limit is ${spec.maxImageSizeMb} MB',
      );
    }

    // Dimensions
    if (widthPx != null) {
      if (spec.maxImageWidthPx != null && widthPx > spec.maxImageWidthPx!) {
        warnings.add(
          'Image will be downscaled from ${widthPx}px '
          'to ${spec.maxImageWidthPx}px on ${platform.label}',
        );
      }
      if (spec.minImageWidthPx != null && widthPx < spec.minImageWidthPx!) {
        warnings.add(
          'Image will be upscaled from ${widthPx}px '
          'to ${spec.minImageWidthPx}px on ${platform.label}',
        );
      }
    }

    // Aspect ratio
    if (widthPx != null && heightPx != null && heightPx > 0) {
      final ar = widthPx / heightPx;
      if (spec.minAspectRatio != null && ar < spec.minAspectRatio!) {
        errors.add(
          'Aspect ratio ${ar.toStringAsFixed(2)} is too narrow for '
          '${platform.label} (min ${spec.minAspectRatio!.toStringAsFixed(2)})',
        );
      }
      if (spec.maxAspectRatio != null && ar > spec.maxAspectRatio!) {
        errors.add(
          'Aspect ratio ${ar.toStringAsFixed(2)} is too wide for '
          '${platform.label} (max ${spec.maxAspectRatio!.toStringAsFixed(2)})',
        );
      }
    }

    return MediaValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate a video file against a platform's spec.
  static MediaValidationResult validateVideo({
    required SocialPlatform platform,
    required String extension,
    required int fileSizeBytes,
    int? durationSec,
    int? widthPx,
    int? fps,
  }) {
    final spec = platformSpecs[platform];
    if (spec == null) return const MediaValidationResult();

    final errors = <String>[];
    final warnings = <String>[];
    final ext = extension.toLowerCase().replaceAll('.', '');

    // Format
    if (!spec.videoFormats.contains(ext)) {
      errors.add(
        '${platform.label} does not support .$ext video. '
        'Use: ${spec.videoFormats.join(", ")}',
      );
    }

    // Size
    final sizeMb = fileSizeBytes / (1024 * 1024);
    if (sizeMb > spec.maxVideoSizeMb) {
      errors.add(
        'Video is ${sizeMb.toStringAsFixed(0)} MB — '
        '${platform.label} limit is ${spec.maxVideoSizeMb} MB',
      );
    }

    // Duration
    if (durationSec != null) {
      if (spec.maxVideoDurationSec != null &&
          durationSec > spec.maxVideoDurationSec!) {
        errors.add(
          'Video is ${durationSec}s — '
          '${platform.label} max is ${spec.maxVideoDurationSec}s',
        );
      }
      if (spec.minVideoDurationSec != null &&
          durationSec < spec.minVideoDurationSec!) {
        errors.add(
          'Video is ${durationSec}s — '
          '${platform.label} min is ${spec.minVideoDurationSec}s',
        );
      }
    }

    // Resolution
    if (widthPx != null) {
      if (spec.maxVideoWidthPx != null && widthPx > spec.maxVideoWidthPx!) {
        warnings.add(
          'Video will be downscaled from ${widthPx}px '
          'to ${spec.maxVideoWidthPx}px on ${platform.label}',
        );
      }
      if (spec.minVideoWidthPx != null && widthPx < spec.minVideoWidthPx!) {
        errors.add(
          'Video is ${widthPx}px wide — '
          '${platform.label} min is ${spec.minVideoWidthPx}px',
        );
      }
    }

    // FPS
    if (fps != null && spec.maxFps != null && fps > spec.maxFps!) {
      warnings.add(
        'Video is ${fps}fps — '
        '${platform.label} max is ${spec.maxFps}fps, will be re-encoded',
      );
    }

    return MediaValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Check if a carousel is allowed and within item limits.
  static MediaValidationResult validateCarousel({
    required SocialPlatform platform,
    required int itemCount,
  }) {
    final spec = platformSpecs[platform];
    if (spec == null) return const MediaValidationResult();

    final errors = <String>[];

    if (spec.minCarouselItems == null) {
      errors.add('${platform.label} does not support carousels');
    } else {
      if (itemCount < spec.minCarouselItems!) {
        errors.add(
          'Carousel needs at least ${spec.minCarouselItems} items '
          'on ${platform.label}',
        );
      }
      if (spec.maxCarouselItems != null &&
          itemCount > spec.maxCarouselItems!) {
        errors.add(
          'Max ${spec.maxCarouselItems} carousel items '
          'on ${platform.label} (you have $itemCount)',
        );
      }
    }

    return MediaValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate media against ALL selected platforms.
  /// Returns combined errors/warnings keyed by platform.
  static Map<SocialPlatform, MediaValidationResult> validateForPlatforms({
    required List<SocialPlatform> platforms,
    required PostType postType,
    String? fileExtension,
    int? fileSizeBytes,
    int? widthPx,
    int? heightPx,
    int? durationSec,
    int? fps,
    int? carouselCount,
  }) {
    final results = <SocialPlatform, MediaValidationResult>{};

    for (final p in platforms) {
      switch (postType) {
        case PostType.image:
          if (fileExtension != null && fileSizeBytes != null) {
            results[p] = validateImage(
              platform: p,
              extension: fileExtension,
              fileSizeBytes: fileSizeBytes,
              widthPx: widthPx,
              heightPx: heightPx,
            );
          }
        case PostType.video:
        case PostType.reel:
        case PostType.short_:
        case PostType.story:
          if (fileExtension != null && fileSizeBytes != null) {
            results[p] = validateVideo(
              platform: p,
              extension: fileExtension,
              fileSizeBytes: fileSizeBytes,
              durationSec: durationSec,
              widthPx: widthPx,
              fps: fps,
            );
          }
        case PostType.carousel:
          if (carouselCount != null) {
            results[p] = validateCarousel(
              platform: p,
              itemCount: carouselCount,
            );
          }
        case PostType.text:
          break; // Text-only — caption validation is separate
      }
    }
    return results;
  }

  /// Platforms that support a given post type.
  static List<SocialPlatform> platformsSupporting(PostType type) {
    switch (type) {
      case PostType.text:
        return SocialPlatform.values.toList();
      case PostType.image:
        return SocialPlatform.values.toList();
      case PostType.video:
        return SocialPlatform.values.toList();
      case PostType.carousel:
        return SocialPlatform.values
            .where((p) => platformSpecs[p]?.minCarouselItems != null)
            .toList();
      case PostType.reel:
        return [SocialPlatform.instagram, SocialPlatform.facebook];
      case PostType.story:
        return [SocialPlatform.instagram, SocialPlatform.facebook];
      case PostType.short_:
        return [SocialPlatform.youtube];
    }
  }
}
