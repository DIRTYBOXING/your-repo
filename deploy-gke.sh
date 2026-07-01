#!/bin/bash
# Deploy DFC to GKE with autonomous health monitoring
set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-datafightcentral}"
CLUSTER_NAME="dfc-prod"
REGION="australia-southeast1"
IMAGE_REGISTRY="${IMAGE_REGISTRY:-ghcr.io/yourusername}"

echo "🚀 Deploying DFC to GKE..."

# Create cluster if not exists
if ! gcloud container clusters describe "$CLUSTER_NAME" --region="$REGION" >/dev/null 2>&1; then
  echo "📦 Creating GKE cluster..."
  gcloud container clusters create "$CLUSTER_NAME" \
    --region="$REGION" \
    --num-nodes=3 \
    --machine-type=n2-standard-4 \
    --enable-autoscaling \
    --min-nodes=3 \
    --max-nodes=20 \
    --enable-autorepair \
    --enable-autoupgrade \
    --enable-ip-alias \
    --enable-stackdriver-kubernetes \
    --workload-pool="${PROJECT_ID}.svc.id.goog"
fi

# Get cluster credentials
echo "🔐 Getting cluster credentials..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --region="$REGION"

# Create namespace
echo "📋 Creating dfc namespace..."
kubectl create namespace dfc --dry-run=client -o yaml | kubectl apply -f -

# Create secrets from env
echo "🔑 Creating secrets..."
kubectl create secret generic dfc-secrets \
  --from-literal=POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-dfc-local-postgres-change-me}" \
  --from-literal=JWT_PRIVATE_KEY="${JWT_PRIVATE_KEY:-REPLACE_WITH_PRIVATE_PEM}" \
  --from-literal=JWT_PUBLIC_KEY="${JWT_PUBLIC_KEY:-REPLACE_WITH_PUBLIC_PEM}" \
  --from-literal=OPENAI_API_KEY="${OPENAI_API_KEY:-}" \
  --from-literal=STRIPE_SECRET="${STRIPE_SECRET:-}" \
  --from-literal=GEMINI_KEY="${GEMINI_KEY:-}" \
  --from-literal=GOOGLE_AI_KEY="${GOOGLE_AI_KEY:-}" \
  --from-literal=ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
  --from-literal=MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-}" \
  -n dfc \
  --dry-run=client -o yaml | kubectl apply -f -

# Substitute image registry in k8s manifest
echo "🖼️ Patching image registry..."
sed -i "s#REPLACE_WITH_REGISTRY#${IMAGE_REGISTRY}#g" k8s/dfc-deployment.yaml || true

# Apply network policy
echo "🔐 Applying network policies..."
kubectl apply -f k8s/network-policy.yaml || true

# Deploy services
echo "🎯 Deploying services..."
kubectl apply -f k8s/dfc-deployment.yaml

# Wait for rollouts
echo "⏳ Waiting for rollouts..."
for deployment in dfc-postgres dfc-redis dfc-minio dfc-python-ai dfc-backend dfc-inference dfc-promotion dfc-gateway; do
  kubectl rollout status deployment/"$deployment" -n dfc --timeout=10m || {
    echo "❌ Rollout failed for $deployment — rolling back"
    kubectl rollout undo deployment/"$deployment" -n dfc
    exit 1
  }
done

# Health check
echo "✅ Checking service health..."
kubectl get pods -n dfc
kubectl get svc -n dfc
kubectl get hpa -n dfc
kubectl get ingress -n dfc

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "🌐 Ingress host: api.datafightcentral.com"
echo ""
echo "📊 Useful commands:"
echo "   kubectl get pods -n dfc"
echo "   kubectl get svc -n dfc"
echo "   kubectl get hpa -n dfc"
echo "   kubectl get ingress -n dfc"
echo "   kubectl logs -f -n dfc deployment/dfc-backend"
echo "   kubectl rollout status deployment/dfc-backend -n dfc"
