#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
$warnings = @()
$blockers = @()

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "  DFC PRE-PUSH SAFETY CHECK" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/8] Checking for node_modules in staging..." -ForegroundColor Yellow
$nm = git diff --cached --name-only 2>$null | Where-Object { $_ -match 'node_modules' }
if (-not $nm) { $nm = git diff --name-only HEAD 2>$null | Where-Object { $_ -match 'node_modules' } }
if ($nm) {
    $count = ($nm | Measure-Object).Count
    $blockers += "BLOCKER: $count node_modules files detected!"
    Write-Host "  FAIL - $count node_modules files" -ForegroundColor Red
} else { Write-Host "  PASS" -ForegroundColor Green }

Write-Host "[2/8] Checking for secrets (.env, keys)..." -ForegroundColor Yellow
$secretPattern = '\.env$|\.env\.|google-services\.json|GoogleService-Info\.plist|\.key$|\.pem$|\.p12$|\.keystore$'
$secrets = git diff --cached --name-only 2>$null | Where-Object { $_ -match $secretPattern }
if (-not $secrets) { $secrets = git diff --name-only HEAD 2>$null | Where-Object { $_ -match $secretPattern } }
if ($secrets) {
    $blockers += "BLOCKER: Secret files detected"
    Write-Host "  FAIL - secrets found" -ForegroundColor Red
} else { Write-Host "  PASS" -ForegroundColor Green }

Write-Host "[3/8] Checking for build artifacts..." -ForegroundColor Yellow
$buildPattern = '^build/|\.dart_tool/|\.gradle/|/Pods/'
$builds = git diff --cached --name-only 2>$null | Where-Object { $_ -match $buildPattern }
if ($builds) {
    $blockers += "BLOCKER: Build artifact files detected"
    Write-Host "  FAIL" -ForegroundColor Red
} else { Write-Host "  PASS" -ForegroundColor Green }

Write-Host "[4/8] Checking .gitignore rules..." -ForegroundColor Yellow
$gi = Get-Content .gitignore -ErrorAction SilentlyContinue
$requiredRules = @('node_modules', '\.env', 'google-services\.json', 'GoogleService-Info\.plist')
$missingRules = @()
foreach ($rule in $requiredRules) {
    $found = $gi | Where-Object { $_ -match $rule }
    if (-not $found) { $missingRules += $rule }
}
if ($missingRules.Count -gt 0) {
    $blockers += "BLOCKER: .gitignore missing critical rules"
    Write-Host "  FAIL" -ForegroundColor Red
} else { Write-Host "  PASS" -ForegroundColor Green }

Write-Host "[5/8] Checking file count..." -ForegroundColor Yellow
$statLine = git diff --stat HEAD 2>$null | Select-Object -Last 1
if ($statLine -and $statLine -match '(\d+) files? changed') {
    $fc = [int]$Matches[1]
    if ($fc -gt 500) {
        $blockers += "BLOCKER: $fc files changed (max safe 500)"
        Write-Host "  FAIL - $fc files" -ForegroundColor Red
    } elseif ($fc -gt 200) {
        $warnings += "WARNING: $fc files changed"
        Write-Host "  WARN - $fc files" -ForegroundColor DarkYellow
    } else {
        Write-Host "  PASS - $fc files" -ForegroundColor Green
    }
} else { Write-Host "  PASS - clean" -ForegroundColor Green }

Write-Host "[6/8] Scanning for hardcoded API keys..." -ForegroundColor Yellow
$keyPatterns = @('AIza[0-9A-Za-z_-]{35}', 'sk_live_[0-9a-zA-Z]{20,}', 'ghp_[0-9a-zA-Z]{36}', 'AKIA[0-9A-Z]{16}')
$keyHits = @()
foreach ($kp in $keyPatterns) {
    $h = git diff HEAD 2>$null | Select-String -Pattern $kp -AllMatches
    if ($h) { $keyHits += $h }
}
if ($keyHits.Count -gt 0) {
    $blockers += "BLOCKER: API keys/tokens found in diff!"
    Write-Host "  FAIL" -ForegroundColor Red
} else { Write-Host "  PASS" -ForegroundColor Green }

Write-Host "[7/8] Checking branch..." -ForegroundColor Yellow
$br = git branch --show-current
if ($br -eq 'master' -or $br -eq 'main') {
    $warnings += "WARNING: On $br - use feature branch"
    Write-Host "  WARN - on $br" -ForegroundColor DarkYellow
} else { Write-Host "  PASS - on $br" -ForegroundColor Green }

Write-Host "[8/8] Checking commit quality..." -ForegroundColor Yellow
$unpushed = git log --oneline "@{u}..HEAD" 2>$null
if ($unpushed) {
    $wipPattern = '^[a-f0-9]+ (WIP|wip|fixup|squash|temp|tmp)'
    $wip = $unpushed | Where-Object { $_ -match $wipPattern }
    if ($wip) {
        $warnings += "WARNING: WIP commits found"
        Write-Host "  WARN" -ForegroundColor DarkYellow
    } else { Write-Host "  PASS" -ForegroundColor Green }
} else { Write-Host "  PASS" -ForegroundColor Green }

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
if ($blockers.Count -gt 0) {
    Write-Host "  PUSH BLOCKED" -ForegroundColor Red
    Write-Host "===========================================================" -ForegroundColor Cyan
    foreach ($b in $blockers) { Write-Host "  X $b" -ForegroundColor Red }
    foreach ($w in $warnings) { Write-Host "  ! $w" -ForegroundColor DarkYellow }
    Write-Host ""
    Write-Host "  Fix issues before pushing." -ForegroundColor Red
    exit 1
}
if ($warnings.Count -gt 0) {
    Write-Host "  PUSH OK (with warnings)" -ForegroundColor DarkYellow
    Write-Host "===========================================================" -ForegroundColor Cyan
    foreach ($w in $warnings) { Write-Host "  ! $w" -ForegroundColor DarkYellow }
    exit 0
}
Write-Host "  ALL CLEAR - SAFE TO PUSH" -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Cyan
exit 0
