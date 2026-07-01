-- infra/sql/archive_demo_data.sql
-- Safe cleanup: snapshot, soft-flag, and prepare demo/test records for human review.
-- Run ONLY after taking a DB snapshot. Requires human approval before purge.

BEGIN;

-- 1. Create snapshot table if it doesn't exist
CREATE TABLE IF NOT EXISTS demo_flag_snapshot (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_table TEXT NOT NULL,
  record_id TEXT NOT NULL,
  payload JSONB NOT NULL,
  flagged_by TEXT DEFAULT 'ops_auto',
  flagged_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2. Identify suspicious records across key tables and insert into snapshot
WITH flagged_campaigns AS (
  SELECT id::text AS record_id, to_jsonb(c.*) AS payload
  FROM campaigns c
  WHERE lower(id) ~ '(demo_|test_|edu_|sample_|example|placeholder)'
     OR lower(coalesce(c.name,'')) ~ '(demo_|test_|edu_|sample_|example|placeholder)'
),
flagged_markers AS (
  SELECT marker_id::text AS record_id, to_jsonb(m.*) AS payload
  FROM markers m
  WHERE lower(marker_id) ~ '(demo_|test_|edu_|sample_|example|placeholder)'
     OR lower(coalesce(m.venue_name,'')) ~ '(demo_|test_|edu_|sample_|example|placeholder)'
),
flagged_events AS (
  SELECT id::text AS record_id, to_jsonb(e.*) AS payload
  FROM events e
  WHERE lower(id) ~ '(demo_|test_|edu_|sample_|example|placeholder)'
     OR lower(coalesce(e.name,'')) ~ '(demo_|test_|edu_|sample_|example|placeholder)'
)
INSERT INTO demo_flag_snapshot (source_table, record_id, payload, flagged_by)
SELECT 'campaigns', record_id, payload, 'ops_auto' FROM flagged_campaigns
UNION ALL
SELECT 'markers', record_id, payload, 'ops_auto' FROM flagged_markers
UNION ALL
SELECT 'events', record_id, payload, 'ops_auto' FROM flagged_events;

-- 3. Soft-flag live records for human review (requires flagged_demo column)
UPDATE campaigns
SET flagged_demo = true, flagged_by = 'ops_auto', flagged_at = now()
WHERE id::text IN (SELECT record_id FROM demo_flag_snapshot WHERE source_table = 'campaigns');

UPDATE markers
SET flagged_demo = true, flagged_by = 'ops_auto', flagged_at = now()
WHERE marker_id::text IN (SELECT record_id FROM demo_flag_snapshot WHERE source_table = 'markers');

UPDATE events
SET flagged_demo = true, flagged_by = 'ops_auto', flagged_at = now()
WHERE id::text IN (SELECT record_id FROM demo_flag_snapshot WHERE source_table = 'events');

-- 4. Create War Room approval ticket for review
INSERT INTO approvals (job_id, asset_id, type, estimated_spend_usd, influencer_count, provenance, outputs, safety_flags, status, created_at)
VALUES (
  gen_random_uuid(),
  NULL,
  'demo_data_review',
  0,
  0,
  jsonb_build_object('source', 'archive_demo_data.sql', 'run_by', current_user),
  jsonb_build_array(),
  jsonb_build_object('requires_human_review', true),
  'pending',
  now()
);

-- Report flagged counts
SELECT source_table, count(*) AS flagged_count
FROM demo_flag_snapshot
WHERE flagged_at >= now() - interval '1 minute'
GROUP BY source_table;

COMMIT;
