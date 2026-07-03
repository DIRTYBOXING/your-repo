# run_with_env.ps1
# Reads .env and optional .env.local, then passes keys as --dart-define flags to flutter
# Usage: .\scripts\run_with_env.ps1 -Action run -Mode demo
#        .\scripts\run_with_env.ps1 -Action build -Mode real

param(
    [ValidateSet('run', 'build')]
    [string]$Action = 'run',

    [ValidateSet('demo', 'real')]
    [string]$Mode = 'demo',

    [string]$Device = 'chrome',

    [switch]$UseEmulator,

    [switch]$AllowDemoWithoutEmulator,

    [int]$WebPort = 8088,

    [string]$WebHostname = '127.0.0.1'
)

$ErrorActionPreference = 'Stop'

$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$envFiles = @(
    (Join-Path $workspaceRoot '.env'),
    (Join-Path $workspaceRoot '.env.local')
)
$webIndexFile = Join-Path $workspaceRoot 'web/index.html'
$mapsKeyPlaceholder = '__GOOGLE_MAPS_API_KEY_WEB__'
$mapsScriptPattern = 'https://maps\.googleapis\.com/maps/api/js\?key=[^"&]*&loading=async'
$defines = @()
$defineMap = [ordered]@{}
$skippedEnvKeys = @()
$originalWebIndexContent = $null
$webIndexWasPatched = $false
$selectedMapsWebKeySource = ''

function Resolve-WebPort {
    param(
        [int]$Port
    )

    $candidate = $Port
    $handledProcessIds = @{}

    while ($true) {
        $reservedProcesses = @(Get-CimInstance Win32_Process -Filter "Name = 'dart.exe' OR Name = 'dartvm.exe' OR Name = 'flutter.exe'" -ErrorAction SilentlyContinue | Where-Object {
                $commandLine = $_.CommandLine
                if ([string]::IsNullOrWhiteSpace($commandLine)) {
                    return $false
                }

                $targetsCandidatePort = $commandLine -match "(^|\s)--web-port\s+$candidate(\s|$)"
                $isFlutterRun = $commandLine -match 'flutter_tools\.snapshot\s+run'
                return $targetsCandidatePort -and $isFlutterRun
            })

        if ($reservedProcesses.Count -gt 0) {
            $shouldAdvancePort = $false
            foreach ($reservedProcess in $reservedProcesses) {
                $processId = $reservedProcess.ProcessId
                if (-not $processId -or $handledProcessIds.ContainsKey($processId)) {
                    continue
                }

                $handledProcessIds[$processId] = $true
                $commandLine = $reservedProcess.CommandLine
                $isEditorLaunch = $commandLine -match '--machine' -or $commandLine -match '--start-paused'

                if ($isEditorLaunch) {
                    Write-Host "Port $candidate is reserved by an active Flutter debug launcher (PID $processId). Falling forward to the next port." -ForegroundColor Yellow
                    $candidate++
                    $shouldAdvancePort = $true
                    break
                }

                try {
                    $process = Get-Process -Id $processId -ErrorAction Stop
                    Write-Host "Stopping stale Flutter launcher reserving port $candidate (PID $processId, $($process.ProcessName))" -ForegroundColor Yellow
                    Stop-Process -Id $processId -Force -ErrorAction Stop
                }
                catch {
                    if ($_.Exception.Message -match 'process with the process identifier .* was not running|Cannot find a process with the process identifier') {
                        continue
                    }

                    throw "Unable to inspect or free reserved Flutter process on port $candidate before Flutter run. $($_.Exception.Message)"
                }
            }

            if ($shouldAdvancePort) {
                continue
            }
        }

        try {
            $listeners = Get-NetTCPConnection -LocalPort $candidate -State Listen -ErrorAction Stop
        }
        catch {
            return $candidate
        }

        $resolved = $false
        foreach ($listener in $listeners) {
            $processId = $listener.OwningProcess
            if (-not $processId) {
                continue
            }

            if ($handledProcessIds.ContainsKey($processId)) {
                continue
            }

            try {
                $process = Get-Process -Id $processId -ErrorAction Stop
                $name = $process.ProcessName.ToLowerInvariant()
                if ($name -in @('dartvm', 'dart', 'flutter')) {
                    Write-Host "Stopping stale Flutter web runner on port $candidate (PID $processId, $($process.ProcessName))" -ForegroundColor Yellow
                    Stop-Process -Id $processId -Force -ErrorAction Stop
                    $handledProcessIds[$processId] = $true
                    $resolved = $true
                }
                else {
                    Write-Host "Port $candidate is owned by PID $processId ($($process.ProcessName)). Falling forward to the next port." -ForegroundColor Yellow
                    $handledProcessIds[$processId] = $true
                    $candidate++
                    $resolved = $true
                }
            }
            catch {
                if ($_.Exception.Message -match 'process with the process identifier .* was not running|Cannot find a process with the process identifier') {
                    $handledProcessIds[$processId] = $true
                    $resolved = $true
                    continue
                }

                throw "Unable to inspect or free port $candidate before Flutter run. $($_.Exception.Message)"
            }
        }

        if (-not $resolved) {
            return $candidate
        }
    }
}

function Set-DartDefine {
    param(
        [string]$Key,
        [string]$Value
    )

    $trimmedKey = $Key.Trim()
    if (-not $trimmedKey) {
        return
    }

    $trimmedValue = $Value.Trim()
    if ($trimmedValue.Length -ge 2) {
        if (($trimmedValue.StartsWith('"') -and $trimmedValue.EndsWith('"')) -or
            ($trimmedValue.StartsWith("'") -and $trimmedValue.EndsWith("'"))) {
            $trimmedValue = $trimmedValue.Substring(1, $trimmedValue.Length - 2)
        }
    }

    $defineMap[$trimmedKey] = $trimmedValue
}

function Test-ValidDartDefineKey {
    param(
        [string]$Key
    )

    return $Key -match '^[A-Z][A-Z0-9_]*$'
}

function Test-IgnorableEnvLine {
    param(
        [string]$Line
    )

    $trimmedLine = $Line.Trim()
    if (-not $trimmedLine) {
        return $true
    }

    if ($trimmedLine.StartsWith('#')) {
        return $true
    }

    return $trimmedLine -match '^(const|let|var|export)\s+'
}

function Format-DartDefineForDisplay {
    param(
        [string]$Key,
        [string]$Value
    )

    $shouldRedact = $Key -match '(SECRET|TOKEN|KEY|PASSWORD|WEBHOOK|PRIVATE|CREDENTIALS|SENDGRID|STRIPE|MUX|TWILIO)'
    if (-not $shouldRedact) {
        return "--dart-define=$Key=$Value"
    }

    if ([string]::IsNullOrEmpty($Value)) {
        return "--dart-define=$Key=<empty>"
    }

    $visiblePrefixLength = [Math]::Min(4, $Value.Length)
    $visiblePrefix = $Value.Substring(0, $visiblePrefixLength)
    return "--dart-define=$Key=$visiblePrefix***"
}

function Get-DartDefineValue {
    param(
        [string]$Key
    )

    if ($defineMap.Contains($Key)) {
        return [string]$defineMap[$Key]
    }

    return ''
}

function Get-LaunchLaneInfo {
    if ($Mode -eq 'demo' -and $UseEmulator) {
        return @{
            Name        = 'SANDBOX: DEMO + EMULATOR'
            Description = 'Safe local repair lane. Demo shell backed by localhost Firebase emulators.'
            Color       = 'Green'
        }
    }

    if ($Mode -eq 'real' -and $UseEmulator) {
        return @{
            Name        = 'LOCAL EMULATOR'
            Description = 'Real app flows against localhost Firebase emulators.'
            Color       = 'DarkCyan'
        }
    }

    if ($Mode -eq 'real') {
        return @{
            Name        = 'LIVE FIREBASE'
            Description = 'Real auth, real backend, and live content lane.'
            Color       = 'Yellow'
        }
    }

    return @{
        Name        = 'DEMO PREVIEW (NO EMULATOR)'
        Description = 'Preview-only lane. Auth is disabled, but this is not the safe local sandbox.'
        Color       = 'Red'
    }
}

function Remove-DartDefine {
    param(
        [string]$Key
    )

    if ($defineMap.Contains($Key)) {
        $defineMap.Remove($Key)
    }
}

function Get-SelectedWebGoogleMapsApiKey {
    $candidateKeys = @()

    if ($Mode -eq 'demo' -or $Action -eq 'run') {
        $candidateKeys = @(
            'GOOGLE_MAPS_API_KEY_WEB_DEV',
            'GOOGLE_MAPS_API_KEY_WEB',
            'GOOGLE_MAPS_API_KEY'
        )
    }
    else {
        $candidateKeys = @(
            'GOOGLE_MAPS_API_KEY_WEB_PROD',
            'GOOGLE_MAPS_API_KEY_WEB',
            'GOOGLE_MAPS_API_KEY'
        )
    }

    foreach ($candidateKey in $candidateKeys) {
        $candidateValue = Get-DartDefineValue -Key $candidateKey
        if ($candidateValue) {
            return @{
                Key   = $candidateKey
                Value = $candidateValue
            }
        }
    }

    return @{
        Key   = ''
        Value = ''
    }
}

function Normalize-WebGoogleMapsApiKey {
    $selection = Get-SelectedWebGoogleMapsApiKey

    foreach ($mapsKey in @(
            'GOOGLE_MAPS_API_KEY_WEB_DEV',
            'GOOGLE_MAPS_API_KEY_WEB_PROD',
            'GOOGLE_MAPS_API_KEY_WEB',
            'GOOGLE_MAPS_API_KEY'
        )) {
        Remove-DartDefine -Key $mapsKey
    }

    if ($selection.Value) {
        Set-DartDefine -Key 'GOOGLE_MAPS_API_KEY_WEB' -Value $selection.Value
        $script:selectedMapsWebKeySource = [string]$selection.Key
        Write-Host "Using $($selection.Key) for the Google Maps web loader." -ForegroundColor DarkCyan
    }
    else {
        $script:selectedMapsWebKeySource = ''
    }
}

function Set-WebGoogleMapsApiKey {
    if (-not (Test-Path $webIndexFile)) {
        return
    }

    $content = [System.IO.File]::ReadAllText($webIndexFile)
    $containsPlaceholder = $content.Contains($mapsKeyPlaceholder)
    $containsMapsScript = $content -match $mapsScriptPattern

    if (-not $containsPlaceholder -and -not $containsMapsScript) {
        return
    }

    $script:originalWebIndexContent = $content

    $mapsApiKey = Get-DartDefineValue -Key 'GOOGLE_MAPS_API_KEY_WEB'

    if (-not $mapsApiKey) {
        Write-Host 'No Google Maps web API key found in .env. Web map pages will stay unconfigured for this run/build.' -ForegroundColor Yellow
    }

    if ($containsPlaceholder) {
        $patchedContent = $content.Replace($mapsKeyPlaceholder, $mapsApiKey)
    }
    else {
        $patchedContent = [System.Text.RegularExpressions.Regex]::Replace(
            $content,
            $mapsScriptPattern,
            [System.Text.RegularExpressions.MatchEvaluator] {
                param($match)
                "https://maps.googleapis.com/maps/api/js?key=$mapsApiKey&loading=async"
            }
        )
    }

    if ($patchedContent -ne $content) {
        [System.IO.File]::WriteAllText($webIndexFile, $patchedContent)
        $script:webIndexWasPatched = $true
        if ($mapsApiKey) {
            if ($selectedMapsWebKeySource) {
                Write-Host "Injected Google Maps web API key into web/index.html using $selectedMapsWebKeySource." -ForegroundColor DarkCyan
            }
            else {
                Write-Host 'Injected Google Maps web API key into web/index.html for this Flutter session.' -ForegroundColor DarkCyan
            }
        }
    }
}

function Restore-WebGoogleMapsApiKey {
    if (-not $webIndexWasPatched) {
        return
    }

    if ($null -eq $originalWebIndexContent) {
        return
    }

    [System.IO.File]::WriteAllText($webIndexFile, $originalWebIndexContent)
    $script:webIndexWasPatched = $false
    $script:originalWebIndexContent = $null
}

# Always set WEB_DEMO_MODE
if ($Mode -eq 'demo') {
    Set-DartDefine -Key 'WEB_DEMO_MODE' -Value 'true'
}
else {
    Set-DartDefine -Key 'WEB_DEMO_MODE' -Value 'false'
    # Real mode → enable live Stripe keys and payment links
    Set-DartDefine -Key 'PRODUCTION' -Value 'true'
    Set-DartDefine -Key 'STRIPE_USE_LIVE_LINKS' -Value 'true'
}

# Synthetic/generated content stays OFF unless a maintainer explicitly flips it.
Set-DartDefine -Key 'ALLOW_SYNTHETIC_CONTENT' -Value 'false'

# Non-core / experimental surfaces stay OFF unless explicitly enabled.
Set-DartDefine -Key 'ENABLE_DRONE_RACING' -Value 'false'
Set-DartDefine -Key 'ENABLE_GAMES' -Value 'false'
Set-DartDefine -Key 'ALLOW_LIVE_AUTO_SEED' -Value 'false'

# Emergency production posture for commerce paths.
Set-DartDefine -Key 'FEATURE_SHELL_V2' -Value 'true'
Set-DartDefine -Key 'FEATURE_PLAY_SKIN' -Value 'false'
Set-DartDefine -Key 'FEATURE_PPV_STORE' -Value 'true'

if ($UseEmulator) {
    Set-DartDefine -Key 'USE_FIREBASE_EMULATOR' -Value 'true'
}
else {
    Set-DartDefine -Key 'USE_FIREBASE_EMULATOR' -Value 'false'
}

if ($Mode -eq 'demo' -and -not $UseEmulator -and -not $AllowDemoWithoutEmulator) {
    throw 'Refusing to run demo mode without -UseEmulator. Use the sandbox lane (-Mode demo -UseEmulator) or pass -AllowDemoWithoutEmulator if you explicitly want preview-only demo mode.'
}

# Read .env/.env.local and inject non-empty keys. Later files override earlier ones.
$loadedEnvFiles = @()
foreach ($envFile in $envFiles) {
    if (-not (Test-Path $envFile)) {
        continue
    }

    Get-Content $envFile | ForEach-Object {
        if (Test-IgnorableEnvLine -Line $_) {
            return
        }

        if ($_ -match '^\s*([^#][^=]+?)\s*=\s*(.+)\s*$') {
            $key = $Matches[1]
            $val = $Matches[2]
            $trimmedKey = $key.Trim()
            if (-not (Test-ValidDartDefineKey -Key $trimmedKey)) {
                $skippedEnvKeys += $trimmedKey
                return
            }

            if ($val -and $val.Trim().Length -gt 0) {
                Set-DartDefine -Key $key -Value $val
            }
        }
    }

    $loadedEnvFiles += [System.IO.Path]::GetFileName($envFile)
}

if ($loadedEnvFiles.Count -gt 0) {
    $loadedList = $loadedEnvFiles -join ', '
    Write-Host "Loaded keys from $loadedList" -ForegroundColor Green
    if ($skippedEnvKeys.Count -gt 0) {
        $skippedList = ($skippedEnvKeys | Sort-Object -Unique) -join ', '
        Write-Host "Skipped invalid env keys: $skippedList" -ForegroundColor Yellow
    }
}
else {
    Write-Host "No .env or .env.local file found - running without extra keys" -ForegroundColor Yellow
}

Normalize-WebGoogleMapsApiKey

$laneInfo = Get-LaunchLaneInfo
Write-Host "Launch lane: $($laneInfo.Name)" -ForegroundColor $laneInfo.Color
Write-Host $laneInfo.Description -ForegroundColor $laneInfo.Color

$flutterArgs = @()

if ($Action -eq 'run') {
    $flutterArgs += @('run', '-d', $Device)
    if ($Device -eq 'chrome' -or $Device -eq 'web-server' -or $Device -eq 'edge') {
        $WebPort = Resolve-WebPort -Port $WebPort
        Write-Host "Using web port $WebPort" -ForegroundColor DarkCyan
        $flutterArgs += @('--web-port', $WebPort.ToString(), '--web-hostname', $WebHostname)
    }
}
else {
    $flutterArgs += @('build', 'web')
}

$defines = foreach ($entry in $defineMap.GetEnumerator()) {
    "--dart-define=$($entry.Key)=$($entry.Value)"
}

$flutterArgs += $defines

$displayFlutterArgs = @()
foreach ($arg in $flutterArgs) {
    if ($arg.StartsWith('--dart-define=')) {
        $defineContent = $arg.Substring(14)
        $splitIndex = $defineContent.IndexOf('=')
        if ($splitIndex -gt 0) {
            $displayFlutterArgs += Format-DartDefineForDisplay -Key $defineContent.Substring(0, $splitIndex) -Value $defineContent.Substring($splitIndex + 1)
            continue
        }
    }

    $displayFlutterArgs += $arg
}

Write-Host ('Running: flutter ' + ($displayFlutterArgs -join ' ')) -ForegroundColor Cyan
$exitCode = 0

try {
    Set-WebGoogleMapsApiKey
    & flutter @flutterArgs
    $exitCode = $LASTEXITCODE
}
finally {
    Restore-WebGoogleMapsApiKey
}

if ($exitCode -ne 0) {
    exit $exitCode
}
