# Module 18 — Experimentation Platform (Core)

**Owner:** @experimentation

**Files to add/modify**
- backend/experiments/experiment_service.dart
- backend/experiments/assignment_service.dart
- backend/experiments/exposure_logger.dart

**APIs required**
- POST /experiments/create
- POST /experiments/assign (userId, experimentId)
- POST /experiments/exposure (userId, experimentId, variant)

**DB collections**
- experiments (experimentId, config, variants)
- assignments (userId, experimentId, variant, timestamp)
- exposures (exposureId, userId, experimentId, variant, timestamp)

**Tests**
- Unit: deterministic assignment logic
- Integration: exposure logging and consistency across retries
- Audit: experiment config immutability tests

**Release gate**
- Deterministic assignment for sample user set
- Exposure logs recorded and queryable
- No assignment drift across restarts
