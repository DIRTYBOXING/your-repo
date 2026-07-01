#!/usr/bin/env bash

set -euo pipefail

BASE_URL=""
EVENT_ID=""
USER_ID=""
EMAIL=""
CHECKOUT_JSON=""

usage() {
  cat <<'EOF'
Usage:
  ./tools/smoke/e2e_checkout_playback.sh \
    --base-url https://staging.example.com \
    --event-id evt_test_001 \
    --user-id user_test_001 \
    --email test@example.com

What this script does:
  1. Creates a PPV checkout session against the live-publisher REST path.
  2. Prints the checkout URL for manual or Stripe CLI assisted completion.
  3. Checks PPV access status.
  4. Attempts replay URL retrieval if replay is already available.

Notes:
  - This is a staging smoke-test helper, not a replacement for real provider dashboards.
  - It assumes the staging environment exposes:
      POST /api/events/:id/ppv/checkout
      GET  /api/events/:id/ppv/access
      GET  /api/events/:id/replay
  - Real end-to-end payment completion still requires Stripe test credentials and webhook delivery.
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-url)
      BASE_URL="$2"
      shift 2
      ;;
    --event-id)
      EVENT_ID="$2"
      shift 2
      ;;
    --user-id)
      USER_ID="$2"
      shift 2
      ;;
    --email)
      EMAIL="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$BASE_URL" || -z "$EVENT_ID" || -z "$USER_ID" || -z "$EMAIL" ]]; then
  usage
  exit 1
fi

require_cmd curl
require_cmd jq

echo "==> Creating checkout session"
CHECKOUT_JSON="$(curl -sS -X POST \
  "$BASE_URL/api/events/$EVENT_ID/ppv/checkout" \
  -H "Content-Type: application/json" \
  -d "{\"userId\":\"$USER_ID\",\"email\":\"$EMAIL\"}")"

echo "$CHECKOUT_JSON" | jq .

CHECKOUT_URL="$(echo "$CHECKOUT_JSON" | jq -r '.checkoutUrl // empty')"
STATUS="$(echo "$CHECKOUT_JSON" | jq -r '.status // empty')"

if [[ "$STATUS" == "already_purchased" ]]; then
  echo "==> User already has access"
elif [[ -n "$CHECKOUT_URL" ]]; then
  echo "==> Checkout created"
  echo "Open this URL and complete payment with Stripe test credentials:"
  echo "$CHECKOUT_URL"
else
  echo "Checkout creation did not return a usable checkoutUrl" >&2
fi

echo
echo "==> Checking PPV access"
ACCESS_JSON="$(curl -sS "$BASE_URL/api/events/$EVENT_ID/ppv/access?userId=$USER_ID")"
echo "$ACCESS_JSON" | jq .

HAS_ACCESS="$(echo "$ACCESS_JSON" | jq -r '.hasAccess // false')"

if [[ "$HAS_ACCESS" != "true" ]]; then
  echo
  echo "Access not yet granted."
  echo "If payment was just completed, verify Stripe webhook delivery or use Stripe CLI forwarding before retrying."
  exit 2
fi

echo
echo "==> Attempting replay URL retrieval"
REPLAY_JSON="$(curl -sS "$BASE_URL/api/events/$EVENT_ID/replay?userId=$USER_ID")"
echo "$REPLAY_JSON" | jq .

REPLAY_URL="$(echo "$REPLAY_JSON" | jq -r '.replayUrl // empty')"

if [[ -n "$REPLAY_URL" ]]; then
  echo
  echo "==> Validating replay URL"
  HTTP_CODE="$(curl -sS -o /dev/null -w '%{http_code}' "$REPLAY_URL")"
  echo "Replay URL HTTP status: $HTTP_CODE"
  if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "302" ]]; then
    echo "Replay URL validation failed" >&2
    exit 3
  fi
fi

echo
echo "Smoke test completed."
echo "For true end-to-end validation, confirm this run used real Stripe test webhook delivery and the intended canonical staging runtime."
