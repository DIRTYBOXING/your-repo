# DFC Platform Governance Blueprint

Authoritative governance model for architecture control, quality enforcement, and release safety across DFC.

## 1) Purpose

This blueprint defines how DFC is controlled and validated across:
- Google/Firebase production runtime
- GitHub source control and CI/CD
- NVIDIA acceleration tier planning
- MCP/local tooling boundaries

Outcomes:
- Zero uncontrolled drift
- Zero unreviewed merges
- Strong security and release discipline

## 2) Governance pillars

### Google / Firebase (production authority)
- Data, auth, storage, functions, and security policy governance
- Runtime integrity, access control, and secret management alignment

### GitHub (engineering authority)
- Source-of-truth governance
- Branch protection and required checks
- PR workflow and change management controls

### NVIDIA (acceleration governance)
- Compute/simulation governance for advanced workloads
- Performance and model-acceleration standards

### MCP (local tooling governance)
- Local assistant boundaries and approved action scope
- Explicit separation from production/runtime authority

## 3) Enforcement stack (merge-blocking)

Required checks:
- `DFC CI / analyze + tests`
- `DFC Sonar Quality Gate / sonar scan + quality gate`
- `DFC Routing Spine Check / forbid literal navigation routes`
- `DFC Firebase Security Check / firestore/storage policy checks`
- `DFC Rule Pack Check / rule pack + routing discipline`

No PR merges when any required check fails.

## 4) Branch protection policy

- Pull request required for protected branches
- Required checks must pass
- At least one reviewer approval (recommended minimum)
- Stale approvals dismissed on new commits (recommended)
- Up-to-date branch required before merge

## 5) Routing spine governance

- No literal route strings in navigation calls
- Shared route constants required
- Alias migrations must be documented and time-bounded

## 6) Firebase security governance

- Firestore/storage policy-sensitive changes require passing security check
- Secrets must never be committed
- Least-privilege and secure credential handling are mandatory

## 7) Sonar/code quality governance

- Maintainability, reliability, and security findings are triaged and addressed
- Quality gate remains merge-blocking where configured
- Rule-pack and analyzer discipline apply to all touched modules

## 8) MCP boundaries

MCP is local tooling only.

Allowed:
- Repo inspection/edits
- Diff/patch workflows
- Local validation commands
- Controlled Firebase admin diagnostics

Disallowed:
- Treating MCP as production backend/runtime
- Bypassing CI/quality/security gates
- Any policy-violating secret handling

## 9) Release governance

Release approval requires:
1. All required checks green
2. PR template completeness
3. Module sweep and risk notes where applicable
4. Reviewer sign-off

## 10) Documentation governance

The following documents are canonical and must be kept current:
- `docs/DFC_PLATFORM_MASTER_MAP.md`
- `docs/DFC_ENTERPRISE_ROADMAP.md`
- `docs/DFC_MCP_ARCHITECTURE_MAP.md`
- `docs/DFC_MCP_SERVER_COMPARISON_TABLE.md`
- `docs/DFC_OPERATOR_QUICK_CARD.md`
- `docs/CLINE_USAGE_POLICY.md`
- `docs/CLINE_FREE_MODE_SETUP.md`
- `docs/QUALITY_GATE_SETUP.md`

## 11) Control hierarchy

1. Architecture blueprint
2. Governance policy
3. Rule-pack and routing constraints
4. CI/quality/security checks
5. Code review and release policy
6. Local tooling assistance

## 12) Final policy statement

DFC platform integrity is determined by repository-native governance and production controls, not by local assistant availability.
