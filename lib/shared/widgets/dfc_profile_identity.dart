import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import 'dfc_network_image.dart';

String dfcResolveIdentityName(
  String? rawName, {
  String fallback = 'DFC Member',
}) {
  final cleaned = (rawName ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (cleaned.isNotEmpty) {
    return cleaned;
  }
  return fallback;
}

class DfcProfileIdentityAvatar extends StatelessWidget {
  final String? imageUrl;
  final String displayName;
  final double radius;
  final Color backgroundColor;
  final Color accentColor;
  final double ringPadding;
  final double borderWidth;
  final List<Color>? gradientColors;
  final IconData fallbackIcon;

  const DfcProfileIdentityAvatar({
    super.key,
    this.imageUrl,
    required this.displayName,
    required this.radius,
    this.backgroundColor = DesignTokens.bgSecondary,
    this.accentColor = DesignTokens.neonCyan,
    this.ringPadding = 0,
    this.borderWidth = 1,
    this.gradientColors,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedName = dfcResolveIdentityName(displayName, fallback: 'D');
    final fallbackText = resolvedName.characters.first.toUpperCase();

    Widget avatar = DfcCircleAvatar(
      imageUrl: imageUrl,
      radius: radius,
      backgroundColor: backgroundColor,
      borderColor: accentColor.withValues(alpha: 0.28),
      borderWidth: borderWidth,
      gradientColors: gradientColors,
      fallbackText: fallbackText,
      fallbackIcon: fallbackIcon,
      fallbackIconColor: accentColor,
    );

    if (ringPadding > 0) {
      avatar = Container(
        padding: EdgeInsets.all(ringPadding),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors:
                gradientColors ??
                [accentColor, accentColor.withValues(alpha: 0.35)],
          ),
        ),
        child: avatar,
      );
    }

    return avatar;
  }
}

class DfcProfileIdentityRow extends StatelessWidget {
  final String displayName;
  final String? imageUrl;
  final String? subtitle;
  final String? roleLabel;
  final bool verified;
  final double avatarRadius;
  final Color accentColor;
  final Color? nameColor;
  final Color? subtitleColor;
  final double ringPadding;

  const DfcProfileIdentityRow({
    super.key,
    required this.displayName,
    this.imageUrl,
    this.subtitle,
    this.roleLabel,
    this.verified = false,
    this.avatarRadius = 20,
    this.accentColor = DesignTokens.neonCyan,
    this.nameColor,
    this.subtitleColor,
    this.ringPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedName = dfcResolveIdentityName(displayName);

    return Row(
      children: [
        DfcProfileIdentityAvatar(
          imageUrl: imageUrl,
          displayName: resolvedName,
          radius: avatarRadius,
          accentColor: accentColor,
          ringPadding: ringPadding,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      resolvedName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: nameColor ?? Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (verified) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.verified, size: 14, color: accentColor),
                  ],
                ],
              ),
              if ((subtitle ?? '').isNotEmpty ||
                  (roleLabel ?? '').isNotEmpty) ...[
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if ((subtitle ?? '').isNotEmpty)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color:
                              subtitleColor ??
                              Colors.white.withValues(alpha: 0.35),
                          fontSize: 11,
                        ),
                      ),
                    if ((roleLabel ?? '').isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          roleLabel!,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
