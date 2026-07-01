# PPV Unification Audit

## Outcome

DFC already has a strong PPV stack, but it currently spans multiple overlapping checkout, access, and entitlement paths. The canonical product path should be consolidated around the Firebase Cloud Function PPV checkout flow plus the Mux streaming layer.

## Canonical Path To Keep

### Checkout and purchase records

- Keep [functions/stripe/ppv.js](functions/stripe/ppv.js) as the canonical PPV checkout implementation.
- Reason: it already supports Stripe Checkout, promo codes, Stripe Connect routing, Firestore logging, credits, and dual-write access grants.

### Playback and live/replay delivery

- Keep [functions/streaming/mux.js](functions/streaming/mux.js) as the canonical live/replay playback layer.
- Reason: it already checks access, signs Mux playback URLs, handles stream status, and serves replay.

### App-side purchase callers

- Current Flutter callers already point primarily at `createPPVCheckoutSession` via:
  - [lib/features/ppv/services/ppv_payment_service.dart](lib/features/ppv/services/ppv_payment_service.dart)
  - [lib/shared/services/ppv_service.dart](lib/shared/services/ppv_service.dart)

## Duplicate or Divergent Paths To Stop Growing

### Live publisher checkout path

- [dfc-content-pipeline/live-publisher/src/index.js](dfc-content-pipeline/live-publisher/src/index.js)
- Problem: it duplicates Stripe checkout + webhook + access-grant responsibilities.
- Worse: it writes access to `users/{userId}/ppv_access/{eventId}` while the canonical gate/playback path reads top-level `ppv_access`.
- Action: keep this service for live update publishing, not as the long-term source of truth for PPV purchases.

### Separate entitlement service

- [entitlements-service/server.js](entitlements-service/server.js)
- Problem: it duplicates checkout/order/token responsibilities that already exist elsewhere.
- Action: either retire it, or explicitly make it the only DRM entitlement boundary and remove duplicate checkout logic from it.

### Separate web payment client path

- [web/src/ppv.js](web/src/ppv.js)
- [lib/services/dfc_payment_client.dart](lib/services/dfc_payment_client.dart)
- Problem: these assume additional bespoke purchase/entitlement endpoints that are not the same canonical PPV Cloud Function path.
- Action: do not extend these further until they are either wired to the canonical PPV stack or removed.

## Schema Mismatches Found

### Purchase field mismatch

- Canonical Cloud Function writes `ppv_purchases.ppvId`.
- Legacy helpers were still reading `ppvEventId`.
- This causes access checks to miss valid purchases.

### Collection mismatch

- Canonical Cloud Function writes top-level `ppv_access`.
- Live publisher webhook writes user subcollection `users/{userId}/ppv_access`.
- Mux playback checks top-level `ppv_access`.
- This means some purchase paths may not unlock playback in the canonical streaming path.

## Fix Completed In This Sweep

### PPV access service aligned

- Updated [lib/features/ppv/services/ppv_access_service.dart](lib/features/ppv/services/ppv_access_service.dart) to:
  - prefer canonical `ppvId`
  - respect `accessGranted`
  - respect expiration timestamps
  - keep legacy `ppvEventId` as fallback read support
  - write top-level `ppv_access` using stable composite IDs instead of random document IDs

## Remaining Recommended Actions

1. Pick one production PPV checkout path and deprecate the others in code comments and docs.
2. Decide whether the entitlement service survives as DRM-only or is removed.
3. Align all app and web callers to the same purchase/access contract.
4. Rotate any real secrets currently present in tracked env files.
5. Add one end-to-end private test: checkout -> webhook -> access -> Mux playback.
