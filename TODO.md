# TODO — PPV / Mux / Stripe / Firebase / Social + VS Code Insiders workflow

## Step 1 — Confirm source-of-truth entitlement path mismatch
- [x] Reviewed Flutter gate + entitlement listener files
- [x] Reviewed backend Stripe + Mux + canonical access state
- [x] Reviewed social publishing + configs
- [ ] Decide / implement normalization so Flutter entitlement and backend authority match

## Step 2 — Implement entitlement normalization (Option B)
- [ ] Update `functions/stripe_webhooks.js` to write `entitlements` documents in the shape Flutter expects
- [ ] Add refund/dispute revocation handling
- [ ] Add Stripe webhook idempotency (store processed event IDs)

## Step 3 — Ensure Mux playback is strictly behind access
- [ ] Verify `ppv_stream_screen.dart` requests playback only after entitlement is true

## Step 4 — Verify Firebase rules for entitlements reads
- [ ] Update `firestore.rules` if `entitlements` collection security rules are missing

## Step 5 — Social + collaboration PPV lifecycle triggers
- [ ] Identify PPV lifecycle trigger functions (event created/live/replay/purchased) and ensure they call `nativePublish` / social publisher

## Step 6 — Docs + dev workflow
- [ ] Create `docs/PPV_INTEGRATION_CHECKLIST.md`
- [ ] Create `docs/DEV_WORKFLOW_GCP_CLOUDSHELL_VSCODE.md`

## Step 7 — Test checklist
- [ ] Stripe test checkout → entitlement granted → Flutter gate passes → Mux playback loads
- [ ] Refund/dispute test → entitlement revoked → access denied
- [ ] Social publish trigger test → Firestore social_publish_log updated

