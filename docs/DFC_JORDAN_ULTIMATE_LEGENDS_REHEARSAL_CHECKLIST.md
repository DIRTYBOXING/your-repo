# DFC Jordan Ultimate Legends Rehearsal Checklist

Status: split between what can run now and what is blocked until real Mux credentials exist.

Event lane:

- Event: Ultimate Legends Test Lane - Jordan Roesler
- Event ID: ultimate-legends-apr-2026
- Bout framing: Jordan Roesler vs Conor Wallace
- Venue framing: Melbourne Pavilion

## Lane A: Rehearsal Mode Available Now

Use this lane when Mux secrets are still missing.

### Preflight

1. Open promoter control room.
2. Confirm the Jordan lane is selected.
3. Confirm settlement proof panel loads gross, payable, buys, confidence, and payout status.
4. Confirm the event detail page shows commercial state, replay policy, and primary CTA.
5. Confirm the PPV watch route resolves without crashing.

### Rehearsal Run

1. Trigger stream credentials from the promoter control room.
2. Confirm the UI clearly labels the result as rehearsal mode.
3. Confirm a stub ingest URL and stream URL are written back to the PPV event.
4. Confirm audit trail text explains that this is a rehearsal credential issue, not a production Mux issue.
5. Open the PPV event page and confirm the surface looks commercially structured.
6. Open the watch route and confirm it loads as the protected playback surface.
7. Copy the operator proof brief from the control room.

### Evidence To Capture

1. Screenshot of control room foundation status.
2. Screenshot of settlement proof panel.
3. Screenshot of rehearsal-mode success message.
4. Screenshot of PPV event landing page.
5. Screenshot of PPV watch route.

### Exit Criteria

1. DFC visibly behaves like a controlled rehearsal lane.
2. No operator has to explain away a broken stream button.
3. Proof surfaces exist for promoter trust even without real Mux.

## Lane B: Real Mux Rehearsal Blocked Until Secrets Exist

Do not claim this lane is complete until all five Mux secrets are installed.

### Required Secrets

1. MUX_TOKEN_ID
2. MUX_TOKEN_SECRET
3. MUX_SIGNING_KEY_ID
4. MUX_SIGNING_PRIVATE_KEY
5. MUX_WEBHOOK_SECRET

### Go-Live Steps Once Secrets Exist

1. Set the five Mux secrets in Firebase Functions.
2. Redeploy the streaming functions.
3. Re-issue stream credentials from the control room.
4. Confirm the response contains real Mux ingest credentials.
5. Push RTMP from OBS or vMix.
6. Confirm stream status moves from idle to active.
7. Confirm paid access opens the live player.
8. End stream and wait for replay asset processing.
9. Confirm replay is available through the same protected watch flow.

### Real-Mode Evidence To Capture

1. Screenshot of returned Mux ingest URL and stream key.
2. Screenshot of live status in the operator surface.
3. Screenshot of buyer watch experience.
4. Screenshot of replay-ready state.
5. Screenshot of settlement proof after transactions settle.

### Real-Mode Exit Criteria

1. Stream can be armed, ingested, watched, stopped, and replayed.
2. The watch path is entitlement-protected.
3. The promoter proof pack shows both stream proof and money proof.

## Current Truth

Lane A is available now.

Lane B starts the moment the DFC-owned Mux secrets are supplied.
