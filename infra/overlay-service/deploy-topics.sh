#!/usr/bin/env bash
# =============================================================================
# DFC Overlay Service — GCP Pub/Sub Topic Provisioning
# =============================================================================
# Creates the Pub/Sub topics and subscriptions needed for the overlay pipeline:
#   dfc-wearable-telemetry  → Jetson edge publishes telemetry (bridge.js)
#   dfc-overlay-commands     → overlay-service publishes HUD commands downstream
#
# Also creates a push subscription on dfc-wearable-telemetry to route messages
# to the Cloud Run overlay-service ingest endpoint.
#
# Usage:  PROJECT_ID=dfc-prod REGION=australia-southeast1 ./deploy-topics.sh
# =============================================================================

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-dfc-prod}"
REGION="${REGION:-australia-southeast1}"

TOPIC_TELEMETRY="dfc-wearable-telemetry"
TOPIC_COMMANDS="dfc-overlay-commands"
SUB_TELEMETRY="dfc-wearable-telemetry-overlay-push"
OVERLAY_SERVICE_URL="${OVERLAY_SERVICE_URL:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log()  { echo -e "${GREEN}[TOPICS]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC}  $1"; exit 1; }

log "Provisioning Pub/Sub topics for DFC Overlay Service..."
log "  Project:  ${PROJECT_ID}"
log "  Region:   ${REGION}"
log ""

# ── Create topics ───────────────────────────────────────────────────────────
for topic in "${TOPIC_TELEMETRY}" "${TOPIC_COMMANDS}"; do
  if gcloud pubsub topics describe "${topic}" --project="${PROJECT_ID}" &>/dev/null; then
    log "Topic '${topic}' already exists — skipping"
    continue
  fi

  log "Creating topic: ${topic}"
  gcloud pubsub topics create "${topic}" \
    --project="${PROJECT_ID}" \
    --message-storage-policy-allowed-regions="${REGION}" \
    --labels=service=dfc-overlay,stack=edge,env=prod
done

# ── Create push subscription (if overlay service URL is known) ──────────────
if [[ -n "${OVERLAY_SERVICE_URL}" ]]; then
  if gcloud pubsub subscriptions describe "${SUB_TELEMETRY}" --project="${PROJECT_ID}" &>/dev/null; then
    log "Subscription '${SUB_TELEMETRY}' already exists — skipping"
  else
    log "Creating push subscription: ${SUB_TELEMETRY}"
    gcloud pubsub subscriptions create "${SUB_TELEMETRY}" \
      --topic="${TOPIC_TELEMETRY}" \
      --project="${PROJECT_ID}" \
      --push-endpoint="${OVERLAY_SERVICE_URL}/ingest" \
      --push-auth-service-account=overlay-service-invoker@${PROJECT_ID}.iam.gserviceaccount.com \
      --ack-deadline=60 \
      --message-retention-duration=7d \
      --enable-exactly-once-delivery \
      --labels=service=dfc-overlay,route=jetson-to-overlay
    log "Push subscription created: ${TOPIC_TELEMETRY} → ${OVERLAY_SERVICE_URL}/ingest"
  fi
else
  log "WARN: OVERLAY_SERVICE_URL not set — skipping push subscription. Run again after deploying Cloud Run."
  log "  Example: OVERLAY_SERVICE_URL=https://dfc-overlay-service-xxxx.a.run.app ./deploy-topics.sh"
fi

# ── Create downstream pipeline subscription ─────────────────────────────────
SUB_DOWNSTREAM="dfc-overlay-commands-dataflow-sub"
if ! gcloud pubsub subscriptions describe "${SUB_DOWNSTREAM}" --project="${PROJECT_ID}" &>/dev/null; then
  log "Creating downstream pipeline subscription: ${SUB_DOWNSTREAM}"
  gcloud pubsub subscriptions create "${SUB_DOWNSTREAM}" \
    --topic="${TOPIC_COMMANDS}" \
    --project="${PROJECT_ID}" \
    --ack-deadline=600 \
    --enable-exactly-once-delivery \
    --labels=role=downstream,consumer=analytics
  log "Downstream subscription created for analytics/Dataflow ingestion"
fi

log ""
log "========================================================="
log "  Pub/Sub provisioning complete!"
log ""
log "  Topics:"
log "    - ${TOPIC_TELEMETRY}"
log "    - ${TOPIC_COMMANDS}"
log ""
log "  Subscriptions:"
log "    - ${SUB_TELEMETRY} (push → overlay-service)"
log "    - ${SUB_DOWNSTREAM} (pull → analytics)"
log ""
log "  Next: Run cloud-run.yaml to deploy the overlay service"
log "========================================================="
