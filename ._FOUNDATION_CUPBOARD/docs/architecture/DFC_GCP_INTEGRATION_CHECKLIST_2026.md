# DFC GCP Integration Checklist 2026

Status: Canonical integration map for Social + PPV execution in this repository.

## Scope lock

- Social + PPV are the only product pillars for this phase.
- Commerce paths are fail-closed by default.
- Demo behavior is forbidden in checkout, entitlement, and playback paths.

## Platform decisions

- Primary cloud: GCP.
- Delivery model: single CDN first, multi-CDN only after measured need.
- Packaging baseline: CMAF/HLS with ABR renditions.
- Entitlement checks: server-side only, short-lived tokens.
- Stripe policy: Checkout Sessions for one-time PPV checkout, Setup Intents for save-for-later.

## End-to-end stack map

1. Ingest

- Primary: SRT contribution where available.
- Fallback: RTMP contribution.
- Required checks:
  - encoder heartbeat and packet loss thresholds
  - backup ingest path tested before every premium event

2. Packager and transcoder

- Use managed packaging/transcode path with ABR output.
- Required checks:
  - HLS manifest reachable
  - first media assets reachable
  - startup and first-frame SLOs measured

3. Origin and CDN

- Origin remains cloud storage + manifest authority.
- CDN serves posters and playback assets.
- Required checks:
  - poster object exists in bucket
  - origin 200 on HEAD
  - edge host 200 across target regions

4. Player and entitlement gate

- Player must request server-side entitlement outcome before playback unlock.
- Required checks:
  - non-entitled sessions blocked
  - entitled sessions can start playback
  - explicit error reason logged on denial

5. Payments and receipts

- Checkout authority: Stripe Checkout Sessions.
- Receipt and entitlement grant must be idempotent.
- Required checks:
  - duplicate webhook retries do not double grant access
  - receipt and entitlement rows can be reconciled from logs

6. Social and clips

- Clips are derived from trusted events and pass moderation queue.
- Required checks:
  - clip artifacts resolve from CDN
  - moderation state is present before public amplification

7. AI and analytics

- Event and playback telemetry lands in analytics store.
- Recommender or ranking services consume durable event data only.
- Required checks:
  - events emitted for startup, rebuffer, entitlement decision, checkout conversion
  - no secret material in logs

8. Operations and security

- Run gate before any staging promotion.
- Run weekly hardening sweep before event windows.
- Required checks:
  - key material stored in secrets manager or encrypted CI secrets
  - webhook signature verification on all payment webhooks
  - incident runbook links present in release threads

## CI and branch protection contract

Required workflow checks on staging branch:

- PPV Staging Gate
- Playwright visual smoke
- Poster + CDN checks

Branch protection policy:

- require pull request
- require at least one approval
- require all status checks to pass
- disallow force push

## Required secrets matrix (GCP-first)

Core runtime:

- GCP_SA_KEY
- GCP_PROJECT_ID
- ENTITLEMENT_HEALTH_URL
- ENTITLEMENT_PROXY_URL
- MUX_AUTH_URL
- MUX_API_TOKEN
- TEST_ENTITLEMENT_TOKEN

Operations:

- SLACK_WEBHOOK_URL
- FLAG_API_TOKEN
- CDN_API_KEY

Stripe:

- STRIPE_SECRET_KEY
- STRIPE_WEBHOOK_SECRET
- PLATFORM_SUBSCRIPTION_PRICE_ID (if subscription products are active)

## Repo execution checklist

Day 0 to 2:

- verify runbook rollback flag flip section
- verify PPV gate workflow secrets contract
- verify poster and player smoke selectors

Day 3 to 7:

- enforce branch protection on staging
- run three successful PPV gate executions
- fix flaky visual assertions before further feature work

Week 2 to 4:

- execute weekly sweep on schedule
- run synthetic load test and collect SLO report
- publish internal proof note with gate run URLs

## SLO targets

- player startup median less than 5 seconds
- rebuffer ratio less than 1 percent on premium events
- entitlement health check returns ready true in gate and sweep
- poster edge availability 200 across required regions

## Evidence required before promotion

Promotion is blocked unless all evidence exists:

- passing PPV gate run URL
- passing weekly sweep output
- entitlement health payload with ready true
- poster + CDN checks output with 200 status
- player/poster Playwright output for chromium

## Runbook links

- docs/runbooks/DFC_PPV_ONE_CLICK_ROLLBACK.md
- docs/runbooks/DFC_PPV_LIVE_EVENT_OPS_RUNBOOK.md
- docs/architecture/dfc_multi_region_streaming_blueprint.md
- docs/architecture/dfc_streaming_0_90_day_foundation.md
