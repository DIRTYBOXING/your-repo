Test harness notes:
- Ensure migrations for webhook_events, orders, ppv_entitlements, ledger_entries are applied.
- Set PG_CONN to your test DB before running tests.
- Run `npm ci` then `npm test` inside `backend/payments`.
