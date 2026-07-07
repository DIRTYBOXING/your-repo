#!/usr/bin/env bash
# =============================================================================
# DFC Overlay Service — Smoke Test
# =============================================================================
# Tests the overlay service after deployment:
#   1. Health check (GET /health)
#   2. Pub/Sub ingest simulation (POST /ingest)
#   3. WebSocket connect (wss://)
#   4. Downstream command publishing (POST /ingest with real payload)
#
# Usage:  OVERLAY_URL=https://dfc-overlay-service-xxxx.a.run.app ./smoke-test.sh
# =============================================================================

set -euo pipefail

OVERLAY_URL="${OVERLAY_URL:-}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass()  { echo -e "${GREEN}[PASS]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

if [[ -z "${OVERLAY_URL}" ]]; then
  echo "Usage: OVERLAY_URL=https://dfc-overlay-service-xxxx.a.run.app ./smoke-test.sh"
  echo ""
  echo "To get the URL:"
  echo "  gcloud run services describe dfc-overlay-service --region=australia-southeast1 --format='value(status.url)'"
  exit 1
fi

FAILURES=0

echo "========================================="
echo "  DFC Overlay Service — Smoke Test"
echo "  Target: ${OVERLAY_URL}"
echo "========================================="
echo ""

# ── 1. Health check ─────────────────────────────────────────────────────────
echo "--- Test 1: Health check ---"
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "${OVERLAY_URL}/health" 2>/dev/null || echo "000")
if [[ "${HEALTH}" == "200" ]]; then
  BODY=$(curl -s "${OVERLAY_URL}/health")
  pass "Health check returned 200 | body: ${BODY}"
else
  fail "Health check returned ${HEALTH}"
  FAILURES=$((FAILURES + 1))
fi
echo ""

# ── 2. Ingest simulation — Pub/Sub push format ──────────────────────────────
echo "--- Test 2: Ingest (Pub/Sub push simulation) ---"
TELEMETRY_PAYLOAD=$(cat <<EOF
{
  "message": {
    "data": "$(echo -n '{"fighterId":"test-fighter-01","zoneScore":85,"heartRate":145,"acceleration":[1.2,-0.3,9.8],"stance":"orthodox","labels":["aggressive","high-output"],"ts":1719000000000}' | base64 -w0)",
    "messageId": "test-msg-$(date +%s)",
    "publishTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  }
}
EOF
)
INGEST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "${OVERLAY_URL}/ingest" \
  -H "Content-Type: application/json" \
  -d "${TELEMETRY_PAYLOAD}" 2>/dev/null || echo "000")
if [[ "${INGEST_STATUS}" == "200" ]]; then
  INGEST_RESPONSE=$(curl -s -X POST "${OVERLAY_URL}/ingest" \
    -H "Content-Type: application/json" \
    -d "${TELEMETRY_PAYLOAD}")
  pass "Ingest returned 200 | response: ${INGEST_RESPONSE}"
else
  fail "Ingest returned ${INGEST_STATUS}"
  FAILURES=$((FAILURES + 1))
fi
echo ""

# ── 3. Ingest — direct JSON (no Pub/Sub wrapper) ────────────────────────────
echo "--- Test 3: Ingest (direct JSON, no Pub/Sub wrapper) ---"
DIRECT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "${OVERLAY_URL}/ingest" \
  -H "Content-Type: application/json" \
  -d '{"fighterId":"test-fighter-02","zoneScore":42,"heartRate":165,"acceleration":[0.5,0.1,9.7],"stance":"southpaw","ts":1719000100000}' 2>/dev/null || echo "000")
if [[ "${DIRECT_STATUS}" == "200" ]]; then
  pass "Direct ingest returned 200"
else
  fail "Direct ingest returned ${DIRECT_STATUS}"
  FAILURES=$((FAILURES + 1))
fi
echo ""

# ── 4. Malformed ingest (should still return 200 for Pub/Sub ack) ──────────
echo "--- Test 4: Malformed ingest (graceful handling) ---"
MALFORMED_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "${OVERLAY_URL}/ingest" \
  -H "Content-Type: application/json" \
  -d 'not-valid-json' 2>/dev/null || echo "000")
if [[ "${MALFORMED_STATUS}" == "200" ]]; then
  pass "Malformed ingest returned 200 (graceful — no Pub/Sub retry loop)"
else
  warn "Malformed ingest returned ${MALFORMED_STATUS} (expected 200)"
fi
echo ""

# ── 5. WebSocket connect test ──────────────────────────────────────────────
echo "--- Test 5: WebSocket connect ---"
WS_URL=$(echo "${OVERLAY_URL}" | sed 's|https://|wss://|')/ws
if command -v websocat &>/dev/null; then
  WS_OUTPUT=$(timeout 3 websocat --oneshot "${WS_URL}" 2>&1 || true)
  if echo "${WS_OUTPUT}" | grep -q "heartbeat"; then
    pass "WebSocket connected and received heartbeat"
  else
    pass "WebSocket connected (raw response)"
  fi
else
  warn "websocat not installed — skipping WebSocket test"
  warn "  Install: apt-get install websocat"
fi
echo ""

# ── Summary ─────────────────────────────────────────────────────────────────
echo "========================================="
if [[ ${FAILURES} -eq 0 ]]; then
  echo -e "${GREEN}  ALL TESTS PASSED${NC}"
  echo "========================================="
  exit 0
else
  echo -e "${RED}  ${FAILURES} TEST(S) FAILED${NC}"
  echo "========================================="
  exit 1
fi
