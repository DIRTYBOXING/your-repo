# DFC Production progressive Promotion Roadmap (Canary Rollout)

## Scope
This promotion roadmap covers the runtime services, static web platforms, event consumers, and database structures that comprise the DFC Hybrid Meta 5 platform mesh.

### Runtime & Static Artifacts Promotion (Unified Ring Progression)
All executable workloads, front-end content, routing configurations, and CDN policies must be promoted simultaneously through the cohorted rings to ensure traffic alignment.

| Service / Artifact        | Technology                                                | Promotion Mechanism                     | Rollout Group    |
| ------------------------- | --------------------------------------------------------- | --------------------------------------- | ---------------- |
| **Firebase Hosting**      | Static Reality Portal, web clients                        | hosting_canary_promote.ps1 / GHA        | Runtime workload |
| **Cloud Run services**    | Payments gateway, verify-session, A/B APIs                | scripts/canary_deploy.sh / gcloud       | Runtime workload |
| **GKE deployments**       | Event queue stream consumers, reconciliation task runners | scripts/canary_deploy.sh / helm         | Runtime workload |
| **Firebase Functions**    | Canary Guard webhooks, event handler hooks                | scripts/canary_deploy.sh / firebase-cli | Runtime workload |
| **Edge CDN / CDN config** | Edge cache rules, cache clearing routines                 | hosting_canary_promote.ps1              | Routing policy   |
| **Feature flag routing**  | ffctl control states, cookie session weights              | ffctl                                   | Routing policy   |

### Database Migrations Promotion Gating
Database migrations are decoupled from direct runtime rings to protect ledger integrity. **Database migrations must only be executed on production after Ring 2 (5%) has proven stable for 48 hours without regressions.** All migrations must utilize non-destructive additive schemas, lazy backfills, and maintain explicit tested rollback SQL files.

---

## Ring Definitions & Dwell Times
Run the progressive promotion across five cohorted routing rings. The default track is conservative. An **Alternate Fast Track** is available only during high-frequency maintenance sprint periods, subject to SRE Lead and Payments Engineering approval.

```
       [ RING 0 ] ──> 24h Gate ──> [ RING 1 ] ──> 24h Gate ──> [ RING 2 ]
       Whitelisted SRE/QA          1% Public Cohort            5% Public Cohort
                                                               (Deploy Migrations)
                                                                       │
                                                                   48h Gate
                                                                       │
                                                                       ▼
       [ RING 5 ] <── 24h Gate <── [ RING 4 ] <── 48h Gate <── [ RING 3 ]
       100% Production             50% Public Cohort          25% Public Cohort
```

### Rollout Rings Specifications
1. **Ring 0 (Internal)**: Internal accounts, whitelisted testing units (SRE, Payments, Growth, QA).
   - **Traffic Split**: 0% Public.
   - **Dwell Time**: 4 - 24 hours.
2. **Ring 1 (Canary A)**: Internal whitelists + 1% of random public traffic.
   - **Traffic Split**: 1%.
   - **Dwell Time**: 24 hours.
3. **Ring 2 (Canary B)**: Standard public cohort.
   - **Traffic Split**: 5%.
   - **Dwell Time**: 48 hours.
   - *Gating Milestone: Database Migrations are executed on the master production database upon the completion of Ring 2 validation.*
4. **Ring 3 (Ramp)**: Broad public cohort.
   - **Traffic Split**: 25%.
   - **Dwell Time**: 48 - 72 hours.
5. **Ring 4 (Wide)**: Near-full platform promotion.
   - **Traffic Split**: 50%.
   - **Dwell Time**: 24 - 72 hours.
6. **Ring 5 (Full)**: Production-wide default active state.
   - **Traffic Split**: 100%.
   - **Dwell Time**: Permanent.

### 💨 Alternate Fast Track (Emergency / High-Frequency Patching)
If hotfixes are required or metrics show total baseline stability under load, SRE and Payments Engineering can bypass standard intervals with this acceleration ramp:
- **Ring 1 (Canary A)**: 1% (dwell 4 hours)
- **Ring 2 (Canary B)**: 10% (dwell 12 hours)
- **Ring 4 (Wide)**: 50% (dwell 12 hours)
- **Ring 5 (Full)**: 100%

---

## Preconditions Checklist

Before starting Ring 0, the SRE team and Release Managers must verify that the following preconditions are met:

- [ ] **Tests Green**: All scoped checkout suites, rights verification, and assignment tests must pass cleanly in local and CI harnesses.
- [ ] **Secrets Loaded**: All production values for `PG_CONN`, `WEBHOOK_SECRET`, `STRIPE_KEY`, `STRIPE_CONNECT` must be injected into the production secrets vault; no hardcoded credentials remain in the codebase.
- [ ] **Canary Guard Online**: `functions/canaryGuard` must be registered, active, and capable of intercepting and blocking deployments if metric budgets are breached.
- [ ] **Database Snapshots**: A complete cold backup or pointing-snapshot of the production PostgreSQL database must be created immediately prior to kickoff.
- [ ] **Reconciliation Baseline**: Nightly reconciliation report outputs must show zero outstanding unexplained audit differences.
- [ ] **Grafana & Alerts Armed**: Prometheus targets are actively scraping, Grafana templates are imported under UID `dfc_canary_dashboard`, and PagerDuty routes are verified on the warning/critical tiers.

---

## Per-Ring Playbook

### Common Pre-Kickoff Checks (Local Environment)
Run these commands from your local workstation terminal to confirm build compile targets and perform dry-run migrations against an ephemeral test host before starting:

```bash
# 1. Force rebuild and verify project unit-test baselines
./scripts/build_all.sh
./scripts/test_all.sh

# 2. Bootstrap ephemeral container database
./scripts/test/bootstrap_pg.sh
export PG_CONN="postgres://dfc:dfc@localhost:5432/dfc_test"

# 3. Apply SQL migrations in Dry-Run mode to parse statement check syntax
psql "$PG_CONN" -f migrations/20260702_create_payments_and_webhooks.sql --dry-run
psql "$PG_CONN" -f migrations/20260702_create_experiments_and_assignments.sql --dry-run
```

---

### Ring 0 (Internal) Playbook

This ring activates the platform mesh configuration ONLY for whitelisted on-call staff, engineers, and QA groups. All public traffic executes safe fallback states.

#### Deployment Commands
Deploy containers and static hosting nodes with 0% weight to public routes and configure Whitelists:
```bash
# 1. Trigger container & hosting pipelines with 0% traffic split and team whitelists
./scripts/canary_deploy.sh --env staging --services all --traffic 0 --whitelist "team:sre,team:payments,team:qa,team:growth"

# 2. Enforce staging feature flag state
ffctl set dfc_payments_flow --on --whitelist "team:sre,team:payments,team:qa"
```

#### SRE Verification Commands
Simulate live operations, dry-run replays, and ledger checks:
```bash
# 1. Run 10 synthetic checks to verify billing, entitlement, and ledger creation
node scripts/synthetic_checkout.js --count=10

# 2. Check DB records are properly written
psql "$PG_CONN" -c "SELECT checkout_session_id, status FROM orders ORDER BY created_at DESC LIMIT 10;"

# 3. Run Webhook Replay Dry-Run check to ensure replay parser finds zero duplicates
node scripts/replay_webhooks.js --dry-run --limit=50

# 4. Trigger Instant Ledger Reconciliation
./scripts/run-reconciliation.sh --date $(date +%F)
```

#### Promotion Gate Thresholds (Ring 0 -> Ring 1)
- **Synthetic Checks**: 100% (10 of 10 complete with active ppv_entitlements created)
- **Database Logs**: `orders` status = `paid`, `ledger_entries` platform fee split written.
- **Reconciliation Audit**: 0.00 AUD discrepancy.
- **Sign-Off Required**: `SRE Lead`, `Payments Engineer`

---

### Ring 1 (1% Canary) Playbook

Exposes the live, idempotent verify-session and experiments pipeline to a cohorted pool representing exactly 1% of incoming public traffic.

#### Deployment Commands
```bash
# 1. Route 1% production container traffic
./scripts/canary_deploy.sh --env prod --services cloudrun,gke,functions,hosting --traffic 1

# 2. Adjust routing flags to 1% cohorted rollout
ffctl set dfc_payments_flow --on --percentage 1
```

#### Monitoring Checks (Dwell 24 Hours)
Execute close-range telemetry watches. If any metric breaches alerts thresholds, the Canary Guard Cloud Function automatically triggers the kill-switch and rolls back traffic.
- **Webhook success rate**: target ≥ 99.9% over 5m
- **verify-session P95 latency**: target < 2s
- **Errors budget consumption**: 0% critical errors allowed

#### Diagnostic Logs Commands
```bash
# Tail verify-session container workloads for any unhandled rejections
kubectl -n payments logs -l app=verify-session --tail=200 -f

# Inspect active routing state weights
ffctl status dfc_payments_flow
```

#### Promotion Gate Thresholds (Ring 1 -> Ring 2)
- **A/B Enrolments**: Assignments are deterministic and stable across restarts.
- **Dwell Duration**: SRE observation under continuous load > 24 hours.
- **Error Backlogs**: 0 outstanding fatal entries inside webhook table.
- **Sign-Off Required**: `SRE Lead`, `Payments Engineer`

---

### Ring 2 (5% Canary) Playbook

Spreads traffic to 5% of active accounts. At the completion of this gate, the master database migrations are executed.

#### Deployment Commands
```bash
# 1. Upgrade progressive cohort to 5%
ffctl set dfc_payments_flow --on --percentage 5
```

#### Verification Checks (Dwell 48 Hours)
- **Reconciliation Routine**: Execute daily and verify the audit output does not throw warning markers.
- **SLO Checks**: verify-session P95 latency must remain < 2s under load.
- **Gating Execution - Execute Master Production Migrations**:
```bash
# Execute only after Ring 2 completes 48-hour soak with zero critical alerts!
psql "$PG_CONN" -f migrations/20260702_create_payments_and_webhooks.sql
psql "$PG_CONN" -f migrations/20260702_create_rights_and_takedown.sql
psql "$PG_CONN" -f migrations/20260702_create_experiments_and_assignments.sql
```

#### Promotion Gate Thresholds (Ring 2 -> Ring 3)
- **Database Migrations status**: Applied, tested up/down, verified clean state.
- **Financial reconciliation**: 0.00 AUD outstanding discrepancy.
- **Sign-Off Required**: `SRE Lead`, `Payments Engineer`, `Data Analyst`

---

### Ring 3 (25% Ramp) Playbook

Opens the platform mesh to 25% of standard public accounts. Requires comprehensive cross-departmental operations and product checks.

#### Deployment Commands
```bash
# 1. Advance cohort rollout percentage to 25%
ffctl set dfc_payments_flow --on --percentage 25
```

#### Verification Checks (Dwell 48 - 72 Hours)
- Verify that **Data exposure logs** are flowing within 30s of engagement to the downstream warehouse.
- Verify that any region-restricted geoblocking or content rights enforcement (takedown status) is correctly matching the applied `geo_policy` indices without false positives.
- Watch **Stripe Connect onboarding registries** and verify that no developer webhook queues are jammed.

#### Promotion Gate Thresholds (Ring 3 -> Ring 4)
- **Exposure Pipeline Latency**: p50 ingestion < 30s.
- **Business Approval**: Product / Growth accepts canary behavior metrics.
- **Sign-Off Required**: `SRE Lead`, `Payments Engineer`, `Data Analyst`, `Product Manager`

---

### Ring 4 (50% Wide Canary) Playbook

Rolls out configurations to exactly half of all incoming users. This is the last phase before total platform cutover and baseline stabilization.

#### Deployment Commands
```bash
# 1. Elevate feature flag splits
ffctl set dfc_payments_flow --on --percentage 50
```

#### Verification Checks (Dwell 24 - 72 Hours)
- Run comprehensive reconciliation comparison against the corporate ledger files.
- Verify that container CPU/Memory bounds in GKE are not scaling out of bounds or leaking memory.
- Monitor client analytics logs to ensure billing UI elements compile properly on mobile/tablet platforms.

#### Promotion Gate Thresholds (Ring 4 -> Ring 5)
- **Reconciliation Audit**: Signed and closed by corporate financial auditing leads.
- **Infrastructure Overhead**: GKE container CPU usage stays < 60% threshold limit.
- **Sign-Off Required**: `SRE Lead`, `Payments Engineer`, `Finance Auditor`, `GTM Director`

---

### Ring 5 (100% Production Cutover) Playbook

Total platforms mesh deployment. The feature flag is promoted as default-activated, and the rollback hooks are decommissioned.

#### Deployment Commands
```bash
# 1. Activate payments and experiments flows globally
ffctl set dfc_payments_flow --on --percentage 100

# 2. Decommission canary whitelist routes by setting default as true
ffctl set dfc_payments_flow --on --default=true
```

#### Post-Promotion Checks (72-Hour Survival Monitor)
- Import final Grafana boards into the SRE central monitor room.
- Declare the platform mesh stable and close the active incident watch room.
- Document rollout statistics inside the `RELEASE.md` and complete final GTM launch reporting.

---

## Rollback & Incident Playbook (First 30 Minutes)

If a critical alert fires (e.g., elevated webhook ingest failures, p95 verify-session latency spikes, or reconciliation discrepancy > 0.00):

### 🚨 1. Immediate Impact Containment (0 - 5 Minutes)
Flip the global kill-switch feature flag. This instantly disables the Payments, verify-session, and Experiments mesh routes, safely redirecting checkout traffic to legacy handlers or gracefully failing with helpful user notifications.
```bash
# Force-disable payments flow globally
ffctl set dfc_payments_flow --off
```

### 🔍 2. Diagnostic Investigation (5 - 15 Minutes)
Perform diagnostic checks to identify the root cause of the incident:
```bash
# 1. Output pending/failed events to local triage file
node scripts/replay_webhooks.js --dry-run --limit=200 > /tmp/replay_triage.log

# 2. Read the error messages from the log
cat /tmp/replay_triage.log | grep -E "duplicate|failed|rejection"

# 3. Check for database locks or connection leak exhaustion
psql "$PG_CONN" -c "SELECT pid, query, state, age(clock_timestamp(), query_start) FROM pg_stat_activity WHERE state != 'idle';"
```

### 🛠️ 3. Execution of Recovery & Runbook Escalation (15 - 30 Minutes)
- **Unearned Entitlements**: Void duplicate checkout sessions, and run `./scripts/run-reconciliation.sh --date $(date +%F)` to export discrepancy CSVs.
- **DB Corruption Resolution**: Restore the point-in-time PostgreSQL database snapshot created prior to the ring kickoff, then safely **replay append-only events from the event stream** (Kafka/Event Store) to rebuild state with zero transaction loss.
- **Emergency Database Schema Revert (Only if schema rollback is authorized)**:
  ```bash
  psql "$PG_CONN" -f migrations/20260702_drop_experiments_and_assignments.sql
  psql "$PG_CONN" -f migrations/20260702_drop_payments_and_webhooks.sql
  ```
- **PagerDuty Escalation**: Escalate the thread, attach discrepancy files, and page the tertiary crisis response leads.

---

## Prometheus Queries & Alerting Thresholds

Configure the Prometheus scrape server to evaluate the following queries. Ingest values directly to your central Alertmanager targets.

### Webhook failure rate (5m window)
- **PromQL**: `sum(rate(payments_webhook_failures_total[5m])) / sum(rate(payments_webhook_requests_total[5m]))`
- **Thresholds**:
  - `Warning`: > 0.005 (0.5% failures) for 5m. Routes to Slack `#payments-ops` and SRE on-call email.
  - `Critical`: > 0.01 (1% failures) for 5m. Triggers **PagerDuty page** to core on-call engineers.

### verify-session P95 Latency (5m window)
- **PromQL**: `histogram_quantile(0.95, sum(rate(verify_session_duration_seconds_bucket[5m])) by (le))`
- **Thresholds**:
  - `Warning`: > 2.0 seconds for 5m.
  - `Critical`: > 5.0 seconds for 5m. Triggers **PagerDuty page** and automates Canary Guard rollback rules.

### Exposure Ingest Latency Median
- **PromQL**: `histogram_quantile(0.5, sum(rate(exposure_ingest_latency_seconds_bucket[5m])) by (le))`
- **Thresholds**:
  - `Warning`: > 15.0 seconds.
  - `Critical`: > 30.0 seconds.

---

## Sign-off Gate Matrix

Use this checklist matrix to obtain formal sign-offs before proceeding to adjacent canary rings. File copies must be appended to the staging PR description.

```
┌─────────────────┬─────────────────┬──────────────────────┬─────────────┬─────────────┬─────────────┐
│ Rollout Gate    │ SRE Lead        │ Payments Eng Lead    │ Data Lead   │ Finance     │ Product     │
├─────────────────┼─────────────────┼──────────────────────┼─────────────┼─────────────┼─────────────┤
│ Ring 0 (0%)     │ [ ] Sign:______ │ [ ] Sign:___________ │ [ ] N/A     │ [ ] N/A     │ [ ] N/A     │
├─────────────────┼─────────────────┼──────────────────────┼─────────────┼─────────────┼─────────────┤
│ Ring 1 (1%)     │ [ ] Sign:______ │ [ ] Sign:___________ │ [ ] N/A     │ [ ] N/A     │ [ ] N/A     │
├─────────────────┼─────────────────┼──────────────────────┼─────────────┼─────────────┼─────────────┤
│ Ring 2 (5%)     │ [ ] Sign:______ │ [ ] Sign:___________ │ [ ] Sign:__ │ [ ] N/A     │ [ ] N/A     │
├─────────────────┼─────────────────┼──────────────────────┼─────────────┼─────────────┼─────────────┤
│ Ring 3 (25%)    │ [ ] Sign:______ │ [ ] Sign:___________ │ [ ] Sign:__ │ [ ] N/A     │ [ ] Sign:__ │
├─────────────────┼─────────────────┼──────────────────────┼─────────────┼─────────────┼─────────────┤
│ Ring 4 (50%)    │ [ ] Sign:______ │ [ ] Sign:___________ │ [ ] Sign:__ │ [ ] Sign:__ │ [ ] Sign:__ │
├─────────────────┼─────────────────┼──────────────────────┼─────────────┼─────────────┼─────────────┤
│ Ring 5 (100%)   │ [ ] Sign:______ │ [ ] Sign:___________ │ [ ] Sign:__ │ [ ] Sign:__ │ [ ] Sign:__ │
└─────────────────┴─────────────────┴──────────────────────┴─────────────┴─────────────┴─────────────┘
```

---

## Appendix: Automated Promoting Tooling References

### Canary Guard hook (`functions/canaryGuard`)
Evaluates active Prometheus metric counts. If error budgets are exhausted, it calls the Feature Flag CLI via Cloud Shell to automate progressive traffic cutoff.
- **Trigger**: Executed by cron scheduler every 1 minute.
- **Log check command**: `gcloud functions logs read canaryGuard --region=us-central1 --limit=50`

### Canary Deployment Orchestrator (`scripts/canary_deploy.sh`)
Orchestrates deployment to production pods. It supports direct traffic splits and on-the-fly whitelisting controls.
- **Usage Examples**:
  ```bash
  # Route 5% traffic on production pods with ATT, TMT and Sydney Fight Club domains
  ./scripts/canary_deploy.sh --env prod --services cloudrun --traffic 5 --domains "tiger_muay_thai,att,syd_fight_club"
  ```

### Static CDN Version Promoter (`hosting_canary_promote.ps1`)
Safely deploys static, secure client wireframes, landing platforms, and CDN directory indexes.
- **Usage Examples**:
  ```powershell
  # Promote static portal directory with 10% edge weight and invalidate CDN cache
  ./hosting_canary_promote.ps1 --env prod --weight 10 --invalidate-cache
  ```

### Synthetic Checkout Runner (`scripts/synthetic_checkout.js`)
Autonomous script that creates secure checkout sessions and pushes completions to webhook interfaces.
- **Usage Examples**:
  ```bash
  # Seed 5 synthetic completions and verify ledger entries
  node scripts/synthetic_checkout.js --count=5 --verbose
  ```
