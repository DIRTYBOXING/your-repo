# DFC Master Execution Plan 2026

Status: active operating plan for taking DFC from a broad, partially hardened platform into a disciplined promoter-first combat sports business.

Purpose: give DFC one execution order that matches what is already built in the repo, what was just hardened, and what still blocks public trust, repeatable revenue, and partner readiness.

Use this document as the top-level plan. Sub-plans such as PPV readiness, streaming doctrine, canonical event graph, and Betaverse standards remain valid, but they should roll up into this plan.

---

## 1. Non-Negotiables

These rules are now the contract for all future DFC work.

1. No fake production paths. Demo content belongs only in tagged test or staging environments.
2. One purchase authority for PPV. Canonical checkout sessions are the source of truth.
3. One entitlement authority. Token validation and access decisions must converge, not fork.
4. One canonical event graph. Event, PPV, artwork, and media references must resolve from approved records.
5. Promoter-first operations. A promoter or operator must be able to run an event without database digging.
6. Revenue before novelty. Hardening settlement, replay, access, and launch surfaces takes priority over speculative new products.
7. Safe expansion only. Betaverse, AI, and immersive surfaces must follow moderation, youth safety, and governance standards already documented in repo.

---

## 2. Current Truth

### 2.1 What is now real

1. PPV authority has been unified around canonical session writes, session-first access checks, and proxy-first entitlement validation.
2. The standalone entitlement service now supports app-factory testing, local smoke validation, and compatibility proxying.
3. The canonical event graph now resolves artwork and event-linked media more consistently across event and PPV surfaces.
4. Social and event surfaces have been consolidated around stronger shared services and media rendering.
5. The Superbeast backend now has persistence tables, operator routes, event outbox support, and passing targeted backend tests.
6. Betaverse doctrine, product standards, founder brief, and code-ops standards are now documented as a connected chain.

### 2.2 What still blocks DFC from being fully public-ready

1. PPV public readiness is still gated by operational secrets, one full live rehearsal, and a real settlement surface.
2. Promoter payout and reconciliation visibility is still not a first-class canonical dashboard.
3. Launch-pack and distribution flows are still spread across multiple surfaces instead of one operator-safe event pack workflow.
4. Partner onboarding, rights handling, and evidence workflows exist in pieces, but are not yet a polished operator lane.
5. Observability, runbooks, and release gates need to be treated as product requirements, not optional engineering chores.

---

## 3. The Correct DFC Priority Order

DFC should execute in this order.

### Priority 1: Public-Ready Revenue Spine

Goal: make one PPV event commercially safe to sell, run, replay, and reconcile.

Execution companion: `docs/DFC_PRIORITY_1_REVENUE_SPINE_CHECKLIST_2026.md`

Must ship:

1. Environment and secrets closure for Mux, Stripe, entitlement proxy, Firebase, and replay flows.
2. One canonical settlement and payout ledger for promoter, fighter, creator, reserve, disputes, refunds, and payout status.
3. One full rehearsal from event creation to replay publication and reconciliation.
4. One operator runbook for event day, incident response, and replay verification.

Primary repo lanes:

1. `functions/stripe/ppv.js`
2. `functions/ppv/access_state.js`
3. `functions/entitlement.js`
4. `functions/drm-license-exchange.js`
5. `functions/streaming/mux.js`
6. `entitlements-service/`
7. promoter PPV and control-room surfaces in `lib/features/promoter` and `lib/features/ppv`

Exit gate:

DFC can run one private paid event with verified buy flow, watch flow, replay flow, refund path, and settlement output.

### Priority 2: Promoter Operating System

Goal: make DFC useful enough that a promoter wants to run repeat events through it.

Must ship:

1. Control-room simplification for event arming, stream credentials, status, and replay state.
2. Launch-pack generator that turns one canonical event record into posters, captions, links, and export bundles.
3. Promoter revenue, payout status, and campaign performance surfaces.
4. Event graph-backed event pages that look commercial and consistent.

Primary repo lanes:

1. `lib/features/promoter/`
2. `lib/shared/services/canonical_event_graph_service.dart`
3. `lib/shared/widgets/event_cards.dart`
4. `lib/shared/services/cross_platform_posting_service.dart`
5. `lib/shared/services/social_post_adapter_service.dart`

Exit gate:

One operator can set up an event, generate the launch pack, distribute it, and monitor commercial health from DFC surfaces alone.

### Priority 3: Distribution And Growth Engine

Goal: turn DFC from a tool into a growth machine.

Must ship:

1. Canonical social post creation and personalized feed loops tied to event and PPV objects.
2. Cross-platform publishing workflows for event, fighter, and replay promotion.
3. Approved media asset governance so official artwork and clip payloads do not fragment.
4. Partner and promotion inventory workflows for rights-safe distribution.

Primary repo lanes:

1. `functions/content/`
2. `lib/features/social/`
3. `lib/shared/services/social_service.dart`
4. `lib/shared/services/dfc_social_engine.dart`
5. `lib/shared/widgets/dfc_post_media.dart`
6. relevant docs and partner inventory records

Exit gate:

Every major event can be promoted from one source record into owned surfaces and external channels with approved art, links, and status.

### Priority 4: Trust, Compliance, And Evidence

Goal: make DFC safe for promoters, fighters, partners, and future regulators.

Must ship:

1. Evidence locker workflows connected to moderation and incident review.
2. Rights and source validation for promotional assets and inbound partner content.
3. Dispute, refund, and fraud review playbooks for PPV commerce.
4. Clear production-vs-test enforcement in content and event pipelines.

Primary repo lanes:

1. `atlas_backend/evidence/`
2. `atlas_backend/moderation/`
3. `functions/anti_fraud.js`
4. trust and safety services in Flutter and functions

Exit gate:

DFC can explain what happened during a payment, moderation, or content dispute using one auditable chain.

### Priority 5: Betaverse And Long-Horizon Expansion

Goal: expand only after the revenue and operator spine is trusted.

Must ship after the earlier priorities are stable:

1. immersive and community experiences that follow the Betaverse product and code-ops standards
2. founder and partner positioning for strategic alliances
3. AI-assisted orchestration that amplifies real event, partner, and commerce workflows instead of adding parallel toy surfaces

Exit gate:

New experiences launch only when they strengthen retention, trust, or revenue without weakening the public-ready spine.

---

## 4. 30 / 60 / 90 Day Plan

### Day 0 to 30

This is the hardening month.

1. Close all runtime secret and environment gaps for streaming and entitlement validation.
2. Finish the canonical promoter settlement and payout screen.
3. Run one full private rehearsal from event setup through replay and reconciliation.
4. Write the event-day operator runbook and incident checklist.
5. Freeze net-new experimental product work unless it directly supports these items.

Success condition:

One private event can be sold and operated end to end without manual backend digging.

### Day 31 to 60

This is the operator month.

1. Unify launch-pack generation around the canonical event record.
2. Tighten promoter control room, PPV landing pages, replay surfaces, and status visibility.
3. Finish promoter-facing revenue and payout visibility.
4. Connect canonical event graph outputs to social publishing and event discovery surfaces.

Success condition:

One promoter can prepare, launch, and review an event from DFC with minimal support.

### Day 61 to 90

This is the expansion month.

1. Turn event promotion into a repeatable cross-platform distribution workflow.
2. Add evidence and moderation closures to operator workflows.
3. Finalize partner-facing onboarding and positioning materials.
4. Open the next wave of AI, community, or Betaverse work only after the first three priorities are green.

Success condition:

DFC has one repeatable commercial operating loop: create event, promote event, sell access, run event, replay event, reconcile event, rebook promoter.

---

## 5. Workstreams And Ownership Model

Every DFC task should map to one of these workstreams.

1. Commerce and entitlement
2. Streaming and replay
3. Promoter operations
4. Distribution and content growth
5. Trust, moderation, and evidence
6. Data and canonical graph
7. Partner readiness and doctrine

Rule: no task should be approved unless it clearly improves one of these workstreams or removes a blocker from one of them.

---

## 6. Release Gates

### Gate A: Internal Stable

Requirements:

1. clean builds and targeted tests for touched modules
2. env and secrets documented
3. no fake production data paths
4. runbook updated

### Gate B: Private Event Pilot

Requirements:

1. paid purchase succeeds
2. entitlement and playback succeed
3. replay is generated and access-controlled
4. settlement output is readable by operator and promoter

### Gate C: Public Event Ready

Requirements:

1. one full rehearsal passed
2. operator can run the event without developer intervention
3. promoter can understand commercial state without raw database access
4. disputes, refunds, and evidence review have an auditable path

---

## 7. What DFC Should Not Do Right Now

These are not forbidden forever, but they are wrong before the spine is stable.

1. build parallel payment systems that bypass canonical PPV authority
2. build immersive or metaverse novelty features ahead of settlement and public PPV readiness
3. keep adding one-off event or poster logic outside the canonical event graph
4. ship promoter-facing revenue promises without a real reconciliation surface
5. expand AI features that are not directly tied to promotion, safety, or revenue execution

---

## 8. North-Star Scoreboard

Track DFC with these top metrics.

1. event setup time from creation to launch-ready
2. checkout completion rate
3. entitlement success rate
4. replay publish delay
5. payout reconciliation time
6. promoter repeat booking rate
7. approved distribution package completion rate
8. moderation and evidence closure time

If these metrics improve, DFC is becoming a real combat sports operating system. If they do not, the platform is expanding sideways instead of upward.

---

## 9. Canonical DFC One-Liner

DFC is the promoter-first operating system for combat sports: create the event, distribute the event, sell the event, stream the event, replay the event, and reconcile the event from one trusted platform.
