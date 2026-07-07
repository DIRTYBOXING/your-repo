import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
export 'router_constants.dart';

// ── Screens that exist at confirmed paths ─────────────────────────────────────
import '../../features/training/screens/training_master_screen.dart';
import '../../features/events/screens/events_screen.dart';
import '../../features/events/screens/ticket_purchase_screen.dart';
import '../../features/ppv/screens/ppv_library_screen.dart'
    show PPVLibraryScreen;
import '../../features/rankings/screens/fighter_rankings_screen.dart';
import '../../features/maps/screens/find_a_gym_screen.dart';
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
    initialLocation: '/',
    routes: [
      // ── Root ────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const WebsiteHomeScreen(),
      ),

      // ── Auth ─────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginOnboardingScreen(),
      ),

      // ── Home shell ───────────────────────────────────────────────────────────
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

      // ── Coach & Training ─────────────────────────────────────────────────────
      GoRoute(
        path: '/neural-coach',
        builder: (context, state) => const NeuralCoachScreen(),
      ),
      GoRoute(
        path: '/corner-coach',
        builder: (context, state) => const _ComingSoon('Corner Coach'),
      ),
      GoRoute(
        path: '/training-session',
        builder: (context, state) => const TrainingMasterScreen(),
      ),
      GoRoute(
        path: '/fight-summary',
        builder: (context, state) => const _ComingSoon('Fight Summary'),
      ),

      // ── Devices & Biometrics ─────────────────────────────────────────────────
      GoRoute(
        path: '/devices',
        builder: (context, state) => const DeviceHubScreen(),
      ),
      GoRoute(
        path: '/astrohealth',
        builder: (context, state) => const AstroHealthMonitorScreen(),
      ),

      // ── Analytics & History ──────────────────────────────────────────────────
      GoRoute(
        path: '/performance-lab',
        builder: (context, state) => const _ComingSoon('Performance Lab'),
      ),
      GoRoute(
        path: '/fight-history',
        builder: (context, state) => const _ComingSoon('Fight History'),
      ),

      // ── Identity & Social ────────────────────────────────────────────────────
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/public-profile',
        builder: (context, state) => const FighterPublicProfileScreen(),
      ),
      GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),

      // ── Gyms & Teams ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/coach-hub',
        builder: (context, state) => const _ComingSoon('Coach Hub'),
      ),
      GoRoute(
        path: '/gym-hub',
        builder: (context, state) => const GymTeamHubScreen(),
      ),
      GoRoute(
        path: '/find-a-gym',
        builder: (context, state) => const FindAGymScreen(),
      ),

      // ── Rankings ─────────────────────────────────────────────────────────────
      GoRoute(
        path: '/rankings',
        builder: (context, state) => const FighterRankingsScreen(),
      ),

      // ── Events & Streaming ───────────────────────────────────────────────────
      GoRoute(
        path: '/event-center',
        builder: (context, state) => const EventsScreen(),
      ),
      GoRoute(
        path: '/tickets/:eventId',
        builder: (context, state) =>
            TicketPurchaseScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/streaming',
        builder: (context, state) => const PPVLibraryScreen(),
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
        builder: (context, state) => const PPVLibraryScreen(),
      ),
      GoRoute(
        path: '/broadcast',
        builder: (context, state) =>
            const BroadcastOverlayScreen(eventId: 'live'),
      ),

      // ── Promoter & Operations ────────────────────────────────────────────────
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
        builder: (context, state) => const _ComingSoon('Venue Operations'),
      ),

      // ── Regulatory & Back Office ─────────────────────────────────────────────
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
        builder: (context, state) => const _ComingSoon('Contracts & Legal'),
      ),
      GoRoute(
        path: '/finance',
        builder: (context, state) => const _ComingSoon('Payouts & Finance'),
      ),
      GoRoute(
        path: '/sponsors',
        builder: (context, state) => const _ComingSoon('Sponsorship'),
      ),

      // ── Admin ────────────────────────────────────────────────────────────────
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
        builder: (context, state) =>
            const _ComingSoon('Stripe Connect Onboarding'),
      ),

      // ── Economy dashboards ───────────────────────────────────────────────────
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

      // ── Content & Marketing ──────────────────────────────────────────────────
      GoRoute(
        path: '/creative-hub',
        builder: (context, state) => const CreativeHubScreen(),
      ),

      // ── TikeRocket ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/tikerocket',
        builder: (context, state) => TikeRocketScreen(
          userId: state.uri.queryParameters['userId'] ?? 'guest',
          userName: state.uri.queryParameters['userName'] ?? 'Fighter Fan',
        ),
      ),

      // ── Partnership Landing Pages ─────────────────────────────────────────────
      GoRoute(
        path: '/partners/google',
        builder: (context, state) => const GooglePartnershipScreen(),
      ),
      GoRoute(
        path: '/partners/nvidia',
        builder: (context, state) => const NvidiaPartnershipScreen(),
      ),
      GoRoute(
        path: '/partners/github',
        builder: (context, state) => const GithubPartnershipScreen(),
      ),
    ],
  );
}
