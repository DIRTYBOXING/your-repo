#!/usr/bin/env bash
set -euo pipefail

# --- EDIT THESE BEFORE RUNNING ---
SERVICE_NAME="${SERVICE_NAME:-dfc-chuckya-radar}"
REGION="${GCP_REGION:-us-central1}"
PROJECT="${GCP_PROJECT:-your-gcp-project-id}"

# Tester emails (replace with real accounts)
OPS_EMAIL="${OPS_EMAIL:-ops_demo@example.com}"
LEGAL_EMAIL="${LEGAL_EMAIL:-legal_demo@example.com}"
# ---------------------------------

echo "=== Restricting IAM for $SERVICE_NAME ==="

# 1. Remove public access
echo "Removing public access (allUsers)..."
gcloud run services remove-iam-policy-binding "$SERVICE_NAME" \
  --member="allUsers" \
  --role="roles/run.invoker" \
  --region="$REGION" \
  --platform=managed || echo "allUsers binding not found (already private)."

# 2. Grant invoke permission to specific tester accounts
echo "Granting invoke to $OPS_EMAIL..."
gcloud run services add-iam-policy-binding "$SERVICE_NAME" \
  --member="user:$OPS_EMAIL" \
  --role="roles/run.invoker" \
  --region="$REGION" \
  --platform=managed

echo "Granting invoke to $LEGAL_EMAIL..."
gcloud run services add-iam-policy-binding "$SERVICE_NAME" \
  --member="user:$LEGAL_EMAIL" \
  --role="roles/run.invoker" \
  --region="$REGION" \
  --platform=managed

# 3. Create demo service account for automation
DEMO_SA="dfc-demo-sa"
DEMO_SA_EMAIL="${DEMO_SA}@${PROJECT}.iam.gserviceaccount.com"

echo "Creating demo service account $DEMO_SA..."
gcloud iam service-accounts create "$DEMO_SA" \
  --display-name="DFC Demo SA" \
  --project="$PROJECT" 2>/dev/null || echo "Service account already exists."

echo "Granting invoke to demo SA..."
gcloud run services add-iam-policy-binding "$SERVICE_NAME" \
  --member="serviceAccount:$DEMO_SA_EMAIL" \
  --role="roles/run.invoker" \
  --region="$REGION" \
  --platform=managed

# 4. Grant demo SA access to secrets and audit bucket
echo "Granting secret access to demo SA..."
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:$DEMO_SA_EMAIL" \
  --role="roles/secretmanager.secretAccessor"

echo "Granting audit bucket access to demo SA..."
gsutil iam ch "serviceAccount:${DEMO_SA_EMAIL}:objectAdmin" "gs://${PROJECT}-dfc-audit"

echo ""
echo "=== IAM restriction complete ==="
echo "Public access removed. Only these can invoke:"
echo "  - $OPS_EMAIL"
echo "  - $LEGAL_EMAIL"
echo "  - $DEMO_SA_EMAIL (automation)"
echo ""
echo "To revoke after demo:"
echo "  gcloud iam service-accounts delete $DEMO_SA_EMAIL --project=$PROJECT"
