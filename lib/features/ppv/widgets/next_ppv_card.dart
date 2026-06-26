import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/image_assets.dart';
import '../../../shared/widgets/dfc_network_image.dart';

class NextPpvCard extends StatelessWidget {
  final String title, location, broadcaster, posterUrl;
  final DateTime startTime;
  final VoidCallback onOpenDetails, onBuy;

  const NextPpvCard({
    super.key,
    required this.title,
    required this.startTime,
    required this.location,
    required this.broadcaster,
    required this.posterUrl,
    required this.onOpenDetails,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final allowSyntheticPosters =
        AppConstants.webDemoMode || AppConstants.syntheticContentEnabled;
    final trimmedPosterUrl = posterUrl.trim();
    final hasRealPosterUrl =
        trimmedPosterUrl.startsWith('http://') ||
        trimmedPosterUrl.startsWith('https://');

    final displayPosterUrl =
        (trimmedPosterUrl.isNotEmpty &&
            (allowSyntheticPosters || hasRealPosterUrl))
        ? ImageAssets.posterVariantFromUrl(trimmedPosterUrl, variant: 'banner')
        : '';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          Stack(
            children: [
              if (displayPosterUrl.isNotEmpty)
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: DfcNetworkImage(
                    url: displayPosterUrl,
                    height: 250,
                    width: double.infinity,
                    errorWidget: _buildPosterFallback(),
                  ),
                )
              else
                _buildPosterFallback(),
              // Bottom gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(startTime)} \u2022 $location',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildButton(
                        label: 'Secure Checkout',
                        icon: Icons.local_fire_department,
                        onPressed: onBuy,
                        isPrimary: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildButton(
                        label: 'View Event',
                        icon: Icons.open_in_new,
                        onPressed: onOpenDetails,
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.neonCyan,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: DesignTokens.neonCyan,
        side: BorderSide(color: DesignTokens.neonCyan.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }

  Widget _buildPosterFallback() {
    return Container(
      height: 250,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0A2E), Colors.black],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 36,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 10),
            Text(
              'Poster unavailable',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
