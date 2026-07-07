## DataFightCentral (DFC) — Global Combat-Sports Operating System

DataFightCentral is building a production-grade operating system for combat sports: events, PPV, creator economy, coaching intelligence, and community infrastructure in one governed platform.

### Why DFC matters

- Expands access to opportunity through technology, engineering, and open collaboration
- Supports fighters, gyms, promoters, creators, and fans with real platform infrastructure
- Uses strict quality/security/reliability controls to deliver trustworthy outcomes at scale

### Architecture pillars

- **Google (runtime):** Firebase + GCP backend, data plane, and cloud AI services
- **GitHub (governance):** Source of truth, CI/CD, branch protection, quality gates
- **NVIDIA (acceleration):** Advanced compute/simulation path for future intelligence workloads
- **MCP (local tooling):** Local AI integration layer for engineering productivity (non-runtime)

### Enterprise docs index

- `docs/DFC_PLATFORM_MASTER_MAP.md`
- `docs/DFC_ENTERPRISE_ROADMAP.md`
- `docs/DFC_PLATFORM_GOVERNANCE.md`
- `docs/DFC_MCP_ARCHITECTURE_MAP.md`
- `docs/DFC_MCP_SERVER_COMPARISON_TABLE.md`
- `docs/DFC_DEVELOPER_ONBOARDING.md`
- `docs/DFC_OPERATOR_QUICK_CARD.md`
- `docs/QUALITY_GATE_SETUP.md`
- `docs/CLINE_USAGE_POLICY.md`
- `docs/CLINE_FREE_MODE_SETUP.md`

### Contribute to DFC

We welcome engineers, researchers, and operators who want to build reliable systems for global combat-sports infrastructure.

- Open issues and PRs with clear module scope and validation proof
- Follow routing spine, rule-pack, and CI gate requirements
- Prioritize production-safe, reviewable, incremental changes

### Sponsor DFC

If your organization supports platform access, athlete opportunity, and responsible AI infrastructure, we welcome sponsorship and technical collaboration.

- Sponsor core platform reliability and open-source operations
- Support AI/analytics innovation for coaching, safety, and event intelligence
- Partner on global scaling and ecosystem development

## Payments & Ads Setup

This sprint adds a clear path to wire subscriptions (Stripe/Google Pay/Apple Pay/PayPal) and ads (AdMob) to the existing `SubscriptionService`, `AdsService`, and Firestore seed data.

### Providers

- Stripe: Web + Android/iOS via official SDKs (Payments + Billing). Use Stripe Checkout or PaymentSheet for a fast MVP; later move to Billing customer portal for upgrades/cancellations.
- Google Pay / Apple Pay: Surface as payment methods through Stripe or respective platform SDKs; unify flows in `SubscriptionService.subscribeWithProvider()`.
- PayPal: Optional add-on via Checkout SDK for web. Treat as a separate provider in `PaymentProvider`.
- AdMob: Initialize on mobile/web where supported and map placements via `AdsService`.

### Data Model & Firestore

- `subscription_plans`: Seeded by `DatabaseSeeder` (weekly/fortnightly/monthly) with `price`, `currency`, `features`, and `providerProductId` per platform.
- `user_entitlements`: Write an entitlement record post-payment with fields `{ userId, planId, provider, status, period, startedAt, renewsAt }`.
- `users.subscriptionStatus`: Cache current entitlement for fast gating; update on webhook/SDK callbacks.

### Client Wiring (MVP)

1. Build plan selection UI (done) and call `SubscriptionService.subscribeWithProvider(plan, provider)`.
2. For Stripe:
   - Web: Create Checkout Session from Cloud Functions, redirect, then handle success/cancel. Alternatively use Payment Element on-site.
   - Mobile: Use PaymentSheet. Confirm payment, then call backend to grant entitlement.
3. For Google/Apple Pay: Use as payment method inside Stripe or native SDKs; map the resulting transaction to entitlement write.
4. Write entitlement to Firestore and refresh profile: `authService.refreshUserProfile()`.
5. Gate features/tabs off `SubscriptionStatus` and entitlement.

### Server Hooks

- Cloud Functions: Implement `createCheckoutSession`, `handleWebhook` (Stripe events: `checkout.session.completed`, `invoice.payment_succeeded`, `customer.subscription.updated`) and entitlement reconciliation.
- Security: Validate signatures (Stripe webhook secret), verify user ownership, and use least privileges.

### Testing

- Stripe: Use test mode; common cards like `4242 4242 4242 4242` (any future expiry, any CVC, any ZIP) and 3DS flows.
- Webhooks: Use `stripe listen` in dev, forward to Functions emulator or deployed endpoint.
- Entitlements: Verify Firestore writes and UI gates; simulate upgrade/downgrade/cancel.

### Ads (Phase-In)

- Initialize SDK on supported platforms and call `AdsService.initialize()`.
- Map `AdPlacement` → unit IDs via `AdsService.configureAdUnit()`.
- Respect subscriptions: disable ads for paid tiers.

### Sprint Checklist

- [ ] Implement Stripe Functions endpoints + webhook handling
- [ ] Wire `SubscriptionService.subscribeWithProvider()` to backend endpoints
- [ ] Add entitlement gates across dashboard/features
- [ ] AdMob: SDK init + placement rendering, subscription-aware
- [ ] Update docs/IMPLEMENTATION_SUMMARY.md with payments/ads status

# DataFightCentral Platform Overview

Welcome to DataFightCentral, the all-in-one operating system for combat sports.

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/DIRTYBOXING/Data-Fight-Central&cloudshell_tutorial=.cloudshell/tutorial.md&cloudshell_open_in_editor=lib/main.dart)

## Features

- **Social Combat Network:** Connect with fighters, coaches, and fans.
- **Health & Performance Hub:** Track your training and recovery with Google Fit integration.
- **Fight Analytics & Rankings:** Dive deep into fight data and rankings.
- **AI Systems:** Get AI-assisted insights into matchups and training.

## Pro Plugins & Extensions

- **Observability:** `sentry_flutter` + Firebase Crashlytics for error tracking.
- **State & DI:** `riverpod` or `provider` (current) with `flutter_lints` strict.
- **Design System:** `flutter_animate`, `rive` for polished micro-interactions.
- **Performance:** `cached_network_image`, `flutter_cache_manager` for assets.
- **Payments:** `stripe_sdk`, `pay` (Google/Apple), `paypal_sdk` planned.
- **Ads:** `google_mobile_ads` wired via `AdsService` placements.
- **Testing:** `golden_toolkit` for UI snapshots; `mocktail` for service stubs.
- **Security:** App Check + Firestore Rules maintained in `firestore.rules`.

VS Code extensions: Dart, Flutter, Firebase, GitLens, Error Lens, Prettify JSON.

## AI Coach Accuracy

- Local rules engine: risk scoring based on sleep, hydration, stress, HR, pain.
- Model-backed analysis: Cloud Function `analyzeTrainingReadiness` (Gemini via Genkit) returns summary and readiness score; client maps to `RiskLevel` and recommendations.
- Safety rules: no diagnosis, no push-through-pain, calm/supportive tone, suggest human support as needed.

- **Promotion & Marketplace:** A hub for gyms, sponsors, and event promoters.
- **Maps & Discovery:** Find gyms, events, and fighters near you.

## Getting Started

To get started with the DataFightCentral app, follow the `SETUP_GUIDE.md`.

For backend AI and Cloud Functions authentication, see [docs/DEVELOPER_SETUP.md](docs/DEVELOPER_SETUP.md).

## Operations Runbook (Secrets + Poster Pipeline)

### Secret Rotation Workflow

1. Download the latest Firebase service-account JSON to `Downloads`.
2. Run the task `DFC: Recreate Auto-Clip Worker (with secrets copy)` or:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.vscode\scripts\recreate-worker.ps1
```

This flow copies the newest key into `.secrets/dfc-firebase-credentials.json`, pushes it into the `dfc-secrets` named Docker volume via `docker cp`, recreates `auto-clip-worker`, and fails fast if Firebase cannot initialize.

### On-call Verification Checklist

- `docker ps --filter name=auto-clip-worker --format "table {{.Names}}\t{{.Status}}"` includes `(healthy)`.
- `docker logs data-fight-central-auto-clip-worker-1 --tail 50` includes `firebase_initialized` and excludes `firebase_init_failed`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\.vscode\scripts\smoke-tests.ps1` passes all checks.
- GitHub Actions workflow `secret-scan` is green on PRs and master pushes.

### Fresh Machine One-liner (Local Bring-up)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.vscode\scripts\recreate-worker.ps1; docker-compose build predictor feeder-worker poster-service auto-clip-worker; docker-compose up -d db redis predictor feeder-worker poster-service auto-clip-worker; $env:DATABASE_URL='postgresql://dfc_admin:dfc-local-postgres-change-me@localhost:5432/dfc'; python scripts/seed-events.py; powershell -NoProfile -ExecutionPolicy Bypass -File .\.vscode\scripts\smoke-tests.ps1
```

### Poster Service

`services/poster` now runs a Puppeteer-based generator (Chromium + HTML template) and keeps the same API contract:

- `POST /generate` returns `storage_path` and `cdn_url`.
- `GET /posters/{fileName}` serves rendered PNG assets.
- `GET /health` reports service readiness.

## Documentation

- `SETUP_GUIDE.md`: Complete installation instructions.
- `DEPLOYMENT.md`: Guide for deploying to the Play Store and App Store.
- `PRIVACY_POLICY.md`: Our full legal privacy policy.
- `DATA_MODELS.md`: Documentation for all 14 data models.
- `IMPLEMENTATION_SUMMARY.md`: A summary of what was built in Phase 1.
- `DEVELOPER_SETUP.md`: Local auth (ADC), emulator, and Genkit usage.
- `PAYMENTS_AND_ADS.md`: Plan for subscriptions (Stripe/Play/StoreKit) and AdMob.
- `DFC_MASTER_EXECUTION_PLAN_2026.md`: The top-level DFC operating plan and execution order.
- `DFC_STREAMING_DOCTRINE_V1.md`: Promoter-first streaming and distribution doctrine.
- `DFC_CANONICAL_EVENT_GRAPH_V1.md`: Canonical event, PPV, and artwork resolution architecture.
- `DFC_LEADERSHIP_ARCHITECTURE_BRIEF.md`: Development, marketing, and research operating model.
- `DFC_BETAVERSE_DOCTRINE.md`: Healthy-by-design metaverse, communications, and collaboration doctrine.
- `DFC_BETAVERSE_PRODUCT_STANDARD.md`: Concrete Betaverse product requirements and release gates.
- `DFC_BETAVERSE_FOUNDER_PARTNER_BRIEF.md`: Founder and partner positioning brief for the Betaverse standard.
- `DFC_BETAVERSE_CODE_OPS_STANDARD.md`: Engineering, moderation, analytics, and operations standard.
- `docs/DFC_MASTER_COMMUNICATIONS_SUITE_2026.md`: Canonical promoter, partner, and community communications pack.
- `docs/architecture/DFC_MEDIA_CDN_LIVE_STREAMING_LAB.md`: Canonical Media CDN + Live Streaming API lab with Cloud Shell commands and staging gate checks.
- `docs/architecture/DFC_CANONICAL_INTEGRATION_STACK_2026.md`: Single canonical 2026 stack per integration with enforcement requirements.
- `docs/api/dfc-events-api.contract.json`: Machine-readable contract for `GET /api/events/{id}` page truth endpoint.
- `web/blueprint.html`: Visual promoter-first and community-first blueprint page for stakeholder briefings.
- `docs/DFC_OPERATOR_QUICK_CARD.md`: One-page day-to-day operator checklist for quality gates and incident triage.
- `docs/QUALITY_GATE_SETUP.md`: Exact branch-protection and required-check wiring guide.
- `docs/CLINE_USAGE_POLICY.md`: Governance boundary for local assistant usage (non-runtime, non-CI dependency).
- `docs/CLINE_FREE_MODE_SETUP.md`: Free-model fallback and continuity runbook for local assistant resilience.
- `docs/DFC_MCP_ARCHITECTURE_MAP.md`: Clear boundary map for Firebase backend vs MCP local tooling architecture.
- `docs/DFC_PLATFORM_MASTER_MAP.md`: Unified architecture blueprint for Google, GitHub, NVIDIA, MCP, and DFC governance controls.
- `docs/DFC_ENTERPRISE_ROADMAP.md`: Multi-phase (2026→2030) enterprise roadmap for platform, cloud, AI, and global scaling.
- `docs/DFC_PLATFORM_GOVERNANCE.md`: Authoritative governance blueprint for controls, release policy, and enforcement hierarchy.
- `docs/DFC_DEVELOPER_ONBOARDING.md`: Fast-start onboarding for modules, MCP/Cline usage, CI success, and routing/rule-pack discipline.

## Strategic and Operator Docs

- `docs/ONLY_FIT_CREATOR_PLAYBOOK.md`: Brand standards, direct-commerce profiles, and Stripe Express compliance checklists for combat and fitness creators.
- `docs/DFC_SPINE.md`: Canonical founder and operator definition of the DFC platform spine.
- `docs/ARCHITECTURE_ONE_PAGER.md`: One-page architecture and deploy summary for partners and funding applications.
- `docs/ARCHITECTURE_DIAGRAM.mmd`: Mermaid system diagram source for frontend, backend, data, AI, media, and ops.
- `docs/REPO_VS_SPINE_AUDIT.md`: Prioritized mismatch list between declared spine and current repo state.
- `docs/DFC_FACE_BUILD_PLAN.md`: When and where to build the public and operational DFC face.
- `docs/API_CONTRACTS/face.md`: Minimum frontend contract for feed, event, promo, and health surfaces.
- `docs/DFC_GOOGLE_PLATFORM_PLAN.md`: Canonical Google-native plan for Maps, Earth, storefront, PPV, and AI sales.
- `docs/NVIDIA_GOOGLE_PILOT_BRIEF.md`: Partner-ready pilot brief for credits, co-engineering, and introductions.
- `docs/AI_BENCHMARK_PLAN.md`: Reproducible CPU baseline to GPU validation plan for DFC AI workloads.
- `docs/SOCIAL_IMPACT_PROGRAM.md`: Operating framework for Pink Shields, Buy a Coffee Not a Coffin, and Gold Coin Gym.
- `docs/SOCIAL_IMPACT_LANDING_COPY.md`: Ready-to-paste landing page and campaign copy.
- `docs/legal/DFC_PARTNER_MOU_TEMPLATE.md`: Partner MOU template for local NGO and gym collaborations.
- `docs/legal/DFC_TRAINER_ONBOARDING_CHECKLIST.md`: Standard trainer and mentor onboarding checklist.
- `docs/INVESTOR_PARTNER_ONE_PAGER.md`: One-page investor and strategic partner briefing sheet.
- `docs/OUTREACH_APEX_ELLIOTT_TEMPLATE.md`: Outreach email template for apex investors and strategic partners.
- `docs/APEX_5_MIN_DEMO_SCRIPT.md`: Timed meeting demo script and pitch bullets for Apex or Elliott calls.
- `docs/PILOT_SOW_4_WEEK.md`: Four-week co-engineering pilot statement of work template.
- `docs/FUNDING_CHECKLIST.md`: Funding and application readiness checklist.
- `docs/OPEN_SOURCE_PLAN.md`: Open-source subset and sponsor-readiness plan.
- `docs/CAMPAIGNS_PLAN.md`: Campaign plan for Google, NVIDIA, and GitHub ecosystem outreach.

## Authentication Setup (Phase 1)

- **Enable providers:** In Firebase Console > Authentication > Sign-in method, enable Email/Password and Google.
- **Authorized domains (Web):** Add your dev host (e.g. `localhost:8080`, `localhost:3000`) and production domains to Firebase Auth authorized domains.
- **Google OAuth client IDs:**
  - Web client (for browser sign-in).
  - Android client with SHA-1/SHA-256 from your keystore.
  - iOS client (reverse client ID in Info.plist).
- **Code paths:**
  - Web: uses `GoogleAuthProvider` with `signInWithPopup` inside `AuthService.signInWithGoogle()`.
  - Mobile: uses `google_sign_in` to obtain tokens and signs into Firebase.
  - After sign-in: `_ensureUserDocument()` creates a user doc (role defaults to `fan`) and router redirects to dashboard.

### Quick Start (Web)

```powershell
flutter pub get
flutter run -d chrome --web-port=8080
```

If Google sign-in fails, verify the domain is authorized in Firebase Console and the Web OAuth client exists.

## YouTube & Stream Keys

Use runtime `--dart-define` values so keys are never hardcoded.

### 1) Create the YouTube Data API key

- Google Cloud Console → APIs & Services → Credentials → Create API key
- Enable `YouTube Data API v3`
- Restrict key by app type and API

### 2) Live stream key

- In YouTube Studio, create a live stream and copy the stream key
- Treat stream keys like passwords (do not commit to git)

### 3) Run with keys (local)

```powershell
flutter run -d chrome --dart-define=YOUTUBE_API_KEY=YOUR_KEY --dart-define=STREAM_API_KEY=YOUR_STREAM_KEY
```

The app reads these from `AppConstants.youtubeApiKey` and `AppConstants.streamApiKey`.

### Backend AI (OAuth/ADC)

- Generative Language API v1/v1beta uses OAuth (no API key).
- Follow [docs/DEVELOPER_SETUP.md](docs/DEVELOPER_SETUP.md) to set Application Default Credentials locally and for Cloud Functions.

## Payments & Ads Roadmap (Phase 1 PR)

**Scope:** Auth hardening (email+Google), ADC for backend AI, and scaffolding for subscriptions + ads.

**PR Summary:**

- Auth: Provider-based Google sign-in, user doc creation, redirects.
- ADC: Cloud Functions + Genkit updated to OAuth; local dev setup documented.
- Subscriptions: Models, Firestore seeding (weekly/fortnightly/monthly), UI wired to seeded plans.
- Ads: `AdsService` placements configured (dashboard, news carousel, FightWire inline, interstitial, rewarded).

**Sprint Tasks (SDK Wiring):**

- Stripe: Add client SDK, create checkout, handle webhooks to activate entitlements.
- Google Pay: Configure payment profiles; integrate Flutter plugin for Android.
- PayPal: Add SDK for web/mobile; server-side capture and reconciliation.
- Apple Pay/StoreKit: iOS entitlement handling; receipt validation.
- AdMob: Initialize SDK, map `AdsService` placements to real ad unit IDs; disable ads for paid tiers.

**Testing Checklist:**

- Web: Verify Google sign-in on authorized domains; test seeded plan rendering and subscribe stubs.
- Mobile: Validate Android SHA-1/SHA-256 OAuth; smoke test ads placeholders.
- Backend: Confirm ADC works for Functions/Genkit; verify Firestore writes for subscriptions.

Footer branding appears in Subscription tabs: "Designed by DataFightCentral © 2026 TM".

# DFC PLATFORM CONTRACT — NO DEMO, NO TOYS

This is DFC (Data Fight Central) — a production combat sports platform.

- NO FAKE DATA in production.
- NO demo/placeholder content in live environments.
- All content must be real events, fighters, promotions, or clearly marked as TEST/STAGING only.

Content sources:

- Event data: connected feeds, CSV, or admin console only.
- Articles: DFC AI agents/bots or approved editors.
- Images: DFC-owned, promoter/fighter-provided, official posters, or licensed stock/CC.

Automation:

- New event → auto article draft (AI), social snippets, email bullet.
- Event status change → feed updates, homepage, notifications.

Environments:

- dev/staging: test data must be tagged as TEST.
- prod: only real data. Any dummy content is a bug.

This is a professional platform. All code, scripts, and AI tools must respect this contract.
