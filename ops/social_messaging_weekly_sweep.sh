#!/usr/bin/env bash
set -euo pipefail

# Weekly social+messaging sweep.
# Runs the social smoke lane and optional signaling load test.

BASE_URL="${BASE_URL:-http://localhost:8080}"
WS_BASE="${WS_BASE:-ws://localhost:8799/ws/social}"
RUN_LOAD="${RUN_LOAD:-0}"

export BASE_URL
export WS_BASE

bash ./ops/social_messaging_smoke.sh

if [[ "$RUN_LOAD" == "1" ]]; then
  if command -v k6 >/dev/null 2>&1; then
    echo "Running signaling storm k6 script"
    k6 run tests/k6/signaling_storm.js
  else
    echo "SKIP: k6 not installed"
  fi
fi

echo "Social messaging weekly sweep passed"
