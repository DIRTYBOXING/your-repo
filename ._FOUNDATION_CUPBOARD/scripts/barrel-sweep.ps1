#!/usr/bin/env pwsh
# scripts/barrel-sweep.ps1
# Scans lib/shared/services/*.dart and appends any missing exports to services.dart.
# Usage: pwsh scripts/barrel-sweep.ps1 [-DryRun]

param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root       = Split-Path $PSScriptRoot -Parent
$servicesDir = Join-Path $root 'lib\shared\services'
$barrel      = Join-Path $servicesDir 'services.dart'

if (-not (Test-Path $barrel)) {
    Write-Error "services.dart not found at: $barrel"
    exit 1
}

# ── Files to skip — non-service helpers, stubs, generated, and the barrel itself ──
$skip = @(
    'services.dart',
    'expansion_stubs.dart',
    'priority_stubs.dart',
    'integration_stubs.dart',
    'firestore_compat.dart'
)

# ── Read the barrel and collect every filename that is already exported ──
$barrelContent = Get-Content $barrel -Raw
$alreadyExported = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

$barrelContent | Select-String -Pattern "export\s+'([^']+)'" -AllMatches |
    ForEach-Object { $_.Matches } |
    ForEach-Object {
        $relative = $_.Groups[1].Value          # e.g. 'auth_service.dart' or sub/path.dart
        $filename  = Split-Path $relative -Leaf
        [void]$alreadyExported.Add($filename)
    }

# ── Find all dart files in the services directory (non-recursive by default) ──
$allDartFiles = Get-ChildItem -Path $servicesDir -Filter '*.dart' -File

$missing = [System.Collections.Generic.List[string]]::new()

foreach ($file in $allDartFiles) {
    if ($skip -contains $file.Name) { continue }
    if ($alreadyExported.Contains($file.Name)) { continue }

    # Skip files that look like they are part of a package (contain a package: import as first line)
    $firstLine = Get-Content $file.FullName -TotalCount 1
    if ($firstLine -match "^library\s") { continue }   # library declarations

    $missing.Add($file.Name)
}

if ($missing.Count -eq 0) {
    Write-Host "✅ All services are already exported in services.dart" -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "📦 Missing exports ($($missing.Count)):" -ForegroundColor Yellow
$missing | ForEach-Object { Write-Host "  + $_" -ForegroundColor Cyan }

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY RUN — no changes written." -ForegroundColor DarkGray
    exit 0
}

# ── Append missing exports to the barrel ──
$newLines = @("")
$newLines += "// Barrel Sweep — auto-added $(Get-Date -Format 'yyyy-MM-dd')"
foreach ($name in $missing) {
    $newLines += "export '$name';"
}

Add-Content -Path $barrel -Value ($newLines -join "`n")

Write-Host ""
Write-Host "✅ Appended $($missing.Count) export(s) to services.dart" -ForegroundColor Green
Write-Host "   Review for any required 'hide' clauses before committing." -ForegroundColor Yellow
