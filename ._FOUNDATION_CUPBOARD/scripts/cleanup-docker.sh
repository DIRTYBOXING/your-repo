#!/usr/bin/env bash
set -euo pipefail

echo "Pruning unused containers, images, networks and build cache (non-interactive)"
docker system prune -af
docker volume prune -f
echo "Docker cleanup complete"
