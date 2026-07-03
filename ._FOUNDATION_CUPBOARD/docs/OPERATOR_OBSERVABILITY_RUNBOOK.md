# Operator Observability Runbook

## Scope

This runbook covers the new Mission Control operator actions and the PPV storefront flow added for DFC.

## Primary Signals

- `operator_action_accepted_count`: rate of signed operator actions accepted by `operatorAction`
- `jobs_queued_count`: jobs inserted into Firestore by operator actions
- `jobs_failed_count`: jobs entering `failed` or `dead_letter`
- `ppv_storefront_latency_ms`: request latency for `createPpvStorefrontOrder`
- `operator_action_failure_ratio`: action failures / accepted actions over 5 minutes

## Alert Thresholds

- Operator failure ratio above `2%` for `10m`
- Jobs older than `15m` in `queued` or `running`
- Dead-letter count above `3` in `15m`
- Storefront latency p95 above `2500ms` for `10m`
- Payment confirmation failures above `1%` for `15m`

## Watchdog Tuning

- Poll queued/running jobs every `60s`
- Requeue only when `lockedUntil < now()` and `attempts < 5`
- Escalate to `dead_letter` after 5 attempts
- Emit an audit row for each watchdog requeue and dead-letter transition
- Cap concurrent retries by `type` so `create_clip` cannot starve payment or promo jobs

## Canary Deploy

1. Deploy operator/storefront functions with the serialized wrapper already in this repo.
2. Route internal beta traffic only.
3. Run smoke sequence:
   - create operator action
   - verify `jobs` row created
   - create PPV order
   - confirm order in sandbox
   - verify entitlement row written
4. Promote only if all steps succeed and error budget remains below `2%`.

## Chaos Checks

- Worker crash: kill the worker mid-run and confirm the watchdog requeues the job
- Missing callback: leave a job in `running` until `lockedUntil` expires and confirm dead-letter escalation after retry budget is exhausted
- Invalid signature: replay an operator request with a bad HMAC and confirm a `401`
- Stripe non-success intent: confirm the storefront returns `payment_not_settled`

## Internal Beta Checklist

- Mission Control layout reviewed on desktop and mobile widths
- PPV storefront checkout path tested with sandbox cards
- Operator actions verified with compile-time env vars:
  - `DFC_OPERATOR_FUNCTION_URL`
  - `DFC_OPERATOR_ID`
  - `DFC_OPERATOR_SECRET`
- Storefront verified with compile-time env vars:
  - `DFC_PPV_STOREFRONT_BASE`
  - `DFC_PPV_AUTO_CONFIRM_SANDBOX`
- Operator credentials injected only into trusted internal builds, not the public web storefront
- Dashboard imported from [monitoring/dfc_operator_observability_dashboard.json](/c:/Users/User/Documents/GitHub/Data-Fight-Central/monitoring/dfc_operator_observability_dashboard.json)

## Rollback

- Disable operator traffic by rotating `OPERATOR_ACTION_SHARED_SECRET`
- Disable storefront purchase entry point in Remote Config or feature flags
- Revert affected functions with the serialized deploy wrapper
