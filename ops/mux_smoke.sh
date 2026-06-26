#!/usr/bin/env bash
set -euo pipefail

MUX_AUTH_URL="${MUX_AUTH_URL:-}"
MUX_API_TOKEN="${MUX_API_TOKEN:-}"

if [[ -z "${MUX_AUTH_URL}" || -z "${MUX_API_TOKEN}" ]]; then
  echo "MUX_AUTH_URL or MUX_API_TOKEN not set" >&2
  exit 2
fi

echo "Running Mux auth smoke against ${MUX_AUTH_URL}"
RESP="$(curl -sS -H "Authorization: Bearer ${MUX_API_TOKEN}" -H "Accept: application/json" "${MUX_AUTH_URL}" || true)"
echo "Response: ${RESP}"

if echo "${RESP}" | jq -e '.ok == true' >/dev/null 2>&1; then
  echo "Mux auth smoke OK (ok:true)"
  exit 0
fi

if echo "${RESP}" | jq -e '.status == "ok"' >/dev/null 2>&1; then
  echo "Mux auth smoke OK (status:ok)"
  exit 0
fi

echo "Mux auth smoke FAILED" >&2
exit 1
