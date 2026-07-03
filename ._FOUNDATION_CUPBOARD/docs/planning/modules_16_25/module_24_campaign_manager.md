# Module 24 — Campaign Manager and Budget Pacing

**Owner:** @growth

**Files to add/modify**
- backend/campaigns/manager_service.dart
- backend/campaigns/pacing_worker.dart
- ui/campaigns/campaign_console_stub.dart

**APIs required**
- POST /campaigns/create
- GET /campaigns/{id}/status
- POST /campaigns/allocate_budget

**DB collections**
- campaigns (campaignId, budget, targeting, status)
- delivery_stats (campaignId, impressions, spend, timestamp)
- audience_segments (segmentId, criteria)

**Tests**
- Unit: pacing algorithm tests
- Integration: budget spend simulation
- Attribution: basic conversion attribution tests

**Release gate**
- Pacing keeps spend within budget for sample simulation
- Campaign delivery stats recorded and queryable
- No overspend in staging simulation
