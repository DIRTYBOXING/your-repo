import 'package:flutter/material.dart';
import '../../core/constants/image_assets.dart';
import 'dfc_network_image.dart';

/// Branded DFC placeholder that replaces random stock photos.
///
/// Shows the DFC logo on a dark gradient background with an optional
/// category label (e.g. "MMA", "GLORY 92", "Boxing"). Use this anywhere
/// the app would otherwise show a picsum/pexels/placeholder image.
class DfcBrandedImage extends StatelessWidget {
  final String? imageUrl;
  final String? category;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const DfcBrandedImage({
    super.key,
    this.imageUrl,
    this.category,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? '').trim();
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');
    final isBlocked = isNetwork && _isBlockedUrl(url);
    final hasValidNetwork = isNetwork && !isBlocked && url.isNotEmpty;

    Widget image;
    if (hasValidNetwork) {
      image = DfcNetworkImage(url: url, width: width, height: height, fit: fit);
    } else if (url.isNotEmpty && !isNetwork) {
      // Local asset path
      image = Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, e2, s2) => _brandedFallback(),
      );
    } else {
      image = _brandedFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _brandedFallback() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1228), Color(0xFF060C18)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle radial glow
          Container(
            width: (width ?? 200) * 0.6,
            height: (height ?? 200) * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00E5FF).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                ImageAssets.dfcBrandedPlaceholder,
                width: _logoSize,
                height: _logoSize,
                fit: BoxFit.contain,
                errorBuilder: (_, e3, s3) => Icon(
                  Icons.sports_mma,
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                  size: _logoSize * 0.7,
                ),
              ),
              if (category != null && category!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  category!.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.7),
                    fontSize: _labelSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  double get _logoSize {
    final h = height ?? 200;
    if (h > 300) return 80;
    if (h > 150) return 56;
    return 36;
  }

  double get _labelSize {
    final h = height ?? 200;
    if (h > 300) return 12;
    if (h > 150) return 10;
    return 8;
  }

  static bool _isBlockedUrl(String url) {
    const blocked = [
      'images.pexels.com',
      'picsum.photos',
      'via.placeholder.com',
    ];
    for (final host in blocked) {
      if (url.contains(host)) return true;
    }
    return false;
  }
}
