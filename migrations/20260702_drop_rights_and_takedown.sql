-- migrations/20260702_drop_rights_and_takedown.sql

BEGIN;
DROP TABLE IF EXISTS takedown_requests;
DROP TABLE IF EXISTS geo_policy;
DROP TABLE IF EXISTS content_rights;
COMMIT;
