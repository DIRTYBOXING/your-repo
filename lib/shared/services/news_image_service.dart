// ═══════════════════════════════════════════════════════════════════════════
// NEWS IMAGE SERVICE — Dynamic OG Image Fetching & Thumbnail Pipeline
// ═══════════════════════════════════════════════════════════════════════════
//
// Provides real images for fight news articles by:
//  1. Fetching OG (Open Graph) images from article URLs
//  2. Caching fetched images for performance
//  3. Providing category-specific fallback thumbnails via DFC CDN
//  4. Supporting fighter avatar library lookups
//
// Used by FightNewsService to show real news images in the feed
// instead of generic DFC branded backgrounds.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/image_assets.dart';

class NewsImageService {
  NewsImageService._();
  static final NewsImageService instance = NewsImageService._();

  /// Cache of resolved OG images: articleUrl → imageUrl
  final _ogImageCache = <String, String>{};

  /// Cache of failed lookups (to avoid re-fetching)
  final _failedLookups = <String>{};

  /// Maximum cache size
  static const int _maxCacheSize = 500;

  /// Fetch timeout
  static const Duration _fetchTimeout = Duration(seconds: 5);

  /// Try to get the OG image for a URL, return null if unavailable.
  Future<String?> fetchOgImage(String? articleUrl) async {
    if (articleUrl == null || articleUrl.isEmpty) return null;
    if (_failedLookups.contains(articleUrl)) return null;
    if (_ogImageCache.containsKey(articleUrl)) return _ogImageCache[articleUrl];

    // Browser CORS blocks third-party OG scraping in web builds.
    if (kIsWeb) return null;

    try {
      final uri = Uri.tryParse(articleUrl);
      if (uri == null || !uri.hasScheme) return null;

      final response = await http.get(uri).timeout(_fetchTimeout);

      if (response.statusCode != 200) {
        _failedLookups.add(articleUrl);
        return null;
      }

      final body = response.body;

      // Try og:image first, then twitter:image
      String? ogImage = _extractMetaContent(body, 'og:image');
      ogImage ??= _extractMetaContent(body, 'twitter:image');
      ogImage ??= _extractMetaContent(body, 'twitter:image:src');

      if (ogImage != null && ogImage.isNotEmpty) {
        // Resolve relative URLs
        if (ogImage.startsWith('//')) {
          ogImage = 'https:$ogImage';
        } else if (ogImage.startsWith('/')) {
          ogImage = '${uri.scheme}://${uri.host}$ogImage';
        }

        // Validate it looks like an image URL
        if (_isValidImageUrl(ogImage)) {
          _cacheImage(articleUrl, ogImage);
          return ogImage;
        }
      }

      _failedLookups.add(articleUrl);
      return null;
    } catch (_) {
      _failedLookups.add(articleUrl);
      return null;
    }
  }

  /// Batch-resolve OG images for multiple articles.
  Future<Map<String, String>> batchFetchOgImages(
    List<String> articleUrls,
  ) async {
    if (kIsWeb || articleUrls.isEmpty) return const {};

    final results = <String, String>{};
    final futures = <Future<void>>[];
    final uniqueUrls = articleUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet();

    for (final url in uniqueUrls) {
      futures.add(
        fetchOgImage(url).then((imageUrl) {
          if (imageUrl != null) results[url] = imageUrl;
        }),
      );
    }

    await Future.wait(futures);
    return results;
  }

  /// Get the best available image for a news article.
  /// Priority: cached OG → category fallback
  String resolveNewsImage({
    String? articleUrl,
    String? existingImageUrl,
    required String category,
  }) {
    // If already has a real network image, use it
    if (existingImageUrl != null &&
        existingImageUrl.startsWith('http') &&
        !_isGenericPlaceholder(existingImageUrl)) {
      return existingImageUrl;
    }

    // Check OG cache
    if (articleUrl != null && _ogImageCache.containsKey(articleUrl)) {
      return _ogImageCache[articleUrl]!;
    }

    // Return themed fallback based on category
    return _categoryThumbnail(category);
  }

  /// Category-themed fallback thumbnails.
  String _categoryThumbnail(String category) {
    final lc = category.toLowerCase();
    if (lc.contains('ufc') || lc.contains('mma')) {
      return ImageAssets.ufcPlaceholder;
    }
    if (lc.contains('box')) return ImageAssets.boxingPlaceholder;
    if (lc.contains('muay')) return ImageAssets.muayThaiPlaceholder;
    if (lc.contains('kick')) return ImageAssets.kickboxingPlaceholder;
    if (lc.contains('bare') || lc.contains('bkfc')) {
      return ImageAssets.bkfcPlaceholder;
    }
    return ImageAssets.bgAction;
  }

  /// Extract content from a meta tag in HTML.
  String? _extractMetaContent(String html, String property) {
    // Match: <meta property="og:image" content="...">
    // or:    <meta name="twitter:image" content="...">
    final patterns = [
      RegExp(
        '<meta[^>]*(?:property|name)=["\']$property["\'][^>]*content=["\']([^"\']+)["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]*content=["\']([^"\']+)["\'][^>]*(?:property|name)=["\']$property["\']',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) return match.group(1);
    }
    return null;
  }

  bool _isValidImageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    // Must be https (or http) and look like an image endpoint
    return uri.scheme == 'https' || uri.scheme == 'http';
  }

  bool _isGenericPlaceholder(String url) {
    return url.startsWith('assets/') ||
        url.contains('placeholder') ||
        url.contains('dfc_backgrounds');
  }

  void _cacheImage(String articleUrl, String imageUrl) {
    if (_ogImageCache.length >= _maxCacheSize) {
      // Evict oldest entries
      final keysToRemove = _ogImageCache.keys.take(100).toList();
      for (final key in keysToRemove) {
        _ogImageCache.remove(key);
      }
    }
    _ogImageCache[articleUrl] = imageUrl;
  }

  /// Cache stats for monitoring.
  Map<String, dynamic> get stats => {
    'cachedImages': _ogImageCache.length,
    'failedLookups': _failedLookups.length,
  };

  /// Clear all caches.
  void clearCache() {
    _ogImageCache.clear();
    _failedLookups.clear();
  }
}
