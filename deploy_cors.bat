@echo off
echo =============================================
echo  DFC — Deploy CORS + Security Rules
echo =============================================
echo.

REM Step 1: Deploy Storage CORS via gsutil
echo [1/3] Deploying Storage CORS configuration...
gsutil cors set storage.cors.json gs://datafightcentral.firebasestorage.app
if errorlevel 1 (
    echo WARNING: gsutil failed. Trying Firebase CLI instead...
    firebase deploy --only storage --project datafightcentral
)
echo.

REM Step 2: Deploy Firestore Rules
echo [2/3] Deploying Firestore security rules...
firebase deploy --only firestore:rules --project datafightcentral
echo.

REM Step 3: Deploy Storage Rules
echo [3/3] Deploying Storage security rules...
firebase deploy --only storage --project datafightcentral
echo.

echo =============================================
echo  DEPLOYMENT COMPLETE
echo =============================================
echo.
echo If gsutil is not installed:
echo   1. Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install
echo   2. Run: gcloud auth login
echo   3. Re-run this script
echo.
pause
