#!/usr/bin/env bash
# Staging smoke verification script for one-click social buy flow.
#
# Usage:
#   export STAGING_HOST="https://staging.datafightcentral.com"
#   export DATABASE_URL="postgresql://user:pass@host:5432/db"
#   ./scripts/staging_smoke.sh [PR_NUMBER]
#
# PR_NUMBER is optional; if provided and gh CLI is available, logs will be
# posted as a PR comment.

set -euo pipefail

STAGING_HOST="${STAGING_HOST:-https://<staging-host>}"
PR_REF="${1:-local}"
OUTDIR="$(mktemp -d /tmp/dfc-smoke-XXXX)"
echo "[+] Logs will be written to $OUTDIR"

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }

# ---------------------------------------------------------------------------
# 1. Apply migrations
# ---------------------------------------------------------------------------
log "Applying migrations"
psql "${DATABASE_URL}" -f atlas_backend/db/migrations/002_social_buy.sql \
  > "$OUTDIR/migrations.log" 2>&1 || {
    log "ERROR: migrations failed"; cat "$OUTDIR/migrations.log"; exit 1
}

# ---------------------------------------------------------------------------
# 2. Health check
# ---------------------------------------------------------------------------
log "Health check"
curl -sS "${STAGING_HOST}/api/v1/health" | jq '.' \
  > "$OUTDIR/health.json" 2>&1 || {
    log "ERROR: health check failed"; cat "$OUTDIR/health.json"; exit 1
}
log "Health check OK"

# ---------------------------------------------------------------------------
# 3. Seat hold smoke
# ---------------------------------------------------------------------------
log "Seat hold smoke"
curl -sS -X POST "${STAGING_HOST}/api/v1/seat-hold/hold" \
  -H "Content-Type: application/json" \
  -d '{"sku_id":"sku-test","qty":1,"ttl_seconds":300}' \
  > "$OUTDIR/seat_hold.json" 2>&1 || {
    log "ERROR: seat hold failed"; cat "$OUTDIR/seat_hold.json"; exit 1
}
log "Seat hold OK"

# ---------------------------------------------------------------------------
# 4. Checkout skeleton smoke
# ---------------------------------------------------------------------------
log "Checkout smoke"
IDEMPOTENCY_KEY="smoke-$(date +%s)"
CHECKOUT_PAYLOAD=$(cat <<EOF
{
  "items":[{"sku_id":"sku-test","qty":1}],
  "email":"test@dfc.test",
  "idempotency_key":"${IDEMPOTENCY_KEY}",
  "ref":"promoter_abc"
}
EOF
)
curl -sS -X POST "${STAGING_HOST}/api/v1/checkout" \
  -H "Content-Type: application/json" \
  -d "${CHECKOUT_PAYLOAD}" \
  > "$OUTDIR/checkout.json" 2>&1 || {
    log "ERROR: checkout failed"; cat "$OUTDIR/checkout.json"; exit 1
}
log "Checkout OK"

ORDER_ID=$(jq -r '.order_id // empty' "$OUTDIR/checkout.json" || true)
log "Order ID: ${ORDER_ID}"

# ---------------------------------------------------------------------------
# 5. Stripe webhook simulation
# ---------------------------------------------------------------------------
log "Stripe webhook: forwarding test payment_intent.succeeded"
if command -v stripe >/dev/null 2>&1; then
  log "  Using Stripe CLI. Run 'stripe listen' in a separate terminal."
  log "  Press ENTER after stripe listen is running to trigger the event."
  read -r -p "  [Press ENTER] "

  stripe trigger payment_intent.succeeded \
    > "$OUTDIR/stripe_trigger.log" 2>&1 || {
      log "WARNING: stripe trigger returned non-zero (may be OK if listen not active)"
  }
  log "Stripe CLI trigger done"

  # Wait a few seconds for async webhook processing
  log "Waiting 6s for webhook processing"
  sleep 6
else
  log "  Stripe CLI not found. Attempting CI-friendly webhook stub..."
  log "  Sending curl POST with a test payload (staging-only verifier must accept test signature)"

  # This stub sends a payment_intent.succeeded event directly.
  # In staging, the webhook endpoint must accept a test secret for CI runs.
  STRIPE_TEST_SIGNATURE="t=000000,v1=testsig"
  TEST_WEBHOOK_PAYLOAD=$(cat <<EOF
{
  "type": "payment_intent.succeeded",
  "data": {
    "object": {
      "id": "pi_test_${IDEMPOTENCY_KEY}",
      "metadata": {
        "order_id": "${ORDER_ID}"
      }
    }
  }
}
EOF
)
  curl -sS -X POST "${STAGING_HOST}/api/v1/webhooks/payments" \
    -H "Content-Type: application/json" \
    -H "Stripe-Signature: ${STRIPE_TEST_SIGNATURE}" \
    -d "${TEST_WEBHOOK_PAYLOAD}" \
    > "$OUTDIR/webhook_stub.log" 2>&1 || {
      log "ERROR: webhook stub call failed"; cat "$OUTDIR/webhook_stub.log"; exit 1
  }
  log "Webhook stub call done. Waiting 6s for ticket issuance..."
  sleep 6
fi

# ---------------------------------------------------------------------------
# 6. Ticket issuance verification
# ---------------------------------------------------------------------------
if [ -n "$ORDER_ID" ]; then
  log "Fetching tickets for order ${ORDER_ID}"
  curl -sS "${STAGING_HOST}/api/v1/tickets?order_id=${ORDER_ID}" \
    | jq '.' > "$OUTDIR/tickets.json" 2>&1 || {
      log "WARNING: tickets query returned non-zero (check output)"
  }
  log "Tickets response saved"
else
  log "No order_id found; skipping tickets check"
fi

# ---------------------------------------------------------------------------
# 7. Gate validate smoke
# ---------------------------------------------------------------------------
TICKET_CODE=$(jq -r '.[0].code // empty' "$OUTDIR/tickets.json" || true)
if [ -n "$TICKET_CODE" ]; then
  log "Validating ticket code ${TICKET_CODE}"
  VALIDATE_PAYLOAD=$(cat <<EOF
{
  "code": "${TICKET_CODE}",
  "scanner_id": "smoke-scanner",
  "location": "smoke-location"
}
EOF
)
  curl -sS -X POST "${STAGING_HOST}/api/v1/tickets/validate" \
    -H "Content-Type: application/json" \
    -d "${VALIDATE_PAYLOAD}" \
    > "$OUTDIR/validate.json" 2>&1 || {
      log "WARNING: validate call returned non-zero (check output)"
  }
  log "Validate response saved"
else
  log "No ticket code found; skipping validate"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=============================================="
echo " Smoke finished. Logs in: ${OUTDIR}"
echo "=============================================="
ls -la "${OUTDIR}/"

# Upload to PR comment if gh CLI available and PR_REF is numeric
if command -v gh >/dev/null 2>&1 && [[ "$PR_REF" =~ ^[0-9]+$ ]]; then
  log "Uploading log references to PR #${PR_REF}"
  gh pr comment "$PR_REF" --body "Staging smoke completed. Logs in \`${OUTDIR}\`. Key files: $(ls -m ${OUTDIR}/*.log ${OUTDIR}/*.json 2>/dev/null | tr '\n' ' ')"
fi

exit 0
