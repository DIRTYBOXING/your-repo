# DFC Streaming 0-90 Day Foundation

Version: 2026-04-18
Status: foundation document
Related:

- `docs/architecture/dfc_multi_region_streaming_blueprint.md`
- `docs/architecture/dfc_ppv_system_snapshot.md`
- `docs/architecture/dfc_whole_stack_comparison.md`
- `docs/runbooks/DFC_PPV_LIVE_EVENT_OPS_RUNBOOK.md`

## Purpose

This document defines the 0-90 day foundation DFC has to replace with real platform behavior.

It is not a backlog.
It is not a fantasy scale plan.
It is the minimum foundation required to stop improvising across PPV, entitlements, playback, and event operations.

It is grounded in the current stack already present in the repo:

- Flutter clients as the canonical product surface
- Firebase plus GCP as the control plane
- Firebase Functions as the strongest current purchase and PPV access lane
- Mux as the strongest current media and playback authority
- separate entitlement services already present and needing convergence, not duplication

## What this foundation is fixing

The stack review shows DFC already has enough parts to run serious events.
The problem is that the real stack is split across overlapping authorities.

Current fault lines:

- multiple payment acquisition patterns
- multiple entitlement and token authorities
- playback authority spread across Functions, Mux integration, and dedicated entitlement services
- event operations still too dependent on operator memory instead of platform truth

The 0-90 day foundation exists to remove that confusion.

## Foundation rules

1. one entitlement authority must be declared canonical before any new premium playback features are added
2. DFC-owned event, checkout, watch, and replay surfaces remain canonical
3. social, clips, and promotion feed traffic into DFC, not around DFC
4. PPV and checkout chrome stays restrained and professional
5. no new DRM, token, payment, or playback authority is introduced during foundation work
6. reliability claims only count after rehearsal on the real stack

## Day 0 to 30: establish platform truth

This phase is about stopping the stack from contradicting itself.

### Foundation target: canonical authority map

DFC needs one written truth for:

- purchase creation
- purchase settlement
- entitlement resolution
- playback authorization
- replay access

The current repo points to Firebase Functions plus Firestore access records as the strongest integrated PPV authority. That needs to be explicitly declared while parallel paths are quarantined.

Required outcomes:

- one canonical entitlement authority declared
- one canonical checkout to access path declared
- all non-canonical token or access paths marked transitional or disabled from watch-critical flows
- operator-facing explanation of where truth lives for PPV access

### Foundation target: server-side watch gate

Playback must not depend on client-side interpretation of purchase truth.

Required outcomes:

- playback authorization resolved server-side
- geo and rights logic resolved before manifest or token release
- denial reasons made operator-readable
- paid user recovery path documented without introducing a second authority

### Foundation target: trusted PPV surfaces

The app has to stop looking experimental on premium flows.

Required outcomes:

- PPV hub, event detail, checkout, and watch states follow restrained product chrome
- playful or game-like UI remains outside commerce-critical surfaces
- trust posture is visually consistent across web and mobile

## Day 31 to 60: make the stack behave like one system

This phase is about joining ingest, packaging, delivery, and telemetry into the same operational lane.

### Foundation target: controlled live media path

DFC should use the real media path it already has, then harden it.

Required outcomes:

- primary and backup ingest paths documented and tested
- HLS and DASH output verified from the chosen packaging path
- ABR ladder verified on web and one native client
- replay-ready output path confirmed before event day

### Foundation target: disciplined delivery path

Delivery must be measurable before it is scaled.

Required outcomes:

- single-CDN path with documented cache behavior
- prewarm procedure for premium events
- region-aware visibility into startup failures, edge errors, and rebuffering
- playback telemetry joined to entitlement and commerce telemetry

### Foundation target: player contract parity

Web and native cannot behave like separate products.

Required outcomes:

- same entitlement states across web, iOS, and Android
- same playback state naming and telemetry contract
- same operator-visible failure categories across clients

## Day 61 to 90: harden the real event lane

This phase is about proving that the foundation works under event pressure.

### Foundation target: premium event rehearsal

DFC needs to rehearse the real failure modes, not discuss them.

Required outcomes:

- full dress rehearsal using the canonical purchase, entitlement, and playback path
- rollback exercise for watch-critical services
- degraded-mode drill for entitlement and ingest failures
- promoter, support, and operator communications exercised against the runbook

### Foundation target: premium spike readiness

Scale claims only matter if the event lane can absorb them.

Required outcomes:

- synthetic concurrency test against the canonical event path
- identified saturation points for entitlement, origin, or edge delivery
- optional backup CDN path evaluated for premium events
- replay readiness measured as an operational KPI

### Foundation target: growth attached to the canonical surface

Growth only matters if it strengthens the owned watch business.

Required outcomes:

- promoter and social traffic lands on canonical DFC event pages
- attribution works for creators, fighters, gyms, and promoters
- replay and clip publication routes viewers back into DFC-owned surfaces
- no discovery experiment bypasses entitlement or checkout truth

## Cross-stack replacement priorities

### Replace ambiguity with declared authority

- replace parallel entitlement interpretation with one canonical service decision
- replace overlapping checkout stories with one operator-readable purchase flow
- replace tribal knowledge with written runbooks and dashboards

### Replace isolated tools with one event lane

- replace disconnected media steps with one documented live path
- replace per-client playback behavior drift with one player contract
- replace optimistic event operations with rehearsal-backed readiness

### Replace noisy product cues with trust

- replace toy-like premium UI cues with restrained shell and watch surfaces
- replace mixed messaging on access states with explicit entitlement outcomes
- replace scattered event comms with one status and incident language set

## Proof that the foundation is real

By day 90, DFC should be able to prove the following on the actual stack:

- one premium event can run through one canonical purchase-to-watch path
- entitled users enter consistently and non-entitled users are denied consistently
- web and native clients report the same watch-critical states
- live operators can fail over, roll back, and communicate without inventing process mid-event
- promoters and social channels drive traffic into DFC-owned pages instead of replacing them

## What foundation work must not become

- not a second entitlement rewrite running beside the first one
- not a speculative platform rebuild detached from the repo
- not a UI refresh that ignores checkout and playback truth
- not a scale claim without synthetic tests and event rehearsal
- not a recommendation project that lands before PPV authority is clean
