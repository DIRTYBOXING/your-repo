import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import 'dfc_network_image.dart';

class DFCPosterFrame extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final Widget? background;
  final Widget? foreground;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Gradient? overlayGradient;
  final Gradient? backgroundGradient;
  final Color? borderColor;

  const DFCPosterFrame({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.background,
    this.foreground,
    this.loadingWidget,
    this.errorWidget,
    this.overlayGradient,
    this.backgroundGradient,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final backgroundChildren = background == null
      ? const <Widget>[]
      : <Widget>[background!];
    final overlayChildren = overlayGradient == null
      ? const <Widget>[]
      : <Widget>[
        DecoratedBox(decoration: BoxDecoration(gradient: overlayGradient)),
        ];
    final foregroundChildren = foreground == null
      ? const <Widget>[]
      : <Widget>[foreground!];

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient:
            backgroundGradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF102034), Color(0xFF08111D)],
            ),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ...backgroundChildren,
          if (hasImage)
            DfcNetworkImage(
              url: imageUrl!,
              width: width,
              height: height,
              fit: fit,
              loadingWidget: loadingWidget,
              errorWidget: errorWidget,
            )
          else if (background == null)
            const _PosterFallback(),
          ...overlayChildren,
          ...foregroundChildren,
        ],
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.sports_mma,
        size: 42,
        color: DesignTokens.neonCyan.withValues(alpha: 0.3),
      ),
    );
  }
}
