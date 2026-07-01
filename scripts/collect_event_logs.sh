#!/usr/bin/env bash
# Collect logs from all DFC services for post-event audit
# Usage: bash scripts/collect_event_logs.sh [EVENT_NAME]
set -euo pipefail

EVENT="${1:-$(date +%Y%m%d-%H%M%S)}"
LOG_DIR="logs/$EVENT"
mkdir -p "$LOG_DIR"

echo "Collecting DFC event logs → $LOG_DIR"

# Docker service logs
for svc in db ingest n8n redis predictor auto-clip-worker entitlements secrets; do
  container=$(docker-compose ps -q "$svc" 2>/dev/null || true)
  if [ -n "$container" ]; then
    docker logs "$container" > "$LOG_DIR/${svc}.log" 2>&1 || true
    echo "  Collected: $svc"
  fi
done

# Prometheus metrics snapshot
curl -s http://localhost:9090/metrics > "$LOG_DIR/prometheus.prom" 2>/dev/null || true

# Smoke test artifacts
cp -r ci/smoke-artifacts/* "$LOG_DIR/" 2>/dev/null || true

# Load test results
cp load/results/*.json "$LOG_DIR/" 2>/dev/null || true

echo ""
echo "Event logs collected to $LOG_DIR/"
ls -la "$LOG_DIR/"
