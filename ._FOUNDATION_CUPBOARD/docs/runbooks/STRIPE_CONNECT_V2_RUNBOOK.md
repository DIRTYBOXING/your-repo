# Stripe Connect V2 Runbook

## Purpose

This repo now treats Stripe Connect V2 as the canonical promoter payout path.

Primary backend files:

- `functions/stripe/connect.js`
- `functions/stripe/payments.js` (legacy callable compatibility only)
- `functions/stripe/ppv.js`

Primary Firestore collection:

- `connected_accounts_v2/{userId}`

## Required Secrets

Set these in Firebase Functions before deploy:

- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_WEBHOOK_SECRET_CONNECT`
- `STRIPE_WEBHOOK_SECRET_SUBSCRIPTIONS`
- `PLATFORM_SUBSCRIPTION_PRICE_ID`
- `BASE_URL`

Recommended related secrets if PPV is enabled:

- `MUX_TOKEN_ID`
- `MUX_TOKEN_SECRET`
- `MUX_WEBHOOK_SECRET`

## Webhook Endpoints

Configure Stripe to hit these deployed endpoints:

- `handleStripeWebhook`
  Purpose: payment intents, checkout completion, subscription events on the legacy/general payment lane
- `stripeConnectWebhook`
  Purpose: Connect V2 thin events for account capability and requirements updates
- `stripeSubscriptionWebhook`
  Purpose: platform subscription lifecycle for connected accounts

Current deployed URLs:

- `https://stripeconnectwebhook-drxosqpmwq-ts.a.run.app`
- `https://stripesubscriptionwebhook-drxosqpmwq-ts.a.run.app`

Use separate webhook secrets for each endpoint.

Current live monthly partner subscription price:

- `price_1TLSeeBSoM6ez8FYlBH6N7F8`

## Deployment Steps

1. Rotate any leaked or previously shared Stripe test or live secrets.
2. Set Firebase Functions secrets or environment configuration.
3. Deploy Functions.
4. Register webhook endpoints in Stripe Dashboard or run `node scripts/provision_stripe_connect_v2_webhooks.mjs <connectUrl> <subscriptionUrl>`.
5. Replay or trigger test events from Stripe Dashboard.
6. Verify Firestore updates in `connected_accounts_v2` and PPV purchase collections.

## Verification Checklist

### Connect onboarding

- Call `createConnectedAccountV2` or the compatibility callable `createConnectAccount`.
- Confirm a `connected_accounts_v2/{userId}` document is created.
- Open onboarding URL from `createAccountLink`.
- Complete KYC flow in Stripe.
- Verify `stripeConnectWebhook` updates:
  - `status`
  - `onboardingComplete`
  - `cardPaymentsActive`
  - `requirementsStatus`

### Promoter status read

- Call `getConnectedAccountStatus`.
- Confirm returned values align with Firestore:
  - `exists`
  - `accountId`
  - `onboardingComplete`
  - `readyToProcessPayments`
  - `requirementsStatus`

### PPV checkout

- Create a PPV checkout session.
- Confirm metadata includes `promoterId` and `connectedAccountId` when the promoter is onboarded.
- Complete payment in Stripe test mode.
- Verify `ppv_checkout_sessions`, `ppv_purchases`, and `ppv_access` updates.

## Compatibility Notes

Legacy callable names remain exported for compatibility:

- `createConnectAccount`
- `getConnectAccountStatus`
- `createConnectLoginLink`

These should not be used for new UI work.

`createConnectLoginLink` only works for true legacy Express accounts in `connected_accounts`.
V2 full-dashboard accounts do not expose Express login links.

## Failure Modes

If onboarding completes in Stripe but DFC still shows not ready:

- Check `stripeConnectWebhook` delivery status in Stripe Dashboard.
- Confirm `STRIPE_WEBHOOK_SECRET_CONNECT` matches the deployed endpoint.
- Confirm the app is reading `connected_accounts_v2`, not `connected_accounts`.

If checkout succeeds but access is missing:

- Check `handleStripeWebhook` delivery status.
- Confirm the event reached the deployed project and region.
- Inspect `payment_intents`, `ppv_checkout_sessions`, `ppv_purchases`, and `ppv_access`.

## Cleanup Direction

New code should use:

- `createConnectedAccountV2`
- `createAccountLink`
- `getConnectedAccountStatus`
- `createConnectedCheckout`
- `stripeConnectWebhook`

Avoid adding new dependencies on legacy Express account flows.
