#!/usr/bin/env pwsh
# scripts/missing-import-scan.ps1
# Scans Dart files for import/export statements that reference files that
# do not exist on disk, and reports orphaned imports.
# Usage: pwsh scripts/missing-import-scan.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root   = Split-Path $PSScriptRoot -Parent
$libDir = Join-Path $root 'lib'

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

$dartFiles = Get-ChildItem -Path $libDir -Recurse -Filter '*.dart' -File

foreach ($file in $dartFiles) {
    $lines   = Get-Content $file.FullName -ErrorAction SilentlyContinue
    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
        # Skip package: and dart: imports — those are resolved by pub
        if ($line -match "(?:import|export)\s+'((?!package:|dart:)[^']+\.dart)'") {
            $importPath = $Matches[1]

            # Resolve relative to the current file's directory
            $fileDir     = Split-Path $file.FullName -Parent
            $resolved    = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($fileDir, $importPath))

            if (-not (Test-Path $resolved)) {
                $results.Add([PSCustomObject]@{
                    File       = $file.FullName.Replace($root + '\', '')
                    Line       = $lineNum
                    Import     = $importPath
                    Resolved   = $resolved.Replace($root + '\', '')
                })
            }
        }
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "  Missing-Import Scan" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""

if ($results.Count -eq 0) {
    Write-Host "✅ All relative imports resolve to existing files." -ForegroundColor Green
} else {
    Write-Host "❌ $($results.Count) broken import(s) found:" -ForegroundColor Red
    Write-Host ""
    foreach ($r in $results) {
        Write-Host "  $($r.File):$($r.Line)" -ForegroundColor Yellow
        Write-Host "    import '$($r.Import)'" -ForegroundColor White
        Write-Host "    → Missing: $($r.Resolved)" -ForegroundColor Red
        Write-Host ""
    }
    Write-Host "Fix: Update the import path or create the missing file." -ForegroundColor DarkGray
    exit 1
}

Write-Host ""
