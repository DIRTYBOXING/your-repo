#!/usr/bin/env bash
set -euo pipefail
docker compose down || true
docker rm -f n8n || true
echo "Stopped background services"
