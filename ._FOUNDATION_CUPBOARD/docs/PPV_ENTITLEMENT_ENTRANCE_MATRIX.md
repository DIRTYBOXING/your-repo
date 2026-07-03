# PPV Entitlement Entrance Matrix (Frontend vs Backend)

## Purpose
Prevent entitlement gate mismatches by documenting the required Firestore shapes.

## Flutter (entitlement listener)
File: `dfc_frontend/dfc_app/lib/ppv_entitlement_service.dart`

Flutter queries:
- collection: `entitlements`
- where `userId` == `uid`
- where `scope` == `event:<eventId>`
- where `active` == `true`

So Flutter expects a doc in:
- `entitlements/<docId>`
  - `userId: <uid>`
  - `scope: event:<eventId>`
  - `active: true`

## Backend (Mux canonical access)
File: `functions/ppv/access_state.js`

Mux callable `getMuxPlaybackUrl` uses canonical access resolution. This typically depends on:
- `ppv_checkout_sessions`
- `ppv_access`
- `ppv_purchases`

## Stripe (current behavior)
File: `functions/stripe_webhooks.js`

Current code writes:
- `users/<userId>/ppv_purchases/<eventId>`
  - `status: "active"`

This does **not** match Flutter’s `entitlements` query.

## Fix target
To make the system consistent with Flutter:
- Stripe webhook (and any refund/dispute paths) must write `entitlements` docs matching Flutter’s query shape.

---

## Required canonical output (what we will implement)
When payment/grant is successful:
- `entitlements/<purchaseId or any id>`
  - `userId`
  - `scope: event:<eventId>`
  - `active: true`

When payment is refunded/disputed:
- same doc(s) should be set:
  - `active: false`

Notes:
- The `docId` can be chosen, but must be consistent with how you plan to update on refund/dispute.
- Best docId choice: `purchaseId = <userId>_<eventId>`.

