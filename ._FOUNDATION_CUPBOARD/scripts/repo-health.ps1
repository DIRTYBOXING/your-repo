#!/usr/bin/env pwsh
# scripts/repo-health.ps1
# Repo health check for Data-Fight-Central.
# Run: pwsh scripts/repo-health.ps1

$root = $PSScriptRoot ? (Split-Path $PSScriptRoot -Parent) : (Get-Location).Path
$errors   = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Fail($msg)   { $errors.Add("  ❌ $msg") }
function Warn($msg)   { $warnings.Add("  ⚠️  $msg") }
function Pass($msg)   { Write-Host "  ✅ $msg" -ForegroundColor Green }

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DFC Repo Health Check" -ForegroundColor Cyan
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ── 1. Nested git repos ───────────────────────────────────────────────────
Write-Host "1. Nested git repositories" -ForegroundColor White
$nested = Get-ChildItem -Path $root -Recurse -Depth 6 -Directory -Filter ".git" -ErrorAction SilentlyContinue |
          Where-Object { $_.FullName -ne (Join-Path $root ".git") }
if ($nested) {
    foreach ($n in $nested) { Fail "Nested .git found: $($n.FullName)" }
} else { Pass "No nested git repos" }

# ── 2. Gitlinks in index ─────────────────────────────────────────────────
Write-Host "2. Gitlinks in index (160000 mode)" -ForegroundColor White
$gitlinks = git -C $root ls-tree -r HEAD --format='%(objectmode) %(path)' 2>$null | Where-Object { $_ -match '^160000' }
if ($gitlinks) {
    foreach ($g in $gitlinks) { Fail "Gitlink in index: $g" }
} else { Pass "No gitlinks in index" }

# ── 3. Orphan / stale branches ──────────────────────────────────────────
Write-Host "3. Orphan branches (no remote tracking)" -ForegroundColor White
$orphans = git -C $root branch --format='%(refname:short) %(upstream)' 2>$null |
           Where-Object { $_ -match '^\S+\s*$' } |  # upstream is blank
           Where-Object { $_ -notmatch '^(master|main|develop)' }
if ($orphans) {
    foreach ($b in $orphans) { Warn "Local branch with no upstream: $($b.Trim())" }
} else { Pass "All branches have upstream tracking" }

# ── 4. Untracked files in root ──────────────────────────────────────────
Write-Host "4. Untracked files in repo root" -ForegroundColor White
$untracked = git -C $root ls-files --others --exclude-standard --directory 2>$null |
             Where-Object { $_ -ne "" }
if ($untracked) {
    foreach ($u in $untracked) { Warn "Untracked: $u" }
} else { Pass "No untracked files" }

# ── 5. services.dart barrel completeness ────────────────────────────────
Write-Host "5. services.dart barrel coverage" -ForegroundColor White
$barrel  = Join-Path $root "lib/shared/services/services.dart"
$svcDir  = Join-Path $root "lib/shared/services"
if (Test-Path $barrel) {
    $barrelContent = Get-Content $barrel -Raw
    $missing = Get-ChildItem -Path $svcDir -Filter "*.dart" |
               Where-Object { $_.Name -ne "services.dart" } |
               Where-Object { $barrelContent -notmatch [regex]::Escape($_.Name) }
    if ($missing) {
        foreach ($m in $missing) { Warn "Not re-exported in services.dart: $($m.Name)" }
    } else { Pass "services.dart exports all service files" }
} else { Warn "services.dart barrel not found" }

# ── 6. TODO stubs (placeholder-only dart files) ─────────────────────────
Write-Host "6. TODO stub dart files" -ForegroundColor White
$stubs = Get-ChildItem -Path (Join-Path $root "lib") -Recurse -Filter "*.dart" |
         Where-Object {
             $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
             $content -and $content.Trim() -match '^// TODO Implement this library\.$'
         }
if ($stubs) {
    foreach ($s in $stubs) { Warn "Stub file: $($s.FullName.Replace($root,'').TrimStart('\/'))" }
} else { Pass "No unimplemented stub files" }

# ── 7. Large files (>5 MB committed) — uses ls-tree --long for speed ────
Write-Host "7. Large files in git history (>5 MB)" -ForegroundColor White
$largeThreshold = 5 * 1024 * 1024  # 5 MB in bytes
$large = git -C $root ls-tree -r HEAD --long 2>$null |
         Where-Object { $_ -match '^\d+\s+\S+\s+\S+\s+(\d+)\s+(.+)$' } |
         Where-Object {
             $size = [long]$Matches[1]
             $size -gt $largeThreshold
         } |
         ForEach-Object {
             if ($_ -match '^\d+\s+\S+\s+\S+\s+(\d+)\s+(.+)$') {
                 "$($Matches[2]) ($([math]::Round([long]$Matches[1]/1MB, 1)) MB)"
             }
         }
if ($large) {
    foreach ($l in $large) { Warn "Large tracked file: $l" }
} else { Pass "No tracked files over 5 MB" }

# ── Summary ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings ($($warnings.Count)):" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors ($($errors.Count)):" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    Write-Host ""
    exit 1
} else {
    Write-Host ""
    Write-Host "  ✅ Repo is healthy ($($warnings.Count) warning(s))" -ForegroundColor Green
    Write-Host ""
    exit 0
}
