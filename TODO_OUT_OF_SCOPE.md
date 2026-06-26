# TODO Out Of Scope

These items were intentionally not auto-completed because they require provider access, deployment authority, or an explicit production cutover decision.

## Secrets And Provider Rotation

- Rotate real Stripe API keys and webhook secrets in Stripe.
- Rotate Mux token ID, token secret, signing keys, and webhook secret in Mux.
- Rotate any Firebase, Cloudflare, GitHub Actions, or storage credentials that are currently active.
- Remove fallback access to old secrets after staged verification.

## Runtime Cutover Decisions

- Decide the single canonical runtime for PPV commerce and playback.
- Fence off or retire duplicate flows in:
  - `entitlements-service/server.js`
  - `web/src/ppv.js`
  - `lib/services/dfc_payment_client.dart`
  - non-canonical PPV checkout logic inside `dfc-content-pipeline/live-publisher/src/index.js`

## Real Upstream Verification

- Run staging checkout with real Stripe test credentials.
- Confirm webhook delivery and Firestore purchase writes.
- Confirm Mux playback token and manifest access against staging.
- Confirm replay access expiry enforcement with real upstream data.

## Operational Closeout

- Monitor telemetry during cutover.
- Confirm rollback path and feature flag behavior.
- Remove deprecated runtime after a stable observation window.
