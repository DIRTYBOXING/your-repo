import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/image_assets.dart';
import '../../core/utils/image_url_sanitizer.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC NETWORK IMAGE — Safe network image with error/loading handling
///
/// Replaces raw Image.network / NetworkImage with proper fallbacks.
/// Shows a styled placeholder on error and a loading shimmer while loading.
/// ═══════════════════════════════════════════════════════════════════════════

const Color _card = Color(0xFF0A1628);
const Color _cyan = Color(0xFF00E5FF);

bool _isSvgPath(String value) =>
    value.toLowerCase().split('?').first.endsWith('.svg');

/// Drop-in replacement for Image.network with error + loading handling.
class DfcNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData errorIcon;
  final Color? errorIconColor;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const DfcNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorIcon = Icons.broken_image_outlined,
    this.errorIconColor,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final safeUrl = ImageUrlSanitizer.sanitize(
      url,
      fallback: ImageAssets.fightPlaceholder,
    );

    Widget image;
    if (ImageAssets.isLocalAsset(safeUrl)) {
      if (_isSvgPath(safeUrl)) {
        image = SvgPicture.asset(
          safeUrl,
          width: width,
          height: height,
          fit: fit,
          placeholderBuilder: (context) {
            if (loadingWidget != null) {
              return SizedBox(
                width: width,
                height: height,
                child: loadingWidget,
              );
            }
            return Container(
              width: width,
              height: height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D2137), Color(0xFF0A1628)],
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _cyan.withValues(alpha: 0.5),
                ),
              ),
            );
          },
        );
      } else {
        image = Image.asset(
          safeUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            if (errorWidget != null) {
              return SizedBox(width: width, height: height, child: errorWidget);
            }
            return Container(
              width: width,
              height: height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D2137), Color(0xFF0A1628)],
                ),
              ),
              child: Center(
                child: Image.asset(
                  ImageAssets.dfcBrandedPlaceholder,
                  width: 48,
                  height: 48,
                  color: _cyan.withValues(alpha: 0.4),
                  errorBuilder: (_, _, _) => Icon(
                    errorIcon,
                    color: errorIconColor ?? _cyan.withValues(alpha: 0.3),
                    size: 32,
                  ),
                ),
              ),
            );
          },
        );
      }
    } else {
      if (_isSvgPath(safeUrl)) {
        image = SvgPicture.network(
          safeUrl,
          width: width,
          height: height,
          fit: fit,
          placeholderBuilder: (context) {
            if (loadingWidget != null) {
              return SizedBox(
                width: width,
                height: height,
                child: loadingWidget,
              );
            }
            return Container(
              width: width,
              height: height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D2137), Color(0xFF0A1628)],
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _cyan.withValues(alpha: 0.5),
                ),
              ),
            );
          },
        );
      } else {
        image = CachedNetworkImage(
          imageUrl: safeUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) {
            if (loadingWidget != null) {
              return SizedBox(
                width: width,
                height: height,
                child: loadingWidget,
              );
            }
            return Container(
              width: width,
              height: height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D2137), Color(0xFF0A1628)],
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _cyan.withValues(alpha: 0.5),
                ),
              ),
            );
          },
          errorWidget: (context, url, error) {
            if (errorWidget != null) {
              return SizedBox(width: width, height: height, child: errorWidget);
            }
            return Image.asset(
              ImageAssets.dfcBrandedPlaceholder,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, _, _) {
                return Container(
                  width: width,
                  height: height,
                  color: _card,
                  child: Center(
                    child: Icon(
                      errorIcon,
                      color: errorIconColor ?? _cyan.withValues(alpha: 0.3),
                      size: 32,
                    ),
                  ),
                );
              },
            );
          },
        );
      }
    }

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

/// Safe ImageProvider that wraps NetworkImage with an onError fallback.
/// Use this wherever you need a NetworkImage (CircleAvatar, DecorationImage).
class DfcSafeNetworkImage extends ImageProvider<NetworkImage> {
  final String url;
  final NetworkImage _delegate;

  DfcSafeNetworkImage(this.url)
    : _delegate = NetworkImage(
        ImageUrlSanitizer.sanitize(url, fallback: ImageAssets.fightPlaceholder),
      );

  @override
  ImageStreamCompleter loadImage(
    NetworkImage key,
    ImageDecoderCallback decode,
  ) {
    return _delegate.loadImage(_delegate, decode);
  }

  @override
  Future<NetworkImage> obtainKey(ImageConfiguration configuration) {
    return _delegate.obtainKey(configuration);
  }

  @override
  bool operator ==(Object other) =>
      other is DfcSafeNetworkImage && url == other.url;

  @override
  int get hashCode => url.hashCode;
}

/// Builds a safe backgroundImage for CircleAvatar.
/// Returns null and uses child fallback if url is null/empty.
ImageProvider? safeNetworkImageProvider(String? url) {
  if (url == null || url.isEmpty) return null;
  final sanitized = ImageUrlSanitizer.sanitize(
    url,
    fallback: ImageAssets.fightPlaceholder,
  );
  if (ImageAssets.isLocalAsset(sanitized)) return AssetImage(sanitized);
  return NetworkImage(sanitized);
}

/// Builds a CircleAvatar with safe network image handling.
/// Shows icon fallback on null URL or load error.
class DfcCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color backgroundColor;
  final IconData fallbackIcon;
  final Color? fallbackIconColor;
  final String? fallbackText;
  final List<Color>? gradientColors;
  final Color? borderColor;
  final double borderWidth;
  final TextStyle? fallbackTextStyle;
  final Widget? fallbackChild;

  const DfcCircleAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor = _card,
    this.fallbackIcon = Icons.person,
    this.fallbackIconColor,
    this.fallbackText,
    this.gradientColors,
    this.borderColor,
    this.borderWidth = 0,
    this.fallbackTextStyle,
    this.fallbackChild,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;

    final size = radius * 2;
    final fallback = _buildFallback();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        gradient: gradientColors != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors!,
              )
            : null,
        border: borderColor != null && borderWidth > 0
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: hasUrl
            ? DfcNetworkImage(
                url: imageUrl!,
                width: size,
                height: size,
                errorWidget: fallback,
              )
            : fallback,
      ),
    );
  }

  Widget _buildFallback() {
    if (fallbackChild != null) return fallbackChild!;

    return Container(
      width: radius * 2,
      height: radius * 2,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: fallbackText != null
          ? Text(
              fallbackText!,
              style:
                  fallbackTextStyle ??
                  TextStyle(
                    color: fallbackIconColor ?? _cyan,
                    fontSize: radius * 0.72,
                    fontWeight: FontWeight.bold,
                  ),
            )
          : Icon(
              fallbackIcon,
              color: fallbackIconColor ?? _cyan.withValues(alpha: 0.5),
              size: radius,
            ),
    );
  }
}

/// Safe DecorationImage that won't crash on bad URLs.
DecorationImage? safeDecorationImage({
  required String? url,
  BoxFit fit = BoxFit.cover,
  ColorFilter? colorFilter,
}) {
  if (url == null || url.isEmpty) return null;
  final sanitized = ImageUrlSanitizer.sanitize(
    url,
    fallback: ImageAssets.fightPlaceholder,
  );
  return DecorationImage(
    image: ImageAssets.isLocalAsset(sanitized)
        ? AssetImage(sanitized)
        : NetworkImage(sanitized),
    fit: fit,
    colorFilter: colorFilter,
    onError: (_, _) {},
  );
}
