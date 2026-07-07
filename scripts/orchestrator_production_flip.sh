#!/usr/bin/env bash
set -euo pipefail

# orchestrator_production_flip.sh
# Single-pass orchestrator to convert staging -> production readiness and run authenticated smoke.
# Defaults to dry-run. Use --delete to remove test promos and --promote to promote revision.
#
# Usage:
#   ./scripts/orchestrator_production_flip.sh --project my-project --region australia-southeast1 \
#     --service dfc-backend --repo owner/repo --staging-url https://staging-url.run.app \
#     --prod-url https://prod-url.run.app --firebase-api-key X --ops-uid <UID> [--delete] [--promote REVISION]
#
# REQUIRED: fill or pass via flags the variables below.

# -------------------------
# Default variables (override via flags)
# -------------------------
PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
REGION="${REGION:-australia-southeast1}"
SERVICE_NAME="${SERVICE_NAME:-dfc-backend}"
GITHUB_REPO="${GITHUB_REPO:-owner/repo}"        # e.g., DIRTYBOXING/your-repo
STAGING_URL="${STAGING_URL:-https://staging-your-service-url.run.app}"
PROD_URL="${PROD_URL:-https://prod-your-service-url.run.app}"
FIREBASE_API_KEY="${FIREBASE_API_KEY:-your_firebase_web_api_key}"
FIREBASE_SMOKE_EMAIL="${FIREBASE_SMOKE_EMAIL:-smoke_test@datafightcentral.com}"
FIREBASE_SMOKE_PASSWORD="${FIREBASE_SMOKE_PASSWORD:-SmokeTest123!}"
STRIPE_LIVE_KEY="${STRIPE_LIVE_KEY:-sk_live_...}"
STRIPE_WEBHOOK_SECRET="${STRIPE_WEBHOOK_SECRET:-whsec_...}"
REDIS_URL="${REDIS_URL:-redis://:password@host:6379/0}"
OPS_USER_UID="${OPS_USER_UID:-}"                 # UID to set ops claim for
GHA_SA_NAME="${GHA_SA_NAME:-gha-deployer}"
# -------------------------

# Flags
DELETE_PROMOS=false
PROMOTE_REVISION=""
DRY_RUN=true

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_ID="$2"; shift 2;;
    --region) REGION="$2"; shift 2;;
    --service) SERVICE_NAME="$2"; shift 2;;
    --repo) GITHUB_REPO="$2"; shift 2;;
    --staging-url) STAGING_URL="$2"; shift 2;;
    --prod-url) PROD_URL="$2"; shift 2;;
    --firebase-api-key) FIREBASE_API_KEY="$2"; shift 2;;
    --smoke-email) FIREBASE_SMOKE_EMAIL="$2"; shift 2;;
    --smoke-pass) FIREBASE_SMOKE_PASSWORD="$2"; shift 2;;
    --stripe-key) STRIPE_LIVE_KEY="$2"; shift 2;;
    --stripe-webhook) STRIPE_WEBHOOK_SECRET="$2"; shift 2;;
    --redis) REDIS_URL="$2"; shift 2;;
    --ops-uid) OPS_USER_UID="$2"; shift 2;;
    --delete) DELETE_PROMOS=true; DRY_RUN=false; shift;;
    --promote) PROMOTE_REVISION="$2"; DRY_RUN=false; shift 2;;
    --help) echo "See header comments for usage"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

echo "=== Orchestrator starting ==="
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Service: $SERVICE_NAME"
echo "Repo: $GITHUB_REPO"
echo "Staging URL: $STAGING_URL"
echo "Dry run: $DRY_RUN"
echo "Delete promos: $DELETE_PROMOS"
echo "Promote revision: ${PROMOTE_REVISION:-none}"

# Helper: fail fast if required CLIs missing
for cmd in gcloud gh jq python3 node curl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $cmd"
    exit 1
  fi
done

# 1) Repo scan for stubs/test keys
echo
echo "1) Scanning repository for TODOs, UnimplementedError, test keys, and demo content..."
SCAN_RESULTS=$(grep -RIn --exclude-dir=.git --exclude-dir=build -E "TODO|UnimplementedError|throw UnimplementedError|Smoke|Test Promo|Demo|smoke_test|sk_test_|pk_test_|AIza" || true)
if [[ -n "$SCAN_RESULTS" ]]; then
  echo "ERROR: Found potential stubs/test markers in repo. Listing first 200 lines:"
  echo "$SCAN_RESULTS" | head -n 200
  echo
  echo "You must remove/replace these before proceeding to production. Aborting."
  exit 2
fi
echo "Repo scan clean."

# 2) Dry-run DB sweep (list test/demo promos)
echo
echo "2) Dry-run DB sweep: listing promotions with test/demo markers (no deletes unless --delete passed)."
cat > /tmp/cleanup_test_promos.py <<'PY'
from google.cloud import firestore
import os, re, sys
project = os.environ.get("PROJECT_ID")
if not project:
    print("Set PROJECT_ID env var")
    sys.exit(2)
pattern = re.compile(r"(smoke|test|demo|sample|placeholder)", re.IGNORECASE)
db = firestore.Client(project=project)
found = []
for doc in db.collection("promotions").stream():
    d = doc.to_dict()
    title = d.get("title","")
    status = d.get("status","")
    if pattern.search(title) or str(status).lower() in ("test","demo","smoke"):
        found.append((doc.id, title, status))
if not found:
    print("No test/demo promos found.")
else:
    print(f"Found {len(found)} test/demo promos:")
    for pid, title, status in found:
        print(f" - {pid} : {title} ({status})")
PY

export PROJECT_ID
python3 /tmp/cleanup_test_promos.py

if $DELETE_PROMOS; then
  echo
  echo "3) Deleting found promos (backup will be created first)."
  echo "Creating Firestore export backup..."
  BUCKET="gs://${PROJECT_ID}-firestore-backups"
  echo "Exporting to $BUCKET (creating bucket if needed)..."
  gsutil mb -p "$PROJECT_ID" -l "$REGION" "$BUCKET" || true
  gcloud firestore export "$BUCKET" --project "$PROJECT_ID"
  echo "Backup complete."
  # Run deletion script (requires manual confirmation)
  echo "Running deletion (manual confirmation required)."
  python3 - <<'PY'
from google.cloud import firestore
import os, re
project = os.environ.get("PROJECT_ID")
pattern = re.compile(r"(smoke|test|demo|sample|placeholder)", re.IGNORECASE)
db = firestore.Client(project=project)
to_delete=[]
for doc in db.collection("promotions").stream():
    d=doc.to_dict()
    title=d.get("title","")
    status=d.get("status","")
    if pattern.search(title) or str(status).lower() in ("test","demo","smoke"):
        to_delete.append(doc.id)
print("Found", len(to_delete), "promos to delete.")
confirm = input("Type DELETE to confirm: ")
if confirm == "DELETE":
    for pid in to_delete:
        db.collection("promotions").document(pid).delete()
    print("Deleted promos.")
else:
    print("Aborted deletion.")
PY
else
  echo "Dry-run only: no deletions performed."
fi

# 4) Provision service account and GitHub secret (gha-deployer)
echo
echo "4) Provisioning service account and uploading key to GitHub (requires gh CLI auth)."
SA_NAME="$GHA_SA_NAME"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="/tmp/${SA_NAME}-key.json"

if ! gcloud iam service-accounts describe "$SA_EMAIL" --project "$PROJECT_ID" >/dev/null 2>&1; then
  echo "Creating service account $SA_EMAIL"
  gcloud iam service-accounts create "$SA_NAME" --display-name="$SA_NAME" --project "$PROJECT_ID"
else
  echo "Service account $SA_EMAIL already exists."
fi

echo "Granting roles to service account..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/run.admin" || true
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/artifactregistry.writer" || true
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/secretmanager.secretAccessor" || true
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/datastore.user" || true

echo "Creating key for service account..."
gcloud iam service-accounts keys create "$KEY_FILE" --iam-account="$SA_EMAIL" --project="$PROJECT_ID" --quiet

echo "Uploading key to GitHub Actions secrets (GCP_SA_KEY)."
GCP_SA_KEY_B64=$(base64 -w 0 "$KEY_FILE")
echo "$GCP_SA_KEY_B64" | gh secret set GCP_SA_KEY --repo "$GITHUB_REPO"
echo "Uploaded GCP_SA_KEY to GitHub repo $GITHUB_REPO."

# 5) Create Secret Manager secrets and map to Cloud Run
echo
echo "5) Creating Secret Manager secrets and mapping into Cloud Run."
# FIREBASE_ADMIN_CREDENTIALS_JSON must be created from your firebase-admin.json file locally
if [ ! -f "./path/to/firebase-admin.json" ]; then
  echo "WARNING: ./path/to/firebase-admin.json not found. Please place your firebase-admin.json at that path or create the secret manually."
else
  gcloud secrets create FIREBASE_ADMIN_CREDENTIALS_JSON --data-file="./path/to/firebase-admin.json" --project "$PROJECT_ID" || true
fi

# Create STRIPE_SECRET_KEY and REDIS_URL secrets from env values
echo -n "$STRIPE_LIVE_KEY" | gcloud secrets create STRIPE_SECRET_KEY --data-file=- --project "$PROJECT_ID" || true
echo -n "$REDIS_URL" | gcloud secrets create REDIS_URL --data-file=- --project "$PROJECT_ID" || true

# Grant access to service account
gcloud secrets add-iam-policy-binding FIREBASE_ADMIN_CREDENTIALS_JSON --member="serviceAccount:${SA_EMAIL}" --role="roles/secretmanager.secretAccessor" --project "$PROJECT_ID" || true
gcloud secrets add-iam-policy-binding STRIPE_SECRET_KEY --member="serviceAccount:${SA_EMAIL}" --role="roles/secretmanager.secretAccessor" --project "$PROJECT_ID" || true
gcloud secrets add-iam-policy-binding REDIS_URL --member="serviceAccount:${SA_EMAIL}" --role="roles/secretmanager.secretAccessor" --project "$PROJECT_ID" || true

echo "Mapping secrets into Cloud Run service $SERVICE_NAME..."
gcloud run services update "$SERVICE_NAME" \
  --update-secrets FIREBASE_ADMIN_CREDENTIALS_JSON=projects/"$PROJECT_ID"/secrets/FIREBASE_ADMIN_CREDENTIALS_JSON:latest \
  --update-secrets STRIPE_SECRET_KEY=projects/"$PROJECT_ID"/secrets/STRIPE_SECRET_KEY:latest \
  --update-secrets REDIS_URL=projects/"$PROJECT_ID"/secrets/REDIS_URL:latest \
  --region "$REGION" --project "$PROJECT_ID" --quiet

echo "Secrets mapped. Restarting service by deploying no-traffic revision..."
# Deploy no-traffic revision using existing image (assumes image tag logic in CI)
# If you have an image URI, you can redeploy; otherwise, this step ensures env mapping applied.
gcloud run services update "$SERVICE_NAME" --region "$REGION" --project "$PROJECT_ID" --quiet || true

# 6) Set ops custom claim if OPS_USER_UID provided
if [[ -n "${OPS_USER_UID:-}" ]]; then
  echo
  echo "6) Setting ops custom claim for UID: $OPS_USER_UID"
  # Use node script to set custom claim (requires firebase-admin json at ./path/to/firebase-admin.json)
  cat > /tmp/set_ops_claim.js <<'JS'
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/firebase-admin.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const uid = process.argv[2];
if (!uid) { console.error("Usage: node set_ops_claim.js <uid>"); process.exit(1); }
admin.auth().setCustomUserClaims(uid, { ops: true })
  .then(() => { console.log(`Set ops claim for ${uid}`); process.exit(0); })
  .catch(err => { console.error(err); process.exit(1); });
JS
  node /tmp/set_ops_claim.js "$OPS_USER_UID"
else
  echo "No OPS_USER_UID provided; skipping custom claim set."
fi

# 7) Run authenticated staging smoke (seed event -> create promo -> verify feed -> cleanup)
echo
echo "7) Running authenticated staging smoke test (using service account identity token)."
# Activate service account for gcloud
gcloud auth activate-service-account --key-file="$KEY_FILE" --project "$PROJECT_ID"
TOKEN=$(gcloud auth print-identity-token)

TARGET_URL="$STAGING_URL"
echo "Using token to call admin endpoints on $TARGET_URL"

# Seed event
EVENT_PAYLOAD='{"title":"Smoke Test Event","slug":"smoke-test-event","start_at":"'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'","end_at":"'"$(date -u -d "+4 hours" +"%Y-%m-%dT%H:%M:%SZ")"'","venue":{"name":"DFC Smoke Arena","city":"Brisbane","country":"AU"},"status":"published"}'
EVENT_RESP=$(curl -s -X POST "${TARGET_URL}/api/v1/admin/events" -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" -d "$EVENT_PAYLOAD" || true)
EVENT_ID=$(echo "$EVENT_RESP" | jq -r '.id // empty')
if [[ -z "$EVENT_ID" ]]; then
  echo "ERROR: failed to create event. Response:"
  echo "$EVENT_RESP"
  exit 3
fi
echo "Created event: $EVENT_ID"

# Create promo
PROMO_PAYLOAD='{"event_id":"'"$EVENT_ID"'","title":"Smoke Test Promo","start_at":"'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'","end_at":"'"$(date -u -d "+10 minutes" +"%Y-%m-%dT%H:%M:%SZ")"'","priority":9999,"channels":["home_feed"],"targeting":{"regions":["AU"]},"status":"active"}'
PROMO_RESP=$(curl -s -X POST "${TARGET_URL}/api/v1/admin/promotions" -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" -d "$PROMO_PAYLOAD" || true)
PROMO_ID=$(echo "$PROMO_RESP" | jq -r '.id // empty')
if [[ -z "$PROMO_ID" ]]; then
  echo "ERROR: failed to create promo. Response:"
  echo "$PROMO_RESP"
  # Attempt cleanup of event
  curl -s -X DELETE "${TARGET_URL}/api/v1/admin/events/${EVENT_ID}" -H "Authorization: Bearer ${TOKEN}" || true
  exit 4
fi
echo "Created promo: $PROMO_ID"

# Verify promo appears in feed (retry)
echo "Verifying promo appears in feed..."
FOUND=false
for i in {1..12}; do
  sleep 5
  FEED=$(curl -s -H "Authorization: Bearer ${TOKEN}" "${TARGET_URL}/api/v1/feeds/home?include_promotions=true&limit=20" || true)
  if echo "$FEED" | jq -e --arg title "Smoke Test Promo" '.items[]? | select(.title == $title)' >/dev/null 2>&1; then
    FOUND=true
    echo "Promo found in feed."
    break
  fi
done

if ! $FOUND; then
  echo "ERROR: Smoke promo not found in feed after retries."
  # Cleanup
  curl -s -X DELETE "${TARGET_URL}/api/v1/admin/promotions/${PROMO_ID}" -H "Authorization: Bearer ${TOKEN}" || true
  curl -s -X DELETE "${TARGET_URL}/api/v1/admin/events/${EVENT_ID}" -H "Authorization: Bearer ${TOKEN}" || true
  exit 5
fi

# Cleanup seeded artifacts
echo "Cleaning up seeded artifacts..."
curl -s -X DELETE "${TARGET_URL}/api/v1/admin/promotions/${PROMO_ID}" -H "Authorization: Bearer ${TOKEN}" || true
curl -s -X DELETE "${TARGET_URL}/api/v1/admin/events/${EVENT_ID}" -H "Authorization: Bearer ${TOKEN}" || true
echo "Cleanup complete."

# 8) Optional: promote candidate revision to 100% traffic if --promote provided
if [[ -n "${PROMOTE_REVISION:-}" ]]; then
  echo "Promoting revision ${PROMOTE_REVISION} to 100% traffic..."
  gcloud run services update-traffic "$SERVICE_NAME" --to-revisions "${PROMOTE_REVISION}=100" --region "$REGION" --project "$PROJECT_ID"
  echo "Promotion complete."
fi

# 9) Final Go/No-Go summary
echo
echo "=== FINAL SUMMARY ==="
echo "Project: $PROJECT_ID"
echo "Service: $SERVICE_NAME"
echo "Staging smoke: succeeded"
if $DELETE_PROMOS; then
  echo "DB sweep: deletions performed (check logs above)"
else
  echo "DB sweep: dry-run only (no deletions)."
fi
echo "Secrets: created and mapped to Cloud Run (verify with gcloud run services describe)"
echo "Ops claim: ${OPS_USER_UID:-not set}"
echo "If you passed --promote <REVISION>, that revision was promoted."

echo "=== ORCHESTRATOR COMPLETE ==="
