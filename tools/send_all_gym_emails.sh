#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# send_all_gym_emails.sh — Bulk-send Shields & Gold Coins outreach
# to sponsored gyms listed in data/contacts/gyms.csv.
#
# IMPORTANT: Only gyms with sponsored=yes receive Shields emails.
# Non-sponsored gyms are skipped automatically.
#
# Usage:
#   SEND_ENDPOINT="https://your-endpoint.example/sendPromoterEmail" \
#     bash tools/send_all_gym_emails.sh [gym_shields_initial|gym_shields_followup|gym_shields_confirm]
#
# Requires: curl, jq
# ─────────────────────────────────────────────────────────────
set -euo pipefail

TEMPLATE="${1:-gym_shields_initial}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTACT_CSV="$REPO_ROOT/data/contacts/gyms.csv"
LOG_DIR="$REPO_ROOT/docs/legal/email_logs"

ENDPOINT="${SEND_ENDPOINT:-}"
if [ -z "$ENDPOINT" ]; then
  echo "ERROR: Set SEND_ENDPOINT env var before running."
  echo "  export SEND_ENDPOINT='https://...cloudfunctions.net/sendPromoterEmail'"
  exit 1
fi

if [ ! -f "$CONTACT_CSV" ]; then
  echo "ERROR: Missing $CONTACT_CSV"
  exit 1
fi

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl not found"; exit 1; }
command -v jq   >/dev/null 2>&1 || { echo "ERROR: jq not found"; exit 1; }

mkdir -p "$LOG_DIR"

SENT=0
FAILED=0
SKIPPED=0

echo "═══════════════════════════════════════════════════════"
echo " DFC Gym Outreach — template: $TEMPLATE"
echo " Endpoint: $ENDPOINT"
echo " Contact CSV: $CONTACT_CSV"
echo " NOTE: Only sponsored gyms receive Shields & extra ads"
echo "═══════════════════════════════════════════════════════"
echo ""

# Skip header row
tail -n +2 "$CONTACT_CSV" | while IFS=',' read -r gym_id gym_name contact_name contact_email city country sponsored notes; do
  # Only send Shields emails to sponsored gyms
  if [ "$sponsored" != "yes" ]; then
    echo "⏭  Skipped $gym_name — not a sponsored gym (sponsored=$sponsored)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [ -z "$contact_email" ] || [ "$contact_email" = "[REPLACE_WITH_REAL_EMAIL]" ]; then
    echo "⏭  Skipped $gym_name — no real email address set"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  echo "📧 Sending [$TEMPLATE] → $contact_email ($gym_name)..."

  PAYLOAD=$(jq -n \
    --arg to "$contact_email" \
    --arg template "$TEMPLATE" \
    --arg gymId "$gym_id" \
    --arg gymName "$gym_name" \
    --arg contact "$contact_name" \
    '{to: $to, template: $template, eventId: "gym-outreach", gym: {id: $gymId, name: $gymName, contact: $contact}}')

  HTTP_CODE=$(curl -s -o /tmp/dfc_gym_email_response.json -w "%{http_code}" \
    -X POST "$ENDPOINT" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo "   ✅ $HTTP_CODE OK"
    SENT=$((SENT + 1))
    STATUS="sent"
  else
    echo "   ❌ $HTTP_CODE FAILED — $(cat /tmp/dfc_gym_email_response.json 2>/dev/null)"
    FAILED=$((FAILED + 1))
    STATUS="failed"
  fi

  # Write per-gym JSON audit log
  jq -n \
    --arg ts "$TIMESTAMP" \
    --arg gymId "$gym_id" \
    --arg to "$contact_email" \
    --arg template "$TEMPLATE" \
    --arg status "$STATUS" \
    --arg httpCode "$HTTP_CODE" \
    '{timestamp: $ts, gymId: $gymId, to: $to, template: $template, status: $status, httpCode: $httpCode}' \
    >> "$LOG_DIR/gym_${gym_id}_send_log.json"

done

echo ""
echo "═══════════════════════════════════════════════════════"
echo " Done. Sent: $SENT | Failed: $FAILED | Skipped: $SKIPPED"
echo " Audit logs: $LOG_DIR/"
echo "═══════════════════════════════════════════════════════"
