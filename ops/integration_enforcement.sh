#!/usr/bin/env bash
set -euo pipefail

# Canonical enforcement lane:
# 1) PPV production gate
# 2) Weekly sweep

EVENT_ID="${1:-${EVENT_ID:-champions-collide-2026}}"

echo "[1/2] Running PPV production gate"
npm run ppv:gate

echo "[2/2] Running weekly sweep for event: ${EVENT_ID}"
bash ./ops/weekly_sweep.sh "${EVENT_ID}"

echo "Integration enforcement passed"
