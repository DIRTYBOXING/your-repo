param(
    [int]$Timeout = 60,
    [int]$Retries = 3
)

$ErrorActionPreference = 'Stop'

$entitlementUrl = if ($env:ENTITLEMENT_URL) { $env:ENTITLEMENT_URL } else { 'http://localhost:3001' }
$pricingUrl = if ($env:PRICING_URL) { $env:PRICING_URL } else { 'http://localhost:3001' }
$predictorUrl = if ($env:PREDICTOR_URL) { $env:PREDICTOR_URL } else { 'http://localhost:8090' }
$n8nWebhookUrl = if ($env:N8N_WEBHOOK_URL) { $env:N8N_WEBHOOK_URL } else { 'http://localhost:5678/webhook/clip-created' }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
Set-Location $repoRoot

$artifacts = Join-Path $repoRoot 'ci/smoke-artifacts'
New-Item -ItemType Directory -Force -Path $artifacts | Out-Null

$pass = 0
$fail = 0
$results = @()

function Test-ServiceReachable {
    param(
        [string]$Name,
        [string]$Url
    )

    $statusCode = & curl.exe -s -o NUL -w "%{http_code}" "$Url" --connect-timeout 3 --max-time 8
    return ($statusCode -ne '000')
}

function Invoke-HttpCheck {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Method = 'GET',
        [string]$Body = ''
    )

    $safeName = ($Name -replace '\s+', '_')
    $respFile = Join-Path $artifacts "$safeName.json"

    $attempt = 0
    $ok = $false
    $statusCode = '000'

    while ($attempt -lt $Retries) {
        $attempt++

        if ($Method -eq 'POST') {
            $statusCode = & curl.exe -s -o "$respFile" -w "%{http_code}" -X POST "$Url" -H "Content-Type: application/json" -d "$Body" --connect-timeout 5 --max-time 15
        } else {
            $statusCode = & curl.exe -s -o "$respFile" -w "%{http_code}" "$Url" --connect-timeout 5 --max-time 15
        }

        if ($statusCode -match '^2') {
            $ok = $true
            break
        }

        Start-Sleep -Seconds 2
    }

    if ($ok) {
        Write-Host "  PASS: $Name (HTTP $statusCode)" -ForegroundColor Green
        $script:pass++
        $script:results += @{ name = $Name; status = 'pass'; http = [int]$statusCode }
    } else {
        Write-Host "  FAIL: $Name (HTTP $statusCode after $Retries attempts)" -ForegroundColor Red
        $script:fail++
        $script:results += @{ name = $Name; status = 'fail'; http = [int]$statusCode }
    }
}

Write-Host '============================='
Write-Host 'DFC Smoke Test Suite (Windows)'
Write-Host '============================='

$missing = @()
if (-not (Test-ServiceReachable -Name 'entitlement/pricing api' -Url "$entitlementUrl/issue")) {
    $missing += "Serverless API not reachable at $entitlementUrl (start Serverless Offline on port 3001)."
}
if (-not (Test-ServiceReachable -Name 'predictor api' -Url "$predictorUrl/health")) {
    $missing += "Predictor not reachable at $predictorUrl (start docker compose predictor service or local predictor process)."
}
if (-not (Test-ServiceReachable -Name 'n8n' -Url "$n8nWebhookUrl")) {
    $missing += "n8n webhook host not reachable at $n8nWebhookUrl (start n8n on port 5678)."
}

if ($missing.Count -gt 0) {
    Write-Host ''
    Write-Host 'Preflight failed: required local services are offline.' -ForegroundColor Yellow
    foreach ($msg in $missing) {
        Write-Host " - $msg" -ForegroundColor Yellow
    }
    throw 'SMOKE TEST BLOCKED: start required local services first.'
}

Write-Host '[1/6] Entitlement - Issue Token'
Invoke-HttpCheck -Name 'issue_token' -Url "$entitlementUrl/issue" -Method 'POST' -Body '{"userId":"smoke-user-1","postId":"smoke-ppv-1","deviceId":"smoke-dev-1","ttl":300}'

Write-Host '[2/6] Entitlement - Validate Token'
$token = ''
$issueTokenFile = Join-Path $artifacts 'issue_token.json'
if (Test-Path $issueTokenFile) {
    try {
        $token = (Get-Content $issueTokenFile -Raw | ConvertFrom-Json).token
    } catch {
        $token = ''
    }
}
if ($token) {
    Invoke-HttpCheck -Name 'validate_token' -Url "$entitlementUrl/validate" -Method 'POST' -Body ("{`"token`":`"$token`",`"deviceId`":`"smoke-dev-1`"}")
} else {
    Write-Host '  SKIP: validate_token (no token from issue)' -ForegroundColor Yellow
    $results += @{ name = 'validate_token'; status = 'skip' }
}

Write-Host '[3/6] Dynamic Pricing'
Invoke-HttpCheck -Name 'pricing_api' -Url "$pricingUrl/pricing" -Method 'POST' -Body '{"eventId":"smoke-ppv-1","userId":"smoke-user-1","basePrice":19.99,"signals":{"timeToEventHours":12,"viewsLastHour":100}}'

Write-Host '[4/6] Predictor Health'
Invoke-HttpCheck -Name 'predictor_health' -Url "$predictorUrl/health" -Method 'GET'

Write-Host '[5/6] Predictor Predict'
Invoke-HttpCheck -Name 'predictor_predict' -Url "$predictorUrl/predict" -Method 'POST' -Body '{"fighter_a":{"name":"Fighter A","wins":15,"losses":2,"style":"striker"},"fighter_b":{"name":"Fighter B","wins":12,"losses":4,"style":"grappler"}}'

Write-Host '[6/6] n8n Clip Webhook'
Invoke-HttpCheck -Name 'n8n_clip_webhook' -Url $n8nWebhookUrl -Method 'POST' -Body '{"clipId":"smoke-clip-1","s3Url":"https://example.com/test.mp4","title":"Smoke Test Highlight","creatorId":"creator-1"}'

Write-Host "Results: $pass passed, $fail failed"

$resultPayload = @{
    timestamp = (Get-Date).ToUniversalTime().ToString('o')
    passed = $pass
    failed = $fail
    total = ($pass + $fail)
    checks = $results
}

($resultPayload | ConvertTo-Json -Depth 8) | Set-Content -Path (Join-Path $artifacts 'smoke_results.json')
Write-Host "Artifacts saved to $artifacts"

if ($fail -gt 0) {
    throw 'SMOKE TEST FAILED'
}

Write-Host 'SMOKE TEST PASSED' -ForegroundColor Green
