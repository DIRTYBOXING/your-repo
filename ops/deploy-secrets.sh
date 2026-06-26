#!/usr/bin/env bash
# ops/deploy-secrets.sh
# Creates/updates all Secret Manager secrets and deploys Cloud Run services
# with --set-secrets bindings.
#
# Usage:
#   export PROJECT_ID=your-gcp-project
#   export REGION=australia-southeast1
#   bash ops/deploy-secrets.sh
#
# Prerequisites: gcloud CLI authenticated, Secret Manager API enabled,
#   Cloud Run API enabled, service accounts already created.

set -euo pipefail

PROJECT_ID="${PROJECT_ID:?PROJECT_ID env var required}"
REGION="${REGION:-australia-southeast1}"

ENTITLEMENTS_SA="dfc-entitlements-sa@${PROJECT_ID}.iam.gserviceaccount.com"
WORKER_SA="dfc-worker-sa@${PROJECT_ID}.iam.gserviceaccount.com"

echo "==> Creating secrets (will skip if already exist)"

create_secret() {
  local name="$1"
  if gcloud secrets describe "$name" --project="$PROJECT_ID" &>/dev/null; then
    echo "  [skip] $name already exists"
  else
    gcloud secrets create "$name" \
      --project="$PROJECT_ID" \
      --replication-policy="automatic"
    echo "  [created] $name — add a version with:"
    echo "    echo -n '<value>' | gcloud secrets versions add $name --data-file=- --project=$PROJECT_ID"
  fi
}

create_secret STRIPE_SECRET
create_secret STRIPE_WEBHOOK_SECRET
create_secret JWT_PRIVATE_KEY
create_secret JWT_PUBLIC_KEY
create_secret REDIS_URL
create_secret DRM_LICENSE_URL
create_secret ASSETS_BUCKET
create_secret AI_ENDPOINT

echo ""
echo "==> Granting Secret Manager accessor roles to service accounts"

grant_secret_access() {
  local secret="$1"
  local sa="$2"
  gcloud secrets add-iam-policy-binding "$secret" \
    --project="$PROJECT_ID" \
    --member="serviceAccount:${sa}" \
    --role="roles/secretmanager.secretAccessor" \
    --quiet
}

for secret in STRIPE_SECRET STRIPE_WEBHOOK_SECRET JWT_PRIVATE_KEY JWT_PUBLIC_KEY REDIS_URL DRM_LICENSE_URL; do
  grant_secret_access "$secret" "$ENTITLEMENTS_SA"
done

for secret in ASSETS_BUCKET AI_ENDPOINT; do
  grant_secret_access "$secret" "$WORKER_SA"
done

echo ""
echo "==> Deploying entitlements-service with secrets"

ENTITLEMENTS_IMAGE="${ENTITLEMENTS_IMAGE:-gcr.io/${PROJECT_ID}/entitlements-service:latest}"

gcloud run deploy entitlements-service \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --image="$ENTITLEMENTS_IMAGE" \
  --platform=managed \
  --no-allow-unauthenticated \
  --service-account="$ENTITLEMENTS_SA" \
  --set-secrets="\
STRIPE_SECRET=STRIPE_SECRET:latest,\
STRIPE_WEBHOOK_SECRET=STRIPE_WEBHOOK_SECRET:latest,\
JWT_PRIVATE_KEY=JWT_PRIVATE_KEY:latest,\
JWT_PUBLIC_KEY=JWT_PUBLIC_KEY:latest,\
REDIS_URL=REDIS_URL:latest,\
DRM_LICENSE_URL=DRM_LICENSE_URL:latest" \
  --set-env-vars="TOKEN_TTL=120,JTI_TTL=180,NODE_ENV=production,FRONTEND_URL=https://datafightcentral.com" \
  --max-instances=20 \
  --timeout=60

echo ""
echo "==> Deploying poster-worker with secrets"

POSTER_IMAGE="${POSTER_IMAGE:-gcr.io/${PROJECT_ID}/poster-worker:latest}"

gcloud run deploy poster-worker \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --image="$POSTER_IMAGE" \
  --platform=managed \
  --no-allow-unauthenticated \
  --service-account="$WORKER_SA" \
  --set-secrets="ASSETS_BUCKET=ASSETS_BUCKET:latest,AI_ENDPOINT=AI_ENDPOINT:latest" \
  --max-instances=10 \
  --timeout=300

echo ""
echo "==> Done. Next: create Pub/Sub push subscriptions:"
echo ""
echo "  POSTER_URL=\$(gcloud run services describe poster-worker --region=$REGION --project=$PROJECT_ID --format='value(status.url)')"
echo ""
echo "  gcloud pubsub subscriptions create poster-generation-push \\"
echo "    --project=$PROJECT_ID \\"
echo "    --topic=poster_generation \\"
echo "    --push-endpoint=\${POSTER_URL}/pubsub \\"
echo "    --ack-deadline=60"
