# Modules 16-25 PR Templates and Branch Plan

## Branch Naming Standard
- feat/module-16-rights-enforcement
- feat/module-17-search-autosuggest
- feat/module-18-experimentation-core
- feat/module-19-schema-registry
- feat/module-20-moderation-case-management
- feat/module-21-safety-ml-scoring
- feat/module-22-notifications-fallback
- feat/module-23-messaging-moderation-rate-limits
- feat/module-24-campaign-manager-pacing
- feat/module-25-reconciliation-disputes

## PR Title Standard
- feat(module-XX): <short module outcome>

Example:
- feat(module-16): enforce regional content rights and takedowns

## PR Body Template

### Summary
- Implements Module XX from planning tracker.
- Scope: <service/controller/middleware/worker changes>

### APIs
- <list endpoints added or changed>

### Data Contracts
- <list collections/tables touched>

### Tests Added
- Unit:
- Integration:
- Load/Regression:

### Release Gate Evidence
- [ ] Gate 1 met:
- [ ] Gate 2 met:
- [ ] Gate 3 met:

### Rollback Plan
- Revert PR commit(s).
- Disable feature flag or route guard.
- Re-run smoke checks.

## Required Labels
- backend
- frontend
- infra
- data
- safety
- payments
- priority:<high|medium|critical>

## Merge Checklist
- [ ] `flutter pub get`
- [ ] `dart analyze`
- [ ] module unit tests
- [ ] module integration tests
- [ ] architecture verifier
- [ ] release gate evidence attached

## Suggested Delivery Sequence
1. Module 16 and 19
2. Module 20 and 23
3. Module 17 and 18
4. Module 22 and 24
5. Module 21
6. Module 25

Reasoning: legal/data contracts and safety controls before growth and payouts cutover.
