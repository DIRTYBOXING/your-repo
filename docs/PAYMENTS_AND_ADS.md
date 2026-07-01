# Payments, Subscriptions, and Ads

This document outlines how DataFightCentral will implement payments and ads across platforms while keeping code modular and secure.

## Subscriptions

### Stripe (Web/Android/iOS)

- Use Stripe Checkout/PaymentLinks for web to minimize PCI scope.
- Mobile: use native SDKs (Stripe Android/iOS) or link-out to hosted checkout where possible.
- Server: verify events via webhooks (Cloud Functions) and update Firestore `subscriptions/{userId}`.

### Google Play Billing (Android)

- Integrate Play Billing client for managed subscriptions.
- Sync purchases via Cloud Functions Play Developer API.
- Mirror entitlements in Firestore; UI reads entitlements via `SubscriptionService`.

### Apple StoreKit (iOS)

- Integrate StoreKit for subscriptions.
- Use App Store Server Notifications to reconcile receipts in backend.

## Ads (AdMob/Google Mobile Ads)

- Initialize Google Mobile Ads SDK.
- Load banners/interstitials sparingly (respect user experience).
- Use placements in dashboard carousels and news panels; disable ads for paid tiers.

## Data Model

- `subscriptions/{userId}`: { planId, provider, status, startedAt, renewedAt, canceledAt }
- `entitlements/{userId}`: { features: [ 'ai_coach', 'advanced_analytics', 'ad_free' ] }

## Security & Privacy

- Never store raw card data.
- Enforce role/entitlement checks server-side.
- Offer clear opt-out and refund pathways per store policy.

## Roadmap

- Phase 1: Stripe hosted checkout (Web) + AdMob banners on free tier.
- Phase 2: Play Billing + StoreKit native subscriptions.
- Phase 3: Server-side reconciliation + grant logic + promotions.
