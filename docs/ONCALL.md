# DFC On-Call Runbook

## Alert → Response matrix

| Alert | Severity | First response | Escalation threshold |
|-------|----------|---------------|----------------------|
| Entitlement failure rate > 1% | P1 | Check function logs, drain DLQ | 10 min no recovery → page lead |
| DLQ size > 50 unprocessed | P2 | Run `dlq-worker` manually | 30 min no drain → P1 |
| Stripe webhook delivery failure | P1 | Check Stripe Dashboard webhook log | 5 min → escalate |
| Mux playback token errors > 5% | P1 | Check Mux Dashboard + function logs | 10 min → escalate |
| Flutter analyze regression | P3 | Review PR that introduced it | Block merge, fix on next PR |
| DLC size alarm | P2 | Check Grafana funnel dashboard | 1 hour no drop → P1 |

---

## P1 incident response (< 10 minutes)

1. **Acknowledge** the alert in Slack `#dfc-ops`.
2. **Check function logs**:
   ```bash
   gcloud functions logs read create_entitlement \
     --project=YOUR_PROJECT_ID --limit=50
   gcloud functions logs read stripeWebhook \
     --project=YOUR_PROJECT_ID --limit=50
   ```
3. **Check Firestore** for stalled purchases:
   - Collection `webhook_dlq` — count docs with `status: "pending"`
   - Collection `ppv_purchases` — check latest doc timestamps
4. **Drain DLQ** if backed up:
   ```bash
   gcloud scheduler jobs run dlq-worker \
     --project=YOUR_PROJECT_ID --location=us-central1
   ```
5. **If no recovery in 10 minutes** → roll back (see [ROLLBACK.md](ROLLBACK.md)).
6. **Post status update** in `#dfc-ops` every 15 minutes until resolved.

---

## Daily health checks

Run these each morning before any deployments:

```bash
# 1. Check DLQ depth
node -e "
const admin = require('firebase-admin');
admin.initializeApp();
admin.firestore()
  .collection('webhook_dlq')
  .where('status','==','pending')
  .get()
  .then(s => { console.log('DLQ pending:', s.size); process.exit(0); });
"

# 2. Check recent entitlement grants (last 24h)
gcloud logging read \
  'jsonPayload.metric="entitlement_granted"' \
  --project=YOUR_PROJECT_ID \
  --freshness=24h \
  --format="value(timestamp,jsonPayload.userId)"

# 3. Check Stripe webhook delivery
# → Stripe Dashboard → Developers → Webhooks → inspect last 20 events

# 4. Flutter analyze
flutter analyze --no-pub
```

---

## Stripe webhook failure

1. Go to Stripe Dashboard → Developers → Webhooks.
2. Find the failing event and click **Resend**.
3. If repeated failures: check `STRIPE_WEBHOOK_SECRET` in Secret Manager matches the live endpoint secret.
4. Re-seed the secret if rotated:
   ```bash
   echo -n "whsec_new_value" | gcloud secrets versions add stripe-webhook-secret \
     --data-file=- --project=YOUR_PROJECT_ID
   ```

---

## Mux playback failure

1. Check Mux Dashboard → Video → Live Streams or Assets for the affected event.
2. Confirm `MUX_TOKEN_ID` and `MUX_TOKEN_SECRET` in Secret Manager are current.
3. Check function `createMuxPlaybackToken` logs for 401/403 from Mux API.
4. If signing key rotated: update `MUX_SIGNING_KEY_ID` and `MUX_SIGNING_PRIVATE_KEY` secrets.

---

## Useful dashboards and links

| Resource | URL |
|----------|-----|
| Grafana PPV dashboard | http://localhost:3001 (local) or your hosted Grafana |
| Firebase Console | https://console.firebase.google.com/project/datafightcentral |
| Stripe Dashboard | https://dashboard.stripe.com |
| Mux Dashboard | https://dashboard.mux.com |
| GCP Logging | https://console.cloud.google.com/logs?project=YOUR_PROJECT_ID |
| GCP Monitoring | https://console.cloud.google.com/monitoring?project=YOUR_PROJECT_ID |
| GitHub Actions | https://github.com/DIRTYBOXING/Data-Fight-Central/actions |

---

## Escalation contacts

| Role | Responsibility |
|------|---------------|
| Platform lead | Final call on rollback and incident severity |
| Stripe account owner | Webhook secret rotation, payout disputes |
| Mux account owner | Signing key rotation, stream health |
| Firebase project owner | IAM, security rules, function deployment |

> Update this table with real names before going live.

---

## Post-mortem template

Open a GitHub issue titled: `[Post-mortem] <date> — <brief description>`

Include:
- **Timeline**: when alert fired, when investigated, when resolved
- **Root cause**: what failed and why
- **Impact**: purchases affected, revenue at risk, duration
- **Fix applied**: what was deployed or rolled back
- **Follow-up actions**: what prevents recurrence
