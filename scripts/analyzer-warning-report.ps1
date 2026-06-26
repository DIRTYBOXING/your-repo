#!/usr/bin/env pwsh
# Runs flutter analyze in warn-only mode and writes a CI summary.
# This script never fails the pipeline; it is visibility-only for staged strictness.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$output = & flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1
$exitCode = $LASTEXITCODE

# Normalize to string lines so counting logic is stable for 0/1/N matches.
$lines = @($output | ForEach-Object { "$_" })

# Echo analyzer output for raw logs
$lines | ForEach-Object { Write-Output $_ }

$errorCount = ($lines | Where-Object { $_ -match '^\s*error\s*[-:]' } | Measure-Object).Count
$warningCount = ($lines | Where-Object { $_ -match '^\s*warning\s*[-:]' } | Measure-Object).Count
$infoCount = ($lines | Where-Object { $_ -match '^\s*info\s*[-:]' } | Measure-Object).Count

# Build a per-rule breakdown from analyzer lines ending in "- rule_name"
$ruleCounts = @{}
foreach ($line in $lines) {
    if ($line -match '-\s+([a-z0-9_]+)\s*$') {
        $rule = $Matches[1]
        if ($ruleCounts.ContainsKey($rule)) {
            $ruleCounts[$rule]++
        } else {
            $ruleCounts[$rule] = 1
        }
    }
}

$topRules = $ruleCounts.GetEnumerator() |
    Sort-Object -Property Value -Descending |
    Select-Object -First 20

# Phase C ratchet candidates: rules currently configured in analysis_options
# that show zero hits in the current analyzer run.
$strictRules = @(
    'avoid_print',
    'prefer_final_locals',
    'always_declare_return_types',
    'avoid_dynamic_calls',
    'avoid_empty_else',
    'avoid_redundant_argument_values',
    'avoid_returning_null_for_future',
    'avoid_slow_async_io',
    'cancel_subscriptions',
    'close_sinks',
    'prefer_const_constructors',
    'prefer_const_literals_to_create_immutables',
    'unnecessary_lambdas',
    # Phase B2 candidates
    'avoid_void_async',
    'prefer_void_to_null',
    'no_adjacent_strings_in_list',
    'avoid_shadowing_type_parameters',
    'use_rethrow_when_possible',
    'avoid_renaming_method_parameters',
    'unnecessary_null_aware_assignments',
    'unnecessary_null_checks'
)

$ratchetCandidates = $strictRules |
    Where-Object { -not $ruleCounts.ContainsKey($_) } |
    Sort-Object

$nextCycleTargets = $strictRules |
    Where-Object { $ruleCounts.ContainsKey($_) } |
    ForEach-Object {
        [pscustomobject]@{
            Rule = $_
            Hits = $ruleCounts[$_]
        }
    } |
    Sort-Object -Property Hits, Rule |
    Select-Object -First 10

$topRulesMd = if ($topRules) {
    ($topRules | ForEach-Object { "| $($_.Name) | $($_.Value) |" }) -join "`n"
} else {
    '| (none) | 0 |'
}

$ratchetMd = if ($ratchetCandidates) {
    ($ratchetCandidates | ForEach-Object { "- $_" }) -join "`n"
} else {
    '- (none yet)'
}

$nextCycleMd = if ($nextCycleTargets) {
    ($nextCycleTargets | ForEach-Object { "| $($_.Rule) | $($_.Hits) |" }) -join "`n"
} else {
    '| (none) | 0 |'
}

$summary = @"
## Dart Analyzer Strictness (Warn-Only)

| Metric | Count |
|--------|-------|
| Errors | $errorCount |
| Warnings | $warningCount |
| Infos | $infoCount |
| Analyzer Exit Code | $exitCode |

Phase: B (visibility-only)
Policy: This step does not fail CI while strictness is being rolled out.

### Top Lint Rules By Hit Count

| Rule | Hits |
|------|------|
$topRulesMd

### Phase C Ratchet Candidates (0 Hits This Run)

$ratchetMd

### Next Cycle Burndown Targets (Lowest Non-Zero Tracked Rules)

| Rule | Hits |
|------|------|
$nextCycleMd
"@

if ($env:GITHUB_STEP_SUMMARY) {
    $summary | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Encoding utf8 -Append
}

# Write a local markdown report for optional artifact publishing.
$reportDir = Join-Path $PWD 'reports'
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir | Out-Null
}
$reportPath = Join-Path $reportDir 'analyzer-ratchet-candidates.md'
$summary | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "Analyzer summary: errors=$errorCount warnings=$warningCount infos=$infoCount exitCode=$exitCode"
Write-Host "Ratchet candidates: $($ratchetCandidates.Count)"
Write-Host "Report written: $reportPath"

# Always succeed for staged rollout.
exit 0
