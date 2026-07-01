#!/usr/bin/env bash
set -euo pipefail
host=$1; shift
port=$1; shift
timeout=${TIMEOUT:-30}
echo "Waiting for $host:$port (timeout ${timeout}s)"
for i in $(seq 1 $timeout); do
  if command -v nc >/dev/null 2>&1; then
    nc -z "$host" "$port" 2>/dev/null && {
      echo "Service $host:$port is up"
      exit 0
    }
  else
    (echo > /dev/tcp/$host/$port) >/dev/null 2>&1 && {
      echo "Service $host:$port is up"
      exit 0
    }
  fi
  sleep 1
done
echo "Timeout waiting for $host:$port"
exit 1
