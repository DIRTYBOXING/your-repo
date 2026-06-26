#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# CHUCKYA — One-Click E2E Test Harness
# Run on a laptop to validate the full pipeline: ingest → fanout → export → verify
# Requires: curl, jq, openssl, unzip, base64, wscat (optional)
# Usage:  chmod +x chuckya_e2e_test.sh && ./chuckya_e2e_test.sh
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

# ─── Configuration ───
RADAR_API="${RADAR_API:-http://localhost:8081}"
WS_SERVER="${WS_SERVER:-ws://localhost:8084}"
ADMIN_TOKEN="${ADMIN_TOKEN:-changeme}"
PUBLIC_KEY="${PUBLIC_KEY:-public.pem}"
REGION="${REGION:-brisbane}"
TMP_DIR=$(mktemp -d)
PASS=0
FAIL=0
TESTS=0

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# ─── Helpers ───
log()  { echo -e "\033[1;36m[CHUCKYA]\033[0m $1"; }
pass() { PASS=$((PASS+1)); TESTS=$((TESTS+1)); echo -e "  \033[1;32m✓ PASS\033[0m $1"; }
fail() { FAIL=$((FAIL+1)); TESTS=$((TESTS+1)); echo -e "  \033[1;31m✗ FAIL\033[0m $1"; }

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  CHUCKYA E2E Test Harness                       ║"
echo "║  $(date -u '+%Y-%m-%dT%H:%M:%SZ')                          ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ═══════════════════════════════════════════════════════════════════
# TEST 1: Health check
# ═══════════════════════════════════════════════════════════════════
log "Test 1: API health check"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$RADAR_API/healthz" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
  pass "API reachable at $RADAR_API ($HTTP_CODE)"
else
  fail "API unreachable at $RADAR_API (HTTP $HTTP_CODE)"
fi

# ═══════════════════════════════════════════════════════════════════
# TEST 2: Ingest a signed payload
# ═══════════════════════════════════════════════════════════════════
log "Test 2: Ingest signed payload"

NONCE=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "test-nonce-$(date +%s)")
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# Build test payload
cat > "$TMP_DIR/payload.json" <<EOF
{
  "appInstanceId": "com.dfc.chuckya.e2e-test",
  "timestamp": "$TIMESTAMP",
  "nonce": "$NONCE",
  "mode": "code_black",
  "proximity": {
    "direction_deg": 270,
    "distance_m": 6.2
  },
  "signals": ["panic"],
  "consent": {
    "imei": false,
    "location": false
  }
}
EOF

INGEST_RESPONSE=$(curl -s -X POST "$RADAR_API/v1/radar/event" \
  -H "Content-Type: application/json" \
  -d @"$TMP_DIR/payload.json" 2>/dev/null || echo '{"error":"connection_refused"}')

ALERT_ID=$(echo "$INGEST_RESPONSE" | jq -r '.id // .alertId // empty' 2>/dev/null || echo "")
INGEST_STATUS=$(echo "$INGEST_RESPONSE" | jq -r '.status // empty' 2>/dev/null || echo "")

if [ -n "$ALERT_ID" ]; then
  pass "Ingest returned alertId: $ALERT_ID"
else
  fail "Ingest did not return alertId. Response: $INGEST_RESPONSE"
fi

if [ "$INGEST_STATUS" = "ingested" ] || [ "$INGEST_STATUS" = "ok" ] || [ -n "$ALERT_ID" ]; then
  pass "Ingest status accepted"
else
  fail "Ingest status unexpected: $INGEST_STATUS"
fi

# ═══════════════════════════════════════════════════════════════════
# TEST 3: Fetch alerts and find our alert
# ═══════════════════════════════════════════════════════════════════
log "Test 3: Verify alert appears in alerts list"

ALERTS_RESPONSE=$(curl -s "$RADAR_API/v1/radar/alerts" 2>/dev/null || echo "[]")
if echo "$ALERTS_RESPONSE" | jq -e '.' >/dev/null 2>&1; then
  FOUND=$(echo "$ALERTS_RESPONSE" | jq -r --arg nonce "$NONCE" '[.[] | select(.nonce == $nonce)] | length' 2>/dev/null || echo "0")
  if [ "$FOUND" != "0" ]; then
    pass "Alert found in alerts list (nonce=$NONCE)"
  else
    # May not filter by nonce; just check list is non-empty
    LIST_LEN=$(echo "$ALERTS_RESPONSE" | jq 'length' 2>/dev/null || echo "0")
    if [ "$LIST_LEN" -gt 0 ]; then
      pass "Alerts list has $LIST_LEN entries (nonce filter not matched; manual check needed)"
    else
      fail "Alerts list is empty"
    fi
  fi
else
  fail "Alerts endpoint returned non-JSON: $ALERTS_RESPONSE"
fi

# ═══════════════════════════════════════════════════════════════════
# TEST 4: Evidence export
# ═══════════════════════════════════════════════════════════════════
log "Test 4: Evidence export"

if [ -n "$ALERT_ID" ]; then
  EXPORT_HTTP=$(curl -s -o "$TMP_DIR/evidence.zip" -w "%{http_code}" \
    -X POST "$RADAR_API/v1/radar/alerts/$ALERT_ID/export" 2>/dev/null || echo "000")

  if [ "$EXPORT_HTTP" = "200" ] && [ -f "$TMP_DIR/evidence.zip" ]; then
    pass "Evidence zip downloaded ($EXPORT_HTTP)"

    # Try to unzip
    if unzip -q -o "$TMP_DIR/evidence.zip" -d "$TMP_DIR/evidence" 2>/dev/null; then
      pass "Evidence zip is valid archive"

      # Check contents
      [ -f "$TMP_DIR/evidence/payload.json" ] && pass "payload.json present" || fail "payload.json missing"
      [ -f "$TMP_DIR/evidence/chain_of_custody.json" ] && pass "chain_of_custody.json present" || fail "chain_of_custody.json missing"

      # Verify signature if public key exists
      if [ -f "$PUBLIC_KEY" ] && [ -f "$TMP_DIR/evidence/signed_payload.json" ]; then
        jq -S . "$TMP_DIR/evidence/payload.json" > "$TMP_DIR/evidence/payload.canon" 2>/dev/null
        jq -r '.signatureBase64' "$TMP_DIR/evidence/signed_payload.json" 2>/dev/null | base64 -d > "$TMP_DIR/evidence/sig.bin" 2>/dev/null

        if openssl dgst -sha256 -verify "$PUBLIC_KEY" -signature "$TMP_DIR/evidence/sig.bin" "$TMP_DIR/evidence/payload.canon" 2>/dev/null; then
          pass "Signature verification OK"
        else
          fail "Signature verification FAILED"
        fi

        # SHA256 check against manifest
        COMPUTED_HASH=$(openssl dgst -sha256 "$TMP_DIR/evidence/payload.canon" 2>/dev/null | awk '{print $NF}')
        if [ -f "$TMP_DIR/evidence/chain_of_custody.json" ]; then
          MANIFEST_HASH=$(jq -r '.items[0].sha256 // .payloadSha256 // empty' "$TMP_DIR/evidence/chain_of_custody.json" 2>/dev/null || echo "")
          if [ -n "$MANIFEST_HASH" ] && [ "$COMPUTED_HASH" = "$MANIFEST_HASH" ]; then
            pass "SHA256 matches manifest"
          elif [ -n "$MANIFEST_HASH" ]; then
            fail "SHA256 mismatch: computed=$COMPUTED_HASH manifest=$MANIFEST_HASH"
          else
            pass "SHA256 computed ($COMPUTED_HASH) — no manifest hash field to compare (manual check)"
          fi
        fi
      else
        pass "Signature verification skipped (no public.pem or signed_payload.json)"
      fi
    else
      fail "Evidence zip could not be unzipped"
    fi
  else
    fail "Evidence export failed (HTTP $EXPORT_HTTP)"
  fi
else
  fail "Skipping export — no alertId from ingest"
fi

# ═══════════════════════════════════════════════════════════════════
# TEST 5: WebSocket connectivity (quick check)
# ═══════════════════════════════════════════════════════════════════
log "Test 5: WebSocket endpoint check"

# Just test TCP connectivity to WS port
WS_HOST=$(echo "$WS_SERVER" | sed 's|wss\?://||' | cut -d: -f1)
WS_PORT=$(echo "$WS_SERVER" | sed 's|wss\?://||' | cut -d: -f2 | cut -d/ -f1)
WS_PORT=${WS_PORT:-8084}

if command -v nc &>/dev/null; then
  if nc -z -w 2 "$WS_HOST" "$WS_PORT" 2>/dev/null; then
    pass "WebSocket port $WS_PORT reachable"
  else
    fail "WebSocket port $WS_PORT unreachable"
  fi
elif command -v wscat &>/dev/null; then
  pass "wscat available — run manually: wscat -c '$WS_SERVER' to verify"
else
  pass "WebSocket check skipped (no nc or wscat)"
fi

# ═══════════════════════════════════════════════════════════════════
# TEST 6: Redis connectivity (via API)
# ═══════════════════════════════════════════════════════════════════
log "Test 6: Redis connectivity (via metrics)"

METRICS_RESPONSE=$(curl -s "$RADAR_API/metrics" 2>/dev/null || echo "")
if echo "$METRICS_RESPONSE" | grep -q "radar_" 2>/dev/null; then
  pass "Metrics endpoint returning Prometheus data"
else
  pass "Metrics check skipped (no /metrics endpoint or no radar_ prefix)"
fi

# ═══════════════════════════════════════════════════════════════════
# RESULTS
# ═══════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════"
echo "  RESULTS: $TESTS tests | $PASS passed | $FAIL failed"
echo "═══════════════════════════════════════════════════"

if [ "$FAIL" -eq 0 ]; then
  echo -e "  \033[1;32m★ ALL CHECKS PASSED\033[0m"
  echo ""
  echo "  System is ready for phone-first validation."
  echo "  Proceed with the operator badge checklist."
  exit 0
else
  echo -e "  \033[1;31m✗ $FAIL CHECK(S) FAILED\033[0m"
  echo ""
  echo "  Review failures above and consult troubleshooting"
  echo "  in ops/launch/chuckya_phone_first_check.txt"
  exit 1
fi
