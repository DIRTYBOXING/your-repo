# PPV + Mux + Stripe + Firebase + Social — Integration Checklist

## 0) Scope
- PPV entitlement gate works end-to-end
- Stripe webhook correctly grants/revokes entitlement
- Flutter gate blocks stream until access is granted
- Mux playback uses signed URLs (when configured)
- Social publisher triggers exist and log results
- Dev workflow reproducible from VS Code Insiders + Cloud Shell

---

## 1) Entitlement Gate (Flutter → Firestore)
### 1.1 Flutter listener
- [ ] `dfc_frontend/dfc_app/lib/ppv_entitlement_service.dart` checks:
  - [ ] `collection('entitlements')`
  - [ ] `where('userId' == uid)`
  - [ ] `where('scope' == 'event:<eventId>')`
  - [ ] `where('active' == true)`

### 1.2 Flutter gate screen
- [ ] `dfc_frontend/dfc_app/lib/ppv_stream_screen.dart` redirects to `/access-pass` when entitlement false
- [ ] Analytics funnel steps fire at:
  - [ ] `gate_view`
  - [ ] `gate_check_access`
  - [ ] `gate_access_granted` / `gate_access_denied`
  - [ ] `watch_start` / `watch_complete`

---

## 2) Stripe Webhook Authority (Stripe → Firebase)
### 2.1 Webhook verification + idempotency
- [ ] Stripe signature is verified via `stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret)`
- [ ] Idempotency marker stored (e.g. `stripe_webhook_events/<eventId>`) after successful handling
- [ ] Repeated webhook deliveries do not duplicate entitlements

### 2.2 Event handling coverage
- [ ] Grant on successful purchase:
  - [ ] `checkout.session.completed` (or `payment_intent.succeeded` depending on flow)
- [ ] Revoke on refund/dispute:
  - [ ] `charge.refunded`
  - [ ] `charge.dispute.created`

### 2.3 Write shape matches Flutter
- [ ] Backend writes to `entitlements` so Flutter query matches:
  - [ ] `entitlements` documents include `userId`
  - [ ] `scope` exactly `event:<eventId>`
  - [ ] `active: true` when granted
  - [ ] `active: false` when revoked

---

## 3) Canonical Access State (for Mux)
- [ ] `functions/ppv/access_state.js` resolves canonical access
- [ ] Mux callable `getMuxPlaybackUrl` denies access when canonical access is not granted

---

## 4) Mux Playback (Firebase → Mux)
### 4.1 Signed playback URLs
- [ ] `functions/streaming/mux.js` issues signed HLS/thumbnail URLs only when signing keys exist
- [ ] Playback URL returned by `getMuxPlaybackUrl` is only requested after Flutter entitlement is true

### 4.2 Stream lifecycle
- [ ] `muxWebhook` correctly transitions event/stream status
  - [ ] live → active
  - [ ] idle → ended/replay
  - [ ] asset ready → sets `replayPlaybackId`, `replayUrl`

---

## 5) Firebase Security Rules
- [ ] `entitlements` read allowed only for owner
- [ ] Backend (admin) can write entitlements
- [ ] No client write permission to entitlement docs

---

## 6) Social Media + Collaboration
- [ ] `functions/content/social_publisher.js` supports platform publishing adapters
- [ ] PPV lifecycle triggers call publisher:
  - [ ] PPV event announcement
  - [ ] PPV going live
  - [ ] replay available
  - [ ] major purchase milestones (optional)
- [ ] Results are logged to:
  - [ ] `social_publish_log`
  - [ ] `social_engine_posts`

---

## 7) Testing (minimum)
- [ ] Purchase in Stripe test mode
- [ ] Verify backend webhook granted entitlement
- [ ] Verify Flutter gate passes (no redirect)
- [ ] Verify Mux playback request succeeds and loads HLS
- [ ] Trigger refund/dispute test and verify entitlement revocation
- [ ] Verify social log entries created for event triggers

