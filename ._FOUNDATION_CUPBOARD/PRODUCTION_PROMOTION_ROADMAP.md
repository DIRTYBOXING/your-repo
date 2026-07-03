# Production Progressive Promotion Roadmap

## Scope

This document defines the canary promotion rings for rolling out the DFC platform through production. SRE progresses through each ring sequentially; promotion to the next ring requires all verification checks to pass.

## Preconditions (Before Any Promotion)

- Branch merged into `master` and CI pipeline green.
- No compilation or configuration errors in the release.
- `scripts/canary_deploy.sh` prerequisites satisfied (Firebase authenticated, staging URL configured).
- `ops/README.md` bootstrap complete: Cloud Build triggers, canary rollback Cloud Function, alert policy, and Secret Manager secrets provisioned.

---

## Rings

### Ring 0 — Flag OFF (Main Branch)

**State:** Feature flag `dfc_payments_flow` is **OFF**. Code is merged to `master` but not activated for any users.

**Command:**
```bash
# Confirm flag state (should be OFF)
gcloud firestore documents get settings/canary --project $PROJECT_ID
# Expected: canary_percent = 0
```

**Gate:** CI passes, no compilation or configuration errors.

---

### Ring 1 — Internal Canary (SRE/QA Whitelist, 24h)

**State:** Deploy to staging/internal environment. Access restricted to SRE/QA allowlist only. No public traffic.

**Deploy Sequence:**
```bash
PROJECT=dfc-staging \
STAGING_URL=https://staging.datafightcentral.com \
./scripts/canary_deploy.sh dfc-staging 5
```

**Verification Checklist (run during this ring):**

1. Synthetic checkout segment:
   ```bash
   node scripts/synthetic_checkout.js --count=5
   ```
   - Expected: All synthetic checkout flows complete successfully.

2. Duplicate order check:
   ```bash
   psql "$PG_CONN" -c "SELECT checkout_session_id, COUNT(*) FROM orders GROUP BY checkout_session_id HAVING COUNT(*) > 1;"
   ```
   - Expected: Zero rows returned.

3. Failed webhook processor check:
   ```bash
   psql "$PG_CONN" -c "SELECT type, COUNT(*) FROM webhook_events WHERE status='failed' GROUP BY type;"
   ```
   - Expected: Zero rows returned.

4. Reconciliation run:
   ```bash
   ./scripts/run-reconciliation.sh --date $(date +%F)
   ```
   - Expected: Zero critical mismatches; any triage items documented and acknowledged.

**Containment Trigger:**
```bash
ffctl set dfc_payments_flow --off
```

**Gate:** All four checks pass. 24-hour observation window complete with no P1/P2 incidents.

---

### Ring 2 — 1% Public Traffic (Progressive Ramp, 48h)

**State:** Feature flag `dfc_payments_flow` is **ON** for 1% of production traffic. Traffic is gradually increased.

**Traffic Shift Commands:**
```bash
# Set canary to 1% (via load balancer or traffic manager)
gcloud firestore documents set settings/canary --project $PROJECT_ID \
  --data='{"canary_percent":1}'

# Promote stepwise: 1% → 5% → 10% → 25% → 50%
# Each step requires 24h of stable metrics before advancing.
gcloud firestore documents set settings/canary --project $PROJECT_ID \
  --data='{"canary_percent":5}'
```

**Monitoring KPIs (running continuously across this ring):**
- Entitlement success rate: **≥ 99.5%**
- Playback success rate (start → first frame): **≥ 99%**
- Startup latency (median): **≤ 2 s**
- Rebuffer ratio: **≤ 1%**
- License API p95: **< 500 ms**
- Purchase success rate: **> 90%**
- Pub/Sub DLQ growth: **< 10% over 10 min**
- Reconciliation mismatch ratio: **< 1%**

**Containment Trigger (if any critical alert fires):**
```bash
ffctl set dfc_payments_flow --off
```

**Gate:** 48h stable metrics at each step (1%, 5%, 10%, 25%, 50%). No P1/P2 incidents.

---

### Ring 3 — 100% Promo (Default ON)

**State:** Feature flag `dfc_payments_flow` is **ON** for 100% of production traffic. Full rollout complete.

**Promotion Command:**
```bash
gcloud firestore documents set settings/canary --project $PROJECT_ID \
  --data='{"canary_percent":100}'
```

**Final Verification Checklist:**

1. Full reconciliation run:
   ```bash
   ./scripts/run-reconciliation.sh --date $(date +%F)
   ```
   - Expected: Reconciliation mismatch ratio < 1%.

2. Alert policy confirmation:
   ```bash
   gcloud alpha monitoring policies list --project $PROJECT_ID
   ```
   - Expected: `playback_success_rate` alert policy active and firing threshold < 99%.

3. Canary rollback guard smoke test:
   ```bash
   gcloud functions deploy canary-rollback \
     --project="${PROJECT_ID}" \
     --runtime=nodejs20 \
     --trigger-http \
     --region="${REGION}" \
     --source=functions/canaryGuard \
     --entry-point=canaryRollback \
     --service-account="${SA}" \
     --no-allow-unauthenticated
   ```
   - Follow smoke-test in `ops/README.md` Step 5; expected response: `{"status":"rolled_back","canary_percent":0}`.

**Gate:** All checks pass. Monitor KPIs for 72h post-promotion.

---

## Incident Response (Any Ring)

### Immediate Containment

```bash
ffctl set dfc_payments_flow --off
```

### Incident Triage Steps

1. Run synthetic checkout test:
   ```bash
   node scripts/synthetic_checkout.js --count=5
   ```

2. Check for duplicate orders:
   ```bash
   psql "$PG_CONN" -c "SELECT checkout_session_id, COUNT(*) FROM orders GROUP BY checkout_session_id HAVING COUNT(*) > 1;"
   ```

3. Check for failed webhook processors:
   ```bash
   psql "$PG_CONN" -c "SELECT type, COUNT(*) FROM webhook_events WHERE status='failed' GROUP BY type;"
   ```

4. Trigger reconciliation run:
   ```bash
   ./scripts/run-reconciliation.sh --date $(date +%F)
   ```

---

## Rollback Procedures

### Cloud Run Service Rollback
```bash
gcloud run services describe <service-name> --region=$REGION --project=$PROJECT_ID
gcloud run services update-traffic <service-name> --region=$REGION --project=$PROJECT_ID --to-revisions=<previous-revision>=100
```

### Firebase Functions Rollback
```bash
firebase functions:delete <functionName> --project $PROJECT_ID
git checkout <previous-tag> && firebase deploy --only functions --project $PROJECT_ID
```

### Hosting Rollback
- Firebase Console → Hosting → Release History → Roll back.

### Canary Rollback via Guard
```bash
TOKEN=$(gcloud secrets versions access latest --secret=CANARY_TRIGGER_TOKEN)
curl -s -X POST "${CANARY_URL}" \
  -H "Content-Type: application/json" \
  -H "x-canary-token: ${TOKEN}" \
  -d '{"reason":"manual rollback"}' | jq .
```

---

## References

- `RELEASE.md` — Pre-merge, merge/tag, first 24h monitoring, and rollback procedures.
- `docs/PRODUCTION_ROLLOUT_RUNBOOK.md` — Live smoke checks, canary promotion, alerts, and incident actions.
- `docs/runbooks/staging_hardening_runback.md` — Staging acceptance criteria and rollout guidance (1% → 10% → 50% → 100%).
- `ops/README.md` — Canary rollback notification channel setup, alert policy, Cloud Function deploy, and incident response.
- `scripts/canary_deploy.sh` — Automated canary deploy pipeline for Firebase functions.
- `scripts/hosting_canary_promote.ps1` — Firebase Hosting preview channel and promotion.
- `functions/canaryGuard/index.js` — Automated canary rollback Cloud Function.
- `k8s/dfc-deployment.yaml` — GKE deployment manifests for dfc services.
- `deploy-gke.sh` — GKE cluster creation and service rollout script.
- `cloudbuild.yaml` — Cloud Build CI/CD pipeline for Cloud Run services.
- `azure-pipelines.yml` — Azure DevOps Flutter build and Firebase Functions deploy pipeline.
