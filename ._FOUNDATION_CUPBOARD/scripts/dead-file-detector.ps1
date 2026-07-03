#!/usr/bin/env pwsh
# scripts/dead-file-detector.ps1
# Finds Dart, TypeScript, and JavaScript files that are never imported/referenced.
# Usage: pwsh scripts/dead-file-detector.ps1 [-IncludeTs] [-Verbose]

param(
    [switch]$IncludeTs,     # also scan TS/JS files (slower)
    [switch]$Verbose        # show all files being scanned
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent

function Write-Section($title) {
    Write-Host ""
    Write-Host "── $title ──" -ForegroundColor White
}

# ────────────────────────────────────────────────
# DART dead-file scan
# ────────────────────────────────────────────────
Write-Section "Dart dead-file scan (lib/)"

$libDir = Join-Path $root 'lib'
$dartFiles = Get-ChildItem -Path $libDir -Recurse -Filter '*.dart' -File

# Build a set of all import targets referenced across all dart files
$allImportedPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($file in $dartFiles) {
    $lines = Get-Content $file.FullName -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        # Match: import 'package:datafightcentral/...'; or import '../path/file.dart';
        if ($line -match "(?:import|export)\s+'([^']+\.dart)'") {
            $target = $Matches[1]
            # Normalise package: imports to relative paths
            if ($target -match "^package:datafightcentral/(.+)$") {
                $rel = $Matches[1] -replace '/', '\'
                [void]$allImportedPaths.Add($rel)
            } elseif (-not ($target -match "^package:")) {
                # Relative import — store the basename for a quick check
                [void]$allImportedPaths.Add((Split-Path $target -Leaf))
            }
        }
    }
}

# Known entry-points that are never imported but are roots
$dartEntryPoints = @('main.dart', 'firebase_options.dart', 'services.dart')

$deadDart = [System.Collections.Generic.List[string]]::new()

foreach ($file in $dartFiles) {
    $name = $file.Name
    if ($dartEntryPoints -contains $name) { continue }
    # If nothing imports this file by name, flag it
    if (-not $allImportedPaths.Contains($name)) {
        $rel = $file.FullName.Replace($root + '\', '')
        $deadDart.Add($rel)
        if ($Verbose) { Write-Host "  ? $rel" -ForegroundColor DarkYellow }
    }
}

if ($deadDart.Count -eq 0) {
    Write-Host "  ✅ No unreferenced Dart files detected" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  $($deadDart.Count) potentially unreferenced Dart file(s):" -ForegroundColor Yellow
    $deadDart | Sort-Object | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkYellow }
    Write-Host ""
    Write-Host "  NOTE: Files that are only referenced via barrel exports or GoRouter" -ForegroundColor DarkGray
    Write-Host "        registrations will appear here — review before deleting." -ForegroundColor DarkGray
}

# ────────────────────────────────────────────────
# TypeScript / JavaScript dead-file scan (optional)
# ────────────────────────────────────────────────
if ($IncludeTs) {
    Write-Section "TypeScript / JavaScript dead-file scan (src/, functions/)"

    $scanDirs = @(
        (Join-Path $root 'src'),
        (Join-Path $root 'functions')
    ) | Where-Object { Test-Path $_ }

    $tsFiles = $scanDirs | ForEach-Object {
        Get-ChildItem -Path $_ -Recurse -Include '*.ts','*.js','*.mjs' -File |
            Where-Object { $_.FullName -notmatch '\\node_modules\\' }
    }

    $allTsImported = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($file in $tsFiles) {
        $lines = Get-Content $file.FullName -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            if ($line -match """(?:import|require)\s*(?:from\s*)?['""]([^'""]+)['""]") {
                [void]$allTsImported.Add((Split-Path $Matches[1] -Leaf))
            }
        }
    }

    $tsEntryPoints = @('index.ts','index.js','index.mjs','publish.ts','handler.ts','handler.js')
    $deadTs = [System.Collections.Generic.List[string]]::new()

    foreach ($file in $tsFiles) {
        $name = $file.Name
        $nameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($name)
        if ($tsEntryPoints -contains $name) { continue }
        if (-not ($allTsImported.Contains($name) -or $allTsImported.Contains($nameNoExt))) {
            $rel = $file.FullName.Replace($root + '\', '')
            $deadTs.Add($rel)
        }
    }

    if ($deadTs.Count -eq 0) {
        Write-Host "  ✅ No unreferenced TS/JS files detected" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $($deadTs.Count) potentially unreferenced TS/JS file(s):" -ForegroundColor Yellow
        $deadTs | Sort-Object | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkYellow }
    }
}

Write-Host ""
