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
