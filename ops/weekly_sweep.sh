#!/usr/bin/env bash
set -euo pipefail

EVENT="${1:-${EVENT:-champions-collide-2026}}"
GCS_BUCKET="${GCS_BUCKET:-${FIREBASE_STORAGE_BUCKET:-datafightcentral.firebasestorage.app}}"
EDGE_HOST="${EDGE_HOST:-edge-us.cdn.dfc.example.com}"
ENTITLEMENT_HEALTH="${ENTITLEMENT_HEALTH:-https://entitlements.staging.dfc.example.com/health}"
BASE_URL="${BASE_URL:-http://localhost:8080}"
WS_BASE="${WS_BASE:-ws://localhost:8799/ws/social}"
LIVE_BUCKET="${LIVE_BUCKET:-${BUCKET:-}}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
SWEEP_NAME="${SWEEP_NAME:-DFC Weekly Sweep}"
SKIP_POSTER_CHECK="${SKIP_POSTER_CHECK:-false}"

notify_slack() {
  local level="$1"
  local text="$2"

  if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
    return
  fi

  local emoji=":information_source:"
  if [[ "$level" == "success" ]]; then
    emoji=":white_check_mark:"
  elif [[ "$level" == "failure" ]]; then
    emoji=":rotating_light:"
  fi

  local payload
  payload=$(printf '{"text":"%s %s - %s"}' "$emoji" "$SWEEP_NAME" "$text")
  curl -sS -X POST -H "Content-type: application/json" --data "$payload" "$SLACK_WEBHOOK_URL" >/dev/null || true
}

on_exit() {
  local code=$?
  if [[ "$code" -eq 0 ]]; then
    notify_slack "success" "Weekly sweep passed for event ${EVENT}."
  else
    notify_slack "failure" "Weekly sweep failed for event ${EVENT}. Check pipeline logs."
  fi
}

trap on_exit EXIT

echo "1) Run PPV staging gate"
if command -v gh >/dev/null 2>&1; then
  gh workflow run ppv-staging-gate.yml -f EVENT_ID="$EVENT" || { echo "Gate failed"; exit 1; }
else
  echo "gh CLI not found; skipping trigger in local-only mode"
fi

echo "2) Check posters"
if [[ "$SKIP_POSTER_CHECK" == "true" ]]; then
  echo "Skipping poster check because SKIP_POSTER_CHECK=true"
else
  bash ./ops/check_posters.sh "$GCS_BUCKET" "$EVENT" "$EDGE_HOST" || { echo "Poster check failed"; exit 1; }
fi

echo "3) Entitlement health"
if command -v jq >/dev/null 2>&1; then
  curl -s "$ENTITLEMENT_HEALTH" | jq || { echo "Entitlement health failed"; exit 1; }
else
  echo "jq not found; printing raw entitlement health payload"
  curl -s "$ENTITLEMENT_HEALTH" || { echo "Entitlement health failed"; exit 1; }
  echo
fi

echo "4) Playwright smoke"
npx playwright test test/visual/player-poster.spec.ts --project=chromium || { echo "Playwright failed"; exit 1; }

echo "5) CDN edge hit ratio check - manual dashboard review required"
echo "6) Social messaging gate"
BASE_URL="$BASE_URL" WS_BASE="$WS_BASE" bash ./ops/social_messaging_smoke.sh || { echo "Social messaging smoke failed"; exit 1; }

echo "7) Live manifest check (optional, enabled when LIVE_BUCKET or BUCKET is set)"
if [[ -n "$LIVE_BUCKET" ]]; then
  bash ./ops/check_manifests.sh "$LIVE_BUCKET" "$EVENT" || { echo "Manifest check failed"; exit 1; }
else
  echo "Skipping manifest check: set LIVE_BUCKET (or BUCKET) to enable"
fi

echo "Weekly sweep PASSED"
