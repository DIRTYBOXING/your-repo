# DFC Ring 0 to Ring 1 Canary Runbook

## Purpose

Safely promote a stable release from internal validation traffic (Ring 0) to controlled production traffic (Ring 1) with explicit go and no-go gates.

## Scope

- Platform area: PPV commerce plus connected analytics and reconciliation paths.
- Deployment path: [scripts/canary_deploy.sh](scripts/canary_deploy.sh).
- Monitoring references:
  - [monitoring/grafana/ppv-commerce-dashboard.json](monitoring/grafana/ppv-commerce-dashboard.json)
  - [monitoring/prometheus.yml](monitoring/prometheus.yml)

## Entry Criteria

All items must be true before any traffic shift:

1. Branch sync is clean for the rollout branch (ahead/behind equals 0 and 0).
2. Targeted tests are green for rollout-critical flows.
3. Reconciliation checks are green.
4. Meta CAPI handshake and event forwarding are healthy.
5. No active sev1 or sev2 incidents.
6. Rollback owner is assigned.

## Preflight Commands

Run from repository root.

1. Git health:
   - git branch --show-current
   - git rev-list --left-right --count "@{u}...HEAD"
2. Flutter smoke:
   - flutter test test/experiments/assignment_test.dart
3. Optional broader smoke:
   - flutter test dfc_frontend/dfc_app/test/widget_test.dart
4. Script capability check:
   - bash scripts/canary_deploy.sh

Expected result: preflight either passes or clearly fails before traffic move.

## Ring 0 Deployment

Set staging URL then execute canary script at low percentage.

1. Set environment:
   - set STAGING_URL=https://staging.datafightcentral.com
2. Deploy and smoke:
   - bash scripts/canary_deploy.sh dfc-staging 1

Notes:

- Script runs function deploy, optional seed, and Playwright smoke.
- If smoke fails, stop and do not move traffic.

## Ring 1 Promotion Gate

Promote from 1 percent to 5 percent only if all below are true for at least 30 minutes:

1. Entitlement success rate is greater than or equal to 99.5 percent.
2. Purchase success rate is greater than or equal to 90 percent.
3. DLQ exhaustion alerts are zero.
4. No sustained latency or error spikes in API and function endpoints.
5. Reconciliation drift remains within expected tolerance.

Then move to 5 percent and monitor for 24 to 48 hours.

## Hold and Rollback Criteria

Immediate hold if any of the following occurs:

1. Purchase success drops below 90 percent for more than 5 minutes.
2. Entitlement success drops below 99.5 percent for more than 5 minutes.
3. DLQ exhaustion rises above zero and repeats.
4. Reconciliation mismatch appears in current canary window.

Rollback actions:

1. Shift traffic back to previous stable release at load balancer level.
2. Redeploy prior tag to functions.
3. Run reconciliation verification.
4. Log incident summary and retained evidence links.

## Evidence Checklist

Capture these artifacts during rollout:

1. Deployment timestamp and operator.
2. Commit SHA and branch name.
3. Test results for rollout-critical suites.
4. Dashboard snapshots at start, plus 30 minutes, plus end.
5. Reconciliation summary for canary interval.
6. Final decision: promote, hold, or rollback.

## Current Readiness Notes

At the time of writing, branch sync can be healthy while local workspace changes still exist. Prefer running this rollout from a release branch with tightly scoped changes and a documented release tag.
