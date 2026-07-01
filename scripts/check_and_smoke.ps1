#!/usr/bin/env pwsh
# scripts/check_and_smoke.ps1
# Usage: pwsh -ExecutionPolicy Bypass -File scripts/check_and_smoke.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Optional env overrides.
$base = if ($env:SMOKE_BASE) { $env:SMOKE_BASE } else { 'http://localhost' }
$entPort = if ($env:ENT_PORT) { [int]$env:ENT_PORT } else { 3001 }
$pricingPort = if ($env:PRICING_PORT) { [int]$env:PRICING_PORT } else { $entPort }
$predictorPort = if ($env:PREDICTOR_PORT) { [int]$env:PREDICTOR_PORT } else { 8090 }
$n8nPort = if ($env:N8N_PORT) { [int]$env:N8N_PORT } else { 5678 }
$requireN8n = $false
if ($env:SMOKE_REQUIRE_N8N) {
    $requireN8n = @('1', 'true', 'yes') -contains $env:SMOKE_REQUIRE_N8N.ToLowerInvariant()
}

$artifacts = Join-Path -Path (Get-Location) -ChildPath 'ci\smoke-artifacts'
New-Item -ItemType Directory -Path $artifacts -Force | Out-Null

function Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format o)] $Message"
}

function Has-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-Port {
    param(
        [string]$HostName,
        [int]$Port
    )

    try {
        $res = Test-NetConnection -ComputerName $HostName -Port $Port -WarningAction SilentlyContinue
        return [bool]$res.TcpTestSucceeded
    }
    catch {
        return $false
    }
}

function Wait-ForPort {
    param(
        [string]$HostName,
        [int]$Port,
        [int]$TimeoutSec = 30
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (Test-Port -HostName $HostName -Port $Port) {
            return $true
        }
        Start-Sleep -Seconds 1
    }

    return $false
}

function Get-PortOwners {
    param([int]$Port)

    try {
        return Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty OwningProcess -Unique
    }
    catch {
        return @()
    }
}

function Stop-PortOwners {
    param([int]$Port)

    $pids = @(Get-PortOwners -Port $Port)
    foreach ($pid in $pids) {
        if ($pid -and $pid -gt 0) {
            try {
                Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
                Log "Stopped PID $pid on port $Port"
            }
            catch {
                Log "Unable to stop PID ${pid} on port ${Port}: $_"
            }
        }
    }
}

function Test-EntitlementHealth {
    param([int]$Port)

    try {
        $uri = "http://localhost:$Port/issue"
        $body = '{"userId":"smoke-user","postId":"post-health","deviceId":"dev-health"}'
        $resp = Invoke-WebRequest -Method Post -Uri $uri -Body $body -ContentType 'application/json' -TimeoutSec 6 -ErrorAction Stop
        return $resp.StatusCode -ge 200 -and $resp.StatusCode -lt 300
    }
    catch {
        return $false
    }
}

function Start-ComposeIfPresent {
    if (-not (Has-Command -Name 'docker')) {
        Log 'Docker not found; skipping compose startup.'
        return
    }

    $livekitCompose = 'livekit/docker-compose.yml'
    if (Test-Path $livekitCompose) {
        Log "Starting compose stack from $livekitCompose"
        try {
            docker compose -f $livekitCompose up -d | Out-Host
        }
        catch {
            Log "Failed to start ${livekitCompose}: $_"
        }
    }

    if (Test-Path 'docker-compose.yml') {
        Log 'Starting root docker-compose.yml stack'
        try {
            docker compose up -d | Out-Host
        }
        catch {
            Log "Failed to start root compose stack: $_"
        }
    }
}

function Start-N8nIfMissing {
    if (-not (Has-Command -Name 'docker')) {
        return
    }

    try {
        $exists = docker ps --format "{{.Names}}" | Select-String -Pattern '(^n8n$|.*-n8n(?:-1)?$)' -Quiet
        if ($exists) {
            Log 'n8n container already running'
            return
        }

        if (-not (Test-Path 'docker-compose.yml')) {
            Log 'docker-compose.yml not found; skipping n8n startup.'
            return
        }

        Log 'Starting hardened n8n services from docker-compose.yml'
        docker compose up -d db redis n8n n8n-worker | Out-Host
    }
    catch {
        Log "Unable to start n8n services: $_"
    }
}

function Start-Entitlement {
    if (-not (Has-Command -Name 'npx')) {
        Log 'npx not found; skipping serverless offline startup.'
        return
    }

    if (Test-Port -HostName 'localhost' -Port $entPort) {
        if (Test-EntitlementHealth -Port $entPort) {
            Log "Entitlement/pricing API already listening on $entPort and healthy"
            return
        }

        Log "Port $entPort is in use but endpoint probe failed; restarting entitlement service"
        Stop-PortOwners -Port $entPort
        Stop-PortOwners -Port 3002
        Start-Sleep -Milliseconds 500
    }

    Log "Starting serverless offline on port $entPort"
    $slsOut = Join-Path $artifacts 'serverless_offline.out.log'
    $slsErr = Join-Path $artifacts 'serverless_offline.err.log'
    try {
        Start-Process -FilePath 'npx' `
            -ArgumentList "serverless offline start --stage staging --httpPort $entPort" `
            -RedirectStandardOutput $slsOut `
            -RedirectStandardError $slsErr `
            -WindowStyle Hidden
    }
    catch {
        Log "Failed to launch serverless offline: $_"
    }
}

function Start-Pricing {
    $svcPath = Join-Path (Get-Location) 'services\pricing'
    if (-not (Test-Path $svcPath)) {
        Log 'Pricing service path not found; skipping direct pricing startup.'
        return
    }

    if (Test-Port -HostName 'localhost' -Port $pricingPort) {
        Log "Pricing API already listening on $pricingPort"
        return
    }

    Log "Starting pricing service from $svcPath"
    $pricingOut = Join-Path $artifacts 'pricing_service.out.log'
    $pricingErr = Join-Path $artifacts 'pricing_service.err.log'
    try {
        Start-Process -FilePath 'pwsh' `
            -ArgumentList "-NoProfile -Command cd '$svcPath'; npm run dev" `
            -RedirectStandardOutput $pricingOut `
            -RedirectStandardError $pricingErr `
            -WindowStyle Hidden
    }
    catch {
        Log "Failed to launch pricing service: $_"
    }
}

function Start-Predictor {
    $svcPath = Join-Path (Get-Location) 'services\predictor'
    if (-not (Test-Path $svcPath)) {
        Log 'Predictor service path not found; skipping direct predictor startup.'
        return
    }

    if (Test-Port -HostName 'localhost' -Port $predictorPort) {
        Log "Predictor already listening on $predictorPort"
        return
    }

    Log "Starting predictor from $svcPath"
    $predictorOut = Join-Path $artifacts 'predictor_service.out.log'
    $predictorErr = Join-Path $artifacts 'predictor_service.err.log'

    $predictorCmd = if (Has-Command -Name 'uvicorn') {
        "cd '$svcPath'; uvicorn main:app --host 0.0.0.0 --port $predictorPort"
    }
    elseif (Has-Command -Name 'python') {
        "cd '$svcPath'; python -m uvicorn main:app --host 0.0.0.0 --port $predictorPort"
    }
    elseif (Has-Command -Name 'py') {
        "cd '$svcPath'; py -m uvicorn main:app --host 0.0.0.0 --port $predictorPort"
    }
    else {
        ''
    }

    if ([string]::IsNullOrWhiteSpace($predictorCmd)) {
        Log 'No uvicorn/python runtime found; cannot auto-start predictor.'
        return
    }

    try {
        Start-Process -FilePath 'pwsh' `
            -ArgumentList "-NoProfile -Command $predictorCmd" `
            -RedirectStandardOutput $predictorOut `
            -RedirectStandardError $predictorErr `
            -WindowStyle Hidden
    }
    catch {
        Log "Failed to launch predictor service: $_"
    }
}

function Run-Check {
    param(
        [string]$Label,
        [string]$Method,
        [string]$Url,
        [string]$Data = ''
    )

    $safeLabel = $Label -replace '[^a-zA-Z0-9_-]', '_'
    $outFile = Join-Path $artifacts "$safeLabel.txt"

    Log "Running $Label -> $Url"
    try {
        if ([string]::IsNullOrWhiteSpace($Data)) {
            & curl.exe -v -X $Method $Url 2>&1 | Tee-Object -FilePath $outFile | Out-Host
        }
        else {
            & curl.exe -v -X $Method $Url -H 'Content-Type: application/json' -d $Data 2>&1 | Tee-Object -FilePath $outFile | Out-Host
        }

        if ($LASTEXITCODE -ne 0) {
            return @{ ok = $false; file = $outFile }
        }

        $raw = Get-Content $outFile -Raw
        $is2xx = $raw -match 'HTTP/\d(?:\.\d)?\s+2\d\d'
        $hasKnownAppError = $raw -match '"errorMessage"\s*:\s*"\[504\]\s*-\s*Lambda timeout' -or
        $raw -match '"errorType"\s*:\s*"LambdaTimeoutError"' -or
        $raw -match '"error"\s*:\s*"fetch is not a function"'
        return @{ ok = ($is2xx -and -not $hasKnownAppError); file = $outFile }
    }
    catch {
        Log "Exception during ${Label}: $_"
        return @{ ok = $false; file = $outFile }
    }
}

if (-not (Has-Command -Name 'curl.exe')) {
    throw 'curl.exe is required but was not found in PATH.'
}

Log 'Starting common services (best-effort)'
Start-ComposeIfPresent
Start-N8nIfMissing
Start-Entitlement
Start-Pricing
Start-Predictor

$checks = @(
    @{ name = 'Entitlement'; host = 'localhost'; port = $entPort },
    @{ name = 'Pricing'; host = 'localhost'; port = $pricingPort },
    @{ name = 'Predictor'; host = 'localhost'; port = $predictorPort },
    @{ name = 'n8n'; host = 'localhost'; port = $n8nPort }
)

$ready = @{}
foreach ($c in $checks) {
    Log "Waiting for $($c.name) on port $($c.port) (timeout 30s)"
    $ok = Wait-ForPort -HostName $c.host -Port $c.port -TimeoutSec 30
    $ready[$c.name] = $ok
    Log "$($c.name) reachable: $ok"
}

$results = @{}

if ($ready['Entitlement']) {
    $issueUrl = "$base`:$entPort/issue"
    $results['Entitlement_Issue'] = Run-Check -Label 'Entitlement_Issue' -Method 'POST' -Url $issueUrl -Data '{"userId":"smoke-user","postId":"post-smoke","deviceId":"dev-smoke"}'
}
else {
    $results['Entitlement_Issue'] = @{ ok = $false; file = 'n/a' }
}

if ($ready['Entitlement']) {
    $issueFile = Join-Path $artifacts 'Entitlement_Issue.txt'
    $token = $null
    if (Test-Path $issueFile) {
        $content = Get-Content $issueFile -Raw
        if ($content -match '"token"\s*:\s*"([^"]+)"') {
            $token = $Matches[1]
        }
    }

    if ($token) {
        $validateUrl = "$base`:$entPort/validate"
        $payload = "{`"token`":`"$token`",`"deviceId`":`"dev-smoke`"}"
        $results['Entitlement_Validate'] = Run-Check -Label 'Entitlement_Validate' -Method 'POST' -Url $validateUrl -Data $payload
    }
    else {
        Log 'No token found from issue step; skipping validate.'
        $results['Entitlement_Validate'] = @{ ok = $false; file = 'skipped_no_token' }
    }
}
else {
    $results['Entitlement_Validate'] = @{ ok = $false; file = 'n/a' }
}

if ($ready['Pricing']) {
    $pricingUrl = "$base`:$pricingPort/pricing"
    $results['Pricing_API'] = Run-Check -Label 'Pricing_API' -Method 'POST' -Url $pricingUrl -Data '{"signals":{"buzz":0.7},"basePrice":19.99}'
}
else {
    $results['Pricing_API'] = @{ ok = $false; file = 'n/a' }
}

if ($ready['Predictor']) {
    $healthUrl = "$base`:$predictorPort/health"
    $results['Predictor_Health'] = Run-Check -Label 'Predictor_Health' -Method 'GET' -Url $healthUrl

    $predictUrl = "$base`:$predictorPort/predict"
    $results['Predictor_Predict'] = Run-Check -Label 'Predictor_Predict' -Method 'POST' -Url $predictUrl -Data '{"fighter_a":{"fighter_id":"smoke-a","name":"Smoke A"},"fighter_b":{"fighter_id":"smoke-b","name":"Smoke B"}}'
}
else {
    $results['Predictor_Health'] = @{ ok = $false; file = 'n/a' }
    $results['Predictor_Predict'] = @{ ok = $false; file = 'n/a' }
}

if ($ready['n8n']) {
    $n8nUrl = "$base`:$n8nPort/webhook/clip-created"
    $results['n8n_Clip_Webhook'] = Run-Check -Label 'n8n_Clip_Webhook' -Method 'POST' -Url $n8nUrl -Data '{"clipId":"smoke-clip"}'
}
else {
    if ($requireN8n) {
        $results['n8n_Clip_Webhook'] = @{ ok = $false; file = 'n/a' }
    }
    else {
        Log 'n8n not reachable; skipping optional n8n webhook check (set SMOKE_REQUIRE_N8N=1 to enforce).'
        $results['n8n_Clip_Webhook'] = @{ ok = $true; file = 'skipped_optional_n8n' }
    }
}

Log '---- Smoke Check Summary ----'
$failCount = 0
foreach ($name in $results.Keys) {
    $res = $results[$name]
    $status = if ($res.ok) { 'PASS' } else { 'FAIL' }
    if (-not $res.ok) {
        $failCount++
    }
    Write-Host ("{0,-25} {1,-6} {2}" -f $name, $status, $res.file)
}

if ($failCount -eq 0) {
    Log 'All checks passed.'
    exit 0
}

Log "$failCount checks failed. Artifacts saved to $artifacts"
exit 1
