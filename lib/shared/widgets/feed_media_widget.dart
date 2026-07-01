import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/cdn_media_pipeline_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FEED MEDIA WIDGET — Variant-aware photo / video thumbnail renderer
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Selects the appropriate variant URL from [CDNMedia.variants] based on the
/// device's logical screen width (via MediaQuery):
///
///   ≤ 480 px  → thumbnail  (image) / sd480  (video)
///   ≤ 768 px  → small      (image) / sd480  (video)
///   > 768 px  → medium     (image) / hd720  (video)
///
/// Falls back to the next available tier, then to [CDNMedia.originalUrl] if no
/// variant matches.  For videos the widget shows a still thumbnail with a play
/// overlay; actual playback is handled by the caller via [onTap].
///
/// Usage:
/// ```dart
/// FeedMediaWidget(media: cdnMedia)
/// FeedMediaWidget(media: cdnMedia, displayMode: FeedMediaMode.card)
/// ```
/// ═══════════════════════════════════════════════════════════════════════════

enum FeedMediaMode {
  /// Small square used in list rows (e.g. comment / search result).
  thumb,

  /// Full-width card as rendered in the main social feed.
  card,

  /// Full-screen (profile hero / PPV poster).
  hero,
}

class FeedMediaWidget extends StatelessWidget {
  final CDNMedia media;
  final FeedMediaMode displayMode;
  final VoidCallback? onTap;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const FeedMediaWidget({
    super.key,
    required this.media,
    this.displayMode = FeedMediaMode.card,
    this.onTap,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  // ── Variant selection ─────────────────────────────────────────────────────

  /// Returns the best image variant URL for the given [screenWidth].
  String _imageVariant(double screenWidth) {
    // Priority lists from narrowest to widest — first match wins.
    final List<String> priority;
    if (screenWidth <= 480) {
      priority = ['thumbnail', 'small', 'medium', 'large', 'original'];
    } else if (screenWidth <= 768) {
      priority = ['small', 'medium', 'thumbnail', 'large', 'original'];
    } else {
      priority = ['medium', 'large', 'small', 'original', 'thumbnail'];
    }

    for (final key in priority) {
      final url = media.variants[key];
      if (url != null && url.isNotEmpty) return url;
    }
    return media.originalUrl;
  }

  /// Returns the best video quality key for the given [screenWidth].
  String _videoVariant(double screenWidth) {
    final List<String> priority;
    if (screenWidth <= 480) {
      priority = ['sd480', 'hd720', 'hd1080', 'preview'];
    } else if (screenWidth <= 768) {
      priority = ['hd720', 'sd480', 'hd1080', 'preview'];
    } else {
      priority = ['hd1080', 'hd720', 'sd480', 'preview'];
    }

    for (final key in priority) {
      final url = media.variants[key];
      if (url != null && url.isNotEmpty) return url;
    }
    return media.thumbnailUrl ?? media.originalUrl;
  }

  // ── Dimension helpers ─────────────────────────────────────────────────────

  double? get _fixedHeight {
    switch (displayMode) {
      case FeedMediaMode.thumb:
        return 72;
      case FeedMediaMode.card:
        return null; // intrinsic / aspect-ratio driven
      case FeedMediaMode.hero:
        return null;
    }
  }

  double? get _fixedWidth {
    switch (displayMode) {
      case FeedMediaMode.thumb:
        return 72;
      case FeedMediaMode.card:
        return double.infinity;
      case FeedMediaMode.hero:
        return double.infinity;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVideo = media.type == MediaType.video;

    final imageUrl = isVideo
        ? (media.thumbnailUrl ?? media.originalUrl)
        : _imageVariant(screenWidth);

    Widget content = _buildImage(imageUrl);

    if (isVideo) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          content,
          Positioned.fill(
            child: _VideoOverlay(videoUrl: _videoVariant(screenWidth)),
          ),
        ],
      );
    }

    if (borderRadius != null) {
      content = ClipRRect(borderRadius: borderRadius!, child: content);
    }

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    if (_fixedHeight != null || _fixedWidth != null) {
      content = SizedBox(
        width: _fixedWidth,
        height: _fixedHeight,
        child: content,
      );
    }

    return content;
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) {
      return _placeholder();
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: _fixedWidth,
      height: _fixedHeight,
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) => _errorWidget(),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF1A1A2E),
    child: const Center(
      child: CircularProgressIndicator(
        strokeWidth: 1.5,
        color: Color(0xFF00FFFF),
      ),
    ),
  );

  Widget _errorWidget() => Container(
    color: const Color(0xFF1A1A2E),
    child: const Center(
      child: Icon(Icons.broken_image_outlined, color: Color(0xFF555577)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Video play overlay (static thumbnail + play button + duration chip).
// Caller is responsible for launching the player on tap.
// ─────────────────────────────────────────────────────────────────────────────

class _VideoOverlay extends StatelessWidget {
  final String videoUrl;

  const _VideoOverlay({required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
        ),
      ),
      child: const Center(child: _PlayButton()),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF00FFFF), width: 1.5),
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Color(0xFF00FFFF),
        size: 32,
      ),
    );
  }
}
