# Tier 7 Creator Dashboard — Release Checklist (Phase 2B + Outreach)

**Release Date:** 2026-07-09
**Branch:** `feat/ppv-visual-upgrade`
**Current Commit:** `858e7c1b` (outreach pack finalized)
**Version:** 1.0.1 (ready to bump)

---

## Phase 1: Pre-Merge Review & QA

### ✅ Code Review Checklist

- [ ] Firestore adapter (`creator_firestore_adapter.dart`) tested with hero creator data
- [ ] Stream subscriptions verified (5/5 listeners healthy)
- [ ] Feature flags configured: `CREATOR_DASHBOARD_LIVE_MODE=false`, allowlist=`['hero_creator_test_001']`
- [ ] Security rules deployed (`firestore.rules` includes creator_dashboards collections)
- [ ] Compilation: zero errors on `flutter analyze`
- [ ] Outreach infrastructure (CSVs, email templates) ready for dispatch

### ✅ Local Testing

```powershell
# Run tests and linters
flutter test --coverage
flutter analyze
dart format --set-exit-if-changed .
```

---

## Phase 2: Merge to Main & Version Bump

### Merge Commands

```bash
# Ensure on feat/ppv-visual-upgrade branch (latest commit: 858e7c1b)
git checkout feat/ppv-visual-upgrade
git pull origin feat/ppv-visual-upgrade

# Rebase onto main to keep history clean
git fetch origin
git rebase origin/main

# If conflicts, resolve and continue
git rebase --continue

# Merge to main
git checkout main
git pull origin main
git merge --no-ff feat/ppv-visual-upgrade -m "Merge: Tier 7 Creator Dashboard Phase 2B + Outreach Infrastructure"

# Bump version: 1.0.0+1 → 1.0.1+1
# Edit pubspec.yaml:
#   version: 1.0.1+1

# Commit version bump
git add pubspec.yaml
git commit -m "chore: bump version to 1.0.1+1 for creator dashboard release"

# Tag the release
git tag -a v1.0.1 -m "Tier 7 Creator Dashboard Release — Phase 2B complete"
git push origin main --tags
```

---

## Phase 3: CI Pipeline & Build Verification

### ✅ Pipeline Gates

- [ ] Build succeeds (CloudBuild or GitHub Actions)
- [ ] All tests pass (unit, widget, integration)
- [ ] Code coverage ≥ 70% on new files
- [ ] Lint warnings ≤ 5 (acceptable in outreach docs)
- [ ] No security vulnerabilities (SonarQube / OWASP)

### Monitor CI Status

```bash
# Check CloudBuild status
gcloud builds list --limit=5

# Or GitHub Actions (replace ORG/REPO)
# https://github.com/DIRTYBOXING/your-repo/actions
```

---

## Phase 4: Staged Deployment

### 4a. Deploy to Staging

```bash
# Ensure CI is green before proceeding

# Deploy to staging environment (feature flag OFF)
firebase deploy --only functions,firestore:rules,storage:rules --project datafightcentral-staging

# Run smoke tests in staging
flutter test integration_test/creator_smoke_test.dart --target=staging
```

### 4b. Canary Deploy to Production (Feature Flag OFF)

```bash
# Deploy to production with feature flag DISABLED by default
CREATOR_DASHBOARD_LIVE_MODE=false flutter build appbundle
# OR for web:
CREATOR_DASHBOARD_LIVE_MODE=false flutter build web --release

# Deploy via Play Store internal testing, App Store TestFlight, or Firebase Hosting
# Keep rollout at 1-5% initially if using staged rollout channels

# Deploy backend (functions, rules, indexes)
firebase deploy --only functions,firestore:rules,firestore:indexes,storage:rules --project datafightcentral
```

### 4c. Enable for Hero Creator Only (Feature Flag ON, Allowlist = ['hero_creator_test_001'])

```bash
# Firestore config doc to enable the allowlist
# (assumes allowlist defaults to empty on first deployment)
# NO CODE CHANGE NEEDED — allowlist is already in app_constants.dart

# Manually test in app:
# 1. Log in as hero_creator_test_001 (seed data in Firestore)
# 2. Navigate to /creator/dashboard
# 3. Verify: live streams, earnings, clips, ranking all populate
# 4. Check Firestore telemetry/creator_listeners for health status
```

---

## Phase 5: Post-Deployment Verification (T+0 to T+24h)

### T+0: Immediate Checks (Deploy Complete)

```bash
# ✅ Firestore Health Check
db.collection('telemetry').doc('creator_listeners')
  .collection('docs').where('creatorId', '==', 'hero_creator_test_001')
  .orderBy('timestamp', 'desc').limit(1).get()

# Expected: status='active', errorMessage=null, updatedAt ≈ now
```

### T+15m: Email Dispatch & Mailchimp Snapshot

1. **Dispatch Batch 1 (warm)** + **Partner send** from Mailchimp
2. **Type in chat:** `SEND NOW`
3. **Paste Mailchimp snapshot row (CSV format):**
   ```
   Timestamp,CampaignName,Batch,Variant,Sent,Delivered,Bounces,Opens,OpenRate(%),Clicks,ClickRate(%),Unsubscribes,Signups
   2026-07-09T21:15:00+10:00,DFC Creator Pilot - Batch1,Warm,A,10,9,1,4,44.4,2,22.2,0,2
   ```

### T+1h: Agent Delivers Full Report

- **Deliverability:** sent / delivered / bounces
- **Engagement:** opens / clicks / open rate / click rate / A/B signal
- **Top responders** for follow-up
- **Firestore health:** listener status / Feed P95 / conversion writes / duplicates
- **Recommendation:** continue / pause / adjust

### T+6h & T+24h: Running Performance & Attribution

- A/B performance breakdown
- Early signups & conversion attribution
- Next steps & scale recommendations

---

## Phase 6: Alert Thresholds & Rollback Triggers

### ⚠️ Pause / Rollback If Any Occur:

| Metric                    | Threshold     | Action                                                  |
| ------------------------- | ------------- | ------------------------------------------------------- |
| Feed P95 latency          | > 3.0s        | Pause remaining batches; investigate; consider rollback |
| Conversion write failures | > 0           | Immediate pause; roll back to last known good           |
| Duplicate conversions     | > 0           | Immediate pause; clear duplicates; investigate          |
| Listener health           | < 5/5         | Investigate listener failures; pause if > 1 failure     |
| Bounce rate (email)       | > 5%          | Continue with caution; monitor daily                    |
| Email unsubscribes        | > 10% of sent | Pause; review template / messaging                      |

---

## Phase 7: Rollback Commands (Use If Needed)

### **Option A: Fastest — Runtime Allowlist Clear (No Redeploy)**

```javascript
// Execute in Firestore Console (Cloud Firestore web UI)
db.collection("config").doc("creator_allowlist").set({ allowlist: [] });
```

**Effect:** Disables hero creator from live mode immediately; app still deployed.
**Recovery time:** ~30s

### **Option B: Full Rollback — Disable Feature Flag (Requires Redeploy)**

```dart
// Edit lib/core/constants/app_constants.dart
static const bool creatorDashboardLiveMode = bool.fromEnvironment(
  'CREATOR_DASHBOARD_LIVE_MODE',
  defaultValue: false,  // Already false by default
);

// Re-deploy
git revert HEAD~1  // Revert merge commit if needed
CREATOR_DASHBOARD_LIVE_MODE=false flutter build appbundle
firebase deploy --only functions,firestore:rules --project datafightcentral
```

**Effect:** Feature fully disabled; requires app redeploy or server restart.
**Recovery time:** 20–40 min (build + deploy)

### **Option C: Pause Email Sends Only (Mailchimp)**

- Go to Mailchimp → Campaign → Pause sending
- Does NOT rollback app; only stops outreach

---

## Phase 8: Communication Timeline

### **Pre-Merge (T-2h)**

```
📧 Slack #product-alerts:
"🚀 Tier 7 Creator Dashboard Phase 2B release incoming. Ready to merge feat/ppv-visual-upgrade → main.
Feature flag OFF by default. Hero creator (Kai Reeves) test cohort ready.
Stand by for CI results and staged deploy. Expected deploy time: 10–15 min."
```

### **At Merge (T-0)**

```
"✅ Code merged to main. CI running. Feature flag: OFF. Allowing staged rollout.
Firestore security rules updated. Running smoke tests now."
```

### **At Canary Deploy Complete (T+5m)**

```
"✅ Canary deployed. Feature flag: OFF. Allowlist: ['hero_creator_test_001'].
Hero creator dashboard live mode disabled until batch sends.
Ready for email dispatch sequence at T+10m."
```

### **At Email Dispatch (T+15m)**

```
"📧 Batch 1 (10 warm) + Partner send (10) dispatched.
Mailchimp snapshot: Sent=20, Delivered=19, Bounces=1, Opens=4.
Firestore telemetry: 5/5 listeners active, Feed P95=1.2s, 0 conversion failures.
T+1h report incoming."
```

### **At T+1h**

```
"📊 T+1h Report:
• Deliverability: 95% (19/20 delivered)
• Engagement: 21% open rate, 11% click rate
• A/B Signal: Variant A outperforming by 3%
• Top Responder: [email], clicked at 12:45m
• Firestore Health: ✅ All metrics green
• Recommendation: ✅ CONTINUE — all thresholds met, expand to Batch 2"
```

---

## Checklist Summary

### Pre-Merge

- [ ] Code review complete
- [ ] Tests pass locally
- [ ] Feature flags verified (OFF by default, allowlist ready)
- [ ] Branch up to date with main

### Merge & Version

- [ ] Merged to main with `--no-ff` flag
- [ ] Version bumped to 1.0.1+1
- [ ] Tag created and pushed (v1.0.1)

### CI & Deploy

- [ ] CI pipeline green (build, tests, lint)
- [ ] Staging deployment successful
- [ ] Canary deploy to production (feature OFF)
- [ ] Smoke tests pass

### Verification

- [ ] Firestore telemetry online (5/5 listeners, P95 ~1.2s)
- [ ] Email sends dispatched (T+15m)
- [ ] CSV snapshot pasted & T+1h report delivered
- [ ] All alert thresholds monitored

### Rollback Ready

- [ ] Fast allowlist clear command copied
- [ ] Full rollback steps documented
- [ ] On-call team notified

---

## Key Contacts & Escalation

**On-Call:** [your-oncall@dfc.io]
**Product:** [product@dfc.io]
**Engineering Lead:** [tech-lead@dfc.io]

**Escalation Path:**

1. Issue detected → Pause remaining email batches
2. Threshold breach → Execute fast rollback (allowlist clear)
3. Unresolved after 5 min → Full rollback (redeploy)
4. Call on-call for any production impact

---

## Summary

**You are here:** ✅ Code pushed, ready to merge.

**Next immediate action:**

1. Review this checklist with team
2. Run local tests: `flutter test` + `flutter analyze`
3. Merge to main following Phase 2 commands
4. Monitor CI pipeline
5. Deploy to staging, then canary production (feature OFF)
6. When ready: dispatch sends and type **SEND NOW**

**Expected timeline:** Merge → CI green (5 min) → Canary deploy (10 min) → Smoke tests (5 min) → Ready for dispatch (T+20m)

---

**Status:** ✅ Ready to proceed. Next: Phase 2 — Merge & Version Bump
