 YOU WORKINGH OR STUCK -- migrations/20260702_create_payments_and_webhooks.sql
-- Create payments, webhooks, entitlements, ledger, provider transactions, and payout tables
-- Run with: psql $PG_CONN -f migrations/20260702_create_payments_and_webhooks.sql
-- Rollback: psql $PG_CONN -f migrations/20260702_drop_payments_and_webhooks.sql

BEGIN;

-- webhook_events: store raw provider events for replay and audit
CREATE TABLE IF NOT EXISTS webhook_events (
  event_id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  raw_payload JSONB NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'pending', -- pending | processed | failed
  retry_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT
);
CREATE INDEX IF NOT EXISTS idx_webhook_events_status_received_at ON webhook_events(status, received_at);

-- provider_transactions: canonical provider transaction records (mirror provider ledger)
CREATE TABLE IF NOT EXISTS provider_transactions (
  provider_tx_id TEXT PRIMARY KEY,
  provider TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  currency TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  raw_payload JSONB
);
CREATE INDEX IF NOT EXISTS idx_provider_transactions_created_at ON provider_transactions(created_at);

-- orders: canonical order records created after successful payment
CREATE TABLE IF NOT EXISTS orders (
  order_id TEXT PRIMARY KEY,
  checkout_session_id TEXT UNIQUE,
  provider_payment_id TEXT, -- e.g., payment_intent or charge id
  user_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  currency TEXT NOT NULL,
  status TEXT NOT NULL, -- created | paid | refunded | canceled
  provider TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_provider_payment_id ON orders(provider_payment_id);

-- ppv_entitlements: access grants for PPV events
CREATE TABLE IF NOT EXISTS ppv_entitlements (
  entitlement_id TEXT PRIMARY KEY,
  order_id TEXT REFERENCES orders(order_id) ON DELETE SET NULL,
  user_id TEXT NOT NULL,
  event_id TEXT NOT NULL,
  valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
  valid_until TIMESTAMPTZ,
  granted_by TEXT NOT NULL, -- webhook | manual | admin
  revoked_at TIMESTAMPTZ,
  revoked_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_entitlements_user_event ON ppv_entitlements(user_id, event_id);

-- ledger_entries: accounting ledger for platform and creators
CREATE TABLE IF NOT EXISTS ledger_entries (
  entry_id TEXT PRIMARY KEY,
  order_id TEXT REFERENCES orders(order_id) ON DELETE SET NULL,
  account_id TEXT NOT NULL, -- platform or creator account
  amount NUMERIC(12,2) NOT NULL, -- positive credit, negative debit
  currency TEXT NOT NULL,
  type TEXT NOT NULL, -- sale | fee | payout | refund | dispute
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ledger_entries_order_id ON ledger_entries(order_id);

-- payout_batches and attempts for creator payouts
CREATE TABLE IF NOT EXISTS payout_batches (
  batch_id TEXT PRIMARY KEY,
  status TEXT NOT NULL, -- pending | processing | completed | failed
  total_amount NUMERIC(12,2) NOT NULL,
  currency TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS payout_attempts (
  attempt_id TEXT PRIMARY KEY,
  batch_id TEXT REFERENCES payout_batches(batch_id) ON DELETE CASCADE,
  provider_response JSONB,
  status TEXT NOT NULL, -- attempted | success | failed
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- sample seed rows for local testing (safe defaults)
INSERT INTO provider_transactions(provider_tx_id, provider, amount, currency, status, raw_payload)
SELECT 'tx_sample_001', 'stripe', 19.99, 'AUD', 'settled', '{}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM provider_transactions WHERE provider_tx_id = 'tx_sample_001');

INSERT INTO orders(order_id, checkout_session_id, provider_payment_id, user_id, product_id, amount, currency, status, provider, metadata)
SELECT 'order_sample_001', 'cs_sample_001', 'pi_sample_001', 'user-test-001', 'ppv-evt-101', 19.99, 'AUD', 'paid', 'stripe', '{"source":"fixture"}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM orders WHERE order_id = 'order_sample_001');

INSERT INTO ppv_entitlements(entitlement_id, order_id, user_id, event_id, granted_by)
SELECT 'ent_sample_001', 'order_sample_001', 'user-test-001', 'ppv-evt-101', 'seed' WHERE NOT EXISTS (SELECT 1 FROM ppv_entitlements WHERE entitlement_id = 'ent_sample_001');

COMMIT;

-- End of migration
