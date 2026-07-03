$ErrorActionPreference = "Stop"
Write-Host "--- IGNITION: BUILDING LAUNCHPAD FOR DFC ---"

# 1. Clean workspace
Write-Host "Cleaning workspace..."
flutter clean
flutter pub get

# 2. Build Android (APK for direct sideloading and AppBundle for Play Store)
Write-Host "Building Android APK..."
flutter build apk --release --dart-define-from-file=.env.prod
Write-Host "Building Android AppBundle..."
flutter build appbundle --release --dart-define-from-file=.env.prod

# 3. Build iOS
Write-Host "Building iOS IPA..."
flutter build ios --release --no-codesign --dart-define-from-file=.env.prod

# 4. Build Web (for www.datafightcentral.com)
Write-Host "Building Web App..."
flutter build web --release --dart-define-from-file=.env.prod

Write-Host "--- LAUNCHPAD BUILDS COMPLETE ---"
Write-Host "Artifacts are ready in build/app/outputs/ and build/web/"