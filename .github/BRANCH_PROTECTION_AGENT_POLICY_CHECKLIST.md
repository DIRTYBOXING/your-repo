# Agent Automation Branch Protection Checklist

Use this checklist **before enabling auto-approve or auto-merge** for agent-created PRs.

## Required repository protections

- [ ] Branch rule exists for `master`
- [ ] Require pull request before merging
- [ ] Require status checks to pass before merging
- [ ] Require branch to be up to date before merging
- [ ] Require CODEOWNERS review
- [ ] Require approval of most recent push
- [ ] Dismiss stale approvals on new commits
- [ ] Include administrators
- [ ] Force pushes disabled
- [ ] Branch deletion disabled

## Required CI checks for agent PRs

- [ ] Build workflow required
- [ ] Sonar/quality gate required (or equivalent static analysis gate)
- [ ] Unit/integration tests required for touched domains
- [ ] Secret scanning required

## Auto-merge policy (recommended safe defaults)

- [ ] Auto-merge is OFF by default
- [ ] Auto-merge allowed only for risk = `low`
- [ ] Auto-merge blocked for changes touching:
  - [ ] `.github/workflows/**`
  - [ ] `firestore.rules`, `storage.rules`, `firebase.json`
  - [ ] auth/payment/entitlement/webhook paths
  - [ ] deployment/infra manifests
- [ ] Auto-merge requires at least one human CODEOWNER approval

## Agent identity and permissions

- [ ] Agent/service account uses least privilege
- [ ] Agent cannot bypass branch protection
- [ ] Agent PRs are labeled (example: `agent-fix`)
- [ ] Agent PR body includes metadata: tool, trigger, confidence, owner

## Auditability and rollback

- [ ] Every agent PR links evidence (CI run, failing rule/issue)
- [ ] Revert plan is documented in PR
- [ ] Post-merge monitoring owner is assigned for high-risk changes

## Rollout plan (recommended)

1. Pilot in non-critical repo or feature branch
2. Measure false positives / bad fixes over 1-2 weeks
3. Enable limited auto-merge for low-risk docs/chore fixes only
4. Expand gradually after review quality is consistent
