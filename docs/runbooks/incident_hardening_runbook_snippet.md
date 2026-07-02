# Incident Runbook Snippet — Hardening Payments/Experiments

Use this snippet for on-call triage during the gated rollout. Attach to the PR and Slack alerts.

## Webhook ingestion failures

**Symptom**: Elevated `webhook_events.status = failed` or webhook handler 5xx.

**Quick checks**
- `psql "$PG_CONN" -c "SELECT type, COUNT(*) FROM webhook_events WHERE status='failed' AND received_at > now() - interval '1 hour' GROUP BY type;"`
- `psql "$PG_CONN" -c "SELECT last_error FROM webhook_events WHERE status='failed' ORDER BY received_at DESC LIMIT 5;"`

**Remediation**
1. If provider is returning invalid payloads: pause replay and notify payments engineer.
2. If DB constraint violation: check `orders.checkout_session_id` unique constraint; dedupe duplicates.
3. If connectivity: verify `PG_CONN` and Postgres availability; restart reference server.
4. Replay missed events after fix: `node scripts/replay_webhooks.js --since="1h ago" --limit=100`

## Reconciliation mismatch

**Symptom**: `provider_transactions.amount` differs from `ledger_entries.amount` for same `provider_tx_id`.

**Quick checks**
- `psql "$PG_CONN" -c "\copy (SELECT provider_tx_id, amount, status FROM provider_transactions WHERE created_at >= CURRENT_DATE - INTERVAL '1 day') TO 'reconciliation_report.csv' CSV HEADER"`
- Compare CSV totals to expected settlement batch.

**Remediation**
1. Document mismatch in incident channel with CSV attached.
2. If provider error: open dispute/dispute flow with provider.
3. If rounding/currency: correct ledger with adjusting entry and note reason.
4. If systemic: rollback feature flag and run migration rollback if schema root cause.

## Duplicate orders / entitlements

**Symptom**: Two `orders` rows with same `checkout_session_id`, or duplicate `ppv_entitlements` for same `order_id`.

**Quick checks**
- `psql "$PG_CONN" -c "SELECT checkout_session_id, COUNT(*) FROM orders GROUP BY checkout_session_id HAVING COUNT(*) > 1;"`
- `psql "$PG_CONN" -c "SELECT order_id, COUNT(*) FROM ppv_entitlements GROUP BY order_id HAVING COUNT(*) > 1;"`

**Remediation**
1. Identify duplicate rows and set status to `void` on extras.
2. Verify idempotency key handling in webhook and verify-session endpoints.
3. Add unique constraint on `orders.checkout_session_id` if missing.
4. Reconcile entitlements and ledger for correctness.

## Escalation

- **Payments engineer**: webhook handler, Stripe config, replay script behavior
- **SRE/DB team**: Postgres connectivity, migration issues, connection pool exhaustion
- **Data**: experiments assignment consistency, randomization mismatches
- **Legal-Tech**: rights/takedown policy flags affecting entitlements
