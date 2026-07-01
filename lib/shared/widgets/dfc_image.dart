import 'package:flutter/material.dart';
import '../../core/constants/image_assets.dart';
import '../../core/utils/image_url_sanitizer.dart';

/// Smart image widget that automatically handles local assets vs network URLs.
///
/// Uses [ImageAssets.isLocalAsset] to detect asset paths (e.g. 'assets/logos/...')
/// and renders [Image.asset] for those, [Image.network] for http(s) URLs.
/// Falls back to [ImageAssets.dfcBrandedPlaceholder] when the URL is empty or blocked.
class DfcImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const DfcImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final sanitized = ImageUrlSanitizer.sanitize(url);

    if (ImageAssets.isLocalAsset(sanitized)) {
      return Image.asset(
        sanitized,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _buildFallback(),
      );
    }

    return Image.network(
      sanitized,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    if (fallback != null) return fallback!;
    return Image.asset(
      ImageAssets.dfcBrandedPlaceholder,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
