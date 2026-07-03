# ops/ — DFC Infrastructure & Operator Runbook

This directory contains scripts, configs, and CI/CD artifacts for the
DataFightCentral backend platform. Run the steps below in order the first
time you bootstrap a new environment, then refer to individual sections when
updating specific subsystems.

## Live Streaming Codelab (Media CDN + Live Streaming API)

Use this lane for PPV dress rehearsals: ingest -> transcode -> GCS origin -> CDN -> player.

Run the setup script:

```bash
PROJECT=your-gcp-project-id REGION=us-central1 EVENT=champions-collide-2026 \
BUCKET=dfc-live-your-gcp-project-id bash ops/gcp_live_codelab.sh
```

Dry-run mode for CI access checks:

```bash
PROJECT=your-gcp-project-id REGION=us-central1 EVENT=champions-collide-2026 \
BUCKET=dfc-live-your-gcp-project-id bash ops/gcp_live_codelab.sh --dry-run
```

Validate output manifests:

```bash
bash ops/check_manifests.sh dfc-live-your-gcp-project-id champions-collide-2026
```

Media CDN allowlist:

- Media CDN may require project allowlisting. Coordinate with your Google account team if origin/endpoint creation is unavailable.
- If allowlist is pending, continue staging playback using signed GCS URLs.

Manual Cloud Console steps:

- Network Services -> Media CDN -> create origin and endpoint pointing to:
  gs://<BUCKET>/events/<EVENT>/

Run environment preflight before staging lanes:

```bash
bash ops/verify_env.sh
```

This checks Docker daemon reachability, GitHub CLI authentication, and active gcloud project/account.

---

## Prerequisites

| Tool           | Min version | Notes                                                         |
| -------------- | ----------- | ------------------------------------------------------------- |
| `gcloud` CLI   | 450+        | `gcloud auth login` + `gcloud auth application-default login` |
| `firebase` CLI | 13+         | `firebase login`                                              |
| `bash`         | 5+          | Use Git Bash or WSL on Windows                                |
| Node.js        | 20.x        | Required for Cloud Functions deploy                           |
| GitHub token   | —           | `repo` + `admin:repo_hook` scopes                             |

Export these before running any script:

```bash
export PROJECT_ID=your-gcp-project-id
export GITHUB_ORG=DIRTYBOXING
export GITHUB_REPO=Data-Fight-Central
export GITHUB_TOKEN=ghp_...
export REGION=australia-southeast1   # or your preferred region
```

---

## Step 1 — Bootstrap Cloud Build triggers & branch protection

```bash
bash ops/create-cloudbuild-trigger.sh
```

This registers two Cloud Build triggers (`dfc-pr-check`, `dfc-deploy`) and
applies GitHub branch protection on `master` requiring all seven
`dfc-ci:*` status checks:

| Context name                     | Job                                       |
| -------------------------------- | ----------------------------------------- |
| `dfc-ci:ent-audit`               | npm audit — entitlements-service          |
| `dfc-ci:tsc-poster`              | TypeScript check — poster-worker          |
| `dfc-ci:tsc-promotion`           | TypeScript check — promotion-worker       |
| `dfc-ci:flutter`                 | flutter analyze                           |
| `dfc-ci:docker-entitlements`     | Docker smoke build — entitlements-service |
| `dfc-ci:docker-poster-worker`    | Docker smoke build — poster-worker        |
| `dfc-ci:docker-promotion-worker` | Docker smoke build — promotion-worker     |

---

## Step 2 — Create the Canary Rollback notification channel

Create a webhook notification channel that points at the deployed
`canary-rollback` Cloud Function URL:

```bash
CANARY_FN_URL="https://${REGION}-${PROJECT_ID}.cloudfunctions.net/canary-rollback"

cat > /tmp/channel.json <<EOF
{
  "type": "webhook",
  "displayName": "Canary Rollback Webhook",
  "labels": { "url": "${CANARY_FN_URL}" }
}
EOF

gcloud alpha monitoring channels create \
  --project="${PROJECT_ID}" \
  --channel-content-from-file=/tmp/channel.json
```

Copy the `name` field from the output — it looks like:
`projects/your-project/notificationChannels/1234567890`

---

## Step 3 — Apply the alert policy

1. Open `ops/alert-policy.json`.
2. Replace both placeholder values:
   - `REPLACE_ME_PROJECT_ID` → your GCP project ID (e.g. `datafightcentral-prod`)
   - `REPLACE_ME_NOTIF_CHANNEL_ID` → the channel `name` from Step 2
3. Commit the updated file, then apply:

```bash
gcloud alpha monitoring policies create \
  --project="${PROJECT_ID}" \
  --policy-from-file=ops/alert-policy.json
```

The policy fires when `custom.googleapis.com/playback_success_rate` falls
below **99 %** for **5 minutes**, triggering the canary rollback function.

---

## Step 4 — Store secrets in Secret Manager

```bash
# Slack webhook for canary incident notifications
gcloud secrets create SLACK_CANARY_WEBHOOK --replication-policy="automatic"
echo -n "https://hooks.slack.com/services/XXX/YYY/ZZZ" \
  | gcloud secrets versions add SLACK_CANARY_WEBHOOK --data-file=-

# Shared token that the alert webhook uses to authenticate calls to the CF
gcloud secrets create CANARY_TRIGGER_TOKEN --replication-policy="automatic"
echo -n "$(openssl rand -hex 32)" \
  | gcloud secrets versions add CANARY_TRIGGER_TOKEN --data-file=-
```

Grant the function service account access:

```bash
SA="your-service-account@${PROJECT_ID}.iam.gserviceaccount.com"

for SECRET in SLACK_CANARY_WEBHOOK CANARY_TRIGGER_TOKEN; do
  gcloud secrets add-iam-policy-binding "${SECRET}" \
    --member="serviceAccount:${SA}" \
    --role="roles/secretmanager.secretAccessor"
done
```

---

## Step 5 — Deploy the Canary Rollback Cloud Function

```bash
gcloud functions deploy canary-rollback \
  --project="${PROJECT_ID}" \
  --runtime=nodejs20 \
  --trigger-http \
  --region="${REGION}" \
  --source=functions/canaryGuard \
  --entry-point=canaryRollback \
  --service-account="${SA}" \
  --no-allow-unauthenticated
```

Smoke-test the endpoint (replace token with the value stored in step 4):

```bash
TOKEN=$(gcloud secrets versions access latest --secret=CANARY_TRIGGER_TOKEN)
CANARY_URL="https://${REGION}-${PROJECT_ID}.cloudfunctions.net/canary-rollback"

curl -s -X POST "${CANARY_URL}" \
  -H "Content-Type: application/json" \
  -H "x-canary-token: ${TOKEN}" \
  -d '{"reason":"manual smoke test"}' | jq .
```

Expected response: `{"status":"rolled_back","canary_percent":0}`  
Firestore `settings/canary.canary_percent` should be **0** and a Slack
message should appear in the configured channel.

---

## Step 6 — Run Postman E2E

```bash
npx newman run ops/postman-entitlements-e2e.json \
  --env-var "BASE_URL=https://${REGION}-${PROJECT_ID}.run.app" \
  --env-var "CANARY_TOKEN=${TOKEN}" \
  --reporters cli,json \
  --reporter-json-export ops/launch/e2e-results.json
```

All 8 steps must pass before flipping the public canary above 0 %.

---

## Monitoring KPIs

| Metric                                 | Target             |
| -------------------------------------- | ------------------ |
| Playback success (start → first frame) | ≥ 99.5 %           |
| Startup latency (median)               | ≤ 2 s              |
| Rebuffer ratio                         | ≤ 1 %              |
| License API p95                        | < 500 ms           |
| Pub/Sub DLQ growth                     | < 10 % over 10 min |

---

## Incident response

1. Alert fires → rollback function sets `canary_percent = 0` and posts to Slack.
2. Pull Cloud Run logs: `gcloud run services logs read entitlements-service --region=${REGION}`
3. Inspect Pub/Sub DLQ: navigate to Cloud Console → Pub/Sub → `<topic>-dlq`.
4. Revoke compromised tokens if needed: `gcloud secrets versions disable`.
5. Open a postmortem incident channel and tag the on-call engineer.
6. Re-deploy fix, re-run E2E, then gradually ramp canary back: 1 % → 10 % → 50 % → 100 %.

---

## GitHub branch protection API payload (reference)

If you need to update branch protection manually without running the script,
use this payload against
`PUT https://api.github.com/repos/DIRTYBOXING/Data-Fight-Central/branches/master/protection`:

```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "dfc-ci:ent-audit",
      "dfc-ci:tsc-poster",
      "dfc-ci:tsc-promotion",
      "dfc-ci:flutter",
      "dfc-ci:docker-entitlements",
      "dfc-ci:docker-poster-worker",
      "dfc-ci:docker-promotion-worker"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
```

```bash
# One-liner using curl:
curl -s -X PUT \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/DIRTYBOXING/Data-Fight-Central/branches/master/protection" \
  -d @ops/branch-protection.json
```
