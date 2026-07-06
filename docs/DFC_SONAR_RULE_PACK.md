# DFC Sonar Rule Pack (Production)

This rule pack is tuned for Data Fight Central’s architecture:
Flutter + Firebase + PPV + Admin + Promoter + Creator + multi-module routing.

## Required Sonar Stack (Minimal)

1. **SonarQube for IDE (SonarLint)**
2. **Sonar Copilot Assistant**

Optional:
- SonarQube Lint Scanner (offline scans / exports)

---

## Quality Gate (must pass)

Apply these gate rules on **New Code**:

- Reliability Rating: **A**
- Security Rating: **A**
- Maintainability Rating: **A**
- New Blocker Issues: **0**
- New Critical Issues: **0**
- New Security Hotspots Reviewed: **100%**
- New Duplicated Lines (%): **<= 3%**
- Coverage on New Code: **>= 80%**

For legacy code, prioritize New Code gate first to avoid migration deadlock.

---

## Core DFC Rules (enforce across all modules)

## 1) Routing Spine Integrity

### Rule R1 — No hardcoded route literals in navigation calls
Disallow direct string literals in:
- `context.go(...)`
- `context.push(...)`
- `context.pushReplacement(...)`
- `Navigator.pushNamed(...)`

Use `RouteConstants.*` only.

**Bad**
- `context.push('/ppv')`

**Good**
- `context.push(rc.RouteConstants.ppvHub)`

### Rule R2 — Namespaced route constants import
For screens using route constants, enforce:
- `import '.../router_constants.dart' as rc;`

Never rely on unprefixed symbols in large files.

### Rule R3 — Avoid framework symbol collisions
Do not create app symbols that collide with Flutter framework symbols.
If unavoidable, require explicit namespace prefixing.

### Rule R4 — Legacy route aliases must be tagged
Any compatibility alias must carry:
- `// TODO remove after migration`

---

## 2) Firebase / Security

### Rule S1 — No secrets in source
Block commits containing:
- service account JSON
- private keys
- bearer tokens
- API secrets

### Rule S2 — Firestore writes must be service-layered
UI layer should not contain direct schema/business writes except approved thin adapters.
Prefer `lib/shared/services/*`.

### Rule S3 — Auth-sensitive operations must be guarded
Critical flows (PPV purchase, payouts, admin actions) must verify user/session state.

### Rule S4 — External links must be validated
Any domain amplification/publishing path must validate outbound domain allowlists.

---

## 3) PPV / Monetization Safety

### Rule P1 — Entitlement checks before watch/play
Playback routes/components must verify access before streaming path execution.

### Rule P2 — Price/revenue paths require typed models
No loosely-typed map arithmetic in payment-critical paths when typed model exists.

### Rule P3 — Payment navigation via constants only
All checkout/subscription/paywall navigation must use `RouteConstants`.

---

## 4) Admin / Promoter / Creator Consistency

### Rule A1 — Module route drift is forbidden
No module may introduce fresh literal routes after migration.

### Rule A2 — Cross-module calls must use shared constants
If Admin opens Promoter/PPV paths, use `rc.RouteConstants.*`.

### Rule A3 — No synthetic placeholder logic in production paths
Operational modules must avoid fake data paths unless explicitly marked as demo.

---

## 5) Code Health Baselines

### Rule C1 — Zero new analyzer errors
No PR merge with new analyzer errors.

### Rule C2 — Remove dead imports and unreachable branches
Enforce cleanup to avoid noisy diagnostics and false positives.

### Rule C3 — Keep file-level complexity manageable
Flag deeply nested widget logic for extraction when readability regresses.

---

## Pull Request Policy (DFC)

Every PR touching routing or navigation must include:

1. **Routing Delta**
   - constants added
   - literals removed
   - legacy aliases tagged

2. **Analyzer Proof**
   - touched files analyzer-clean

3. **Risk Notes**
   - any backward-compatible aliases retained

4. **Module Scope**
   - PPV/Admin/Promoter/Creator/etc. explicitly listed

---

## Suggested Sonar Focus by Module

- **PPV**: entitlement checks, route constants, payment safety
- **Admin**: privilege boundaries, route drift, audit-sensitive actions
- **Promoter**: cross-module route constants, contract/payout flow safety
- **Creator**: route consistency, content workflow integrity
- **SmartCoach/Media**: external input validation, service isolation

---

## Fast Adoption Plan

1. Keep existing Sonar connected mode.
2. Apply this rule pack to New Code gate first.
3. Run module sweeps in order: PPV → Admin → Promoter → Creator.
4. Enforce PR template checks for routing delta + analyzer proof.
5. Burn down legacy aliases after migration windows close.
