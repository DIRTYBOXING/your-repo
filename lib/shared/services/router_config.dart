import 'package:go_router/go_router.dart';

import '../../features/auth/screens/register_screen.dart';
import '../../features/legal/screens/cookie_policy_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/legal/screens/terms_of_service_screen.dart';
import '../../features/legal/screens/community_guidelines_screen.dart';

// This is a basic router configuration. You would expand this to include
// all your app's routes like /login, /home, etc.

final router = GoRouter(
  initialLocation: '/register',
  routes: [
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/terms-of-service',
      builder: (context, state) => const TermsOfServiceScreen(),
      // Custom transition example
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const TermsOfServiceScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PrivacyPolicyScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: '/cookie-policy',
      builder: (context, state) => const CookiePolicyScreen(),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CookiePolicyScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: '/community-guidelines',
      builder: (context, state) => const CommunityGuidelinesScreen(),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CommunityGuidelinesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
  ],
);
