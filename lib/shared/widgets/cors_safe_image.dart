import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/image_assets.dart';
import '../../core/utils/image_url_sanitizer.dart';

/// Widget that handles CORS issues gracefully for external images
/// Falls back to placeholder icons if images fail to load
class CorsSafeImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final IconData fallbackIcon;
  final BorderRadius? borderRadius;

  const CorsSafeImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fallbackIcon = Icons.image,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final safeUrl = ImageUrlSanitizer.sanitize(
      imageUrl,
      fallback: ImageAssets.fightPlaceholder,
    );

    final child = CachedNetworkImage(
      imageUrl: safeUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: borderRadius,
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 2,
              ),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey[900]!, const Color(0xFF303030)],
              ),
              borderRadius: borderRadius,
            ),
            child: Center(
              child: Icon(
                fallbackIcon,
                color: Colors.grey[700],
                size: width != null ? width! * 0.3 : 48,
              ),
            ),
          ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
