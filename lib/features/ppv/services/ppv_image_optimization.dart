import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// IMAGE OPTIMIZATION SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
/// Provides optimized image loading with caching, compression, and fallbacks

class PPVImageOptimization {
  // Custom cache manager for PPV images (14-day retention)
  static final _cacheManager = CacheManager(
    Config(
      'ppv_image_cache',
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 100,
    ),
  );

  /// Get optimized image URL with proper query parameters
  static String optimizeUrl(String url, {int? width, int? height}) {
    if (!url.contains('unsplash') && !url.contains('cloudinary')) {
      return url; // Non-CDN URLs returned as-is
    }

    // Unsplash URL optimization
    if (url.contains('unsplash.com')) {
      final separator = url.contains('?') ? '&' : '?';
      final w = width ?? 800;
      final q = 'q=80'; // 80% quality for balance
      return '$url${separator}w=$w&$q';
    }

    return url;
  }

  /// Preload image for better perceived performance
  static Future<void> preloadImage(
    BuildContext context,
    String imageUrl,
  ) async {
    try {
      await precacheImage(CachedNetworkImageProvider(imageUrl), context);
    } catch (e) {
      // Silent fail - image will load normally
    }
  }

  /// Clear old cached images (call periodically)
  static Future<void> clearOldCache() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      // Silent fail
    }
  }

  /// Build an optimized cached image widget
  static Widget buildOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    VoidCallback? onTap,
    Duration fadeInDuration = const Duration(milliseconds: 300),
  }) {
    final optimizedUrl = optimizeUrl(imageUrl, width: width?.toInt());

    return CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      placeholder: (context, url) => Container(
        color: Colors.grey[900],
        child: const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[900],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      ),
      memCacheHeight: height?.toInt(),
      memCacheWidth: width?.toInt(),
    );
  }
}

/// Image compression helper for upload operations
class PPVImageCompression {
  /// Recommended image sizes to reduce bandwidth
  static const Map<String, int> imageSizes = {
    'thumbnail': 200,
    'small': 400,
    'medium': 800,
    'large': 1200,
    'hero': 1600,
  };

  /// Get recommended image URL variant based on screen width
  static String getResponsiveUrl(String baseUrl, double screenWidth) {
    if (screenWidth < 400) {
      return _appendSize(baseUrl, 'small');
    } else if (screenWidth < 800) {
      return _appendSize(baseUrl, 'medium');
    } else if (screenWidth < 1200) {
      return _appendSize(baseUrl, 'large');
    } else {
      return _appendSize(baseUrl, 'hero');
    }
  }

  static String _appendSize(String url, String sizeKey) {
    final size = imageSizes[sizeKey] ?? 800;
    return PPVImageOptimization.optimizeUrl(url, width: size);
  }
}
