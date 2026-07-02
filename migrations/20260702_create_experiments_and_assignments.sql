-- migrations/20260702_create_experiments_and_assignments.sql
-- Module 18 schema: experiments, assignments, exposures, experiment_audit
-- Run with: psql "$PG_CONN" -f migrations/20260702_create_experiments_and_assignments.sql

BEGIN;

CREATE TABLE IF NOT EXISTS experiments (
  "experimentId" TEXT PRIMARY KEY,
  "config" JSONB NOT NULL,
  "variants" TEXT[] NOT NULL,
  "status" TEXT NOT NULL DEFAULT 'active',
  "configVersion" INTEGER NOT NULL DEFAULT 1,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_experiments_status ON experiments("status");

CREATE TABLE IF NOT EXISTS assignments (
  "userId" TEXT NOT NULL,
  "experimentId" TEXT NOT NULL REFERENCES experiments("experimentId") ON DELETE CASCADE,
  "variant" TEXT NOT NULL,
  "assignedAt" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "source" TEXT NOT NULL DEFAULT 'api',
  PRIMARY KEY ("userId", "experimentId")
);
CREATE INDEX IF NOT EXISTS idx_assignments_experiment ON assignments("experimentId");
CREATE INDEX IF NOT EXISTS idx_assignments_assigned_at ON assignments("assignedAt");

CREATE TABLE IF NOT EXISTS exposures (
  "exposureId" TEXT PRIMARY KEY,
  "userId" TEXT NOT NULL,
  "experimentId" TEXT NOT NULL REFERENCES experiments("experimentId") ON DELETE CASCADE,
  "variant" TEXT NOT NULL,
  "timestamp" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "metadata" JSONB
);
CREATE INDEX IF NOT EXISTS idx_exposures_experiment_timestamp ON exposures("experimentId", "timestamp");
CREATE INDEX IF NOT EXISTS idx_exposures_user_timestamp ON exposures("userId", "timestamp");

CREATE TABLE IF NOT EXISTS experiment_audit (
  "changeId" TEXT PRIMARY KEY,
  "experimentId" TEXT NOT NULL REFERENCES experiments("experimentId") ON DELETE CASCADE,
  "actorId" TEXT NOT NULL,
  "change" JSONB NOT NULL,
  "timestamp" TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_experiment_audit_experiment_timestamp ON experiment_audit("experimentId", "timestamp");

INSERT INTO experiments ("experimentId", "config", "variants", "status", "configVersion")
SELECT
  'exp_sample_001',
  '{"hypothesis":"variant_a increases conversion"}'::jsonb,
  ARRAY['control','variant_a'],
  'active',
  1
WHERE NOT EXISTS (
  SELECT 1 FROM experiments WHERE "experimentId" = 'exp_sample_001'
);

COMMIT;
