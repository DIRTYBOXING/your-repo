-- migrations/20260702_drop_experiments_and_assignments_verified.sql
-- Verified rollback for Module 18 schema: experiments, assignments, exposures, experiment_audit
-- Run with: psql "$PG_CONN" -f migrations/20260702_drop_experiments_and_assignments_verified.sql
-- Includes verification queries and safe drop order.

BEGIN;

-- Drop exposures first (references experiments)
DROP TABLE IF EXISTS exposures CASCADE;

-- Drop experiment_audit (references experiments)
DROP TABLE IF EXISTS experiment_audit CASCADE;

-- Drop assignments (references experiments)
DROP TABLE IF EXISTS assignments CASCADE;

-- Drop experiments last
DROP TABLE IF EXISTS experiments CASCADE;

-- Drop indexes that may have been created separately
DROP INDEX IF EXISTS idx_experiments_status;
DROP INDEX IF EXISTS idx_assignments_experiment;
DROP INDEX IF EXISTS idx_assignments_assigned_at;
DROP INDEX IF EXISTS idx_exposures_experiment_timestamp;
DROP INDEX IF EXISTS idx_exposures_user_timestamp;
DROP INDEX IF EXISTS idx_experiment_audit_experiment_timestamp;

COMMIT;

-- Verification: confirm tables no longer exist
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('experiments','assignments','exposures','experiment_audit')
  ) THEN
    RAISE EXCEPTION 'Verification failed: experiments-related tables still exist after rollback';
  END IF;
END $$;

-- Log success
SELECT 'experiments rollback verified: tables dropped' AS status;
