#!/usr/bin/env bash
set -euo pipefail

# Replace these values
PROJECT="your-gcp-project"
SA_NAME="dfc-ci-sa"
SA_DISPLAY_NAME="DFC CI Service Account"
KEY_OUTPUT="./dfc-ci-sa-key.json"

# Create service account
gcloud iam service-accounts create "$SA_NAME" \
  --project="$PROJECT" \
  --display-name="$SA_DISPLAY_NAME"

# Grant minimal roles required for CI pipeline
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Create and download a key (store securely)
gcloud iam service-accounts keys create "$KEY_OUTPUT" \
  --iam-account="${SA_NAME}@${PROJECT}.iam.gserviceaccount.com" \
  --project="$PROJECT"

echo "Service account key written to $KEY_OUTPUT"
echo "Upload $KEY_OUTPUT to GitHub Actions secret GCP_SERVICE_ACCOUNT_KEY (base64 or raw JSON)."
