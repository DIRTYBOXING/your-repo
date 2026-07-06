import 'package:flutter/material.dart' hide RouterConfig;
import 'package:go_router/go_router.dart';
import 'router_constants.dart';
export 'router_constants.dart';

// ── Screens that exist at confirmed paths ─────────────────────────────────────
import '../../features/home/screens/home_screen.dart';
import '../../features/coach/screens/website_home_screen.dart';
import '../../features/coach/screens/neural_coach_screen.dart';
import '../../features/coach/screens/login_onboarding_screen.dart';
import '../../features/coach/screens/admin_console_screen.dart';
import '../../features/devices/screens/device_hub_screen.dart';
import '../../features/profile/screens/profile_screen_v2.dart';
import '../../features/profile/screens/fighter_public_profile_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../shared/widgets/gym_team_hub_screen.dart';
import '../../features/ppv/services/ppv_storefront_screen.dart';
import '../../features/ppv/services/ppv_detail_screen.dart';
import '../../features/ppv/services/ppv_streaming_screen.dart';
import '../../features/ppv/screens/promoter_dashboard_screen.dart';
import '../../features/promoter/screens/broadcast_overlay_screen.dart';
import '../../features/promoter/screens/economy_control_room_screen.dart';
import '../../features/promoter/screens/officials_tablet_screen.dart';
import '../../features/fight_card/screens/fight_card_builder_screen.dart';
import '../../features/astrohealth/screens/astro_health_monitor_screen.dart';
import '../../features/admin/screens/google_ecosystem_hub_screen.dart';
import '../../features/creative_hub/screens/creative_hub_screen.dart';
import 'promoter_economy_dashboard.dart';
import 'fighter_economy_dashboard.dart';
import 'gym_economy_dashboard.dart';
import 'medical_safety_screen.dart';
// ── Partnership landing pages ─────────────────────────────────────────────────
import '../../features/partnership/screens/google_partnership_screen.dart';
import '../../features/partnership/screens/nvidia_partnership_screen.dart';
import '../../features/partnership/screens/github_partnership_screen.dart';
// ── TikeRocket ────────────────────────────────────────────────────────────────
import '../../features/passes/screens/tikerocket_screen.dart';

// ── Stub for routes whose screens are not yet built ───────────────────────────
class _ComingSoon extends StatelessWidget {
  final String title;
  const _ComingSoon(this.title);
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050A14),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0A1628),
      foregroundColor: const Color(0xFF00E5FF),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    ),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction, color: Color(0xFF00E5FF), size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Module coming soon',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    ),
  );
}

class AppRouter {
  static final router = GoRouter(
    initialLocation: RouteConstants.root,
    routes: [
      // ── Root ────────────────────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.root,
        builder: (context, state) => const WebsiteHomeScreen(),
      ),

      // ── Auth ─────────────────────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginOnboardingScreen(),
      ),

      // ── Home shell ───────────────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.home,
        builder: (context, state) => const HomeScreen(),
      ),

      // ── Coach & Training ─────────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.neuralCoachPath,
        builder: (context, state) => const NeuralCoachScreen(),
      ),
      GoRoute(
        path: RouteConstants.cornerCoachPath,
        builder: (context, state) => const _ComingSoon('Corner Coach'),
      ),
      GoRoute(
        path: RouteConstants.trainingSessionPath,
        builder: (context, state) => const _ComingSoon('Training Session'),
      ),
      GoRoute(
        path: RouteConstants.fightSummaryPath,
        builder: (context, state) => const _ComingSoon('Fight Summary'),
      ),

      // ── Devices & Biometrics ─────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.deviceHubPath,
        builder: (context, state) => const DeviceHubScreen(),
      ),
      GoRoute(
        path: RouteConstants.astroHealthPath,
        builder: (context, state) => const AstroHealthMonitorScreen(),
      ),

      // ── Analytics & History ──────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.performanceLabPath,
        builder: (context, state) => const _ComingSoon('Performance Lab'),
      ),
      GoRoute(
        path: RouteConstants.fightHistoryPath,
        builder: (context, state) => const _ComingSoon('Fight History'),
      ),

      // ── Identity & Social ────────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.profilePath,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteConstants.publicProfilePath,
        builder: (context, state) => const FighterPublicProfileScreen(),
      ),
      GoRoute(
        path: RouteConstants.feedPath,
        builder: (context, state) => const FeedScreen(),
      ),

      // ── Gyms & Teams ─────────────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.coachHubPath,
        builder: (context, state) => const _ComingSoon('Coach Hub'),
      ),
      GoRoute(
        path: RouteConstants.gymHubPath,
        builder: (context, state) => const GymTeamHubScreen(),
      ),

      // ── Events & Streaming ───────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.eventCenterPath,
        builder: (context, state) => const _ComingSoon('Event Center'),
      ),
      GoRoute(
        path: RouteConstants.streamingPath,
        builder: (context, state) => const _ComingSoon('Streaming Center'),
      ),
      GoRoute(
        path: RouteConstants.ppvHub,
        builder: (context, state) => const PpvStorefrontScreen(),
      ),
      GoRoute(
        path: RouteConstants.ppvDetailByEventId,
        builder: (context, state) =>
            PpvDetailScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: RouteConstants.ppvStreamByEventId,
        builder: (context, state) =>
            PpvStreamingScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: RouteConstants.replayPath,
        builder: (context, state) => const _ComingSoon('Replay Center'),
      ),
      GoRoute(
        path: RouteConstants.broadcastPath,
        builder: (context, state) =>
            const BroadcastOverlayScreen(eventId: 'live'),
      ),

      // ── Promoter & Operations ────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.promoterPath,
        builder: (context, state) => const PromoterDashboardScreen(),
      ),
      GoRoute(
        path: RouteConstants.cardBuilderPath,
        builder: (context, state) => const FightCardBuilderScreen(),
      ),
      GoRoute(
        path: RouteConstants.venueOpsPath,
        builder: (context, state) => const _ComingSoon('Venue Operations'),
      ),

      // ── Regulatory & Back Office ─────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.officialsPath,
        builder: (context, state) => const OfficialsTabletScreen(),
      ),
      GoRoute(
        path: RouteConstants.medicalPath,
        builder: (context, state) => const MedicalSafetyScreen(),
      ),
      GoRoute(
        path: RouteConstants.legalPath,
        builder: (context, state) => const _ComingSoon('Contracts & Legal'),
      ),
      GoRoute(
        path: RouteConstants.financePath,
        builder: (context, state) => const _ComingSoon('Payouts & Finance'),
      ),
      GoRoute(
        path: RouteConstants.sponsorsPath,
        builder: (context, state) => const _ComingSoon('Sponsorship'),
      ),

      // ── Admin ────────────────────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.googleHubPath,
        builder: (context, state) => const GoogleEcosystemHubScreen(),
      ),
      GoRoute(
        path: RouteConstants.adminConsolePath,
        builder: (context, state) => const AdminConsoleScreen(),
      ),
      GoRoute(
        path: RouteConstants.economyControlPath,
        builder: (context, state) => const EconomyControlRoomScreen(),
      ),
      GoRoute(
        path: RouteConstants.financeOnboardingPath,
        builder: (context, state) =>
            const _ComingSoon('Stripe Connect Onboarding'),
      ),

      // ── Economy dashboards ───────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.financePromoterById,
        builder: (context, state) =>
            PromoterEconomyDashboard(promoterId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteConstants.financeFighterById,
        builder: (context, state) =>
            FighterEconomyDashboard(fighterId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteConstants.financeGymById,
        builder: (context, state) =>
            GymEconomyDashboard(gymId: state.pathParameters['id']!),
      ),

      // ── Content & Marketing ──────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.creativeHub,
        builder: (context, state) => const CreativeHubScreen(),
      ),

      // ── TikeRocket ────────────────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.tikeRocket,
        builder: (context, state) => TikeRocketScreen(
          userId: state.uri.queryParameters['userId'] ?? 'guest',
          userName: state.uri.queryParameters['userName'] ?? 'Fighter Fan',
        ),
      ),

      // ── Partnership Landing Pages ─────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.googlePartnerPath,
        builder: (context, state) => const GooglePartnershipScreen(),
      ),
      GoRoute(
        path: RouteConstants.nvidiaPartnerPath,
        builder: (context, state) => const NvidiaPartnershipScreen(),
      ),
      GoRoute(
        path: RouteConstants.githubPartnerPath,
        builder: (context, state) => const GithubPartnershipScreen(),
      ),
    ],
  );
}
