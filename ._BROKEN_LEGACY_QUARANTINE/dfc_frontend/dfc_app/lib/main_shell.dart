import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/motion/dfc_motion.dart';
import 'core/navigation/navigation_shell.dart';
import 'modules/auth/screens/auth_screen.dart';
import 'modules/auth/controllers/auth_controller.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/events_screen.dart';
import 'features/admin/screens/fighters_screen.dart';
import 'features/coach/screens/smart_coach_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'features/community/screens/womens_haven_screen.dart';
import 'features/community/screens/stripe_onboarding_screen.dart';
import 'features/community/screens/leaderboard_screen.dart';
import 'features/admin/screens/gyms_screen.dart';
import 'features/events/screens/ppv_live_watch_screen.dart';
import 'health_ingestion_screen.dart';
import 'post_fight_analytics_screen.dart';
import 'fan_audience_dashboard_screen.dart';
import 'athlete_profile_media_screen.dart';
import 'contract_negotiation_screen.dart';
import 'merch_ecommerce_storefront_screen.dart';
import 'ticketing_seating_screen.dart';
import 'betting_odds_dashboard_screen.dart';
import 'messaging_screen.dart';
import 'search_screen.dart';
import 'gym_team_screen.dart';
import 'blueprint_pack_screen.dart';
import 'event_feed_screen.dart';
import 'notifications_screen.dart';
import 'settings_account_screen.dart';
import 'admin_tools_screen.dart';
import 'home_dashboard_screen.dart';
import 'admin_moderation_screen.dart';
import 'growth_dashboard_screen.dart';
import 'training_vault_screen.dart';
import 'creator_offers_screen.dart';
import 'creator_subscription_controller.dart';
import 'modules/gym_directory/screens/gym_directory_screen.dart';
import 'superhuman_dashboard_screen.dart';
import 'chat_screen.dart';
import 'ppv_poster_screen.dart';
import 'achievements_screen.dart';
import 'fan_pickems_screen.dart';
import 'weight_cut_engine_screen.dart';

final dfcRouter = GoRouter(
  initialLocation: '/auth',
  refreshListenable: authController,
  redirect: (context, state) {
    final isAuth = authController.isAuthenticated;
    final isGoingToAuth = state.matchedLocation.startsWith('/auth');

    if (!isAuth && !isGoingToAuth) {
      return '/auth';
    }
    if (isAuth && isGoingToAuth) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) =>
          DfcMotion.slidePage(key: state.pageKey, child: const AuthScreen()),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return DfcNavigationShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const HomeDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/events',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const EventsScreen(),
          ),
        ),
        GoRoute(
          path: '/fighters',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const FightersScreen(),
          ),
        ),
        GoRoute(
          path: '/admin',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const AdminDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/smartcoach',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const SmartCoachScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/analytics',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const AnalyticsDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/womens-haven',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const WomensHavenScreen(),
          ),
        ),
        GoRoute(
          path: '/stripe-onboarding',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const StripeOnboardingScreen(),
          ),
        ),
        GoRoute(
          path: '/leaderboard',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const LeaderboardScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/gyms',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const GymsScreen(),
          ),
        ),
        GoRoute(
          path: '/gyms',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const GymDirectoryScreen(),
          ),
        ),
        GoRoute(
          path: '/ppv-live/:id',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: PpvLiveWatchScreen(
              eventId: state.pathParameters['id'] ?? 'unknown',
            ),
          ),
        ),
        GoRoute(
          path: '/health-ingestion',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const HealthIngestionScreen(),
          ),
        ),
        GoRoute(
          path: '/post-fight-analytics',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const PostFightAnalyticsScreen(),
          ),
        ),
        GoRoute(
          path: '/fan-dashboard',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const FanAudienceDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/athlete-profile',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const AthleteProfileMediaScreen(),
          ),
        ),
        GoRoute(
          path: '/contract-negotiation',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const ContractNegotiationScreen(),
          ),
        ),
        GoRoute(
          path: '/store',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const MerchEcommerceStorefrontScreen(),
          ),
        ),
        GoRoute(
          path: '/ticketing',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const TicketingSeatingScreen(),
          ),
        ),
        GoRoute(
          path: '/betting-odds',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const BettingOddsDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/messaging',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const MessagingScreen(),
          ),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const SearchScreen(),
          ),
        ),
        GoRoute(
          path: '/gym-team',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const GymTeamScreen(),
          ),
        ),
        GoRoute(
          path: '/blueprints',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const BlueprintPackScreen(),
          ),
        ),
        GoRoute(
          path: '/event-feed',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const EventFeedScreen(),
          ),
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const NotificationsScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const SettingsAccountScreen(),
          ),
        ),
        GoRoute(
          path: '/admin-tools',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const AdminToolsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/moderation',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const AdminModerationScreen(),
          ),
        ),
        GoRoute(
          path: '/growth-dashboard',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const GrowthDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/training-vault/:creatorId/:creatorName',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: TrainingVaultScreen(
              creatorId: state.pathParameters['creatorId'] ?? 'unknown',
              creatorName: state.pathParameters['creatorName'] ?? 'Creator',
            ),
          ),
        ),
        GoRoute(
          path: '/creator-offers/:creatorId',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: CreatorOffersScreen(
              controller: state.extra as CreatorSubscriptionController,
              creatorId: state.pathParameters['creatorId'] ?? 'unknown',
            ),
          ),
        ),
        GoRoute(
          path: '/chat/:id',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: ChatScreen(
              conversationId: state.pathParameters['id'] ?? '',
              name: state.uri.queryParameters['name'] ?? 'Chat',
            ),
          ),
        ),
        GoRoute(
          path: '/bionic',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const SuperhumanDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/ppv/:id',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: PpvPosterScreen(eventId: state.pathParameters['id'] ?? ''),
          ),
        ),
        GoRoute(
          path: '/achievements',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const AchievementsScreen(),
          ),
        ),
        GoRoute(
          path: '/pickems',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const FanPickemsScreen(),
          ),
        ),
        GoRoute(
          path: '/weight-cut',
          pageBuilder: (context, state) => DfcMotion.slidePage(
            key: state.pageKey,
            child: const WeightCutEngineScreen(),
          ),
        ),
      ],
    ),
  ],
);
