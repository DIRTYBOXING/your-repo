// ── RouterConfig — App Route Path Constants ────────────────────────────────────
// Single source of truth for all named route paths used across screens.

class RouterConfig {
  RouterConfig._();

  // ── Core ──────────────────────────────────────────────────────────────────
  static const String root = '/';
  static const String login = '/login';
  static const String home = '/home';

  // ── Coach & Training ─────────────────────────────────────────────────────
  static const String neuralCoachPath = '/neural-coach';
  static const String cornerCoachPath = '/corner-coach';
  static const String trainingSessionPath = '/training-session';
  static const String fightCampToolsPath = '/fight-camp';
  static const String fightSummaryPath = '/fight-summary';

  // ── Health & Devices ─────────────────────────────────────────────────────
  static const String deviceHubPath = '/devices';
  static const String healthDashboardPath = '/health';
  static const String bodyMonitorPath = '/body-monitor';
  static const String astroHealthPath = '/astrohealth';

  // ── Analytics ────────────────────────────────────────────────────────────
  static const String performanceLabPath = '/performance-lab';
  static const String fightHistoryPath = '/fight-history';

  // ── Identity & Social ────────────────────────────────────────────────────
  static const String profilePath = '/profile';
  static const String publicProfilePath = '/public-profile';
  static const String feedPath = '/feed';

  // ── Gyms & Teams ─────────────────────────────────────────────────────────
  static const String coachHubPath = '/coach-hub';
  static const String gymHubPath = '/gym-hub';

  // ── Events & Streaming ───────────────────────────────────────────────────
  static const String eventCenterPath = '/event-center';
  static const String streamingPath = '/streaming';
  static const String ppvStorePath = '/ppv';
  static const String replayPath = '/replay';
  static const String broadcastPath = '/broadcast';

  // ── Promoter ─────────────────────────────────────────────────────────────
  static const String promoterPath = '/promoter';
  static const String cardBuilderPath = '/card-builder';
  static const String venueOpsPath = '/venue-ops';
  static const String missionControlPath = '/admin-console';

  // ── Back Office ──────────────────────────────────────────────────────────
  static const String officialsPath = '/officials';
  static const String medicalPath = '/medical';
  static const String legalPath = '/legal';
  static const String financePath = '/finance';
  static const String promoterReconciliationPath = '/reconciliation';
  static const String promoterReconciliation = 'promoter-reconciliation';
  static const String sponsorsPath = '/sponsors';

  // ── Admin ────────────────────────────────────────────────────────────────
  static const String googleHubPath = '/google-hub';
  static const String adminConsolePath = '/admin-console';
  static const String economyControlPath = '/economy-control-room';

  // ── Content ──────────────────────────────────────────────────────────────
  static const String creativeHubPath = '/creative-hub';

  // ── Partnership ──────────────────────────────────────────────────────────
  static const String googlePartnerPath = '/partners/google';
  static const String nvidiaPartnerPath = '/partners/nvidia';
  static const String githubPartnerPath = '/partners/github';

  // ── TikeRocket ────────────────────────────────────────────────────────────
  static const String tikeRocket = '/tikerocket';

  // ── Social content ───────────────────────────────────────────────────────
  static const String createStoryPath = '/stories/create';
  static const String storyViewerPath = '/stories/view';

  // ── Auth ─────────────────────────────────────────────────────────────────
  static const String roleSelection = '/role-selection';
  static const String ppvHub = '/ppv';
}

// Legacy aliases retained for modules/tests still importing RouteConstants.
class RouteConstants {
  RouteConstants._();

  // Historical name kept for compatibility. Used as a GoRouter route name.
  static const String promoterReconciliationPath =
      RouterConfig.promoterReconciliation;
}
