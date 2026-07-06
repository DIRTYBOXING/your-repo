# DFC Module Sweep Checklist

Use this checklist for each module sweep (PPV, Admin, Promoter, Creator, SmartCoach, Media, Dashboard).

## 0) Scope Declaration

- [ ] Module name declared
- [ ] Files in scope listed
- [ ] Out-of-scope files listed

## 1) Route Discipline

- [ ] No literal routes in navigation calls (`context.go/push/pushReplacement`, `Navigator.pushNamed`)
- [ ] Shared constants only (`rc.RouteConstants.*`)
- [ ] Any temporary alias marked with `TODO remove after migration`

## 2) Import / Namespace Discipline

- [ ] Route constants imported with namespace alias (`as rc`)
- [ ] No symbol collisions with framework classes
- [ ] Dead imports removed

## 3) Service-Layer Integrity

- [ ] No business-critical direct writes from UI when service abstraction exists
- [ ] Auth-sensitive operations verify user/session state
- [ ] External links validated against trusted domain rules where applicable

## 4) Module-Specific Safety

### PPV
- [ ] Entitlement checks before playback
- [ ] Payment routes use constants only
- [ ] Typed models used for pricing/revenue paths

### Admin
- [ ] Privileged actions guarded
- [ ] Audit-sensitive paths reviewed

### Promoter
- [ ] Cross-module navigation uses shared constants
- [ ] Contract/payout flow paths reviewed

### Creator
- [ ] Creator route consistency preserved
- [ ] Content workflow pathing reviewed

## 5) Validation

- [ ] Touched files analyzer-clean
- [ ] Module-level grep confirms no fresh route literals
- [ ] CI checks pass (routing-check, rulepack-check, Firebase-security, CI, Sonar gate)

## 6) PR Artifacts

- [ ] Routing Delta documented (constants added, literals removed, aliases retained)
- [ ] Analyzer proof attached (touched files)
- [ ] Module scope noted in PR template
- [ ] Risk notes documented

## Suggested Sweep Order

1. PPV
2. Admin
3. Promoter
4. Creator
5. SmartCoach
6. Media
7. Dashboard

## Exit Criteria (Module Complete)

A module is complete only when all boxes above are checked and no new CI gate failures are introduced.
