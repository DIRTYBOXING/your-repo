import 'package:flutter/foundation.dart';
import '../constants/image_assets.dart';

/// Central guard for known-bad image URLs seen in local/dev builds.
///
/// Blocks external stock/placeholder hosts (pexels, picsum, via.placeholder)
/// and falls back to LOCAL branded DFC assets — never to another external URL.
class ImageUrlSanitizer {
  static const String _deadPexelsA =
      'https://images.pexels.com/photos/70567/pexels-photo-70567.jpeg?auto=compress&cs=tinysrgb&w=800';
  static const String _deadPexelsB =
      'https://images.pexels.com/photos/70567/boxing-ring-boxers-fight-70567.jpeg?auto=compress&cs=tinysrgb&w=800';

  static const _deadStoragePrefixes = [
    'https://firebasestorage.googleapis.com/v0/b/datafightcentral.firebasestorage.app/o/placeholders%2F',
    'https://firebasestorage.googleapis.com/v0/b/datafightcentral.firebasestorage.app/o/placeholders/',
  ];

  static const _blockedHosts = [
    'images.pexels.com',
    'picsum.photos',
    'via.placeholder.com',
  ];

  // On web/CanvasKit, many third-party image hosts block CORS and will fail.
  // Keep this list tight and extend only for domains proven to return
  // permissive CORS headers in production.
  static const _webAllowedHosts = [
    'firebasestorage.googleapis.com',
    'storage.googleapis.com',
    'lh3.googleusercontent.com',
    'datafightcentral.com',
    'datafightcentral.app',
  ];

  /// The fallback is ALWAYS a local asset — never an external URL.
  static const String _localFallback = ImageAssets.dfcBrandedPlaceholder;

  static String _normalizeLocalAssetPath(String input) {
    var value = input.trim().replaceAll('\\\\', '/');
    if (value.isEmpty) return value;

    // Legacy seed/docs sometimes used this invalid folder spelling.
    value = value.replaceAll(
      'assets/dfc backgrounds/',
      'assets/dfc_backgrounds/',
    );
    value = value.replaceAll(
      'assets/dfc%20backgrounds/',
      'assets/dfc_backgrounds/',
    );

    if (value.startsWith('assets/')) {
      value = Uri.decodeFull(value);
    }

    return value;
  }

  static String sanitize(String? rawUrl, {String fallback = _localFallback}) {
    final url = _normalizeLocalAssetPath(rawUrl ?? '');
    if (url.isEmpty) return fallback;

    // Local asset paths are always safe
    if (ImageAssets.isLocalAsset(url)) return url;

    if (url == _deadPexelsA || url == _deadPexelsB) {
      return fallback;
    }

    for (final prefix in _deadStoragePrefixes) {
      if (url.startsWith(prefix)) {
        return fallback;
      }
    }

    if (!(url.startsWith('http://') || url.startsWith('https://'))) {
      return fallback;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return fallback;

    for (final host in _blockedHosts) {
      if (uri.host.contains(host)) {
        return fallback;
      }
    }

    if (kIsWeb) {
      final host = uri.host.toLowerCase();
      final allowed = _webAllowedHosts.any(
        (h) => host == h || host.endsWith('.$h'),
      );
      if (!allowed) return fallback;
    }

    return url;
  }
}
