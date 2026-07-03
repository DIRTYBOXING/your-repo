# Module 21 — Safety ML Scoring Service (text/image/video)

**Owner:** @safety-ml

**Files to add/modify**
- backend/safety/scoring_service.dart
- infra/safety/model_hosting_adapter.dart
- backend/safety/score_store.dart

**APIs required**
- POST /safety/score (payload)
- GET /safety/score/{id}

**DB collections**
- moderation_scores (itemId, modelVersion, score, metadata)
- model_versions (modelId, version, metadata)
- false_positive_audit (itemId, auditResult)

**Tests**
- Offline: precision/recall evaluation tests
- Integration: scoring pipeline with mock model host
- Drift: model versioning and rollback tests

**Release gate**
- Model metrics meet baseline thresholds on validation set
- Scoring pipeline records model version and score for each item
- False positive audit workflow in place
