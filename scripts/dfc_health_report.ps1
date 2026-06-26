#!/usr/bin/env pwsh

param(
    [switch]$RunSmoke,
    [string]$OutputDir = 'reports\health',
    [string]$EmailTo = '',
    [string]$FromEmail = '',
    [string]$EmailSubject = 'DFC Autonomous Health Report'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Get-Location).Path
$outputPath = Join-Path $repoRoot $OutputDir
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

$timestamp = Get-Date
$stamp = $timestamp.ToString('yyyyMMdd-HHmmss')
$jsonPath = Join-Path $outputPath "dfc-health-$stamp.json"
$mdPath = Join-Path $outputPath "dfc-health-$stamp.md"
$latestJsonPath = Join-Path $outputPath 'latest.json'
$latestMdPath = Join-Path $outputPath 'latest.md'

function Invoke-CommandCapture {
    param(
        [string]$Command,
        [string]$WorkingDirectory = $repoRoot
    )

    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        Push-Location $WorkingDirectory
        try {
            & pwsh -NoProfile -Command $Command *> $tempFile
            $exitCode = $LASTEXITCODE
        } finally {
            Pop-Location
        }

        return [pscustomobject]@{
            ExitCode = if ($null -eq $exitCode) { 0 } else { [int]$exitCode }
            Output = Get-Content -Raw $tempFile
        }
    } finally {
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}

function Get-EnvMap {
    param([string]$Path)

    $map = @{}
    if (-not (Test-Path $Path)) {
        return $map
    }

    foreach ($line in Get-Content $Path) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.TrimStart().StartsWith('#')) { continue }
        $index = $line.IndexOf('=')
        if ($index -lt 1) { continue }
        $key = $line.Substring(0, $index).Trim()
        $value = $line.Substring($index + 1)
        $map[$key] = $value
    }

    return $map
}

function Convert-JsonSafe {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $null
    }

    $trimmed = $Text.Trim()
    $jsonStart = $trimmed.IndexOf('{')
    if ($jsonStart -lt 0) {
        $jsonStart = $trimmed.IndexOf('[')
    }
    if ($jsonStart -lt 0) {
        return $null
    }

    $candidate = $trimmed.Substring($jsonStart)
    try {
        return $candidate | ConvertFrom-Json -Depth 100
    } catch {
        return $null
    }
}

function Test-ObjectProperty {
    param(
        [object]$Object,
        [string]$Name
    )

    if ($null -eq $Object) {
        return $false
    }

    return $null -ne $Object.PSObject.Properties[$Name]
}

function Get-FlutterAnalyzeStatus {
    $result = Invoke-CommandCapture -Command 'flutter analyze'
    $clean = $result.Output -replace '\r', ''
    $issueMatch = [regex]::Match($clean, '(?m)(\d+) issues found\.')
    $isClean = $clean -match 'No issues found!'

    return [pscustomobject]@{
        command = 'flutter analyze'
        exitCode = $result.ExitCode
        healthy = $isClean -or ($result.ExitCode -eq 0)
        issueCount = if ($issueMatch.Success) { [int]$issueMatch.Groups[1].Value } else { 0 }
        summary = if ($isClean) { 'Analyzer clean' } else { 'Analyzer reported issues' }
        raw = $clean.Trim()
    }
}

function Get-RootNpmOutdatedStatus {
    $result = Invoke-CommandCapture -Command 'npm outdated --json'
    $parsed = Convert-JsonSafe -Text $result.Output
    $packages = @()

    if ($parsed) {
        foreach ($property in $parsed.PSObject.Properties) {
            $item = $property.Value
            $packages += [pscustomobject]@{
                name = $property.Name
                current = [string]$item.current
                wanted = [string]$item.wanted
                latest = [string]$item.latest
                majorBehind = ($item.current -ne $item.latest) -and (($item.current -split '\.')[0] -ne ($item.latest -split '\.')[0])
            }
        }
    }

    return [pscustomobject]@{
        command = 'npm outdated --json'
        exitCode = $result.ExitCode
        packageCount = $packages.Count
        majorCount = @($packages | Where-Object { $_.majorBehind }).Count
        packages = @($packages | Sort-Object name)
        healthy = $packages.Count -eq 0
        raw = $result.Output.Trim()
    }
}

function Get-FunctionsNpmOutdatedStatus {
    $result = Invoke-CommandCapture -Command 'npm outdated --json' -WorkingDirectory (Join-Path $repoRoot 'functions')
    $parsed = Convert-JsonSafe -Text $result.Output
    $packages = @()

    if ($parsed) {
        foreach ($property in $parsed.PSObject.Properties) {
            $item = $property.Value
            $packages += [pscustomobject]@{
                name = $property.Name
                current = [string]$item.current
                wanted = [string]$item.wanted
                latest = [string]$item.latest
                majorBehind = ($item.current -ne $item.latest) -and (($item.current -split '\.')[0] -ne ($item.latest -split '\.')[0])
            }
        }
    }

    return [pscustomobject]@{
        command = 'npm outdated --json (functions)'
        exitCode = $result.ExitCode
        packageCount = $packages.Count
        majorCount = @($packages | Where-Object { $_.majorBehind }).Count
        packages = @($packages | Sort-Object name)
        healthy = $packages.Count -eq 0
        raw = $result.Output.Trim()
    }
}

function Get-FlutterOutdatedStatus {
    $result = Invoke-CommandCapture -Command 'flutter pub outdated --json 2>$null'
    $parsed = Convert-JsonSafe -Text $result.Output
    $packages = @()

    if ($parsed -and $parsed.packages) {
        foreach ($package in $parsed.packages) {
            $currentVersion = if ($package.current) { [string]$package.current.version } else { '' }
            $latestVersion = if ($package.latest) { [string]$package.latest.version } else { '' }
            $resolvableVersion = if ($package.resolvable) { [string]$package.resolvable.version } else { '' }
            $packages += [pscustomobject]@{
                name = [string]$package.package
                kind = [string]$package.kind
                current = $currentVersion
                resolvable = $resolvableVersion
                latest = $latestVersion
                majorBehind = ($currentVersion -and $latestVersion) -and (($currentVersion -split '\.')[0] -ne ($latestVersion -split '\.')[0])
                hasUpdate = $currentVersion -ne $latestVersion
            }
        }
    }

    $directPackages = @($packages | Where-Object { $_.kind -eq 'direct' -and $_.hasUpdate })

    return [pscustomobject]@{
        command = 'flutter pub outdated --json'
        exitCode = $result.ExitCode
        packageCount = $directPackages.Count
        majorCount = @($directPackages | Where-Object { $_.majorBehind }).Count
        packages = @($directPackages | Sort-Object name)
        healthy = $directPackages.Count -eq 0
        raw = $result.Output.Trim()
    }
}

function Get-StripeStatus {
    $envPath = Join-Path $repoRoot 'functions\.env'
    $key = ''

    if (-not [string]::IsNullOrWhiteSpace($env:STRIPE_SECRET_KEY)) {
        $key = $env:STRIPE_SECRET_KEY.Trim()
    } elseif (Test-Path $envPath) {
        $line = Get-Content $envPath | Where-Object { $_ -like 'STRIPE_SECRET_KEY=*' } | Select-Object -First 1
        if ($line) {
            $key = $line.Substring(18).Trim()
        }
    }

    if ([string]::IsNullOrWhiteSpace($key)) {
        return [pscustomobject]@{
            configured = $false
            healthy = $false
            summary = 'STRIPE_SECRET_KEY missing'
        }
    }

    try {
        $response = Invoke-RestMethod -Method Get -Uri 'https://api.stripe.com/v1/account' -Headers @{ Authorization = "Bearer $key" }
        return [pscustomobject]@{
            configured = $true
            healthy = $true
            accountId = [string]$response.id
            country = [string]$response.country
            summary = 'Stripe secret key verified against /v1/account'
        }
    } catch {
        return [pscustomobject]@{
            configured = $true
            healthy = $false
            summary = $_.Exception.Message
        }
    }
}

function Get-FunctionsHealthCheckStatus {
    $functionsIndex = Join-Path $repoRoot 'functions\index.js'
    if (-not (Test-Path $functionsIndex)) {
        return [pscustomobject]@{
            healthy = $false
            implemented = $false
            summary = 'functions/index.js not found'
        }
    }

    $content = Get-Content -Raw $functionsIndex
    $implemented = $content -match 'exports\.healthCheck\s*=\s*onCall'

    return [pscustomobject]@{
        healthy = $implemented
        implemented = $implemented
        summary = if ($implemented) { 'Backend healthCheck callable exists' } else { 'Backend healthCheck callable missing' }
    }
}

function Get-SmokeStatus {
    $smokeFile = Join-Path $repoRoot 'reports\smoke-results.json'
    if (-not $RunSmoke -and -not (Test-Path $smokeFile)) {
        return [pscustomobject]@{
            healthy = $false
            executed = $false
            summary = 'No smoke report found yet'
        }
    }

    if ($RunSmoke) {
        $smokeResult = Invoke-CommandCapture -Command 'pwsh -ExecutionPolicy Bypass -File scripts/smoke_clip_publish_strict.ps1 -Timeout 30 -Retries 2'
        $executed = $true
        $raw = $smokeResult.Output.Trim()
    } else {
        $executed = $false
        $raw = Get-Content -Raw $smokeFile
    }

    $parsed = Convert-JsonSafe -Text $raw
    $healthy = $false
    $summary = 'Smoke status unavailable'

    if ($parsed) {
        if (Test-ObjectProperty -Object $parsed -Name 'status') {
            $healthy = [string]$parsed.status -in @('ok', 'healthy', 'passed', 'success')
            $summary = "Smoke status: $($parsed.status)"
        } elseif (Test-ObjectProperty -Object $parsed -Name 'collection') {
            $healthy = $true
            $summary = 'Smoke collection file present'
        }
    }

    return [pscustomobject]@{
        healthy = $healthy
        executed = $executed
        summary = $summary
    }
}

function Send-HealthReportEmail {
    param(
        [string]$ApiKey,
        [string]$Sender,
        [string[]]$Recipients,
        [string]$Subject,
        [string]$MarkdownBody,
        [object]$ReportObject
    )

    $safeBody = ($MarkdownBody -replace '&', '&amp;') -replace '<', '&lt;' -replace '>', '&gt;'
    $html = @"
<html>
  <body style="font-family:Arial,sans-serif;background:#0a0e1a;color:#f5f7ff;padding:24px;">
    <div style="max-width:760px;margin:0 auto;background:#111827;border-radius:16px;padding:24px;">
      <h1 style="margin-top:0;color:#00d9ff;">DFC Autonomous Health Report</h1>
      <p><strong>Overall Status:</strong> $($ReportObject.overallStatus.ToUpperInvariant())</p>
      <p><strong>Generated:</strong> $($ReportObject.generatedAt)</p>
      <pre style="white-space:pre-wrap;background:#0f172a;padding:16px;border-radius:12px;color:#e5f0ff;">$safeBody</pre>
    </div>
  </body>
</html>
"@

    $personalizations = @(
        @{
            to = @($Recipients | ForEach-Object { @{ email = $_ } })
            subject = $Subject
        }
    )

    $payload = @{
        personalizations = $personalizations
        from = @{ email = $Sender; name = 'DFC Health Monitor' }
        content = @(
            @{ type = 'text/plain'; value = $MarkdownBody },
            @{ type = 'text/html'; value = $html }
        )
    } | ConvertTo-Json -Depth 20

    Invoke-RestMethod -Method Post `
        -Uri 'https://api.sendgrid.com/v3/mail/send' `
        -Headers @{ Authorization = "Bearer $ApiKey" } `
        -ContentType 'application/json' `
        -Body $payload | Out-Null
}

function Get-OverallStatus {
    param([object[]]$Checks)

    $failed = @($Checks | Where-Object { $_.healthy -eq $false }).Count
    if ($failed -eq 0) { return 'green' }
    if ($failed -le 2) { return 'amber' }
    return 'red'
}

$analyze = Get-FlutterAnalyzeStatus
$flutterOutdated = Get-FlutterOutdatedStatus
$rootNpmOutdated = Get-RootNpmOutdatedStatus
$functionsNpmOutdated = Get-FunctionsNpmOutdatedStatus
$stripe = Get-StripeStatus
$backendHealth = Get-FunctionsHealthCheckStatus
$smoke = Get-SmokeStatus
$envMap = Get-EnvMap -Path (Join-Path $repoRoot 'functions\.env')

$checks = @(
    [pscustomobject]@{ name = 'Flutter Analyze'; healthy = $analyze.healthy; summary = $analyze.summary },
    [pscustomobject]@{ name = 'Flutter Dependencies'; healthy = $flutterOutdated.healthy; summary = "$($flutterOutdated.packageCount) direct packages outdated" },
    [pscustomobject]@{ name = 'Root Node Dependencies'; healthy = $rootNpmOutdated.healthy; summary = "$($rootNpmOutdated.packageCount) packages outdated" },
    [pscustomobject]@{ name = 'Functions Dependencies'; healthy = $functionsNpmOutdated.healthy; summary = "$($functionsNpmOutdated.packageCount) packages outdated" },
    [pscustomobject]@{ name = 'Stripe Secret'; healthy = $stripe.healthy; summary = $stripe.summary },
    [pscustomobject]@{ name = 'Backend Health Callable'; healthy = $backendHealth.healthy; summary = $backendHealth.summary },
    [pscustomobject]@{ name = 'Smoke Status'; healthy = $smoke.healthy; summary = $smoke.summary }
)

$recommendations = New-Object System.Collections.Generic.List[string]
if (-not $analyze.healthy) { $recommendations.Add('Fix analyzer issues before shipping.') }
if ($flutterOutdated.packageCount -gt 0) { $recommendations.Add("Review $($flutterOutdated.packageCount) outdated direct Flutter packages, starting with major upgrades.") }
if ($rootNpmOutdated.majorCount -gt 0) { $recommendations.Add("Review $($rootNpmOutdated.majorCount) major root Node dependency upgrades.") }
if ($functionsNpmOutdated.majorCount -gt 0) { $recommendations.Add("Review $($functionsNpmOutdated.majorCount) major Firebase Functions dependency upgrades.") }
if (-not $stripe.healthy) { $recommendations.Add('Repair or rotate the Stripe secret key before payment-path changes.') }
if (-not $smoke.healthy) { $recommendations.Add('Run the strict smoke path to validate runtime flow, not just static analysis.') }
if ($recommendations.Count -eq 0) { $recommendations.Add('Health baseline is clean. Next step is scheduled reporting and alert routing.') }

$report = [pscustomobject]@{
    generatedAt = $timestamp.ToString('o')
    overallStatus = Get-OverallStatus -Checks $checks
    checks = $checks
    detail = [pscustomobject]@{
        flutterAnalyze = $analyze
        flutterOutdated = $flutterOutdated
        rootNpmOutdated = $rootNpmOutdated
        functionsNpmOutdated = $functionsNpmOutdated
        stripe = $stripe
        backendHealthCheck = $backendHealth
        smoke = $smoke
    }
    recommendations = $recommendations
}

$report | ConvertTo-Json -Depth 100 | Set-Content -Path $jsonPath
$report | ConvertTo-Json -Depth 100 | Set-Content -Path $latestJsonPath

$markdown = @(
    '# DFC Autonomous Health Report',
    '',
    "Generated: $($report.generatedAt)",
    "Overall Status: $($report.overallStatus.ToUpperInvariant())",
    '',
    '## Checks',
    ''
)

foreach ($check in $checks) {
    $icon = if ($check.healthy) { '[OK]' } else { '[WARN]' }
    $markdown += "- $icon $($check.name): $($check.summary)"
}

$markdown += ''
$markdown += '## Priority Actions'
$markdown += ''
foreach ($recommendation in $recommendations) {
    $markdown += "- $recommendation"
}

$markdown += ''
$markdown += '## Top Dependency Pressure'
$markdown += ''

foreach ($item in @($flutterOutdated.packages | Select-Object -First 5)) {
    $markdown += "- Flutter: $($item.name) $($item.current) -> $($item.latest)"
}
foreach ($item in @($functionsNpmOutdated.packages | Select-Object -First 5)) {
    $markdown += "- Functions: $($item.name) $($item.current) -> $($item.latest)"
}
foreach ($item in @($rootNpmOutdated.packages | Select-Object -First 5)) {
    $markdown += "- Root: $($item.name) $($item.current) -> $($item.latest)"
}

$markdown -join "`r`n" | Set-Content -Path $mdPath
$markdown -join "`r`n" | Set-Content -Path $latestMdPath

$emailStatus = 'not_requested'
if (-not [string]::IsNullOrWhiteSpace($EmailTo)) {
    $sendGridApiKey = if ($env:SENDGRID_API_KEY) { $env:SENDGRID_API_KEY } elseif ($envMap.ContainsKey('SENDGRID_API_KEY')) { $envMap['SENDGRID_API_KEY'] } else { '' }
    $sender = if (-not [string]::IsNullOrWhiteSpace($FromEmail)) { $FromEmail } elseif ($env:FROM_EMAIL) { $env:FROM_EMAIL } elseif ($envMap.ContainsKey('FROM_EMAIL')) { $envMap['FROM_EMAIL'] } else { 'legal@datafightcentral.com' }
    $recipients = @($EmailTo.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })

    if ([string]::IsNullOrWhiteSpace($sendGridApiKey)) {
        $emailStatus = 'sendgrid_missing'
        Write-Warning 'SENDGRID_API_KEY not found; report email was skipped.'
    } elseif ($recipients.Count -eq 0) {
        $emailStatus = 'recipient_missing'
        Write-Warning 'No valid email recipients were provided; report email was skipped.'
    } else {
        try {
            Send-HealthReportEmail -ApiKey $sendGridApiKey -Sender $sender -Recipients $recipients -Subject $EmailSubject -MarkdownBody ($markdown -join "`r`n") -ReportObject $report
            $emailStatus = 'sent'
            Write-Host "DFC health report emailed to: $($recipients -join ', ')"
        } catch {
            $emailStatus = 'failed'
            Write-Warning "Failed to send DFC health report email: $($_.Exception.Message)"
        }
    }
}

$report | Add-Member -NotePropertyName emailStatus -NotePropertyValue $emailStatus -Force
$report | ConvertTo-Json -Depth 100 | Set-Content -Path $jsonPath
$report | ConvertTo-Json -Depth 100 | Set-Content -Path $latestJsonPath

Write-Host "DFC health report written to: $latestMdPath"
Write-Host "DFC health data written to: $latestJsonPath"
Write-Host "Overall status: $($report.overallStatus.ToUpperInvariant())"
Write-Host "Email status: $emailStatus"