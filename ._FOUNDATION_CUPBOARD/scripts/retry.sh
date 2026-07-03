#!/usr/bin/env bash
set -euo pipefail
cmd="$1"; shift
retries=${RETRIES:-5}
delay=${DELAY:-2}
attempt=0
until [ $attempt -ge $retries ]
do
  attempt=$((attempt+1))
  echo "[retry] attempt $attempt: $cmd"
  if bash -c "$cmd"; then
    echo "[retry] success"
    exit 0
  fi
  echo "[retry] failed, sleeping $delay"
  sleep $delay
done
echo "[retry] exhausted $retries attempts"
exit 1
