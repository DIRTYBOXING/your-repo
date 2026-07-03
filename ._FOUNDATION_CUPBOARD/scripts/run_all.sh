#!/usr/bin/env bash
set -euo pipefail
echo "Starting docker-compose stack..."
docker-compose up -d --build
./scripts/wait-for.sh localhost 9000
./scripts/wait-for.sh localhost 5432
./scripts/wait-for.sh localhost 6379
echo "All infra healthy"
