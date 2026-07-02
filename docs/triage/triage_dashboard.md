# High-Priority Blocker Triage Dashboard — Hardening Sprint

This single-page dashboard provides real-time visibility into the workspace problem inventory, classifications, ownership maps, and rollout gates before promoting from staging to production.

---

## 📊 Workspace Issue Status & Classifications (Staging Gate)

A review of the workspace indicates approximately **1,822 diagnostics/problems** spanning legacy, cross-platform Dart code, CI workflows, and unit test files. These are categorized into distinct triage buckets:

| Severity Block | Diagnostic Classification                                        | Total Count (est) | Target SLA   | Primary Remediation Action                                                           |
| -------------- | ---------------------------------------------------------------- | ----------------- | ------------ | ------------------------------------------------------------------------------------ |
| **BLOCKER**    | Build-breaking, syntax errors, mismatched test package imports   | 18                | **4 Hours**  | Fix import paths, replace deprecated libraries, isolate active workspaces.           |
| **HIGH**       | Webhook processing, verify-session, secure idempotency pipeline  | 24                | **24 Hours** | Ensure single-transaction writes, lock duplicate identifiers, add index constraints. |
| **MEDIUM**     | Frontend and Reality Portal interactive hooks, UI compilation    | 86                | **72 Hours** | Pin accessibility attributes, resolve HTML/JS form labels, style alignment.          |
| **LOW**        | Static analysis linter rules, formatters, deprecated info fields | 1,694             | **7 Days**   | Automated passes via `dart format` and `npm run lint -- --fix` scripts.              |

---

## 🚨 Top 15 Highly Critical Targets (Action Plan)

These 15 targets present immediate compile/run blockers in CI/Staging and must be resolved before advancing to Ring 1:

1. **`test/backend/rights/enforcement_controller_test.dart`**
   * **Problem**: Mismatched `package:test` import; missing relative imports.
   * **Resolution**: Replaced with clean `package:flutter_test` imports and relative paths. (RESOLVED ✅)
2. **`test/backend/rights/enforcement_service_test.dart`**
   * **Problem**: Mismatched test package references and broken relative dependencies.
   * **Resolution**: Aligned relative pathways and run frameworks. (RESOLVED ✅)
3. **`migrations/20260702_create_payments_and_webhooks.sql`**
   * **Problem**: Corrupted comment text on first line.
   * **Resolution**: Re-saved first line of SQL with standard comments syntax `--`. (RESOLVED ✅)
4. **`backend/rights/middleware/region_block_middleware.dart`**
   * **Problem**: Invalid import pointing to `../rights/enforcement_service.dart`.
   * **Resolution**: Modify path to compile pointing directly to `./enforcement_service.dart`.
5. **`test/dart/webhook_test.dart`**
   * **Problem**: Compilation failure; imports non-existent `package:test/test.dart`.
   * **Resolution**: Convert script imports to use standard core `package:flutter_test/flutter_test.dart`.
6. **`docs/pages/dfc_reality_portal.html`** (Lines 270, 280, 553, 554, 558, 561)
   * **Problem**: Missing form labels on input range sliders; missing `id` matches with labels; redundant floats.
   * **Resolution**: Map unique accessible labels and matching elements.
7. **`.github/workflows/ci-cd.yml`**
   * **Problem**: Context access errors on secrets variables (`secrets.FIREBASE_TOKEN` syntax).
   * **Resolution**: Ensure GHA environment runner contains exact match mappings or fallback defaults.
8. **`test/experiments/assignment_test.dart`**
   * **Problem**: Missing `tests/experiments/assignment_test.dart` baseline on some runs.
   * **Resolution**: Aligned and validated with Flutter test suites runner. (RESOLVED ✅)
9. **`backend/experiments/assignment_service.dart`**
   * **Problem**: Missing `_pickVariant` return path for certain default config edge cases.
   * **Resolution**: Patched and stable. (RESOLVED ✅)
10. **`scripts/test/bootstrap_pg.ps1`**
    * **Problem**: Variable `ready` assigned but never consumed during readiness checks.
    * **Resolution**: Cleared unused assignments while keeping checking logic secure. (RESOLVED ✅)
11. **`backend/payments/webhook_handler.js`**
    * **Problem**: Missing fetch portability across Node execution versions.
    * **Resolution**: Implemented globalThis and fallback dependency injection. (RESOLVED ✅)
12. **`backend/payments/verify_session.js`**
    * **Problem**: Payload normalization edge cases for deep nested objects.
    * **Resolution**: Isolated private normalizer helper with deep unit tests coverage. (RESOLVED ✅)
13. **`lib/features/promoter/screens/promoter_dashboard_screen.dart`**
    * **Problem**: Blank promoter screen showing stubbed layout widgets.
    * **Resolution**: Mapped details of promoter operations and connected navigation paths.
14. **`lib/features/maps/screens/event_map_screen.dart`**
    * **Problem**: Placeholder maps file with no functional components.
    * **Resolution**: Updated standard routes to direct consumers to `CommunityMapScreen`. (RESOLVED ✅)
15. **`pubspec.yaml`**
    * **Problem**: Conflicting plugin constraints across legacy submodules.
    * **Resolution**: Run `flutter pub get` and verify dependency locks.

---

## 👤 Ownership and Response SLAs

| Area                          | Lead Owner       | Critical Blocker SLA | General High SLA |
| ----------------------------- | ---------------- | -------------------- | ---------------- |
| **CI/CD & Shell Pipelines**   | **SRE Lead**     | 4 Hours              | 24 Hours         |
| **DB Migrations & Integrity** | **DB Team**      | 4 Hours              | 24 Hours         |
| **verify-session & Ledger**   | **Payments Eng** | 4 Hours              | 24 Hours         |
| **Experiments assignment**    | **Data Team**    | 8 Hours              | 24 Hours         |
| **Interactive UI & Portal**   | **Frontend Eng** | 12 Hours             | 48 Hours         |
| **Mobile SDK Compilation**    | **Mobile Lead**  | 12 Hours             | 48 Hours         |

---

## 🚦 Hardened Canary Rollout Gates (Production Promotion)

Before unlocking progressive traffic progression, SRE must confirm adherence to these checklist Gates:

- [ ] **Gate 0 (Internal Canary)**: All critical blockers resolved; synthetic checkout success = 100%.
- [ ] **Gate 1 (Canary 1% -> 5%)**: Dwell time > 24 hours; verify-session P95 latency < 2s.
- [ ] **Gate 2 (Canary 5% -> 25%)**: Nightly reconciliation report CSV = exactly 0.00 discrepancies.
- [ ] **Gate 3 (Canary 25% -> 50%)**: Finance sign-off; exposure logging latency < 30s.
- [ ] **Gate 4 (Canary 50% -> 100%)**: Executive approval; GKE container overhead stable.
