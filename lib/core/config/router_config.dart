import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/screens/admin_console_screen.dart';
import '../config/economy_control_room_screen.dart';
import '../../features/admin/screens/google_ecosystem_hub_screen.dart';
import '../../features/analytics/screens/performance_lab_screen.dart';
import '../../features/astrohealth/screens/astro_health_monitor_screen.dart';
import '../../features/auth/screens/login_onboarding_screen.dart';
import '../../features/broadcast/screens/broadcast_overlay_screen.dart';
import '../../features/coach/screens/coach_hub_screen.dart';
import '../../features/coach/screens/corner_coach_screen.dart';
import '../../features/coach/screens/neural_coach_screen.dart';
import '../../features/coach/screens/website_home_screen.dart';
import '../../features/creative/screens/creative_hub_screen.dart';
import '../../features/devices/screens/device_hub_screen.dart';
import '../../features/events/screens/event_center_screen.dart';
import '../../features/events/screens/fight_card_builder_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/fempower/screens/only_fit_portal_screen.dart';
import '../../features/finance/screens/payouts_finance_screen.dart';
import '../../features/finance/screens/stripe_connect_onboarding_screen.dart';
import '../../features/gym/screens/gym_team_hub_screen.dart';
import '../../features/history/screens/fight_history_screen.dart';
// Import your screens here (adjust paths if your folder structure differs slightly)
import '../../features/home/screens/home_screen.dart';
import '../../features/legal/screens/contracts_legal_screen.dart';
import '../../features/medical/screens/medical_safety_screen.dart';
import '../../features/officials/screens/officials_tablet_screen.dart';
import '../../features/ppv/screens/ppv_detail_screen.dart';
import '../../features/ppv/screens/ppv_storefront_screen.dart';
import '../../features/ppv/screens/ppv_streaming_screen.dart';
import '../../features/profile/screens/fighter_public_profile_screen.dart';
import '../../features/profile/screens/profile_screen_v2.dart';
import '../../features/promoter/screens/promoter_dashboard_screen.dart';
import '../../features/replay/screens/replay_center_screen.dart';
import '../../features/sponsors/screens/sponsorship_system_screen.dart';
import '../../features/streaming/screens/streaming_center_screen.dart';
import '../../features/training/screens/fight_summary_screen.dart';
import '../../features/training/screens/training_session_screen.dart';
import '../../features/venue/screens/venue_operations_screen.dart';
import 'fighter_economy_dashboard.dart';
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
        builder: (context, state) => const NeuralCoachScreen(),
      ),
      GoRoute(
        path: '/corner-coach',
        builder: (context, state) => const CornerCoachScreen(),
      ),
      GoRoute(
        path: '/training-session',
        builder: (context, state) => const TrainingSessionScreen(),
      ),
      GoRoute(
        path: '/fight-summary',
        builder: (context, state) => const FightSummaryScreen(),
      ),

      // Devices & Biometrics
      GoRoute(
        path: '/devices',
        builder: (context, state) => const DeviceHubScreen(),
      ),
      GoRoute(
        path: '/astrohealth',
        builder: (context, state) => const AstroHealthMonitorScreen(),
      ),

      // Analytics & History
      GoRoute(
        path: '/performance-lab',
        builder: (context, state) => const PerformanceLabScreen(),
      ),
      GoRoute(
        path: '/fight-history',
        builder: (context, state) => const FightHistoryScreen(),
      ),

      // Identity & Social
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
        builder: (context, state) => const CoachHubScreen(),
      ),
      GoRoute(
        path: '/gym-hub',
        builder: (context, state) => const GymTeamHubScreen(),
      ),

      // Events & Streaming
      GoRoute(
        path: '/event-center',
        builder: (context, state) => const EventCenterScreen(),
      ),
      GoRoute(
        path: '/streaming',
        builder: (context, state) => const StreamingCenterScreen(),
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
        builder: (context, state) => const ReplayCenterScreen(),
      ),
      GoRoute(
        path: '/broadcast',
        builder: (context, state) => const BroadcastOverlayScreen(),
      ),

      // Promoter & Operations
      GoRoute(
        path: '/promoter',
        builder: (context, state) => const PromoterDashboardScreen(),
      ),
      GoRoute(
        path: '/card-builder',
        builder: (context, state) => const FightCardBuilderScreen(),
      ),
      GoRoute(
        path: '/venue-ops',
        builder: (context, state) => const VenueOperationsScreen(),
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
        builder: (context, state) => const ContractsLegalScreen(),
      ),
      GoRoute(
        path: '/finance',
        builder: (context, state) => const PayoutsFinanceScreen(),
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
    ],
  );
}
