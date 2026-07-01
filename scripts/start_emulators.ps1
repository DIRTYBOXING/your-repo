# ------------------------------------------------------------------
# Firebase Local Emulator Suite - start all emulators
#
# Usage:
#   .\scripts\start_emulators.ps1            # start fresh
#   .\scripts\start_emulators.ps1 -Import    # start with saved data
#   .\scripts\start_emulators.ps1 -Export    # start and export on shutdown
#   .\scripts\start_emulators.ps1 -KillExisting # stop stale Firebase emulator processes first
#
# Ports:
#   Emulator UI  -> http://localhost:4000
#   Auth         -> localhost:9099
#   Firestore    -> localhost:8080
#   Functions    -> localhost:5001
#   Storage      -> localhost:9199
#
# To connect Flutter, set _useEmulator = true in lib/main.dart
# ------------------------------------------------------------------

param(
    [switch]$Import,
    [switch]$Export,
    [switch]$KillExisting
)

$ErrorActionPreference = "Stop"

$emulatorPorts = @(4000, 4400, 4500, 5000, 8080, 9099, 9199)

function Get-NodeMajorVersion {
    param(
        [string]$NodeExecutable = "node"
    )

    try {
        $versionOutput = & $NodeExecutable --version 2>&1 | Out-String
        $match = [regex]::Match($versionOutput, 'v(?<major>\d+)')
        if ($match.Success) {
            return [int]$match.Groups['major'].Value
        }
    }
    catch {
        return $null
    }

    return $null
}

function Get-FunctionsRequestedNodeMajor {
    param(
        [string]$RepoRoot
    )

    $packageJsonPath = Join-Path $RepoRoot 'functions\package.json'
    if (-not (Test-Path $packageJsonPath)) {
        return $null
    }

    try {
        $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
        $requestedVersion = [string]$packageJson.engines.node
        $match = [regex]::Match($requestedVersion, '(?<major>\d+)')
        if ($match.Success) {
            return [int]$match.Groups['major'].Value
        }
    }
    catch {
        return $null
    }

    return $null
}

function Get-FirebaseCliJavaScriptPath {
    $npmCommand = Get-Command npm -ErrorAction SilentlyContinue
    if ($npmCommand -and $npmCommand.Source) {
        try {
            $globalRoot = (& $npmCommand.Source root -g 2>$null | Out-String).Trim()
            if ($globalRoot) {
                $jsPath = Join-Path $globalRoot 'firebase-tools\lib\bin\firebase.js'
                if (Test-Path $jsPath) {
                    return $jsPath
                }
            }
        }
        catch {
        }
    }

    $firebaseCmd = Get-Command firebase.cmd -ErrorAction SilentlyContinue
    if ($firebaseCmd -and $firebaseCmd.Source) {
        $candidate = Join-Path (Split-Path $firebaseCmd.Source -Parent) 'node_modules\firebase-tools\lib\bin\firebase.js'
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

function Invoke-FirebaseCli {
    param(
        [string[]]$FirebaseArguments,
        [int]$RequestedNodeMajor,
        [int]$HostNodeMajor
    )

    $shouldUseRequestedNode = $RequestedNodeMajor -and $HostNodeMajor -and ($RequestedNodeMajor -ne $HostNodeMajor)

    if ($shouldUseRequestedNode) {
        $npxCommand = Get-Command npx -ErrorAction SilentlyContinue
        $firebaseCliJs = Get-FirebaseCliJavaScriptPath

        if ($npxCommand -and $npxCommand.Source -and $firebaseCliJs) {
            Write-Host "Launching Firebase CLI with Node $RequestedNodeMajor to match functions/package.json" -ForegroundColor Cyan
            & $npxCommand.Source '-y' "node@$RequestedNodeMajor" $firebaseCliJs @FirebaseArguments
            return
        }

        Write-Host "Unable to launch Firebase CLI with Node $RequestedNodeMajor automatically; falling back to host Node $HostNodeMajor." -ForegroundColor Yellow
    }

    & firebase @FirebaseArguments
}

function Get-JavaMajorVersion {
    param(
        [string]$JavaExecutable = "java"
    )

    try {
        $versionOutput = & $JavaExecutable -version 2>&1 | Out-String
        $match = [regex]::Match($versionOutput, 'version\s+"(?<major>\d+)')
        if ($match.Success) {
            return [int]$match.Groups['major'].Value
        }
    }
    catch {
        return $null
    }

    return $null
}

function Get-JavaMajorFromExecutablePath {
    param(
        [string]$JavaExecutable
    )

    try {
        $javaHome = Split-Path -Parent (Split-Path -Parent $JavaExecutable)
        $folderName = Split-Path -Leaf $javaHome
        $match = [regex]::Match($folderName, '(?<major>\d+)')
        if ($match.Success) {
            return [int]$match.Groups['major'].Value
        }
    }
    catch {
        return $null
    }

    return $null
}

function Use-JavaHome {
    param(
        [string]$JavaHome
    )

    $env:JAVA_HOME = $JavaHome
    $javaBin = Join-Path $JavaHome 'bin'
    $pathEntries = @($env:Path -split ';' | Where-Object { $_ -and $_.Trim().Length -gt 0 })
    $pathEntries = @($javaBin) + ($pathEntries | Where-Object { $_ -ne $javaBin })
    $env:Path = ($pathEntries -join ';')
}

function Get-PortListeners {
    param(
        [int[]]$Ports
    )

    $connections = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalPort -in $Ports }

    $listeners = foreach ($connection in ($connections | Sort-Object LocalPort, OwningProcess -Unique)) {
        $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Port        = $connection.LocalPort
            ProcessId   = $connection.OwningProcess
            ProcessName = if ($process) { $process.ProcessName } else { 'Unknown' }
            Path        = if ($process) { $process.Path } else { '' }
        }
    }

    return @($listeners)
}

function Show-PortListeners {
    param(
        [object[]]$Listeners
    )

    if (-not $Listeners -or $Listeners.Count -eq 0) {
        return
    }

    Write-Host "The following processes are already listening on Firebase emulator ports:" -ForegroundColor Yellow
    $Listeners |
    Select-Object Port, ProcessId, ProcessName, Path |
    Format-Table -AutoSize |
    Out-String |
    Write-Host
}

function Stop-StaleEmulatorProcesses {
    param(
        [object[]]$Listeners
    )

    if (-not $Listeners -or $Listeners.Count -eq 0) {
        return
    }

    $stoppable = @($Listeners | Where-Object { $_.ProcessName -in @('node', 'java', 'firebase') } | Sort-Object ProcessId -Unique)

    if ($stoppable.Count -eq 0) {
        return
    }

    Write-Host "Stopping stale emulator processes..." -ForegroundColor Yellow
    foreach ($process in $stoppable) {
        try {
            Stop-Process -Id $process.ProcessId -Force -ErrorAction Stop
            Write-Host "Stopped PID $($process.ProcessId) ($($process.ProcessName))" -ForegroundColor DarkGray
        }
        catch {
            Write-Host "Failed to stop PID $($process.ProcessId) ($($process.ProcessName)): $_" -ForegroundColor Red
            throw
        }
    }

    Start-Sleep -Seconds 2
}

# Verify firebase CLI is available
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "Firebase CLI not found. Install via: npm install -g firebase-tools" -ForegroundColor Red
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
Set-Location $repoRoot

if ([string]::IsNullOrWhiteSpace($env:FUNCTIONS_DISCOVERY_TIMEOUT)) {
    $env:FUNCTIONS_DISCOVERY_TIMEOUT = '30'
}

$requestedNodeMajor = Get-FunctionsRequestedNodeMajor -RepoRoot $repoRoot
$hostNodeMajor = Get-NodeMajorVersion
if ($requestedNodeMajor -and $hostNodeMajor) {
    Write-Host "Functions runtime requests Node $requestedNodeMajor; host Node is $hostNodeMajor" -ForegroundColor DarkGray
}

$javaCandidates = @()

if ($env:JAVA_HOME) {
    $javaCandidates += (Join-Path $env:JAVA_HOME 'bin\java.exe')
}

$searchPatterns = @(
    'C:\Program Files\Microsoft\jdk*\bin\java.exe',
    'C:\Program Files\Eclipse Adoptium\jdk*\bin\java.exe',
    'C:\Program Files\Eclipse Adoptium\temurin*\bin\java.exe',
    'C:\Program Files\Java\jdk*\bin\java.exe'
)

foreach ($pattern in $searchPatterns) {
    $matches = Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue
    foreach ($match in $matches) {
        $javaCandidates += $match.FullName
    }
}

$selectedJavaExe = $null
$javaMajor = $null

foreach ($candidate in ($javaCandidates | Select-Object -Unique)) {
    if (-not (Test-Path $candidate)) {
        continue
    }

    $candidateMajor = Get-JavaMajorVersion -JavaExecutable $candidate
    if (-not $candidateMajor) {
        $candidateMajor = Get-JavaMajorFromExecutablePath -JavaExecutable $candidate
    }

    if ($candidateMajor -and $candidateMajor -ge 21) {
        $selectedJavaExe = $candidate
        $javaMajor = $candidateMajor
        break
    }
}

if (-not $selectedJavaExe) {
    Write-Host "Java 21+ is required by the Firebase Emulator Suite on this machine." -ForegroundColor Red
    Write-Host "   Install Microsoft OpenJDK 21 or Temurin 21, then rerun this script." -ForegroundColor Red
    exit 1
}

$javaHome = Split-Path -Parent (Split-Path -Parent $selectedJavaExe)
Use-JavaHome -JavaHome $javaHome
Write-Host "Using Java from $javaHome" -ForegroundColor Cyan

$listeners = Get-PortListeners -Ports $emulatorPorts
if ($listeners.Count -gt 0) {
    Show-PortListeners -Listeners $listeners

    if ($KillExisting) {
        Stop-StaleEmulatorProcesses -Listeners $listeners
        $listeners = Get-PortListeners -Ports $emulatorPorts
    }

    if ($listeners.Count -gt 0) {
        Write-Host "Firebase emulator ports are still occupied." -ForegroundColor Red
        Write-Host "Rerun with -KillExisting to stop stale emulator processes, or free these ports manually." -ForegroundColor Red
        exit 1
    }
}

# Build the command
$firebaseArgs = @('emulators:start', '--project', 'datafightcentral')

if ($Import) {
    $firebaseArgs += '--import=./emulator-data'
    Write-Host "Importing saved emulator data from ./emulator-data" -ForegroundColor Cyan
}

if ($Export) {
    $firebaseArgs += '--export-on-exit=./emulator-data'
    Write-Host "Data will be exported to ./emulator-data on shutdown" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Starting Firebase Emulator Suite..." -ForegroundColor Yellow
Write-Host "   UI:        http://localhost:4000" -ForegroundColor DarkGray
Write-Host "   Auth:      localhost:9099" -ForegroundColor DarkGray
Write-Host "   Firestore: localhost:8080" -ForegroundColor DarkGray
Write-Host "   Functions: localhost:5001" -ForegroundColor DarkGray
Write-Host "   Storage:   localhost:9199" -ForegroundColor DarkGray
Write-Host "   Project:   datafightcentral" -ForegroundColor DarkGray
Write-Host "   Java:      $javaMajor" -ForegroundColor DarkGray
Write-Host "   Discovery: $($env:FUNCTIONS_DISCOVERY_TIMEOUT)s" -ForegroundColor DarkGray
Write-Host ""
Write-Host '   Set _useEmulator = true in lib/main.dart to connect Flutter' -ForegroundColor DarkGray
Write-Host ""

Invoke-FirebaseCli -FirebaseArguments $firebaseArgs -RequestedNodeMajor $requestedNodeMajor -HostNodeMajor $hostNodeMajor
