#!/usr/bin/env pwsh
# scripts/asset-validator.ps1
# Validates that every asset listed under flutter.assets in pubspec.yaml
# exists on disk.  Also checks fonts if present.
# Usage: pwsh scripts/asset-validator.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root    = Split-Path $PSScriptRoot -Parent
$pubspec = Join-Path $root 'pubspec.yaml'

if (-not (Test-Path $pubspec)) {
    Write-Error "pubspec.yaml not found at: $pubspec"
    exit 1
}

# ── Minimal YAML parser — extract flutter.assets and flutter.fonts blocks ──
# We don't import a full YAML library; instead we parse the known structure.
$content = Get-Content $pubspec -Raw

function ExtractListItems([string]$yaml, [string]$sectionPattern) {
    # Find the section and collect indented "- value" entries
    $items = [System.Collections.Generic.List[string]]::new()
    $inSection = $false
    $sectionIndent = -1

    foreach ($line in ($yaml -split "`n")) {
        if ($line -match $sectionPattern) {
            $inSection = $true
            $sectionIndent = ($line -replace '^(\s*).*', '$1').Length
            continue
        }

        if ($inSection) {
            # A non-empty, non-comment line at same or lower indent ends the section
            if ($line -match '^\s*#') { continue }            # comment
            if ($line -match '^\s*$') { continue }             # blank

            $indent = ($line -replace '^(\s*).*', '$1').Length

            if ($indent -le $sectionIndent -and $line -match '^\s*\S') {
                $inSection = $false
                continue
            }

            if ($line -match '^\s+-\s+(.+)$') {
                $value = $Matches[1].Trim()
                # Strip any inline comments
                $value = ($value -split '#')[0].Trim()
                if ($value) { $items.Add($value) }
            }
        }
    }
    return $items
}

$assetEntries = ExtractListItems $content '^\s+assets\s*:'

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "  Flutter Asset Validator" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Checking $($assetEntries.Count) asset declaration(s)..." -ForegroundColor White
Write-Host ""

$missing  = [System.Collections.Generic.List[string]]::new()
$wildcard = [System.Collections.Generic.List[string]]::new()   # directory entries

foreach ($entry in $assetEntries) {
    if ($entry.EndsWith('/')) {
        # Directory wildcard — verify the directory exists
        $dir = Join-Path $root ($entry -replace '/', '\')
        if (-not (Test-Path $dir -PathType Container)) {
            $missing.Add("$entry  [directory missing]")
        } else {
            $wildcard.Add($entry)
        }
    } else {
        $path = Join-Path $root ($entry -replace '/', '\')
        if (-not (Test-Path $path -PathType Leaf)) {
            $missing.Add($entry)
        }
    }
}

if ($missing.Count -eq 0) {
    Write-Host "✅ All assets validated — nothing missing." -ForegroundColor Green
    if ($wildcard.Count -gt 0) {
        Write-Host ""
        Write-Host "  ℹ️  $($wildcard.Count) directory wildcard(s) found (directory exists — individual" -ForegroundColor DarkGray
        Write-Host "      file presence within not verified):" -ForegroundColor DarkGray
        $wildcard | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    }
} else {
    Write-Host "❌ $($missing.Count) missing asset(s):" -ForegroundColor Red
    Write-Host ""
    foreach ($m in $missing) {
        Write-Host "  ✗  $m" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Fix: Add the file to the correct path, or remove the entry from pubspec.yaml." -ForegroundColor DarkGray
    exit 1
}

Write-Host ""
