// ── RouterConfig — App Route Path Constants ────────────────────────────────────
// Single source of truth for all named route paths used across screens.

class RouteConstants {
  RouteConstants._();

  // ── Core ──────────────────────────────────────────────────────────────────
  static const String root = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

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
  static const String messaging = '/messaging';
  static const String friendRequests = '/friend-requests';

  // ── Gyms & Teams ─────────────────────────────────────────────────────────
  static const String coachHubPath = '/coach-hub';
  static const String gymHubPath = '/gym-hub';

  // ── Events & Streaming ───────────────────────────────────────────────────
  static const String eventCenterPath = '/event-center';
  static const String eventsCreatePath = '/events/create';
  static const String eventDetailsBasePath = '/event';
  static const String ticketPurchaseBasePath = '/ticket-purchase';
  static const String mapPath = '/map';
  static const String fightWorldMapPath = '/fight-world-map';
  static const String fightPassMyPassesPath = '/fight-pass/my-passes';
  static const String streamingPath = '/streaming';
  static const String ppvStorePath = '/ppv';
  static const String subscriptionPath = '/subscription';
  // TODO remove after migration: prefer ppvHub
  static const String replayPath = '/replay';
  static const String broadcastPath = '/broadcast';
  static const String ppvDetailByEventId = '/ppv-detail/:eventId';
  static const String ppvStreamByEventId = '/ppv-stream/:eventId';
  static const String ppvEventById = '/ppv/event/:id';
  static const String ppvWatchById = '/ppv/:id/watch';
  static const String ppvById = '/ppv/:id';
  static const String judgeLeaderboardPath = '/ppv/judge-leaderboard';
  static const String ppvCreatePath = '/ppv/create';
  static const String ppvPosterStorePath = '/ppv/poster-store';
  static const String ppvStoreInnerPath = '/ppv/store';
  static const String ppvNotificationsByEventId = '/ppv/notifications/:id';
  static const String privacyPath = '/privacy';
  static const String communityStandardsPath = '/community-standards';
  static const String helpPath = '/help';
  static const String streamingComparisonPath = '/streaming-comparison';
  static const String googleEarthPath = '/google-earth';
  static const String promoterPosterGeneratorPath =
      '/promoter/poster-generator';
  // TODO remove after migration: prefer promoterOnboardingPath.
  static const String legacyPromoterOnboardingPath = '/onboarding/promoter';
  static const String profileEditPath = '/profile/edit';

  // ── Promoter ─────────────────────────────────────────────────────────────
  static const String promoterPath = '/promoter';
  static const String promoterDashboardPath = '/promoter/dashboard';
  static const String cardBuilderPath = '/card-builder';
  static const String venueOpsPath = '/venue-ops';
  static const String missionControlPath = '/admin-console';
  static const String openSlotsPath = '/open-slots';
  static const String promoterOutreachHqPath = '/promoter-outreach-hq';
  static const String facebookPostPreviewPath = '/facebook-post-preview';
  static const String utmLinkBuilderPath = '/utm-link-builder';
  static const String dealPipelinePath = '/deal-pipeline';
  static const String slidingContractCalculatorPath =
      '/sliding-contract-calculator';

  // ── Back Office ──────────────────────────────────────────────────────────
  static const String officialsPath = '/officials';
  static const String medicalPath = '/medical';
  static const String legalPath = '/legal';
  static const String financePath = '/finance';
  static const String financeOnboardingPath = '/finance/onboarding';
  static const String financePromoterById = '/finance/promoter/:id';
  static const String financeFighterById = '/finance/fighter/:id';
  static const String financeGymById = '/finance/gym/:id';
  static const String sponsorsPath = '/sponsors';

  // ── Admin ────────────────────────────────────────────────────────────────
  static const String googleHubPath = '/google-hub';
  static const String adminConsolePath = '/admin-console';
  static const String economyControlPath = '/economy-control-room';
  static const String adminUsersPath = '/admin/users';
  static const String adminModerationPath = '/admin/moderation';
  static const String adminRbacPath = '/admin/rbac';
  static const String adminAuditLogsPath = '/admin/audit-logs';
  static const String adminSettingsPath = '/admin/settings';
  static const String adminAnalyticsPath = '/admin/analytics';
  static const String adminHealthPath = '/admin/health';
  static const String adminPaymentsPath = '/admin/payments';
  static const String adminSecurityPath = '/admin/security';
  static const String adminAiModerationPath = '/admin/ai-moderation';
  static const String adminPinkShieldPath = '/admin/pink-shield';
  static const String adminLockdownPath = '/admin/lockdown';
  static const String adminGdprPath = '/admin/gdpr';
  static const String adminSafetyIncidentsPath = '/admin/safety-incidents';
  static const String adminUserManagementScreenPath =
      '/admin/user-management-screen';
  static const String adminNinjaModerationPath = '/admin/ninja-moderation';
  static const String adminCampaignControlPath = '/admin/campaign-control';
  static const String adminAnalyticsWarRoomPath = '/admin/analytics-war-room';

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
  // TODO remove after migration: prefer creativeHub

  // ── Creator Hub & Content Tools ──────────────────────────────────────────
  static const String creativeHub = '/creative-hub';
  static const String viralPostTemplate = '/creator/viral-post-template';
  static const String twitterThreadComposer = '/creator/twitter-thread';
  static const String youtubeScriptWriter = '/creator/youtube-script';
  static const String facebookPostPreview = '/creator/facebook-post';
  static const String aiQuickEdit = '/creator/ai-quick-edit';
  static const String brandVoiceManager = '/creator/brand-voice';
  static const String promoVideoEditor = '/creator/promo-video';
  static const String socialQueue = '/creator/social-queue';
  static const String socialCommandCenter = '/creator/social-command-center';
  static const String contentPipelineDashboard = '/creator/content-pipeline';
  static const String linkInBio = '/creator/link-in-bio';

  // ── Marketing & Growth ───────────────────────────────────────────────────
  static const String localBusinessMarketing = '/marketing/local-business';
  static const String utmLinkBuilder = '/marketing/utm-builder';
  static const String qrPromo = '/marketing/qr-promo';
  static const String marketingHQ = '/marketing/hq';
  static const String engagementDashboard = '/marketing/engagement';
  static const String growthEngineDashboard = '/marketing/growth-engine';
  static const String marketingCostEstimator = '/marketing/cost-estimator';

  // ── Promoter Operations ──────────────────────────────────────────────────
  static const String eventManagerPath = '/promoter/event-manager';
  static const String eventsPath = '/promoter/events';
  static const String marketingHQPath = '/marketing/hq';
  static const String socialConnectorsPath = '/promoter/social-connectors';
  static const String adsSpotlightPath = '/promoter/ads-spotlight';
  static const String fighterDatabankPath = '/promoter/fighter-databank';

  // ── Marketing Command Center ─────────────────────────────────────────────
  static const String contentPipelineDashboardPath =
      '/marketing/content-pipeline';
  static const String socialQueuePath = '/marketing/social-queue';
  static const String marketingAnalyticsPath = '/marketing/analytics';
  static const String qrPromoPath = '/marketing/qr-promo';
  static const String contentCalendarPath = '/marketing/content-calendar';
  static const String linkInBioPath = '/marketing/link-in-bio';
  static const String engagementDashboardPath = '/marketing/engagement';
  static const String posterGeneratorPath = '/marketing/poster-generator';
  static const String promotionWarehousePath = '/marketing/promotion-warehouse';

  // ── Admin Command Center ─────────────────────────────────────────────────
  static const String ownerCommandCenterPath = '/admin/owner-command-center';
  static const String ppvHubPath = '/ppv';
  static const String combatMapPath = '/admin/combat-map';
  static const String promoterPricingPath = '/promoter/pricing';
  static const String promoCommandCenterPath = '/marketing/command-center';
  static const String campaignOpsPath = '/marketing/campaign-ops';

  // ── Gym Tools ────────────────────────────────────────────────────────────
  static const String partnershipHubPath = '/gym/partnerships';
  static const String combatAnalyticsPath = '/gym/combat-analytics';
  static const String gymMentorPath = '/gym/mentor';
  static const String sponsorDashboardPath = '/gym/sponsors';
  static const String registerGymPath = '/gym/register';

  // ── Global Command Panels ────────────────────────────────────────────
  static const String globalPricingPath = '/admin/global-pricing';
  static const String globalDistributionPath = '/admin/global-distribution';
  static const String globalRankingPath = '/admin/global-ranking';
  static const String autoCaptionPath = '/admin/auto-caption';
  static const String globalSeoScreenPath = '/admin/global-seo';
  // ── Nuke Room / Owner Ops ────────────────────────────────────────────────
  static const String warRoomPath = '/admin/war-room';
  static const String controlTowerPath = '/admin/control-tower';
  static const String swarmDashboardPath = '/admin/swarm-dashboard';
  static const String contentCommandCenterPath =
      '/admin/content-command-center';

  // ── Promoter Portal ──────────────────────────────────────────────────────
  static const String promoterControlRoomPath = '/promoter/control-room';
  static const String promoterOnboardingPath = '/promoter/onboarding';
  static const String promoterRightsIntakePath = '/promoter/rights-intake';
  static const String promoterReconciliationPath = '/promoter/reconciliation';

  // ── Social Discovery & Groups ────────────────────────────────────────────
  static const String fightWirePath = '/social/fightwire';
  static const String eventPromotionPath = '/social/event-promotion';
  static const String socialMediaToolkitPath = '/social/media-toolkit';
  static const String createGroupPath = '/social/groups/create';
  static const String groupDetailPath = '/social/groups/:groupId';
  static const String uploadReelPath = '/social/reels/upload';
  static const String inbox = '/messaging/inbox';
  static const String inboxPath = '/messaging/inbox';
  static const String findFriends = '/social/find-friends';
  static const String homePath = '/home';
  static const String crossPlatformPublishPath =
      '/social/cross-platform-publish';

  // ── AI & Intelligence ────────────────────────────────────────────────────
  static const String aiBrainPath = '/ai-brain';
  static const String fightLabPath = '/fight-lab';

  // ── Gym Discovery ────────────────────────────────────────────────────────
  static const String findAGymPath = '/find-a-gym';

  // ── Promoter Aliases ─────────────────────────────────────────────────────
  // TODO remove after migration: prefer promoterReconciliationPath
  static const String promoterReconciliation = '/promoter/reconciliation';

  // ── Onboarding & Info ────────────────────────────────────────────────────
  static const String howWeWorkPath = '/how-we-work';
  static const String landingPath = '/landing';
}
