#!/usr/bin/env bash
set -euo pipefail

echo "Starting core DFC services: db redis ingest predictor entitlements prometheus grafana secrets"
docker compose up -d db redis ingest predictor entitlements prometheus grafana secrets

echo "Services started. Use 'docker compose ps' to check status and 'docker compose logs -f <service>' for logs."
