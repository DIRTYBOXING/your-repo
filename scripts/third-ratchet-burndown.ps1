#!/usr/bin/env pwsh
# Generates a focused burn-down report for third-ratchet rules.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$targetRules = @(
    'avoid_void_async',
    'no_adjacent_strings_in_list',
    'unnecessary_null_checks'
)

$output = & flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1
$exitCode = $LASTEXITCODE
$lines = @($output | ForEach-Object { "$_" })

$findings = foreach ($line in $lines) {
    # Capture from the right so message text never bleeds into the file path.
    if ($line -match ' - ([^\s]+):(\d+):(\d+) - ([a-z0-9_]+)\s*$') {
        $file = $Matches[1]
        $lineNo = [int]$Matches[2]
        $colNo = [int]$Matches[3]
        $rule = $Matches[4]

        if ($targetRules -contains $rule) {
            [pscustomobject]@{
                File = $file
                Line = $lineNo
                Column = $colNo
                Rule = $rule
                Raw = $line.Trim()
            }
        }
    }
}

$ruleCounts = @{}
foreach ($rule in $targetRules) {
    $ruleCounts[$rule] = @($findings | Where-Object { $_.Rule -eq $rule }).Count
}

$fileCounts = $findings |
    Group-Object -Property File |
    Sort-Object -Property Count -Descending

$hotspotsByRule = foreach ($rule in $targetRules) {
    $grouped = $findings |
        Where-Object { $_.Rule -eq $rule } |
        Group-Object -Property File |
        Sort-Object -Property Count -Descending |
        Select-Object -First 10

    [pscustomobject]@{
        Rule = $rule
        Hotspots = $grouped
    }
}

$reportDir = Join-Path $PWD 'reports'
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir | Out-Null
}
$reportPath = Join-Path $reportDir 'third-ratchet-burndown.md'

$summaryLines = @()
$summaryLines += '# Third Ratchet Burndown'
$summaryLines += ''
$summaryLines += '| Rule | Hit Count |'
$summaryLines += '|------|-----------|'
foreach ($rule in $targetRules) {
    $summaryLines += "| $rule | $($ruleCounts[$rule]) |"
}
$summaryLines += ''
$summaryLines += '## Combined Top File Hotspots'
$summaryLines += ''
$summaryLines += '| File | Hits |'
$summaryLines += '|------|------|'
if ($fileCounts) {
    foreach ($entry in ($fileCounts | Select-Object -First 25)) {
        $summaryLines += "| $($entry.Name) | $($entry.Count) |"
    }
} else {
    $summaryLines += '| (none) | 0 |'
}

foreach ($ruleHotspot in $hotspotsByRule) {
    $summaryLines += ''
    $summaryLines += "## $($ruleHotspot.Rule) Hotspots"
    $summaryLines += ''
    $summaryLines += '| File | Hits |'
    $summaryLines += '|------|------|'
    if ($ruleHotspot.Hotspots) {
        foreach ($entry in $ruleHotspot.Hotspots) {
            $summaryLines += "| $($entry.Name) | $($entry.Count) |"
        }
    } else {
        $summaryLines += '| (none) | 0 |'
    }
}

$summaryLines += ''
$summaryLines += '## Full Finding List'
$summaryLines += ''
$summaryLines += '| Rule | File | Line | Column |'
$summaryLines += '|------|------|------|--------|'
if ($findings) {
    foreach ($f in ($findings | Sort-Object Rule, File, Line, Column)) {
        $summaryLines += "| $($f.Rule) | $($f.File) | $($f.Line) | $($f.Column) |"
    }
} else {
    $summaryLines += '| (none) | (none) | 0 | 0 |'
}

$summary = $summaryLines -join "`n"
$summary | Out-File -FilePath $reportPath -Encoding utf8

if ($env:GITHUB_STEP_SUMMARY) {
    $summary | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Encoding utf8 -Append
}

Write-Host "Third ratchet summary generated."
Write-Host "Analyzer exit code: $exitCode"
Write-Host "Report written: $reportPath"
foreach ($rule in $targetRules) {
    Write-Host ("{0}: {1}" -f $rule, $ruleCounts[$rule])
}

exit 0
