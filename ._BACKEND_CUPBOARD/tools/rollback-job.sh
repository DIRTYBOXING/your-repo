#!/usr/bin/env bash
set -euo pipefail
BACKEND=${PROMOTE_BACKEND:-http://localhost:4000}
if [ $# -lt 1 ]; then
  echo "Usage: $0 <JOB_ID1> [JOB_ID2 ...]"
  exit 2
fi
PROMOTE_BACKEND=$BACKEND node tools/rollback-job.js "$@"
