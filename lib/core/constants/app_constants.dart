import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../shared/models/stats/combat_stats.dart';

/// DataFightCentral Application Constants
class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'Data Fight Central';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Professional Social Media and PPV Platform for Combat Sports';
  static const bool webDemoMode = bool.fromEnvironment('WEB_DEMO_MODE');
  static const bool useFirebaseEmulator = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
  );

  // Synthetic/generated content is OFF by default.
  static const bool syntheticContentEnabled = bool.fromEnvironment(
    'ALLOW_SYNTHETIC_CONTENT',
  );

  /// Auto-seeding must never silently touch a live Firebase project.
  /// Use sandbox lane (demo + emulator), or explicitly opt in.
  static const bool allowLiveAutoSeed = bool.fromEnvironment(
    'ALLOW_LIVE_AUTO_SEED',
  );

  /// Non-core surfaces stay OFF unless explicitly enabled.
  static const bool enableDroneRacing = bool.fromEnvironment(
    'ENABLE_DRONE_RACING',
  );

  static const bool enableGames = bool.fromEnvironment('ENABLE_GAMES');

  static const bool featureShellV2 = bool.fromEnvironment(
    'FEATURE_SHELL_V2',
    defaultValue: true,
  );

  static const bool featurePpvStore = bool.fromEnvironment('FEATURE_PPV_STORE');

  static const bool featurePlaySkin = bool.fromEnvironment('FEATURE_PLAY_SKIN');

  static bool get authEnabled => !(kIsWeb && webDemoMode);

  /// Safe local sandbox lane: demo shell backed by the local emulator suite.
  static bool get shouldSeedDemoData => webDemoMode && useFirebaseEmulator;

  static bool get allowAutoSeed => shouldSeedDemoData || allowLiveAutoSeed;

  /// True when the user is browsing as guest (emergency local session).
  /// Services should serve demo/fallback data instead of querying Firestore.
  static bool guestMode = false;

  static const bool googleSignInEnabled = true;
  static const String authDisabledMessage =
      'Live authentication will switch on once Firebase keys are provided. For now, logins are disabled.';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String fightersCollection = 'fighters';
  static const String gymsCollection = 'gyms';
  static const String eventsCollection = 'events';
  static const String fightsCollection = 'fights';
  static const String rankingsCollection = 'rankings';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String jobsCollection = 'jobs';
  static const String newsCollection = 'news';
  static const String consentsCollection = 'consents';
  static const String adsCollection = 'ads';
  static const String verificationCollection = 'verification';
  static const String auditLogCollection = 'audit_logs';
  static const String fightStockCollection = 'fight_stocks';
  static const String fighterStatsCollection = 'fighter_stats';
  static const String trainingSessionsCollection = 'training_sessions';
  static const String trainingCyclesCollection = 'training_cycles';
  static const String onboardingCollection = 'user_onboarding';
  static const String engagementMetricsCollection = 'engagement_metrics';
  static const String userActivityCollection = 'user_activity';
  static const String adPerformanceCollection = 'ad_performance';
  static const String aiRecommendationCollection = 'ai_recommendations';
  static const String fighterBrandingCollection = 'fighter_branding';
  static const String aiInsightsCollection = 'ai_insights';
  static const String promotionRunsCollection = 'promotion_runs';
  static const String promotionDlqCollection = 'promotion_dlq';
  static const String campaignVariantsCollection = 'campaign_variants';
  static const String regionsCollection = 'regions';
  static const String moderationCollection = 'moderation';
  static const String settingsCollection = 'settings';
  static const String marketplaceItemsCollection = 'marketplace_items';
  static const String storiesCollection = 'stories';
  static const String scannedContentCollection = 'scanned_content';

  // Subcollections
  static const String healthLogsSubcollection = 'health_logs';
  static const String closeFriendsSubcollection = 'close_friends';
  static const String aiInsightsSubcollection = 'ai_insights';
  static const String questionsSubcollection = 'questions';
  static const String responsesSubcollection = 'responses';
  static const String regionPostsSubcollection = 'posts';
  static const String regionMembersSubcollection = 'members';

  // User Roles
  static const List<String> userRoles = [
    'fighter',
    'coach',
    'gym',
    'promoter',
    'sponsor',
    'fan',
    'admin',
  ];

  // Post Content Types (FightWire 2.0)
  static const List<String> postContentTypes = [
    'text',
    'photo',
    'video',
    'article',
    'promo',
  ];

  // Post Visibility
  static const List<String> postVisibilities = [
    'public',
    'regionOnly',
    'followersOnly',
  ];

  // Moderation Statuses
  static const List<String> moderationStatuses = [
    'pending',
    'approved',
    'rejected',
  ];

  // Comment Statuses
  static const List<String> commentStatuses = [
    'approved',
    'filtered',
    'removed',
  ];

  // Notification Types
  static const List<String> notificationTypes = [
    'newResponse',
    'newFollower',
    'eventUpdate',
  ];

  // Pink Shield Statuses (Gym safety tiers)
  static const List<String> pinkShieldStatuses = [
    'none',
    'standard',
    'vulnerable_safe',
    'trauma_informed',
  ];

  // Weight Classes (MMA)
  static const List<String> mmaWeightClasses = [
    'Light Flyweight',
    'Flyweight',
    'Bantamweight',
    'Featherweight',
    'Lightweight',
    'Welterweight',
    'Middleweight',
    'Light Heavyweight',
    'Heavyweight',
  ];

  // Weight Classes (Boxing)
  static const List<String> boxingWeightClasses = [
    'Minimumweight',
    'Light Flyweight',
    'Flyweight',
    'Super Flyweight',
    'Bantamweight',
    'Super Bantamweight',
    'Featherweight',
    'Super Featherweight',
    'Lightweight',
    'Super Lightweight',
    'Welterweight',
    'Super Welterweight',
    'Middleweight',
    'Super Middleweight',
    'Light Heavyweight',
    'Cruiserweight',
    'Heavyweight',
  ];

  // Combat Sports Types
  static const List<String> sportTypes = [
    'MMA',
    'Boxing',
    'Bare Knuckle',
    'BKFC',
    'Brawling',
    'Muay Thai',
    'Kickboxing',
    'Brazilian Jiu-Jitsu',
    'Wrestling',
    'Judo',
    'Karate',
    'Run It',
  ];

  // Gym Support / Safety Tags
  static const List<String> gymSupportTags = [
    'mentor_gold_diamond',
    'mentor_pink_diamond',
    'general_community_gym',
  ];

  static const List<String> gymSafetyFocusLevels = [
    'standard',
    'vulnerable_safe',
    'trauma_informed',
  ];

  // Fight Outcomes
  static const List<String> fightOutcomes = [
    'KO',
    'TKO',
    'Submission',
    'Decision - Unanimous',
    'Decision - Split',
    'Decision - Majority',
    'Draw',
    'No Contest',
    'DQ',
  ];

  // Verification Status
  static const List<String> verificationStatuses = [
    'pending',
    'verified',
    'rejected',
    'expired',
  ];

  // Post Types
  static const List<String> postTypes = [
    'text',
    'image',
    'video',
    'fight_update',
    'training_log',
    'announcement',
    'poll',
  ];

  // Consent Types
  static const List<String> consentTypes = [
    'analytics',
    'personalized_ads',
    'location_tracking',
    'health_data',
    'email_marketing',
    'push_notifications',
  ];

  // Disclaimers
  static const String educationalDisclaimer =
      'DataFightCentral provides data for educational and informational purposes only. '
      'Always consult professionals before making decisions based on this information.';

  static const String aiDisclaimer =
      'AI-generated insights are probabilistic and should be used as one of many '
      'factors in decision-making. Confidence scores indicate reliability estimates.';

  static const String healthDataDisclaimer =
      'Health data collection is optional and can be disabled at any time. '
      'This data is never shared without explicit consent and is encrypted at rest.';

  static const String fightStockDisclaimer =
      'Fight Stocks are engagement indices for educational visualization only. '
      'They are NOT financial instruments and have no monetary value.';

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxUsernameLength = 30;
  static const int minUsernameLength = 3;
  static const int maxBioLength = 500;
  static const int maxPostLength = 2000;
  static const int maxCommentLength = 500;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Durations (in seconds)
  static const int shortCacheDuration = 300; // 5 minutes
  static const int mediumCacheDuration = 1800; // 30 minutes
  static const int longCacheDuration = 86400; // 24 hours

  // Image Sizes
  static const int thumbnailSize = 150;
  static const int profileImageSize = 400;
  static const int coverImageSize = 1200;
  static const int maxUploadSizeMB = 10;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // API Endpoints (placeholders)
  static const String baseApiUrl = 'https://api.datafightcentral.com';
  static const String publicWebBaseUrl = 'https://datafightcentral.com';
  static const String publicRepositoryUrl =
      'https://github.com/DIRTYBOXING/Data-Fight-Central';
  static const String publicRepositoryIssuesUrl = '$publicRepositoryUrl/issues';
  static const String publicRepositoryContributingUrl =
      '$publicRepositoryUrl/blob/master/CONTRIBUTING.md';
  static const String sponsorProgramUrl =
      'https://github.com/sponsors/DIRTYBOXING';
  static const String launchPageContentUrl =
      '$publicRepositoryUrl/blob/master/docs/launch/DFC_PUBLIC_LAUNCH_PAGE.md';
  static const String sponsorTierMatrixUrl =
      '$publicRepositoryUrl/blob/master/docs/launch/DFC_SPONSOR_TIER_MATRIX.md';
  static const String sponsorPitchDeckUrl =
      '$publicRepositoryUrl/blob/master/docs/launch/DFC_SPONSOR_PITCH_DECK.md';
  static const String sponsorOutreachPackUrl =
      '$publicRepositoryUrl/blob/master/docs/launch/DFC_SPONSOR_OUTREACH_PACK.md';
  static const String grantApplicationPackUrl =
      '$publicRepositoryUrl/blob/master/docs/launch/DFC_GRANT_APPLICATION_PACK.md';
  static const String grantSubmissionCalendarUrl =
      '$publicRepositoryUrl/blob/master/docs/launch/DFC_GRANT_SUBMISSION_CALENDAR.md';
  static const String privacyPolicyUrl = '$publicWebBaseUrl/privacy';
  static const String termsOfServiceUrl = '$publicWebBaseUrl/terms';
  static const String supportEmail = 'support@datafightcentral.com';
  static const String infoEmail = 'info@datafightcentral.com';

  // External video platform keys — compile-time --dart-define takes priority,
  // then runtime dotenv (.env file), then empty (fallback/demo mode).
  static String get youtubeApiKey {
    const compileTime = String.fromEnvironment('YOUTUBE_API_KEY');
    if (compileTime.isNotEmpty) return compileTime;
    return _dotenvGet('YOUTUBE_API_KEY');
  }

  static String get streamApiKey {
    const compileTime = String.fromEnvironment('STREAM_API_KEY');
    if (compileTime.isNotEmpty) return compileTime;
    return _dotenvGet('STREAM_API_KEY');
  }

  static bool get hasYoutubeApiKey => youtubeApiKey.isNotEmpty;
  static bool get hasStreamApiKey => streamApiKey.isNotEmpty;

  static String get operatorFunctionUrl {
    const compileTime = String.fromEnvironment('DFC_OPERATOR_FUNCTION_URL');
    if (compileTime.isNotEmpty) return compileTime;
    return _dotenvGet('DFC_OPERATOR_FUNCTION_URL');
  }

  static String get operatorId {
    const compileTime = String.fromEnvironment('DFC_OPERATOR_ID');
    if (compileTime.isNotEmpty) return compileTime;
    return _dotenvGet('DFC_OPERATOR_ID');
  }

  static String get operatorSecret {
    const compileTime = String.fromEnvironment('DFC_OPERATOR_SECRET');
    if (compileTime.isNotEmpty) return compileTime;
    return _dotenvGet('DFC_OPERATOR_SECRET');
  }

  static String get ppvStorefrontBaseUrl {
    const compileTime = String.fromEnvironment('DFC_PPV_STOREFRONT_BASE');
    if (compileTime.isNotEmpty) return compileTime;
    return _dotenvGet('DFC_PPV_STOREFRONT_BASE');
  }

  static bool get ppvStorefrontAutoConfirmSandbox {
    const compileTime = String.fromEnvironment('DFC_PPV_AUTO_CONFIRM_SANDBOX');
    if (compileTime.isNotEmpty) {
      return compileTime.toLowerCase() == 'true';
    }
    return _dotenvGet('DFC_PPV_AUTO_CONFIRM_SANDBOX').toLowerCase() == 'true';
  }

  /// Safe dotenv accessor — returns empty string if dotenv wasn't loaded.
  static String _dotenvGet(String key) {
    try {
      final val = _dotenvEnv[key];
      return (val != null && val.isNotEmpty) ? val : '';
    } catch (_) {
      return '';
    }
  }

  static Map<String, String> get _dotenvEnv {
    try {
      // ignore: depend_on_referenced_packages
      return dotenv.env;
    } catch (_) {
      return const {};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  GLOBAL EXPANSION — Regional Platform Constants
  // ═══════════════════════════════════════════════════════════════

  /// Regions where DFC operates or plans to expand.
  static const List<String> expansionRegions = [
    'australia',
    'india',
    'pakistan',
    'kenya',
    'nigeria',
    'south_africa',
    'philippines',
    'thailand',
    'japan',
    'brazil',
    'uk',
    'usa',
    'new_zealand',
    'indonesia',
    'china',
  ];

  /// Regional social platforms for content distribution.
  static const Map<String, List<String>> regionalPlatforms = {
    'india': [
      'ShareChat',
      'Moj',
      'Josh',
      'Chingari',
      'Koo',
      'Roposo',
      'Sony LIV',
      'JioCinema',
      'Hotstar',
      'Star Sports',
      'FanCode',
    ],
    'pakistan': [
      'TikTok',
      'YouTube',
      'Facebook',
      'Instagram',
      'Telegram',
      'PTV Sports',
      'Ten Sports PK',
      'ARY Digital',
      'Geo Super',
      'Tapmad',
    ],
    'middle_east': [
      'MBC Action',
      'Abu Dhabi Sports',
      'beIN Sports',
      'Shahid',
      'StarzPlay',
      'YouTube',
      'Instagram',
      'TikTok',
    ],
    'southeast_asia': [
      'ONE App',
      'iQIYI',
      'TrueVisions',
      'Vidio',
      'Tap Go',
      'TikTok',
      'YouTube',
      'Facebook',
    ],
    'japan': ['ABEMA', 'U-NEXT', 'DAZN', 'YouTube', 'X', 'LINE'],
    'korea': ['TVING', 'YouTube', 'Instagram', 'TikTok'],
    'africa': [
      'WhatsApp',
      'Facebook',
      'Instagram',
      'TikTok',
      'Telegram',
      'YouTube',
      'SuperSport',
      'Showmax',
      'StarTimes',
    ],
    'latin_america': [
      'ESPN Deportes',
      'Star+',
      'Combate Global',
      'TV Azteca',
      'Globo',
      'YouTube',
      'TikTok',
      'Instagram',
    ],
    'europe': [
      'TNT Sports',
      'Sky Sports',
      'DAZN',
      'VIAPLAY',
      'Canal+',
      'RTL',
      'YouTube',
      'Instagram',
    ],
    'global': [
      'Meta',
      'YouTube',
      'TikTok',
      'Instagram',
      'X',
      'Telegram',
      'Signal',
    ],
  };

  /// Metaverse / immersive platforms.
  static const List<String> metaversePlatforms = [
    'Meta Horizon Worlds',
    'Roblox',
    'Decentraland',
    'The Sandbox',
    'VRChat',
    'WebXR',
  ];

  /// Supported localization languages for content distribution.
  static const List<String> expansionLanguages = [
    'en', // English
    'hi', // Hindi
    'pa', // Punjabi
    'ur', // Urdu
    'sw', // Swahili
    'pt', // Portuguese
    'ja', // Japanese
    'th', // Thai
    'tl', // Tagalog
    'id', // Indonesian
    'zh', // Chinese
    'ar', // Arabic
  ];

  /// Content format types for cross-platform distribution.
  static const List<String> contentFormats = [
    'short_video', // 15-60s — TikTok, Moj, Reels, Shorts
    'long_video', // 5-15min — YouTube, Facebook Watch
    'live_stream', // YouTube Live, Facebook Live, Twitch
    'interactive_xr', // WebXR / Roblox / Horizon immersive
    'community_post', // WhatsApp / Telegram / Facebook Groups
    'ar_activation', // Mobile AR filters and experiences
  ];

  /// WebXR teaser path (relative to web root).
  static const String webXrTeaserPath = '/webxr/';
}

class Fighter extends Equatable {
  final String id;
  final String name;
  final int wins;

  const Fighter({required this.id, required this.name, required this.wins});

  // Convert model to JSON (save to Firestore)
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'wins': wins};
  }

  // Convert JSON to model (read from Firestore)
  factory Fighter.fromMap(Map<String, dynamic> map) {
    return Fighter(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      wins: map['wins'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, wins];
}

class PerformanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Read fighter stats from Firestore
  Future<CombatStats> getFighterStats(String fighterId) async {
    final doc = await _firestore
        .collection('fighter_stats')
        .doc(fighterId)
        .get();

    if (!doc.exists) {
      throw Exception('Stats not found');
    }

    // Convert JSON to model using .fromMap()
    return CombatStats.fromMap(doc.data()!);
  }

  // Stream real-time stats
  Stream<CombatStats> streamFighterStats(String fighterId) {
    return _firestore
        .collection('fighter_stats')
        .doc(fighterId)
        .snapshots()
        .map((doc) => CombatStats.fromMap(doc.data()!));
  }
}

// Simple example screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<CombatStats> statsFuture;
  final performanceService = PerformanceService();

  @override
  void initState() {
    super.initState();
    // Fetch data in initState (NOT in build)
    statsFuture = performanceService.getFighterStats('current_user');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: FutureBuilder<CombatStats>(
        future: statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final stats = snapshot.data!;
          return ListView(
            children: [
              Text('Wins: ${stats.wins}'),
              Text('Losses: ${stats.losses}'),
              Text('KOs: ${stats.knockouts}'),
            ],
          );
        },
      ),
    );
  }
}
