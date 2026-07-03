# DataFightCentral — Platform Overview

_What DFC is, what it does, and what's been built._

---

## What Is DataFightCentral?

DataFightCentral (DFC) is a multi-platform combat sports super-app built on Flutter (Web, iOS, Android, Windows, macOS). It combines fighter management, social engagement, pay-per-view distribution, AI coaching, health tracking, content creation, and live event infrastructure into one platform — specifically designed for the MMA, boxing, bare-knuckle, brawling, and broader combat sports ecosystem.

DFC serves every role in the fight industry: fighters, coaches, promoters, sponsors, gyms, fans, and creators — each with dedicated tooling, dashboards, and monetization paths.

## Promoter-First Operating Model

DFC does not compete with promotions. DFC promotes promotions.

The platform should treat every serious event as a canonical commercial object with real metadata, real artwork, real ticket or PPV pathways, and real replay value. That standard applies to major promotions and to regional shows that usually get ignored by larger platforms.

Strategic reference documents:

- `docs/DFC_STREAMING_DOCTRINE_V1.md`
- `docs/DFC_CANONICAL_EVENT_GRAPH_V1.md`
- `docs/DFC_LEADERSHIP_ARCHITECTURE_BRIEF.md`
- `docs/DFC_BETAVERSE_DOCTRINE.md`

---

## Architecture

| Layer                | Technology                                                                                   |
| -------------------- | -------------------------------------------------------------------------------------------- |
| **Frontend**         | Flutter (Dart), multi-platform — Web (Chrome), iOS, Android, Windows, macOS                  |
| **State Management** | Provider + ChangeNotifier                                                                    |
| **Routing**          | GoRouter v17                                                                                 |
| **Backend**          | Firebase — Firestore, Cloud Functions (Node 20, v2 API), Auth, Storage, Analytics, Messaging |
| **Payments**         | Stripe (Payment Intents, Checkout, Subscriptions, Connect Express)                           |
| **Region**           | australia-southeast1                                                                         |
| **CI/CD**            | Azure Pipelines (azure-pipelines.yml)                                                        |

**Codebase scale:**

| Metric                   | Count           |
| ------------------------ | --------------- |
| Feature modules          | 67              |
| Shared services          | 157             |
| Data models              | 37+             |
| Cloud Functions          | 21              |
| Home screen tabs         | 8               |
| Firestore security rules | 50+ collections |
| Documentation files      | 50+             |
| Dependencies             | 40+ core        |

---

## Home Screen — 8-Tab Navigation

The main UI is an `IndexedStack` with lazy-loaded tabs, bottom navigation (`DFCBottomNav`), a side drawer (`DFCNavDrawer`), a floating `DFCOrb` assistant, ambient background planets, and a logo backdrop.

| Tab              | Screen                | What It Does                                                                                                                                                                              |
| ---------------- | --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Dashboard**    | Premium2026Dashboard  | KPIs, fighter stats, combat pulse, performance science, AI head coach, owner dashboard, command center — 17 dashboard views total                                                         |
| **Feed**         | DFCFeedScreen         | Social timeline — posts, shares, clips, sponsored content, fight reactions. 14 social screens (compose, post details, friends list, friend requests, member directory, upload clip, etc.) |
| **Explore**      | ExploreScreen         | Discovery engine — recommended fighters, events, content, trending topics                                                                                                                 |
| **FightWire**    | FightWireMasterScreen | News aggregation from UFC.com, ESPN MMA, Ring TV, ONE Championship, and combat media channels                                                                                             |
| **Training**     | TrainingMasterScreen  | Training sessions, periodization, camp logistics, AI readiness analysis                                                                                                                   |
| **Wellness**     | WellnessMasterScreen  | Health metrics, biometrics, recovery, hydration, body monitoring, sleep integration (NiteChill)                                                                                           |
| **Creative Hub** | CreativeHubScreen     | Content creation tools, video editing, fight card design, AI image generation                                                                                                             |
| **Profile**      | ProfileScreen         | User settings, identity verification, subscription management, consent records                                                                                                            |

---

## Feature Modules (67 Domains)

Organized under `lib/features/` by domain:

**Core Platform:** home, dashboard, auth, onboarding, profile, settings, account, splash, landing, notifications

**Fight Industry:** fighter, fighter_profile, fighter_analytics, fighter_card, fight_card, fight_camp, fight_pipe, matchmaking, scoring, rankings, databank, events, fightlab

**Social & Community:** social (14 screens), community, messaging, discovery, fan_zone

**Content & Media:** creative_hub, creator, creator_studio, fightwire, media_center, image_gen, drone, drone_racing

**Health & Performance:** training, wellness, health, astrohealth, mind_body_soul, recovery_access, performance, metrics, devices

**Revenue & Business:** marketplace, ppv, passes, subscription, donation, donations, monetization, sponsorship, partnership, partner_portal, promoter, promotion

**Operations & Admin:** admin, analytics, operations, safety, legal, verification, support, tasker, work, submit

**AI & Intelligence:** ai_brain, genie, intellect, coach, cmo_da

**Specialty:** earthmap, google_earth, maps, nasa, nanotech, nitechill, fempower, ibc, run_it, growth, cards, action, engine, opportunity

---

## Service Layer (157 Services)

All services export through a single barrel at `lib/shared/services/services.dart`. Key domains:

### Authentication & Identity

- **AuthService** — Firebase Auth, registration, consent logging, onboarding flags, demo mode toggle
- **IdentityVerificationService** — ID verification pipeline
- **DFCSecurityService** — Security monitoring and threat detection

### Payment Pipeline (Stripe)

- **StripePaymentEngine** — Core Stripe integration (Payment Intents, customer creation, refunds)
- **StripeConnectService** — Stripe Connect Express for promoter direct payouts (sliding 30-50% DFC platform fee)
- **PPVService** — Pay-per-view event purchasing with atomic access grants
- **SubscriptionService** — Tiered subscription billing (Supporter, Pro, Elite)
- **PaymentsService** — General payment processing
- **CreatorPayoutEngine** — Creator earnings and payout scheduling
- **InvoiceGenerationService** — Invoice creation and management
- **MultiCurrencyEngine** — Multi-currency payment support
- **QuickPaymentService** — Fast checkout flows

### Feed Architecture (8 Engines)

- **AutoFeedOrchestratorService** — Cross-source normalization and ingestion
- **FeedRankingEngine** — Intelligent content ranking
- **FeedPrioritizationService** — Priority sorting
- **FeedCacheService** — Caching layer
- **FightWireFeedService** — News-specific feed
- **FeedPipelineAuditService** — Audit trail
- **ContentPipelineService** — Content ingestion
- **SourceTrustRulesService** — Trust validation for external sources

### AI & Coaching

- **AICoachService** — AI coaching personality
- **CornerVoiceService** — Real-time corner voice synthesis
- **AIEsoEngineService** — Emotional state optimization
- **CombatIntelligenceEngine** — Fight analysis AI
- **SamuraiService / SamuraiOrchestrator / SamuraiCoreEngine** — Core AI reasoning
- **SamuraiSwarmCoordinator** — Multi-agent hive mind (53 agents, 25 engines)
- **AIModerationService** — Content moderation AI
- **NinjaModerationService** — Ninja-branded moderation layer

### Fighter & Combat

- **FighterService** — Fighter CRUD and profiles
- **FighterAnalytics** — Stats and performance data
- **FightMatcherService** — Matchmaking algorithm (MMA, Boxing, Bare Knuckle, BKFC, Brawling)
- **MatchmakingService** — Advanced matchmaking
- **FightCampService** — Training camp logistics
- **FightCardTemplateService** — Fight card design templates
- **FightNewsService** — News aggregation

### Social & Community

- **SocialService** — Post creation, timeline, reactions
- **DFCSocialEngine** — Social AI engine
- **SocialConnectorService** — External platform integrations
- **EnhancedFriendsService** — Friend discovery and recommendations
- **FriendService** — Friend management
- **RelationshipsService** — Social graph
- **FriendSuggestionsEngine** — Recommendation algorithm

### Health & Performance

- **HealthIntelligenceEngine** — Health AI analysis
- **SportsScienceEngine** — Athlete performance optimization
- **BiometricDataService** — Wearable sensor data
- **BodyMonitorService** — Continuous body metrics
- **DailyGrindService** — Daily activity tracking
- **HydrationService** — Hydration monitoring
- **FitbitService** — Fitbit integration
- **DFCHealthEngine** — Self-healing health watchdog
- **SmartDeviceService** — Wearable ecosystem

### Media & Content

- **VideoService** — Video upload and streaming
- **GeminiImageService** — AI image generation (Google Gemini)
- **EnhancedCardImageService** — Fight card imagery
- **MediaUploadService** — File upload pipeline
- **SamuraiContentTransformer** — AI content transformation
- **ContentProtectionEngine** — DRM and content protection
- **ContentPublisherService** — Publishing workflows
- **ContentRotationEngine** — Content freshness management

### Streaming

- **DFCStreamingEngine** — HLS/DASH live streaming infrastructure

### Events & Marketplace

- **EventsService / EventManagerService** — Event CRUD and orchestration
- **CanonicalEventGraphService** — Resolves canonical event identity, approved artwork, and PPV linkage across event surfaces
- **FightMarketplaceService** — PPV and ticket marketplace
- **EventPromoCardService** — Promotional card generation
- **PromotionService** — Campaign management
- **SponsorshipService** — Sponsor deal management

### Marketing & Growth

- **MarketingAIService** — Marketing optimization
- **CampaignService** — Campaign management
- **ABTestService** — A/B testing
- **AdsService** — Ad serving
- **SponsorFeedEngine** — Sponsored content
- **MetaverseAdCampaignEngine** — Metaverse advertising

### External Integrations

- **YouTubeService** — YouTube API
- **TwitterService** — Twitter/X integration
- **NASAApiService** — NASA data feeds
- **MetaService / MetaContentService** — Meta/Facebook
- **NiteChillIntegrationService** — Sleep/recovery brand

### Security & Compliance

- **TrustSafetyService** — Trust and safety policies
- **ContentSafetyService** — Safety filters
- **ContentScannerEngine** — Content scanning
- **LegalComplianceService** — Legal/regulatory compliance

### Maps & Location

- **MapsService** — Google Maps integration
- **LocationService** — GPS/geolocation
- **MarineSafetyService** — Ocean/marine safety monitoring

### Infrastructure

- **PerformanceOptimizer** — Caching and performance
- **BeastModeService** — Performance turbo mode
- **BundleCacheService** — Intelligent asset caching
- **RealtimeNotificationEngine** — Real-time push
- **AnalyticsService** — Firebase Analytics wrapper
- **DiscoveryService** — Content discovery algorithm
- **FighterTravelPackageService** — Travel logistics for fighters

---

## Cloud Functions (21 Endpoints)

All deployed to `australia-southeast1`, Node 20, Firebase Functions v2 API.

### Payment & Billing

| Function                 | Type     | Purpose                                                                                    |
| ------------------------ | -------- | ------------------------------------------------------------------------------------------ |
| `createPaymentIntent`    | Callable | Stripe Payment Intent with Connect routing (auto-detects promoter, sliding 30–50% DFC fee) |
| `createStripeCustomer`   | Callable | Register Stripe customer                                                                   |
| `createStripeCheckout`   | Callable | Hosted checkout session                                                                    |
| `createRefund`           | Callable | Process refund                                                                             |
| `cancelSubscription`     | Callable | Cancel subscription                                                                        |
| `restorePurchases`       | Callable | Restore previous purchases                                                                 |
| `syncSubscriptionStatus` | Callable | Sync subscription state → Firestore                                                        |

### Stripe Connect (Promoter Payouts)

| Function                    | Type     | Purpose                                                            |
| --------------------------- | -------- | ------------------------------------------------------------------ |
| `createConnectedAccountV2`  | Callable | Create Stripe Connect V2 account for promoter                      |
| `createAccountLink`         | Callable | Generate Stripe-hosted onboarding link                             |
| `getConnectedAccountStatus` | Callable | Query Connect V2 onboarding and capability status                  |
| `createConnectAccount`      | Callable | Compatibility alias for older clients; now routes to V2 onboarding |
| `createConnectLoginLink`    | Callable | Legacy Express-only dashboard link                                 |

### Stripe Webhook

| Event                           | Handler                                                                  |
| ------------------------------- | ------------------------------------------------------------------------ |
| `checkout.session.completed`    | Activate subscription, write Firestore                                   |
| `customer.subscription.updated` | Sync plan changes                                                        |
| `customer.subscription.deleted` | Revoke access                                                            |
| `invoice.payment_failed`        | Dunning event, notify user                                               |
| `charge.succeeded`              | PPV access grant (atomic batch: access doc + transaction + viewer count) |
| `charge.failed`                 | Log failed transaction                                                   |
| `charge.refunded`               | Revoke PPV access, log refund                                            |
| `account.updated`               | Sync Connect onboarding status                                           |

Webhook includes **idempotency** via `webhook_events/{eventId}` collection — duplicate events are rejected.

### AI & Data

| Function                   | Purpose                                                              |
| -------------------------- | -------------------------------------------------------------------- |
| `getFightNewsFeed`         | Aggregated fight news (UFC.com, ESPN MMA, Ring TV, ONE Championship) |
| `listFighters`             | Query fighter database                                               |
| `getFighterStats`          | Get fighter statistics                                               |
| `upsertFighterStats`       | Create/update fighter stats                                          |
| `analyzeTrainingReadiness` | AI training readiness assessment                                     |
| `cornerVoiceLive`          | Real-time AI corner coach                                            |
| `aiHello`                  | AI greeting/test                                                     |

### Scheduled Jobs

| Function                    | Purpose                     |
| --------------------------- | --------------------------- |
| `ninjaGuardianDaily`        | Daily system health check   |
| `ninjaGuardianHarmonyCheck` | Periodic harmony validation |

---

## Stripe Connect — Promoter Direct Payouts

The payment model uses **Stripe Connect V2** so promoters receive money directly into their own Stripe account, with DFC automatically collecting a **sliding 30-50% platform fee** based on event exposure (buy count). Higher exposure = higher DFC share.

**Flow:**

1. Promoter calls `createConnectedAccountV2` and `createAccountLink` or the compatibility alias `createConnectAccount`
2. Stripe fires Connect V2 events → `stripeConnectWebhook` syncs status to `connected_accounts_v2/{promoterId}`
3. When a fan buys a PPV, checkout logic checks if the event's promoter has a connected account
4. If yes: money routes to promoter via `transfer_data.destination` with `application_fee_amount` (sliding 30-50%)
5. If promoter hasn't onboarded yet: falls back to DFC-collects model (money goes to DFC, manual settlement)

**Three-party guarantee:** Stripe holds the funds in escrow between fan → promoter → DFC, with Stripe's own dispute resolution and fraud protection.

---

## Firestore Security Rules

50+ collection rules with helper functions:

```
isAuthenticated(), isOwner(userId), isAdmin(), isPromoter(),
isHeadAdmin(), hasRole(role), isAdminOrOwner(userId)
```

Protected collections include: users, fighters, events, posts, gyms, rankings, health_logs, notifications, messages, onboarding, ppv_events, ppv_purchases, ppv_access, payment_intents, transactions, refunds, webhook_events, stripe_customers, connected_accounts, connected_accounts_v2, creator_earnings_ledger, payout_history, payout_schedules, tax_profiles, streams, stream_sessions, vod_assets, invoices, and more.

---

## Data Models (37+)

**Core:** UserModel, FighterModel, FightModel, UserRelationship, FriendModel
**Events:** EventModel, EventManagerModel, BoutSlotModel, BoutOfferModel
**Social:** PostModel, FightWirePost, CommunityModels, CampaignModel
**Payments:** PPVModel, SubscriptionPlan, SubscriptionStatus, SponsorshipModel
**Health:** HealthMetricsModel, CombatStats, AnalyticsModel
**System:** NotificationModel, ConsentModel, VerificationModel, AgentRoleRegistry
**Specialized:** JobModel, GymModel, RankingModel, CulturalProfileModel, FightCardTemplate

All models extend `Equatable` and use Firestore-compatible `toMap()`/`fromMap()` serialization.

---

## Security Posture

Hardened in this build cycle:

- **Webhook idempotency** — duplicate Stripe events rejected via `webhook_events` collection
- **Atomic batch writes** — PPV purchases use Firestore batches (access grant + transaction + viewer count in one atomic operation)
- **Access gating** — PPV content checks `ppv_access/{eventId}__{userId}` before serving
- **Query limits** — all Firestore queries capped with `.limit()` to prevent runaway reads
- **Environment variables** — all secrets use `String.fromEnvironment()` / `defineSecret()` (no hardcoded keys)
- **Error logging** — all catch blocks log via `debugPrint` (no silent failures)
- **Compound indexes** — 9 Firestore compound indexes for efficient queries
- **Firestore rules** — role-based access control on every collection
- **Content safety** — AI moderation + content scanner + trust/safety service
- **OWASP alignment** — injection prevention, auth validation, access control enforcement

---

## What DFC Covers by Role

| Role         | What They Get                                                                                                                     |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| **Fighter**  | Profile, stats dashboard, matchmaking, training camp, health/biometrics, rankings, travel packages, AI coaching, content creation |
| **Coach**    | AI corner voice, training periodization, performance science, fighter analytics, camp management                                  |
| **Promoter** | Event management, PPV distribution, Stripe Connect direct payouts, fight card builder, promotional tools, analytics               |
| **Sponsor**  | Sponsorship management, ad campaigns, branded content, A/B testing, engagement metrics                                            |
| **Fan**      | Social feed, PPV purchases, FightWire news, explore/discovery, friend network, subscriptions, gamification                        |
| **Gym**      | Gym profile, fighter roster, training scheduling, device integrations                                                             |
| **Creator**  | Creative hub, video tools, AI image generation, content publishing, payout engine                                                 |
| **Admin**    | Command center, moderation tools, security monitoring, compliance dashboard                                                       |

---

## AI Systems

DFC integrates multiple AI layers:

- **Samurai Swarm** — Multi-agent coordinator (53 agents, 25 engines) for distributed AI reasoning
- **Combat Intelligence Engine** — Fight analysis and prediction
- **AI Coach / Corner Voice** — Real-time coaching personality with voice synthesis
- **ESO Engine** — Emotional state optimization for athlete mental performance
- **Health Intelligence** — AI-driven health monitoring and alerts
- **Marketing AI** — Campaign optimization and audience targeting
- **Content Moderation** — Automated content scanning and safety filtering
- **Feed Ranking** — Intelligent content prioritization based on engagement signals
- **Friend Suggestions** — Social graph recommendation engine
- **Gemini Image Service** — AI-powered image generation via Google Gemini

---

## External Integrations

| Integration       | Purpose                                                   |
| ----------------- | --------------------------------------------------------- |
| **Stripe**        | Payments, subscriptions, Connect Express, webhooks        |
| **Firebase**      | Auth, Firestore, Functions, Storage, Analytics, Messaging |
| **Google Maps**   | Location services, gym/event mapping, Earth visualization |
| **YouTube**       | Video embedding, fight content                            |
| **Twitter/X**     | Social connector                                          |
| **Meta/Facebook** | Social connector, content sync                            |
| **Fitbit**        | Wearable health data                                      |
| **NASA**          | Earth/space data feeds                                    |
| **Apple Sign-In** | iOS SSO                                                   |

---

## Deployment Status

| Item              | Status                                    |
| ----------------- | ----------------------------------------- |
| Flutter analyze   | **Zero issues**                           |
| Flutter build web | **Success**                               |
| Firestore rules   | **Written — ready to deploy**             |
| Firestore indexes | **9 compound indexes defined**            |
| Cloud Functions   | **21 functions — ready to deploy**        |
| Stripe Connect    | **Built — needs Dashboard configuration** |
| Branch            | `datafight-master-2` (PR #4 open)         |
| Repository        | DIRTYBOXING/Data-Fight-Central            |

### Remaining Deploy Steps

1. Set Firebase environment secrets: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PRICE_SUPPORTER`, `STRIPE_PRICE_PRO`, `STRIPE_PRICE_ELITE`
2. Run: `firebase deploy --only functions,firestore:rules,firestore:indexes`
3. Configure Stripe webhook URL + events in Stripe Dashboard
4. Enable Stripe Connect Express in Stripe Dashboard settings
5. Configure Google Sign-In OAuth credentials (currently stubbed)

---

## Documentation Library (50+ Files)

Architecture, deployment, setup, legal (ToS, privacy policy, disclaimers), partnership agreements, PPV guides, incident response playbooks, monetization strategies, grant applications, SEO strategies, campaign guides, community guidelines, and video production scripts — all under `docs/`.

---

_Built with Flutter 3.10+ | Firebase | Stripe | Dart SDK >=3.10.0 | Node 20_
