#!/usr/bin/env bash
set -euo pipefail

# --- EDIT THESE BEFORE RUNNING ---
SERVICE_URL="${SERVICE_URL:-https://REPLACE_WITH_CLOUD_RUN_URL}"
PRIVATE_KEY="./tools/demo_private.pem"
PAYLOAD_FILE="./tools/payload.json"
TOKEN_FILE="./tools/token.txt"
ALERT_POLL_TIMEOUT=30
# ---------------------------------

echo "=== CHUCKYA Radar Demo Automation ==="
echo "Target: $SERVICE_URL"

# Create payload
cat > "$PAYLOAD_FILE" <<EOF
{
  "source": "device_app",
  "appInstanceId": "app_demo_1",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "type": "manual_scan",
  "riskScore": 95,
  "topSignals": ["manual_ping"],
  "notes": "demo ping from automation script"
}
EOF

echo "Signing payload..."
node tools/sign_payload.js "$PRIVATE_KEY" "$PAYLOAD_FILE" > "$TOKEN_FILE"
TOKEN=$(cat "$TOKEN_FILE")

echo "Posting signed payload to $SERVICE_URL/v1/radar/event ..."
RESP=$(jq -n \
  --argjson p "$(cat "$PAYLOAD_FILE")" \
  --arg t "$TOKEN" \
  '$p + {signatureJwt: $t}' | \
  curl -s -X POST "$SERVICE_URL/v1/radar/event" \
    -H "Content-Type: application/json" -d @-)

echo "Ingest response: $RESP"

ALERT_ID=$(echo "$RESP" | jq -r '.id // .alertId // empty')
if [ -z "$ALERT_ID" ]; then
  echo "ERROR: No alert id returned."
  exit 1
fi

echo "Alert created: $ALERT_ID"
echo "Polling for alert (timeout: ${ALERT_POLL_TIMEOUT}s)..."

END=$((SECONDS + ALERT_POLL_TIMEOUT))
FOUND=false
while [ $SECONDS -lt $END ]; do
  sleep 1
  LIST=$(curl -s "$SERVICE_URL/v1/radar/alerts")
  if echo "$LIST" | jq -e --arg ID "$ALERT_ID" '.[] | select(.alertId == $ID)' >/dev/null 2>&1; then
    echo "Alert visible in list."
    FOUND=true
    break
  fi
done

if [ "$FOUND" = "false" ]; then
  echo "Warning: alert not found in list within timeout. Continuing with export..."
fi

echo "Downloading evidence zip..."
curl -s -X POST "$SERVICE_URL/v1/radar/alerts/$ALERT_ID/export" -o "${ALERT_ID}_evidence.zip"
echo "Saved ${ALERT_ID}_evidence.zip"

echo ""
echo "=== Demo automation complete ==="
echo "Evidence pack: ${ALERT_ID}_evidence.zip"
echo "Present this zip to police for demo."
