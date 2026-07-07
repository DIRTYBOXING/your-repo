# DFC Operator Quick Card

One-page reference for safe day-to-day operation of DFC quality gates.

## Golden rule

**Repository-native checks are the authority.**
Local assistants are optional.

## Required merge checks (master)

- `DFC CI / analyze + tests`
- `DFC Sonar Quality Gate / sonar scan + quality gate`
- `DFC Routing Spine Check / forbid literal navigation routes`
- `DFC Firebase Security Check / firestore/storage policy checks`
- `DFC Rule Pack Check / rule pack + routing discipline`

If any required check fails: **do not merge**.

## Pre-PR operator checklist

- [ ] `flutter analyze --no-fatal-infos` passes
- [ ] `flutter test` passes
- [ ] No new literal navigation routes
- [ ] Route constants used (`rc.RouteConstants.*`)
- [ ] PR template sections completed
- [ ] Module scope listed (PPV/Admin/Promoter/Creator/SmartCoach/Media)

## Routing guardrail

Never ship new calls like:

- `context.go('/...')`
- `context.push('/...')`
- `Navigator.pushNamed('/...')`

Use shared route constants only.

## Firebase guardrail

- Never allow broad `allow read, write: if true;`
- Never commit secret material
- Validate `firestore.rules` and `firebase.json` on security-sensitive changes

## Sonar guardrail

- Keep `SONAR_TOKEN` configured in GitHub secrets
- Treat Sonar Quality Gate as blocking for merge

## Cline/local assistant policy (important)

- Cline is local tooling only
- Cline is not a CI/runtime dependency
- If paid model access fails, switch to free fallback model and continue

## If paid AI model fails

1. Switch to free fallback model
2. Continue coding locally
3. Run analyzer/tests
4. Open PR
5. Merge only after required GitHub checks pass

## Incident quick triage

1. Identify failed required check
2. Reproduce locally (analyze/tests/routing grep/rules check)
3. Fix root cause in smallest safe change
4. Re-run local checks
5. Push and confirm green required checks

## Canonical docs

- `docs/QUALITY_GATE_SETUP.md`
- `docs/CLINE_USAGE_POLICY.md`
- `docs/CLINE_FREE_MODE_SETUP.md`
- `docs/DFC_SONAR_RULE_PACK.md`
- `docs/DFC_MODULE_SWEEP_CHECKLIST.md`
