#!/usr/bin/env bash
set -euo pipefail

PROJECT="${1:-chromium}"
SMOKE_SPEC="test/visual/wallet_ai_shakura_smoke.spec.ts"

PLAYWRIGHT_STATIC_WEB_BASE="${PLAYWRIGHT_STATIC_WEB_BASE:-http://127.0.0.1:8088}"
PLAYWRIGHT_BASE_URL="${PLAYWRIGHT_BASE_URL:-http://127.0.0.1:8088}"
PLAYWRIGHT_API_BASE="${PLAYWRIGHT_API_BASE:-http://127.0.0.1:3000}"
PLAYWRIGHT_POSTER_BASE="${PLAYWRIGHT_POSTER_BASE:-http://127.0.0.1:3000}"
PLAYWRIGHT_EXPECT_AUTH="${PLAYWRIGHT_EXPECT_AUTH:-1}"
PLAYWRIGHT_STRICT_SMOKE="${PLAYWRIGHT_STRICT_SMOKE:-1}"

export PLAYWRIGHT_STATIC_WEB_BASE
export PLAYWRIGHT_BASE_URL
export PLAYWRIGHT_API_BASE
export PLAYWRIGHT_POSTER_BASE
export PLAYWRIGHT_EXPECT_AUTH
export PLAYWRIGHT_STRICT_SMOKE

cleanup() {
  if [[ -f .api-server.pid ]]; then
    kill "$(cat .api-server.pid)" >/dev/null 2>&1 || true
    rm -f .api-server.pid
  fi
  if [[ -f .static-server.pid ]]; then
    kill "$(cat .static-server.pid)" >/dev/null 2>&1 || true
    rm -f .static-server.pid
  fi
}
trap cleanup EXIT

node server/index.js > /tmp/dfc-api.log 2>&1 & echo $! > .api-server.pid
python3 -m http.server 8088 --directory web > /tmp/dfc-static.log 2>&1 & echo $! > .static-server.pid

for _ in $(seq 1 45); do
  if curl -fsS "${PLAYWRIGHT_API_BASE}/health" >/dev/null; then
    break
  fi
  sleep 1
done

for _ in $(seq 1 45); do
  if curl -fsS "${PLAYWRIGHT_STATIC_WEB_BASE}/promoters.html" >/dev/null; then
    break
  fi
  sleep 1
done

curl -fsS "${PLAYWRIGHT_API_BASE}/health" >/dev/null
curl -fsS "${PLAYWRIGHT_STATIC_WEB_BASE}/promoters.html" >/dev/null

npx playwright test "$SMOKE_SPEC" --project="$PROJECT" --grep "@smoke"
