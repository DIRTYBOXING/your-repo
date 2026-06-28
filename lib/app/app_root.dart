import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme.dart';

import '../app/app_router.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/dfc_themes.dart';
import '../shared/services/localization_service.dart';
import '../shared/services/cultural_calendar_service.dart';
import '../shared/services/gym_finder_service.dart';
import '../shared/services/auth_service.dart';
import '../shared/services/user_profile_service.dart';
import '../shared/services/app_audio_service.dart';
import '../shared/services/analytics_service.dart';
import '../shared/services/beast_mode_service.dart';
import '../shared/services/fighter_service.dart';
import '../shared/services/social_service.dart';
import '../shared/services/social_connector_service.dart';
import '../shared/services/group_service.dart';
import '../shared/services/short_video_service.dart';
import '../shared/services/event_service.dart';
import '../shared/services/events_service.dart';
import '../shared/services/performance_service.dart' as perf;
import '../shared/services/subscription_service.dart';
import '../shared/services/fight_news_service.dart';
import '../shared/services/meta_content_service.dart';
import '../shared/services/discovery_service.dart';
import '../shared/services/location_service.dart';
import '../shared/services/ai_coach_service.dart';
import '../shared/services/ai_eso_engine_service.dart';
import '../shared/services/content_scanner_engine.dart';
import '../shared/services/promoter_ai_service.dart';
import '../shared/services/dfc_ai_powerhouse.dart';
import '../shared/services/fight_camp_service.dart';
import '../shared/services/fight_notification_service.dart';
import '../shared/services/fight_marketplace_service.dart';
import '../shared/services/payments_service.dart';
import '../shared/services/health_data_service.dart';
import '../shared/services/badges_service.dart';
import '../shared/services/maps_service.dart';
import '../shared/services/smart_device_service.dart';
import '../shared/services/sports_science_engine.dart';
import '../shared/services/biometric_data_service.dart';
import '../shared/services/samurai_core_engine.dart';
import '../shared/services/samurai_swarm_coordinator.dart';
import '../shared/services/content_safety_service.dart';
import '../shared/services/identity_verification_service.dart';
import '../shared/services/fight_card_template_service.dart';
import '../shared/services/fight_matcher_service.dart';
import '../shared/services/daily_grind_service.dart';
import '../shared/services/body_monitor_service.dart';
import '../shared/services/ads_service.dart';
import '../shared/services/event_promo_card_service.dart';
// Enhanced Social Network Services
import '../shared/services/enhanced_friends_service.dart';
import '../shared/services/ecosystem_state_service.dart';
import '../shared/services/friend_suggestions_engine.dart';
import '../features/messaging/services/messaging_service.dart';
import '../features/settings/services/settings_service.dart';
import '../features/promoter/services/promoter_service.dart';
import '../shared/services/neural_mesh_engine.dart';
// PPV Services
import '../features/ppv/services/ppv_access_service.dart';
import '../features/ppv/services/ppv_notification_service.dart';
import '../features/ppv/services/judge_score_service.dart';
import '../features/ppv/services/fight_item_service.dart';
import '../shared/services/n8n_service.dart';
import '../shared/services/user_settings_service.dart';
import '../shared/services/account_recovery_service.dart';
import '../shared/services/login_history_service.dart';

const bool _featureProTheme = bool.fromEnvironment(
  'FEATURE_PRO_THEME',
);

class _RuntimeLaneBannerData {
  const _RuntimeLaneBannerData({
    required this.title,
    required this.message,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String title;
  final String message;
  final Color backgroundColor;
  final Color borderColor;
}

class DataFightCentralApp extends StatefulWidget {
  const DataFightCentralApp({super.key});

  @override
  State<DataFightCentralApp> createState() => _DataFightCentralAppState();
}

class _DataFightCentralAppState extends State<DataFightCentralApp> {
  GoRouter? _router;

  _RuntimeLaneBannerData? _runtimeLaneBannerData(AuthService authService) {
    if (authService.isEmergencyLocalSession) {
      return const _RuntimeLaneBannerData(
        title: 'LOCAL RECOVERY SESSION',
        message:
            'Temporary local profile. Changes may not sync to live Firebase.',
        backgroundColor: Color(0xCC4A1010),
        borderColor: Color(0xFFFF6B6B),
      );
    }

    if (AppConstants.webDemoMode && AppConstants.useFirebaseEmulator) {
      return const _RuntimeLaneBannerData(
        title: 'SANDBOX: DEMO + EMULATOR',
        message:
            'Safe local repair lane. Demo shell backed by localhost Firebase.',
        backgroundColor: Color(0xCC08334A),
        borderColor: Color(0xFF18D7FF),
      );
    }

    if (AppConstants.useFirebaseEmulator) {
      return const _RuntimeLaneBannerData(
        title: 'LOCAL EMULATOR',
        message:
            'Real app flows against localhost Firebase. No live production data.',
        backgroundColor: Color(0xCC0F2C1E),
        borderColor: Color(0xFF3DDC97),
      );
    }

    if (AppConstants.webDemoMode || AppConstants.guestMode) {
      return const _RuntimeLaneBannerData(
        title: 'DEMO PREVIEW',
        message:
            'Auth is limited and seeded demo data may appear. Not the live platform lane.',
        backgroundColor: Color(0xCC4A3210),
        borderColor: Color(0xFFFFC857),
      );
    }

    if (!kDebugMode) {
      return null;
    }

    return const _RuntimeLaneBannerData(
      title: 'LIVE FIREBASE',
      message: 'Real auth, real backend, and live data path.',
      backgroundColor: Color(0xCC102414),
      borderColor: Color(0xFF5EEA88),
    );
  }

  bool _shouldHideRuntimeLaneBanner() {
    final path = _router?.routeInformationProvider.value.uri.path ?? '';
    const hiddenPrefixes = [
      '/landing',
      '/login',
      '/register',
      '/forgot-password',
    ];

    return hiddenPrefixes.any(
      (prefix) => path == prefix || path.startsWith('$prefix/'),
    );
  }

  Widget _buildRuntimeLaneBanner(AuthService authService) {
    if (_shouldHideRuntimeLaneBanner()) {
      return const SizedBox.shrink();
    }

    final bannerData = _runtimeLaneBannerData(authService);
    if (bannerData == null) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 760),
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bannerData.backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: bannerData.borderColor, width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bannerData.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bannerData.message,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Auth & Analytics (core) ─────────────────────────────
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => UserProfileService()),
        ChangeNotifierProvider(
          create: (_) {
            final service = AppAudioService();
            service.initialize().catchError(
              (e) => debugPrint('AppAudio init failed: $e'),
            );
            return service;
          },
        ),
        Provider(create: (_) => AnalyticsService()),
        ChangeNotifierProvider(create: (_) => BeastModeService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),

        // ── Plain services ──────────────────────────────────────
        Provider(create: (_) => FighterService()),
        Provider(create: (_) => SocialService()),
        ChangeNotifierProvider(create: (_) => SocialConnectorService()),
        ChangeNotifierProvider(create: (_) => GroupService()),
        ChangeNotifierProvider(create: (_) => ShortVideoService()),
        Provider(create: (_) => EventService()),
        Provider(create: (_) => EventsService()),
        Provider(create: (_) => perf.PerformanceService()),
        Provider(create: (_) => SubscriptionService()),
        Provider(create: (_) => FightNewsService()),
        Provider(create: (_) => MetaContentService()),
        Provider(create: (_) => DiscoveryService()),
        ChangeNotifierProvider(create: (_) => AdsService()),
        ChangeNotifierProvider(create: (_) => MessagingService()),
        // Enhanced Social Network Services
        ChangeNotifierProvider(create: (_) => EnhancedFriendsService()),
        Provider(create: (_) => FriendSuggestionsEngine()),
        Provider(create: (_) => LocationService()),
        Provider(create: (_) => FightMarketplaceService()),
        Provider(create: (_) => PromoterService()),

        // ── ChangeNotifier services ─────────────────────────────
        ChangeNotifierProvider(create: (_) => AICoachService()),
        ChangeNotifierProvider(create: (_) => AIEsoEngineService()),
        ChangeNotifierProvider(create: (_) => ContentScannerEngine()),
        ChangeNotifierProvider(create: (_) => PromoterAIService()),
        ChangeNotifierProvider(create: (_) => DFCAIPowerhouse()),
        ChangeNotifierProvider(create: (_) => FightCampService()),
        ChangeNotifierProvider(create: (_) => FightNotificationService()),
        ChangeNotifierProvider(create: (_) => PaymentsService()),
        ChangeNotifierProvider(create: (_) => HealthDataService()),
        ChangeNotifierProvider(create: (_) => BadgesService()),
        ChangeNotifierProvider(create: (_) => MapsService()),
        ChangeNotifierProvider(
          create: (_) {
            final s = SmartDeviceService();
            s.initialize().catchError(
              (e) => debugPrint('SmartDevice init failed: $e'),
            );
            return s;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final s = SportsScienceEngine();
            s.initialize().catchError(
              (e) => debugPrint('SportsSci init failed: $e'),
            );
            return s;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final s = SamuraiCoreEngine();
            s.initialize().catchError(
              (e) => debugPrint('Samurai init failed: $e'),
            );
            return s;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final bioService = BiometricDataService();
            try {
              final smartDevice = context.read<SmartDeviceService>();
              final sportsSci = context.read<SportsScienceEngine>();
              bioService
                  .initialize(smartDevice, sportsSci)
                  .catchError((e) => debugPrint('Bio init failed: $e'));
            } catch (e) {
              debugPrint('BiometricData provider read failed: $e');
            }
            return bioService;
          },
        ),
        ChangeNotifierProvider(create: (_) => ContentSafetyService()),
        ChangeNotifierProvider(create: (_) => IdentityVerificationService()),
        ChangeNotifierProvider(create: (_) => FightCardTemplateService()),
        ChangeNotifierProvider(create: (_) => FightMatcherService()),
        ChangeNotifierProvider(create: (_) => DailyGrindService()),
        ChangeNotifierProvider(create: (_) => BodyMonitorService()),
        ChangeNotifierProvider(create: (_) => EventPromoCardService()),
        ChangeNotifierProvider(
          create: (_) {
            final s = SamuraiSwarmCoordinator();
            s.bootSwarm().catchError(
              (e) => debugPrint('Swarm boot failed: \$e'),
            );
            return s;
          },
        ),
        // ── Neural Mesh Engine (PSYCHE, SCALES, SHIELD, FUEL) ─
        ChangeNotifierProvider(
          create: (_) {
            final s = NeuralMeshEngine();
            s.initialize().catchError(
              (e) => debugPrint('NeuralMesh init failed: $e'),
            );
            return s;
          },
        ),
        // ── Ecosystem & Market Intelligence ───────────────────
        ChangeNotifierProvider(create: (_) => EcosystemStateService()),
        // ── Localization & Cultural Awareness ─────────────────
        ChangeNotifierProvider(
          create: (_) {
            final s = LocalizationService();
            s.initialize().catchError(
              (e) => debugPrint('Localization init failed: $e'),
            );
            return s;
          },
        ),
        ChangeNotifierProvider(create: (_) => CulturalCalendarService()),
        ChangeNotifierProvider(create: (_) => GymFinderService()),

        // ── PPV & Fight Commerce ──────────────────────────────
        Provider(create: (_) => PPVService()),
        ChangeNotifierProvider(create: (_) => PPVPaymentService()),
        Provider(create: (_) => PPVAccessService()),
        Provider(
          create: (_) {
            final s = PPVNotificationService();
            s.initialize().catchError(
              (e) => debugPrint('PPVNotification init failed: $e'),
            );
            return s;
          },
        ),
        Provider(create: (_) => JudgeScoreService()),
        Provider(create: (_) => FightItemService()),
        Provider(create: (_) => N8nService()),
        // ── User Settings Backend (Firestore-backed) ─────────
        ChangeNotifierProvider(create: (_) => UserSettingsService()),
        ChangeNotifierProvider(create: (_) => AccountRecoveryService()),
        ChangeNotifierProvider(create: (_) => LoginHistoryService()),
        // Provider(create: (_) => HydrationService()), // Removed: HydrationService not defined
      ],
      child: Builder(
        builder: (context) {
          // Create the router exactly once, GoRouter.refreshListenable
          // handles auth-state redirect re-evaluation automatically.
          // GOOGLE INTEGRATION NOTICE:
          // This app relies on Google services (Firebase, Google Fit, etc.) for core functionality, health, and user experience.
          // Ensure all Google integrations are active and healthy. App health and user safety depend on it.
          // If Google integration fails, surface errors clearly and notify the user.
          _router ??= AppRouter.getRouter(context);

          // Watch the theme mode from SettingsService
          final settings = context.watch<SettingsService>();
          final theme = _featureProTheme
              ? appTheme()
              : DFCThemes.forMode(settings.themeMode);

          // Watch localization for RTL and locale changes
          final localization = context.watch<LocalizationService>();
          final currentLocale = Locale(localization.currentLocale);

          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: theme,
            routerConfig: _router,
            builder: (context, child) {
              final authService = context.watch<AuthService>();

              return Stack(
                children: [
                  Positioned.fill(child: child ?? const SizedBox.shrink()),
                  _buildRuntimeLaneBanner(authService),
                ],
              );
            },
            locale: currentLocale,
            supportedLocales: LocalizationService.supportedLocales
                .map((l) => Locale(l.code))
                .toList(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
