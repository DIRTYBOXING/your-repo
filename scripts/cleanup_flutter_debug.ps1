param(
    [string]$WorkspacePath = ''
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($WorkspacePath)) {
    $WorkspacePath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}
else {
    $WorkspacePath = (Resolve-Path $WorkspacePath).Path
}

$workspacePattern = [Regex]::Escape($WorkspacePath)
$stoppedProcessIds = New-Object 'System.Collections.Generic.HashSet[int]'

function Test-IsFlutterWebRunCommandLine {
    param(
        [string]$CommandLine
    )

    if ([string]::IsNullOrWhiteSpace($CommandLine)) {
        return $false
    }

    if ($CommandLine -notmatch 'flutter_tools\.snapshot\s+run') {
        return $false
    }

    if ($CommandLine -match '--web-port(?:=|\s+)' -or $CommandLine -match '(?:^|\s)-d\s+(chrome|web-server|edge)(?:\s|$)') {
        return $true
    }

    return $CommandLine -match $workspacePattern
}

function Stop-TrackedProcess {
    param(
        [int]$ProcessId
    )

    if (-not $ProcessId) {
        return
    }

    if (-not $stoppedProcessIds.Add($ProcessId)) {
        return
    }

    try {
        Stop-Process -Id $ProcessId -Force -ErrorAction Stop
        Write-Host "Stopped PID $ProcessId"
    }
    catch {
        if ($_.Exception.Message -match 'process with the process identifier .* was not running|Cannot find a process with the process identifier') {
            return
        }

        throw
    }
}

$flutterRunProcesses = @(Get-CimInstance Win32_Process -Filter "Name = 'dart.exe' OR Name = 'dartvm.exe' OR Name = 'flutter.exe'" -ErrorAction SilentlyContinue | Where-Object {
        $commandLine = $_.CommandLine
        return (Test-IsFlutterWebRunCommandLine -CommandLine $commandLine)
    })

foreach ($flutterRunProcess in $flutterRunProcesses) {
    Stop-TrackedProcess -ProcessId $flutterRunProcess.ProcessId
}

$flutterBrowserProcesses = @(Get-CimInstance Win32_Process -Filter "Name = 'chrome.exe' OR Name = 'msedge.exe'" -ErrorAction SilentlyContinue | Where-Object {
        $commandLine = $_.CommandLine
        if ([string]::IsNullOrWhiteSpace($commandLine)) {
            return $false
        }

        return $commandLine -match 'flutter_tools_chrome_device'
    })

foreach ($flutterBrowserProcess in $flutterBrowserProcesses) {
    Stop-TrackedProcess -ProcessId $flutterBrowserProcess.ProcessId
}

if ($stoppedProcessIds.Count -eq 0) {
    Write-Host 'No stale Flutter web debug processes found.'
}
