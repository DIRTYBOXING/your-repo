# DFC Quality Gate Setup

This guide enables merge-blocking branch protection for the DFC quality stack.

## Required workflows

Ensure these workflow files exist in `master`:

- `.github/workflows/ci.yml`
- `.github/workflows/quality-gate.yml`
- `.github/workflows/routing-check.yml`
- `.github/workflows/firebase-security-check.yml`
- `.github/workflows/dfc-rulepack-check.yml`

## Required repository secrets

Add this secret in GitHub repository settings:

- `SONAR_TOKEN` (required for Sonar scan + quality gate)

## Branch protection (master)

In GitHub:

1. Open **Settings → Branches → Branch protection rules**
2. Create or edit rule for `master`
3. Enable:
   - **Require a pull request before merging**
   - **Require approvals** (recommended: at least 1)
   - **Dismiss stale approvals when new commits are pushed** (recommended)
   - **Require status checks to pass before merging**
4. Select these required checks:
   - `DFC CI / analyze + tests`
   - `DFC Sonar Quality Gate / sonar scan + quality gate`
   - `DFC Routing Spine Check / forbid literal navigation routes`
   - `DFC Firebase Security Check / firestore/storage policy checks`
   - `DFC Rule Pack Check / rule pack + routing discipline`
5. Enable:
   - **Require branches to be up to date before merging**
   - **Do not allow bypassing the above settings** (for strict enforcement)

## Operational notes

- The local warning `Context access might be invalid: SONAR_TOKEN` in workflow editors is expected if secrets are not locally resolvable by schema tooling.
- GitHub Actions will resolve `secrets.SONAR_TOKEN` correctly once configured in repository/org secrets.
- Routing discipline is enforced by CI; no literal routes should be introduced in navigation calls.
- Rule-pack conformance should be documented in PRs using `.github/pull_request_template.md`.

## Verification checklist

- [ ] All five workflows run on PR
- [ ] `SONAR_TOKEN` configured
- [ ] Required checks selected in branch protection
- [ ] PR cannot merge when any required check fails
- [ ] PR template sections completed (routing delta, analyzer proof, module scope)
