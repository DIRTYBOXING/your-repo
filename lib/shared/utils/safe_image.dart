import 'package:flutter/material.dart';
import '../../core/constants/image_assets.dart';
import '../widgets/cors_safe_image.dart';

/// Helper extension for building safe network images with fallback handling
extension SafeNetworkImage on Widget {
  /// Builds an image with automatic CORS and error handling
  static Widget build(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    IconData fallbackIcon = Icons.sports_mma,
  }) {
    return CorsSafeImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      fallbackIcon: fallbackIcon,
    );
  }
}

/// Legacy Image.network wrapper with automatic error handling
class SafeImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;

  const SafeImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.sports_mma,
  });

  @override
  Widget build(BuildContext context) {
    if (ImageAssets.isLocalAsset(url)) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey[900]!, const Color(0xFF303030)],
              ),
            ),
            child: Center(
              child: Icon(
                fallbackIcon,
                color: Colors.grey[700],
                size: width != null ? width! * 0.3 : 48,
              ),
            ),
          );
        },
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[900]!, const Color(0xFF303030)],
            ),
          ),
          child: Center(
            child: Icon(
              fallbackIcon,
              color: Colors.grey[700],
              size: width != null ? width! * 0.3 : 48,
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[900],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
}
