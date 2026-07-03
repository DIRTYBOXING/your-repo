# DFC Production Rollout Runbook

## Scope

This runbook covers production rollout for the public PPV storefront and protected Mission Control lane on Data Fight Central.

## Preconditions

- Branch merged into `master` (PR #22 or later).
- Firebase Hosting build artifact produced from current commit.
- Core functions deployed and active in `australia-southeast1`:
  - `operatorAction`
  - `createPpvStorefrontOrder`
  - `confirmPpvStorefrontOrder`
  - `ogDynamicServe`
- Secret Manager contains current values for:
  - `maps-api-key`
  - Stripe/Mux secrets used by storefront and playback services.

## Deploy Sequence

1. Run CI deploy workflow and confirm `build-web` + `deploy-hosting` succeed.
2. Confirm Hosting release points to expected artifact.
3. Confirm rewrites are healthy (no `ogDynamicServe` endpoint warnings).

## Live Smoke Checks

1. Public storefront route:
   - `https://datafightcentral.com/#/ppv/store`
   - Expected: route remains public and does not redirect to login.
2. Admin route:
   - `https://datafightcentral.com/#/admin/mission-control`
   - Expected: login-protected redirect.
3. Checkout path:
   - Create order -> complete payment -> confirm entitlement -> request playback.
   - Expected: paid order + entitlement + valid playback token/URL.

## Canary Promotion

Use `scripts/hosting_canary_promote.ps1` to push a preview channel and promote to live only after smoke success.

Example:

```powershell
pwsh -ExecutionPolicy Bypass -File scripts/hosting_canary_promote.ps1 -ProjectId datafightcentral -SiteId datafightcentral -ChannelId canary-ppv -Promote
```

## Alerts to Watch

- Dead letter growth in job pipelines.
- Job runtime age p95 > 15 minutes.
- Function HTTP 409 rate spikes above baseline.
- Signature verification failures for operator/storefront endpoints.

## Incident Actions

### Playback fails

1. Validate Mux credentials in Secret Manager.
2. Validate function logs for token generation errors.
3. Rebind updated secrets and redeploy affected function.

### Checkout or entitlement fails

1. Verify Stripe webhook/event flow.
2. Check Firestore writes for order and entitlement docs.
3. Retry with known-good test card/user.

### Operator action signature failures

1. Verify `OPERATOR_ACTION_SHARED_SECRET` rotation status.
2. Confirm HMAC client and server use identical payload canonicalization.
3. Re-run operator smoke using signed test request.

## Rollback

1. Roll back Hosting to previous release:
   - Firebase Console -> Hosting -> Release History -> Roll back.
2. If function regression exists, redeploy previous stable function revision.
3. Re-run smoke checks on storefront, admin gate, and playback.

## Security Rotation (if exposure suspected)

1. Revoke exposed key/token in provider dashboard (Mux/Stripe/GCP).
2. Create replacement with least privilege.
3. Update Secret Manager values.
4. Redeploy dependent functions/workflows.
5. Execute smoke checks and close incident with timestamped notes.
