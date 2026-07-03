# Module 16: Rights Enforcement and Regional Blocking

## Title
Implement Rights Enforcement and Regional Blocking

## Owner
@legal-tech

## Files to add/modify
- backend/rights/enforcement_service.dart
- backend/rights/controllers/enforcement_controller.dart
- backend/rights/middleware/region_block_middleware.dart

## APIs required
- GET /rights/{contentId}
- GET /rights/enforce/{contentId}?region={code}
- POST /rights/takedown

## DB collections
- content_rights (contentId, ownerId, rights, allowed_regions)
- geo_policy (contentId, blocked_regions)
- takedown_requests (requestId, contentId, status)

## Tests
- Unit: policy evaluation and enforcement logic
- Integration: region-based access checks with mocked geo IP
- Regression: takedown workflow and audit trail

## Release gate
- Region and rights enforcement returns correct allow/deny for sample dataset
- Takedown requests update content visibility and create audit entries
- No critical policy bypass in red-team tests
