# DFC Developer Onboarding

This guide gets engineers shipping quickly across all DFC modules while staying compliant with routing, CI, Sonar, Firebase, and rule-pack governance.

## 1) Platform mental model (read first)

DFC is a platform, not a single app.

- Frontend: Flutter multi-module surfaces (`PPV`, `Admin`, `Promoter`, `Creator`, `SmartCoach`, `Media`, etc.)
- Backend: Firebase + selected GCP services
- Governance: GitHub Actions + branch protection + Sonar + rule-pack + routing checks
- Local AI tooling: Cline + MCP (assistive only, never runtime authority)

Start with these canonical docs:

- `docs/DFC_PLATFORM_MASTER_MAP.md`
- `docs/DFC_PLATFORM_GOVERNANCE.md`
- `docs/DFC_ENTERPRISE_ROADMAP.md`
- `docs/DFC_MCP_ARCHITECTURE_MAP.md`

## 2) First-day setup

1. Install core tooling:
   - VS Code
   - Flutter/Dart SDKs
   - Node.js
   - Firebase CLI
2. Open **repo root** in VS Code (do not work from isolated subfolders).
3. If needed for your lane, create local environment config from project examples and fill only required values.
4. Run dependency install:

```powershell
flutter pub get
```

## 3) Fast daily dev loop (recommended)

1. Implement scoped changes in one module/lane.
2. Run local validation:

```powershell
flutter analyze --no-fatal-infos
flutter test
```

3. Ensure routing and rule-pack constraints are still clean.
4. Open PR with module scope + proof.
5. Merge only when required checks are green.

## 4) Required CI gates (merge-blocking)

These checks are authoritative:

- `DFC CI / analyze + tests`
- `DFC Sonar Quality Gate / sonar scan + quality gate`
- `DFC Routing Spine Check / forbid literal navigation routes`
- `DFC Firebase Security Check / firestore/storage policy checks`
- `DFC Rule Pack Check / rule pack + routing discipline`

Reference: `docs/QUALITY_GATE_SETUP.md`

## 5) Routing spine discipline (critical)

Use shared route constants and centralized routing ownership.

Do not introduce literal navigation routes like:

- `context.go('/...')`
- `context.push('/...')`
- `Navigator.pushNamed('/...')`

Why: prevents cross-module drift and route breakage.

## 6) Rule-pack and sweep discipline

Follow these docs in every feature lane:

- `docs/DFC_SONAR_RULE_PACK.md`
- `docs/DFC_MODULE_SWEEP_CHECKLIST.md`
- `.github/pull_request_template.md`

PR expectations:

- scope declared
- analyzer/test proof included
- routing delta explained when relevant
- no unresolved critical quality/security regressions

## 7) MCP + Cline usage (correct boundaries)

MCP/Cline are local accelerators.

Allowed:

- repo inspection/patching
- local validation automation
- controlled Firebase admin diagnostics

Not allowed:

- treating MCP/Cline as backend/runtime
- bypassing CI/security/routing/rule-pack enforcement

References:

- `docs/CLINE_USAGE_POLICY.md`
- `docs/CLINE_FREE_MODE_SETUP.md`
- `docs/DFC_MCP_SERVER_COMPARISON_TABLE.md`
- `docs/DFC_OPERATOR_QUICK_CARD.md`

## 8) Priority 1 PPV verification lane

Before changing entitlement, playback, settlement, or monetization paths, run the PPV lane.

### Commands

```powershell
npm --prefix entitlements-service start
node scripts/ppv_runtime_readiness_check.mjs
npm --prefix entitlements-service run test:smoke
```

### VS Code tasks

- `PPV: Start Entitlement Proxy`
- `PPV: Runtime Readiness Check`
- `PPV: Runtime Readiness Success Harness`
- `PPV: Smoke Entitlement Proxy`
- `PPV: Priority 1 Verification Lane`

### What the readiness check protects

It fails if:

- entitlement env is incomplete
- entitlement proxy is unreachable
- transport would silently fall through to deployed production URL

This prevents accidental production-side behavior during local verification.

### Redis note

Smoke verification does not require a live Redis instance. Prefer existing smoke seams unless explicitly working on Redis-backed JTI paths.

Optional success harness:

```powershell
node scripts/ppv_runtime_readiness_success_harness.mjs
```

### PPV-critical files

- `entitlements-service/server.js`
- `entitlements-service/tests/smokeCompatProxy.js`
- `scripts/ppv_runtime_readiness_check.mjs`
- `.vscode/tasks.json`
- `docs/DFC_PPV_PUBLIC_READINESS_PLAN.md`
- `docs/DFCalive_OPS_RUNBOOK.md`

## 9) Mission Control and storefront runtime wiring

Runtime defines expected by operator/storefront surfaces:

- `DFC_OPERATOR_FUNCTION_URL`
- `DFC_OPERATOR_ID`
- `DFC_OPERATOR_SECRET`
- `DFC_PPV_STOREFRONT_BASE`
- `DFC_PPV_AUTO_CONFIRM_SANDBOX`

Safety rule:

- `DFC_OPERATOR_SECRET` is internal-operator only
- never ship it in public consumer builds

Example internal operator run:

```powershell
flutter run -d windows `
   --dart-define=DFC_OPERATOR_FUNCTION_URL="https://australia-southeast1-datafightcentral.cloudfunctions.net/operatorAction" `
   --dart-define=DFC_OPERATOR_ID="ops_alpha" `
   --dart-define=DFC_OPERATOR_SECRET="replace-with-internal-operator-secret" `
   --dart-define=DFC_PPV_STOREFRONT_BASE="https://australia-southeast1-datafightcentral.cloudfunctions.net" `
   --dart-define=DFC_PPV_AUTO_CONFIRM_SANDBOX=true
```

Example public storefront run:

```powershell
flutter run -d chrome `
   --dart-define=DFC_PPV_STOREFRONT_BASE="https://australia-southeast1-datafightcentral.cloudfunctions.net" `
   --dart-define=DFC_PPV_AUTO_CONFIRM_SANDBOX=false
```

## 10) Security baseline for every engineer

- Never commit secrets
- Respect Firebase rules and policy checks
- Keep least-privilege assumptions in service/workflow changes
- Treat failing security checks as release blockers

## 11) New engineer PR checklist

- [ ] Scoped changes (module + files clearly listed)
- [ ] `flutter analyze --no-fatal-infos` passes
- [ ] `flutter test` passes
- [ ] No new literal routes
- [ ] Rule-pack constraints satisfied
- [ ] PR template completed
- [ ] Required checks green before merge

## 12) Escalation pattern when blocked

When asking for help, include:

- failing check name
- exact file list touched
- module impacted
- local analyze/test output
- whether issue is routing, Firebase security, Sonar, or PPV runtime lane

This keeps triage fast and accurate.

## 13) First-week success target

- Day 1: local setup + run + pass analyze/tests
- Day 2: one small merge through full gates
- Day 3+: module-level ownership with governance compliance

Success definition: fast delivery with zero governance bypass and zero platform drift.
