# .vscode/scripts/recreate-worker.ps1
# Rotates Firebase credentials into the dfc-secrets named Docker volume and
# recreates the auto-clip-worker. Uses docker cp so Docker Desktop Windows
# bind-mount EISDIR quirks never affect credential delivery.
param(
    # Skip the Downloads search and just re-push the existing .secrets file
    [switch]$NoDownload
)
$ErrorActionPreference = 'Stop'

$REVOKED_KEY_ID = 'f3de8e87791656f3a6a8222bce53e286cd2a0e34'
$VOLUME_NAME    = 'dfc-secrets'
$VOLUME_PATH    = '/vol/dfc-firebase-credentials.json'
$WORKER_NAME    = 'data-fight-central-auto-clip-worker-1'

$repoRoot  = Resolve-Path -Path (Join-Path $PSScriptRoot "..\..")
$secretsDir = Join-Path $repoRoot ".secrets"
$credFile   = Join-Path $secretsDir "dfc-firebase-credentials.json"

Write-Host "=== DFC: Recreate Auto-Clip Worker ===" -ForegroundColor Cyan
Write-Host "Repo root : $repoRoot"

# ── 1. Optionally pull newest key from Downloads ─────────────────────────────
if (-not $NoDownload) {
    $downloadPattern = "$env:USERPROFILE\Downloads\datafightcentral-*.json"
    $latest = Get-ChildItem -Path $downloadPattern -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($latest) {
        $keyData = Get-Content $latest.FullName | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($keyData -and $keyData.private_key_id -eq $REVOKED_KEY_ID) {
            Write-Host "ERROR: Newest download is the REVOKED key ($REVOKED_KEY_ID). Download a new key first." -ForegroundColor Red
            exit 1
        }
        New-Item -ItemType Directory -Force -Path $secretsDir | Out-Null
        Copy-Item -Path $latest.FullName -Destination $credFile -Force
        Write-Host "Copied  $($latest.Name) -> .secrets/dfc-firebase-credentials.json" -ForegroundColor Green
        Write-Host "Key ID  $($keyData.private_key_id)" -ForegroundColor Green
    } else {
        Write-Host "No datafightcentral-*.json in Downloads — using existing .secrets file." -ForegroundColor Yellow
    }
}

# ── 2. Verify local file exists and is not revoked ───────────────────────────
if (-not (Test-Path $credFile)) {
    Write-Host "ERROR: No credentials file at $credFile" -ForegroundColor Red
    exit 1
}
$existing = Get-Content $credFile | ConvertFrom-Json
if ($existing.private_key_id -eq $REVOKED_KEY_ID) {
    Write-Host "ERROR: .secrets/dfc-firebase-credentials.json still has the REVOKED key. Replace it first." -ForegroundColor Red
    exit 1
}
Write-Host "Active key: $($existing.private_key_id)" -ForegroundColor Green

# ── 3. Ensure named volume exists ────────────────────────────────────────────
$volExists = docker volume inspect $VOLUME_NAME 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating Docker volume $VOLUME_NAME..." -ForegroundColor Cyan
    docker volume create $VOLUME_NAME | Out-Null
}

# ── 4. Push credentials into the named volume via docker cp ─────────────────
#      This avoids Windows bind-mount EISDIR entirely.
Write-Host "Refreshing $VOLUME_NAME volume..." -ForegroundColor Cyan
$tempName = "dfc-secrets-refresh-$(Get-Random)"
docker run -d --name $tempName -v "${VOLUME_NAME}:/vol" alpine sleep 30 | Out-Null
try {
    docker cp $credFile "${tempName}:${VOLUME_PATH}"
    Write-Host "Volume refreshed." -ForegroundColor Green
} finally {
    docker rm -f $tempName | Out-Null
}

# ── 5. Recreate worker ───────────────────────────────────────────────────────
Write-Host "`nRecreating auto-clip-worker..." -ForegroundColor Cyan
Push-Location $repoRoot
try {
    docker-compose up -d --no-deps --force-recreate auto-clip-worker
} finally {
    Pop-Location
}

# ── 6. Verify startup ────────────────────────────────────────────────────────
Write-Host "`nWaiting for worker to start..." -ForegroundColor Cyan
Start-Sleep -Seconds 6
$logs = docker logs $WORKER_NAME --tail 20 2>&1
Write-Host $logs

if ($logs -match 'firebase_initialized') {
    Write-Host "`nFIREBASE INITIALIZED - worker is healthy." -ForegroundColor Green
} elseif ($logs -match 'firebase_init_failed') {
    Write-Host "`nWARNING: firebase_init_failed - check volume and credentials." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nWorker started (Firebase status unknown - check logs above)." -ForegroundColor Yellow
}
