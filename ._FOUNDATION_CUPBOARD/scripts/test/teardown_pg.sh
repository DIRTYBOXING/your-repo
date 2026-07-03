#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${PG_CONTAINER_NAME:-dfc-pg-test}"
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  docker rm -f "${CONTAINER_NAME}" >/dev/null
  echo "Removed ${CONTAINER_NAME}"
else
  echo "Container ${CONTAINER_NAME} not found"
fi
