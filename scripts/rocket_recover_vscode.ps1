param(
    [string]$WorkspacePath = '',
    [switch]$SkipTempCleanup,
    [switch]$DryRun,
    [int]$RelaunchDelayMs = 1500
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($WorkspacePath)) {
    $WorkspacePath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}
else {
    $WorkspacePath = (Resolve-Path $WorkspacePath).Path
}

function Get-CodeExecutablePath {
    $codeProcesses = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like 'Code*' })
    foreach ($codeProcess in $codeProcesses) {
        if ($codeProcess.Path -and (Test-Path $codeProcess.Path)) {
            return $codeProcess.Path
        }
    }

    $codeCommand = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCommand -and $codeCommand.Source) {
        $commandSource = $codeCommand.Source
        if ($commandSource -match '[\\/]bin[\\/]code(?:\.cmd)?$') {
            $candidate = [System.IO.Path]::GetFullPath((Join-Path (Split-Path $commandSource -Parent) '..\Code.exe'))
            if (Test-Path $candidate) {
                return $candidate
            }
        }

        return $commandSource
    }

    $candidates = @(
        (Join-Path $env:LocalAppData 'Programs\Microsoft VS Code\Code.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft VS Code\Code.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft VS Code\Code.exe')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    throw 'Unable to locate the Visual Studio Code executable.'
}

function Remove-StaleFlutterTempArtifacts {
    param(
        [string]$TempPath
    )

    if ([string]::IsNullOrWhiteSpace($TempPath) -or -not (Test-Path $TempPath)) {
        return
    }

    $entries = @(Get-ChildItem -Path $TempPath -Force -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match '^(flutter_tools|dart_tools)(\.|$)'
        })

    foreach ($entry in $entries) {
        try {
            Remove-Item -LiteralPath $entry.FullName -Recurse -Force -ErrorAction Stop
            Write-Host "Removed temp artifact $($entry.FullName)"
        }
        catch {
            Write-Warning "Could not remove temp artifact $($entry.FullName): $($_.Exception.Message)"
        }
    }
}

$codeExecutablePath = Get-CodeExecutablePath
$cleanupScriptPath = Join-Path $PSScriptRoot 'cleanup_flutter_debug.ps1'

if ($DryRun) {
    $tempArtifactCount = 0
    if (-not $SkipTempCleanup -and (Test-Path $env:TEMP)) {
        $tempArtifactCount = @(
            Get-ChildItem -Path $env:TEMP -Force -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -match '^(flutter_tools|dart_tools)(\.|$)'
            }
        ).Count
    }

    Write-Host "Rocket recovery dry run"
    Write-Host "Workspace: $WorkspacePath"
    Write-Host "VS Code executable: $codeExecutablePath"
    Write-Host "Cleanup script present: $(Test-Path $cleanupScriptPath)"
    Write-Host "Skip temp cleanup: $SkipTempCleanup"
    Write-Host "Temp artifacts matched: $tempArtifactCount"
    Write-Host "Relaunch delay ms: $RelaunchDelayMs"
    return
}

if (Test-Path $cleanupScriptPath) {
    & $cleanupScriptPath -WorkspacePath $WorkspacePath
}

if (-not $SkipTempCleanup) {
    Remove-StaleFlutterTempArtifacts -TempPath $env:TEMP
}

$escapedCodeExecutablePath = $codeExecutablePath.Replace("'", "''")
$escapedWorkspacePath = $WorkspacePath.Replace("'", "''")
$relaunchCommand = @"
`$codeExecutablePath = '$escapedCodeExecutablePath'
`$workspacePath = '$escapedWorkspacePath'
`$delayMs = $RelaunchDelayMs
Start-Sleep -Milliseconds `$delayMs
`$deadline = (Get-Date).AddSeconds(20)
do {
    `$runningCodeProcesses = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { `$_.ProcessName -like 'Code*' })
    if (`$runningCodeProcesses.Count -eq 0) {
        break
    }

    Start-Sleep -Milliseconds 250
} while ((Get-Date) -lt `$deadline)

Start-Process -FilePath `$codeExecutablePath -ArgumentList @('--reuse-window', `$workspacePath) | Out-Null
"@

Start-Process -FilePath 'pwsh' -WindowStyle Hidden -ArgumentList @(
    '-NoProfile',
    '-ExecutionPolicy',
    'Bypass',
    '-Command',
    $relaunchCommand
) | Out-Null

$codeProcesses = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like 'Code*' } | Sort-Object Id -Descending)
if ($codeProcesses.Count -eq 0) {
    Write-Host "No active VS Code process found. Scheduled reopen for $WorkspacePath"
    return
}

foreach ($codeProcess in $codeProcesses) {
    try {
        Stop-Process -Id $codeProcess.Id -Force -ErrorAction Stop
        Write-Host "Stopped VS Code PID $($codeProcess.Id)"
    }
    catch {
        Write-Warning "Could not stop VS Code PID $($codeProcess.Id): $($_.Exception.Message)"
    }
}

Write-Host "Scheduled VS Code relaunch for $WorkspacePath"
