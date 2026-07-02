-- migrations/20260702_drop_payments_and_webhooks.sql
-- Rollback for payments + webhooks schema
-- Run with: psql "$PG_CONN" -f migrations/20260702_drop_payments_and_webhooks.sql

BEGIN;

DROP TABLE IF EXISTS payout_attempts;
DROP TABLE IF EXISTS payout_batches;
DROP TABLE IF EXISTS ledger_entries;
DROP TABLE IF EXISTS ppv_entitlements;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS provider_transactions;
DROP TABLE IF EXISTS webhook_events;

COMMIT;
