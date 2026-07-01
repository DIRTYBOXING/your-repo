#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# deploy_scheduler.sh — Create/update GCP Cloud Scheduler jobs for DFC PPV
#
# Usage:
#   ./infra/scheduler/deploy_scheduler.sh [PROJECT_ID] [REGION]
#
# Env vars (can also be set inline):
#   GCP_PROJECT_ID  — GCP project ID (required)
#   GCP_REGION      — Cloud Functions region (default: us-central1)
#   SERVICE_ACCOUNT — SA for invoking Cloud Functions (default: auto-detect)
#
# Prerequisites:
#   gcloud CLI installed and authenticated
#   Firebase Functions deployed
#   Cloud Scheduler API enabled: gcloud services enable cloudscheduler.googleapis.com
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ID="${1:-${GCP_PROJECT_ID:-}}"
REGION="${2:-${GCP_REGION:-us-central1}}"

if [[ -z "$PROJECT_ID" ]]; then
  echo "ERROR: PROJECT_ID required. Pass as arg or set GCP_PROJECT_ID." >&2
  exit 1
fi

BASE_URL="https://${REGION}-${PROJECT_ID}.cloudfunctions.net"

# Try to detect default compute SA if not explicitly set
if [[ -z "${SERVICE_ACCOUNT:-}" ]]; then
  PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
  SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
fi

echo "==> Deploying Cloud Scheduler jobs"
echo "    Project : $PROJECT_ID"
echo "    Region  : $REGION"
echo "    SA      : $SERVICE_ACCOUNT"
echo "    Base URL: $BASE_URL"
echo ""

# Helper: create-or-update a scheduler job
upsert_job() {
  local NAME="$1"
  local SCHEDULE="$2"
  local URI="$3"
  local METHOD="${4:-POST}"
  local BODY="${5:-{\}}"
  local DESCRIPTION="${6:-DFC scheduler job}"

  echo "--> Job: $NAME ($SCHEDULE)"

  if gcloud scheduler jobs describe "$NAME" --project="$PROJECT_ID" --location="$REGION" &>/dev/null; then
    gcloud scheduler jobs update http "$NAME" \
      --project="$PROJECT_ID" \
      --location="$REGION" \
      --schedule="$SCHEDULE" \
      --uri="$URI" \
      --http-method="$METHOD" \
      --message-body="$BODY" \
      --headers="Content-Type=application/json" \
      --oidc-service-account-email="$SERVICE_ACCOUNT" \
      --oidc-token-audience="$URI" \
      --attempt-deadline=60s \
      --description="$DESCRIPTION"
  else
    gcloud scheduler jobs create http "$NAME" \
      --project="$PROJECT_ID" \
      --location="$REGION" \
      --schedule="$SCHEDULE" \
      --uri="$URI" \
      --http-method="$METHOD" \
      --message-body="$BODY" \
      --headers="Content-Type=application/json" \
      --oidc-service-account-email="$SERVICE_ACCOUNT" \
      --oidc-token-audience="$URI" \
      --attempt-deadline=60s \
      --description="$DESCRIPTION"
  fi
}

# ─── Job 1: Webhook DLQ Worker (every 5 minutes) ────────────────────────────
upsert_job \
  "dfc-webhook-dlq-worker" \
  "*/5 * * * *" \
  "${BASE_URL}/dlqWorkerRun" \
  "POST" \
  '{"triggered":"scheduler"}' \
  "DFC: Retry ready items in Firestore webhook dead-letter queue"

# ─── Job 2: A/B Results Aggregation (every 15 minutes) ──────────────────────
upsert_job \
  "dfc-ab-results-aggregation" \
  "*/15 * * * *" \
  "${BASE_URL}/abResultsAggregation" \
  "POST" \
  '{"updateMetrics":true}' \
  "DFC: Aggregate A/B experiment results and update offer acceptance metrics"

# ─── Job 3: Feature Flag Cache Warmup (every 10 minutes) ────────────────────
upsert_job \
  "dfc-feature-flag-warmup" \
  "*/10 * * * *" \
  "${BASE_URL}/auditFeatureFlags" \
  "POST" \
  '{}' \
  "DFC: Warm feature flag cache to reduce Firestore read latency"

# ─── Job 4: DLQ Exhausted Daily Report (08:00 ET) ───────────────────────────
upsert_job \
  "dfc-dlq-exhausted-daily-report" \
  "0 13 * * *" \
  "${BASE_URL}/dlqInspect?status=exhausted" \
  "GET" \
  '{}' \
  "DFC: Daily summary of exhausted DLQ items for ops review"

echo ""
echo "==> All scheduler jobs deployed successfully."
echo ""
echo "    Verify with:"
echo "    gcloud scheduler jobs list --project=${PROJECT_ID} --location=${REGION}"
