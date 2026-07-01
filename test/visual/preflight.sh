#!/usr/bin/env bash
set -euo pipefail

TEST_BASE_URL="${TEST_BASE_URL:-http://127.0.0.1:8088}"
API_BASE_URL="${PLAYWRIGHT_API_BASE:-http://127.0.0.1:3000}"

echo "[preflight] Checking static page: ${TEST_BASE_URL}/promoters.html"
if ! curl -fsS "${TEST_BASE_URL}/promoters.html" >/dev/null; then
  echo "Static promoters page not reachable at ${TEST_BASE_URL}/promoters.html"
  exit 2
fi

echo "[preflight] Checking API health: ${API_BASE_URL}/health"
if ! curl -fsS "${API_BASE_URL}/health" >/dev/null; then
  echo "API health endpoint not reachable at ${API_BASE_URL}/health"
  exit 2
fi

echo "[preflight] Checking promoters selector #dfc-fuzzy"
if ! curl -fsS "${TEST_BASE_URL}/promoters.html" | grep -q 'id="dfc-fuzzy"'; then
  echo "Promoters selector missing: #dfc-fuzzy"
  exit 2
fi

echo "[preflight] Preflight checks passed"
