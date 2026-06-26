#!/usr/bin/env bash
set -euo pipefail

# --- EDIT THESE BEFORE RUNNING ---
GCP_PROJECT="${GCP_PROJECT:-your-gcp-project-id}"
GCP_REGION="${GCP_REGION:-us-central1}"
IMAGE_NAME="dfc-radar"
IMAGE_TAG="staging"
SERVICE_NAME="dfc-chuckya-radar"
AUDIT_BUCKET="gs://${GCP_PROJECT}-dfc-audit"
SECRET_NAME="dfc_jwt_private"
PRIVATE_KEY_FILE="./tools/demo_private.pem"
ALLOW_UNAUTH="${ALLOW_UNAUTH:-true}"
# ---------------------------------

echo "Project: $GCP_PROJECT  Region: $GCP_REGION"

gcloud config set project "$GCP_PROJECT"
gcloud config set run/region "$GCP_REGION"

echo "Enabling required APIs..."
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  storage-api.googleapis.com

echo "Ensure Artifact Registry repo exists..."
gcloud artifacts repositories describe dfc-repo --location="$GCP_REGION" >/dev/null 2>&1 || \
  gcloud artifacts repositories create dfc-repo --repository-format=docker --location="$GCP_REGION"

IMAGE_URI="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/dfc-repo/${IMAGE_NAME}:${IMAGE_TAG}"

echo "Building and pushing image to Artifact Registry..."
gcloud builds submit --tag "$IMAGE_URI" ./chuckya-radar/radar-server

echo "Deploying Cloud Run service $SERVICE_NAME..."
DEPLOY_CMD=(gcloud run deploy "$SERVICE_NAME"
  --image="$IMAGE_URI"
  --platform=managed
  --region="$GCP_REGION"
  --set-env-vars "NODE_ENV=staging,AUDIT_BUCKET=${AUDIT_BUCKET}")

if [ "$ALLOW_UNAUTH" = "true" ]; then
  DEPLOY_CMD+=(--allow-unauthenticated)
fi
"${DEPLOY_CMD[@]}"

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$GCP_REGION" --format="value(status.url)")
echo "Service deployed at: $SERVICE_URL"

echo "Creating audit bucket if missing..."
if ! gsutil ls -b "$AUDIT_BUCKET" >/dev/null 2>&1; then
  gsutil mb -l "$GCP_REGION" "$AUDIT_BUCKET"
fi

echo "Granting Cloud Run service account write access to audit bucket..."
SERVICE_ACCOUNT=$(gcloud run services describe "$SERVICE_NAME" --region="$GCP_REGION" --format="value(spec.template.spec.serviceAccountName)")
gsutil iam ch "serviceAccount:${SERVICE_ACCOUNT}:objectAdmin" "$AUDIT_BUCKET"

if [ -f "$PRIVATE_KEY_FILE" ]; then
  echo "Creating or updating Secret Manager secret $SECRET_NAME..."
  if ! gcloud secrets describe "$SECRET_NAME" >/dev/null 2>&1; then
    gcloud secrets create "$SECRET_NAME" --data-file="$PRIVATE_KEY_FILE"
  else
    gcloud secrets versions add "$SECRET_NAME" --data-file="$PRIVATE_KEY_FILE"
  fi
  gcloud secrets add-iam-policy-binding "$SECRET_NAME" \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/secretmanager.secretAccessor"
  echo "Secret $SECRET_NAME created and bound to $SERVICE_ACCOUNT"
else
  echo "Warning: private key file $PRIVATE_KEY_FILE not found. Skipping secret creation."
fi

echo ""
echo "==========================================="
echo "Deployment complete."
echo "Service URL: $SERVICE_URL"
echo "==========================================="
echo ""
echo "To restrict public access later run:"
echo "  gcloud run services remove-iam-policy-binding $SERVICE_NAME \\"
echo "    --member=\"allUsers\" --role=\"roles/run.invoker\" \\"
echo "    --region=$GCP_REGION --platform=managed"
