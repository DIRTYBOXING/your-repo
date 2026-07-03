#!/usr/bin/env bash
set -euo pipefail

# Live Streaming codelab bootstrap for DFC staging lanes.
# Creates bucket, enables APIs, and provisions input/channel.

REGION="${REGION:-us-central1}"
EVENT_ID="${1:-${EVENT_ID:-champions-collide-2026}}"
INPUT_ID="${INPUT_ID:-dfc-input}"
CHANNEL_ID="${CHANNEL_ID:-dfc-channel}"

if ! command -v gcloud >/dev/null 2>&1; then
  echo "ERROR: gcloud not found" >&2
  exit 2
fi

if ! command -v gsutil >/dev/null 2>&1; then
  echo "ERROR: gsutil not found" >&2
  exit 2
fi

PROJECT="$(gcloud config get-value project)"
if [[ -z "$PROJECT" || "$PROJECT" == "(unset)" ]]; then
  echo "ERROR: gcloud project is not set" >&2
  exit 2
fi

BUCKET="${BUCKET:-dfc-live-${PROJECT}}"
OUTPUT_URI="gs://${BUCKET}/events/${EVENT_ID}/"

echo "[1/5] Ensuring GCS bucket: gs://${BUCKET}"
if ! gsutil ls "gs://${BUCKET}" >/dev/null 2>&1; then
  gsutil mb -p "$PROJECT" -l "$REGION" "gs://${BUCKET}"
fi
gsutil versioning set on "gs://${BUCKET}"

echo "[2/5] Enabling APIs"
gcloud services enable \
  livestream.googleapis.com \
  compute.googleapis.com \
  storage.googleapis.com \
  monitoring.googleapis.com \
  iam.googleapis.com

echo "[3/5] Ensuring Live Streaming input: ${INPUT_ID}"
if ! gcloud livestream inputs describe "$INPUT_ID" --region="$REGION" >/dev/null 2>&1; then
  gcloud livestream inputs create "$INPUT_ID" \
    --region="$REGION" \
    --type=rtmp
fi

INPUT_RESOURCE="projects/${PROJECT}/locations/${REGION}/inputs/${INPUT_ID}"

echo "[4/5] Ensuring Live Streaming channel: ${CHANNEL_ID}"
if ! gcloud livestream channels describe "$CHANNEL_ID" --region="$REGION" >/dev/null 2>&1; then
  gcloud livestream channels create "$CHANNEL_ID" \
    --region="$REGION" \
    --input="$INPUT_RESOURCE" \
    --output-uri="$OUTPUT_URI"
fi

echo "[5/5] Summary"
echo "Project:      $PROJECT"
echo "Region:       $REGION"
echo "Bucket:       gs://${BUCKET}"
echo "Event output: ${OUTPUT_URI}"
echo
echo "Next: get RTMP ingest URL and run ops/live_streaming_ffmpeg_test_signal.sh"
