# .vscode/scripts/smoke-tests.ps1
param()
$ErrorActionPreference = 'Continue'
$pass = 0; $fail = 0

function Test-Endpoint($label, $method, $uri, $body = $null, $contentType = 'application/json') {
    Write-Host "`n[$label]" -ForegroundColor Cyan
    try {
        $params = @{ Method = $method; Uri = $uri; ErrorAction = 'Stop' }
        if ($body) { $params.Body = $body; $params.ContentType = $contentType }
        $r = Invoke-RestMethod @params
        Write-Host "  PASS - $($r | ConvertTo-Json -Depth 3 -Compress)" -ForegroundColor Green
        $script:pass++
    } catch {
        Write-Host "  FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $script:fail++
    }
}

# 1. Predictor health
Test-Endpoint "Predictor /health" Get 'http://localhost:8090/health'

# 2. Maps generate
Test-Endpoint "Maps /maps/generate" Get 'http://localhost:8090/maps/generate?type=synthetic&zoom=10&x=512&y=512'

# 3. Predict event (names)
$eventBody = @{ fighters = @('Jon Jones', 'Stipe Miocic') } | ConvertTo-Json
Test-Endpoint "Predict /predict/event" Post 'http://localhost:8090/predict/event' $eventBody

# 4. Predict UFC event by ID
$ufcBody = @{ ufc_event_id = 'UFC999' } | ConvertTo-Json
Test-Endpoint "Predict /predict/event/ufc" Post 'http://localhost:8090/predict/event/ufc' $ufcBody

# 5. Poster generate
$posterBody = @{ event_id = 1; title = 'UFC 999'; fighters = @('Alex Pereira', 'Jiri Prochazka') } | ConvertTo-Json
Test-Endpoint "Poster /generate" Post 'http://localhost:8081/generate' $posterBody

# 6. Feed service health
Test-Endpoint "Feed service :8080" Get 'http://localhost:8080/health'

Write-Host "`n--- Results: $pass passed, $fail failed ---" -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Yellow' })
