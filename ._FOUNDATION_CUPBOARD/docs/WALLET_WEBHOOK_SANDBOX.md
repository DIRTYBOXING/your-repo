# Wallet Webhook Sandbox Commands

This runbook gives staging-safe Stripe CLI and PayPal sandbox commands for wallet and PPV webhook verification.

## Prerequisites

- API running at `http://localhost:3000`
- Environment variables set:
  - `REQUIRE_AUTH_FOR_PPV=true`
  - `STRIPE_SECRET_KEY`
  - `STRIPE_WEBHOOK_SECRET`
  - `PAYPAL_CLIENT_ID`
  - `PAYPAL_CLIENT_SECRET`

## Stripe: Forward events locally

1. Start listener and copy the generated webhook secret if needed:

```bash
stripe listen --forward-to http://localhost:3000/api/webhook/payment
```

2. Trigger a checkout completion event:

```bash
stripe trigger checkout.session.completed \
  --add checkout_session:metadata[eventId]=999 \
  --add checkout_session:metadata[userId]=test_user \
  --add checkout_session:metadata[sku]=PPV-999 \
  --add checkout_session:amount_total=4999 \
  --add checkout_session:payment_status=paid
```

3. Validate entitlement:

```bash
curl -s http://localhost:3000/api/entitlements/test_user | jq
```

## PayPal: Sandbox webhook simulation

For local or staging simulation without external callback signing, set:

```bash
export PAYPAL_WEBHOOK_VERIFY_BYPASS=true
```

Then post the sample payload:

```bash
curl -s -X POST http://localhost:3000/api/paypal/webhook \
  -H "Content-Type: application/json" \
  --data @server/test/fixtures/paypal-webhook-capture-completed.json | jq
```

When running strict verification mode (`PAYPAL_REQUIRE_WEBHOOK_VERIFY=true`), use real PayPal sandbox webhook deliveries and keep `PAYPAL_WEBHOOK_VERIFY_BYPASS=false`.
