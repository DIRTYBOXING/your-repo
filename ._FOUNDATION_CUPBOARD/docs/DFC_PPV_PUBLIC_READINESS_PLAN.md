# DFC PPV Public Readiness Plan

Status: canonical catch-up plan for taking DFC from technically wired to operationally public-ready.

Purpose: remove confusion by combining the verified blockers, the exact module ownership, the execution order, and the VS Code work list into one document.

Use this document as the single source for PPV readiness work.

---

## 1. Verified Now

These items were verified against the current repo and deployment state.

### 1.1 Verified working paths

- Mux live stream creation exists in `functions/streaming/mux.js`
- signed playback URL generation exists in `functions/streaming/mux.js`
- replay lookup exists in `functions/streaming/mux.js`
- Mux webhook handling exists in `functions/streaming/mux.js`
- PPV checkout session and payment intent creation exist in `functions/stripe/ppv.js`
- reconciliation and event summary logic exist in `functions/stripe/reconciliation.js`
- promoter payout dashboard row routing into the reconciliation board now has a dedicated widget test
- targeted Flutter analyze and widget validation now pass for the payout and reconciliation surfaces
- promoter control room can issue stream credentials in `lib/features/promoter/screens/promoter_control_room_screen.dart`
- entitlements service now exposes `GET /health` and `GET /ready` with explicit runtime capability state
- entitlement proxy smoke validation passes through the new readiness endpoints
- key Flutter streaming files analyze cleanly

### 1.2 Verified blockers

- local `functions/.env` is missing:
  - `MUX_TOKEN_ID`
  - `MUX_TOKEN_SECRET`
  - `MUX_SIGNING_KEY_ID`
  - `MUX_SIGNING_PRIVATE_KEY`
  - `MUX_WEBHOOK_SECRET`
- deployed legacy runtime config is empty via `firebase functions:config:get --project datafightcentral`
- deployed Firebase secrets are missing:
  - `MUX_TOKEN_ID`
  - `MUX_TOKEN_SECRET`
  - `MUX_SIGNING_KEY_ID`
  - `MUX_SIGNING_PRIVATE_KEY`
  - `MUX_WEBHOOK_SECRET`

### 1.3 Verified product gaps

- the first canonical settlement visibility slice now exists, but refunds, disputes, reserve handling, and payout lifecycle closure are not finished end to end
- go-live and replay publish gates are not fully closed
- multi-cam is still not enabled in the incident-response baseline

This means DFC is pilot-ready, but not yet hardened for a public PPV event.

---

## 1.4 Verified Must-Do List

If you ignore everything else, do these in order.

### Must do now

1. create these five Firebase secrets:
   - `MUX_TOKEN_ID`
   - `MUX_TOKEN_SECRET`
   - `MUX_SIGNING_KEY_ID`
   - `MUX_SIGNING_PRIVATE_KEY`
   - `MUX_WEBHOOK_SECRET`
2. decide whether local real-Mux support is required or whether deployed functions are the only supported path
3. verify the streaming functions can actually read those secrets at runtime

### Must do next

4. run one real stream credential test from the promoter control room
5. standardize the PPV landing page and watch surfaces so the product looks commercial, not internal
6. build one canonical settlement dashboard

### Must do before any public event

7. run the full private rehearsal from event creation through replay and reconciliation
8. confirm one operator can run the event without guessing or database digging
9. confirm promoter-facing trust surfaces are clear enough to support repeat bookings

### Current truth in one sentence

DFC can prepare and prove core lanes locally, but it is not public-ready until secrets, runtime closure, settlement closure, and one full rehearsal are done.

---

## 2. Public-Ready Definition

DFC is public-ready only when all of the following are true:

1. Mux secrets exist locally where needed and in deployed Firebase secrets.
2. One operator can arm, monitor, stop, and verify a stream without guessing.
3. Paid access, live playback, replay playback, and reconciliation all pass one full rehearsal.
4. One canonical settlement screen exists for promoter, fighter, gym, creator, reserve, dispute, and payout state.

If any one of these is false, DFC is not public-ready.

---

## 3. Segment A — Environment And Config

Goal: make the runtime actually capable of real Mux-backed live streaming.

### Modules

- `functions/.env`
- `functions/config/index.js`
- Firebase Secret Manager
- deployment scripts and runbooks

### Tasks

1. create the missing Firebase secrets:
   - `MUX_TOKEN_ID`
   - `MUX_TOKEN_SECRET`
   - `MUX_SIGNING_KEY_ID`
   - `MUX_SIGNING_PRIVATE_KEY`
   - `MUX_WEBHOOK_SECRET`
2. add the same variables locally when local function execution needs real Mux access
3. verify which functions need explicit secret binding if migrated from raw `process.env` use
4. verify entitlements runtime state through `GET /health` and `GET /ready`
5. document the source of truth for Mux secrets so there is no split-brain between local and deployed environments

### Exit criteria

- all five Mux secrets exist in Firebase
- all five Mux variables are available to the streaming functions at runtime
- entitlement runtime reports `ready=true` when the canonical proxy inputs are present
- local test instructions clearly state whether local Mux is supported or deployment-only

### Fast commands

```powershell
firebase functions:secrets:set MUX_TOKEN_ID --project datafightcentral
firebase functions:secrets:set MUX_TOKEN_SECRET --project datafightcentral
firebase functions:secrets:set MUX_SIGNING_KEY_ID --project datafightcentral
firebase functions:secrets:set MUX_SIGNING_PRIVATE_KEY --project datafightcentral
firebase functions:secrets:set MUX_WEBHOOK_SECRET --project datafightcentral
npm --prefix entitlements-service run test:smoke
node scripts/ppv_runtime_readiness_check.mjs
```

### VS Code verification lane

- `PPV: Start Entitlement Proxy` starts the local proxy on the default `http://127.0.0.1:8080` lane.
- `PPV: Runtime Readiness Check` validates local env completeness, rejects accidental production fallback for the Functions base URL, and reads `/ready` from the entitlement proxy.
- `PPV: Smoke Mux Auth` is the default safe Mux runtime validation step. It calls the read-only `testMuxAuth` callable against the deployed Functions base URL and does not create streams, assets, or Firestore fixtures.
- `PPV: Smoke Mux Credential Delivery` remains operator-only and destructive. It seeds Firestore state and provisions a real Mux live stream for end-to-end credential rehearsal.
- `PPV: Priority 1 Verification Lane` runs the readiness check first, then the entitlement smoke lane and the safe Mux auth check in sequence.

---

## 4. Segment B — Streaming Pipeline

Goal: prove that DFC can arm, ingest, play, stop, and replay a PPV stream.

### Modules

- `functions/streaming/mux.js`
- `functions/streaming/live.js`
- `lib/shared/services/mux_streaming_service.dart`
- `lib/features/promoter/screens/promoter_control_room_screen.dart`
- `lib/features/ppv/screens/ppv_live_watch_screen.dart`
- `lib/features/ppv/widgets/ppv_gate.dart`
- `lib/features/ppv/widgets/dfc_video_player.dart`

### Tasks

1. create a PPV event and issue stream credentials from the promoter control room
2. confirm Mux returns stream key, playback ID, and ingest URL
3. send RTMP from OBS or vMix
4. confirm stream status transitions from idle to active
5. confirm a paid viewer receives signed playback and the watch screen opens correctly
6. end stream and verify replay asset becomes available
7. confirm replay access respects the same entitlement rules

### Exit criteria

- one real stream lifecycle completes end to end
- the operator sees stream status and replay status without manual database inspection
- replay is not publicly exposed without entitlement

---

## 5. Segment C — PPV Product Surfaces

Goal: make the PPV product look and behave like a real commercial product instead of an internal toolchain.

### Modules

- `lib/features/ppv/screens/ppv_event_detail_screen.dart`
- `lib/features/ppv/screens/ppv_event_detail_simple_screen.dart`
- `lib/features/ppv/screens/ppv_live_watch_screen.dart`
- replay-related watch surfaces

### Tasks

1. standardize the landing page modules:
   - poster
   - fighters or card summary
   - date and time
   - countdown
   - trailer or approved clip
   - price and what is included
   - replay policy
   - buy now CTA
2. standardize the watch screen so it feels deliberate and operator-safe
3. standardize the replay surface so replay is a first-class state, not an afterthought
4. add or tighten round markers and event timeline metadata where feasible

### Exit criteria

- every PPV event page follows the same commercial structure
- users can understand live, buy, and replay states without guesswork

---

## 6. Segment D — Launch Pack Generator

Goal: generate the event promotion payload from one canonical event record.

### Modules

- `lib/features/promoter/screens/promoter_control_room_screen.dart`
- `lib/features/promoter/screens/poster_generator_screen.dart`
- `lib/features/promoter/screens/event_poster_command_screen.dart`

### Tasks

1. generate posters in required sizes
2. generate fight cards in required sizes
3. generate countdown assets
4. generate captions and hashtags
5. generate referral links
6. export the event pack as one structured bundle

### Exit criteria

- one operator can create a full launch pack without manually jumping between disconnected screens

---

## 7. Segment E — Activation Engine

Goal: turn fighters, gyms, creators, and promoters into a coordinated distribution network.

### Modules

- promoter portal surfaces
- war room surfaces
- event sharing surfaces
- outbound email and SMS services

### Tasks

1. create audience-specific pack delivery states
2. generate recipient-specific messages
3. send or export launch packs for:
   - fighters
   - gyms
   - creators
   - promoters
4. track sent, pending, and failed states

### Exit criteria

- one event can move from launch-pack generation into distribution with visible status

---

## 8. Segment F — Settlement Visibility

Goal: make money in and money out legible enough to support promoter trust.

### Modules

- `functions/stripe/reconciliation.js`
- `functions/stripe/connect.js`
- `lib/features/monetization/screens/promoter_payout_dashboard_screen.dart`
- `lib/features/monetization/screens/promoter_reconciliation_screen.dart`

### Tasks

1. keep the shipped payout dashboard and reconciliation board as the single promoter path for settlement proof
2. finish refunds, disputes, reserve handling, payable amount, and payout state in the same canonical ledger
3. connect promoter, fighter, gym, and creator split visibility to the same ledger
4. surface reconciliation results from the backend clearly in the UI
5. keep routing and narrow-screen behavior covered so the operator surface does not regress silently

### Exit criteria

- one event has one authoritative settlement view
- promoter trust no longer depends on raw Firestore inspection or ad hoc exports

---

## 9. Segment G — Private Rehearsal

Goal: prove the whole system works before public launch.

### Rehearsal flow

1. create event
2. create PPV record
3. create Mux stream credentials
4. send RTMP from OBS or vMix
5. verify live status
6. complete a test PPV purchase
7. verify gate unlock
8. watch live stream
9. stop stream
10. verify replay processing
11. watch replay
12. run reconciliation
13. verify settlement visibility

### Exit criteria

- all thirteen steps pass without hand-waving
- one operator can run the event without relying on engineering intervention for normal flow

---

## 10. VS Code Catch-Up List

Use this as the immediate execution order.

### Tonight Main Event Stack

This is the end-of-night list. No side quests.

1. confirm where the real Mux credentials will come from
   - if you already have them, create the five Firebase secrets tonight
   - if you do not have them yet, write down the exact values you still need to obtain and who owns them
2. verify the streaming functions will read secrets from the deployed environment, not just a local `.env`
3. verify the entitlement proxy with the dedicated smoke lane
4. open and tighten the streaming-critical files only:
   - `functions/streaming/mux.js`
   - `functions/config/index.js`
   - `lib/shared/services/mux_streaming_service.dart`
   - `lib/features/promoter/screens/promoter_control_room_screen.dart`
5. keep the monetization-critical files green:
   - `lib/features/monetization/screens/promoter_payout_dashboard_screen.dart`
   - `lib/features/monetization/screens/promoter_reconciliation_screen.dart`
   - `test/promoter_payout_dashboard_screen_test.dart`
6. prepare one test event lane
   - one event
   - one PPV record
   - one operator path
   - one expected replay path
7. choose the next product build, and only one:
   - PPV landing page standardization
   - settlement ledger closure
8. do not branch into activation packs, multi-cam, creator extras, or growth loops tonight
9. end the night with one written status:
   - what is now verified
   - what is still blocked
   - what the first move is tomorrow

### Tonight Definition Of A Good Night

Tonight is a win if you finish with:

- the Mux blocker made explicit and owned
- the next implementation target chosen
- no confusion about what happens tomorrow

### Now

- create the five missing Firebase Mux secrets
- decide whether local real-Mux support is required or deployment-only
- verify secret access inside streaming functions
- run the entitlement proxy smoke lane and confirm `GET /ready` reflects runtime truth

### Next

- run one full stream credential test from the promoter control room
- standardize the PPV event detail and landing page
- close the remaining canonical settlement ledger gaps

### After that

- build launch-pack generation
- build activation tracking and delivery
- run the full private rehearsal

---

## 11. Brutal Truth

The architecture is already real.

The blocker is not whether DFC can be a PPV platform.

The blocker is whether operations, secrets, and trust surfaces are finished well enough that a real promoter can rely on it without you improvising on event day.

That is what this plan is for.
