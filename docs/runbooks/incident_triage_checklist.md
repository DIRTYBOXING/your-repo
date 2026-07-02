# DFC Staging & Production Incident Triage Checklist

Use this one-page checklist to triage and contain payments, webhook, and ledger incidents during progressive deployment.

---

## 🚨 PHASE 1: Immediate Triage (0 - 5 Minutes)

### [ ] Step 1: Check System Alert Status
Identify the severity level in PagerDuty or Slack `#payments-ops-alerts`:
- **CRITICAL**: Outage affecting > 1% checkout success, raw webhook processing drops, or Reconciliation mismatch > $0.00.
- **WARNING**: Elevated latencies (`verify-session` P95 > 2s) or exposure logging queue backlog > 1,000 events.

### [ ] Step 2: Emergency Containment (Kill-Switch)
If checkouts are failing or double-billing is suspected, IMMEDIATELY disable the payments flow globally. This redirects traffic to graceful error fallback states or static partner landing options.
```bash
# Disable feature flag globally (immediate off)
ffctl set dfc_payments_flow --off
```

### [ ] Step 3: Check Webhook Ingest Health
Confirm if webhook payloads are reaching the database or failing on-arrival:
```bash
# Query recent failures from raw webhook table
psql "$PG_CONN" -c "
  SELECT type, COUNT(*), substring(last_error from 1 for 100) as error_msg
  FROM webhook_events
  WHERE status='failed' AND received_at > now() - interval '1 hour'
  GROUP BY type, last_error;
"
```

---

## 🔍 PHASE 2: Lock & Diagnose (5 - 15 Minutes)

### [ ] Step 4: Detect Idempotency Failures
Determine if duplicate transactions are spawning concurrent records in the ledger or entitlements database:
```bash
# Find duplicate orders for identical checkout sessions
psql "$PG_CONN" -c "
  SELECT checkout_session_id, COUNT(*)
  FROM orders
  GROUP BY checkout_session_id
  HAVING COUNT(*) > 1;
"
```

### [ ] Step 5: Execute Staged Replay Dry Run
Assess processing status of all pending or failed webhook payloads before executing changes:
```bash
# Dry-run replay to verify output logs
node scripts/replay_webhooks.js --dry-run --limit=200 > /tmp/replay_triage.log
cat /tmp/replay_triage.log | grep -E "duplicate|failed|success"
```

### [ ] Step 6: Verify Transaction Balances
Run immediate reconciliation checks to trace discrepancies between Stripe logs and our internal database:
```bash
# Run on-demand reconciliation audit
./scripts/run-reconciliation.sh --date $(date +%F)
```
Check generated CSV under `reconciliation/reports/*.csv`.

---

## 🛠️ PHASE 3: Repair & Recovery (15 - 30 Minutes)

### [ ] Step 7: Resolve Schema Locks & Re-process
If the error is due to database connection exhaustion or locks, clear blocking queries on Postgres, then replay:
```bash
# Safely re-trigger processing of valid failed webhooks
node scripts/replay_webhooks.js --limit=100
```

### [ ] Step 8: Finalizing Escalation Chain
If ledger mismatches cannot be resolved or data corruption is suspected:
1. Notify **Finance Team** (`@finance`) and **Legal Compliance Team** (`@legal-tech`).
2. Attach the generated reconciliation CSV reports to the escalation Slack note.
3. Keep the feature flag `OFF` until exact hotfixes are committed on the branch.
