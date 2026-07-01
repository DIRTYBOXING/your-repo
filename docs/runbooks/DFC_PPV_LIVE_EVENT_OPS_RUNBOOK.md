# DFC PPV Live Event Ops Runbook

Version: 2026-04-18
Audience: SRE, streaming ops, promoter ops, PPV operators, product leads
Related:

- `docs/architecture/dfc_multi_region_streaming_blueprint.md`
- `docs/architecture/dfc_one_page_architecture.svg`
- `docs/architecture/dfc_ppv_system_snapshot.md`
- `docs/PPV_INCIDENT_RESPONSE.md`
- `docs/DFC_PPV_OPERATOR_CHECKLIST.md`

## Purpose

This is the compact event-week runbook for a single DFC PPV event.

Use this document when the event is real, launch risk matters, and the team needs one operational checklist that covers:

- preflight
- live monitoring
- degraded-mode handling
- rollback
- postmortem

This runbook assumes the canonical DFC rules still apply:

- DFC-owned watch and event pages remain canonical
- product chrome stays professional on PPV and checkout surfaces
- social channels are acquisition lanes, not the playback authority
- no parallel entitlement authority is introduced during live event preparation

## Event roles

Every live PPV must name these owners before launch:

- event commander: overall decision owner
- streaming operator: ingest, packager, playback, CDN
- commerce owner: checkout, entitlement, receipts, geo policy
- support lead: customer support, status messaging, incident intake
- promoter owner: promoter communications and approvals
- settlement owner: replay, reconciliation, refunds or credits if needed

Do not go live without named owners.

## Critical event KPIs

Track these live:

- playback success rate greater than 98 percent
- rebuffer ratio less than 1 percent
- first frame time within platform target
- entitlement validation latency within target
- checkout success rate within expected baseline
- CDN edge hit ratio within event target
- ingest packet loss and encoder stability within threshold

## Preflight timeline and owners

- T-72 hours owner: product ops confirms event truth, entitlement flow, refund posture, and the operator thread
- T-48 hours owner: streaming engineering verifies ingest, packager, manifest, replay readiness, and CDN prewarm plan
- T-24 hours owner: SRE runs the verification lane, reviews thresholds, confirms rollback readiness, and enables edge protections
- T-2 hours owner: on-call operator runs final smoke, opens the status channel, and freezes non-critical watch-path changes

## T-72 to T-24 hours: preflight

### Product and event truth

- confirm the DFC event page is the canonical landing page
- confirm event metadata, poster, prices, replay policy, and timezone are correct
- confirm the PPV route, watch route, and event route all resolve correctly
- confirm feature flags for any playful discovery surfaces are isolated from PPV and checkout surfaces

### Commerce and entitlements

- run end-to-end purchase test: checkout -> receipt -> entitlement -> watch access
- verify geo rules and blackout rules for the event
- confirm entitlement logs show explicit allow or deny reasons
- verify refunds or manual-access recovery path exists if entitlement release fails

### Streaming and delivery

- verify primary ingest path
- verify secondary ingest path
- verify automatic or manual failover path and documented switch conditions
- confirm packager or transcoder outputs required HLS and DASH renditions
- confirm ABR ladder is available in test playback
- confirm origin or manifest service serves the correct signed playback behavior
- coordinate CDN prewarm plan for manifests, posters, and top renditions

### Ops and security

- publish on-call rota and escalation tree
- verify dashboards for ingest, playback, entitlement, checkout, and CDN
- enable WAF, rate limits, and event-specific DDoS posture
- verify alert thresholds for entitlement latency, startup failure, and rebuffer spikes

### Synthetic testing

- run synthetic playback test at current target concurrency tier
- capture startup, rebuffer, entitlement latency, and checkout metrics
- do not proceed unless results are reviewed by event commander and streaming operator

### Exact DFC verification lane

Use the existing repo-safe PPV lane before claiming event readiness.

PowerShell or shell commands:

```powershell
npm --prefix entitlements-service start
node scripts/ppv_runtime_readiness_check.mjs
npm --prefix entitlements-service run test:smoke
node scripts/smoke_mux_auth.mjs --base-url "https://australia-southeast1-datafightcentral.cloudfunctions.net"
pwsh -ExecutionPolicy Bypass -File tools/smoke/e2e_checkout_playback.ps1 -BaseUrl "<baseUrl>" -EventId "<eventId>" -UserId "<userId>" -Email "<email>"
```

VS Code task equivalents:

- `PPV: Start Entitlement Proxy`
- `PPV: Runtime Readiness Check`
- `PPV: Smoke Entitlement Proxy`
- `PPV: Smoke Mux Auth`
- `PPV: Priority 1 Verification Lane`
- `PPV: Smoke Checkout + Playback (Windows)`

Operator-only or destructive rehearsal commands:

```powershell
node scripts/smoke_mux_credential_delivery.mjs --base "https://australia-southeast1-datafightcentral.cloudfunctions.net" --recipient "<operator email>"
node scripts/prepare_ppv_replay.cjs --eventId "<eventId>" --playbackId "<playbackId>" --replayUrl "<replayUrl>" --replayPath "<storagePath>" --dryRun true
```

Use destructive commands only in controlled rehearsal windows, never as the default smoke lane.

## T-24 to T-2 hours: launch lock

### Final launch lock checklist

- freeze non-critical deploys on watch-critical services
- confirm blue-green or canary rollback target is healthy
- confirm region rollout status and active region health
- confirm incident templates and customer messaging are drafted
- confirm replay pipeline is prepared before live start, not after

### Live environment checks

- verify encoder primary and backup are both reachable
- verify live countdown or pre-show is visible on approved surfaces only
- verify checkout still converts from canonical entry points
- verify watch gate blocks non-entitled users and passes entitled users
- verify support team has known-issues script and refund or credit policy

## T-60 to T-10 minutes: final go-live gate

All of the following must be true:

- primary ingest healthy
- secondary ingest healthy
- packager healthy
- origin healthy
- CDN healthy
- entitlement service healthy
- checkout healthy
- playback healthy on web and one native mobile client

If any watch-critical system is degraded without a clear fallback, hold launch.

## Live event operations

### Live monitoring loop

During the event, watch these continuously:

- encoder bitrate, packet loss, dropped frames
- ingest edge health
- packager queue or transcoder saturation
- manifest latency and origin errors
- CDN hit ratio and regional error spikes
- playback startup time and rebuffering
- entitlement latency and denial spikes
- checkout errors and payment failures

### Five-minute operational cadence

Every five minutes during the event, confirm:

- playback success rate is holding above target
- rebuffer ratio remains below target
- entitlement latency remains within threshold
- packager or transcoder instances are not backing up or restarting unexpectedly
- edge hit ratio stays strong enough that origin is not taking avoidable load
- encoder packet loss stays below event threshold

Use the safe Mux auth smoke lane only when credential delivery or Mux runtime health is specifically in doubt. Do not use destructive credential delivery smoke during the live window.

### Escalation thresholds

Escalate immediately if any of the following occur:

- sustained entitlement latency spike beyond target
- playback success rate below threshold
- rebuffer ratio spike above threshold
- regional CDN failure or origin saturation
- encoder instability with no healthy backup path
- checkout success collapse or mass entitlement denials

### Live actions allowed

- fail over to backup ingest path
- prewarm additional CDN paths
- reduce aggressive front-end experiments through feature flags
- disable non-essential community or play-layer surfaces if they add noise during incident handling
- move to rollback target if service deploy caused degradation

### Live actions not allowed

- do not introduce a new payment or entitlement path under pressure
- do not reroute paid watch traffic to a third-party social platform as the new primary experience
- do not promise replay timing that the replay lane cannot meet

## Degraded mode handling

### Case 1: entitlement slow or failing

Actions:

- confirm whether issue is checkout-side, receipt-side, or entitlement validation-side
- switch operator focus to entitlement authority first
- pause non-critical UI changes
- prepare support message for customers who paid but cannot enter
- if needed, enable approved temporary recovery path without creating a second authority

### Case 2: ingest degradation

Actions:

- inspect packet loss, jitter, encoder health
- fail over to backup contribution path
- reduce bitrate ladder exposure if required to stabilize origin and playback
- log exact failover time and affected minutes

### Case 3: CDN or regional delivery degradation

Actions:

- inspect edge error rate by region
- confirm origin is healthy before blaming edge delivery
- route traffic to backup CDN or safer path if approved
- communicate regional scope clearly in status channels

### Case 4: checkout converting but playback failing

Actions:

- inspect entitlement issuance and playback-token flow immediately
- verify event page and watch route are using canonical authority
- freeze promotion pushes until entitlement confidence is restored
- prepare compensation flow for paid users if incident lasts beyond threshold

## Rollback plan

### Rollback triggers

- deploy introduced watch-critical regression
- entitlement or playback failure is linked to latest release
- canary metrics are materially worse than baseline

### Rollback order

1. disable non-essential feature flags
2. route traffic off the new canary or green deployment
3. revert to previous healthy service version
4. verify entitlement, playback, and checkout health
5. publish operator status update

Rollback must be reversible and documented per region.

## Communication templates

### T-72 preflight kickoff

```text
DFC LIVE EVENT PREFLIGHT
Event: <event name>
Window: T-72 hours begins now
Owners: product ops, streaming engineering, SRE, support
Required pass list: entitlement flow, packager output, dual ingest, CDN prewarm, synthetic load, smoke lane
Action: reply in thread with PASS or FAIL plus evidence for your lane
```

### Critical incident alert

```text
ALERT: [CRITICAL] Live playback degradation detected
Event: <event name>
Trigger: <metric or threshold>
Immediate actions: inspect packager health, inspect CDN edge ratio, inspect entitlement latency
Pager: <sre-oncall> <streaming-oncall> <product-ops>
Update cadence: every 2 minutes until contained
```

### Internal status channel update

```text
DFC PPV STATUS
Event: <event name>
Severity: <sev>
Time: <timestamp>
Issue: <one-line issue summary>
Impact: <who is affected>
Current action: <what the team is doing>
Next update: <time>
Owner: <name>
```

### Customer-facing degraded service note

```text
We are actively resolving a live event issue affecting some viewers. Purchases remain recorded and access will be restored as quickly as possible. Thank you for your patience.
```

### Resolved note

```text
The live event issue has been resolved. Playback and access are operating normally again. If your access still looks incorrect, contact support and include your purchase email or account ID.
```

### Postmortem notification

```text
POSTMORTEM SCHEDULED
Event: <event name>
Review time: <timestamp>
Owners: SRE, streaming engineering, product ops
Deliverables: RCA, mitigation plan, customer credit or refund decision, runbook updates
```

## Post-event closeout

### Within 30 minutes of event end

- confirm replay readiness or publish exact replay hold reason
- confirm watch session closeout metrics captured
- confirm entitlement and checkout logs retained for audit
- confirm support channel remains staffed for post-event issues

### Within 24 hours

- reconcile purchases, entitlement grants, failed charges, and refunds
- review playback KPIs against targets
- review regional performance and CDN behavior
- capture promoter distribution performance and conversion signals
- publish internal event summary

### Within 72 hours

- complete postmortem if thresholds were breached
- document root cause, timeline, mitigation, and follow-up actions
- update this runbook, dashboards, and alert thresholds if gaps were found
- publish customer credit or refund policy if paid viewers were materially affected

## Definition of a healthy event

An event is considered operationally healthy when:

- users can discover the event on canonical DFC pages
- checkout and entitlement complete without hidden manual intervention
- playback is stable across the primary supported clients
- replay availability is predictable
- social and promoter distribution feed traffic into DFC surfaces instead of replacing them
- operators can explain any denial, degradation, or rollback with logs and ownership
