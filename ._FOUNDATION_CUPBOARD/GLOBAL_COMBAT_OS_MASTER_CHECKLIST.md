# GLOBAL COMBAT OS MASTER CHECKLIST

This checklist is the production control sheet for DFC releases.
Use it for pre-release, launch day, and post-launch validation.

## A. Architecture And Module Integrity

- [ ] Feature folders contain only `screens`, `widgets`, `controllers`, `services`, `models`.
- [ ] Business logic is isolated from UI and not embedded in widgets.
- [ ] Shared components are in `lib/shared/widgets` and reused instead of duplicated.
- [ ] No stray root-level Dart feature files remain outside intended module folders.
- [ ] Route registration remains centralized in `lib/core/config/router_config.dart`.

## B. Riverpod And GoRouter Integrity

- [ ] `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `build_runner`, `custom_lint`, `riverpod_lint` are declared in `pubspec.yaml`.
- [ ] `analysis_options.yaml` includes `custom_lint` plugin and `riverpod_lint` rules.
- [ ] App root uses `ProviderScope` in `lib/main.dart`.
- [ ] All annotated providers generate `.g.dart` files successfully.
- [ ] `dart run build_runner build --delete-conflicting-outputs` completes without errors.
- [ ] Deep-link routes for PPV/ticket/creator flows are covered and tested.

## C. Commerce Pipeline: PPV, Ticket, Subscription

- [ ] `stripe_checkout_express.js` creates Checkout Sessions with metadata: `user_id`, `creator_id`, `event_id`, `type`.
- [ ] Stripe webhook endpoint verifies `STRIPE_WEBHOOK_SECRET` signatures.
- [ ] `checkout.session.completed` writes order and access artifacts to Firestore and Postgres.
- [ ] Access tokens (PPV/ticket) are generated, persisted, and verifiable.
- [ ] Profile/storefront reflects successful purchase state: `Ticket ready` or `Watch now`.
- [ ] Refund, dispute, and cancellation paths are implemented and logged.

## D. Secrets And Runtime Configuration

- [ ] Required secrets exist in Google Cloud Secret Manager:
- [ ] `STRIPE_SECRET_KEY`
- [ ] `STRIPE_WEBHOOK_SECRET`
- [ ] `STRIPE_PUBLISHABLE_KEY`
- [ ] `DATABASE_URL`
- [ ] `REDIS_URL`
- [ ] `JWT_SIGNING_KEY`
- [ ] `GOOGLE_GENAI_API_KEY` (if predictions/AI are active)
- [ ] `MUX_TOKEN_ID` and `MUX_TOKEN_SECRET` (if Mux is active)
- [ ] No production secrets are present in source files.
- [ ] Cloud Run service is configured with `--set-secrets` bindings and expected env vars.

## E. Cloud Run, Domain, And TLS

- [ ] Backend image builds from `atlas_backend/Dockerfile`.
- [ ] Candidate deployment and smoke tests pass in `.github/workflows/dfc-backend-deploy.yml`.
- [ ] `gcloud run services describe dfc-backend` reports ready revision.
- [ ] Custom domain `api.datafightcentral.com` mapping exists and is in READY state.
- [ ] TLS handshake works from external clients for `/health` and `/api/v1/health`.
- [ ] Domain DNS points to expected Cloud Run host target.

## F. Feed, Prediction, And Personalization

- [ ] Purchase events feed into ranking/personalization pipeline.
- [ ] `lib/shared/widgets/onlyfit_prediction_card.dart` renders live data without fallback-only mode.
- [ ] New promotions/events appear in personalized home feed within SLA window.
- [ ] Feed scoring and campaign weights are auditable by event ID and user ID.

## G. Campaigns, Beneficiary Splits, And Support Events

- [ ] Support campaign mode exists with explicit split override rules.
- [ ] Split formulas sum to 100 percent and are recorded per transaction.
- [ ] Beneficiary payout routing is verifiable through ledger entries.
- [ ] Campaign pages display raised amount, supporter count, and payout audit links.

## H. External Funnel Validation

- [ ] Meta, TikTok, X, YouTube assets link into DFC-owned checkout pages.
- [ ] UTM tracking is captured and queryable in analytics.
- [ ] Conversion events map source channel to completed purchase.
- [ ] No external platform directly processes DFC primary commerce flows.

## I. Safety, Compliance, And Trust

- [ ] Creator KYC status is required before monetization is enabled.
- [ ] Age-gating and policy gates exist for protected content types.
- [ ] Moderation reporting works in app and admin console.
- [ ] Terms, refund policy, payout policy, and content policy are visible in production.

## J. Launch Verification Runbook

- [ ] Create a live $1 test event (or equivalent controlled test amount).
- [ ] Complete checkout with correct metadata.
- [ ] Verify Stripe payment success and webhook 200 delivery.
- [ ] Confirm Firestore and Postgres order/token writes.
- [ ] Confirm app profile/storefront access state updates immediately.
- [ ] Confirm stream/ticket artifact redemption works end to end.

## K. Go/No-Go Criteria

Go only when all sections A through J are green with evidence links in release notes.
No-Go if any of the following are true:

- Domain TLS handshake failures persist.
- Webhook signature verification is failing.
- Order/token writes are incomplete or delayed beyond SLA.
- KYC/compliance gates are bypassable.
- Core monetization paths are untested in production-like conditions.

## L. Evidence Log (Fill Per Release)

- Release ID:
- Date:
- Operator:
- Candidate revision:
- Stripe webhook delivery sample IDs:
- Firestore order sample IDs:
- Postgres order sample IDs:
- Feed propagation proof:
- Domain/TLS verification proof:
- Final decision: GO or NO-GO
