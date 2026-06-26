# DFC Resilience Roadmap (12-Month Foundation)

## Mission
Build a resilient, onboarding-friendly platform where user-facing flows (discovery, PPV access, playback, messaging, and maps) remain reliable under failure, and new developers can ship safely with reproducible infrastructure.

## Core Principles
- Fail safe: contain faults and degrade gracefully.
- Measure first: every critical path gets SLO-backed telemetry.
- Reproducible delivery: deterministic builds and environment parity.
- Security by default: strict secrets handling and supply-chain controls.

## 0-90 Day Priorities (P0)
1. Visual quality gate with diagnostics
- Keep visual uniqueness as WARN-grade to avoid false blockers from auth-gated route redirects.
- Persist duplicate diagnostics to `test-results/visual-duplicates.json`.
- Upload artifacts and PR diagnostics in CI for fast triage.

2. Onboarding-ready developer environment
- Devcontainer post-create bootstrap for Node, Flutter web, Playwright browser deps, and hooks.
- VS Code launch/task workflows for fast visual and runtime validation lanes.
- Pre-commit checks for route test hooks so UI contract drift is caught locally.

3. Runtime verification baselines
- Define smoke checks for PPV route mount, auth/demo entry path, and map/messaging shell render.
- Add explicit timeout guards in visual wait helpers to prevent indefinite hangs.

## 3-9 Month Priorities (P1)
1. Progressive delivery and rollback
- Canary deployment lane with automatic rollback on SLO breach.
- Promotion gates from visual + contract + smoke health.

2. Observability and incident readiness
- SLOs for startup render time, route-mount success, entitlement latency, and playback startup.
- Runbooks linked from alerts with owner and escalation policy.

3. Supply chain and environment hardening
- SBOM generation, dependency vulnerability scanning, signed release artifacts.
- Secret rotation automation and least-privilege access boundaries.

## 9-18 Month Priorities (P2)
1. Self-healing controls
- Circuit breakers and adaptive retries for external dependencies.
- Horizontal scaling triggers from traffic and queue pressure.

2. Automated reliability intelligence
- Flaky-test trend detection and owner routing.
- Error-budget tracking with policy-based release controls.

## Onboarding Technology Track
1. New engineer < 1 day to first validated PR
- Single-command environment bootstrap via devcontainer and workspace tasks.
- Guided lanes: build, visual audit, smoke suite, artifact inspection.

2. Documentation as executable workflow
- Keep docs aligned with CI scripts and tasks.
- Add checklists for first-week onboarding and production incident shadowing.

## Success Metrics
- Visual lane diagnostic completeness: 100% failed runs include report artifacts.
- False-blocker reduction from auth-gated duplicates: >80% reduction.
- New engineer environment setup time: under 60 minutes median.
- P0 incident detection to acknowledged response: under 10 minutes.
