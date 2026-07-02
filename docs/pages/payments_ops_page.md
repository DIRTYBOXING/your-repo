# Payments Ops Page

## Purpose
Operational console for webhooks, verify-session, replay, ledger, reconciliation, and payouts.

## API Contracts
- `POST /payments/webhook`: verify signature, persist `webhook_events`, acknowledge quickly.
- `POST /internal/payments/verify-session`: idempotent creation of `orders`, `ppv_entitlements`, `ledger_entries`.
- `POST /internal/payments/replay`: replay events by `event_id` or time range.

## Run Commands

```bash
node scripts/replay_webhooks.js --dry-run --limit=100
node scripts/replay_webhooks.js --limit=50
./scripts/run-reconciliation.sh --date 2026-07-02
```

## Operational Views
- Webhook queue filtered by status (`pending`, `processed`, `failed`).
- Replay log with event id, attempts, and result.
- Ledger view by `order_id`.
- Reconciliation report CSV export and triage links.

## Idempotency Rules
- Unique constraint on `checkout_session_id`.
- `verify-session` checks for existing order and returns it.
- Emit events only after DB commit.

## Escalation
If reconciliation shows critical mismatch, open incident and notify @finance and @legal-tech.

## Owners
- Payments ops: @payments-ops
- Finance: @finance

## Acceptance Criteria
Replay is idempotent and reconciliation mismatches are triaged within SLA.

## Staging & Canary Monitoring Controls

### 1. Prometheus / Grafana Scrape Spec & Alert Rules
Define these custom metrics for SRE to wire up alerting directly to PagerDuty and Slack:

```yaml
groups:
  - name: dfc-payments-mesh-rules
    rules:
      - alert: DFCWebhookFailureElevated
        expr: sum(rate(dfc_webhook_events_total{status="failed"}[5m])) / sum(rate(dfc_webhook_events_total[5m])) * 100 > 1.0
        for: 5m
        labels:
          severity: warning
          tier: payments
        annotations:
          summary: "Elevated Webhook Ingestion Failures detected"
          description: "Staging Webhook endpoint is failing to process events. Success rate currently < 99%."
          runbook: "docs/runbooks/incident_hardening_runbook_snippet.md"

      - alert: DFCPaymentLatencyElevated
        expr: histogram_quantile(0.95, sum(rate(dfc_verify_session_duration_seconds_bucket[5m])) by (le)) > 5.0
        for: 5m
        labels:
          severity: critical
          tier: payments
        annotations:
          summary: "P95 Payment verify-session duration is extremely high"
          description: "Staging payment processing exceeds 5 seconds for 95% of sessions."
          runbook: "docs/runbooks/incident_hardening_runbook_snippet.md"

      - alert: DFCReconciliationMismatchCritical
        expr: dfc_reconciliation_mismatch_count > 0
        for: 1m
        labels:
          severity: critical
          tier: finance
        annotations:
          summary: "Nightly Reconciliation Mismatch Detected"
          description: "Unexplained ledger mismatches between provider logs and internal ledger entries."
          runbook: "docs/runbooks/incident_hardening_runbook_snippet.md"
```

### 2. Feature Flag (Canary Deploy) CLI Controls
To deploy the platform mesh safely using progressive canary rings, use the following operational shell commands:

```bash
# Ring 0: Deploy behind feature flag default-off
dfc-admin-cli flags create --key="ppv-payments-mesh" --type="boolean" --default=false --description="Idempotent payments, event database & deterministic assignment"

# Ring 1: Enable for internal whitelisted developers (Canary 1%)
dfc-admin-cli flags update-rules --key="ppv-payments-mesh" --add-rule="userId IN ('test-user-001', 'sre-auth-999', 'platform-lead')" --variation=true

# Ring 2: Roll out progressive traffic buckets deterministically (Canary 10%)
dfc-admin-cli flags update-rules --key="ppv-payments-mesh" --rollout=10 --variation=true

# Ring 3: Global Roll out (100% Traffic)
dfc-admin-cli flags update-rules --key="ppv-payments-mesh" --default=true
```

### 3. Progressive Rollout Monitoring Checklist

- **Webhook success rate**: target ≥ 99.9% over 5m
- **verify-session p95 latency**: target < 2s (flag warning if > 5s)
- **Reconciliation daily mismatches**: target = 0 (flag critical if > 0)
- **Exposure event pipeline flow**: target < 30s latency from action to analytics warehouse in staging/canary.
