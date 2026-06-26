import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV AD SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
/// Manages monetization through ads on the PPV storefront without
/// interfering with premium content experience

class PPVAdService {
  static final PPVAdService _instance = PPVAdService._internal();
  bool _isInitialized = false;

  factory PPVAdService() {
    return _instance;
  }

  PPVAdService._internal();

  /// Initialize Google Mobile Ads SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Google Mobile Ads SDK
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✓ Ad service initialized');
    } catch (e) {
      debugPrint('⚠️  Ad service initialization failed: $e');
    }
  }

  /// Check if ads are enabled (respects user preferences)
  bool get isAdsEnabled => _isInitialized;

  /// Load a banner ad for placement in the storefront
  BannerAd? loadBannerAd({required String adUnitId, required AdSize size}) {
    if (!_isInitialized) return null;

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✓ Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('✗ Banner ad failed: ${error.message}');
          ad.dispose();
        },
      ),
    );

    banner.load();
    return banner;
  }

  /// Build a banner ad widget
  static Widget buildBannerAdWidget({
    required BannerAd? bannerAd,
    EdgeInsets padding = const EdgeInsets.only(bottom: 16),
  }) {
    if (bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Container(
        alignment: Alignment.center,
        width: bannerAd.size.width.toDouble(),
        height: bannerAd.size.height.toDouble(),
        child: AdWidget(ad: bannerAd),
      ),
    );
  }

  /// Log ad engagement event for analytics
  void logAdEvent(String eventName, {Map<String, dynamic>? parameters}) {
    // Could integrate with Firebase Analytics here
    debugPrint('📊 Ad event: $eventName - $parameters');
  }

  /// Dispose of ad resources
  void dispose() {
    // Clean up ad resources
  }
}

/// Native ad widget for integrated ad placements (sponsor spots)
class PPVNativeAdWidget extends StatelessWidget {
  final String sponsorName;
  final String sponsorLogo;
  final String adCopy;
  final VoidCallback onTap;
  final Color accentColor;

  const PPVNativeAdWidget({
    super.key,
    required this.sponsorName,
    required this.sponsorLogo,
    required this.adCopy,
    required this.onTap,
    this.accentColor = const Color(0xFF00D9FF),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (sponsorLogo.isNotEmpty)
                  Image.network(
                    sponsorLogo,
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sponsor Spotlight',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      sponsorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              adCopy,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Learn more',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Icon(Icons.arrow_forward, color: accentColor, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ad Unit IDs for different environments
class PPVAdUnitIds {
  static const String bannerTestUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialTestUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedTestUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // Production IDs (replace with actual IDs)
  static const String bannerProdUnitId =
      'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
  static const String interstitialProdUnitId =
      'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
  static const String rewardedProdUnitId =
      'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';

  static bool get isProduction => false; // Toggle for production

  static String get bannerUnitId =>
      isProduction ? bannerProdUnitId : bannerTestUnitId;
  static String get interstitialUnitId =>
      isProduction ? interstitialProdUnitId : interstitialTestUnitId;
  static String get rewardedUnitId =>
      isProduction ? rewardedProdUnitId : rewardedTestUnitId;
}
