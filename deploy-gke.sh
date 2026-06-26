#!/bin/bash
# Deploy to GKE with autonomous health monitoring

set -e

PROJECT_ID="${GCP_PROJECT_ID:-datafightcentral}"
CLUSTER_NAME="dfc-prod"
REGION="australia-southeast1"
IMAGE_REGISTRY="ghcr.io/yourusername"

echo "🚀 Deploying DFC to GKE..."

# Create cluster if not exists
if ! gcloud container clusters describe $CLUSTER_NAME --region=$REGION 2>/dev/null; then
  echo "📦 Creating GKE cluster..."
  gcloud container clusters create $CLUSTER_NAME \
    --region=$REGION \
    --num-nodes=3 \
    --machine-type=n2-standard-4 \
    --enable-autoscaling \
    --min-nodes=3 \
    --max-nodes=20 \
    --enable-autorepair \
    --enable-autoupgrade \
    --enable-ip-alias \
    --enable-stackdriver-kubernetes
fi

# Get cluster credentials
echo "🔐 Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION

# Create namespace
echo "📋 Creating dfc namespace..."
kubectl create namespace dfc --dry-run=client -o yaml | kubectl apply -f -

# Create secrets from GitHub Actions
echo "🔑 Creating secrets..."
kubectl create secret generic dfc-secrets \
  --from-literal=STRIPE_SECRET="$STRIPE_SECRET" \
  --from-literal=JWT_PRIVATE_KEY="$JWT_PRIVATE_KEY" \
  --from-literal=OPENAI_API_KEY="$OPENAI_API_KEY" \
  -n dfc \
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy services
echo "🎯 Deploying services..."
kubectl apply -f k8s/dfc-deployment.yaml

# Wait for rollout
echo "⏳ Waiting for deployments to stabilize..."
kubectl rollout status deployment/ingest -n dfc --timeout=5m
kubectl rollout status deployment/entitlements -n dfc --timeout=5m
kubectl rollout status deployment/predictor -n dfc --timeout=5m

# Check service health
echo "✅ Checking service health..."
kubectl get pods -n dfc
kubectl get svc -n dfc

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📊 Monitoring dashboard:"
echo "   kubectl port-forward -n dfc svc/prometheus 9090:9090"
echo "   http://localhost:9090"
echo ""
echo "🔍 View logs:"
echo "   kubectl logs -f -n dfc deployment/ingest"
echo "   kubectl logs -f -n dfc deployment/entitlements"
echo "   kubectl logs -f -n dfc deployment/predictor"
