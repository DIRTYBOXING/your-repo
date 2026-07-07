# DFC Contributor Quickstart

## Mission-first contribution model

DFC contributions should improve reliability, clarity, and real-world impact. Keep changes small, reviewable, and production-safe.

## 1) Clone and setup

1. Fork and clone the repository.
2. Install Flutter/Dart tooling and project dependencies.
3. Configure Firebase files and local environment according to setup docs.

Primary setup references:

- `SETUP_GUIDE.md`
- `docs/DEVELOPER_SETUP.md`
- `CONTRIBUTING.md`

## 2) Run locally

- Run the app on your target platform.
- Verify key screens load without runtime errors.
- Use demo/emulator-safe workflows when touching auth/data flows.

## 3) Make a clean change

- Pick one scoped issue or module objective.
- Follow existing architecture patterns (services, constants, shared widgets).
- Avoid broad refactors unless explicitly required.

## 4) Validate before PR

- Run static analysis and tests for impacted modules.
- Confirm no unrelated files are included in your commit.
- Ensure docs are updated if behavior or workflows changed.

## 5) Open a high-signal PR

Include:

- Problem statement
- What changed
- How you validated it
- Risks and rollback notes

Use the repo PR templates and keep each PR focused.

## Governance expectations

- Respect branch protections and required checks
- Do not bypass quality gates
- Keep security and user safety standards intact

## Suggested first contributions

- Docs clarity improvements
- Test stabilization and flaky fixups
- Small UI reliability fixes
- Service-level bug fixes with reproduction notes

## Contributor support

- Issue tracker: https://github.com/DIRTYBOXING/Data-Fight-Central/issues
- Sponsor/mission context: https://github.com/sponsors/DIRTYBOXING
