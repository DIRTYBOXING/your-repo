# Cutover Decision

Last updated: 2026-04-12

## Decision Status

Status: Proposed and ready for staging validation

## Canonical Runtime

Chosen canonical runtime for PPV purchase and playback:

- Purchase and entitlement source: `functions/stripe/ppv.js`
- Playback and replay source: `functions/streaming/mux.js`

## Rationale

- `functions/stripe/ppv.js` already supports the richest PPV checkout flow, including promo codes, Stripe Connect routing, credits, and Firestore-native writes.
- `functions/streaming/mux.js` already acts as the strongest Mux playback and replay authorization layer.
- The finishing sweep aligned app-side access checks and purchase deserialization toward this contract.

## Transitional Compatibility

During the cutover window, compatibility remains in place for:

- top-level `ppv_access`
- legacy `users/{userId}/ppv_access`
- canonical `ppv_purchases.ppvId`
- legacy `ppv_purchases.ppvEventId`

## Deprecation Targets

- `entitlements-service/server.js`
- `web/src/ppv.js`
- `lib/services/dfc_payment_client.dart`
- PPV checkout logic inside `dfc-content-pipeline/live-publisher/src/index.js`

## Rollback Plan

If staging or production validation fails:

1. Revert the runtime flag to the previous routing mode.
2. Restore the previous deployment artifact.
3. Keep dual-read compatibility intact until the issue is fixed.
4. Re-run smoke tests before attempting cutover again.

## Required Evidence Before Final Cutover

- staging checkout succeeds with Stripe test credentials
- webhook recorded purchase is visible in Firestore
- top-level `ppv_access` record exists and expires correctly
- Mux playback URL or replay path succeeds for an authorized user
- telemetry shows no parity regressions versus the previous path
