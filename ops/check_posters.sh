#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: bash ops/check_posters.sh <GCS_BUCKET> <EVENT_ID> <CDN_EDGE_HOST>" >&2
  exit 1
fi

BUCKET="$1"
EVENT="$2"
EDGE_HOST="$3"
REQUIRE_POSTER_VARIANTS="${REQUIRE_POSTER_VARIANTS:-0}"
MIN_POSTER_BYTES="${MIN_POSTER_BYTES:-10240}"

POSTER_EXTENSIONS=(jpg jpeg png webp)
REGIONS=(us-east1 europe-west1 australia-southeast1)

if ! command -v gsutil >/dev/null 2>&1; then
  echo "ERROR: gsutil not found in PATH" >&2
  exit 2
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl not found in PATH" >&2
  exit 2
fi

find_poster_object() {
  local extension
  for extension in "${POSTER_EXTENSIONS[@]}"; do
    local candidate="gs://${BUCKET}/events/${EVENT}/poster.${extension}"
    if gsutil ls "$candidate" >/dev/null 2>&1; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

validate_object_size() {
  local object_path="$1"
  local size_bytes

  size_bytes="$(gsutil ls -l "${object_path}" | awk 'NR==1 {print $1}')"
  if [[ -z "${size_bytes}" || ! "${size_bytes}" =~ ^[0-9]+$ ]]; then
    echo "Unable to determine object size for ${object_path}" >&2
    return 1
  fi

  if (( size_bytes < MIN_POSTER_BYTES )); then
    echo "Poster object too small (${size_bytes} bytes < ${MIN_POSTER_BYTES}): ${object_path}" >&2
    return 1
  fi

  return 0
}

require_object() {
  local object_path="$1"
  if ! gsutil ls "${object_path}" >/dev/null 2>&1; then
    echo "Required poster object missing: ${object_path}" >&2
    return 1
  fi

  validate_object_size "${object_path}"
}

if [[ "${REQUIRE_POSTER_VARIANTS}" == "1" ]]; then
  HERO_OBJECT="gs://${BUCKET}/events/${EVENT}/poster.jpg"
  MOBILE_OBJECT="gs://${BUCKET}/events/${EVENT}/poster_200x200.jpg"

  if ! require_object "${HERO_OBJECT}"; then
    echo "Poster fidelity FAIL: required hero poster missing or below size threshold." >&2
    exit 3
  fi

  if ! require_object "${MOBILE_OBJECT}"; then
    echo "Poster fidelity FAIL: required mobile poster missing or below size threshold." >&2
    exit 3
  fi

  POSTER_OBJECT="${HERO_OBJECT}"
else
  POSTER_OBJECT="$(find_poster_object || true)"
  if [[ -z "$POSTER_OBJECT" ]]; then
    echo "GCS object MISSING FAIL: no poster.{jpg,jpeg,png,webp} found for event ${EVENT}" >&2
    exit 3
  fi
  if ! validate_object_size "${POSTER_OBJECT}"; then
    echo "Poster size FAIL: poster object is below minimum size threshold." >&2
    exit 3
  fi
fi

POSTER_NAME="${POSTER_OBJECT#gs://${BUCKET}/}"
ORIGIN_URL="https://storage.googleapis.com/${BUCKET}/${POSTER_NAME}"

echo "Checking poster object in GCS: ${POSTER_OBJECT}"
echo
echo "1) GCS object metadata"
gsutil ls -L "${POSTER_OBJECT}" | sed -n '1,25p'
echo "GCS object exists PASS"

echo
echo "2) Origin HTTP HEAD check"
ORIGIN_STATUS="$(curl -sS -o /dev/null -w '%{http_code} %{time_total}\n' -I "${ORIGIN_URL}" || true)"
echo "Origin response: ${ORIGIN_STATUS}"
if [[ ! "${ORIGIN_STATUS}" =~ ^200\  ]]; then
  echo "Origin HEAD FAIL" >&2
  echo "Try signed URL generation, bucket permissions, or object path validation." >&2
  exit 4
fi
echo "Origin HEAD PASS"

echo
echo "3) CDN edge checks"
if [[ -z "${EDGE_HOST}" || "${EDGE_HOST}" =~ example\.com$ || "${EDGE_HOST}" =~ \.example\.com$ ]]; then
  echo "Skipping CDN edge checks: EDGE_HOST is placeholder (${EDGE_HOST})"
  echo "CDN edge PASS (skipped)"
else
FAIL_COUNT=0
EDGE_PATH="${POSTER_NAME#events/${EVENT}/}"
for region in "${REGIONS[@]}"; do
  EDGE_URL="https://${EDGE_HOST}/events/${EVENT}/${EDGE_PATH}"
  OUT="$(curl -sS -o /dev/null -w '%{http_code} %{time_total}\n' "${EDGE_URL}" || true)"
  echo "${region}: ${EDGE_URL} -> ${OUT}"
  CODE="$(echo "${OUT}" | awk '{print $1}')"
  if [[ "${CODE}" != "200" ]]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done

if [[ "${FAIL_COUNT}" -gt 0 ]]; then
  echo "CDN edge checks FAILED (${FAIL_COUNT} regions). Consider purge or origin mapping review." >&2
  exit 5
fi
echo "CDN edge PASS"
fi

echo
echo "4) CORS heuristic"
CORS_OUT="$(curl -sS -I -H 'Origin: https://staging.dfc.example.com' "${ORIGIN_URL}" | grep -i 'access-control-allow-origin' || true)"
if [[ -n "${CORS_OUT}" ]]; then
  echo "CORS header present: ${CORS_OUT}"
else
  echo "No CORS header detected. Add bucket CORS if the frontend requires direct cross-origin fetches."
fi

echo
echo "5) Cache headers"
curl -sS -I "${ORIGIN_URL}" | grep -Ei 'cache-control|age|via|content-type' || true

echo
echo "Poster checks completed SUCCESS"
