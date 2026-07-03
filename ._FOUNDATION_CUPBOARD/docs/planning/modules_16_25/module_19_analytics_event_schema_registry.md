# Module 19: Analytics Event Schema Registry

## Title
Implement Analytics Event Schema Registry

## Owner
@data-platform

## Files to add/modify
- backend/analytics/schema_registry_service.dart
- infra/analytics/ingest_validator.dart
- docs/analytics/schema_catalog.md

## APIs required
- POST /schema/register
- GET /schema/{eventType}
- POST /ingest/validate (event payload)

## DB collections
- schema_registry (eventType, schemaVersion, schema)
- data_quality_results (eventType, result, timestamp)
- analytics_events (raw events stream)

## Tests
- Unit: schema validation logic
- Integration: ingest validation against registered schemas
- Contract: backward and forward compatibility tests

## Release gate
- Schema registry accepts and validates sample event payloads
- Ingest validator rejects malformed events and logs errors
- Data quality checks pass for sample dataset
