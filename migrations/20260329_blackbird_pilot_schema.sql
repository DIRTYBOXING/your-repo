-- migrations/20260329_blackbird_pilot_schema.sql
-- Blackbird Pilot: PostGIS-enabled schema for radar tracks,
-- device locations, watchlist, alerts, and audit evidence.

-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── Radar Tracks ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tracks (
  track_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  node_id       TEXT NOT NULL,
  ts            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  origin        geography(Point, 4326) NOT NULL,
  bearing_deg   FLOAT NOT NULL,
  range_m       FLOAT NOT NULL,
  confidence    FLOAT NOT NULL DEFAULT 0.0,
  raw_payload   JSONB,
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tracks_ts ON tracks(ts DESC);
CREATE INDEX IF NOT EXISTS idx_tracks_origin ON tracks USING GIST(origin);
CREATE INDEX IF NOT EXISTS idx_tracks_node ON tracks(node_id);

-- ─── Device Locations (GPS pings from enrolled phones) ──────────────────────
CREATE TABLE IF NOT EXISTS device_locations (
  id            SERIAL PRIMARY KEY,
  device_id     UUID NOT NULL,
  user_id       TEXT,
  ts            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  geom          geography(Point, 4326) NOT NULL,
  accuracy_m    FLOAT,
  signed        BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_device_loc_ts ON device_locations(ts DESC);
CREATE INDEX IF NOT EXISTS idx_device_loc_geom ON device_locations USING GIST(geom);
CREATE INDEX IF NOT EXISTS idx_device_loc_device ON device_locations(device_id);

-- ─── Watchlist ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS watchlist (
  id            SERIAL PRIMARY KEY,
  kind          TEXT NOT NULL,        -- 'phone', 'device_id', 'name'
  value         TEXT NOT NULL,
  label         TEXT,
  threat_level  TEXT DEFAULT 'medium',
  active        BOOLEAN DEFAULT TRUE,
  added_by      TEXT,
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_watchlist_kind_value ON watchlist(kind, value);

-- ─── Alerts ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS alerts (
  alert_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  level         TEXT NOT NULL,        -- 'Verify', 'Action', 'Resolved'
  reason        TEXT,
  score         FLOAT,
  ts            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  evidence      JSONB,
  exported      BOOLEAN DEFAULT FALSE,
  exported_at   TIMESTAMP WITH TIME ZONE,
  operator_note TEXT
);

CREATE INDEX IF NOT EXISTS idx_alerts_ts ON alerts(ts DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_level ON alerts(level);

-- ─── Audit Log ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_log (
  id            SERIAL PRIMARY KEY,
  operator_id   TEXT NOT NULL,
  action        TEXT NOT NULL,
  target_id     TEXT,
  detail        JSONB,
  ts            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_ts ON audit_log(ts DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_op ON audit_log(operator_id);

-- ─── PostGIS Matching Functions ──────────────────────────────────────────────

-- Compute projected point from track origin, bearing, and range
CREATE OR REPLACE FUNCTION track_point(p_track_id UUID)
RETURNS geography AS $$
DECLARE
  rec RECORD;
  pt  geography;
BEGIN
  SELECT origin, bearing_deg, range_m
    INTO rec FROM tracks WHERE track_id = p_track_id;
  IF NOT FOUND THEN RETURN NULL; END IF;
  pt := ST_Project(rec.origin::geometry, rec.range_m, radians(rec.bearing_deg))::geography;
  RETURN pt;
END;
$$ LANGUAGE plpgsql STABLE;

-- Find device locations near a track within time and distance thresholds
CREATE OR REPLACE FUNCTION find_device_matches(
  p_track_id       UUID,
  p_time_window    INTERVAL,
  p_dist_threshold FLOAT
)
RETURNS TABLE (
  track_id   UUID,
  device_id  UUID,
  device_ts  TIMESTAMP WITH TIME ZONE,
  track_ts   TIMESTAMP WITH TIME ZONE,
  dist_m     FLOAT
) AS $$
BEGIN
  RETURN QUERY
  WITH t AS (
    SELECT
      tr.track_id,
      tr.ts,
      ST_Project(tr.origin::geometry, tr.range_m, radians(tr.bearing_deg))::geography AS track_point
    FROM tracks tr
    WHERE tr.track_id = p_track_id
  )
  SELECT
    t.track_id,
    d.device_id,
    d.ts  AS device_ts,
    t.ts  AS track_ts,
    ST_Distance(t.track_point, d.geom) AS dist_m
  FROM t
  JOIN device_locations d
    ON d.ts BETWEEN t.ts - p_time_window AND t.ts + p_time_window
  WHERE ST_Distance(t.track_point, d.geom) <= p_dist_threshold;
END;
$$ LANGUAGE plpgsql STABLE;

-- Check if a phone number is on the active watchlist
CREATE OR REPLACE FUNCTION is_ping_watchlist_match(p_phone TEXT)
RETURNS BOOLEAN AS $$
DECLARE cnt INT;
BEGIN
  SELECT COUNT(*) INTO cnt
    FROM watchlist
   WHERE kind = 'phone' AND value = p_phone AND active = TRUE;
  RETURN cnt > 0;
END;
$$ LANGUAGE plpgsql STABLE;
