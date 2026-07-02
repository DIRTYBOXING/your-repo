# Runbook Page

## Purpose
Operational runbook for staging validation, migrations, replay, reconciliation, and gated rollout.

## Summary
Hardening branch `hardening/release-<date>` with payments, experiments, UI, and CI changes.

## Preconditions
- Secrets set: `PG_CONN`, `WEBHOOK_SECRET`, `STRIPE_KEY`, `STRIPE_CONNECT`.
- CI secrets and feature flag service available.

## Quick Commands

```bash
git checkout -b hardening/release-$(date +%F)-runbook
git apply 0009-payments.patch
git add backend/payments scripts/replay_webhooks.js
git commit -m "chore(payments): add verify-session and webhook handler"
git push origin HEAD
scripts/test/bootstrap_pg.sh
export PG_CONN="postgres://user:pass@localhost:5432/dfc_test"
psql "$PG_CONN" -f migrations/20260702_create_payments_and_webhooks.sql
node backend/payments/index.js
npx cypress run --spec tests/e2e/subscription_flow.spec.js
```

## Staging Checklist
- [ ] Migrations applied to staging DB.
- [ ] Payments service running and connected to DB.
- [ ] Webhook receiver accepts test events and marks `webhook_events.status = processed`.
- [ ] Replay dry run shows no duplicates.
- [ ] Reconciliation CSV produced and reviewed.
- [ ] Experiments assignment smoke passed (10k sample).
- [ ] CI migration smoke job passed (apply + rollback).

## Rollback Steps

```bash
psql "$PG_CONN" -f migrations/20260702_drop_payments_and_webhooks.sql
psql "$PG_CONN" -f migrations/20260702_drop_experiments_and_assignments.sql
```

## Owners
- Runbook owner: @platform-lead
- SRE: @sre
- Payments: @payments-engineering
- Data: @data

## Acceptance Criteria
All checks green, no critical reconciliation mismatches, CI green.
