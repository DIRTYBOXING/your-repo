# Staging Hardening Runbook

## Scope
This runbook validates the payments, rights, and experiments paths for a production-hardening snapshot.

## Preconditions
- Docker installed (for local Postgres bootstrap)
- Node.js 20+
- Flutter stable
- Dart SDK available through Flutter
- psql available for direct migration execution

## 1) Create hardening branch snapshot

PowerShell:

$branch = "hardening/release-$(Get-Date -Format yyyy-MM-dd)"
git checkout -b $branch
git add -A
git commit -m "chore(release): snapshot for hardening"
git push origin HEAD

## 2) Bootstrap local Postgres (optional)

PowerShell:

./scripts/test/bootstrap_pg.ps1

This sets PG_CONN in the current shell output. If needed, export it manually:

$env:PG_CONN = "postgres://dfc:dfc@localhost:5432/dfc_test"

Teardown:

./scripts/test/teardown_pg.ps1

## 3) Apply migrations (staging or local)

PowerShell:

psql "$env:PG_CONN" -f migrations/20260702_create_payments_and_webhooks.sql
psql "$env:PG_CONN" -f migrations/20260702_create_rights_and_takedown.sql
psql "$env:PG_CONN" -f migrations/20260702_create_experiments_and_assignments.sql

Rollback smoke:

psql "$env:PG_CONN" -f migrations/20260702_drop_experiments_and_assignments.sql
psql "$env:PG_CONN" -f migrations/20260702_drop_rights_and_takedown.sql
psql "$env:PG_CONN" -f migrations/20260702_drop_payments_and_webhooks.sql

## 4) Start payments reference server

PowerShell:

cd backend/payments
npm ci
$env:PG_CONN = "postgres://dfc:dfc@localhost:5432/dfc_test"
node index.js

Expected:
- log contains server listening message
- no immediate DB connection failures during webhook/verify-session calls

## 5) Run tests

Node payments:

cd backend/payments
npm test

Dart rights and experiments:

flutter pub get
flutter analyze backend/rights backend/experiments test/backend/rights test/experiments
flutter test test/backend/rights
flutter test test/experiments/assignment_test.dart

## 6) Payment flow smoke

- Create checkout session via frontend or API.
- Complete payment in provider test mode.
- Verify rows:

SQL:

SELECT * FROM orders WHERE checkout_session_id = 'cs_test_abc123';
SELECT * FROM ppv_entitlements WHERE order_id = '<orderId>';
SELECT * FROM ledger_entries WHERE order_id = '<orderId>';

## 7) Replay and reconciliation

Dry run replay:

node scripts/replay_webhooks.js --dry-run --limit=20

Small live replay:

node scripts/replay_webhooks.js --limit=20

Reconciliation:

./scripts/run-reconciliation.sh --date $(date +%F)

or

psql "$env:PG_CONN" -c "\copy (SELECT provider_tx_id, amount, status FROM provider_transactions WHERE created_at >= CURRENT_DATE - INTERVAL '1 day') TO 'reconciliation_report.csv' CSV HEADER"

## 8) Acceptance criteria

- CI workflow .github/workflows/payments-ci.yml is green.
- Migration up/down smoke passes.
- Payments node tests pass.
- Rights and experiments tests pass.
- Reconciliation has zero critical mismatches or documented triage items.

## 9) Rollout guidance

1. Deploy behind feature flag (default OFF).
2. Internal canary for 24 hours.
3. Public cohort ramp: 1% -> 10% -> 50% -> 100%.
4. Rollback path: feature flag OFF, run rollback migration if required, replay events.
