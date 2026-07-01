#!/usr/bin/env pwsh

param(
    [string]$DataBankRoot = (Join-Path $HOME 'dfc-data-bank'),
    [string]$FixtureSource = 'test/fixtures/smoke.mp4',
    [int]$FixturePort = 9000,
    [int]$WebPort = 8088,
    [switch]$NoPlaywright,
    [switch]$KeepServers
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format o)] $Message"
}

function Resolve-Tool {
    param([string[]]$Candidates)

    foreach ($candidate in $Candidates) {
        if (Get-Command $candidate -ErrorAction SilentlyContinue) {
            return $candidate
        }
    }

    return $null
}

function Wait-ForPort {
    param(
        [string]$HostName,
        [int]$Port,
        [int]$TimeoutSec = 20
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $client = $null
        try {
            $client = [System.Net.Sockets.TcpClient]::new()
            $task = $client.ConnectAsync($HostName, $Port)
            if ($task.Wait(500) -and $client.Connected) {
                return $true
            }
        }
        catch {
            # Keep polling until timeout.
        }
        finally {
            if ($client) {
                $client.Dispose()
            }
        }

        Start-Sleep -Milliseconds 300
    }

    return $false
}

function Ensure-Dir {
    param([string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Ensure-SmokeFixture {
    param(
        [string]$SourcePath,
        [string]$TargetPath
    )

    if (Test-Path $SourcePath) {
        Copy-Item -Path $SourcePath -Destination $TargetPath -Force
        Log "Fixture copied from repo: $SourcePath"
        return
    }

    $ffmpeg = Resolve-Tool -Candidates @('ffmpeg')
    if ($ffmpeg) {
        Log 'Fixture not found in repo; generating tiny MP4 with ffmpeg'
        & $ffmpeg -f lavfi -i testsrc=duration=1:size=320x240:rate=5 -c:v libx264 -pix_fmt yuv420p -t 1 -y $TargetPath | Out-Null
        return
    }

    Log 'Fixture missing and ffmpeg unavailable; writing placeholder file'
    Set-Content -Path $TargetPath -Encoding ascii -NoNewline -Value 'dfc-media-smoke-placeholder'
}

$repoRoot = (Get-Location).Path
$fixturesDir = Join-Path $DataBankRoot 'fixtures'
$reportsDir = Join-Path $DataBankRoot 'reports'
$logsDir = Join-Path $DataBankRoot 'logs'

Ensure-Dir -Path $DataBankRoot
Ensure-Dir -Path $fixturesDir
Ensure-Dir -Path $reportsDir
Ensure-Dir -Path $logsDir

$fixtureTarget = Join-Path $fixturesDir 'smoke.mp4'
Ensure-SmokeFixture -SourcePath $FixtureSource -TargetPath $fixtureTarget

$shaPath = "$fixtureTarget.sha256"
$hash = Get-FileHash -Algorithm SHA256 -Path $fixtureTarget
"$($hash.Hash.ToLowerInvariant())  smoke.mp4" | Set-Content -Path $shaPath -Encoding ascii
Log "Fixture checksum written: $shaPath"

$python = Resolve-Tool -Candidates @('python', 'python3', 'py')
if (-not $python) {
    throw 'Python runtime is required to host local fixture/web servers.'
}

$fixtureLogOut = Join-Path $logsDir 'fixture-server.out.log'
$fixtureLogErr = Join-Path $logsDir 'fixture-server.err.log'
$webLogOut = Join-Path $logsDir 'web-server.out.log'
$webLogErr = Join-Path $logsDir 'web-server.err.log'

Log "Starting fixture server: http://127.0.0.1:$FixturePort"
$fixtureProc = Start-Process -FilePath $python `
    -ArgumentList @('-m', 'http.server', "$FixturePort", '--directory', $fixturesDir) `
    -PassThru `
    -RedirectStandardOutput $fixtureLogOut `
    -RedirectStandardError $fixtureLogErr

if (-not (Wait-ForPort -HostName '127.0.0.1' -Port $FixturePort)) {
    throw "Fixture server failed to start on port $FixturePort"
}

Log "Starting web server: http://127.0.0.1:$WebPort"
$webDir = Join-Path $repoRoot 'web'
$webProc = Start-Process -FilePath $python `
    -ArgumentList @('-m', 'http.server', "$WebPort", '--directory', $webDir) `
    -PassThru `
    -RedirectStandardOutput $webLogOut `
    -RedirectStandardError $webLogErr

if (-not (Wait-ForPort -HostName '127.0.0.1' -Port $WebPort)) {
    throw "Web server failed to start on port $WebPort"
}

try {
    if (-not $NoPlaywright) {
        Log 'Running promoter Playwright smoke against local web server'
        $env:PLAYWRIGHT_BASE_URL = "http://127.0.0.1:$WebPort"
        & node ./node_modules/playwright/cli.js test test/visual/promoter_how_we_work.spec.ts --project=desktop
        if ($LASTEXITCODE -ne 0) {
            throw "Playwright smoke failed with exit code $LASTEXITCODE"
        }
    }

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

    if (Test-Path 'playwright-report') {
        $reportZip = Join-Path $reportsDir "promoter-playwright-report-$stamp.zip"
        if (Test-Path $reportZip) {
            Remove-Item $reportZip -Force
        }
        Compress-Archive -Path 'playwright-report\*' -DestinationPath $reportZip
        Log "Archived report: $reportZip"
    }

    if (Test-Path 'test-results') {
        $resultsZip = Join-Path $reportsDir "promoter-test-results-$stamp.zip"
        if (Test-Path $resultsZip) {
            Remove-Item $resultsZip -Force
        }
        Compress-Archive -Path 'test-results\*' -DestinationPath $resultsZip
        Log "Archived results: $resultsZip"
    }

    $summaryPath = Join-Path $reportsDir "local-smoke-summary-$stamp.json"
    $summary = [ordered]@{
        generatedAt = (Get-Date).ToString('o')
        fixtureUrl = "http://127.0.0.1:$FixturePort/smoke.mp4"
        baseUrl = "http://127.0.0.1:$WebPort"
        fixtureSha256 = $hash.Hash.ToLowerInvariant()
        playwrightRun = (-not $NoPlaywright)
    }
    ($summary | ConvertTo-Json -Depth 5) | Set-Content -Path $summaryPath -Encoding utf8
    Log "Summary written: $summaryPath"
}
finally {
    if (-not $KeepServers) {
        if ($fixtureProc -and -not $fixtureProc.HasExited) {
            Stop-Process -Id $fixtureProc.Id -Force -ErrorAction SilentlyContinue
        }
        if ($webProc -and -not $webProc.HasExited) {
            Stop-Process -Id $webProc.Id -Force -ErrorAction SilentlyContinue
        }
        Log 'Local servers stopped'
    }
    else {
        Log "Servers kept running: fixture PID=$($fixtureProc.Id), web PID=$($webProc.Id)"
    }
}

Log 'Data-bank smoke run complete'
