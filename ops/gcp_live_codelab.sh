#!/usr/bin/env bash
set -euo pipefail

# DFC Live Streaming codelab automation.
# Supports dry-run mode for CI rehearsal checks without mutating resources.

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null || true)}"
REGION="${REGION:-us-central1}"
EVENT="${EVENT:-champions-collide-2026}"
BUCKET="${BUCKET:-dfc-live-${PROJECT}}"
INPUT_ID="${INPUT_ID:-dfc-input}"
CHANNEL_ID="${CHANNEL_ID:-dfc-channel}"

if [[ -z "${PROJECT}" || "${PROJECT}" == "(unset)" ]]; then
  echo "ERROR: PROJECT is not set and gcloud has no default project" >&2
  exit 2
fi

if ! command -v gcloud >/dev/null 2>&1; then
  echo "ERROR: gcloud CLI not found" >&2
  exit 2
fi

if ! command -v gsutil >/dev/null 2>&1; then
  echo "ERROR: gsutil not found" >&2
  exit 2
fi

run_cmd() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

echo "Project: ${PROJECT}  Region: ${REGION}  Event: ${EVENT}  Bucket: ${BUCKET}"

echo "[1/5] Enable required APIs"
run_cmd gcloud services enable \
  livestream.googleapis.com \
  storage.googleapis.com \
  monitoring.googleapis.com \
  --project="${PROJECT}"

echo "[2/5] Ensure bucket exists and versioning enabled"
if ! gsutil ls -b "gs://${BUCKET}" >/dev/null 2>&1; then
  run_cmd gsutil mb -p "${PROJECT}" -l "${REGION}" "gs://${BUCKET}"
fi
run_cmd gsutil versioning set on "gs://${BUCKET}"

echo "[3/5] Ensure Live Streaming input exists"
if ! gcloud livestream inputs describe "${INPUT_ID}" --region="${REGION}" --project="${PROJECT}" >/dev/null 2>&1; then
  run_cmd gcloud livestream inputs create "${INPUT_ID}" \
    --region="${REGION}" \
    --type=rtmp \
    --project="${PROJECT}"
fi

INPUT_RESOURCE="projects/${PROJECT}/locations/${REGION}/inputs/${INPUT_ID}"
OUTPUT_URI="gs://${BUCKET}/events/${EVENT}/"

echo "[4/5] Ensure channel exists"
if ! gcloud livestream channels describe "${CHANNEL_ID}" --region="${REGION}" --project="${PROJECT}" >/dev/null 2>&1; then
  run_cmd gcloud livestream channels create "${CHANNEL_ID}" \
    --region="${REGION}" \
    --input="${INPUT_RESOURCE}" \
    --output-uri="${OUTPUT_URI}" \
    --project="${PROJECT}"
fi

echo "[5/5] Summary"
echo "Output path: ${OUTPUT_URI}"
echo "Media CDN allowlist may be required before origin/edge setup."
echo "Next: push RTMP test signal and validate manifests with ops/check_manifests.sh"
