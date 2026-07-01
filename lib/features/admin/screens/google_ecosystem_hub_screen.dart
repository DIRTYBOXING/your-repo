import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DFC × GOOGLE ECOSYSTEM POWER HUB
//
//  Every Google technology, service, API, and program mapped to DFC.
//  From mental institution to app developer — Google is the engine,
//  DFC is the vehicle, and fighters are the destination.
// ─────────────────────────────────────────────────────────────────────────────

class GoogleEcosystemHubScreen extends StatefulWidget {
  const GoogleEcosystemHubScreen({super.key});

  @override
  State<GoogleEcosystemHubScreen> createState() =>
      _GoogleEcosystemHubScreenState();
}

class _GoogleEcosystemHubScreenState extends State<GoogleEcosystemHubScreen>
    with SingleTickerProviderStateMixin {
  // ── Neon Theme ────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF0A0E1A);
  static const _card = Color(0xFF111827);
  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _amber = Color(0xFFFFAB00);
  static const _red = Color(0xFFFF1744);
  static const _purple = Color(0xFF9D00FF);
  static const _orange = Color(0xFFFF6D00);
  static const _blue = Color(0xFF2979FF);
  static const _pink = Color(0xFFFF4081);

  // Google brand colours
  static const _gBlue = Color(0xFF4285F4);
  static const _gRed = Color(0xFFEA4335);
  static const _gYellow = Color(0xFFFBBC04);
  static const _gGreen = Color(0xFF34A853);

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Row(
          children: [
            _googleLogo(14),
            const SizedBox(width: 8),
            const Text(
              '× DFC POWER HUB',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: _gBlue,
          labelColor: _gBlue,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.hub, size: 13), text: 'OVERVIEW'),
            Tab(
              icon: Icon(Icons.local_fire_department, size: 13),
              text: 'FIREBASE',
            ),
            Tab(icon: Icon(Icons.cloud, size: 13), text: 'CLOUD'),
            Tab(icon: Icon(Icons.psychology, size: 13), text: 'AI / ML'),
            Tab(icon: Icon(Icons.web, size: 13), text: 'PLATFORMS'),
            Tab(icon: Icon(Icons.auto_stories, size: 13), text: 'MY STORY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildOverviewTab(),
          _buildFirebaseTab(),
          _buildCloudTab(),
          _buildAiMlTab(),
          _buildPlatformsTab(),
          _buildFounderStoryTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 1 — OVERVIEW (Full Google Ecosystem Map)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        // ── Hero Banner ───────────────────────────────────────────────────
        _googleHeroBanner(),
        const SizedBox(height: 16),

        // ── Active Integrations ───────────────────────────────────────────
        _sectionHeader(
          Icons.check_circle,
          'ACTIVE GOOGLE INTEGRATIONS',
          _green,
        ),
        const SizedBox(height: 8),
        _statusGrid([
          const _GStatus(
            'Firebase Auth',
            Icons.lock,
            _green,
            true,
            'User login, Google Sign-In, MFA',
          ),
          const _GStatus(
            'Firestore',
            Icons.storage,
            _green,
            true,
            'Real-time NoSQL database',
          ),
          const _GStatus(
            'Cloud Functions',
            Icons.functions,
            _green,
            true,
            'Serverless backend logic',
          ),
          const _GStatus(
            'Cloud Storage',
            Icons.cloud_upload,
            _green,
            true,
            'Media files, fight footage',
          ),
          const _GStatus(
            'Firebase Analytics',
            Icons.analytics,
            _green,
            true,
            'User behaviour tracking',
          ),
          const _GStatus(
            'Firebase App Check',
            Icons.verified_user,
            _green,
            true,
            'Blocks non-genuine traffic',
          ),
          const _GStatus(
            'Gemini AI (Genkit)',
            Icons.auto_awesome,
            _green,
            true,
            'AI coach, fight analysis',
          ),
          const _GStatus(
            'Google Fit API',
            Icons.watch,
            _green,
            true,
            'Health data sync',
          ),
          const _GStatus(
            'Google Pay',
            Icons.payment,
            _green,
            true,
            'In-app payments',
          ),
          const _GStatus(
            'Google Mobile Ads',
            Icons.ads_click,
            _amber,
            false,
            'Stub mode — awaiting Firebase ^3.x',
          ),
          const _GStatus(
            'Flutter Framework',
            Icons.phone_android,
            _green,
            true,
            'Cross-platform UI',
          ),
          const _GStatus(
            'Material Design 3',
            Icons.palette,
            _green,
            true,
            'Design system',
          ),
        ]),
        const SizedBox(height: 16),

        // ── Planned Integrations ──────────────────────────────────────────
        _sectionHeader(Icons.schedule, 'PLANNED INTEGRATIONS', _amber),
        const SizedBox(height: 8),
        _statusGrid([
          const _GStatus(
            'Google Maps Platform',
            Icons.map,
            _amber,
            false,
            'Gym finder, event locations',
          ),
          const _GStatus(
            'YouTube Data API',
            Icons.play_circle,
            _amber,
            false,
            'Fight video embedding',
          ),
          const _GStatus(
            'Vertex AI',
            Icons.psychology,
            _amber,
            false,
            'Advanced ML models',
          ),
          const _GStatus(
            'Cloud Vision AI',
            Icons.remove_red_eye,
            _amber,
            false,
            'Fight footage analysis',
          ),
          const _GStatus(
            'Cloud Video AI',
            Icons.videocam,
            _amber,
            false,
            'Auto fight highlights',
          ),
          const _GStatus(
            'Speech-to-Text',
            Icons.mic,
            _amber,
            false,
            'Voice commands, accessibility',
          ),
          const _GStatus(
            'Text-to-Speech',
            Icons.volume_up,
            _amber,
            false,
            'Screen reader support',
          ),
          const _GStatus(
            'Cloud Translation',
            Icons.translate,
            _amber,
            false,
            '40+ language support',
          ),
          const _GStatus(
            'reCAPTCHA',
            Icons.security,
            _amber,
            false,
            'Bot protection',
          ),
          const _GStatus(
            'Google Workspace',
            Icons.work,
            _amber,
            false,
            'Team collaboration',
          ),
          const _GStatus(
            'BigQuery',
            Icons.table_chart,
            _amber,
            false,
            'Analytics data warehouse',
          ),
          const _GStatus(
            'Firebase Remote Config',
            Icons.tune,
            _amber,
            false,
            'Feature flags, A/B testing',
          ),
        ]),
        const SizedBox(height: 16),

        // ── Grant Programs ────────────────────────────────────────────────
        _sectionHeader(
          Icons.card_giftcard,
          'GOOGLE GRANT & SUPPORT PROGRAMS',
          _gBlue,
        ),
        const SizedBox(height: 8),
        _grantCard(
          'Google for Startups',
          'Up to \$100K in Cloud credits + mentorship',
          _gBlue,
          Icons.rocket_launch,
          [
            'Cloud credits for Firebase + GCP services',
            'Technical mentorship from Google engineers',
            'Access to Google\'s startup network',
            'Potential investment introductions',
            'Google for Startups Accelerator eligibility',
          ],
          'APPLYING',
        ),
        _grantCard(
          'Google Ad Grants',
          '\$10,000/month in free Google Ads',
          _gGreen,
          Icons.campaign,
          [
            '\$10K monthly search ad budget',
            'Reach fighters, gyms, and fans via Google Search',
            'Requires 501(c)(3) or social enterprise status',
            'Must maintain 5% click-through rate',
            'Perfect for community-focused marketing',
          ],
          'APPLYING',
        ),
        _grantCard(
          'Firebase Spark → Blaze',
          'Pay-as-you-go with free tier',
          _orange,
          Icons.local_fire_department,
          [
            'Generous free tier covers early growth',
            'No upfront costs — pay only for overages',
            'Auto-scaling from 0 to millions of users',
            'Apply for Firebase startup credits programme',
          ],
          'ACTIVE',
        ),
        _grantCard(
          'Google.org Impact Challenge',
          'Grants for social impact technology',
          _gRed,
          Icons.favorite,
          [
            'Grants up to \$2M for community impact projects',
            'DFC qualifies via youth development + health pillars',
            'Disability inclusion angle strengthens application',
            'Global reach across 128+ countries',
          ],
          'RESEARCHING',
        ),
        _grantCard(
          'Google Cloud for Nonprofits',
          'Free Google Workspace + Cloud credits',
          _purple,
          Icons.cloud,
          [
            'Free Google Workspace Business for nonprofits',
            '\$2,000/year in Google Cloud credits',
            'Access to YouTube Nonprofit Programme',
            'Google Maps Platform credits',
          ],
          'RESEARCHING',
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 2 — FIREBASE (The Backbone)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFirebaseTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        _firebaseBanner(),
        const SizedBox(height: 16),

        _sectionHeader(Icons.build, 'BUILD SERVICES', _orange),
        const SizedBox(height: 8),
        _firebaseService('Authentication', Icons.lock, _green, 'ACTIVE', [
          'Email/password registration + Google OAuth',
          'Apple Sign-In for iOS users',
          'Multi-factor authentication (MFA) ready',
          'Custom claims for admin/developer access',
          'Onboarding flow with consent logging',
          'DFC Use: Every user login, role-based access, developer gate',
        ]),
        _firebaseService('Cloud Firestore', Icons.storage, _gBlue, 'ACTIVE', [
          'Real-time NoSQL document database',
          'Offline persistence for mobile users',
          'Security rules enforce data access policies',
          'Compound queries for fight search and filtering',
          'DFC Use: Users, fighters, posts, events, stats, health, training sessions',
        ]),
        _firebaseService(
          'Cloud Functions',
          Icons.functions,
          _purple,
          'ACTIVE',
          [
            'Node.js serverless functions triggered by events',
            'HTTPS callable functions for AI coach pipeline',
            'Firestore triggers for automated workflows',
            'Scheduled functions for daily analytics rollups',
            'DFC Use: Genkit AI flows, fight predictions, moderation',
          ],
        ),
        _firebaseService('Cloud Storage', Icons.cloud_upload, _cyan, 'ACTIVE', [
          'Store images, videos, fight footage',
          'Resumable uploads for large fight videos',
          'Security rules protect user media',
          'Auto-generate thumbnails via Cloud Functions',
          'DFC Use: Profile photos, fight cards, event posters, training clips',
        ]),
        const SizedBox(height: 16),

        _sectionHeader(Icons.analytics, 'ANALYTICS & ENGAGEMENT', _amber),
        const SizedBox(height: 8),
        _firebaseService(
          'Firebase Analytics',
          Icons.analytics,
          _amber,
          'ACTIVE',
          [
            'Automatic event tracking (screen views, sessions)',
            'Custom events for feature usage analytics',
            'User properties for segmentation',
            'Integration with BigQuery for deep analysis',
            'DFC Use: Track which features fighters use most, engagement funnels',
          ],
        ),
        _firebaseService('Crashlytics', Icons.bug_report, _red, 'PLANNED', [
          'Real-time crash reporting with stack traces',
          'Impact analysis — which crashes affect most users',
          'Breadcrumb logs for crash reproduction',
          'Alerts for new issues and regressions',
          'DFC Use: Ensure app stability across all platforms',
        ]),
        _firebaseService(
          'Performance Monitoring',
          Icons.speed,
          _green,
          'PLANNED',
          [
            'Automatic HTTP/S request tracing',
            'Screen rendering performance metrics',
            'Custom traces for critical code paths',
            'Network request success/failure rates',
            'DFC Use: Monitor fight feed load times, video upload speeds',
          ],
        ),
        _firebaseService('Remote Config', Icons.tune, _blue, 'PLANNED', [
          'Change app behaviour without publishing updates',
          'A/B testing for UI experiments',
          'Percentage-based rollouts for new features',
          'Conditional values based on user segments',
          'DFC Use: Feature flags, maintenance mode, onboarding experiments',
        ]),
        const SizedBox(height: 16),

        _sectionHeader(Icons.people, 'GROWTH & MESSAGING', _pink),
        const SizedBox(height: 8),
        _firebaseService(
          'Cloud Messaging (FCM)',
          Icons.notifications,
          _pink,
          'PLANNED',
          [
            'Push notifications to iOS, Android, and web',
            'Topic-based messaging (by discipline, region)',
            'Personalised notifications via user segments',
            'Silent data messages for background sync',
            'DFC Use: Fight alerts, event reminders, sponsor promotions, health nudges',
          ],
        ),
        _firebaseService(
          'Dynamic Links / App Links',
          Icons.link,
          _cyan,
          'PLANNED',
          [
            'Deep links that survive app installation',
            'Share fighter profiles that open directly in-app',
            'Referral tracking for fighter ambassador programme',
            'Cross-platform link handling (iOS, Android, web)',
            'DFC Use: Fighter referral engine, event sharing, gym invites',
          ],
        ),
        _firebaseService('App Check', Icons.verified_user, _green, 'ACTIVE', [
          'Play Integrity (Android) + DeviceCheck (iOS)',
          'Blocks non-genuine traffic and API abuse',
          'Works with Firestore, Storage, and Functions',
          'DFC Use: Prevent bots from scraping fighter data',
        ]),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 3 — CLOUD (GCP Infrastructure)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCloudTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        _gcpBanner(),
        const SizedBox(height: 16),

        _sectionHeader(Icons.dns, 'COMPUTE & HOSTING', _gBlue),
        const SizedBox(height: 8),
        _gcpService(
          'Cloud Run',
          Icons.rocket_launch,
          _gBlue,
          'Run containerised backend services that auto-scale to zero when idle. '
              'Perfect for the DFC AI pipeline, video processing, and batch analytics.',
          [
            'Atlas backend (Python/FastAPI)',
            'Video processing workers',
            'Fight prediction API',
          ],
        ),
        _gcpService(
          'App Engine',
          Icons.web,
          _gGreen,
          'Fully managed platform for web apps. Host DFC web version with automatic '
              'SSL, custom domains, and global CDN.',
          ['DFC web app hosting', 'Admin dashboard', 'Public API endpoints'],
        ),
        _gcpService(
          'Firebase Hosting',
          Icons.language,
          _orange,
          'Fast, secure hosting for web assets with global CDN. Already used for '
              'DFC web build. Auto-deploys from GitHub Actions.',
          [
            'flutter build web output',
            'Static assets and PWA',
            'Custom domain with SSL',
          ],
        ),
        const SizedBox(height: 16),

        _sectionHeader(Icons.storage, 'DATA & DATABASES', _green),
        const SizedBox(height: 8),
        _gcpService(
          'BigQuery',
          Icons.table_chart,
          _gBlue,
          'Serverless data warehouse for petabyte-scale analytics. Export Firestore '
              'data to BigQuery for deep fight analytics, trend analysis, and ML training.',
          [
            'Fight performance analytics at scale',
            'User engagement data warehouse',
            'ML training data pipeline',
          ],
        ),
        _gcpService(
          'Cloud SQL',
          Icons.grid_on,
          _gGreen,
          'Managed PostgreSQL/MySQL for relational data. If DFC ever needs complex '
              'relational queries (league tables, tournament brackets), Cloud SQL handles it.',
          [
            'Tournament bracket engine',
            'League standings with complex joins',
            'Historical records archive',
          ],
        ),
        _gcpService(
          'Memorystore (Redis)',
          Icons.memory,
          _red,
          'In-memory caching for blazing-fast reads. Cache fighter rankings, trending '
              'content, and live event feeds.',
          [
            'Fighter ranking cache',
            'Trending feed cache',
            'Live event state management',
          ],
        ),
        const SizedBox(height: 16),

        _sectionHeader(Icons.security, 'SECURITY & IDENTITY', _red),
        const SizedBox(height: 8),
        _gcpService(
          'Cloud KMS',
          Icons.vpn_key,
          _red,
          'Key Management Service for encryption at rest. All DFC data encrypted '
              'with Google-managed keys. Option for customer-managed keys at enterprise tier.',
          [
            'AES-256 encryption',
            'Automatic key rotation',
            'CMEK for enterprise clients',
          ],
        ),
        _gcpService(
          'Identity Platform',
          Icons.fingerprint,
          _purple,
          'Enterprise-grade identity and access management. Multi-tenant auth '
              'for gyms and promoters who manage their own fighter rosters.',
          [
            'Multi-tenant gym auth',
            'SAML/OIDC for enterprise',
            'Blocking functions for custom logic',
          ],
        ),
        _gcpService(
          'Secret Manager',
          Icons.lock_outline,
          _amber,
          'Securely store API keys, database passwords, and service credentials. '
              'No more secrets in code — everything stays in Secret Manager.',
          [
            'OpenAI API key storage',
            'Stripe secret keys',
            'Third-party API credentials',
          ],
        ),
        const SizedBox(height: 16),

        _sectionHeader(Icons.network_check, 'NETWORKING & CDN', _cyan),
        const SizedBox(height: 8),
        _gcpService(
          'Cloud CDN',
          Icons.public,
          _cyan,
          'Global content delivery network. Fight videos, images, and static assets '
              'served from 200+ edge locations for sub-50ms latency worldwide.',
          [
            'Fight video streaming',
            'Image/poster delivery',
            'Web app static assets',
          ],
        ),
        _gcpService(
          'Cloud Armor',
          Icons.shield,
          _red,
          'DDoS protection and WAF (Web Application Firewall). Protect DFC APIs '
              'from attacks, rate limit abusive clients, and block bad actors.',
          ['DDoS mitigation', 'Rate limiting', 'Geo-based access controls'],
        ),
        _gcpService(
          'Cloud DNS',
          Icons.dns,
          _gBlue,
          'Reliable, low-latency DNS hosting. 100% SLA. Custom domain management '
              'for datafightcentral.com and partner gym subdomains.',
          [
            'Custom domain routing',
            'Gym subdomain management',
            'Geographic routing',
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 4 — AI / ML (Google Intelligence)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAiMlTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        _aiBanner(),
        const SizedBox(height: 16),

        _sectionHeader(Icons.auto_awesome, 'GEMINI AI — THE BRAIN', _purple),
        const SizedBox(height: 8),
        _aiService(
          'Gemini 2.0 Flash',
          Icons.flash_on,
          _purple,
          'ACTIVE (via Genkit)',
          [
            'AI Coach — personalised training recommendations',
            'Fight prediction engine — analyse matchups',
            'Content moderation — scan posts for safety',
            'Nutrition planning — AI-generated meal plans',
            'Opponent analysis — strengths/weaknesses breakdown',
            'Fight commentary generation — auto captions for clips',
          ],
        ),
        _aiService('Gemini 2.0 Pro', Icons.auto_awesome, _cyan, 'PLANNED', [
          'Advanced fight strategy analysis with multi-modal input',
          'Video understanding — break down fight footage frame by frame',
          'Long context — analyse entire fight careers in one prompt',
          'Agentic capabilities — chain fight analysis with recommendations',
        ]),
        const SizedBox(height: 16),

        _sectionHeader(Icons.visibility, 'VISION AI — THE EYES', _cyan),
        const SizedBox(height: 8),
        _aiService('Cloud Vision AI', Icons.remove_red_eye, _cyan, 'PLANNED', [
          'OCR fight card scan — auto-extract fighter details from posters',
          'Image labelling — auto-tag fight photos',
          'Safe search — filter inappropriate content uploads',
          'Face detection — optional fighter ID verification',
          'Logo detection — identify sponsors in fight footage',
        ]),
        _aiService('Video Intelligence AI', Icons.videocam, _green, 'PLANNED', [
          'Shot detection — auto-split rounds in fight footage',
          'Action recognition — detect punches, kicks, takedowns, submissions',
          'Highlight reel generation — AI picks the best moments',
          'Person tracking — follow specific fighter through fight footage',
          'Label detection — auto-tag fighting style and techniques',
        ]),
        const SizedBox(height: 16),

        _sectionHeader(
          Icons.record_voice_over,
          'LANGUAGE AI — THE VOICE',
          _amber,
        ),
        const SizedBox(height: 8),
        _aiService('Speech-to-Text', Icons.mic, _amber, 'PLANNED', [
          'Voice commands — "show me my stats" hands-free in gym',
          'Corner voice transcription — convert coaching audio to text',
          'Fight commentary-to-text — auto-transcribe live events',
          'Accessibility — voice navigation for disabled fighters',
          'Multi-language speech recognition (128 languages)',
        ]),
        _aiService('Text-to-Speech', Icons.volume_up, _orange, 'PLANNED', [
          'Screen reader — full app narration for blind users',
          'AI Coach voice — spoken training recommendations',
          'Event announcements — auto-generate audio for fight cards',
          'Multi-language speech output for global community',
          'Custom voice models — DFC branded AI voice',
        ]),
        _aiService('Cloud Translation', Icons.translate, _gBlue, 'PLANNED', [
          'Real-time translation of posts and comments (135 languages)',
          'Auto-translate fighter profiles for international scouts',
          'Event descriptions in local languages',
          'Chat translation between fighters from different countries',
          'Neural Machine Translation for natural-sounding output',
        ]),
        _aiService(
          'Natural Language AI',
          Icons.text_fields,
          _green,
          'PLANNED',
          [
            'Sentiment analysis on fight discussion posts',
            'Entity extraction — auto-link fighters, gyms, events from text',
            'Content classification — auto-categorise posts by topic',
            'Syntax analysis — improve AI-generated content quality',
          ],
        ),
        const SizedBox(height: 16),

        _sectionHeader(Icons.model_training, 'ML PLATFORM — THE MUSCLE', _red),
        const SizedBox(height: 8),
        _aiService('Vertex AI', Icons.hub, _red, 'PLANNED', [
          'AutoML — train custom fight scoring models without ML expertise',
          'Custom model training — predict fight outcomes from historical data',
          'Model deployment — serve predictions at scale',
          'Feature Store — reusable ML features (fighter stats, fight history)',
          'MLOps — automated model retraining and monitoring',
        ]),
        _aiService('TensorFlow / TFLite', Icons.memory, _orange, 'PLANNED', [
          'On-device ML — real-time pose estimation during training',
          'Punch speed measurement via phone camera',
          'Technique scoring — compare form to reference models',
          'Offline inference — works without internet in gym',
          'Federated learning — improve models without raw data leaving device',
        ]),
        _aiService('Recommendations AI', Icons.recommend, _pink, 'PLANNED', [
          'Fighter-to-fighter matching — "Fighters like you trained with..."',
          'Gym recommendations — based on discipline, location, skill level',
          'Content recommendations — personalised fight feed',
          'Event recommendations — fights you\'d want to attend',
        ]),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 5 — PLATFORMS (Google Products & APIs)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPlatformsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        _sectionHeader(Icons.map, 'GOOGLE MAPS PLATFORM', _gGreen),
        const SizedBox(height: 8),
        _platformCard('Maps SDK for Flutter', Icons.map, _gGreen, [
          'Interactive gym finder with real-time location',
          'Event venue mapping with directions',
          'Fighter heatmap — where fights happen globally',
          'Geo-fencing for event check-in',
          'Custom map styles matching DFC neon theme',
        ]),
        _platformCard('Places API', Icons.place, _gBlue, [
          'Gym search with reviews, photos, and hours',
          'Auto-complete for gym and venue addresses',
          'Nearby gyms recommendation for travelling fighters',
        ]),
        _platformCard('Geocoding API', Icons.pin_drop, _amber, [
          'Convert fighter addresses to coordinates',
          'Reverse geocode event locations',
          'Region-based fighter search and matching',
        ]),
        const SizedBox(height: 16),

        _sectionHeader(Icons.play_circle, 'YOUTUBE & MEDIA', _red),
        const SizedBox(height: 8),
        _platformCard('YouTube Data API v3', Icons.play_circle, _red, [
          'Embed fight videos directly in fighter profiles',
          'Search YouTube for fight footage by fighter name',
          'Display fight channels and subscriber counts',
          'Upload fight highlights directly to YouTube from DFC',
          'YouTube Shorts integration for viral fight clips',
        ]),
        _platformCard('YouTube Live Streaming API', Icons.live_tv, _red, [
          'Live stream fights from DFC app',
          'Scheduled live events with countdown',
          'Chat overlay for live fight commentary',
          'Monetisation via Super Chats during fights',
        ]),
        _platformCard(
          'YouTube Nonprofit Programme',
          Icons.volunteer_activism,
          _gRed,
          [
            'Link-anywhere cards (not just YouTube)',
            'Call-to-action overlays for DFC sign-up',
            'Donation cards on fight videos',
            'Increased visibility in search results',
          ],
        ),
        const SizedBox(height: 16),

        _sectionHeader(Icons.ads_click, 'GOOGLE ADS & MARKETING', _gBlue),
        const SizedBox(height: 8),
        _platformCard('Google Ads API', Icons.campaign, _gBlue, [
          'Programmatic ad campaign management',
          'Auto-generate fight-themed ad creatives',
          'Keyword bidding automation for fight-related terms',
          'Performance reporting integrated into DFC dashboard',
        ]),
        _platformCard(
          'AdMob / Google Mobile Ads',
          Icons.monetization_on,
          _gGreen,
          [
            'Banner ads on fight feed (non-intrusive)',
            'Interstitial ads between fight card views',
            'Rewarded video ads — watch an ad to unlock premium features',
            'Native ads blended into fight content stream',
            'Mediation for maximum ad revenue',
          ],
        ),
        _platformCard('Google Analytics 4', Icons.analytics, _amber, [
          'Cross-platform event tracking (app + web)',
          'Funnel analysis: sign-up → first fight → sponsor match',
          'Audience segmentation by discipline, region, skill',
          'Predictive metrics: likely-to-churn, likely-to-purchase',
          'BigQuery export for advanced analysis',
        ]),
        const SizedBox(height: 16),

        _sectionHeader(Icons.health_and_safety, 'HEALTH & WEARABLES', _green),
        const SizedBox(height: 8),
        _platformCard('Google Fit / Health Connect', Icons.favorite, _green, [
          'Sync heart rate, steps, sleep, calories',
          'Training load tracking from wearables',
          'Recovery monitoring between fights',
          'Weight tracking for weight class management',
          'Integration with Fitbit, Wear OS, and Pixel Watch',
        ]),
        _platformCard('Fitbit Web API', Icons.watch, _cyan, [
          'Detailed heart rate zone analysis during training',
          'Sleep stage tracking for recovery optimisation',
          'Stress management score for fight readiness',
          'SpO2 monitoring for altitude training',
          'Active Zone Minutes for workout intensity',
        ]),
        const SizedBox(height: 16),

        _sectionHeader(
          Icons.accessibility_new,
          'ACCESSIBILITY & INCLUSION',
          _purple,
        ),
        const SizedBox(height: 8),
        _platformCard(
          'Android Accessibility Suite',
          Icons.accessibility_new,
          _purple,
          [
            'TalkBack screen reader compatibility',
            'Switch Access for motor-impaired users',
            'Voice Access for hands-free navigation',
            'BrailleBack for Braille display support',
            'Live Caption for fight video accessibility',
          ],
        ),
        _platformCard('Material Design Accessibility', Icons.palette, _cyan, [
          'High-contrast neon theme already implemented',
          'Semantic labels on all interactive elements',
          'Minimum 4.5:1 contrast ratio enforcement',
          'Scalable text for vision-impaired users',
          'Keyboard navigation support for web',
        ]),
        _platformCard('Google Workspace (Team Tools)', Icons.work, _gBlue, [
          'Gmail for team communication',
          'Google Meet for remote meetings',
          'Google Drive for shared documents',
          'Google Sheets for data management',
          'Google Calendar for event scheduling',
        ]),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 6 — MY STORY (Founder Journey)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFounderStoryTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        _founderBanner(),
        const SizedBox(height: 20),

        _storyChapter(
          'CHAPTER 1',
          'THE GUTTER',
          _red,
          Icons.nights_stay,
          'I grew up on the streets. Not metaphorically — literally in the gutter. '
              'Child abuse. Poverty so deep you can\'t see the top. No safety net. '
              'No one coming to help. The streets were my home and my classroom.\n\n'
              'I was jailed for a crime I never committed. Inside, I crossed paths '
              'with Mark Brandon "Chopper" Read — one of Australia\'s most notorious '
              'convicted criminals. That was the world I knew. Violence. Survival. '
              'The kind of life where every day is a fight just to exist.\n\n'
              'Addiction followed. Drugs. Alcohol. The things you reach for when the '
              'pain gets louder than your will. Mental illness wasn\'t a diagnosis — '
              'it was daily life. Institutions became temporary shelters between '
              'stretches of nothing.',
        ),

        _storyChapter(
          'CHAPTER 2',
          'THE FIGHTER',
          _amber,
          Icons.sports_mma,
          'But through all of it, I could fight. Not just survive — FIGHT.\n\n'
              'I became a fighting champion. From the gutters to the ring. No '
              'sponsors. No fancy gym. No manager. Just raw talent forged in '
              'the hardest school on Earth — the streets.\n\n'
              'Fighting gave me the only identity I had. It gave me purpose when '
              'everything else was chaos. It gave me respect when the world gave '
              'me nothing. But addiction, street life, poverty, and bad relationships '
              'eventually took it all away. My career ended. My life felt over.\n\n'
              'I was a champion with nothing. A fighter with no fight left.',
        ),

        _storyChapter(
          'CHAPTER 3',
          'THE REBIRTH',
          _cyan,
          Icons.lightbulb,
          'Then Google entered my life.\n\n'
              'Not as a search engine for get-rich-quick schemes. As a LEARNING '
              'PLATFORM. As a lifeline. YouTube taught me to code when no university '
              'would have me. Google Search answered questions at 3 AM when no one '
              'else was awake. Firebase gave me a production backend without needing '
              'a team. Flutter let me build for every platform from one codebase.\n\n'
              'I\'m disabled. The world calls me unintelligent. I\'m a single father. '
              'I run commercial printers by day and write code by night. I have no '
              'degree, no certification, no team, no funding.\n\n'
              'But I have Google\'s tools. And with those tools, I built Data Fight '
              'Central — a platform that serves fighters in 128 countries. Line by '
              'line. Screen by screen. Error by error. Alone.',
        ),

        _storyChapter(
          'CHAPTER 4',
          'THE PLATFORM',
          _green,
          Icons.code,
          'DFC isn\'t just an app. It\'s everything I wish I had as a young fighter.\n\n'
              '• The gym finder I never had when I was training in car parks.\n'
              '• The health tracking I never had when I was cutting weight dangerously.\n'
              '• The sponsor connections I never had when I was fighting for nothing.\n'
              '• The AI coach I never had when I was learning technique from street fights.\n'
              '• The community I never had when I was alone in a cell.\n\n'
              'Every feature in DFC was born from pain. The mental health resources '
              'exist because I know what it\'s like to lose your mind. The addiction '
              'awareness exists because I know what it\'s like to lose yourself. '
              'The accessibility features exist because I know what it\'s like when '
              'the world isn\'t built for you.\n\n'
              'Every single piece runs on Google technology.\n'
              'Flutter. Firebase. Gemini. Maps. Fit. Pay. Analytics.\n'
              '30+ Google technologies. 50,000+ lines of code. One developer.',
        ),

        _storyChapter(
          'CHAPTER 5',
          'THE PROOF',
          _purple,
          Icons.auto_awesome,
          'Google, look at what your technology did:\n\n'
              '• A man who lived in the gutter now builds AI-powered platforms.\n'
              '• A man who was jailed now creates tools that keep young fighters off the streets.\n'
              '• A man who nearly died from addiction now builds health monitoring systems.\n'
              '• A man society called unintelligent now writes code that serves 128 countries.\n'
              '• A man who fought in car parks now connects fighters to sponsors and gyms.\n'
              '• A disabled single father with no degree built this. WITH YOUR TOOLS.\n\n'
              'I am not a Silicon Valley founder. I am not a Stanford graduate. '
              'I am a fighter from the gutters of Australia who clawed his way '
              'to a keyboard and built something that matters.\n\n'
              'That is the story of Google technology. Not just search. Not just ads. '
              'Google is the great equaliser. It doesn\'t ask where you came from. '
              'It only asks what you want to build.',
        ),

        _storyChapter(
          'CHAPTER 6',
          'THE ASK',
          _gBlue,
          Icons.handshake,
          'Google, this is what I need:\n\n'
              '• Cloud credits — so DFC can scale to millions without bankrupting a single father.\n'
              '• Ad Grants — so fighters who need this platform can find it.\n'
              '• Mentorship — so I can make this app everything it deserves to be.\n'
              '• Partnership — because I\'ve proven what one person can do with your tools.\n\n'
              'I\'m not asking for charity. I\'m asking you to invest in proof.\n\n'
              'Proof that your technology changes lives. Proof that disability doesn\'t mean inability.\n'
              'Proof that a man from the gutter can build a global platform. Proof that fighting — the sport that saved my life — can save others.\n'
              'Proof that a fighter, a promoter, a teacher, and a survivor can rise again.\n\n'
              'I was Rowdy Bec Rawlings\' first trainer. I promoted fights, fought myself, and lost everything through fake lies and defamation on social media.\n'
              'I went to jail for a crime I never committed — never convicted, but my name was destroyed.\n'
              'I have put my heart and soul into the fight game and rose from the streets and gutters where all my friends and family have fallen and died.\n'
              'I am still here, learning tech, building my painful life into passion to save others.\n'
              'I have a medical cannabis education show thanks to Google, and have empowered myself with the power of Google.\n'
              'I am deeply respectful and honoured to show my loyalty and values towards Google.\n'
              'I just need to prove this and get a shot — a chance to show a better life, world, planet, humans, and me.\n\n'
              'From the streets to code.\n'
              'From addiction to creation.\n'
              'From mental institution to app developer.\n'
              'From prison to platform.\n'
              'From single father to founder.\n'
              'From defamation to dedication.\n\n'
              'I AM the proof. Now let me prove it at scale.',
        ),
        const SizedBox(height: 16),

        // ── Life Timeline ─────────────────────────────────────────────────
        _sectionHeader(Icons.timeline, 'THE JOURNEY — TIMELINE', _amber),
        const SizedBox(height: 8),
        _timelineItem(
          'STREETS',
          'Grew up homeless. Child abuse. Poverty. No safety net.',
          _red,
          true,
        ),
        _timelineItem(
          'FIGHTING',
          'Found combat sports. Became champion from the gutters. Trained Rowdy Bec Rawlings.',
          _amber,
          true,
        ),
        _timelineItem(
          'PROMOTER',
          'Promoted fights, built community, gave others a shot.',
          _amber,
          true,
        ),
        _timelineItem(
          'ADDICTION',
          'Drugs, alcohol, mental illness. Lost everything.',
          _red,
          true,
        ),
        _timelineItem(
          'DEFAMATION',
          'Lost reputation, career, and friends to fake lies on social media.',
          _red,
          true,
        ),
        _timelineItem(
          'PRISON',
          'Jailed for a crime never committed. Met Chopper Read. Never convicted.',
          _red,
          true,
        ),
        _timelineItem(
          'ROCK BOTTOM',
          'Career over. Relationships destroyed. Life in ruins.',
          _red,
          true,
        ),
        _timelineItem(
          'GOOGLE',
          'Found YouTube, learned to code. Firebase. Flutter. AI. Medical cannabis education show.',
          _gBlue,
          true,
        ),
        _timelineItem(
          'DFC BORN',
          '50,000+ lines of code. 40+ screens. 30+ Google technologies.',
          _cyan,
          true,
        ),
        _timelineItem(
          'TODAY',
          'Disabled single father. Commercial printer by day. Coder by night. Loyal to Google.',
          _green,
          true,
        ),
        _timelineItem(
          'TOMORROW',
          'DFC serves millions. Grant funded. Global impact. Saving lives.',
          _purple,
          false,
        ),
        const SizedBox(height: 16),

        // ── Impact Numbers ────────────────────────────────────────────────
        _sectionHeader(Icons.bar_chart, 'BY THE NUMBERS', _cyan),
        const SizedBox(height: 8),
        _numberRow('Google Technologies Used', '30+', _gBlue),
        _numberRow('Firebase Services Active', '6', _orange),
        _numberRow('AI Models Integrated', '3', _purple),
        _numberRow('Lines of Dart Code', '50,000+', _cyan),
        _numberRow('Screens Built', '40+', _green),
        _numberRow('Countries Targeted', '128', _amber),
        _numberRow('Fighting Disciplines', '40+', _red),
        _numberRow('Developer Count', '1 (disabled single father)', _pink),
        _numberRow('Formal Education', 'None', _amber),
        _numberRow('Funding Received', '\$0', _red),
        _numberRow('Team Size', 'Just me', _cyan),
        _numberRow('Reason Built', 'For fighters like me', _green),
        const SizedBox(height: 16),

        // ── Google Technologies That Made This Possible ───────────────────
        _sectionHeader(
          Icons.favorite,
          'GOOGLE TECH THAT REBUILT MY LIFE',
          _gRed,
        ),
        const SizedBox(height: 8),
        _techGratitude(
          'YouTube',
          'Taught me to code when no school, university, or person would',
        ),
        _techGratitude(
          'Google Search',
          'Answered 10,000 questions at 3 AM when no one was there',
        ),
        _techGratitude(
          'Flutter',
          'Let me build for every platform alone — no team needed',
        ),
        _techGratitude(
          'Firebase',
          'Gave me a production backend a whole team couldn\'t match',
        ),
        _techGratitude(
          'Gemini AI',
          'Became the AI coach I never had as a fighter',
        ),
        _techGratitude(
          'GitHub Copilot',
          'Became the coding partner I couldn\'t afford to hire',
        ),
        _techGratitude(
          'Material Design',
          'Made my UI accessible — because I know what exclusion feels like',
        ),
        _techGratitude(
          'Google Fit',
          'Connects fighters to health data I never had access to',
        ),
        _techGratitude('Google Fit', 'Connects fighters to their health data'),
        _techGratitude(
          'Google Maps',
          'Will help every fighter find a gym near them',
        ),
        const SizedBox(height: 16),

        // ── Dedication Banner ─────────────────────────────────────────────
        _dedicationBanner(),
        // ── Closing Statement ─────────────────────────────────────────────
        _closingBanner(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  REUSABLE WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _googleLogo(double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'G',
          style: TextStyle(
            color: _gBlue,
            fontSize: size,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          'o',
          style: TextStyle(
            color: _gRed,
            fontSize: size,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          'o',
          style: TextStyle(
            color: _gYellow,
            fontSize: size,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          'g',
          style: TextStyle(
            color: _gBlue,
            fontSize: size,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          'l',
          style: TextStyle(
            color: _gGreen,
            fontSize: size,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          'e',
          style: TextStyle(
            color: _gRed,
            fontSize: size,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color col) {
    return Row(
      children: [
        Icon(icon, color: col, size: 14),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: col,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ── Banners ─────────────────────────────────────────────────────────────

  Widget _googleHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _gBlue.withAlpha(20),
            _gRed.withAlpha(15),
            _gYellow.withAlpha(15),
            _gGreen.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gBlue.withAlpha(50)),
      ),
      child: Column(
        children: [
          _googleLogo(22),
          const SizedBox(height: 4),
          const Text(
            '× DATA FIGHT CENTRAL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Every line of DFC code runs on Google technology. '
            'Firebase powers the backend. Gemini powers the AI. Flutter powers the UI. '
            'Google is not just a search engine — it\'s the foundation of a global '
            'platform that empowers fighters and communities.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(130),
              fontSize: 10,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _gBlue.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '30+ Google Technologies Mapped',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _firebaseBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_orange.withAlpha(20), _amber.withAlpha(15)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _orange.withAlpha(50)),
      ),
      child: Column(
        children: [
          const Icon(Icons.local_fire_department, color: _orange, size: 28),
          const SizedBox(height: 6),
          const Text(
            'FIREBASE — DFC\'S BACKBONE',
            style: TextStyle(
              color: _orange,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Firebase replaces an entire engineering team. Auth, database, storage, '
            'functions, analytics, hosting — all managed by Google, all auto-scaling, '
            'all secure. One developer can build what used to take twenty.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(130),
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gcpBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gBlue.withAlpha(20), _cyan.withAlpha(15)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gBlue.withAlpha(50)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud, color: _gBlue, size: 28),
          const SizedBox(height: 6),
          const Text(
            'GOOGLE CLOUD PLATFORM',
            style: TextStyle(
              color: _gBlue,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The same infrastructure that powers Google Search, YouTube, and Gmail. '
            'DFC runs on Google\'s global network of data centres — 99.99% uptime, '
            'auto-scaling, and enterprise-grade security.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(130),
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_purple.withAlpha(20), _cyan.withAlpha(15)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _purple.withAlpha(50)),
      ),
      child: Column(
        children: [
          const Icon(Icons.psychology, color: _purple, size: 28),
          const SizedBox(height: 6),
          const Text(
            'GOOGLE AI — HIGH INTELLIGENCE',
            style: TextStyle(
              color: _purple,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Google\'s AI is the most advanced on Earth. Gemini, Vertex AI, Vision AI, '
            'Speech AI, Translation AI, TensorFlow — every intelligence layer is available '
            'to DFC. A single developer with Google AI is more powerful than a team of 100.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(130),
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _founderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _red.withAlpha(15),
            _amber.withAlpha(10),
            _cyan.withAlpha(10),
            _green.withAlpha(15),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withAlpha(50)),
      ),
      child: Column(
        children: [
          const Text(
            'FROM THE GUTTER TO CODE',
            style: TextStyle(
              color: _cyan,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Streets. Prison. Addiction. Champion. Developer.',
            style: TextStyle(
              color: _amber.withAlpha(180),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This is the true story of a homeless street fighter, wrongfully jailed, '
            'who battled addiction, mental illness, and poverty — then found Google\'s '
            'tools and built a platform that serves fighters in 128 countries. '
            'No degree. No funding. No team. Just a disabled single father with a laptop.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(130),
              fontSize: 10,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dedicationBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_amber.withAlpha(30), _gBlue.withAlpha(15)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amber.withAlpha(50)),
      ),
      child: Column(
        children: [
          const Icon(Icons.volunteer_activism, color: _amber, size: 28),
          const SizedBox(height: 6),
          const Text(
            'DEDICATED TO EVERYONE WHO FELL',
            style: TextStyle(
              color: _amber,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This journey is for my friends, family, and fighters who never made it out.\n'
            'For those lost to the streets, addiction, violence, and lies.\n'
            'For those who never got a second chance.\n'
            'For those who were never believed.\n'
            'For those who still fight, in any way they can.\n\n'
            'And for Google — for giving me the tools to turn pain into purpose,\n'
            'and for giving me a shot to prove that one life can change many.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _closingBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _red.withAlpha(12),
            _amber.withAlpha(10),
            _cyan.withAlpha(10),
            _green.withAlpha(12),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withAlpha(50)),
      ),
      child: Column(
        children: [
          _googleLogo(18),
          const SizedBox(height: 8),
          const Text(
            'YOUR TECHNOLOGY REBUILT MY LIFE',
            style: TextStyle(
              color: _green,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'I am living proof.\n\n'
            'From sleeping in the gutter to writing code.\n'
            'From prison to building a platform.\n'
            'From addiction to creation.\n'
            'From street fighter to app developer.\n'
            'From the world calling me unintelligent to 50,000+ lines of code.\n'
            'From single father with nothing to founder with a mission.\n\n'
            'Google didn\'t just give me tools — it gave me a second life.\n'
            'Now I\'m building something that gives fighters theirs.\n\n'
            'Every fighter deserves what I never had.\n'
            'A platform. A community. A chance.\n\n'
            'Let\'s do this together.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(140),
              fontSize: 10,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _cyan.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cyan.withAlpha(40)),
            ),
            child: const Text(
              'REPOWER HUMANITY',
              style: TextStyle(
                color: _cyan,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Grid ─────────────────────────────────────────────────────────

  Widget _statusGrid(List<_GStatus> items) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1.1,
      children: items
          .map(
            (i) => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: i.color.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: i.color.withAlpha(i.active ? 50 : 25),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(i.icon, color: i.color, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    i.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withAlpha(i.active ? 200 : 100),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: (i.active ? _green : _amber).withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      i.active ? 'ACTIVE' : 'PLANNED',
                      style: TextStyle(
                        color: i.active ? _green : _amber,
                        fontSize: 6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Service Cards ───────────────────────────────────────────────────────

  Widget _firebaseService(
    String name,
    IconData icon,
    Color col,
    String status,
    List<String> details,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(40)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: col.withAlpha(25),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: col, size: 16),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          status,
          style: TextStyle(
            color: status == 'ACTIVE' ? _green : _amber,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconColor: col,
        collapsedIconColor: col.withAlpha(120),
        children: details
            .map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      d.startsWith('DFC Use:')
                          ? Icons.sports_mma
                          : Icons.check_circle,
                      color: d.startsWith('DFC Use:') ? _cyan : col,
                      size: 11,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d,
                        style: TextStyle(
                          color: d.startsWith('DFC Use:')
                              ? _cyan.withAlpha(200)
                              : Colors.white54,
                          fontSize: 10,
                          fontWeight: d.startsWith('DFC Use:')
                              ? FontWeight.w700
                              : FontWeight.normal,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _gcpService(
    String name,
    IconData icon,
    Color col,
    String desc,
    List<String> dfcUses,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(35)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        leading: Icon(icon, color: col, size: 20),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconColor: col,
        collapsedIconColor: col.withAlpha(120),
        children: [
          Text(
            desc,
            style: TextStyle(
              color: Colors.white.withAlpha(120),
              fontSize: 10,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          ...dfcUses.map(
            (u) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.sports_mma, color: _cyan, size: 11),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      u,
                      style: TextStyle(
                        color: _cyan.withAlpha(200),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiService(
    String name,
    IconData icon,
    Color col,
    String status,
    List<String> capabilities,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(40)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: col.withAlpha(25),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: col, size: 16),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          status,
          style: TextStyle(
            color: status.contains('ACTIVE') ? _green : _amber,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconColor: col,
        collapsedIconColor: col.withAlpha(120),
        children: capabilities
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome, color: col, size: 11),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _grantCard(
    String name,
    String value,
    Color col,
    IconData icon,
    List<String> benefits,
    String status,
  ) {
    final statusColor = status == 'ACTIVE'
        ? _green
        : status == 'APPLYING'
        ? _amber
        : _blue;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(50)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: col.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: col, size: 18),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: col,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        iconColor: col,
        collapsedIconColor: col.withAlpha(120),
        children: benefits
            .map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: col, size: 11),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _platformCard(
    String name,
    IconData icon,
    Color col,
    List<String> features,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(35)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        leading: Icon(icon, color: col, size: 20),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconColor: col,
        collapsedIconColor: col.withAlpha(120),
        children: features
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: col, size: 11),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Story Chapter ───────────────────────────────────────────────────────

  Widget _storyChapter(
    String num,
    String title,
    Color col,
    IconData icon,
    String text,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: col.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: col, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    num,
                    style: TextStyle(
                      color: col.withAlpha(150),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: col,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withAlpha(140),
              fontSize: 11,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ── Number Rows ─────────────────────────────────────────────────────────

  Widget _numberRow(String label, String value, Color col) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.withAlpha(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          Text(
            value,
            style: TextStyle(
              color: col,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _techGratitude(String tech, String reason) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gBlue.withAlpha(15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('❤️ ', style: TextStyle(fontSize: 12)),
          SizedBox(
            width: 70,
            child: Text(
              tech,
              style: const TextStyle(
                color: _gBlue,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              reason,
              style: TextStyle(
                color: Colors.white.withAlpha(120),
                fontSize: 9,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(String label, String desc, Color col, bool completed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? col : Colors.transparent,
              border: Border.all(color: col, width: 2),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: col,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                color: Colors.white.withAlpha(completed ? 130 : 180),
                fontSize: 9,
                fontWeight: completed ? FontWeight.normal : FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
          if (!completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: col.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'NEXT',
                style: TextStyle(
                  color: col,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PRIVATE DATA CLASS
// ─────────────────────────────────────────────────────────────────────────────

class _GStatus {
  final String name;
  final IconData icon;
  final Color color;
  final bool active;
  final String desc;
  const _GStatus(this.name, this.icon, this.color, this.active, this.desc);
}
