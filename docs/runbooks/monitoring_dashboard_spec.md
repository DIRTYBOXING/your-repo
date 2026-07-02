# Monitoring Dashboard Spec — Hardening Rollout

Provide this one-pager to SRE/Observability for dashboarding and alerting during the gated rollout.

## Required Metrics

| Metric | Source | Aggregation | Window |
|---|---|---|---|
| webhook_failure_rate | webhook_events (status=failed / total) | sum(failed)/sum(total) | 5m |
| payment_success_rate | provider_transactions (status=succeeded / total) | sum(succeeded)/sum(total) | 15m |
| entitlement_creation_latency | ppv_entitlements creation timestamp delta from webhook received_at | p95 | 1m |
| reconciliation_mismatches | daily reconciliation run output | count | 24h |
| chargeback_dispute_rate | provider_transactions (status=disputed / total) | sum(disputed)/sum(total) | 24h |

## Alert Thresholds

| Alert | Condition | Severity | Notification |
|---|---|---|---|
| Webhook failure rate | > 1% over 5m | warning | Slack #oncall |
| Payment success rate | < 99% over 15m | critical | Slack #oncall + page |
| Entitlement creation latency | p95 > 5s over 5m | warning | Slack #oncall |
| Reconciliation mismatches | > 0 per day | critical | Slack #oncall + incident link |
| Chargeback/dispute rate | > 0.5% over 24h | critical | Slack #oncall + incident link |

## Dashboard Panels

1. **Webhook pipeline health**
   - Incoming rate (events/min)
   - Failure rate by event type
   - Retry count distribution
   - Last error sample

2. **Payments funnel**
   - Checkout session creation rate
   - Payment success rate
   - Average order value
   - Entitlement creation latency p95

3. **Reconciliation**
   - Daily mismatch count
   - CSV diff summary
   - Provider transaction volume vs ledger volume

4. **Experiments**
   - Assignment rate by variant
   - Exposure count per experiment
   - Sample size progress

5. **Rights/takedown**
   - Content_rights flags applied
   - Takedown request queue depth
   - Geo_policy matches

## Incident Links

Attach these runbooks to each critical alert:
- Webhook failure: `docs/runbooks/incident_hardening_runbook_snippet.md`
- Reconciliation mismatch: `docs/runbooks/incident_hardening_runbook_snippet.md`
- Duplicate orders: `docs/runbooks/incident_hardening_runbook_snippet.md`

## Data Freshness

- Metrics: 30s scrape interval
- Logs: 1m retention for alert evaluation
- Reconciliation: nightly at 02:00 UTC; manual run available via `./scripts/run-reconciliation.sh --date $(date +%F)`
