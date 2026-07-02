-- migrations/20260702_create_rights_and_takedown.sql
-- Rights and takedown schema for Module 16
-- Run with: psql $PG_CONN -f migrations/20260702_create_rights_and_takedown.sql
-- Rollback: psql $PG_CONN -f migrations/20260702_drop_rights_and_takedown.sql

BEGIN;

-- content_rights: canonical rights metadata for content items
CREATE TABLE IF NOT EXISTS content_rights (
  content_id TEXT PRIMARY KEY,
  owner_id TEXT NOT NULL,
  rights JSONB NOT NULL,
  allowed_regions TEXT[],
  min_age INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_content_rights_owner ON content_rights(owner_id);
CREATE INDEX IF NOT EXISTS idx_content_rights_allowed_regions ON content_rights USING GIN (allowed_regions);

-- geo_policy: explicit per-content geo blocks or overrides
CREATE TABLE IF NOT EXISTS geo_policy (
  id SERIAL PRIMARY KEY,
  content_id TEXT NOT NULL REFERENCES content_rights(content_id) ON DELETE CASCADE,
  blocked_regions TEXT[],
  allow_overrides JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_geo_policy_content_id ON geo_policy(content_id);

-- takedown_requests: audit trail for takedown submissions and status
CREATE TABLE IF NOT EXISTS takedown_requests (
  request_id TEXT PRIMARY KEY,
  content_id TEXT NOT NULL REFERENCES content_rights(content_id) ON DELETE CASCADE,
  requester_id TEXT NOT NULL,
  reason TEXT,
  evidence JSONB,
  status TEXT NOT NULL DEFAULT 'open',
  assigned_to TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_takedown_requests_content_id ON takedown_requests(content_id);
CREATE INDEX IF NOT EXISTS idx_takedown_requests_status ON takedown_requests(status);

-- sample seed data for local testing (no production effect)
INSERT INTO content_rights(content_id, owner_id, rights, allowed_regions, min_age)
SELECT 'content_sample_001', 'creator_sample_001', '{"canStream": true, "license":"standard"}'::jsonb, ARRAY['AU','US','GB'], 18
WHERE NOT EXISTS (SELECT 1 FROM content_rights WHERE content_id = 'content_sample_001');

INSERT INTO geo_policy(content_id, blocked_regions)
SELECT 'content_sample_001', ARRAY['CN','KP'] WHERE NOT EXISTS (SELECT 1 FROM geo_policy WHERE content_id = 'content_sample_001');

INSERT INTO takedown_requests(request_id, content_id, requester_id, reason, evidence, status)
SELECT 'td_sample_001', 'content_sample_001', 'user-test-001', 'copyright claim', '{"links":["http://example.com/claim"]}'::jsonb, 'actioned'
WHERE NOT EXISTS (SELECT 1 FROM takedown_requests WHERE request_id = 'td_sample_001');

COMMIT;

-- End of rights/takedown migration
