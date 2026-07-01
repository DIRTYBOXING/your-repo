#!/usr/bin/env bash
# tools/smoke_all.sh — Quick smoke test for all DFC services
# Usage: API_BASE=https://staging-api.example.com ./tools/smoke_all.sh
set -euo pipefail

API_BASE="${API_BASE:-https://staging-api.example.com}"
TOKEN="${TEST_TOKEN:-}"
FAIL=0

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }

check_health() {
  local name="$1" url="$2"
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" || echo "000")
  if [ "$status" = "200" ]; then
    log "PASS: $name -> HTTP $status"
  else
    log "FAIL: $name -> HTTP $status"
    FAIL=1
  fi
}

# ---------- Health checks ----------
log "=== Health Checks ==="
check_health "API root"            "${API_BASE}/health"
check_health "Chukya radar"        "${API_BASE}/chukya/health"
check_health "Social feed"         "${API_BASE}/social/health"
check_health "PPV service"         "${API_BASE}/ppv/health"
check_health "Promotions"          "${API_BASE}/promotions/health"
check_health "Auto-feed orchestrator" "${API_BASE}/feed/health"
check_health "Marketplace"         "${API_BASE}/marketplace/health"

# ---------- Chukya inject (if token set) ----------
if [ -n "$TOKEN" ]; then
  log "=== Chukya Inject Tests ==="
  for f in test_fingerprint_high.json test_fingerprint_medium.json test_fingerprint_low.json; do
    if [ -f "$f" ]; then
      status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 \
        -X POST "${API_BASE}/chukya/test/inject_scan" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        -d @"$f")
      if [ "$status" = "200" ] || [ "$status" = "201" ]; then
        log "PASS: inject $f -> HTTP $status"
      else
        log "FAIL: inject $f -> HTTP $status"
        FAIL=1
      fi
    else
      log "SKIP: $f not found"
    fi
  done
else
  log "SKIP: Chukya inject tests (TEST_TOKEN not set)"
fi

# ---------- Summary ----------
log "=== Summary ==="
if [ "$FAIL" -eq 0 ]; then
  log "All smoke tests passed"
  exit 0
else
  log "One or more smoke tests failed"
  exit 1
fi
