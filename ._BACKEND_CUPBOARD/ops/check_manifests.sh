#!/usr/bin/env bash
set -euo pipefail

BUCKET="${1:-${BUCKET:-}}"
EVENT="${2:-${EVENT:-champions-collide-2026}}"
MAX_SEGMENTS="${MAX_SEGMENTS:-3}"

if [[ -z "${BUCKET}" ]]; then
  echo "Usage: $0 <bucket> [event]" >&2
  echo "Or set BUCKET env var." >&2
  exit 2
fi

if ! command -v gsutil >/dev/null 2>&1; then
  echo "ERROR: gsutil not found" >&2
  exit 2
fi

manifest="gs://${BUCKET}/events/${EVENT}/master.m3u8"

echo "Checking manifest: ${manifest}"
gsutil ls "${manifest}" >/dev/null

tmp_file="$(mktemp)"
trap 'rm -f "${tmp_file}"' EXIT

gsutil cat "${manifest}" > "${tmp_file}"

echo "Validating manifest header"
grep -q '^#EXTM3U' "${tmp_file}" || { echo "Invalid manifest header" >&2; exit 1; }

echo "Extracting first ${MAX_SEGMENTS} media references"
mapfile -t refs < <(grep -E '^[^#].+' "${tmp_file}" | head -n "${MAX_SEGMENTS}")

if [[ "${#refs[@]}" -eq 0 ]]; then
  echo "No segment or child-manifest references found" >&2
  exit 1
fi

for ref in "${refs[@]}"; do
  ref="${ref%%$'\r'}"
  if [[ "${ref}" == http* ]]; then
    echo "Skipping remote URL ref: ${ref}"
    continue
  fi
  target="gs://${BUCKET}/events/${EVENT}/${ref}"
  echo "Checking ${target}"
  gsutil ls "${target}" >/dev/null

done

echo "Manifest check passed"
