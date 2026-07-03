# Patch C Test Harness and Rollback Runbook

This runbook validates Patch C (CI + tests + migrations) end-to-end in local and CI contexts.

## Scope

- backend/payments tests (unit + optional PG integration)
- backend/rights and backend/experiments analyze + tests
- migration up/down smoke for payments, rights, experiments

## Prerequisites

- Docker running locally
- Flutter SDK installed
- Node.js 20+
- PostgreSQL client (`psql`) available if running migrations directly from host

## Local Quickstart (PowerShell)

1. Start ephemeral PostgreSQL:

```powershell
./scripts/test/bootstrap_pg.ps1
```

2. Apply migrations up:

```powershell
psql $env:PG_CONN -f migrations/20260702_create_payments_and_webhooks.sql
psql $env:PG_CONN -f migrations/20260702_create_rights_and_takedown.sql
psql $env:PG_CONN -f migrations/20260702_create_experiments_and_assignments.sql
```

3. Run payments tests:

```powershell
cd backend/payments
npm ci
$env:RUN_PG_INTEGRATION = "1"
npm test
cd ../..
```

4. Run Flutter scoped checks:

```powershell
flutter pub get
flutter analyze backend/rights backend/experiments test/backend/rights test/experiments
flutter test test/backend/rights
flutter test test/experiments/assignment_test.dart
```

5. Roll back migrations (down order):

```powershell
psql $env:PG_CONN -f migrations/20260702_drop_experiments_and_assignments.sql
psql $env:PG_CONN -f migrations/20260702_drop_rights_and_takedown.sql
psql $env:PG_CONN -f migrations/20260702_drop_payments_and_webhooks.sql
```

6. Tear down container:

```powershell
./scripts/test/teardown_pg.ps1
```

## Local Quickstart (bash)

1. Start PostgreSQL:

```bash
./scripts/test/bootstrap_pg.sh
export PG_CONN="postgres://dfc:dfc@localhost:5432/dfc_test"
```

2. Migrations up:

```bash
psql "$PG_CONN" -f migrations/20260702_create_payments_and_webhooks.sql
psql "$PG_CONN" -f migrations/20260702_create_rights_and_takedown.sql
psql "$PG_CONN" -f migrations/20260702_create_experiments_and_assignments.sql
```

3. Tests:

```bash
(
  cd backend/payments
  npm ci
  RUN_PG_INTEGRATION=1 npm test
)
flutter pub get
flutter analyze backend/rights backend/experiments test/backend/rights test/experiments
flutter test test/backend/rights
flutter test test/experiments/assignment_test.dart
```

4. Migrations down + teardown:

```bash
psql "$PG_CONN" -f migrations/20260702_drop_experiments_and_assignments.sql
psql "$PG_CONN" -f migrations/20260702_drop_rights_and_takedown.sql
psql "$PG_CONN" -f migrations/20260702_drop_payments_and_webhooks.sql
./scripts/test/teardown_pg.sh
```

## CI Gate Expectations

`payments-ci.yml` now enforces:

- `migration-smoke`: up + down migration chain in isolated Postgres
- `payments-node-test`: backend/payments tests against PG with `RUN_PG_INTEGRATION=1`
- `dart-rights-experiments-test`: flutter analyze + targeted flutter tests

All three jobs must pass before merge.

## Rollback Procedure (Production Hotfix)

If Patch C must be rolled back quickly:

1. Revert the commit that introduced Patch C workflow/scripts/docs.
2. Execute down migrations if schema introduced by this patch was already applied:

```sql
\i migrations/20260702_drop_experiments_and_assignments.sql
\i migrations/20260702_drop_rights_and_takedown.sql
\i migrations/20260702_drop_payments_and_webhooks.sql
```

3. Validate service health checks and core payment read paths.
4. Re-run baseline CI for the previous stable commit.

## Notes

- Integration tests are intentionally gated by `RUN_PG_INTEGRATION=1`.
- Use ephemeral DB instances only for CI/local harness runs.
- Keep migration ordering consistent with this runbook to avoid FK dependency issues.
