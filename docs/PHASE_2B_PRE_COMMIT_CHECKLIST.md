# Phase 2B Pre-Commit Quality Checklist

**Before pushing to Git, run this checklist.** High editorial standards ensure production readiness.

---

## 📋 Code Quality Gates (Non-Negotiable)

- [ ] **Zero compilation errors**: `flutter analyze --no-preamble`
  - Run: `flutter analyze --no-preamble | grep -i error`
  - Expected: No output

- [ ] **Zero linting violations**: `flutter analyze`
  - Fix: `dart fix --apply`
  - Suppress only if documented and approved

- [ ] **All tests pass**: `flutter test --coverage`
  - Run: `flutter test`
  - Expected: All tests pass (0 failures)
  - Coverage: Aim for > 80% on modified files

- [ ] **No merge conflicts**: `git status`
  - Resolve all conflicts before commit
  - Verify: `git diff --name-only --diff-filter=U`

---

## 🚀 Functional Verification (Phase 2B Specific)

### E2E Validation Pipeline

```bash
# Run Phase 2B validation
dart run lib/core/utils/e2e_test_harness.dart --phase 2b
```

**Expected Output**:

```
✅ Phase 2B E2E Validation Complete
  ✅ [1/8] Collections exist (6/6 verified)
  ✅ [2/8] Creator profile verified
  ✅ [3/8] Earnings verified
  ✅ [4/8] Clips verified (5 clips found)
  ✅ [5/8] Ranking verified (#42 global)
  ✅ [6/8] Badges verified
  ✅ [7/8] Stream subscription verified
  ✅ [8/8] Conversion event recorded
✅ All stages passed
```

- [ ] All 8 stages pass
- [ ] Zero failures logged
- [ ] Conversion audit trail created

### Security Rules Verification (Staging)

```bash
# Run in Dart console or test suite
final verifier = SecurityRulesVerifier();
final result = await verifier.verifyAllRules();
print(result.summary);
```

**Expected**:

```
✅ PASSED: 5/5 tests passed

Details:
✅ owner_read_profile
✅ owner_cannot_write_earnings
✅ owner_append_conversions
✅ guest_cannot_read_profile
✅ telemetry_rules
```

- [ ] All security rules verified
- [ ] No permission bypass detected
- [ ] Conversion append-only confirmed

### Feature Flag Integration

**Verify AppConstants**:

```dart
// In Dart console or unit test
print('Live mode enabled: ${AppConstants.creatorDashboardLiveMode}');
print('Allowlist: ${AppConstants.creatorLiveAllowlist}');
print('Hero creator in allowlist: ${AppConstants.creatorLiveAllowlist.contains("hero_creator_test_001")}');
```

- [ ] `creatorDashboardLiveMode` defaults to `false`
- [ ] `creatorLiveAllowlist` contains at least `hero_creator_test_001`
- [ ] Feature flag is documented in code comments

### Controller Live Mode Integration

**Verify in CreatorDashboardController**:

```dart
// Mock test
final controller = CreatorDashboardController(...);
await controller.initializeDashboard('hero_creator_test_001');

// Verify feature flag check
expect(controller.isInLiveMode, false);  // ← Because flag defaults to false

// Simulate flag enabled
// (In unit test with mocked AppConstants)
expect(controller.isInLiveMode, true);   // ← Now live mode active
```

- [ ] `initializeDashboard` checks feature flag
- [ ] Controller respects allowlist
- [ ] Graceful fallback to mock mode if flag disabled
- [ ] No error on missing live data

---

## 📊 Performance Benchmarks

### Stream Latency (Local Emulator)

```bash
# Start emulator
firebase emulators:start --import=data

# Run latency test
dart run lib/core/utils/performance_benchmarks.dart --test stream_latency
```

**Expected**:

- Profile stream: < 300ms (P95)
- Earnings stream: < 300ms (P95)
- Clips stream: < 500ms (P95)
- Ranking stream: < 300ms (P95)

- [ ] All stream latencies within budget
- [ ] No timeout errors
- [ ] Subscriptions cleanup properly

### Memory Usage

```bash
# Monitor during extended stream subscription
flutter run --track-widget-creation --profile

# Observe memory growth for 5 minutes
# Expected: < 50MB increase
```

- [ ] No memory leaks detected
- [ ] Streams cleanup on dispose
- [ ] No orphaned subscriptions

### Firestore Operations

```bash
# Count document reads per operation
# Expected budget:
#   - Load dashboard: 6 reads (1 per collection)
#   - Refresh: 0 reads (stream-based, server push)
#   - Conversion recording: 1 write
```

- [ ] Read budget respected
- [ ] Write operations idempotent
- [ ] No N+1 queries

---

## 🔐 Security Checklist

- [ ] **Firestore Rules Deployed**
  - Verify: `firebase deploy --only firestore:rules --dry-run`
  - Check: No MISSING rules for creator_dashboards

- [ ] **No Secrets in Code**
  - Scan: `git diff HEAD~ | grep -i "secret\|key\|password\|token"`
  - Expected: No matches

- [ ] **Auth Bypass Test**
  - Attempt: Read earnings as non-owner → should fail
  - Attempt: Write conversion without auth → should fail

- [ ] **Idempotency Key Implemented**
  - Verify: `grep -r "requestId" lib/features/creator/services/`
  - Expected: Conversion writes use requestId for dedup

- [ ] **No PII in Logs**
  - Scan: `grep -r "email\|phone\|ssn" lib/features/creator/`
  - Expected: No hardcoded PII
  - Log should be: `debugPrint('Processed conversion for $creatorId')`

---

## 📝 Documentation Completeness

- [ ] **Code Comments Updated**
  - Every public method has a doc comment
  - Complex logic has inline comments
  - Example:
    ```dart
    /// Auto-detect and switch to live mode if Firestore data exists
    /// Falls back to mock data if no creator profile found
    ///
    /// Returns: true if switched to live, false if using mock
    Future<void> autoDetectLiveMode(String creatorId) async {
    ```

- [ ] **README Updated**
  - Phase 2B section added
  - Feature flag instructions included
  - Example: [docs/README.md](./README.md#phase-2b-creator-dashboard)

- [ ] **API Docs Generated**
  - Run: `dart doc`
  - Verify: CreatorFirestoreAdapter documented
  - Verify: CreatorDashboardController methods documented

- [ ] **Changelog Updated**
  - File: [CHANGELOG.md](../CHANGELOG.md)
  - Entry format:

    ```
    ## [1.0.1] - 2026-07-09
    ### Added
    - Phase 2B: Creator Dashboard Firestore integration
    - Real-time stream subscriptions for dashboard data
    - Feature flag for canary rollout
    - Security rules for creator_dashboards collections

    ### Changed
    - Creator services now use CreatorFirestoreAdapter
    - Dashboard controller supports live/mock mode switching
    ```

---

## 🧪 Git Workflow

### Pre-Push Verification

```bash
# 1. Stage files
git add lib/ docs/ firestore.rules

# 2. Review staged changes
git diff --cached --stat

# 3. Verify commit message format
# Expected:
#   Phase 2B: Creator Dashboard Firestore integration
#
#   - Real-time stream subscriptions for dashboard data
#   - Feature flag for canary rollout with allowlist
#   - Security rules for creator_dashboards collections
#   - E2E validation pipeline with 8-stage verification
#   - Telemetry monitoring for listener health
#   - Pre-commit quality checklist

# 4. Commit
git commit -m "Phase 2B: Creator Dashboard Firestore integration"

# 5. Verify branch state
git log --oneline -5

# 6. Push
git push origin feat/ppv-visual-upgrade
```

- [ ] All modified files staged
- [ ] Commit message follows convention
- [ ] Branch is clean (no stashed changes)
- [ ] No uncommitted modifications remain

---

## 📋 Final Sign-Off

**Approve by role**:

- [ ] **Developer**: Code compiles, tests pass, E2E validation passes
- [ ] **QA Lead**: Security rules verified, smoke tests pass, telemetry configured
- [ ] **Product**: Feature flag ready, canary rollout plan approved, metrics dashboard created
- [ ] **Platform Owner**: Risk controls in place, rollback plan tested, launch window scheduled

**Sign-off template** (add to commit message):

```
Reviewed by:
  ✅ Developer: [Name] @ [Time]
  ✅ QA Lead: [Name] @ [Time]
  ✅ Product: [Name] @ [Time]
  ✅ Platform Owner: [Name] @ [Time]
```

---

## 🚨 If Any Check Fails

**Do NOT commit.** Instead:

1. **Identify the issue**

   ```bash
   # Rerun the failing check in isolation
   flutter analyze | head -20
   ```

2. **Fix immediately**

   ```bash
   dart fix --apply
   flutter pub get
   ```

3. **Re-run checklist**

   ```bash
   flutter analyze && flutter test
   ```

4. **Only commit when all checks pass**

---

## 📊 Sign-Off Time Estimate

- Code Quality: 5 min
- E2E Validation: 10 min
- Security Rules: 5 min
- Performance Benchmarks: 10 min
- Security Checklist: 5 min
- Documentation: 5 min
- Git Workflow: 5 min
- **Total: 45 minutes**

**Ideal**: Run this checklist 1 hour before target commit time to allow for fixes.

---

## 🎯 Success Criteria

✅ **Ready to push** when:

- [ ] All checks marked ✅
- [ ] Zero compilation errors
- [ ] E2E validation 8/8 stages passing
- [ ] Security rules verified
- [ ] Performance within budget
- [ ] Documentation complete
- [ ] All sign-offs obtained

---

**Next Step**: After successful push, proceed to **Phase 2C — Profile Menu & Verified Creator Onboarding**
