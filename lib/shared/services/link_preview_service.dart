import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Open Graph metadata extracted from a URL.
class LinkPreviewData {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? domain;
  final String? favicon;

  const LinkPreviewData({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.domain,
    this.favicon,
  });

  bool get hasContent =>
      title != null || description != null || imageUrl != null;

  Map<String, dynamic> toMap() => {
    'url': url,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'domain': domain,
    'favicon': favicon,
  };

  factory LinkPreviewData.fromMap(Map<String, dynamic> data) {
    return LinkPreviewData(
      url: data['url'] ?? '',
      title: data['title'],
      description: data['description'],
      imageUrl: data['imageUrl'],
      domain: data['domain'],
      favicon: data['favicon'],
    );
  }
}

/// Service that extracts URLs from text and fetches Open Graph metadata.
///
/// Uses only the `http` package + regex-based HTML parsing — no extra
/// dependencies needed.  Caches results in-memory to avoid re-fetching.
class LinkPreviewService {
  LinkPreviewService._();
  static final instance = LinkPreviewService._();

  /// In-memory cache: URL → preview data (or null if fetch failed)
  final Map<String, LinkPreviewData?> _cache = {};

  /// Regex to detect URLs in plain text
  static final _urlPattern = RegExp(
    r'https?://[^\s<>\[\]"]+',
    caseSensitive: false,
  );

  /// Extract the first URL found in [text], or null.
  String? extractFirstUrl(String text) {
    final match = _urlPattern.firstMatch(text);
    return match?.group(0);
  }

  /// Fetch Open Graph metadata for [url].
  /// Returns cached result if available.
  Future<LinkPreviewData?> fetchPreview(String url) async {
    if (_cache.containsKey(url)) return _cache[url];

    // Browser CORS prevents generic third-party HTML scraping on web.
    // Return null and let UI fall back to plain links.
    if (kIsWeb) {
      _cache[url] = null;
      return null;
    }

    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        _cache[url] = null;
        return null;
      }

      final html = response.body;
      final preview = _parseOgTags(html, url);
      _cache[url] = preview;
      return preview;
    } catch (e) {
      debugPrint('[LinkPreview] Failed to fetch $url: $e');
      _cache[url] = null;
      return null;
    }
  }

  /// Parse OG meta tags from raw HTML using regex.
  LinkPreviewData _parseOgTags(String html, String originalUrl) {
    String? ogTitle = _extractMeta(html, 'og:title');
    String? ogDesc = _extractMeta(html, 'og:description');
    String? ogImage = _extractMeta(html, 'og:image');

    // Fallback to standard HTML title + meta description
    ogTitle ??= _extractHtmlTitle(html);
    ogDesc ??= _extractMeta(html, 'description');

    final uri = Uri.tryParse(originalUrl);
    final domain = uri?.host ?? '';

    // Resolve relative image URLs
    if (ogImage != null && !ogImage.startsWith('http') && uri != null) {
      ogImage = uri.resolve(ogImage).toString();
    }

    return LinkPreviewData(
      url: originalUrl,
      title: ogTitle,
      description: ogDesc,
      imageUrl: ogImage,
      domain: domain,
      favicon: uri != null ? '${uri.scheme}://$domain/favicon.ico' : null,
    );
  }

  /// Extract <meta property="[property]" content="..."> or
  /// <meta name="[property]" content="..."> value.
  String? _extractMeta(String html, String property) {
    // property= variant (OG tags)
    final propPattern = RegExp(
      '<meta[^>]+(?:property|name)=["\']$property["\'][^>]+content=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    var match = propPattern.firstMatch(html);
    if (match != null) return _decodeHtml(match.group(1)?.trim() ?? '');

    // Reversed attribute order: content= before property=
    final reversePattern = RegExp(
      '<meta[^>]+content=["\']([^"\']*)["\'][^>]+(?:property|name)=["\']$property["\']',
      caseSensitive: false,
    );
    match = reversePattern.firstMatch(html);
    if (match != null) return _decodeHtml(match.group(1)?.trim() ?? '');

    return null;
  }

  /// Extract <title>...</title> text
  String? _extractHtmlTitle(String html) {
    final match = RegExp(
      r'<title[^>]*>([^<]*)</title>',
      caseSensitive: false,
    ).firstMatch(html);
    final raw = match?.group(1)?.trim();
    return raw != null && raw.isNotEmpty ? _decodeHtml(raw) : null;
  }

  /// Basic HTML entity decoding
  String _decodeHtml(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&apos;', "'");
  }
}
