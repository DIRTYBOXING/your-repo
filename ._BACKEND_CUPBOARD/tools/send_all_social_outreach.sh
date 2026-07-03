#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# send_all_social_outreach.sh — Bulk-send DMs via Messenger + Instagram
# for all PPV events and sponsored gyms.
#
# Sends to the social outreach serverless endpoint. If API tokens
# are not configured on the server, the endpoint returns DM text
# for manual paste (safe, policy-compliant fallback).
#
# Usage:
#   SOCIAL_ENDPOINT="https://your-endpoint.example/sendSocialOutreach" \
#     bash tools/send_all_social_outreach.sh [messenger|instagram] [promoter_initial|promoter_followup|gym_shields]
#
# Requires: curl, jq
# ─────────────────────────────────────────────────────────────
set -euo pipefail

CHANNEL="${1:-messenger}"
TEMPLATE="${2:-promoter_initial}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVENTS_DIR="$REPO_ROOT/data/events"
CONTACT_CSV="$REPO_ROOT/data/contacts/gyms.csv"
LOG_DIR="$REPO_ROOT/docs/legal/social_logs"
MANUAL_DIR="$REPO_ROOT/tools/promoter_messages"

ENDPOINT="${SOCIAL_ENDPOINT:-}"
if [ -z "$ENDPOINT" ]; then
  echo "ERROR: Set SOCIAL_ENDPOINT env var before running."
  echo "  export SOCIAL_ENDPOINT='https://...example/sendSocialOutreach'"
  exit 1
fi

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl not found"; exit 1; }
command -v jq   >/dev/null 2>&1 || { echo "ERROR: jq not found"; exit 1; }

mkdir -p "$LOG_DIR" "$MANUAL_DIR"

SENT=0
FALLBACK=0
FAILED=0
SKIPPED=0

echo "═══════════════════════════════════════════════════════"
echo " DFC Social Outreach — channel: $CHANNEL / template: $TEMPLATE"
echo " Endpoint: $ENDPOINT"
echo "═══════════════════════════════════════════════════════"
echo ""

# ── Promoter DMs (from event JSONs) ──
if [[ "$TEMPLATE" == promoter_* ]]; then
  for JSON_FILE in "$EVENTS_DIR"/*.json; do
    [ -f "$JSON_FILE" ] || continue

    EVENT_ID=$(jq -r '.eventId // empty' "$JSON_FILE" 2>/dev/null)
    PROMOTER=$(jq -r '.promotion // .promoter // "Promoter"' "$JSON_FILE" 2>/dev/null)
    TITLE=$(jq -r '.title // .eventTitle // "Untitled"' "$JSON_FILE" 2>/dev/null)
    RECIPIENT_ID=$(jq -r ".social_ids.${CHANNEL} // empty" "$JSON_FILE" 2>/dev/null)

    if [ -z "$EVENT_ID" ]; then
      echo "⏭  Skipped $(basename "$JSON_FILE") — no eventId"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi

    echo "📨 [$CHANNEL] Sending [$TEMPLATE] for $EVENT_ID ($TITLE)..."

    PAYLOAD=$(jq -n \
      --arg ch "$CHANNEL" \
      --arg tmpl "$TEMPLATE" \
      --arg rid "$RECIPIENT_ID" \
      --arg promoter "$PROMOTER" \
      --arg title "$TITLE" \
      '{channel: $ch, template: $tmpl, recipientId: (if $rid == "" then null else $rid end), vars: {PROMOTER_NAME: $promoter, EVENT_TITLE: $title}}')

    HTTP_CODE=$(curl -s -o /tmp/dfc_social_response.json -w "%{http_code}" \
      -X POST "$ENDPOINT" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD")

    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
      MODE=$(jq -r '.mode // "unknown"' /tmp/dfc_social_response.json 2>/dev/null)
      if [ "$MODE" = "api" ]; then
        echo "   ✅ Sent via API"
        SENT=$((SENT + 1))
        STATUS="sent"
      else
        # Fallback or manual — save text to file for manual paste
        TEXT=$(jq -r '.text // ""' /tmp/dfc_social_response.json 2>/dev/null)
        OUTFILE="$MANUAL_DIR/${CHANNEL}_${EVENT_ID}_dm.txt"
        echo "$TEXT" > "$OUTFILE"
        echo "   📋 Manual paste saved → $OUTFILE"
        FALLBACK=$((FALLBACK + 1))
        STATUS="fallback"
      fi
    else
      echo "   ❌ $HTTP_CODE FAILED — $(cat /tmp/dfc_social_response.json 2>/dev/null)"
      FAILED=$((FAILED + 1))
      STATUS="failed"
    fi

    # Write per-event social log
    jq -n \
      --arg ts "$TIMESTAMP" \
      --arg ch "$CHANNEL" \
      --arg eid "$EVENT_ID" \
      --arg tmpl "$TEMPLATE" \
      --arg status "$STATUS" \
      --arg httpCode "$HTTP_CODE" \
      '{timestamp: $ts, channel: $ch, eventId: $eid, template: $tmpl, status: $status, httpCode: $httpCode}' \
      >> "$LOG_DIR/${CHANNEL}_${EVENT_ID}_log.json"

  done
fi

# ── Gym Shields DMs (from CSV, sponsored only) ──
if [ "$TEMPLATE" = "gym_shields" ]; then
  if [ ! -f "$CONTACT_CSV" ]; then
    echo "ERROR: Missing $CONTACT_CSV"
    exit 1
  fi

  tail -n +2 "$CONTACT_CSV" | while IFS=',' read -r gym_id gym_name contact_name contact_email city country sponsored notes; do
    # Only Shields for sponsored gyms
    if [ "$sponsored" != "yes" ]; then
      echo "⏭  Skipped $gym_name — not sponsored"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi

    echo "📨 [$CHANNEL] Sending gym_shields DM for $gym_name..."

    PAYLOAD=$(jq -n \
      --arg ch "$CHANNEL" \
      --arg tmpl "gym_shields" \
      --arg name "$gym_name" \
      '{channel: $ch, template: $tmpl, recipientId: null, vars: {GYM_NAME: $name}}')

    HTTP_CODE=$(curl -s -o /tmp/dfc_social_response.json -w "%{http_code}" \
      -X POST "$ENDPOINT" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD")

    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
      MODE=$(jq -r '.mode // "unknown"' /tmp/dfc_social_response.json 2>/dev/null)
      if [ "$MODE" = "api" ]; then
        echo "   ✅ Sent via API"
        SENT=$((SENT + 1))
        STATUS="sent"
      else
        TEXT=$(jq -r '.text // ""' /tmp/dfc_social_response.json 2>/dev/null)
        OUTFILE="$MANUAL_DIR/${CHANNEL}_gym_${gym_id}_dm.txt"
        echo "$TEXT" > "$OUTFILE"
        echo "   📋 Manual paste saved → $OUTFILE"
        FALLBACK=$((FALLBACK + 1))
        STATUS="fallback"
      fi
    else
      echo "   ❌ $HTTP_CODE FAILED"
      FAILED=$((FAILED + 1))
      STATUS="failed"
    fi

    jq -n \
      --arg ts "$TIMESTAMP" \
      --arg ch "$CHANNEL" \
      --arg gid "$gym_id" \
      --arg tmpl "gym_shields" \
      --arg status "$STATUS" \
      --arg httpCode "$HTTP_CODE" \
      '{timestamp: $ts, channel: $ch, gymId: $gid, template: $tmpl, status: $status, httpCode: $httpCode}' \
      >> "$LOG_DIR/${CHANNEL}_gym_${gym_id}_log.json"

  done
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo " Results: Sent=$SENT  Fallback=$FALLBACK  Failed=$FAILED  Skipped=$SKIPPED"
echo " Logs:    $LOG_DIR/"
echo " Manual:  $MANUAL_DIR/"
echo "═══════════════════════════════════════════════════════"
