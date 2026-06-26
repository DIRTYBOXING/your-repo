#!/usr/bin/env bash
# scripts/deploy.sh — Full deployment pipeline for DataFightCentral
# Usage:
#   export PROJECT_ID=datafightcentral
#   export REGION=australia-southeast1
#   bash scripts/deploy.sh [--skip-tests] [--skip-flutter]
set -euo pipefail

PROJECT_ID="${PROJECT_ID:?PROJECT_ID env var required}"
REGION="${REGION:-australia-southeast1}"
SKIP_TESTS=false
SKIP_FLUTTER=false

for arg in "$@"; do
  case $arg in
    --skip-tests) SKIP_TESTS=true ;;
    --skip-flutter) SKIP_FLUTTER=true ;;
  esac
done

echo "═══════════════════════════════════════════════════"
echo "  DFC Deploy — Project: $PROJECT_ID  Region: $REGION"
echo "═══════════════════════════════════════════════════"

# 1. Flutter web build
if [ "$SKIP_FLUTTER" = false ]; then
  echo "▸ Building Flutter web..."
  flutter pub get
  if [ "$SKIP_TESTS" = false ]; then
    flutter test --reporter expanded || echo "⚠ Some tests failed — review output"
  fi
  flutter build web --release --no-tree-shake-icons
  echo "✓ Flutter web build complete"
fi

# 2. Deploy Cloud Run services via Cloud Build
echo "▸ Submitting Cloud Build..."
gcloud builds submit \
  --project="$PROJECT_ID" \
  --config=cloudbuild.yaml \
  --substitutions=_REGION="$REGION"
echo "✓ Cloud Run services deployed"

# 3. Deploy Firebase (hosting + functions + indexes + rules)
echo "▸ Deploying Firebase..."
firebase deploy \
  --project="$PROJECT_ID" \
  --only hosting,functions,firestore:indexes,firestore:rules,storage
echo "✓ Firebase deployed"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✓ Deployment complete"
echo "═══════════════════════════════════════════════════"
