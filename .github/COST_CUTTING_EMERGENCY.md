# EMERGENCY: GitHub Spending Reduction to ZERO

**Priority**: IMMEDIATE. Execute in order. **Result**: Free tier only.

---

## ⚡ **Phase 1: KILL ALL PAID SERVICES (15 minutes)**

### Step 1: Disable GitHub Copilot Premium (Save $10/month)

**In GitHub.com → Settings → Copilot:**
1. Go to https://github.com/settings/copilot
2. Click **"Manage seats"** if you have org subscription
3. **Remove your seat** (or disable premium)
4. Keep free tier (GitHub Copilot Free in VS Code) = $0/month

**For org level**: https://github.com/organizations/DIRTYBOXING/settings/copilot
- [ ] Remove all premium seats
- [ ] Switch to free Copilot only (auto-available)

### Step 2: Disable GitHub Codespaces (Save $50+/month)

**In GitHub.com → Settings:**
1. Go to https://github.com/settings/codespaces
2. **Delete all active codespaces** (Storage tab → Delete each one)
3. Set max machines to **"2-core"** (cheapest) or disable entirely
4. Set idle timeout to **30 seconds** (auto-stop = saves $)

**For org**: https://github.com/organizations/DIRTYBOXING/settings/codespaces
- [ ] Disable Codespaces entirely (org setting)
- Or set max spend to $0

### Step 3: Disable GitHub Advanced Security (If Enabled)

**In Repo → Settings → Code security & analysis:**
1. Go to Repo Settings → Code security & analysis
2. **Turn OFF**:
   - [ ] Dependency graph
   - [ ] Dependabot alerts
   - [ ] Dependabot security updates
   - [ ] Secret scanning (use local pre-commit instead)
   - [ ] Code scanning (SAST)
3. Keep: Just branch protection + pre-commit (free)

### Step 4: Disable GitHub Enterprise Features

**In Org Settings → Billing:**
1. https://github.com/organizations/DIRTYBOXING/settings/billing/plans
2. Downgrade from Enterprise to **Free** (if applicable)
3. Remove GitHub Enterprise Server licenses

---

## 💰 **Phase 2: OPTIMIZE WORKFLOWS (30 minutes)**

Your workflows are the main GitHub Actions cost. Reduce to minimum.

### Problem: `pr-check.yml` Runs 8 Jobs on Every PR
Each job = 10 min × ubuntu-latest = ~$0.005-0.01 per run.
**Solution**: Run only what's blocking.

### Step 1: Disable Non-Blocking Checks in `pr-check.yml`

Open `.github/workflows/pr-check.yml` and **disable all `continue-on-error`** jobs:

**Change:**
```yaml
continue-on-error: ${{ github.event_name == 'pull_request' }}
```

**To:**
```yaml
# DELETE this line (skip job entirely if not blocking)
```

Or wrap jobs in `if:` conditions:

```yaml
jobs:
  # KEEP: Only if lib/* changed
  flutter-analyze:
    if: contains(github.event.pull_request.paths, 'lib/**')
    name: dfc-ci:flutter
    runs-on: ubuntu-latest
    # ...
```

**Delete or disable these jobs** (not blocking):
- [ ] `audit-entitlements` (just audit npm? not critical)
- [ ] `tsc-poster-worker` (TypeScript check? do locally)
- [ ] `jest-promotion-worker` (unit tests? do locally)
- [ ] `docker-poster-worker` (smoke build? do locally)
- [ ] `docker-promotion-worker` (smoke build? do locally)

**Keep only:**
- `flutter-analyze` (blocks web build)
- `docker-entitlements` (blocks deployment)

**Expected result**: 2 jobs × 10 min = $0.001/PR (vs. 8 jobs = $0.01/PR)

### Step 2: Enable GitHub Actions Caching

In `pr-check.yml`, add caching to every job:

```yaml
flutter-analyze:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: "3.x"
        channel: stable
        cache: true  # <-- ENABLE CACHING (already there, good!)
    # ...
```

For Node jobs:
```yaml
tsc-poster-worker:
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: "20"
    - uses: actions/cache@v3  # <-- ADD THIS
      with:
        path: ~/.npm
        key: npm-${{ hashFiles('**/package-lock.json') }}
```

### Step 3: Run Jobs Only on Master (Disable on PR)

Change `pr-check.yml`:

```yaml
on:
  pull_request:
    branches: [master]
    # REMOVE if:, just run on master PR
  # DELETE: push trigger (if present)
  # push:
  #   branches: [master]
```

**Expected**: PR checks run only when actually merging to master, not every commit.

### Step 4: Disable `flutter_ci.yml` Until Needed

Check `.github/workflows/flutter_ci.yml`:
- If it runs on every push/PR, **disable it**
- Run locally instead: `flutter analyze`
- Only enable in CI if critical

---

## 🔧 **Phase 3: LOCAL-FIRST WORKFLOW (10 minutes)**

Stop relying on GitHub Actions. Work locally = free.

### Step 1: Install Flutter/Dart Locally

```bash
# macOS/Linux
brew install flutter

# Windows (choco)
choco install flutter

# Or download: https://flutter.dev/docs/get-started/install
```

### Step 2: Run Tests Locally Before PR

```bash
cd Data-Fight-Central

# Instead of GitHub Actions:
flutter analyze --no-fatal-infos       # Run locally
flutter test                            # Run tests locally
flutter build web --release            # Build locally
```

**No cost. Zero GitHub Actions minutes.**

### Step 3: Run Node Checks Locally

```bash
cd poster-worker
npm ci --ignore-scripts
npx tsc --noEmit          # TypeScript check
npm test                  # Jest tests

cd ../promotion-worker
npm ci --ignore-scripts
npx tsc --noEmit
npm test
```

### Step 4: Commit Pre-Commit Hooks

```bash
pip install pre-commit
pre-commit install

# Now every commit validates locally:
git commit -m "my change"
# Hooks run automatically, catch issues before push
```

---

## 📊 **Phase 4: VERIFY ZERO SPENDING (5 minutes)**

Go to GitHub → Org → Billing & plans:

**Check:**
- [ ] GitHub Actions: **$0** (using free tier 2,000 min/month)
- [ ] Codespaces: **$0** (disabled)
- [ ] Copilot: **$0** (free tier only)
- [ ] Advanced Security: **$0** (disabled)
- [ ] LFS: **$0** (not using, or minimal)

**Expected total**: **$0/month** (or $5 if you choose to keep some premium)

---

## ✅ **Checklist: Emergency Cost Cutting**

### GitHub Org Settings
- [ ] Copilot: Disabled premium, free only
- [ ] Codespaces: Deleted all, set max machines to disabled
- [ ] Advanced Security: All features OFF
- [ ] Enterprise: Downgraded to Free

### Workflows Optimized
- [ ] `pr-check.yml`: Only 2 blocking jobs (flutter-analyze, docker-entitlements)
- [ ] `flutter_ci.yml`: Disabled (run locally)
- [ ] All jobs have caching enabled
- [ ] Only run on master PR, not every commit

### Local Development
- [ ] Flutter installed locally
- [ ] Node.js installed locally
- [ ] Pre-commit hooks installed
- [ ] Can run `flutter analyze`, `npm test` offline

### Spending Verification
- [ ] GitHub Org Billing: $0/month confirmed
- [ ] No active Codespaces
- [ ] No premium Copilot seats
- [ ] No Advanced Security enabled

---

## 🚨 **If You're Still Getting Charged**

1. **Check GitHub Billing**:
   - https://github.com/organizations/DIRTYBOXING/settings/billing/plans
   - Look at "Usage this month" for each product
   - Look at "Recent invoices"

2. **Find what's costing**:
   - Actions? (Reduce workflow concurrency, disable jobs)
   - Codespaces? (Delete all, disable)
   - Copilot? (Downgrade to free)
   - LFS? (Track only essential files)

3. **Contact GitHub Support** (free):
   - https://support.github.com/
   - Explain situation: "Accidentally enabled paid features, need to downgrade to free tier only"
   - They can help disable, may issue credit

---

## 💡 **Minimum Viable Setup**

This is the absolute minimum:

```
GitHub.com free tier only:
├── Repo (public or private, free)
├── 2,000 Actions minutes/month (free)
├── Copilot Free (VS Code plugin, free)
├── Branch protection (free)
├── Pre-commit hooks (local, free)
└── Local dev workflow (laptop only, free)
```

**Monthly cost: $0**

---

## 🎯 **Result After This Plan**

✅ **Before**: Likely $50-200/month (Actions, Copilot, Codespaces, Advanced Security)  
✅ **After**: **$0/month** (free tier only)

**Trade-off**: 
- Slower CI (you run locally instead)
- No cloud IDE (use VS Code local)
- No automated security scanning (use local linters)

**Benefit**:
- Zero GitHub spending
- Full control over when things run
- Faster feedback (local > waiting for CI)

---

## 📞 **Need Help?**

If something is still charging:
1. Open GitHub Billing issue
2. Run `git log --oneline | head -20` to see recent commits
3. Check GitHub Org Settings → Members to see who has access
4. Verify no other accounts/orgs are linked

You're not alone. Many devs hit this. GitHub support is responsive to "accidental premium" cases.

---

**Document**: Emergency Cost Cutting  
**Created**: 2026-05-05  
**Status**: Ready to execute  
**Expected Savings**: $50-200/month
