-- migrations/20260702_drop_experiments_and_assignments.sql
-- Rollback for Module 18 schema
-- Run with: psql "$PG_CONN" -f migrations/20260702_drop_experiments_and_assignments.sql

BEGIN;

DROP TABLE IF EXISTS experiment_audit;
DROP TABLE IF EXISTS exposures;
DROP TABLE IF EXISTS assignments;
DROP TABLE IF EXISTS experiments;

COMMIT;
