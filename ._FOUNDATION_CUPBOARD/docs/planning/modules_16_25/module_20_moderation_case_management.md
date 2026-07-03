# Module 20 — Moderation Triage and Case Management

**Owner:** @trust-and-safety

**Files to add/modify**
- backend/moderation/triage_service.dart
- backend/moderation/case_manager.dart
- ui/moderation/moderation_console_stub.dart

**APIs required**
- POST /moderation/report
- GET /moderation/case/{caseId}
- POST /moderation/action/{caseId}

**DB collections**
- reports (reportId, reporterId, targetId, reason, status)
- moderation_cases (caseId, reports[], assignedTo, status)
- actions (actionId, caseId, actionType, actorId, timestamp)

**Tests**
- Unit: triage prioritization logic
- Integration: report → case creation → action flow
- SLA: case assignment and resolution timing tests

**Release gate**
- Reports create cases and assign per routing rules
- Actions applied change content visibility and are auditable
- Case handling SLA met in staging simulation
