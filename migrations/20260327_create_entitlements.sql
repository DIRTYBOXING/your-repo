-- migrations/20260327_create_entitlements.sql
-- Entitlement + license audit tables for DFC PPV

CREATE TABLE IF NOT EXISTS entitlements (
  id            SERIAL PRIMARY KEY,
  user_id       TEXT NOT NULL,
  event_id      TEXT NOT NULL,
  token_hash    TEXT NOT NULL,
  device_id     TEXT,
  expires_at    TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_entitlements_token_hash
  ON entitlements(token_hash);
CREATE INDEX IF NOT EXISTS idx_entitlements_user_event
  ON entitlements(user_id, event_id);

CREATE TABLE IF NOT EXISTS license_issuance (
  id            SERIAL PRIMARY KEY,
  user_id       TEXT,
  event_id      TEXT,
  drm_type      TEXT,
  client_ip     TEXT,
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_license_user_event
  ON license_issuance(user_id, event_id);
