param(
    [int]$DockerReadyTimeoutSeconds = 480,
    [int]$DockerProbeTimeoutSeconds = 15,
    [int]$WslProbeTimeoutSeconds = 20,
    [int]$PollIntervalSeconds = 8
)

$ErrorActionPreference = 'Stop'

function Resolve-DockerCliPath {
    $dockerCommand = Get-Command docker -ErrorAction SilentlyContinue
    if ($dockerCommand -and $dockerCommand.Source) {
        return $dockerCommand.Source
    }

    $candidates = @(
        'C:\Program Files\Docker\Docker\resources\bin\docker.exe',
        'C:\Program Files\Docker\Docker\Docker\resources\bin\docker.exe'
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

function Resolve-WslCliPath {
    $wslCommand = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wslCommand -and $wslCommand.Source) {
        return $wslCommand.Source
    }

    $candidate = 'C:\Windows\System32\wsl.exe'
    if (Test-Path $candidate) {
        return $candidate
    }

    return $null
}

function Resolve-DockerDesktopPath {
    $candidates = @(
        'C:\Program Files\Docker\Docker\Docker Desktop.exe',
        'C:\Program Files\Docker\Docker\Docker Desktop Installer.exe'
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

function Get-DotEnvValue {
    param(
        [string]$FilePath,
        [string]$Key
    )

    if (-not (Test-Path $FilePath)) {
        return $null
    }

    $match = Select-String -Path $FilePath -Pattern "^$([regex]::Escape($Key))\s*=\s*(.+)$" | Select-Object -First 1
    if (-not $match) {
        return $null
    }

    $value = $match.Matches[0].Groups[1].Value.Trim()
    if ($value.StartsWith('"') -and $value.EndsWith('"')) {
        $value = $value.Substring(1, $value.Length - 2)
    }
    elseif ($value.StartsWith("'") -and $value.EndsWith("'")) {
        $value = $value.Substring(1, $value.Length - 2)
    }

    return $value
}

function Resolve-CredentialPath {
    param(
        [string]$RepoRoot
    )

    if ($env:GOOGLE_APPLICATION_CREDENTIALS) {
        return $env:GOOGLE_APPLICATION_CREDENTIALS
    }

    $dotEnvPath = Join-Path $RepoRoot '.env'
    $dotEnvValue = Get-DotEnvValue -FilePath $dotEnvPath -Key 'GOOGLE_APPLICATION_CREDENTIALS'
    if ($dotEnvValue) {
        $env:GOOGLE_APPLICATION_CREDENTIALS = $dotEnvValue
        return $dotEnvValue
    }

    return $null
}

function Invoke-ProcessCapture {
    param(
        [string]$FilePath,
        [string[]]$Arguments = @(),
        [int]$TimeoutSeconds = 15,
        [string]$WorkingDirectory = $null
    )

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $FilePath
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true

    if ($WorkingDirectory) {
        $startInfo.WorkingDirectory = $WorkingDirectory
    }

    foreach ($argument in $Arguments) {
        [void]$startInfo.ArgumentList.Add($argument)
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    [void]$process.Start()

    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        try {
            $process.Kill($true)
        }
        catch {
        }

        return [pscustomobject]@{
            Succeeded = $false
            TimedOut  = $true
            ExitCode  = $null
            StdOut    = ''
            StdErr    = ''
            Combined  = ''
        }
    }

    $stdOut = $process.StandardOutput.ReadToEnd().Trim()
    $stdErr = $process.StandardError.ReadToEnd().Trim()
    $combined = @($stdOut, $stdErr) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    return [pscustomobject]@{
        Succeeded = ($process.ExitCode -eq 0)
        TimedOut  = $false
        ExitCode  = $process.ExitCode
        StdOut    = $stdOut
        StdErr    = $stdErr
        Combined  = ($combined -join [Environment]::NewLine)
    }
}

function Test-DockerEngine {
    param(
        [string]$DockerCliPath,
        [int]$TimeoutSeconds = 15
    )

    return Invoke-ProcessCapture -FilePath $DockerCliPath -Arguments @('version') -TimeoutSeconds $TimeoutSeconds
}

function Test-WslResponsive {
    param(
        [string]$WslCliPath,
        [int]$TimeoutSeconds = 20
    )

    return Invoke-ProcessCapture -FilePath $WslCliPath -Arguments @('-l', '-q') -TimeoutSeconds $TimeoutSeconds
}

function Invoke-WslSoftReset {
    param(
        [string]$WslCliPath,
        [int]$TimeoutSeconds = 20
    )

    Write-Host 'Attempting a WSL soft reset...' -ForegroundColor Yellow
    $result = Invoke-ProcessCapture -FilePath $WslCliPath -Arguments @('--shutdown') -TimeoutSeconds $TimeoutSeconds
    if ($result.TimedOut) {
        Write-Warning 'WSL soft reset timed out. A full Windows reboot may still be required.'
        return $false
    }

    if (-not $result.Succeeded -and $result.Combined) {
        Write-Warning "WSL soft reset returned an error: $($result.Combined)"
        return $false
    }

    return $true
}

function Start-DockerDesktop {
    param(
        [string]$DockerDesktopPath,
        [switch]$ForceRestart
    )

    if (-not $DockerDesktopPath) {
        return
    }

    $existingProcess = Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue
    if ($ForceRestart -and $existingProcess) {
        Write-Host 'Restarting Docker Desktop...' -ForegroundColor Yellow
        $existingProcess | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
    }

    if (-not (Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue)) {
        Write-Host 'Launching Docker Desktop...' -ForegroundColor Yellow
        Start-Process -FilePath $DockerDesktopPath | Out-Null
    }
}

function Wait-DockerEnvironment {
    param(
        [string]$DockerCliPath,
        [string]$DockerDesktopPath,
        [string]$WslCliPath,
        [int]$ReadyTimeoutSeconds,
        [int]$DockerProbeTimeoutSeconds,
        [int]$WslProbeTimeoutSeconds,
        [int]$PollIntervalSeconds
    )

    $deadline = (Get-Date).AddSeconds($ReadyTimeoutSeconds)
    $softResetAttempted = $false
    $lastDockerResult = $null
    $lastWslResult = $null

    Start-DockerDesktop -DockerDesktopPath $DockerDesktopPath

    while ((Get-Date) -lt $deadline) {
        $lastWslResult = Test-WslResponsive -WslCliPath $WslCliPath -TimeoutSeconds $WslProbeTimeoutSeconds
        if ($lastWslResult.Succeeded) {
            $lastDockerResult = Test-DockerEngine -DockerCliPath $DockerCliPath -TimeoutSeconds $DockerProbeTimeoutSeconds
            if ($lastDockerResult.Succeeded) {
                Write-Host 'Docker Desktop engine is ready.' -ForegroundColor Green
                return
            }

            Write-Host 'Docker engine is not ready yet. Waiting for Docker Desktop to finish starting...' -ForegroundColor Yellow
        }
        elseif ($lastWslResult.TimedOut) {
            Write-Host 'WSL is still not responding. Waiting before retrying Docker Desktop...' -ForegroundColor Yellow
        }
        else {
            $message = if ($lastWslResult.Combined) { $lastWslResult.Combined } else { 'unknown WSL error' }
            Write-Host "WSL probe failed: $message" -ForegroundColor Yellow
        }

        if (-not $softResetAttempted -and ($deadline - (Get-Date)).TotalSeconds -le ($ReadyTimeoutSeconds - 90)) {
            $softResetAttempted = $true
            [void](Invoke-WslSoftReset -WslCliPath $WslCliPath -TimeoutSeconds $WslProbeTimeoutSeconds)
            Start-DockerDesktop -DockerDesktopPath $DockerDesktopPath -ForceRestart
        }

        Start-Sleep -Seconds $PollIntervalSeconds
    }

    $dockerDetail = if ($lastDockerResult -and $lastDockerResult.Combined) {
        $lastDockerResult.Combined
    }
    else {
        'Docker engine never became ready.'
    }

    $wslDetail = if ($lastWslResult -and $lastWslResult.Combined) {
        $lastWslResult.Combined
    }
    elseif ($lastWslResult -and $lastWslResult.TimedOut) {
        'WSL probe timed out.'
    }
    else {
        'WSL never became responsive.'
    }

    throw @"
Docker Desktop did not become ready within $ReadyTimeoutSeconds seconds.

Last WSL result:
    $wslDetail

Last Docker result:
    $dockerDetail

If this happens again after a fresh Windows reboot, verify these manually:
    wsl --status
    wsl -l -v
    & '$DockerCliPath' version
"@
}

function Wait-TcpPort {
    param(
        [string]$TargetAddress,
        [int]$Port,
        [int]$TimeoutSeconds = 60
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $iar = $client.BeginConnect($TargetAddress, $Port, $null, $null)
            if ($iar.AsyncWaitHandle.WaitOne(1000, $false)) {
                $client.EndConnect($iar)
                Write-Host "Service ${TargetAddress}:${Port} is up" -ForegroundColor Green
                return
            }
        }
        catch {
            # retry
        }
        finally {
            $client.Dispose()
        }

        Start-Sleep -Seconds 1
    }

    throw "Timeout waiting for ${TargetAddress}:${Port}"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
Set-Location $repoRoot

$dockerCliPath = Resolve-DockerCliPath
$wslCliPath = Resolve-WslCliPath
if (-not $dockerCliPath) {
    throw @"
Docker is not installed or not available on PATH.

This compose stack requires Docker Desktop on Windows.
The Flutter/Firebase real-auth lane does not require Docker.

Install path for this machine:
    1. Run: wsl --install
    2. Reboot Windows
    3. Run: winget install -e --id Docker.DockerDesktop
    4. Start Docker Desktop and enable the WSL 2 backend
    5. Verify: docker --version
    6. Verify: docker compose version
    7. Re-run this task
"@
}

if (-not $wslCliPath) {
    throw 'WSL CLI was not found. Verify that WSL is installed and available on this machine.'
}

$credentialPath = Resolve-CredentialPath -RepoRoot $repoRoot
if (-not $credentialPath) {
    throw @"
GOOGLE_APPLICATION_CREDENTIALS is not set.

Set it in the current shell or in the repo-root .env file to the host path of your Firebase service account JSON before starting the compose stack.
- PowerShell example: `$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\secrets\dfc-service-account.json'`
- WSL example: `export GOOGLE_APPLICATION_CREDENTIALS=/home/<user>/secrets/dfc-service-account.json`
"@
}

if (-not (Test-Path $credentialPath)) {
    throw "GOOGLE_APPLICATION_CREDENTIALS points to a missing file: $credentialPath"
}

$dockerDesktopPath = Resolve-DockerDesktopPath
$dockerEngineResult = Test-DockerEngine -DockerCliPath $dockerCliPath -TimeoutSeconds $DockerProbeTimeoutSeconds
if (-not $dockerEngineResult.Succeeded) {
    Wait-DockerEnvironment `
        -DockerCliPath $dockerCliPath `
        -DockerDesktopPath $dockerDesktopPath `
        -WslCliPath $wslCliPath `
        -ReadyTimeoutSeconds $DockerReadyTimeoutSeconds `
        -DockerProbeTimeoutSeconds $DockerProbeTimeoutSeconds `
        -WslProbeTimeoutSeconds $WslProbeTimeoutSeconds `
        -PollIntervalSeconds $PollIntervalSeconds
}

Write-Host 'Starting docker compose stack...' -ForegroundColor Cyan
& $dockerCliPath compose up -d --build
if ($LASTEXITCODE -ne 0) { throw 'docker compose up failed' }

$n8nPort = 5678
if ($env:N8N_PORT) {
    [void][int]::TryParse($env:N8N_PORT, [ref]$n8nPort)
}

Wait-TcpPort -TargetAddress 'localhost' -Port 8000 -TimeoutSeconds 90
Wait-TcpPort -TargetAddress 'localhost' -Port 5432 -TimeoutSeconds 90
Wait-TcpPort -TargetAddress 'localhost' -Port 6379 -TimeoutSeconds 90
Wait-TcpPort -TargetAddress 'localhost' -Port $n8nPort -TimeoutSeconds 90

Write-Host 'All infra healthy' -ForegroundColor Green
