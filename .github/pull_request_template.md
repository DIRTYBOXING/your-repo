## Summary

<!-- What does this PR do? Link any related issues. -->

Closes #

---

## One-minute readiness checklist

- [ ] Tests: all unit and integration tests pass locally and in CI.
- [ ] Playwright: smoke suite passes in CI across at least Chromium and one other browser.
- [ ] Secrets: gitleaks reports zero findings for this branch.
- [ ] Dependency health: npm audit has no critical vulnerabilities in runtime paths.
- [ ] CI status checks pass: unit tests, lint, Playwright smoke, gitleaks, dependency scan.
- [ ] Branch protection is enabled on master and requires PR review + passing checks.
- [ ] Code review completed for payments, webhooks, reconciliation, metrics, deploy manifests.
- [ ] Changelog entry added for reconciliation and operational assets.
- [ ] Release tag plan prepared (example: v1.12.0).
- [ ] DFC Sonar rule pack checks pass (`docs/DFC_SONAR_RULE_PACK.md`).

---

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Refactor / cleanup
- [ ] Infrastructure / CI
- [ ] Documentation

---

## Pre-merge checklist

Run these locally before opening the PR. The `dfc-pr-check` Cloud Build gate runs them too — failing any will block merge.

### Node / TypeScript (service changes only)

```bash
# From repo root
cd poster-worker   && npm ci && npm audit --audit-level=high && npx tsc --noEmit; cd ..
cd promotion-worker && npm ci && npm audit --audit-level=high && npx tsc --noEmit; cd ..
cd entitlements-service && npm ci && npm audit --audit-level=high; cd ..
```

### Docker smoke (service changes only)

```bash
docker build -f poster-worker/Dockerfile      -t poster-worker-local      .
docker build -f promotion-worker/Dockerfile   -t promotion-worker-local   .
docker build -f entitlements-service/Dockerfile -t entitlements-local     .
```

### Flutter / Dart

```bash
flutter analyze --no-fatal-infos
flutter test
```

### DFC routing spine checks

```bash
# No literal routes in navigation calls
rg -n "context\.(go|push|pushReplacement)\(\s*['\"]/|Navigator\.pushNamed\(\s*['\"]/" lib/**/*.dart

# Route constants migration markers present
rg -n "TODO remove after migration" lib/core/config/router_constants.dart
```

---

## Affected services

<!-- Tick all that apply -->

- [ ] `poster-worker`
- [ ] `promotion-worker`
- [ ] `entitlements-service`
- [ ] Flutter / Dart (`lib/`)
- [ ] Firebase functions (`functions/`)
- [ ] Firestore rules (`firestore.rules`)
- [ ] CI / deploy config

---

## Code cleanliness (if touching lib/)

- [ ] No Dart file introduced exceeds 400 lines
- [ ] No new TODO / FIXME left without a tracking issue
- [ ] `bash scripts/cleanup_scan.sh` ran locally — no new errors
- [ ] Deleted/moved files approved below (or N/A)

---

## DFC routing / module quality (required for route-affecting PRs)

- [ ] **Routing Delta** documented (constants added, literals removed, legacy aliases tagged).
- [ ] **Analyzer Proof** attached for touched files.
- [ ] **Module Scope** listed (PPV/Admin/Promoter/Creator/SmartCoach/Media/etc.).
- [ ] Cross-module navigation calls use shared constants (`rc.RouteConstants.*`).
- [ ] No fresh literal navigation routes were introduced.

---

## Security notes

<!-- Any auth, secrets, or permission changes? New external endpoints? -->

---

## Owners and Promotion Proof

- [ ] Frontend owner signoff
- [ ] Streaming owner signoff
- [ ] SRE owner signoff
- [ ] Platform owner signoff (if transport or infra changed)

Staging health proof: <!-- https://github.com/<OWNER>/<REPO>/actions/runs/<RUN_ID> -->

Weekly sweep result: <!-- PASS / FAIL with timestamp -->

Transport fallback smoke: <!-- PASS / FAIL -->

---

## Screenshots / recordings (optional)

<!-- UI changes: attach a before/after screenshot or Loom link -->

---

## PPV UI Contract (required for PPV poster changes)

- [ ] I used `PPVPresentationModel.fromEvent` for PPV poster decisions.
- [ ] I did not add poster heuristics directly in UI code.
- [ ] I attached mobile screenshots or visual diffs for 360px, 400px, and 430px widths.
- [ ] I confirmed metadata is owned by either the poster or the surrounding card, not both.
- [ ] I added or updated poster/license metadata if any final artwork was introduced.
