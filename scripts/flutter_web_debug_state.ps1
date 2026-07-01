param(
    [ValidateSet('prepare', 'cleanup')]
    [string]$Action = 'prepare',

    [ValidateSet('demo', 'real')]
    [string]$Mode = 'demo',

    [string]$DebugProfile = '',

    [switch]$UseEmulator,

    [switch]$AllowDemoWithoutEmulator
)

$ErrorActionPreference = 'Stop'

$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$envFiles = @(
    (Join-Path $workspaceRoot '.env'),
    (Join-Path $workspaceRoot '.env.local')
)
$webIndexFile = Join-Path $workspaceRoot 'web/index.html'
$debugStateDirectory = Join-Path $workspaceRoot '.dart_tool\dfc_debug'
$mapsKeyPlaceholder = '__GOOGLE_MAPS_API_KEY_WEB__'
$mapsScriptPattern = 'https://maps\.googleapis\.com/maps/api/js\?key=[^"&]*&loading=async'
$defineMap = [ordered]@{}
$skippedEnvKeys = @()
$selectedMapsWebKeySource = ''

function Get-DebugProfileName {
    param(
        [string]$ProvidedProfile
    )

    if ([string]::IsNullOrWhiteSpace($ProvidedProfile)) {
        if ($Mode -eq 'demo' -and $UseEmulator) {
            return 'web_sandbox'
        }

        if ($Mode -eq 'real') {
            return 'web_real'
        }

        return 'web_demo'
    }

    return ($ProvidedProfile -replace '[^A-Za-z0-9_.-]', '_')
}

function Get-LaunchLaneInfo {
    if ($Mode -eq 'demo' -and $UseEmulator) {
        return @{
            Name        = 'SANDBOX: DEMO + EMULATOR'
            Description = 'Safe local repair lane for F5 and debug runs.'
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
            Description = 'Real auth, backend, and live content lane.'
            Color       = 'Yellow'
        }
    }

    return @{
        Name        = 'DEMO PREVIEW (NO EMULATOR)'
        Description = 'Preview-only lane. Not the safe local sandbox.'
        Color       = 'Red'
    }
}

function Ensure-DebugStateDirectory {
    if (-not (Test-Path $debugStateDirectory)) {
        New-Item -ItemType Directory -Path $debugStateDirectory -Force | Out-Null
    }
}

function Get-DebugDefinesFilePath {
    param(
        [string]$ProfileName
    )

    return Join-Path $debugStateDirectory "$ProfileName.defines.json"
}

function Get-DebugWebIndexBackupFilePath {
    param(
        [string]$ProfileName
    )

    return Join-Path $debugStateDirectory "$ProfileName.web_index.backup.html"
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

function Get-DartDefineValue {
    param(
        [string]$Key
    )

    if ($defineMap.Contains($Key)) {
        return [string]$defineMap[$Key]
    }

    return ''
}

function Remove-DartDefine {
    param(
        [string]$Key
    )

    if ($defineMap.Contains($Key)) {
        $defineMap.Remove($Key)
    }
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

function Initialize-ModeDefines {
    if ($Mode -eq 'demo' -and -not $UseEmulator -and -not $AllowDemoWithoutEmulator) {
        throw 'Refusing to prepare demo debug state without -UseEmulator. Use the sandbox lane or pass -AllowDemoWithoutEmulator if you explicitly want preview-only demo mode.'
    }

    if ($Mode -eq 'demo') {
        Set-DartDefine -Key 'WEB_DEMO_MODE' -Value 'true'
    }
    else {
        Set-DartDefine -Key 'WEB_DEMO_MODE' -Value 'false'
        Set-DartDefine -Key 'PRODUCTION' -Value 'true'
        Set-DartDefine -Key 'STRIPE_USE_LIVE_LINKS' -Value 'true'
    }

    if ($UseEmulator) {
        Set-DartDefine -Key 'USE_FIREBASE_EMULATOR' -Value 'true'
    }
    else {
        Set-DartDefine -Key 'USE_FIREBASE_EMULATOR' -Value 'false'
    }

    # Emergency production posture for commerce paths.
    Set-DartDefine -Key 'FEATURE_SHELL_V2' -Value 'true'
    Set-DartDefine -Key 'FEATURE_PLAY_SKIN' -Value 'false'
    Set-DartDefine -Key 'FEATURE_PPV_STORE' -Value 'true'
}

function Load-DartDefinesFromEnv {
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

    if ($loadedEnvFiles.Count -eq 0) {
        Write-Host 'No .env or .env.local file found - debug launch will run with only explicit mode defines.' -ForegroundColor Yellow
        return
    }

    $loadedList = $loadedEnvFiles -join ', '
    Write-Host "Loaded keys from $loadedList for Flutter web debug state." -ForegroundColor Green
    if ($skippedEnvKeys.Count -gt 0) {
        $skippedList = ($skippedEnvKeys | Sort-Object -Unique) -join ', '
        Write-Host "Skipped invalid env keys: $skippedList" -ForegroundColor Yellow
    }
}

function Get-SelectedWebGoogleMapsApiKey {
    foreach ($candidateKey in @(
            'GOOGLE_MAPS_API_KEY_WEB_DEV',
            'GOOGLE_MAPS_API_KEY_WEB',
            'GOOGLE_MAPS_API_KEY',
            'GOOGLE_MAPS_API_KEY_WEB_PROD'
        )) {
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
        Write-Host "Using $($selection.Key) for the Google Maps web loader in debug mode." -ForegroundColor DarkCyan
    }
    else {
        $script:selectedMapsWebKeySource = ''
        Write-Host 'No Google Maps web API key found for debug mode.' -ForegroundColor Yellow
    }
}

function Write-DebugDefinesFile {
    param(
        [string]$FilePath
    )

    $jsonMap = [ordered]@{}
    foreach ($entry in $defineMap.GetEnumerator()) {
        $jsonMap[$entry.Key] = [string]$entry.Value
    }

    [System.IO.File]::WriteAllText($FilePath, ($jsonMap | ConvertTo-Json -Depth 5))
    Write-Host "Prepared Flutter debug defines at $FilePath" -ForegroundColor DarkCyan
}

function Set-WebGoogleMapsApiKey {
    param(
        [string]$PersistBackupFile
    )

    if (-not (Test-Path $webIndexFile)) {
        return
    }

    $content = [System.IO.File]::ReadAllText($webIndexFile)
    $containsPlaceholder = $content.Contains($mapsKeyPlaceholder)
    $containsMapsScript = $content -match $mapsScriptPattern

    if (-not $containsPlaceholder -and -not $containsMapsScript) {
        return
    }

    $backupDirectory = Split-Path -Parent $PersistBackupFile
    if ($backupDirectory -and -not (Test-Path $backupDirectory)) {
        New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($PersistBackupFile, $content)

    $mapsApiKey = Get-DartDefineValue -Key 'GOOGLE_MAPS_API_KEY_WEB'
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
        if ($mapsApiKey) {
            Write-Host "Injected Google Maps web API key into web/index.html using $selectedMapsWebKeySource." -ForegroundColor DarkCyan
        }
    }
}

function Restore-WebGoogleMapsApiKey {
    param(
        [string]$PersistedBackupFile
    )

    if (-not (Test-Path $PersistedBackupFile)) {
        return
    }

    $restoredContent = [System.IO.File]::ReadAllText($PersistedBackupFile)
    [System.IO.File]::WriteAllText($webIndexFile, $restoredContent)
    Remove-Item -LiteralPath $PersistedBackupFile -Force -ErrorAction SilentlyContinue
    Write-Host 'Restored web/index.html debug state.' -ForegroundColor DarkCyan
}

function Prepare-DebugState {
    $profileName = Get-DebugProfileName -ProvidedProfile $DebugProfile
    $definesFilePath = Get-DebugDefinesFilePath -ProfileName $profileName
    $backupFilePath = Get-DebugWebIndexBackupFilePath -ProfileName $profileName
    $laneInfo = Get-LaunchLaneInfo

    Initialize-ModeDefines
    Load-DartDefinesFromEnv
    Normalize-WebGoogleMapsApiKey
    Ensure-DebugStateDirectory
    Restore-WebGoogleMapsApiKey -PersistedBackupFile $backupFilePath
    Set-WebGoogleMapsApiKey -PersistBackupFile $backupFilePath
    Write-DebugDefinesFile -FilePath $definesFilePath
    Write-Host "Prepared debug lane: $($laneInfo.Name)" -ForegroundColor $laneInfo.Color
    Write-Host $laneInfo.Description -ForegroundColor $laneInfo.Color
}

function Cleanup-DebugState {
    $profiles = @()

    if ([string]::IsNullOrWhiteSpace($DebugProfile)) {
        if (-not (Test-Path $debugStateDirectory)) {
            return
        }

        $profiles = @(
            Get-ChildItem -Path $debugStateDirectory -Filter '*.defines.json' -ErrorAction SilentlyContinue | ForEach-Object {
                $_.BaseName -replace '\.defines$', ''
            }
            Get-ChildItem -Path $debugStateDirectory -Filter '*.web_index.backup.html' -ErrorAction SilentlyContinue | ForEach-Object {
                $_.BaseName -replace '\.web_index\.backup$', ''
            }
        ) | Sort-Object -Unique
    }
    else {
        $profiles = @(Get-DebugProfileName -ProvidedProfile $DebugProfile)
    }

    foreach ($profileName in $profiles) {
        $definesFilePath = Get-DebugDefinesFilePath -ProfileName $profileName
        $backupFilePath = Get-DebugWebIndexBackupFilePath -ProfileName $profileName

        Restore-WebGoogleMapsApiKey -PersistedBackupFile $backupFilePath
        if (Test-Path $definesFilePath) {
            Remove-Item -LiteralPath $definesFilePath -Force -ErrorAction SilentlyContinue
        }
    }

    if (Test-Path $debugStateDirectory) {
        $remainingItems = @(Get-ChildItem -Path $debugStateDirectory -Force -ErrorAction SilentlyContinue)
        if ($remainingItems.Count -eq 0) {
            Remove-Item -LiteralPath $debugStateDirectory -Force -ErrorAction SilentlyContinue
        }
    }
}

if ($Action -eq 'prepare') {
    Prepare-DebugState
    exit 0
}

Cleanup-DebugState
