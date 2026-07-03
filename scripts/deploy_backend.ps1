$ErrorActionPreference = "Stop"
Write-Host "--- DEPLOYING DFC BACKEND SERVICES ---"

# 1. Firebase Rules
Write-Host "Deploying Storage and Firestore Rules..."
firebase deploy --only firestore:rules,storage

# 2. Cloud Functions
Write-Host "Deploying Cloud Functions (Stripe, Mux)..."
cd functions
npm run build
firebase deploy --only functions

Write-Host "--- BACKEND DEPLOYMENT COMPLETE ---"
