#!/usr/bin/env bash
# scripts/apply_facebook_monitoring.sh
#
# Creates log-based metrics and alert policies for the Facebook publish path.
# Run once per project after deploying the promotion-worker.
#
# Usage:
#   bash scripts/apply_facebook_monitoring.sh datafightcentral
#   PROJECT_ID=datafightcentral bash scripts/apply_facebook_monitoring.sh
#
set -euo pipefail

PROJECT_ID="${1:-${PROJECT_ID:-}}"
NOTIFICATION_CHANNEL="${NOTIFICATION_CHANNEL:-}"   # optional; alerts fire silently if blank

if [[ -z "$PROJECT_ID" ]]; then
  echo "Usage: bash scripts/apply_facebook_monitoring.sh <project-id>" >&2
  echo "   or: PROJECT_ID=<project-id> bash scripts/apply_facebook_monitoring.sh" >&2
  exit 1
fi

echo "==> Applying Facebook publish log-based metrics to project: $PROJECT_ID"

# ── 1) facebook_publish_success ───────────────────────────────────────────────
gcloud logging metrics create facebook_publish_success \
  --project="$PROJECT_ID" \
  --description="Successful Facebook Graph API publishes by promotion-worker" \
  --log-filter='resource.type="cloud_run_revision" jsonPayload.metric="facebook_publish_success"' \
  2>/dev/null || \
gcloud logging metrics update facebook_publish_success \
  --project="$PROJECT_ID" \
  --description="Successful Facebook Graph API publishes by promotion-worker" \
  --log-filter='resource.type="cloud_run_revision" jsonPayload.metric="facebook_publish_success"'

echo "  [ok] metric: facebook_publish_success"

# ── 2) facebook_publish_failure ───────────────────────────────────────────────
gcloud logging metrics create facebook_publish_failure \
  --project="$PROJECT_ID" \
  --description="Failed Facebook Graph API publishes by promotion-worker" \
  --log-filter='resource.type="cloud_run_revision" jsonPayload.metric="facebook_publish_failure"' \
  2>/dev/null || \
gcloud logging metrics update facebook_publish_failure \
  --project="$PROJECT_ID" \
  --description="Failed Facebook Graph API publishes by promotion-worker" \
  --log-filter='resource.type="cloud_run_revision" jsonPayload.metric="facebook_publish_failure"'

echo "  [ok] metric: facebook_publish_failure"

# ── 3) Alert: facebook_publish_failure rate > 0 over 5 min ───────────────────
ALERT_JSON=$(cat <<EOF
{
  "displayName": "Facebook Publish Failure",
  "conditions": [
    {
      "displayName": "Any facebook_publish_failure log entry in 5 min",
      "conditionThreshold": {
        "filter": "metric.type=\"logging.googleapis.com/user/facebook_publish_failure\" resource.type=\"cloud_run_revision\"",
        "aggregations": [
          {
            "alignmentPeriod": "300s",
            "crossSeriesReducer": "REDUCE_SUM",
            "perSeriesAligner": "ALIGN_DELTA"
          }
        ],
        "comparison": "COMPARISON_GT",
        "thresholdValue": 0,
        "duration": "0s",
        "trigger": { "count": 1 }
      }
    }
  ],
  "alertStrategy": { "autoClose": "604800s" },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [${NOTIFICATION_CHANNEL:+"\"$NOTIFICATION_CHANNEL\""}],
  "documentation": {
    "content": "Facebook publish failure detected. Check promotion-worker logs for 'facebook_publish_failure' entries and verify DLQ (promotion_dlq topic) is receiving the payload.",
    "mimeType": "text/markdown"
  }
}
EOF
)

ALERT_FILE="$(mktemp -t dfc_fb_alert.XXXXXX.json)"
echo "$ALERT_JSON" > "$ALERT_FILE"
gcloud alpha monitoring policies create \
  --project="$PROJECT_ID" \
  --policy-from-file="$ALERT_FILE"
rm "$ALERT_FILE"

echo "  [ok] alert policy: Facebook Publish Failure"
echo ""
echo "==> Done. Verify in Cloud Monitoring > Alerting."
