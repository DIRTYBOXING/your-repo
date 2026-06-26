# GitHub Operations Hardening: Summary & Daily Runbook

## 📋 Four-Phase Operational Hardening Complete

| Phase | Document | Status | Time to Deploy |
|-------|----------|--------|-----------------|
| **1. Billing & Budgets** | `.github/BILLING_AND_BUDGET_SETUP.md` | ✅ Complete | 30 min (UI setup) |
| **2. Webhook Enforcement** | `scripts/github-budget-webhook.js` | ✅ Complete | 1 hour (deploy to Lambda/Vercel) |
| **3. Branch Protection** | `.github/BRANCH_PROTECTION_SETUP.md` | ✅ Complete | 15 min (GitHub UI) |
| **4. Pre-Commit Hooks** | `.github/PRE_COMMIT_HOOKS_SETUP.md` | ✅ Complete | 20 min (local setup) |

---

## 🚀 Quick Start: 90-Minute Full Deployment

### ⏱️ Timeline
- **0–30 min**: Phase 1 (Billing setup in GitHub UI)
- **30–90 min**: Phase 2 (Deploy webhook to Lambda/Vercel)
- **90–105 min**: Phase 3 (Branch protection rules)
- **105–125 min**: Phase 4 (Pre-commit hooks + team rollout)

### 📝 Deployment Checklist

**Phase 1: Billing & Budgets (GitHub Settings)**
- [ ] Add payment method (DIRTYBOXING org)
- [ ] Set spending limit to $500/month
- [ ] Create Actions budget: $250/month
- [ ] Create Codespaces budget: $150/month
- [ ] Create Copilot budget: $100/month
- [ ] Create LFS budget: $50/month
- [ ] Set thresholds: 50%, 75%, 90%
- [ ] Configure email notifications

**Phase 2: Webhook Enforcement (Deploy Script)**
- [ ] Create Slack webhook (or PagerDuty integration key)
- [ ] Deploy `scripts/github-budget-webhook.js` to AWS Lambda or Vercel
- [ ] Test webhook endpoint (curl the URL)
- [ ] Create GitHub org webhook: `https://your-lambda-url/github/budget-alert`
- [ ] Verify webhook delivery (GitHub settings → Hooks → Recent deliveries)

**Phase 3: Branch Protection (GitHub Settings)**
- [ ] Create `.github/CODEOWNERS` file with owner assignments
- [ ] Go to Repo Settings → Branches → Add rule for `master`
- [ ] Add 8 required status checks from `pr-check.yml` and `flutter_ci.yml`
- [ ] Require 1 approval + CODEOWNERS review
- [ ] Enable "Dismiss stale approvals"
- [ ] Disable force pushes and deletions
- [ ] Test with a dummy PR (verify blocks merge)

**Phase 4: Pre-Commit Hooks (Local + Team)**
- [ ] Install pre-commit framework: `pip install pre-commit`
- [ ] Create `.pre-commit-config.yaml` in repo root
- [ ] Create custom hook scripts in `scripts/hooks/`
- [ ] Run `pre-commit install` in local repo
- [ ] Test hooks: `pre-commit run --all-files`
- [ ] Commit `.pre-commit-config.yaml` to repo
- [ ] Deploy GitHub Actions pre-commit CI workflow
- [ ] Announce to team via Slack/email

---

## 🔔 Daily Runbook: 15-Minute Morning Check

**Every Monday 9:00 AM ET** (assign to **Finance Lead + Eng Lead**):

### Budget Review
```bash
# Check current spending
# GitHub org → Settings → Billing & plans → View usage

1. [ ] Actions: How much spent this month? Trend toward $250 limit?
   - If > 75%: Review workflow jobs, enable caching, consider self-hosted runners
   
2. [ ] Codespaces: Any large machine usage? Should be 2-core only
   - If > 75%: Send reminder to team about machine limits
   
3. [ ] Copilot: Premium requests (Cloud Agent, Spark) trending up?
   - If > 75%: Review heavy users, consider rate-limiting non-prod repos
   
4. [ ] LFS: Any unexpected uploads?
   - If > 50%: Audit `.gitattributes`, remove unnecessary tracked files
```

### CI/CD Health
```bash
1. [ ] Check PR #55 (reconciliation job) status
   - All checks passing?
   - Any failed workflows this week?

2. [ ] Review last 5 workflow runs
   - Any timeouts or out-of-memory errors?
   - Any infrastructure issues?

3. [ ] Check gitleaks + pre-commit violations
   - Any secrets detected in the past 24h?
   - Any large-file upload attempts blocked?

4. [ ] Audit branch protection enforcement
   - Any forced pushes to master? (should be 0)
   - Any CODEOWNERS reviews bypassed? (should be 0)
```

### Security & Compliance
```bash
1. [ ] GitHub secret scanning enabled?
   - Go to Repo Settings → Security → Secret scanning → Enabled?

2. [ ] Dependabot enabled?
   - Go to Repo Settings → Code security → Dependabot → Enabled?

3. [ ] Any critical vulnerabilities (CVSS >= 9.0)?
   - Check GitHub Security tab
   - Triage and fix high-severity issues

4. [ ] Are org secrets still correct?
   - Check `PROD_API_KEY`, `STRIPE_SECRET_KEY`, etc. still present
   - Rotate any older than 90 days
```

### Team Communication
```bash
1. [ ] Post budget summary to #eng Slack:
       "Weekly Budget: Actions $XX/$250, Codespaces $XX/$150, Copilot $XX/$100"

2. [ ] Log any incidents in SECURITY_ROTATION.md
       - Secrets detected and rotated?
       - Branch protection bypasses?
       - Budget overages?

3. [ ] Update CODEOWNERS if team changed
       - New folks should review critical files
```

---

## 📊 Weekly Report Template

Copy to `OPERATIONS_LOG.md` and update each Monday:

```markdown
## Week of [DATE]

### Budget Tracker
| Product | Budget | Spent | % Used | Trend | Action |
|---------|--------|-------|--------|-------|--------|
| Actions | $250 | $XX | X% | ↑/→/↓ | — |
| Codespaces | $150 | $XX | X% | ↑/→/↓ | — |
| Copilot | $100 | $XX | X% | ↑/→/↓ | — |
| LFS | $50 | $XX | X% | ↑/→/↓ | — |

### CI/CD Health
- ✅ All branch protection rules enforced
- ✅ 0 forced pushes to master
- ✅ 0 CODEOWNERS bypasses
- ⚠️ 1 gitleaks incident (detected & rotated: API_KEY in `.env`)
- ✅ 5 new Dependabot PRs (all merged)

### Security Events
- ✅ Secret rotation: None (all < 90 days)
- ✅ Pre-commit violations: 0
- ✅ Large-file attempts blocked: 0
- ⚠️ Webhook failures: 1 (Lambda timeout at 75% budget threshold)
  - Fix: Increased Lambda timeout to 60s

### Next Week Priorities
- [ ] Optimize Actions workflows (currently 68% of budget)
- [ ] Review Codespaces idle timeouts (enforce 15-min max)
- [ ] Rotation: Database password (due 2026-05-20)
```

---

## 🚨 Incident Response

### If Budget Hits 90% (CRITICAL)
1. **Immediately**:
   - Webhook triggers PagerDuty alert
   - Slack message posted to #eng-critical
   - Enforcement kicks in (Actions throttled, Codespaces blocked, LFS locked)

2. **Within 1 hour**:
   - Eng Lead investigates cause (rogue workflow? large runner jobs? premium Copilot usage?)
   - Finance Lead reviews spending limit increase if needed
   - Post-mortem in #eng: "Spent $250 Actions budget by Wed. Cause: Docker builds. Fix: Enable layer caching"

3. **Within 24 hours**:
   - Fix deployed (e.g., workflow optimized, caching enabled)
   - Monitor spending for next 3 days
   - Document in SECURITY_ROTATION.md

### If Secret Detected (URGENT)
1. **Immediately**:
   - Pre-commit hook blocks commit
   - If pushed anyway: gitleaks blocks merge
   - Developer notified in PR comments

2. **Within 2 hours**:
   - Rotate the exposed credential (API key, token, etc.)
   - Update GitHub org secret if applicable
   - Remove from git history: `git filter-repo --replace-text /path/to/file`

3. **Within 24 hours**:
   - Audit logs: Who had access? How long was it exposed?
   - Document in SECURITY_ROTATION.md
   - Notify relevant team (Stripe team if API key, GCP team if service account, etc.)

### If Large File Uploaded (WARNING)
1. **Immediately**:
   - Pre-commit or branch protection blocks commit/merge
   - Developer gets message: "Use Git LFS instead"

2. **Within 1 hour**:
   - Educate developer: "Add to .gitattributes, re-commit with LFS"
   - Track: Is this a one-off or pattern? (e.g., someone uploading videos frequently?)

3. **Action**:
   - Add pattern to `.gitattributes` if new type
   - Monitor LFS usage (Phase 1 budget)

---

## 📚 Operational Documents

All four phases now documented in:

```
.github/
├── BILLING_AND_BUDGET_SETUP.md          # Phase 1: UI steps, budgets, thresholds
├── BRANCH_PROTECTION_SETUP.md           # Phase 3: Branch rules, CODEOWNERS
├── PRE_COMMIT_HOOKS_SETUP.md            # Phase 4: Hooks, scripts, CI integration
├── CODEOWNERS                            # Team assignments (create from template)
└── workflows/
    └── pre-commit-ci.yml                # GitHub Actions pre-commit checks

scripts/
├── github-budget-webhook.js             # Phase 2: Enforcement webhook
└── hooks/
    ├── no-large-files.sh
    ├── block-env-secrets.sh
    └── block-dangerous-imports.sh

docs/ or root:
├── OPERATIONS_LOG.md                    # Weekly budget/security log
└── SECURITY_ROTATION.md                 # Secret rotation + incident log
```

---

## 🔐 Access & Rotation Schedule

### Who Has What Access?
| Role | Access | Rotation |
|------|--------|----------|
| **Finance Lead** | GitHub org billing, spending limits | Monitor weekly |
| **Eng Lead** | Branch protection, CODEOWNERS, Actions | Monitor weekly |
| **DevOps Owner** | Webhook deployment, Lambda, Codespaces config | Monitor weekly |
| **All Developers** | Pre-commit hooks (local), CODEOWNERS review | Auto-enforced |

### Credential Rotation Schedule
- **GitHub Machine User Token**: Every 90 days (next: 2026-08-05)
- **Webhook Secret** (GITHUB_WEBHOOK_SECRET): Every 90 days
- **Slack/PagerDuty Tokens**: Every 90 days
- **AWS Lambda IAM Role**: Audit every 30 days
- **Stripe API Key**: Every 90 days
- **Firebase Service Account**: Every 90 days

---

## ✅ Validation Checklist

After deploying all phases, verify:

- [ ] **Phase 1**: Spend limits and budgets appear in GitHub billing dashboard
- [ ] **Phase 2**: Webhook delivery logs show successful deliveries (GitHub org → Webhooks → Recent deliveries)
- [ ] **Phase 3**: Try to merge PR without approval → GitHub blocks merge
- [ ] **Phase 3**: Try to merge PR with failing status check → GitHub blocks merge
- [ ] **Phase 4**: Try to commit with API key in `.env` → pre-commit hook blocks it
- [ ] **Phase 4**: Try to commit file > 10MB → pre-commit hook blocks it
- [ ] **CI**: GitHub Actions `pre-commit-ci.yml` workflow passes on all PRs
- [ ] **Team**: All devs can `pre-commit run --all-files` without errors

---

## 📞 Escalation Path

| Severity | Response Time | Escalation |
|----------|---------------|-----------|
| 🟢 **Info** (50% budget) | 24 hours | Email to Finance + Eng Leads |
| 🟡 **Warning** (75% budget) | 4 hours | Slack #eng + PagerDuty warning |
| 🔴 **Critical** (90% budget) | 1 hour | Slack #eng-critical + PagerDuty page |
| 🚨 **Security** (secret detected) | 30 min | Immediate rotation + incident log |

---

## 📖 Further Reading

- GitHub Billing docs: https://docs.github.com/en/billing
- Branch protection: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches
- Pre-commit framework: https://pre-commit.com/
- Gitleaks: https://github.com/gitleaks/gitleaks
- TruffleHog: https://github.com/trufflesecurity/trufflehog

---

## 🎯 Success Metrics (30, 60, 90 Days)

### 30 Days
- [ ] 0 unblocked budget alerts
- [ ] 0 secrets committed to repo
- [ ] 0 large files in Git (all using LFS)
- [ ] 100% of PRs require CODEOWNERS approval
- [ ] 0 forced pushes to master

### 60 Days
- [ ] Budget trending stable (not climbing)
- [ ] All new team members running pre-commit hooks
- [ ] 0 incidents from uncaught issues
- [ ] Weekly runbook well-established

### 90 Days
- [ ] Team culture shift: "compliance is automatic"
- [ ] First credential rotation completed (90-day cycle)
- [ ] 0 escalations from policy violations
- [ ] Ready to add advanced features (org secrets, self-hosted runners)

---

## 🚀 Next Phases (Future)

Once this foundation is solid:
- **Phase 5**: Self-hosted runners (reduce GitHub Actions spend)
- **Phase 6**: GitHub Enterprise / Advanced Security (code scanning, SAST)
- **Phase 7**: Custom GitHub Apps (fine-grained permission control)
- **Phase 8**: SAML SSO + IP whitelisting (org security)

---

**Document Created**: 2026-05-05
**Last Updated**: 2026-05-05
**Owner**: @dirtyboxer (CODEOWNERS)
**Status**: ✅ Ready for team deployment
