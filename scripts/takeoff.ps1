$ErrorActionPreference = "Stop"
Write-Host "🚀 INITIATING BOOSTER SEQUENCE: DEPLOYING TO WWW.DATAFIGHTCENTRAL.COM 🚀"

Write-Host "1. Compiling Flutter Web (Release Mode)..."
flutter build web --release --dart-define-from-file=.env.prod

Write-Host "2. Deploying to Firebase Global CDN..."
firebase deploy --only hosting

Write-Host "🚀 TOUCHDOWN! PLATFORM IS LIVE ON THE NET. 🚀"
