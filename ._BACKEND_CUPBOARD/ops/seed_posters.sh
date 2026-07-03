#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null || true)}"
if [[ -z "${PROJECT}" || "${PROJECT}" == "(unset)" ]]; then
  echo "ERROR: PROJECT not set and gcloud has no default project" >&2
  exit 2
fi

BUCKET="${BUCKET:-dfc-live-${PROJECT}}"
EVENT="${1:-${EVENT:-smoke-event}}"
LOCAL_POSTER="${2:-./assets/posters/${EVENT}-poster.jpg}"

if [[ ! -f "${LOCAL_POSTER}" ]]; then
  echo "ERROR: poster file not found: ${LOCAL_POSTER}" >&2
  exit 2
fi

if ! command -v gsutil >/dev/null 2>&1; then
  echo "ERROR: gsutil not found" >&2
  exit 2
fi

target="gs://${BUCKET}/events/${EVENT}/poster.jpg"

echo "Uploading ${LOCAL_POSTER} -> ${target}"
gsutil cp "${LOCAL_POSTER}" "${target}"
gsutil setmeta -h "Cache-Control:public, max-age=86400" "${target}"
gsutil ls -L "${target}"

echo "Seeded poster for ${EVENT}"
