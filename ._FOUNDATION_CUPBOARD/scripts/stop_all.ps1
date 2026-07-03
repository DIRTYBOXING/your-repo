param()

$ErrorActionPreference = 'Continue'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
Set-Location $repoRoot

Write-Host 'Stopping docker compose stack...' -ForegroundColor Cyan
docker compose down | Out-Null

Write-Host 'Stopping n8n container if running...' -ForegroundColor Cyan
docker rm -f n8n | Out-Null

Write-Host 'Stopped background services' -ForegroundColor Green
