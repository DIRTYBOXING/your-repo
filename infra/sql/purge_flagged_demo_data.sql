-- infra/sql/purge_flagged_demo_data.sql
-- Run ONLY after human approval in War Room.
-- Moves flagged records to archive tables and deletes from live tables.
-- Reversible: restore from archive tables if needed.

BEGIN;

-- 1. Create archive tables if they don't exist
CREATE TABLE IF NOT EXISTS campaigns_archive (LIKE campaigns INCLUDING ALL, archived_at TIMESTAMP WITH TIME ZONE DEFAULT now());
CREATE TABLE IF NOT EXISTS markers_archive (LIKE markers INCLUDING ALL, archived_at TIMESTAMP WITH TIME ZONE DEFAULT now());
CREATE TABLE IF NOT EXISTS events_archive (LIKE events INCLUDING ALL, archived_at TIMESTAMP WITH TIME ZONE DEFAULT now());

-- 2. Move flagged campaigns to archive and delete from live table
WITH moved_campaigns AS (
  DELETE FROM campaigns
  WHERE flagged_demo = true
  RETURNING *
)
INSERT INTO campaigns_archive
SELECT mc.*, now() AS archived_at FROM moved_campaigns mc;

-- 3. Move flagged markers to archive and delete from live table
WITH moved_markers AS (
  DELETE FROM markers
  WHERE flagged_demo = true
  RETURNING *
)
INSERT INTO markers_archive
SELECT mm.*, now() AS archived_at FROM moved_markers mm;

-- 4. Move flagged events to archive and delete from live table
WITH moved_events AS (
  DELETE FROM events
  WHERE flagged_demo = true
  RETURNING *
)
INSERT INTO events_archive
SELECT me.*, now() AS archived_at FROM moved_events me;

-- 5. Record audit entry
INSERT INTO audit (actor, action, resource, details, timestamp)
VALUES (
  current_user,
  'purge_demo_data',
  'campaigns,markers,events',
  jsonb_build_object(
    'note', 'Purged flagged demo/test records after human approval',
    'approval_ticket', 'see War Room'
  ),
  now()
);

-- 6. Report purge counts
SELECT 'campaigns_archived' AS metric, count(*) FROM campaigns_archive WHERE archived_at >= now() - interval '1 minute'
UNION ALL
SELECT 'markers_archived', count(*) FROM markers_archive WHERE archived_at >= now() - interval '1 minute'
UNION ALL
SELECT 'events_archived', count(*) FROM events_archive WHERE archived_at >= now() - interval '1 minute';

COMMIT;
