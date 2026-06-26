# DFC Rollback Runbook

## When to use this

Roll back when a deployment causes any of the following in production:
- Entitlement grant failure rate > 1% over 5 minutes
- Stripe webhook delivery failing (DLQ growing, no new purchases writing)
- Mux playback token errors > 5% of requests
- `flutter analyze` regressions introduced post-deploy
- Any P1 alert firing and not self-resolving within 10 minutes

---

## Step 1 — Identify last known good commit

```bash
git log --oneline -10
# Pick the commit SHA before the bad deployment
```

---

## Step 2 — Roll back Firebase functions

```bash
# Option A: re-deploy from last known good tag
git checkout <last-good-tag-or-sha>
firebase deploy --only functions --project YOUR_PROJECT_ID

# Option B: if tag is not available, redeploy from local working tree
git stash
firebase deploy --only functions --project YOUR_PROJECT_ID
```

---

## Step 3 — Roll back Firestore rules (if changed)

```bash
firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
```

---

## Step 4 — Verify recovery

```bash
# Check functions are running
gcloud functions list --project=YOUR_PROJECT_ID

# Check recent function logs for errors
gcloud functions logs read create_entitlement \
  --project=YOUR_PROJECT_ID \
  --limit=50

# Re-run staging smoke
STAGING_URL=https://staging.datafightcentral.com \
  SKIP_SEED=true \
  ./scripts/firebase_deploy_staging.sh
```

---

## Step 5 — Drain the DLQ (if webhook events backed up)

```bash
# Trigger DLQ worker manually via scheduler
gcloud scheduler jobs run dlq-worker \
  --project=YOUR_PROJECT_ID \
  --location=us-central1

# Or call the function directly (requires auth token)
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/dlqWorkerRun
```

---

## Step 6 — Notify stakeholders

- Post in `#dfc-ops` Slack channel with rollback summary.
- Include: what was rolled back, timestamp, last good SHA, current status.
- Open a post-mortem issue in GitHub within 24 hours.

---

## Feature flag kill switch

If rollback is too slow, toggle the feature flag to disable the broken feature:

```bash
# Using Firebase Remote Config (if configured)
firebase remoteconfig:rollback --project YOUR_PROJECT_ID

# Or update the flag in Firestore directly
node -e "
const admin = require('firebase-admin');
admin.initializeApp();
admin.firestore()
  .collection('feature_flags')
  .doc('ppv_checkout_v2')
  .set({ enabled: false }, { merge: true })
  .then(() => { console.log('flag disabled'); process.exit(0); });
"
```

---

## Canary rollback (partial traffic)

If on canary with load balancer traffic split:

```bash
# Re-route 100% traffic back to stable revision
gcloud run services update-traffic YOUR_SERVICE \
  --to-revisions=STABLE_REVISION=100 \
  --project=YOUR_PROJECT_ID \
  --region=us-central1
```

---

## Contacts

| Role | Contact |
|------|---------|
| On-call engineer | See ONCALL.md |
| Stripe support | https://support.stripe.com |
| Mux support | https://mux.com/support |
| Firebase support | https://firebase.google.com/support |
