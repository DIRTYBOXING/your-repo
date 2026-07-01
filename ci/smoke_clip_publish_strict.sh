#!/usr/bin/env bash
# DFC Strict Smoke Test — validates clip→publish→attribution pipeline
# Usage: bash ci/smoke_clip_publish_strict.sh --timeout 60 --retries 3
set -euo pipefail

TIMEOUT=60
RETRIES=3

while [[ $# -gt 0 ]]; do
  case $1 in
    --timeout) TIMEOUT="$2"; shift 2;;
    --retries) RETRIES="$2"; shift 2;;
    *) shift ;;
  esac
done

ENTITLEMENT_URL=${ENTITLEMENT_URL:-http://localhost:3001}
PRICING_URL=${PRICING_URL:-http://localhost:3001}
PREDICTOR_URL=${PREDICTOR_URL:-http://localhost:8090}
N8N_WEBHOOK_URL=${N8N_WEBHOOK_URL:-http://localhost:5678/webhook/clip-created}

ARTIFACTS="./ci/smoke-artifacts"
mkdir -p "$ARTIFACTS"
PASS=0
FAIL=0
RESULTS=()

check() {
  local name="$1" url="$2" method="${3:-GET}" body="${4:-}"
  local http_code resp_file
  resp_file="$ARTIFACTS/$(echo "$name" | tr ' ' '_').json"

  local attempt=0 ok=false
  while [ $attempt -lt $RETRIES ]; do
    attempt=$((attempt+1))
    if [ "$method" = "POST" ]; then
      http_code=$(curl -s -o "$resp_file" -w "%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" -d "$body" --connect-timeout 5 --max-time 15 2>/dev/null || echo "000")
    else
      http_code=$(curl -s -o "$resp_file" -w "%{http_code}" "$url" \
        --connect-timeout 5 --max-time 15 2>/dev/null || echo "000")
    fi

    if [[ "$http_code" =~ ^2 ]]; then
      ok=true
      break
    fi
    sleep 2
  done

  if $ok; then
    echo "  PASS: $name (HTTP $http_code)"
    PASS=$((PASS+1))
    RESULTS+=("{\"name\":\"$name\",\"status\":\"pass\",\"http\":$http_code}")
  else
    echo "  FAIL: $name (HTTP $http_code after $RETRIES attempts)"
    FAIL=$((FAIL+1))
    RESULTS+=("{\"name\":\"$name\",\"status\":\"fail\",\"http\":$http_code}")
  fi
}

echo "============================="
echo "DFC Smoke Test Suite"
echo "============================="
echo ""

# 1. Entitlement: Issue Token
echo "[1/6] Entitlement — Issue Token"
check "issue_token" "$ENTITLEMENT_URL/issue" "POST" \
  '{"userId":"smoke-user-1","postId":"smoke-ppv-1","deviceId":"smoke-dev-1","ttl":300}'

# 2. Entitlement: Validate Token
echo "[2/6] Entitlement — Validate Token"
TOKEN=""
if [ -f "$ARTIFACTS/issue_token.json" ]; then
  TOKEN=$(cat "$ARTIFACTS/issue_token.json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null || echo "")
fi
if [ -n "$TOKEN" ]; then
  check "validate_token" "$ENTITLEMENT_URL/validate" "POST" \
    "{\"token\":\"$TOKEN\",\"deviceId\":\"smoke-dev-1\"}"
else
  echo "  SKIP: validate_token (no token from issue)"
  RESULTS+=("{\"name\":\"validate_token\",\"status\":\"skip\"}")
fi

# 3. Dynamic Pricing
echo "[3/6] Dynamic Pricing"
check "pricing_api" "$PRICING_URL/pricing" "POST" \
  '{"eventId":"smoke-ppv-1","userId":"smoke-user-1","basePrice":19.99,"signals":{"timeToEventHours":12,"viewsLastHour":100}}'

# 4. Predictor Health
echo "[4/6] Predictor Health"
check "predictor_health" "$PREDICTOR_URL/health" "GET"

# 5. Predictor Predict
echo "[5/6] Predictor Predict"
check "predictor_predict" "$PREDICTOR_URL/predict" "POST" \
  '{"fighter_a":{"name":"Fighter A","wins":15,"losses":2,"style":"striker"},"fighter_b":{"name":"Fighter B","wins":12,"losses":4,"style":"grappler"}}'

# 6. n8n Webhook (clip_created)
echo "[6/6] n8n Clip Webhook"
check "n8n_clip_webhook" "$N8N_WEBHOOK_URL" "POST" \
  '{"clipId":"smoke-clip-1","s3Url":"https://example.com/test.mp4","title":"Smoke Test Highlight","creatorId":"creator-1"}'

# Summary
echo ""
echo "============================="
echo "Results: $PASS passed, $FAIL failed"
echo "============================="

# Write structured result
RESULTS_JSON=$(printf '%s,' "${RESULTS[@]}" | sed 's/,$//')
cat > "$ARTIFACTS/smoke_results.json" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "passed": $PASS,
  "failed": $FAIL,
  "total": $((PASS + FAIL)),
  "checks": [$RESULTS_JSON]
}
EOF

echo "Artifacts saved to $ARTIFACTS/"

if [ $FAIL -gt 0 ]; then
  echo "SMOKE TEST FAILED"
  exit 1
fi

echo "SMOKE TEST PASSED"
exit 0
