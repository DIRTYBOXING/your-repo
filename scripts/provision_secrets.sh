#!/usr/bin/env bash
# scripts/provision_secrets.sh
# Automates the creation and uploading of GCP Service Account credentials and Secret Manager keys

set -euo pipefail

PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-your-production-project-id}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="${SERVICE_NAME:-dfc-atlas-backend}"

echo "⚙️ Setting up Service Account for GitHub Actions Integration..."

# 1. Create Deployment Service Account
if ! gcloud iam service-accounts describe "gha-deployer@$PROJECT_ID.iam.gserviceaccount.com" --project="$PROJECT_ID" &>/dev/null; then
  echo "🆕 Creating Service Account..."
  gcloud iam service-accounts create gha-deployer \
    --display-name="gha-deployer" \
    --project="$PROJECT_ID"
else
  echo "✅ Service Account 'gha-deployer' already exists."
fi

# 2. Bind Required Deployer and Accessor Roles
roles=(
  "roles/run.admin"
  "roles/datastore.user"
  "roles/secretmanager.secretAccessor"
)

for role in "${roles[@]}"; do
  echo "🔒 Binding role: $role..."
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:gha-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="$role" \
    --quiet
done

# 3. Generate Service Account JSON Credential Key
echo "🔑 Creating credential token file..."
gcloud iam service-accounts keys create gha-deployer-key.json \
  --iam-account="gha-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
  --project="$PROJECT_ID"

# 4. Upload Secret Token into GitHub Repository
if command -v gh &>/dev/null; then
  echo "📡 Uploading key token directly to GitHub Secrets using GitHub CLI..."
  gh secret set GCP_SA_KEY --body "$(cat gha-deployer-key.json)"
  echo "✅ GitHub Secrets upload complete!"
else
  echo "⚠️ Warning: GitHub CLI 'gh' is not installed. Manually upload 'gha-deployer-key.json' to GitHub Settings under standard secret key named 'GCP_SA_KEY'."
fi

# Clean up local key file immediately
rm -f gha-deployer-key.json

echo "💳 Setting up Secret Manager entries..."

# Helper to create secret in Secret Manager if not existing
create_secret() {
  local name="$1"
  if ! gcloud secrets describe "$name" --project="$PROJECT_ID" &>/dev/null; then
    gcloud secrets create "$name" --project="$PROJECT_ID" --replication-policy="automatic"
    echo "🟩 Created Secret entry: $name"
  else
    echo "✅ Secret entry already exists: $name"
  fi
}

create_secret "FIREBASE_ADMIN_CREDENTIALS_JSON"
create_secret "STRIPE_SECRET_KEY"
create_secret "REDIS_URL"

echo "ℹ️ Populate individual secrets using: gcloud secrets versions add [SECRET_NAME] --data-file=path/to/secured/value"
