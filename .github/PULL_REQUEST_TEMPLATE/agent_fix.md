---
name: Agent Fix PR
about: Use this template for PRs created or assisted by automation agents (Sonar Remediation, AI reviewers, coding agents).
title: "fix(agent): "
labels: agent-fix
---

## What changed

<!-- 2-5 bullets. Keep it concrete and file-level. -->

- 

---

## Agent metadata (required)

- [ ] Agent/tool name recorded (example: Sonar Remediation Agent, Gitar, Copilot)
- [ ] Trigger/rule recorded (issue key, rule id, or prompt link)
- [ ] Confidence/risk level declared: `low` / `medium` / `high`
- [ ] Human owner assigned for this merge

Agent/tool:
Rule/trigger:
Confidence/risk:
Human owner:

---

## Scope guardrails (required)

- [ ] No changes to auth, payments, entitlement, or webhook logic without explicit owner approval
- [ ] No workflow/security policy changes unless this PR is explicitly for CI/security hardening
- [ ] No route literal regressions (uses shared route constants)
- [ ] No hidden behavior changes outside files listed in this PR

---

## Verification evidence (required)

- [ ] Analyzer/lint passed for touched areas
- [ ] Tests added/updated where behavior changed
- [ ] CI checks passed
- [ ] Rollback path is trivial (revert PR) and documented below

### Minimal proof

<!-- Paste exact run links or concise terminal output snippets -->

- CI run:
- Analyzer/lint:
- Tests:

Rollback note:

---

## Merge policy for this PR

- [ ] At least 1 CODEOWNER approval
- [ ] No auto-merge unless all required checks are green
- [ ] If risk = `high`, require 2 approvals and disable auto-merge

---

## Post-merge follow-up (optional)

- [ ] Opened/linked tracking issue for residual debt
- [ ] Added monitoring/alert note if operationally relevant
