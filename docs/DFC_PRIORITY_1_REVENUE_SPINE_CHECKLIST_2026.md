# DFC Priority 1 Revenue Spine Checklist 2026

Status: concrete engineering checklist for the first execution lane in `docs/DFC_MASTER_EXECUTION_PLAN_2026.md`.

Purpose: convert Priority 1 from a strategy statement into an exact delivery list with file ownership, verification, and release gates.

---

## 1. Outcome

DFC can run one private paid PPV event end to end with trusted buy flow, entitlement validation, live playback, replay playback, settlement proof, and promoter payout visibility.

---

## 2. Engineering Checklist

### A. Secrets And Runtime Closure

Goal: remove environment ambiguity from streaming and entitlement paths.

Files and modules:

1. `functions/config/index.js`
2. `functions/streaming/mux.js`
3. `functions/entitlement.js`
4. `entitlements-service/.env.example`
5. deployment and Firebase secret setup docs

Tasks:

1. Verify `MUX_TOKEN_ID`, `MUX_TOKEN_SECRET`, `MUX_SIGNING_KEY_ID`, `MUX_SIGNING_PRIVATE_KEY`, and `MUX_WEBHOOK_SECRET` exist in the real runtime.
2. Verify canonical entitlement proxy variables are documented and available where used.
3. Verify local-vs-deployed support rules are documented so operators do not guess where real streaming is allowed.

Verification:

1. `npm --prefix entitlements-service run test:smoke`
2. entitlement runtime `GET /health` and `GET /ready` report the correct ready or missing state
3. one runtime secret presence check for the streaming lane
4. runbook updated with source of truth for each secret

### B. Canonical Settlement Authority

Goal: make the settlement dashboard authoritative instead of partially derived.

Files and modules:

1. `atlas_backend/ppv/router.py`
2. `atlas_backend/ppv/service.py`
3. `lib/shared/services/promoter_settlement_snapshot_service.dart`
4. `lib/features/monetization/screens/promoter_reconciliation_screen.dart`
5. `lib/features/monetization/screens/promoter_payout_dashboard_screen.dart`

Tasks:

1. Read Atlas settlement snapshots when available.
2. Compare backend settlement, purchase ledger, and revenue share records in one service.
3. Surface review state when any of those records disagree.
4. Make the payout dashboard open the canonical reconciliation board per event.

Verification:

1. settlement screen shows live authority source
2. mismatched totals force review state
3. matching totals show locked state
4. payout dashboard row navigation opens the canonical reconciliation board
5. targeted Flutter tests pass

### C. Entitlement And Playback Rehearsal

Goal: prove a paid user can buy, watch, and replay without access drift.

Files and modules:

1. `functions/ppv/access_state.js`
2. `functions/drm-license-exchange.js`
3. `entitlements-service/server.js`
4. `lib/features/ppv/screens/ppv_live_watch_screen.dart`
5. `lib/features/ppv/widgets/ppv_gate.dart`

Tasks:

1. verify buy completion writes canonical checkout session state
2. verify entitlement validation path resolves from canonical authority
3. verify replay access uses the same authority and does not drift from live access rules

Verification:

1. `npm --prefix entitlements-service run test:smoke`
2. `node --test .\\functions\\ppv\\access_state.test.js`
3. one manual watch and replay smoke on a seeded event

### D. Operator Rehearsal Pack

Goal: give one operator a repeatable event-day workflow.

Files and modules:

1. `lib/features/promoter/screens/promoter_control_room_screen.dart`
2. `docs/DFC_PPV_PUBLIC_READINESS_PLAN.md`
3. event-day runbook docs

Tasks:

1. define create event -> issue stream credentials -> watch -> stop -> replay -> reconcile sequence
2. define incident steps for missing stream, entitlement mismatch, and payout mismatch
3. define sign-off checklist before promoter-facing launch

Verification:

1. one internal rehearsal completed without database digging
2. one non-developer operator can follow the runbook

---

## 3. Release Gate For Priority 1

Priority 1 is complete only when all of these are true:

1. secrets and runtime rules are closed
2. settlement dashboard shows authoritative proof state
3. one full buy-to-replay rehearsal has passed
4. promoter payout and reconciliation state is readable in product surfaces
5. operator runbook exists and works in practice

If any one of these is false, DFC is not yet through Priority 1.
