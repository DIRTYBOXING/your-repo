# Branch Protection Policy for DIRTYBOXING/Data-Fight-Central

## Overview
Enforce code quality, security, and operational rigor by requiring:
- Automated checks (lint, test, security scanning)
- Human review (CODEOWNERS approval)
- Status checks (CI/CD success)
- No force pushes, no deletes to main branches

---

## Setup: Master Branch Protection

### Step 1: Navigate to Branch Protection Settings
1. Go to **GitHub.com** → **DIRTYBOXING/Data-Fight-Central**
2. Click **Settings** → **Branches**
3. Under **Branch protection rules**, click **Add rule**
4. **Branch name pattern**: `master`
5. Click **Create** (will auto-save as you configure below)

### Step 2: Require Status Checks
- ✅ **Require status checks to pass before merging**
  - ✅ **Require branches to be up to date before merging**
  - **Select status checks** (add these required checks):
    - `dfc-ci:flutter` (Flutter analyzer)
    - `dfc-ci:ent-audit` (Entitlements npm audit)
    - `dfc-ci:tsc-poster` (TypeScript compile check)
    - `dfc-ci:tsc-promotion` (TypeScript compile check)
    - `dfc-ci:jest-promotion` (Jest unit tests)
    - `dfc-ci:docker-entitlements` (Docker build smoke test)
    - `dfc-ci:docker-poster-worker` (Docker build smoke test)
    - `dfc-ci:docker-promotion-worker` (Docker build smoke test)

### Step 3: Require Code Review
- ✅ **Require a pull request before merging**
  - **Number of approvals**: `1` (can increase for critical repos)
  - ✅ **Require review from Code Owners** (enforces CODEOWNERS file)
  - ✅ **Require approval of the most recent reviewable push**
  - ✅ **Dismiss stale pull request approvals when new commits are pushed**

### Step 4: Require CODEOWNERS Review
- ✅ **Require a pull request before merging** (already set above)
- ✅ **Require review from Code Owners**
  - Ensures changes to sensitive files (`.github/`, `server/`, `lib/` core) require explicit owner approval

### Step 5: Enforce Administrators
- ✅ **Include administrators** (even admins must follow the rules)
- ✅ **Restrict who can push to matching branches** (optional, for critical repos)

### Step 6: Additional Restrictions
- ✅ **Allow force pushes**: `No` (prevent rewriting history)
- ✅ **Allow deletions**: `No` (prevent accidental branch deletion)
- ✅ **Allow bypassing the above settings**: `No` (no exceptions)

### Step 7: Save
Click **Save changes**

---

## CODEOWNERS File

Create `.github/CODEOWNERS` to enforce approval by subject-matter experts:

```
# Global fallback
* @dirtyboxer

# Flutter app core
/lib/core/ @dirtyboxer
/lib/shared/ @dirtyboxer
/pubspec.yaml @dirtyboxer

# Features (can add owners per feature)
/lib/features/ppv/ @dirtyboxer
/lib/features/social/ @dirtyboxer
/lib/features/marketplace/ @dirtyboxer

# Backend / Server
/server/ @dirtyboxer
/server/jobs/ @dirtyboxer

# Infrastructure & CI/CD
/.github/workflows/ @dirtyboxer
/deploy/ @dirtyboxer
/firestore.rules @dirtyboxer
/storage.rules @dirtyboxer

# Security-critical
/.github/actions.lock.json @dirtyboxer
/firebase.json @dirtyboxer
/server/monitoring/ @dirtyboxer

# Node workers
/poster-worker/ @dirtyboxer
/promotion-worker/ @dirtyboxer
/entitlements-service/ @dirtyboxer

# Documentation
/*.md @dirtyboxer
/docs/ @dirtyboxer
```

---

## Testing the Branch Protection

### Test 1: Verify Status Checks Are Required
1. Create a feature branch: `git checkout -b test/branch-protection`
2. Make a trivial change (add a comment)
3. Push and create a PR
4. **Verify**: PR shows all required checks as pending (cannot merge until checks pass)

### Test 2: Verify CODEOWNERS Approval Is Needed
1. Modify `.github/workflows/flutter_ci.yml` (owned by CODEOWNERS)
2. Create PR
3. **Verify**: PR shows "Review requested" for @dirtyboxer, cannot merge without approval

### Test 3: Verify Admins Are Included
1. As admin, try to merge a failing PR directly
2. **Verify**: GitHub blocks merge (admins cannot bypass)

---

## Secondary Branches: `develop` (Optional)

If using a develop → master flow:

1. Create rule for `develop`
2. **Require status checks**: Same as master
3. **Require review**: `1` approval
4. **Require CODEOWNERS**: Yes
5. **Allow force pushes**: No
6. **Allow deletions**: No

---

## Release Branch: `release/*`

For release PRs (e.g., `release/v1.12.0` → `master`):

1. Create rule for `release/*`
2. **Require status checks**: All (same as master)
3. **Require review**: `2` approvals (higher bar for releases)
4. **Require CODEOWNERS**: Yes
5. **Require up-to-date branches**: Yes

---

## Enforcement Log

Once enabled, GitHub automatically:
- **Blocks merges** if any required status check fails
- **Blocks merges** if no CODEOWNERS approval
- **Blocks merges** if branch is out of date with master
- **Prevents force pushes** and deletions
- **Notifies** code owners of review requests
- **Logs all enforcement actions** in PR audit trail

---

## Troubleshooting

### "Status check context not found"
- The workflow job name doesn't match the branch protection rule name
- **Fix**: Ensure workflow job `name:` matches exactly (e.g., `name: dfc-ci:flutter`)

### "Can't merge, CODEOWNERS approval needed"
- No CODEOWNERS approval yet, or CODEOWNERS file doesn't exist
- **Fix**: Ensure `.github/CODEOWNERS` is committed and paths match changed files

### "Branch is out of date"
- Local branch diverged from master (other PRs merged)
- **Fix**: Click "Update branch" button on PR, or `git rebase origin/master`

### "Admin can't bypass rules"
- "Include administrators" is enabled (intentional for security)
- **Fix**: To allow admin override, uncheck "Include administrators" (not recommended for main branches)

---

## Quick Checklist

- [ ] Create branch protection rule for `master`
- [ ] Add all required status checks (8 checks from `pr-check.yml` and `flutter_ci.yml`)
- [ ] Require 1 approval (can increase to 2 for releases)
- [ ] Require CODEOWNERS review
- [ ] Require branches up-to-date
- [ ] Include administrators in rules
- [ ] Disable force pushes
- [ ] Disable deletions
- [ ] Create `.github/CODEOWNERS` with owner assignments
- [ ] Test protection rules (create test PR, verify blocks merge)
- [ ] Document process in team wiki/Slack
- [ ] Monitor branch protection violations in audit log

---

## Next Steps
→ **Phase 4**: Pre-Commit Hooks (gitleaks, secret scanning, large-file detection)
