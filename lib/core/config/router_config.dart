
import 'package:go_router/go_router.dart';

import '../../features/coach/screens/admin_console_screen.dart';
import '../../features/promoter/screens/economy_control_room_screen.dart';
import '../../features/admin/screens/google_ecosystem_hub_screen.dart';
import '../../features/legacy_root/performance_lab_screen.dart';
import '../../features/astrohealth/screens/neural_coach_dashboard_screen.dart';
import '../../features/astrohealth/screens/fighter_wellness_journal_screen.dart';
import '../../features/coach/screens/login_onboarding_screen.dart';
import '../../features/promoter/screens/broadcast_overlay_screen.dart';
import '../../features/coach/screens/website_home_screen.dart';
import '../../features/creative_hub/screens/creative_hub_screen.dart';
import '../../features/devices/screens/device_hub_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/fempower/screens/only_fit_portal_screen.dart';
import '../../features/gyms/screens/gym_directory_map_screen.dart';
import '../../features/sponsorships/screens/google_nvidia_landing_screen.dart';
import '../../features/ppv/screens/ppv_explore_screen.dart';
import '../../features/ppv/screens/ppv_door_sales_screen.dart';
import '../../features/legacy_root/stripe_connect_onboarding_screen.dart';
import '../../shared/widgets/gym_team_hub_screen.dart';
import '../../core/config/medical_safety_screen.dart';
import '../../features/promoter/screens/officials_tablet_screen.dart';
import '../../features/ppv/services/ppv_detail_screen.dart';
import '../../features/ppv/services/ppv_storefront_screen.dart';
import '../../features/ppv/services/ppv_streaming_screen.dart';
import '../../features/profile/screens/fighter_public_profile_screen.dart';
import '../../features/fighter/screens/fighter_profile_screen.dart';
import '../../features/gym/screens/gym_profile_screen.dart';
import '../../features/profile/screens/profile_screen_v2.dart';
import '../../features/promoter/screens/promoter_dashboard_screen.dart';
import '../../features/promoter/screens/promoter_control_room_screen.dart';
import '../../features/social/fight_wire_post_screen.dart';
import '../../features/social/screens/create_group_screen.dart';
import '../../features/social/screens/create_story_screen.dart';
import '../../features/social/screens/cross_platform_publish_screen.dart';
import '../../features/social/screens/group_detail_screen.dart';
import '../../features/social/screens/story_viewer_screen.dart';
import '../../features/social/screens/upload_reel_screen.dart';
import '../../features/legacy_root/sponsorship_system_screen.dart';
import '../../features/fight_card/screens/fight_card_builder_screen.dart';
import '../../features/spotlight/screens/whos_who_screen.dart';
import '../../features/creator/screens/showmaker_profile_screen.dart';
import '../../shared/widgets/coming_soon_screen.dart';
import '../../features/wallet/screens/digital_wallet_screen.dart';
import '../../features/revenue/screens/commercial_revenue_dashboard_screen.dart';
import '../../features/shakura/screens/shakura_guardian_screen.dart';
import '../../features/ppv/screens/ppv_checkout_screen.dart';
import 'gym_economy_dashboard.dart';
import 'promoter_economy_dashboard.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // Main Hub
      GoRoute(
        path: '/',
        builder: (context, state) => const WebsiteHomeScreen(),
      ),

      // Auth & Onboarding
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginOnboardingScreen(),
      ),

      // Coach & Training
      GoRoute(
        path: '/neural-coach',
        builder: (context, state) => const NeuralCoachDashboardScreen(),
      ),
      GoRoute(
        path: '/corner-coach',
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Corner Coach'),
      ),
      GoRoute(
        path: '/training-session',
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Training Session'),
      ),
      GoRoute(
        path: '/fight-summary',
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Fight Summary'),
      ),

      // Devices & Biometrics
      GoRoute(
        path: '/devices',
        builder: (context, state) => const DeviceHubScreen(),
      ),
      GoRoute(
        path: '/astrohealth',
        builder: (context, state) => const NeuralCoachDashboardScreen(),
      ),
      GoRoute(
        path: '/fighter-wellness',
        builder: (context, state) => const FighterWellnessJournalScreen(),
      ),

      // Analytics & History
      GoRoute(
        path: '/performance-lab',
        builder: (context, state) => const PerformanceLabScreen(),
      ),
      GoRoute(
        path: '/fight-history',
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Fight History'),
      ),

      // Identity & Social
      GoRoute(
        path: '/fighter-profile',
        builder: (context, state) => const FighterProfileScreen(),
      ),
      GoRoute(
        path: '/gym-profile',
        builder: (context, state) => const GymProfileScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/public-profile',
        builder: (context, state) => const FighterPublicProfileScreen(),
      ),
      GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),

      // Gyms & Teams
      GoRoute(
        path: '/coach-hub',
        builder: (context, state) => const ComingSoonScreen(title: 'Coach Hub'),
      ),
      GoRoute(
        path: '/gym-hub',
        builder: (context, state) => const GymTeamHubScreen(),
      ),
      GoRoute(
        path: '/gym-map',
        builder: (context, state) => const GymDirectoryMapScreen(),
      ),
      GoRoute(
        path: '/sponsorship-landing',
        builder: (context, state) => const GoogleNvidiaLandingScreen(),
      ),
      GoRoute(
        path: '/ppv-explore',
        builder: (context, state) => const PpvExploreScreen(),
      ),
      GoRoute(
        path: '/door-sales/:eventId',
        builder: (context, state) => PpvDoorSalesScreen(
          eventId: state.pathParameters['eventId'] ?? 'demo_event',
        ),
      ),

      // Events & Streaming
      GoRoute(
        path: '/event-center',
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Event Center'),
      ),
      GoRoute(
        path: '/streaming',
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Streaming Center'),
      ),
      GoRoute(
        path: '/ppv',
        builder: (context, state) => const PpvStorefrontScreen(),
      ),
      GoRoute(
        path: '/ppv-detail/:eventId',
        builder: (context, state) =>
            PpvDetailScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/ppv-stream/:eventId',
        builder: (context, state) =>
            PpvStreamingScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/replay',
        builder: (context, state) => const ComingSoonScreen(title: 'Replay Center'),
      ),
      GoRoute(
        path: '/broadcast/:eventId',
        builder: (context, state) =>
            BroadcastOverlayScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/shakura',
        builder: (context, state) => const ShakuraGuardianScreen(),
      ),
      GoRoute(
        path: '/ppv-checkout/:eventId',
        builder: (context, state) => PpvCheckoutScreen(
          eventId: state.pathParameters['eventId']!,
          eventTitle: state.uri.queryParameters['title'] ?? 'Live Event',
          muxPlaybackId: state.uri.queryParameters['playbackId'] ?? '',
        ),
      ),

      // Promoter & Operations
      GoRoute(
        path: '/promoter',
        builder: (context, state) => const PromoterControlRoomScreen(),
      ),
      GoRoute(
        path: '/card-builder',
        builder: (context, state) => const FightCardBuilderScreen(),
      ),
      GoRoute(
        path: '/venue-ops',
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Venue Operations'),
      ),

      // Regulatory & Back Office
      GoRoute(
        path: '/officials',
        builder: (context, state) => const OfficialsTabletScreen(),
      ),
      GoRoute(
        path: '/medical',
        builder: (context, state) => const MedicalSafetyScreen(),
      ),
      GoRoute(
        path: '/legal',
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Contracts & Legal'),
      ),
      GoRoute(
        path: '/finance',
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Payouts & Finance'),
      ),
      GoRoute(
        path: '/sponsors',
        builder: (context, state) => const SponsorshipSystemScreen(),
      ),

      // Admin
      GoRoute(
        path: '/google-hub',
        builder: (context, state) => const GoogleEcosystemHubScreen(),
      ),
      GoRoute(
        path: '/admin-console',
        builder: (context, state) => const AdminConsoleScreen(),
      ),
      GoRoute(
        path: '/economy-control-room',
        builder: (context, state) => const EconomyControlRoomScreen(),
      ),
      GoRoute(
        path: '/finance/onboarding',
        builder: (context, state) => const StripeConnectOnboardingScreen(),
      ),

      // Economy & Finances
      GoRoute(
        path: '/commercial-revenue',
        builder: (context, state) => const CommercialRevenueDashboardScreen(),
      ),
      GoRoute(
        path: '/digital-wallet',
        builder: (context, state) => const DigitalWalletScreen(),
      ),
      GoRoute(
        path: '/finance/promoter/:id',
        builder: (context, state) =>
            PromoterEconomyDashboard(promoterId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/finance/fighter/:id',
        builder: (context, state) =>
            FighterEconomyDashboard(fighterId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/finance/gym/:id',
        builder: (context, state) =>
            GymEconomyDashboard(gymId: state.pathParameters['id']!),
      ),

      // Content & Marketing
      GoRoute(
        path: '/creative-hub',
        builder: (context, state) => const CreativeHubScreen(),
      ),

      // OnlyFit Portal
      GoRoute(
        path: '/only-fit',
        builder: (context, state) => const OnlyFitPortalScreen(),
      ),

      GoRoute(
        path: '/whos-who',
        builder: (context, state) => const WhosWhoScreen(),
      ),
      GoRoute(
        path: '/creator/:id',
        builder: (context, state) => ShowmakerProfileScreen(
          creatorId: state.pathParameters['id']!,
        ),
      ),
      // Social module
      GoRoute(
        path: RouterConfig.createGroupPath,
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: RouterConfig.groupDetailPath,
        builder: (context, state) => GroupDetailScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: RouterConfig.uploadReelPath,
        builder: (context, state) => const UploadReelScreen(),
      ),
      GoRoute(
        path: RouterConfig.crossPlatformPublishPath,
        builder: (context, state) => const CrossPlatformPublishScreen(),
      ),
      GoRoute(
        path: RouterConfig.createStoryPath,
        builder: (context, state) => const CreateStoryScreen(),
      ),
      GoRoute(
        path: RouterConfig.storyViewerPath,
        builder: (context, state) => StoryViewerScreen(
          category: state.uri.queryParameters['category'] ?? 'EVENTS',
        ),
      ),
      GoRoute(
        path: RouterConfig.fightWirePath,
        builder: (context, state) => const FightWirePostScreen(),
      ),
    ],
  );
}

/// Named route-path constants for screens that are pushed by string path
/// (via `context.push`) rather than referenced directly, so callers don't
/// have to hardcode raw path strings.
class RouterConfig {
  RouterConfig._();

  static const String createGroupPath = '/create-group';
  static const String groupDetailPath = '/group/:groupId';
  static const String uploadReelPath = '/upload-reel';
  static const String crossPlatformPublishPath = '/cross-platform-publish';
  static const String createStoryPath = '/create-story';
  static const String storyViewerPath = '/story-viewer';
  static const String fightWirePath = '/fight-wire';

  // NOTE: the following three are referenced by find_friends_screen.dart's
  // promo quick-actions but have no corresponding screen/route implemented
  // yet. Kept as placeholders so the file compiles; wire up real
  // destinations before shipping this UI.
  static const String socialQueuePath = '/social-queue';
  static const String eventPromotionPath = '/event-promotion';
  static const String socialMediaToolkitPath = '/social-media-toolkit';
}
