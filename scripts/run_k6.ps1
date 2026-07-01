param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
Set-Location $repoRoot

$k6 = Get-Command k6 -ErrorAction SilentlyContinue
if (-not $k6) {
    Write-Host 'k6 is not installed. Install from https://k6.io/docs/get-started/installation/' -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ScriptPath)) {
    Write-Host "k6 script not found: $ScriptPath" -ForegroundColor Red
    exit 1
}

& k6 run $ScriptPath
exit $LASTEXITCODE
