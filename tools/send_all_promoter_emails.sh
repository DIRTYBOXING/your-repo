#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# send_all_promoter_emails.sh — Bulk-send promoter outreach for all PPV events
# Iterates through data/events/*.json and POSTs each to the serverless endpoint.
#
# Usage:
#   SEND_ENDPOINT="https://your-region-your-project.cloudfunctions.net/sendPromoterEmail" \
#     bash tools/send_all_promoter_emails.sh [initial|followup|approved]
#
# Requires: curl, jq
# ─────────────────────────────────────────────────────────────
set -euo pipefail

TEMPLATE="${1:-initial}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVENTS_DIR="$REPO_ROOT/data/events"
LOG_DIR="$REPO_ROOT/docs/legal/email_logs"

if [ -z "${SEND_ENDPOINT:-}" ]; then
  echo "ERROR: Set SEND_ENDPOINT env var before running."
  echo "  export SEND_ENDPOINT='https://...cloudfunctions.net/sendPromoterEmail'"
  exit 1
fi

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl not found"; exit 1; }
command -v jq   >/dev/null 2>&1 || { echo "ERROR: jq not found"; exit 1; }

mkdir -p "$LOG_DIR"

SENT=0
FAILED=0
SKIPPED=0

echo "═══════════════════════════════════════════════════════"
echo " DFC Promoter Email Blast — template: $TEMPLATE"
echo " Endpoint: $SEND_ENDPOINT"
echo " Events dir: $EVENTS_DIR"
echo "═══════════════════════════════════════════════════════"
echo ""

for JSON_FILE in "$EVENTS_DIR"/*.json; do
  [ -f "$JSON_FILE" ] || continue

  EVENT_ID=$(jq -r '.eventId // empty' "$JSON_FILE" 2>/dev/null)
  PROMOTER=$(jq -r '.promotion // .promoter // "Unknown"' "$JSON_FILE" 2>/dev/null)
  TITLE=$(jq -r '.title // .eventTitle // "Untitled"' "$JSON_FILE" 2>/dev/null)
  TO_EMAIL=$(jq -r '.promoterEmail // empty' "$JSON_FILE" 2>/dev/null)

  if [ -z "$EVENT_ID" ]; then
    echo "⏭  Skipped $(basename "$JSON_FILE") — no eventId"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [ -z "$TO_EMAIL" ]; then
    echo "⏭  Skipped $EVENT_ID — no promoterEmail field in JSON (add it to send)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  echo "📧 Sending [$TEMPLATE] → $TO_EMAIL ($EVENT_ID: $TITLE)..."

  HTTP_CODE=$(curl -s -o /tmp/dfc_email_response.json -w "%{http_code}" \
    -X POST "$SEND_ENDPOINT" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg to "$TO_EMAIL" \
      --arg eventId "$EVENT_ID" \
      --arg title "$TITLE" \
      --arg promoter "$PROMOTER" \
      --arg template "$TEMPLATE" \
      '{to: $to, eventId: $eventId, title: $title, promoter: $promoter, template: $template}'
    )")

  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo "   ✅ $HTTP_CODE OK"
    SENT=$((SENT + 1))
    STATUS="sent"
  else
    echo "   ❌ $HTTP_CODE FAILED — $(cat /tmp/dfc_email_response.json 2>/dev/null)"
    FAILED=$((FAILED + 1))
    STATUS="failed"
  fi

  # Write per-event JSON audit log
  jq -n \
    --arg ts "$TIMESTAMP" \
    --arg eventId "$EVENT_ID" \
    --arg to "$TO_EMAIL" \
    --arg template "$TEMPLATE" \
    --arg status "$STATUS" \
    --arg httpCode "$HTTP_CODE" \
    '{timestamp: $ts, eventId: $eventId, to: $to, template: $template, status: $status, httpCode: $httpCode}' \
    >> "$LOG_DIR/${EVENT_ID}_send_log.json"

done

echo ""
echo "═══════════════════════════════════════════════════════"
echo " Done. Sent: $SENT | Failed: $FAILED | Skipped: $SKIPPED"
echo " Audit logs: $LOG_DIR/"
echo "═══════════════════════════════════════════════════════"
