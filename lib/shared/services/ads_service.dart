import 'package:flutter/foundation.dart';
// NOTE: google_mobile_ads requires Firebase Core ^3.x
// Once Firebase is upgraded, uncomment:
// import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ad placements throughout the app
enum AdPlacement {
  dashboardBanner,
  newsCarouselBanner,
  fightwireFeedInline,
  subscriptionInterstitial,
  rewardsWatchVideo,
}

/// AdMob configuration - Replace with your actual ad unit IDs
class AdMobConfig {
  // Test ad unit IDs (Google's official test IDs)
  static const String testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';
  static const String testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';

  // Replace with your production ad unit IDs from AdMob console
  static const String prodBannerAndroid = 'ca-app-pub-XXXXX/YYYYY';
  static const String prodBannerIos = 'ca-app-pub-XXXXX/YYYYY';
  static const String prodInterstitialAndroid = 'ca-app-pub-XXXXX/YYYYY';
  static const String prodInterstitialIos = 'ca-app-pub-XXXXX/YYYYY';
  static const String prodRewardedAndroid = 'ca-app-pub-XXXXX/YYYYY';
  static const String prodRewardedIos = 'ca-app-pub-XXXXX/YYYYY';
}

/// Reward item placeholder (mirrors google_mobile_ads RewardItem)
class AdReward {
  final int amount;
  final String type;

  AdReward({required this.amount, required this.type});
}

/// Google Mobile Ads orchestration service
///
/// STUB MODE: Full integration requires Firebase ^3.x upgrade
/// This service provides the complete API but simulates behavior until then.
class AdsService with ChangeNotifier {
  bool _initialized = false;
  bool _enabled = false;
  bool _isPremiumUser = false;

  // Stub mode flag - set to false when google_mobile_ads is enabled
  static const bool _stubMode = true;

  bool get enabled => _enabled && !_isPremiumUser;
  bool get initialized => _initialized;

  // Simulated ad ready states
  bool _bannerReady = false;
  bool _interstitialReady = false;
  bool _rewardedReady = false;

  /// Platform ad unit IDs per placement
  final Map<AdPlacement, Map<String, String>> _adUnitIds = {
    AdPlacement.dashboardBanner: {
      'android': AdMobConfig.testBannerAndroid,
      'ios': AdMobConfig.testBannerIos,
    },
    AdPlacement.newsCarouselBanner: {
      'android': AdMobConfig.testBannerAndroid,
      'ios': AdMobConfig.testBannerIos,
    },
    AdPlacement.fightwireFeedInline: {
      'android': AdMobConfig.testBannerAndroid,
      'ios': AdMobConfig.testBannerIos,
    },
    AdPlacement.subscriptionInterstitial: {
      'android': AdMobConfig.testInterstitialAndroid,
      'ios': AdMobConfig.testInterstitialIos,
    },
    AdPlacement.rewardsWatchVideo: {
      'android': AdMobConfig.testRewardedAndroid,
      'ios': AdMobConfig.testRewardedIos,
    },
  };

  /// Initialize Google Mobile Ads SDK
  Future<void> initialize({
    bool enableAds = true,
    bool isPremiumUser = false,
  }) async {
    if (_initialized) return;
    if (kIsWeb) {
      debugPrint('AdsService: Web platform - ads disabled');
      return;
    }

    _isPremiumUser = isPremiumUser;
    _enabled = enableAds;

    if (_stubMode) {
      debugPrint('AdsService: Stub mode - awaiting Firebase ^3.x upgrade');
      _initialized = true;

      // Simulate ad loading
      if (enabled) {
        await preloadPlacements();
      }

      notifyListeners();
      return;
    }

    // Real implementation when google_mobile_ads is enabled
    // try {
    //   await MobileAds.instance.initialize();
    //   _initialized = true;
    //   if (enabled) await preloadPlacements();
    //   notifyListeners();
    // } catch (e) {
    //   debugPrint('AdsService: Failed to initialize - $e');
    // }
  }

  /// Update premium status (disables ads for subscribers)
  void setPremiumUser(bool isPremium) {
    _isPremiumUser = isPremium;
    if (isPremium) {
      disposeAllAds();
    }
    notifyListeners();
  }

  /// Owner control: enable/disable ads at runtime.
  Future<void> setAdsEnabled(bool enabled) async {
    _enabled = enabled;
    if (!enabled) {
      disposeAllAds();
    } else if (_initialized) {
      await preloadPlacements();
    }
    notifyListeners();
  }

  /// Override ad unit IDs for production
  void configureAdUnit(AdPlacement placement, {String? android, String? ios}) {
    final current = _adUnitIds[placement] ?? {};
    _adUnitIds[placement] = {
      'android': android ?? current['android'] ?? '',
      'ios': ios ?? current['ios'] ?? '',
    };
  }

  /// Preload all ad placements
  Future<void> preloadPlacements() async {
    if (!enabled || !_initialized) return;

    if (_stubMode) {
      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 300));
      _bannerReady = true;
      _interstitialReady = true;
      _rewardedReady = true;
      notifyListeners();
      debugPrint('AdsService: Ads preloaded (stub mode)');
      return;
    }

    // Real implementation
  }

  // ==================== BANNER ADS ====================

  /// Load a banner ad for a specific placement
  Future<void> loadBannerAd(AdPlacement placement) async {
    if (!enabled || !_initialized) return;

    if (_stubMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      _bannerReady = true;
      notifyListeners();
      debugPrint('AdsService: Banner loaded for $placement (stub)');
      return;
    }

    // Real implementation
  }

  /// Check if banner is ready for placement
  bool isBannerReady(AdPlacement placement) {
    return _bannerReady && enabled;
  }

  // ==================== INTERSTITIAL ADS ====================

  /// Load an interstitial ad
  Future<void> loadInterstitialAd() async {
    if (!enabled || !_initialized) return;

    if (_stubMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      _interstitialReady = true;
      notifyListeners();
      debugPrint('AdsService: Interstitial loaded (stub)');
      return;
    }

    // Real implementation
  }

  /// Show interstitial ad
  Future<bool> showInterstitial() async {
    if (!enabled || !_interstitialReady) return false;

    if (_stubMode) {
      debugPrint('AdsService: Showing interstitial (stub)');
      await Future.delayed(const Duration(seconds: 1));
      _interstitialReady = false;
      loadInterstitialAd(); // Preload next
      return true;
    }

    // Real implementation
    return false;
  }

  // ==================== REWARDED ADS ====================

  /// Load a rewarded video ad
  Future<void> loadRewardedAd() async {
    if (!enabled || !_initialized) return;

    if (_stubMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      _rewardedReady = true;
      notifyListeners();
      debugPrint('AdsService: Rewarded ad loaded (stub)');
      return;
    }

    // Real implementation
  }

  /// Check if rewarded ad is ready to show
  bool get isRewardedAdReady => _rewardedReady && enabled;

  /// Show rewarded video ad and return the reward earned
  Future<AdReward?> showRewardedAd() async {
    if (!enabled || !_rewardedReady) return null;

    if (_stubMode) {
      debugPrint('AdsService: Showing rewarded ad (stub)');
      await Future.delayed(const Duration(seconds: 2));
      _rewardedReady = false;
      loadRewardedAd(); // Preload next

      // Return mock reward
      return AdReward(amount: 10, type: 'coins');
    }

    // Real implementation
    return null;
  }

  // ==================== UTILITIES ====================

  /// Dispose all cached ads
  void disposeAllAds() {
    _bannerReady = false;
    _interstitialReady = false;
    _rewardedReady = false;
    notifyListeners();
  }

  /// Get ad unit IDs for a placement (for debugging)
  Map<String, String> getAdUnit(AdPlacement placement) {
    return _adUnitIds[placement] ?? const {};
  }

  @override
  void dispose() {
    disposeAllAds();
    super.dispose();
  }
}
