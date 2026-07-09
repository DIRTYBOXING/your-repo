# Phase 2B — Operational Activation Checklist

**Status**: Live Firestore Integration Ready
**Date**: 2026-07-09
**Phase**: Pre-Rollout Validation & Risk Controls

---

## ✅ Immediate Actions (Do First)

### 1. Run E2E Validation Pipeline

```dart
// In flutter console or dev script:
final harness = E2ETestHarness();
final result = await harness.runPhase2BCreatorDashboardValidation();
print(result.summary);
```

**Expected Output**:

- ✅ Collections exist (6/6 verified)
- ✅ Profile data verified (Kai Reeves, 8750 followers)
- ✅ Earnings verified (~$2,450.50 current month)
- ✅ Clips verified (5 clips found)
- ✅ Ranking verified (#42 global)
- ✅ Badges verified (3 badges)
- ✅ Stream subscription verified
- ✅ Conversion event recorded

**Pass Criteria**: All 8 stages pass, zero failures, conversion audit log created

**Run Schedule**:

- Now (baseline)
- Post-feature-flag enable (verify flag wiring)
- Daily during 72-hour canary (monitor drift)

---

### 2. Smoke Test: Creator Dashboard UI

**Test Environment**: Staging Firebase (emulator or staging project)

**Steps**:

1. **Authentication**
   - [ ] Log in as `hero_creator_test_001`
   - [ ] Verify Firebase Auth token granted
   - [ ] Check Firestore read permission for `/creator_dashboards/hero_creator_test_001/*`

2. **Dashboard Load**
   - [ ] Open `/creator/dashboard`
   - [ ] Verify **Live Mode Indicator** appears (green badge "📡 LIVE")
   - [ ] Profile card loads with avatar, follower count, rank
   - [ ] Earnings card shows "$2,450.50" (current month)

3. **Real-Time Stream Test**
   - [ ] Simulate backend earning update:
     ```
     firestore update: creator_dashboards/hero_creator_test_001/earnings/{month}_{year}
     totalEarnings: 2450.50 → 2475.50
     ```
   - [ ] Verify UI updates within **< 2 seconds** (stream latency)
   - [ ] Check debug console for "✅ Earnings updated from Firestore"

4. **Clip Feed**
   - [ ] Verify 5 clips render in feed
   - [ ] Tap a clip → Analytics detail screen loads
   - [ ] Verify clip stats (views, likes, conversions)

5. **Conversion Recording**
   - [ ] Tap "Record Conversion" (if UI button exists)
   - [ ] Verify Firestore write to `conversions/{docId}` succeeds
   - [ ] Check telemetry log for listener health status

---

### 3. Security Rules Verification (Staging)

**Goal**: Ensure client cannot write to protected collections, server can.

```bash
# 1. Client read test (should succeed)
firestore.collection('creator_dashboards')
  .doc('hero_creator_test_001')
  .collection('profile')
  .doc('info')
  .get()  # ✅ PASS (isDocOwner)

# 2. Client write to earnings (should fail)
firestore.collection('creator_dashboards')
  .doc('hero_creator_test_001')
  .collection('earnings')
  .doc('7_2026')
  .set({totalEarnings: 9999})  # ❌ FAIL (superadmin only)

# 3. Client append conversion (should succeed)
firestore.collection('creator_dashboards')
  .doc('hero_creator_test_001')
  .collection('conversions')
  .add({
    clipId: 'clip_001',
    value: '10.50',
    timestamp: serverTimestamp(),
  })  # ✅ PASS (isDocOwner can append)
```

**Test Matrix**:
| Operation | Owner | Superadmin | Guest | Expected |
|-----------|-------|-----------|-------|----------|
| Read profile | ✅ | ✅ | ❌ | PASS if owner or admin |
| Write profile | ❌ | ✅ | ❌ | PASS if superadmin |
| Read earnings | ✅ | ✅ | ❌ | PASS if owner or admin |
| Write earnings | ❌ | ✅ | ❌ | PASS if superadmin (backend) |
| Append conversion | ✅ | ✅ | ❌ | PASS if owner (audit log) |

**Tools**:

- Firebase Console → Firestore → Rules playground
- Local emulator with `firebase emulators:start --import=data`

---

### 4. Telemetry & Listener Health Monitoring

**Metrics Dashboard** (create in Firestore or CloudLogging):

```
telemetry/creator_listeners/
  {docId}: {
    creatorId: "hero_creator_test_001",
    status: "connected" | "disconnected" | "error",
    errorMessage: null,
    timestamp: 2026-07-09T12:34:56Z
  }
```

**Monitor These KPIs** (first 72 hours):

| Metric                   | Target  | Warning | Alert    |
| ------------------------ | ------- | ------- | -------- |
| Listener uptime          | > 99.9% | < 99.5% | < 95%    |
| Profile stream latency   | < 500ms | < 1s    | > 2s     |
| Earnings stream latency  | < 500ms | < 1s    | > 2s     |
| Clips stream latency     | < 1s    | < 2s    | > 5s     |
| Conversion write latency | < 100ms | < 200ms | > 500ms  |
| Conversion duplicates    | 0/1000  | 1/1000  | > 2/1000 |

**Query Logs** (Google Cloud Logging):

```bash
resource.type="cloud_firestore_database"
resource.labels.database_id="(default)"
protoPayload.request.writeOperations.database="/creator_dashboards/hero_creator_test_001/conversions"
```

---

### 5. Idempotency Verification (Conversion Writes)

**Risk**: Duplicate conversion records → double payouts

**Test**:

```dart
// Simulate network retry (same conversion, same timestamp)
await adapter.recordConversion(
  creatorId: 'hero_creator_test_001',
  clipId: 'clip_001',
  conversionValue: '10.50',
  metadata: {'requestId': 'req_abc123'},  // ← Use requestId for dedup
);

// Simulate retry (same requestId)
await adapter.recordConversion(
  creatorId: 'hero_creator_test_001',
  clipId: 'clip_001',
  conversionValue: '10.50',
  metadata: {'requestId': 'req_abc123'},  // Same ID
);

// Query Firestore:
db.collection('creator_dashboards')
  .doc('hero_creator_test_001')
  .collection('conversions')
  .where('metadata.requestId', '==', 'req_abc123')
  .get()
  // Expected: 1 document (not 2)
```

**Implementation**: Add idempotency key to conversions collection, backend deduplicates on write.

---

## 🚩 Feature Flag & Canary Rollout

### Flag Name: `creatorDashboardLiveMode`

**Configuration** (in AppConstants or remote config):

```dart
class AppConstants {
  // ...existing...

  static const bool creatorDashboardLiveMode = bool.fromEnvironment(
    'CREATOR_DASHBOARD_LIVE_MODE',
    defaultValue: false,  // ← Disabled by default
  );

  // Optional: per-creator allowlist
  static const List<String> creatorLiveAllowlist = [
    'hero_creator_test_001',  // ← Start with hero
    // Add internal team creators here
  ];
}
```

**Controller Integration**:

```dart
// In creator_dashboard_controller.dart
Future<void> initializeDashboard(String creatorId) async {
  _isLoading = true;
  notifyListeners();

  try {
    // Check feature flag
    if (AppConstants.creatorDashboardLiveMode &&
        AppConstants.creatorLiveAllowlist.contains(creatorId)) {
      await autoDetectLiveMode(creatorId);
    } else {
      // Fallback to mock mode
      await loadHeroCreator();
    }

    _isLoading = false;
    notifyListeners();
  } catch (e) {
    debugPrint('❌ Dashboard init failed: $e');
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
  }
}
```

### Canary Phases

**Phase 1: Internal (Day 1)**

- Enable flag for: hero creator + 5 internal QA creators
- Run E2E validation 4x per day
- Monitor telemetry continuously
- **Exit Criteria**: 0 errors, 0 duplicate conversions, < 1s latency on all streams

**Phase 2: Staging (Day 2)**

- Add: 10 staging creators with diverse data volumes
- Load test: 50 concurrent users on dashboard
- **Exit Criteria**: < 500ms P95 latency, 0 conversion failures

**Phase 3: Limited Release (Day 3)**

- Add: Top 50 creators (by follower count)
- Monitor: Conversion payout reconciliation
- **Exit Criteria**: Payout numbers match conversion records (audit log verified)

**Phase 4: Full Release (Day 4+)**

- Enable for all verified creators
- Monitor: Daily adoption metrics, churn, engagement

---

## 🔐 Rollback & Safety Procedures

### Rollback Plan (If Issues)

**Immediate**:

1. Set `CREATOR_DASHBOARD_LIVE_MODE=false` (disable live mode)
2. Creators fall back to mock data automatically (no UI breakage)
3. Verify dashboard still loads with cached data
4. No data loss (conversions preserved in audit log)

**Post-Mortem** (if needed):

1. Review Firestore logs for failed writes
2. Query conversion collection for duplicates: `SELECT COUNT(*) FROM conversions WHERE requestId = ...`
3. Delete test conversions from staging (audit trail preserved)
4. Fix root cause, re-enable with feature flag

---

## 📊 Metrics Dashboard (Create These Queries)

### Google Cloud Console (Logging)

**Query 1: Listener Connection Rate**

```
resource.type="cloud_firestore_database"
protoPayload.methodName="google.firestore.v1.Firestore.Listen"
protoPayload.request.database="/creator_dashboards/hero_creator_test_001"
| GROUP BY protoPayload.response.status
| COUNT
```

**Query 2: Conversion Write Success Rate**

```
resource.type="cloud_firestore_database"
protoPayload.methodName="google.firestore.v1.Firestore.Write"
protoPayload.request.database="/creator_dashboards/hero_creator_test_001/conversions"
| GROUP BY protoPayload.response.status
| COMPARE_COUNT
```

**Query 3: Average Stream Latency**

```
resource.type="cloud_firestore_database"
labels.listener_type="realtime"
labels.collection="creator_dashboards"
| EXTRACT latency_ms
| STATS mean(latency_ms) AS avg_latency, percentile(latency_ms, 95) AS p95_latency
```

---

## ✍️ Pre-Commit Checklist (Before Git Push)

- [ ] Phase 2B E2E validation passed (all 8 stages)
- [ ] Smoke test UI live indicator visible
- [ ] Security rules verified in staging (client write blocked, server write succeeds)
- [ ] Telemetry logs confirmed (listener health recorded)
- [ ] Idempotency key implemented in conversion writes
- [ ] Feature flag integrated and defaults to `false`
- [ ] Canary allowlist populated (hero_creator_test_001)
- [ ] Rollback plan documented and tested
- [ ] Metrics queries created in Google Cloud Console
- [ ] No compilation errors: `flutter analyze --no-preamble`
- [ ] All new files have zero TODOs/FIXMEs (unless intentional)

---

## 📋 Daily Standup (First 72 Hours)

**What to report**:

- Listener uptime and latency (from telemetry)
- Conversion write success rate
- Any errors in Firestore logs
- UI responsiveness feedback from QA
- Rollback readiness status

**Escalation Criteria**:

- Listener downtime > 5 minutes
- Conversion write failure rate > 0.1%
- Latency spike > 5 seconds (any stream)
- Security rule violation detected
- Duplicate conversion record found

---

## 🎯 Success Criteria (Day 3)

✅ **All of**:

- E2E validation passing 100% of runs (no transient failures)
- Listener uptime > 99.9%
- All stream latencies < 1 second (P95)
- Zero duplicate conversions across test data
- Security rules verified in staging
- Feature flag wiring confirmed
- Canary rollout plan approved by stakeholders

**Then**: Ready for **Phase 2C** (Profile Menu + Verified Creator Onboarding)

---

## 📝 Notes

- **Firestore emulator** recommended for staging (faster iteration, no production risk)
- **Cloud Functions** needed for payout backend (separate work, planned for Phase 3)
- **Telemetry cleanup**: Remove test listener records before day 4 (audit archive first)
- **Conversion audit log**: Immutable, preserved for 90 days minimum (compliance)
