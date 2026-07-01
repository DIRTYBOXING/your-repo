#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════
# CHUCKYA — Publish Loop for Load Testing
# Pushes 1000 alerts at ~20/sec via the admin HTTP endpoint
# to simulate backend alert publishes.
#
# Usage:
#   chmod +x publish-loop.sh
#   SERVICE_URL=http://localhost:8080 ADMIN_TOKEN=admintoken ./publish-loop.sh
# ═══════════════════════════════════════════════════════
set -euo pipefail

SERVICE_URL="${SERVICE_URL:-http://localhost:8080}"
ADMIN_TOKEN="${ADMIN_TOKEN:-admintoken}"
REGION="${REGION:-brisbane}"
COUNT="${COUNT:-1000}"
DELAY="${DELAY:-0.05}"

echo "Publishing $COUNT alerts to $SERVICE_URL region=$REGION"

for i in $(seq 1 "$COUNT"); do
  payload=$(jq -n \
    --arg id "R-load-$i" \
    --argjson lat "-27.47$(( RANDOM % 100 ))" \
    --argjson lng "153.02$(( RANDOM % 100 ))" \
    --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg mode "code_black" \
    '{alertId:$id, lat:($lat|tonumber), lng:($lng|tonumber), ts:$ts, mode:$mode, riskScore:95, topSignals:["panic_button","sos"]}')

  curl -s -X POST "$SERVICE_URL/publish" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"region\":\"$REGION\",\"payload\":$payload}" >/dev/null

  if (( i % 100 == 0 )); then echo "  → $i / $COUNT published"; fi
  sleep "$DELAY"
done

echo "Done. $COUNT alerts published."
