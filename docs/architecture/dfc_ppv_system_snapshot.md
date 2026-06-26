# DFC PPV System Snapshot

Version: 2026-04-17
Author: DFC + Copilot

## Purpose

This file is the current architecture snapshot for DFC's PPV, entitlement, streaming, and adjacent social-commerce stack.

Use this document before changing any of the following:

- Stripe checkout or payment flows
- PPV purchase/access logic
- Entitlement/token/DRM logic
- Mux playback or replay generation
- PPV watch surfaces in Flutter
- Promoter payout and revenue routing

This snapshot is grounded in the repository as it exists on 2026-04-17. It is not a target-state fantasy doc. It records what is actually present, what is duplicated, and what should be treated as canonical for the next implementation pass.

## 1. Platform Shape

### Client Layer

Main app: Flutter + Dart in `pubspec.yaml`

- Targets: web, Android, iOS, Windows, macOS, Linux
- State/navigation: Provider + GoRouter
- Core platform fabric: Firebase Auth, Firestore, Storage, Cloud Functions, Messaging, Analytics, Crashlytics, Performance, Remote Config, App Check
- Media/realtime surface: video_player, flutter_webrtc, cached media, notifications, deep links, maps, Stripe client packages

### Backend Lanes

#### Node / Firebase Functions lane

Primary orchestration and commerce/runtime lane.

- Firebase Functions + Firebase Admin
- Stripe
- Mux
- Ably, Twilio, SendGrid
- Express runtime in `functions/server.js`
- Pub/Sub dependency present
- Additional Node root tooling: Express, Serverless Offline, PM2, Playwright, Sharp, RSS parsing, Genkit, OpenAI, Postgres client

#### Python lane

Primary intelligence and analysis lane.

- FastAPI in `atlas_backend`
- Predictor service in `services/predictor`
- OpenAI, Anthropic, Google GenAI, Pinecone
- OCR and media analysis tooling
- Async/Postgres and Prometheus support

#### Dedicated entitlements lane

Separate Node service in `entitlements-service`.

- Express
- Redis
- JWT
- Firebase Admin
- Stripe
- Designed for Stripe checkout, token issuance, and DRM proxying

### Infra

Repository is platform-shaped, not monolithic.

- Docker + docker-compose at root
- Postgres/PostGIS
- Redis
- Vault
- n8n
- Atlas backend container
- Predictor container
- Auto-clip worker
- Entitlements service container

## 2. Current PPV System In Repo

### Flutter PPV Surface

The client already has a substantial PPV domain.

Key runtime paths:

- `lib/features/ppv/services/ppv_service.dart`
- `lib/features/ppv/services/ppv_payment_service.dart`
- `lib/features/ppv/services/ppv_access_service.dart`
- `lib/features/ppv/screens/ppv_live_watch_screen.dart`
- `lib/features/ppv/widgets/ppv_payment_sheet.dart`
- `lib/core/config/router_config.dart`

Observed PPV routes include:

- `/ppv`
- `/ppv/event/:ppvId`
- `/ppv/:ppvId/watch`
- `/ppv/library`
- `/ppv/subscribe`
- `/ppv/:ppvId/command-chat`

### Firebase Functions PPV Authority

The most integrated backend PPV path in the repo is the Firebase Functions lane.

Key files:

- `functions/stripe/ppv.js`
- `functions/stripe/payments.js`
- `functions/ppv/access_state.js`
- `functions/streaming/mux.js`

Current responsibilities:

- `createPPVCheckoutSession` exists in `functions/stripe/ppv.js`
- `createPPVPaymentIntent` exists in `functions/stripe/ppv.js`
- `grantPPVAccess` exists in `functions/stripe/ppv.js`
- Stripe webhook handling exists in `functions/stripe/payments.js`
- Canonical purchase/access state resolution exists in `functions/ppv/access_state.js`

This is the strongest candidate for current authoritative purchase/access logic because it is the path already coupled to Flutter callable usage and Firestore access records.

### Access Model

Access/purchase truth is currently represented across Firestore collections, including:

- `ppv_access`
- `ppv_purchases`
- `ppv_checkout_sessions`
- `ppv_payment_intents`

Client-side access evaluation exists in `lib/features/ppv/services/ppv_access_service.dart` and mirrors the canonical resolver pattern used in `functions/ppv/access_state.js`.

### Streaming and Replay

Key streaming/replay assets:

- `functions/streaming/mux.js`
- `functions/automation/auto_legacy.js`
- `functions/automation/post_event.js`
- `functions/config/index.js`

Observed capabilities:

- Mux live stream creation and status management
- Signed playback tokens for Mux playback
- Webhook handling for Mux live/VOD events
- Replay/vault automation primitives
- Clip seeding and post-event automation hooks

## 3. Additional Entitlement Paths Present

The repo contains additional entitlement/token systems beyond the Functions-based PPV path.

### Dedicated entitlements service

`entitlements-service/server.js` currently provides:

- `POST /checkout`
- `POST /webhook/stripe`
- `POST /entitlements/token`
- `POST /license`

Characteristics:

- Firestore-backed `ppv_checkout_sessions` compatibility layer for the web player
- RS256 JWT issuance
- JTI single-use enforcement
- DRM provider proxying

### Functions-side lightweight entitlement service

The `functions/server.js` Express wrapper exposes:

- `POST /entitlements/request`
- `POST /entitlements/validate`
- `POST /drm/license`

Characteristics:

- HMAC JWT playback tokens in `functions/entitlement.js`
- Firestore lookup against `purchases`
- Separate DRM exchange layer in `functions/drm-license-exchange.js`

## 4. Architecture Fault Lines

This is the most important section in the file.

DFC does not have a PPV absence problem. It has a PPV duplication problem.

### A. Three payment acquisition patterns coexist

1. Non-PPV static Stripe payment links still exist in `lib/core/constants/stripe_config.dart`
2. Callable Checkout Session / PaymentIntent flows in `functions/stripe/ppv.js`
3. Standalone Stripe checkout inside `entitlements-service/server.js`

This is the main architectural risk. If these paths stay active at the same time, access grants, reconciliation, and support burden drift apart.

### B. Active PPV UI no longer uses static links, but repo cleanup is still incomplete

The active Flutter PPV purchase/watch surfaces now route through hosted checkout and entitlement-aware flows:

- `lib/features/ppv/widgets/ppv_payment_sheet.dart`
- `lib/features/ppv/widgets/ppv_checkout_sheet.dart`
- `lib/features/ppv/screens/ppv_live_watch_screen.dart`
- `lib/features/ppv/screens/ppv_store_screen.dart`

Static Stripe link constants still exist in the repo, so the architectural risk is reduced but not fully erased until those constants are either removed or clearly quarantined from app-owned PPV flows.

### C. Multiple entitlement/token authorities coexist

At least three token/access approaches are present:

1. Firestore PPV access records + access resolvers
2. Functions-side HMAC playback token flow in `functions/entitlement.js`
3. Standalone RS256/JTI token flow in `entitlements-service/server.js`

That is too many authorities for a paid media platform.

### D. Collection contracts are inconsistent

Observed collection names include:

- `ppv_access`
- `ppv_purchases`
- `purchases`
- `ppv_checkout_sessions`
- `ppv_payment_intents`

Until one purchase ledger and one entitlement ledger are declared canonical, debugging and analytics will stay fragmented.

### E. Current app/runtime integration favors Firebase Functions, not the standalone entitlements service

The Flutter PPV payment service calls callable Functions for PPV checkout/payment intent creation.

Active PPV cash purchase surfaces now converge on that same path, and feature-layer client code no longer writes local purchase records before webhook confirmation.

That means the current canonical runtime is closer to:

`Flutter -> Firebase Functions -> Firestore PPV records -> access resolver`

than it is to:

`Flutter -> standalone entitlements-service`

This matters. Future work should not accidentally document the less-integrated service as if it already owns production flow.

## 5. Canonical Direction For Next Pass

### Purchase authority

For one-time PPV purchases, prefer a single authoritative Stripe path.

Recommended rule:

- Web PPV: Stripe Checkout Sessions
- Native/custom UI only if required: PaymentIntents

Do not keep static PPV payment links as a parallel purchase authority.

Current cleanup state:

- Active Flutter PPV cash purchase surfaces initiate hosted checkout through the Functions-backed lane
- Client-side feature PPV purchase code no longer writes local purchase/access records as a substitute for backend completion
- Watch and gate surfaces now expect access to unlock from canonical backend state after payment confirmation
- Standalone entitlement token issuance now resolves against canonical `ppv_checkout_sessions` records instead of a separate `ppv_orders` ledger
- Stripe webhook completion now marks canonical `ppv_checkout_sessions` entries complete for PPV checkout flows

### Access authority

Until a deliberate migration is executed, treat the current canonical access authority as:

- Firestore purchase/access records written by the Firebase Functions Stripe lane
- Canonical status resolution in `functions/ppv/access_state.js`
- Client-side mirrors in `lib/features/ppv/services/ppv_access_service.dart`

### Token/DRM authority

Choose one of the following and enforce it:

1. Firebase Functions remains the access authority and the standalone entitlements service is reduced to a narrow DRM gateway role
2. Standalone entitlements service becomes the new authority, and all Flutter and webhook flows are migrated to it explicitly

Do not leave both systems active as parallel sources of truth.

### Streaming authority

Current strongest fit remains:

- Mux for ingest/playback/VOD
- Signed playback via `functions/streaming/mux.js`
- Replay automation hooks from existing Functions automation

## 6. Stripe Guidance For This Repo

This repo should follow the following Stripe posture for PPV work:

- Prefer Checkout Sessions for standard one-time PPV purchases
- Keep PaymentIntents only where native/custom collection is required
- Keep Stripe Connect routing logic centralized
- Keep webhook completion as the authoritative purchase completion event
- Keep pricing/promo/fee logic in one backend path only

Current repo note:

- Root package uses Stripe SDK `^20.4.1`
- Functions package uses Stripe SDK `^17.7.0`
- `entitlements-service` uses Stripe SDK `^14.0.0`

That version spread is operationally messy. Upgrade planning should consolidate SDK versions and align on a single API posture.

## 7. Rectification Backlog

### P0 - completed in this pass

1. Removed static PPV payment-link usage from active PPV purchase/watch surfaces
2. Converged active Flutter cash purchase flows on the Firebase Functions Stripe lane
3. Removed client-side local purchase writes from the feature PPV purchase flow so backend completion remains authoritative
4. Rewired the standalone entitlements service from `ppv_orders` to canonical `ppv_checkout_sessions`
5. Marked canonical PPV checkout-session records complete from Stripe webhook handling

### P0 - remaining

1. De-duplicate token issuance paths
2. Reduce standalone checkout creation to a compatibility layer or remove it entirely
3. Declare one authoritative access ledger and make every watch gate consume only canonical access state

### P1 - platform hardening

1. Replay expiry enforcement and revocation consistency
2. Device binding posture for premium playback
3. Unified telemetry for playback success, token errors, buffering, and license latency
4. Clear settlement/reconciliation ledger for promoter payouts
5. Multi-environment contract for local/dev/staging/prod checkout and webhooks

### P2 - leadership stack work

1. Durable event spine with Pub/Sub or Kafka-style semantics
2. Multi-region posture for critical purchase/playback paths
3. Multi-CDN failover strategy
4. Moderation and trust instrumentation for premium live chat and creator flows
5. Activation-kit distribution engine for fighters/gyms/promoters

## 8. What To Preserve

Do not throw away the whole stack. The problem is overlap, not lack of capability.

Preserve these lanes:

- Flutter PPV domain and routes
- Firebase Functions commerce/access logic already wired to client calls
- Mux live/VOD and signed playback work
- Anti-fraud, pricing, waiting-room, replay, and clip automation assets already present
- Dedicated entitlements service as a reusable component, but only after its role is narrowed or promoted deliberately

## 9. Next-Pass Rules For AI Agents

When generating code or architecture from this point:

- Start from this file, not from assumptions
- Treat duplicated payment/entitlement paths as technical debt, not as multiple supported truths
- Prefer the already-integrated Firebase Functions PPV path unless an explicit migration plan says otherwise
- Keep Flutter purchase flows entitlement-aware
- Keep PPV logic event-driven and server-authoritative
- Keep Python focused on ML/intelligence, Node/Functions focused on orchestration and commerce runtime

## 10. Summary

DFC already has a real PPV platform shape.

What exists:

- Flutter PPV client domain
- Firebase Functions purchase/access workflows
- Firestore access ledger patterns
- Mux streaming and replay hooks
- Dedicated entitlement/DRM service components
- Dockerized infra and adjacent automation lanes

What is broken architecturally:

- Too many payment paths
- Too many entitlement/token paths
- Static link constants still exist in the repo, even though active PPV UI no longer calls them
- No single declared source of truth for purchase completion and playback grant

What the next pass must do:

- Choose one purchase authority
- Choose one entitlement authority
- remove or quarantine dormant PPV static-link constants and any unused purchase helpers
- unify ledgers, tokens, and watch gating

That is the shortest path from "stack with PPV features" to "coherent PPV platform."
