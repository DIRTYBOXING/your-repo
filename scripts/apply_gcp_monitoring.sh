#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   PROJECT_ID=your-project bash scripts/apply_gcp_monitoring.sh [--dry-run]
#   OR
#   bash scripts/apply_gcp_monitoring.sh your-project-id [--dry-run]

PROJECT_ID="${1:-${PROJECT_ID:-}}"
DRY_RUN=0

# If first arg is --dry-run and PROJECT_ID empty, allow usage
if [[ "${PROJECT_ID}" == "--dry-run" ]]; then
  PROJECT_ID="${PROJECT_ID:-}"
fi

# If second arg is --dry-run
if [[ "${2:-}" == "--dry-run" || "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

if [ -z "${PROJECT_ID}" ]; then
  echo "Usage: $0 PROJECT_ID [--dry-run]"
  echo "Or set PROJECT_ID in environment and run: PROJECT_ID=... $0 [--dry-run]"
  exit 2
fi

echo "Project: ${PROJECT_ID}"
if [ "${DRY_RUN}" -eq 1 ]; then
  echo "Running in dry-run mode. Commands will be printed but not executed."
fi

run_cmd() {
  if [ "${DRY_RUN}" -eq 1 ]; then
    echo "+ $*"
  else
    echo "-> $*"
    eval "$@"
  fi
}

# Example: create log-based metric for facebook publish failures
run_cmd gcloud logging metrics create facebook_publish_failure \
  --description="Count Facebook publish failures emitted by promotion-worker" \
  --log-filter='jsonPayload.metric="facebook_publish_failure"' \
  --project="${PROJECT_ID}"

run_cmd gcloud logging metrics create facebook_publish_success \
  --description="Count Facebook publish successes emitted by promotion-worker" \
  --log-filter='jsonPayload.metric="facebook_publish_success"' \
  --project="${PROJECT_ID}"

# Example alert policy creation (uses a simple condition on the failure metric)
ALERT_JSON="$(mktemp)"
cat > "${ALERT_JSON}" <<'JSON'
{
  "displayName": "Entitlement / Facebook publish failure rate",
  "combiner": "OR",
  "conditions": [
    {
      "displayName": "Facebook publish failures > 5 in 5m",
      "conditionThreshold": {
        "filter": "metric.type=\"logging.googleapis.com/user/facebook_publish_failure\"",
        "comparison": "COMPARISON_GT",
        "thresholdValue": 5,
        "duration": "300s",
        "trigger": { "count": 1 }
      }
    }
  ],
  "notificationChannels": []
}
JSON

run_cmd gcloud alpha monitoring policies create --policy-from-file="${ALERT_JSON}" --project="${PROJECT_ID}"

rm -f "${ALERT_JSON}"

echo "Monitoring apply completed (dry-run=${DRY_RUN})."
