# DFC Cline Free Mode Setup

Use this guide to keep Cline usable even if paid model credits are unavailable.

## Purpose

Cline is local tooling. DFC quality gates and production systems must not depend on paid model availability.

## Quick policy

- Cline must remain optional for delivery.
- CI/Sonar/Routing/Firebase checks are the source of truth.
- Configure at least one free fallback model at all times.

## Recommended free/fallback providers

- Groq-hosted free models
- DeepSeek free models
- Gemini Flash free tier (where available)
- Local model runtime

## Team baseline requirements

- Keep `.vscode/mcp.json` valid for MCP connectivity.
- Keep repo-native gates enabled:
  - `DFC CI`
  - `DFC Sonar Quality Gate`
  - `DFC Routing Spine Check`
  - `DFC Firebase Security Check`
  - `DFC Rule Pack Check`

## Setup checklist (developer machine)

- [ ] Install/enable Cline extension
- [ ] Configure one primary model
- [ ] Configure at least one free fallback model
- [ ] Verify Cline can execute edits with fallback model
- [ ] Verify repo checks still pass without Cline usage

## Failure-mode behavior

If paid model access fails:

1. Switch to a configured free fallback model.
2. Continue local development.
3. Run analyzer/tests locally.
4. Open PR.
5. Rely on required GitHub checks for merge readiness.

No architecture or workflow changes are permitted solely due to model payment/credit status.

## Related docs

- `docs/CLINE_USAGE_POLICY.md`
- `docs/QUALITY_GATE_SETUP.md`
- `docs/DFC_SONAR_RULE_PACK.md`
- `docs/DFC_MODULE_SWEEP_CHECKLIST.md`
