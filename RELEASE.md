# Release Runbook

## Pre-merge

1. Confirm staging has Stripe and PayPal keys present.
2. Confirm REQUIRE_AUTH_FOR_PPV=true in staging.
3. Enable reconciliation feature flag for admins only.

## Merge and tag

1. Push latest branch:

   git push -u origin feat/reconciliation-job

2. After approvals, merge:

   git checkout master
   git pull origin master
   git merge --no-ff feat/reconciliation-job -m "Merge feat/reconciliation-job"

3. Signed release tag:

   git tag -s v1.12.0 -m "Release v1.12.0 reconciliation job"
   git push origin master --tags

## First 24 hours monitoring

### 0-15 minutes

1. Confirm API health and metrics scrape endpoint.
2. Trigger reconciliation manually and verify run count metric increments.

### 15-60 minutes

1. Check dashboards for checkout success, webhook signature failures, run count, and mismatch ratio.
2. Watch ops channel for warnings.

### 60-240 minutes

1. Checkout success >= 98%
2. Webhook signature failures < 1%
3. Entitlement grant p95 < 500 ms
4. Reconciliation mismatch ratio < 1%

If any SLO gate fails: disable feature flags and pause entitlement grants.

## Rollback

1. Revert the merge commit on master.
2. Disable reconciliation runtime schedule (systemd timer or k8s CronJob).
3. Keep forensic payloads and request IDs for incident review.

## Incident triage payload

Capture:

1. requestId
2. raw request headers
3. forensic webhook table row
4. relevant logs and alert snapshots
