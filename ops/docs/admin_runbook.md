# Data Fight Central — Admin Runbook

## Purpose and Scope

This runbook gives **ops and admins** the exact commands, file paths, and step‑by‑step procedures to deploy, validate, troubleshoot, and roll back Data Fight Central. Save all artifacts under **ops/audit/** and follow the incident playbook exactly.

---

## Quick Start Checklist

- **Backup branch and SHA**

```bash
git checkout -b release-lock
git rev-parse HEAD > ops/audit/release_backup.txt
date -u +"%Y-%m-%dT%H:%M:%SZ" >> ops/audit/release_backup.txt
```

- **Build and deploy**

```bash
flutter build web --release
firebase deploy --only hosting --project YOUR_PROJECT_ID
date -u +"%Y-%m-%dT%H:%M:%SZ" > ops/audit/deploy_timestamp.txt
echo "deployed_by: ops@datafightcentral.com" >> ops/audit/deploy_timestamp.txt
```

- **Auth persistence check** in Edge or Chrome Console

```js
console.log("currentUser", firebase.auth().currentUser);
firebase.auth().onAuthStateChanged((u) => console.log("auth state changed", u));
```

Save console output to `ops/audit/edge-debug-console.txt`.

- **Stripe PaymentIntent test**

```bash
export STRIPE_SECRET_KEY_TEST="YOUR_TEST_KEY_FROM_LOCAL_SECRET_STORE" # pragma: allowlist secret
export CONNECTED_ACCOUNT_ID="acct_YOUR_CONNECTED_ID"
./ops/scripts/stripe_test.sh
# result saved to ops/audit/stripe_paymentintent.json
```

- **Maps enablement** in GCP Console and wait 2 to 5 minutes. Save console errors to `ops/audit/maps_console.txt`.

- **PPV runtime verification**

```bash
node scripts/ppv_runtime_readiness_check.mjs
npm --prefix entitlements-service run test:smoke
```

Save readiness output to `ops/audit/ppv_runtime_ready.json` and entitlement smoke output to `ops/audit/ppv_entitlement_smoke.txt`.

---

## Deploy and Rollback Procedures

### Deploy

1. Ensure `release-lock` branch exists and `ops/audit/release_backup.txt` is present.
2. Run the Build and deploy commands from Quick Start Checklist.
3. Verify production URL loads and auth persists.

### Rollback one command

If auth or core functionality regresses, run:

```bash
git revert <bad-commit-sha> --no-edit
git push origin main
firebase deploy --only hosting --project YOUR_PROJECT_ID
```

Save the revert SHA and timestamp to `ops/audit/release_rollback.txt`.

---

## Troubleshooting Playbook

### Auth Persistence Failure

**Symptoms**: `firebase.auth().currentUser` is null after full reload.  
**Collect**:

- First 8 console error lines saved to `ops/audit/edge-debug-console.txt`.
- HAR export from Network saved to `ops/audit/preview_signin.har`.
- Network entry for failing auth request: Method, URL path only, Status, first 500 chars of response. Save to `ops/audit/auth_network.txt`.

**One line fix** (common cause: wrong authDomain or cookie settings in hosting config):

```bash
# update hosting config or environment then redeploy
# example: set correct authDomain in web config and redeploy
git add web/firebase_config.js && git commit -m "fix: authDomain" && git push origin main && firebase deploy --only hosting --project YOUR_PROJECT_ID
```

### Stripe Transfer or Fee Mismatch

**Collect**: `ops/audit/stripe_paymentintent.json`.  
**Check**:

- **transfer_data.destination** equals your connected account ID.
- **application_fee_amount** equals expected fee in cents.

**One line fix** (recreate PaymentIntent with correct destination):

```bash
curl -s -X POST https://api.stripe.com/v1/payment_intents -u ${STRIPE_SECRET_KEY_TEST}: -d amount=5000 -d currency=aud -d "payment_method_types[]"=card -d "transfer_data[destination]"=acct_CORRECT -d "application_fee_amount"=200 > ops/audit/stripe_paymentintent.json
```

### Maps JavaScript API Errors

**Symptoms**: `RefererNotAllowedMapError` or `ApiNotActivatedMapError` in console. Save to `ops/audit/maps_console.txt`.  
**Fix steps**:

1. In GCP Console enable **Maps JavaScript API** and attach billing.
2. In Credentials select the browser API key and add exact HTTP referrers. Use exact domain strings:
   - `https://www.datafightcentral.com/*`
   - `https://datafightcentral.web.app/*`
   - `https://datafightcentral--preview-fix-*.web.app/*`
3. Wait 2 to 5 minutes and reload.

**If RefererNotAllowedMapError persists**: copy the exact referrer string from the console error and add that exact string to the API key restrictions.

### Uploads and Signed URL Failures

**Collect**: failing upload Network entry and response body; save to `ops/audit/upload_failure.txt`.  
**Check**:

- Signed URL expiry and method match.
- Storage bucket IAM and CORS settings.  
  **Quick fix**: regenerate signed URL with correct method and expiry and retry upload.

---

## Admin UI and Controls

**Pages to use**

- **Dashboard**: monitor KPIs and alerts.
- **Events**: create, schedule, set PPV price, toggle live/VOD.
- **Payouts**: view pending payouts, approve, re-run Stripe transfers.
- **Users**: search, force sign out, change roles.
- **Moderation**: review flagged items, approve or takedown.
- **Logs**: view recent console snapshots, payment logs, and first 500 chars of failing network responses.

**Admin actions**

- Force sign out a user:

```js
// run in Admin console or Cloud Function
admin.auth().revokeRefreshTokens(uid);
```

- Approve a payout: mark payout record as approved in admin UI then run Cloud Function to trigger Stripe transfer.

---

## Incident Response and Escalation

**Severity levels**

- **P1**: Auth down, payments failing, or site unreachable. Immediate page one incident.
- **P2**: Maps or ingest failures affecting user experience. Ops window required.
- **P3**: Minor UI bugs or partner onboarding delays.

**P1 Incident steps**

1. Triage and collect artifacts: `edge-debug-console.txt`, `preview_signin.har`, `stripe_paymentintent.json`.
2. Revert to last known good commit using Rollback one command.
3. Notify stakeholders: Ops lead, Dev lead, Legal if payments affected.
4. Postmortem: save timeline and root cause to `ops/audit/incidents/YYYYMMDD_postmortem.md`.

**Contacts and roles**

- **Ops lead**: runs deploy and rollback.
- **Dev lead**: fixes code and config.
- **Legal**: handles partner contract issues.
- **Growth**: handles partner communications.

---

## Monitoring, Alerts, and KPIs

**Metrics to monitor**

- **Auth persistence**: percent of users still signed in after reload. Alert if < 95%.
- **Stripe success rate**: PaymentIntent success and transfer success. Alert on failures.
- **Ingest success rate**: signed upload and RTMP success.
- **Maps errors**: percent of page loads with Map API errors.
- **Pilot conversions**: pilots signed and converted.

**Alert destinations**

- Slack ops channel for P1 and P2.
- Email to ops@datafightcentral.com for P3.

---

## Appendix Quick Commands and File Locations

- **Audit folder**: `ops/audit/`
- **Legal docs**: `ops/legal/`
- **Admin docs**: `ops/docs/admin_runbook.md`
- **Stripe test script**: `ops/scripts/stripe_test.sh`
- **Commit and push helper**: `ops/git-commit-and-push.sh`
- **Collect HAR**: DevTools Network → Save as HAR → save to `ops/audit/preview_signin.har`
- **Revert and redeploy**:

```bash
git revert <bad-commit-sha> --no-edit
git push origin main
firebase deploy --only hosting --project YOUR_PROJECT_ID
```

---

**Start here now**: run the Quick Start Checklist, save the artifacts listed, and paste `ops/audit/deploy_timestamp.txt` and `ops/audit/stripe_paymentintent.json` here for validation.
