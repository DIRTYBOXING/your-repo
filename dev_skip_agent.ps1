# -------------------------------------------------
# dev_skip_agent.ps1 - start services & run tests
# (does NOT attempt to launch the Antigravity agent)
# -------------------------------------------------

function Log([string]$msg) {
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$time] $msg"
}

# 1) Ensure Stripe key (fallback for dev)
if (-not $Env:STRIPE_SECRET_KEY) {
    Log "WARNING: STRIPE_SECRET_KEY not set - using a dummy test key"
    $Env:STRIPE_SECRET_KEY = "sk_test_dummy"
}

# 2) Launch FastAPI backend (uvicorn) in background
Push-Location "$PSScriptRoot\\atlas_backend"
Log "Starting FastAPI backend (uvicorn)..."
Start-Process -FilePath "python" -ArgumentList "-m","uvicorn","atlas_backend.main:app","--reload","--host","127.0.0.1","--port","8000" -WindowStyle Hidden
Pop-Location
Start-Sleep -Seconds 3

# 3) Launch Entitlements service (Node) in background
Push-Location "$PSScriptRoot\\entitlements-service"
Log "Starting Entitlements service (node)..."
Start-Process -FilePath "node" -ArgumentList "server.js" -WindowStyle Hidden
Pop-Location
Start-Sleep -Seconds 3

# 4) Flutter - get dependencies
Push-Location "$PSScriptRoot"
if (Test-Path "pubspec.yaml") {
    Log "Running flutter pub get..."
    flutter pub get
} else {
    Log "WARNING: No pubspec.yaml found - ensure you are in the Flutter project root."
}
Pop-Location

# 5) Execute widget tests (gatekeeper)
Push-Location "$PSScriptRoot"
Log "Running PPV gatekeeper widget tests..."
$testResult = flutter test test/ppv_watch_gatekeeper_test.dart 2>&1
Pop-Location

if ($testResult -match "All tests passed!") {
    Log "OK: Widget tests passed."
} else {
    Log "FAILED: Widget tests failed. Output:"
    Write-Host $testResult
}

# 6) Quick curl sanity checks (optional)
Log "Running quick curl checks..."
curl -s -o NUL -w "GET /events -> %{http_code}\\n" http://127.0.0.1:8000/api/v1/events/ppv-ibc-03
curl -s -o NUL -w "GET /entitlements -> %{http_code}\\n" http://127.0.0.1:3000/entitlements/test-user/ppv-ibc-03
curl -s -X POST -o NUL -w "POST /checkout -> %{http_code}\\n" "http://127.0.0.1:8000/api/v1/payments/checkout/ppv-ibc-03?user_id=test-user"

Log "All done. If widget tests passed, paste the Antigravity reconnect command into the agent command box."
