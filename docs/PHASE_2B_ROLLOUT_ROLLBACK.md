# Phase 2B Rollout & Rollback Procedures

**Critical**: Follow these procedures exactly. No deviations.

---

## ✅ Pre-Rollout Verification (Day 1, Morning)

### Step 1: Verify Production Readiness

```bash
# 1. Confirm all code is committed and on main branch
git status
# Expected: nothing to commit, working tree clean

# 2. Confirm feature flag is disabled
grep -n "creatorDashboardLiveMode" lib/core/constants/app_constants.dart
# Expected: defaultValue: false

# 3. Confirm allowlist is set correctly
grep -A5 "creatorLiveAllowlist" lib/core/constants/app_constants.dart
# Expected: contains only hero_creator_test_001 for Phase 1

# 4. Verify E2E validation passes
dart run lib/core/utils/e2e_test_harness.dart --phase 2b
# Expected: All 8 stages PASS

# 5. Verify security rules
dart run lib/core/utils/security_rules_verifier.dart
# Expected: All 5 tests PASS

# 6. Verify Firestore deployment
firebase deploy --only firestore:rules --dry-run
# Expected: No errors, rules preview shows changes

# 7. Create Firebase backup
firebase firestore export gs://dfc-backup/phase-2b-pre-rollout-$(date +%Y%m%d-%H%M%S)
# Expected: Export successful
```

### Step 2: Notify Stakeholders

**Message Template**:

```
Subject: Phase 2B Rollout Begins — Creator Dashboard Live Firestore Integration

Timeline:
  9:00 AM — Feature flag disabled (live mode OFF for all)
  10:00 AM — Hero creator dashboard verified on production
  11:00 AM — Internal QA creators added to allowlist
  2:00 PM — Monitor telemetry (listener health, conversions)
  5:00 PM — Expand to 10 staging creators
  EOD — Prepare for Day 2 expansion

Rollback Plan:
  If critical issue detected: Disable feature flag (1-minute rollback)
  No user data loss, no conversion data loss
  Audit trail preserved for investigation

Contacts:
  On-Call Engineer: [Name] [Phone]
  Product Manager: [Name] [Slack]
  Payments Team: [Email] (for payout reconciliation)
```

---

## 🚀 Phase 1 Rollout: Internal (Day 1)

### Step 1: Enable Feature Flag for Internal Only

**Production Firebase Console**:

1. Navigate: Firebase Console → Data Fight Central Project
2. Under "Project Settings" → Environment variables
3. Set: `CREATOR_DASHBOARD_LIVE_MODE=true` (or update deployment config)
4. Set environment: `PRODUCTION`
5. Save and deploy

**Verification**:

```bash
# Verify flag is enabled in production
firebase functions:config:get | grep CREATOR_DASHBOARD_LIVE_MODE
# Expected: true

# Confirm allowlist is restrictive
grep "creatorLiveAllowlist" lib/core/constants/app_constants.dart
# Expected: only hero_creator_test_001
```

### Step 2: Internal QA Test (15 minutes)

**Test Scenario 1: Dashboard Load**

```
1. Open app as hero_creator_test_001
2. Navigate to /creator/dashboard
3. Verify:
   - Live mode indicator visible (green "📡 LIVE")
   - Profile loads: "Kai Reeves", 8,750 followers
   - Earnings show: $2,450.50
   - 5 clips render in feed
   - No errors in console
```

**Test Scenario 2: Real-Time Stream Test**

```
1. Dashboard open and monitoring
2. In Firestore Console, update earnings:
   creator_dashboards/hero_creator_test_001/earnings/7_2026
   totalEarnings: 2450.50 → 2475.50
3. Verify:
   - Dashboard updates within 2 seconds
   - No error notifications
   - Listener health telemetry created
```

**Test Scenario 3: Conversion Recording**

```
1. In app, click "Record Conversion" (or call via API)
2. Simulate conversion: $15.00 for clip_001
3. Verify:
   - Write succeeds without error
   - Conversion appears in Firestore
   - Telemetry logs "conversion_write_success"
4. Attempt duplicate write:
   - Same conversion with same requestId
   - Verify: Only 1 record in Firestore (no duplicate)
```

**Log Check**:

```bash
# View Firestore logs
firebase functions:log --project dfc-prod --limit 50 | grep -i creator_dashboard

# Expected patterns:
# ✅ "Listener subscribed"
# ✅ "Stream latency: 245ms"
# ✅ "Conversion recorded"
# ❌ "Should NOT see: permission denied, duplicate, timeout"
```

### Step 3: Automated Monitoring (30 minutes)

**Monitor Dashboard**:

1. Open Google Cloud Monitoring dashboard
2. Check telemetry collection: `telemetry/creator_listeners`
3. Expected:
   - `status: "connected"` (not "disconnected" or "error")
   - `timestamp` recent (< 1 minute ago)
   - `latencyMs: < 500`

**Monitor Logs**:

```bash
# Real-time log tail
firebase functions:log --project dfc-prod --tail

# Watch for errors:
gcloud logging read \
  'resource.type=cloud_firestore_database AND severity=ERROR' \
  --limit 20 --project=dfc-prod
# Expected: Zero errors
```

### Step 4: Checkpoint (Decision Point)

**Go/No-Go Criteria**:

- [ ] All internal QA tests passed (0 failures)
- [ ] Live mode indicator visible and accurate
- [ ] Streams connected and latency < 500ms
- [ ] Conversion write successful, no duplicates
- [ ] Security rules working (no permission bypasses)
- [ ] Telemetry logged and accessible
- [ ] Zero errors in Firestore/Cloud Functions logs
- [ ] No alerts triggered

**Decision**:

- ✅ **GO**: Proceed to Phase 2 (expand to QA creators)
- ❌ **NO-GO**: Execute rollback, investigate, retry tomorrow

---

## 🔄 Phase 2 Rollout: QA Creators (Day 2)

### Step 1: Expand Allowlist

**Update AppConstants**:

```dart
static const List<String> creatorLiveAllowlist = <String>[
  'hero_creator_test_001',           // ← Already verified
  'internal_creator_qa_001',          // ← Add these
  'internal_creator_qa_002',
  'internal_creator_qa_003',
  'internal_creator_qa_004',
  'internal_creator_qa_005',
  // (5 internal QA creators)
];
```

**Deploy**:

```bash
git add lib/core/constants/app_constants.dart
git commit -m "Phase 2B: Add QA creators to live mode allowlist (Phase 2)"
git push origin feat/ppv-visual-upgrade

# Rebuild and deploy
flutter build appbundle
firebase deploy
```

### Step 2: Canary Monitoring (2 hours)

**Monitor per creator**:

```bash
# Check listener health for each QA creator
firestore collection: telemetry/creator_listeners
filter: creatorId in [qa_001, qa_002, qa_003, qa_004, qa_005]
| STATS COUNT by creatorId, status
```

**Expected**:

- All 5 creators: `status = "connected"`
- All latencies: < 500ms
- Zero errors per creator

**Load Test** (optional):

```bash
# Simulate 10 concurrent viewers per creator
artillery quick --count 10 --num 100 /creator/dashboard?creatorId=internal_creator_qa_001

# Expected:
# - Response time P95: < 1s
# - Error rate: 0%
# - Listener uptime: 100%
```

### Step 3: Checkpoint (Phase 2 Exit Criteria)

- [ ] All 5 QA creators connected and receiving updates
- [ ] Stream latency consistent with Phase 1
- [ ] Conversion writes successful (0 duplicates)
- [ ] Load test passed (if run)
- [ ] Telemetry shows no disconnects or errors
- [ ] Security rules still enforced

**Decision**:

- ✅ **GO**: Proceed to Phase 3 (limited public release)
- ❌ **NO-GO**: Disable for failing creator, investigate, retry after fix

---

## 🌍 Phase 3 Rollout: Limited Release (Day 3)

### Step 1: Expand to Top 50 Creators

**Update Allowlist**:

```dart
// Note: In real deployment, this would come from a database query
// For now, manually add top creators
static const List<String> creatorLiveAllowlist = <String>[
  'hero_creator_test_001',
  'internal_creator_qa_001',
  'internal_creator_qa_002',
  'internal_creator_qa_003',
  'internal_creator_qa_004',
  'internal_creator_qa_005',
  // Top 50 creators by follower count
  'creator_rank_001_8750_followers',  // Kai Reeves
  'creator_rank_002_7200_followers',
  // ... (50 total)
];
```

### Step 2: Enhanced Monitoring (Continuous)

**Payout Reconciliation**:

```bash
# Compare conversions recorded in Firestore vs payout transactions
firestore query:
SELECT creatorId, COUNT(*) as conversion_count, SUM(value) as total_value
FROM creator_dashboards.{creatorId}.conversions
WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY creatorId

# Expected: All conversions have corresponding payout records
# Check payout_log collection for matching entries
```

**Creator Dashboard Engagement**:

```bash
# Measure: Time spent on dashboard, clip views, conversions
firebase analytics query:
SELECT creator_id, COUNT(view) as views, SUM(engagement_time) as total_time
FROM events
WHERE event_name = 'creator_dashboard_view'
GROUP BY creator_id
```

### Step 3: Checkpoint (Phase 3 Exit Criteria)

- [ ] 50 creators connected and active
- [ ] Payout audit: All conversions reconciled
- [ ] Stream latency P95: < 500ms (consistent)
- [ ] Conversion success rate: 100% (0 failures, 0 duplicates)
- [ ] Creator engagement metrics healthy
- [ ] Zero security incidents
- [ ] Telemetry shows < 1 disconnect per creator

**Decision**:

- ✅ **GO**: Full release to all verified creators
- ❌ **NO-GO**: Pause expansion, debug, retry later

---

## ⚠️ Rollback Procedures

### Immediate Rollback (< 1 Minute)

**Scenario**: Critical bug detected (e.g., duplicates, permission bypass)

**Action**:

```bash
# 1. Disable feature flag
firebase functions:config:set creator_dashboard_live_mode=false

# 2. Verify rollback
# All creators fall back to mock mode automatically
# No UI breakage, no data loss

# 3. Notify stakeholders
# Subject: ROLLBACK - Phase 2B Creator Dashboard temporarily disabled
# Reason: [Brief description of issue]
# Action: Fix in progress, ETA [time]
```

**Verification**:

```dart
// In app console
expect(AppConstants.creatorDashboardLiveMode, false);
// → Dashboard now uses mock data for all creators
```

### Post-Incident Recovery

**Steps**:

1. [ ] **Preserve evidence**

   ```bash
   # Export Firestore logs
   firebase firestore export gs://dfc-archive/phase-2b-incident-$(date +%Y%m%d-%H%M%S)

   # Archive telemetry
   gsutil -m cp gs://dfc-logs/creator_listeners/* gs://dfc-archive/incident/
   ```

2. [ ] **Root cause analysis**

   ```bash
   # Query for duplicates
   SELECT requestId, COUNT(*) as count FROM creator_dashboards.*.conversions
   WHERE requestId IS NOT NULL GROUP BY requestId HAVING count > 1

   # Expected after fix: 0 rows
   ```

3. [ ] **Clean up test data**

   ```bash
   # Delete incident test conversions (keep audit trail)
   firestore batch delete creator_dashboards/{creatorId}/conversions
   WHERE metadata.isTest = true
   ```

4. [ ] **Fix implementation**
   - Debug root cause
   - Update code/rules
   - Pass security verification again
   - Re-run E2E validation

5. [ ] **Staged re-enablement**

   ```bash
   # Re-enable for hero creator only
   static const List<String> creatorLiveAllowlist = ['hero_creator_test_001'];

   # Deploy and verify
   # Repeat E2E validation
   # Monitor for 30 minutes
   # If stable: Re-enter Phase 1 rollout
   ```

---

## 📋 Rollback Checklist

Use this if rollback is triggered:

- [ ] **Disable feature flag** (within 1 minute of detection)
- [ ] **Notify all stakeholders** (PM, Payments, Engineering)
- [ ] **Verify fallback** (check dashboard works with mock data)
- [ ] **Preserve logs** (export to backup storage)
- [ ] **Create incident ticket** (document issue)
- [ ] **RCA meeting** (within 1 hour of rollback)
- [ ] **Fix implementation** (code changes + verification)
- [ ] **Clear test data** (conversions, telemetry)
- [ ] **Re-enable for hero only** (sanity check)
- [ ] **Monitor 30 minutes** (zero incidents required)
- [ ] **Escalation** (if still issues, defer to Day 2)

**Escalation Contacts**:

- Platform Owner: [Name] [Phone]
- On-Call Engineer: [Name] [Slack]
- Payments Lead: [Email] (for payout reconciliation)

---

## ✅ Full Release Checklist

Once all 3 phases complete successfully:

- [ ] All 50+ creators connected and stable (72+ hours)
- [ ] Payout reconciliation: 100% of conversions verified
- [ ] Listener uptime: > 99.9%
- [ ] Stream latency P95: < 500ms
- [ ] Conversion success rate: 100%
- [ ] Zero security incidents
- [ ] Zero duplicate conversions
- [ ] Documentation complete
- [ ] Team training complete (if needed)
- [ ] Metrics dashboard operational

**Final Sign-Off**:

```
Rollout Complete ✅

Date: [Date]
Lead: [Name]
Approved by: [Platform Owner]

Creators Live: [#]
Total Conversions: [#]
Total Value: $[#]

Next: Phase 2C - Profile Menu & Creator Onboarding
```

---

## 📊 Rollout Success Metrics

| Metric             | Phase 1 | Phase 2 | Phase 3 | Target         |
| ------------------ | ------- | ------- | ------- | -------------- |
| Creators Live      | 1       | 6       | 50+     | > 95% verified |
| Listener Uptime    | 99.9%   | 99.9%   | 99.9%   | > 99.9%        |
| Stream Latency P95 | 300ms   | 300ms   | 500ms   | < 500ms        |
| Conversion Success | 100%    | 100%    | 100%    | 100%           |
| Duplicate Rate     | 0%      | 0%      | 0%      | 0%             |
| Errors/Hour        | 0       | 0       | < 1     | 0              |

---

**Remember**: When in doubt, rollback. Data safety > Feature velocity.
