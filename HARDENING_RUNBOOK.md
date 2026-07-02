# Hardening Runbook — Data Fight Central
## Staging validation + production rollout

### 1. Create hardening branch and snapshot
```bash
git checkout -b hardening/release-$(date +%F)
git add -A
git commit -m "chore(release): snapshot for hardening"
git push origin HEAD
```

### 2. Apply migrations to fresh staging DB
```bash
export PG_CONN="postgres://user:pass@staging-db:5432/dfc_staging"
psql "$PG_CONN" -f migrations/20260702_create_payments_and_webhooks.sql
psql "$PG_CONN" -f migrations/20260702_create_rights_and_takedown.sql
psql "$PG_CONN" -f migrations/20260702_create_experiments_and_assignments.sql
```

### 3. Start payments reference server
```bash
cd backend/payments
npm ci
export PG_CONN="postgres://user:pass@staging-db:5432/dfc_staging"
node index.js
# confirm logs show "listening" and successful DB connection
```

### 4. Run tests
```bash
# Node payments
cd backend/payments && npm test

# Dart rights + experiments
dart pub get
dart test test/backend/rights
dart test test/experiments/assignment_test.dart

# Python webhooks (if present)
pip install -r requirements.txt
pytest tests/test_webhook.py
```

### 5. Smoke end-to-end payment flow
```bash
# Create checkout session (example)
curl -X POST https://staging.dfc/api/payments/checkout-session \
  -H "Content-Type: application/json" \
  -d '{"user_id":"u_123","product_id":"ppv_456","amount":29.99}'

# Complete payment in provider test UI (Stripe test card 4242...)
# Then verify:
export PG_CONN="postgres://user:pass@staging-db:5432/dfc_staging"
psql "$PG_CONN" -c "SELECT * FROM orders WHERE checkout_session_id = '<CS_ID>';"
psql "$PG_CONN" -c "SELECT * FROM ppv_entitlements WHERE order_id = '<ORDER_ID>';"
psql "$PG_CONN" -c "SELECT * FROM ledger_entries WHERE order_id = '<ORDER_ID>';"
```

### 6. Dry-run replay
```bash
node scripts/replay_webhooks.js --dry-run --limit=20
```

### 7. Small live replay (staging only)
```bash
node scripts/replay_webhooks.js --limit=20
```

### 8. Run reconciliation and export report
```bash
./scripts/run-reconciliation.sh --date $(date +%F)
# or
psql "$PG_CONN" -c "\copy (SELECT provider_tx_id, amount, status FROM provider_transactions WHERE created_at >= CURRENT_DATE - INTERVAL '1 day') TO 'reconciliation_report.csv' CSV HEADER"
```
Acceptance: zero critical mismatches, or document triage items in CSV.

### 9. Rollback plan
```bash
# Feature flag OFF immediately
# Run rollback migration
export PG_CONN="postgres://user:pass@staging-db:5432/dfc_staging"
psql "$PG_CONN" -f migrations/20260702_drop_experiments_and_assignments.sql
psql "$PG_CONN" -f migrations/20260702_drop_rights_and_takedown.sql
psql "$PG_CONN" -f migrations/20260702_drop_payments_and_webhooks.sql

# Reconcile missed events (if needed)
node scripts/replay_webhooks.js --since="2h ago"
```

### 10. Ownership contacts
| Area | Owner |
|---|---|
| Payments flow & replay | Payments engineer |
| DB migrations & infra | SRE / DB team |
| Rights & takedown | Legal-Tech |
| Experiments platform | Data / Experimentation |
| CI & gating | CI/SRE |
| QA & smoke validation | QA lead |
| Monitoring & alerts | SRE / Observability |
