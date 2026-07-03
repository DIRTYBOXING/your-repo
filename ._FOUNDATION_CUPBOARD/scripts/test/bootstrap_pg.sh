#!/usr/bin/env bash
set -euo pipefail

# Boot an ephemeral PostgreSQL container for local CI smoke.
# Usage:
#   ./scripts/test/bootstrap_pg.sh
# Exports:
#   PG_CONN=postgres://dfc:dfc@localhost:5432/dfc_test

CONTAINER_NAME="${PG_CONTAINER_NAME:-dfc-pg-test}"
POSTGRES_USER="${POSTGRES_USER:-dfc}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-dfc}"
POSTGRES_DB="${POSTGRES_DB:-dfc_test}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
fi

docker run -d --name "${CONTAINER_NAME}" \
  -e POSTGRES_USER="${POSTGRES_USER}" \
  -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
  -e POSTGRES_DB="${POSTGRES_DB}" \
  -p "${POSTGRES_PORT}:5432" \
  postgres:15 >/dev/null

export PG_CONN="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${POSTGRES_PORT}/${POSTGRES_DB}"
echo "PG_CONN=${PG_CONN}"

echo "Waiting for PostgreSQL readiness..."
until docker exec "${CONTAINER_NAME}" pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" >/dev/null 2>&1; do
  sleep 1
done

echo "PostgreSQL is ready in container ${CONTAINER_NAME}."
