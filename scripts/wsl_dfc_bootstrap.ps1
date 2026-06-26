param(
    [ValidateSet('Verify', 'Sync', 'Open')]
    [string]$Action = 'Verify',
    [string]$Distro = 'Ubuntu',
    [string]$TargetPath = '~/src/data-fight-central'
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$dockerCliPath = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe'

function Get-CodeExecutablePath {
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

function Get-WslDistros {
    $output = & wsl -l -q 2>$null
    if ($LASTEXITCODE -ne 0) {
        return @()
    }

    return @($output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() })
}

function Assert-WslDistro {
    param(
        [string]$Name
    )

    $distros = Get-WslDistros
    if ($distros -notcontains $Name) {
        throw "WSL distro '$Name' is not installed. Install it with: wsl --install -d $Name"
    }
}

function Invoke-WslCapture {
    param(
        [string]$DistroName,
        [string]$Command
    )

    $output = & wsl -d $DistroName bash -lc $Command
    if ($LASTEXITCODE -ne 0) {
        throw "WSL command failed: $Command"
    }

    return ($output | Out-String).Trim()
}

function Get-WslUser {
    param(
        [string]$DistroName
    )

    return Invoke-WslCapture -DistroName $DistroName -Command 'whoami'
}

function Resolve-LinuxPath {
    param(
        [string]$LinuxPath,
        [string]$LinuxUser
    )

    if ($LinuxPath.StartsWith('~/')) {
        return "/home/$LinuxUser/$($LinuxPath.Substring(2))"
    }

    if ($LinuxPath -eq '~') {
        return "/home/$LinuxUser"
    }

    return $LinuxPath
}

function Convert-ToWslSharePath {
    param(
        [string]$DistroName,
        [string]$LinuxPath
    )

    $trimmedLinuxPath = $LinuxPath.TrimStart('/')
    $windowsRelativePath = $trimmedLinuxPath -replace '/', '\\'
    return "\\\\wsl$\\$DistroName\\$windowsRelativePath"
}

function Assert-DockerDesktopInstalled {
    if (-not (Test-Path $dockerCliPath)) {
        throw "Docker Desktop CLI was not found at $dockerCliPath"
    }
}

function Test-UbuntuDockerAccess {
    param(
        [string]$DistroName
    )

    & wsl -d $DistroName bash -lc 'docker version >/dev/null 2>&1'
    return ($LASTEXITCODE -eq 0)
}

function Sync-RepoToWsl {
    param(
        [string]$DistroName,
        [string]$DestinationLinuxPath
    )

    $linuxUser = Get-WslUser -DistroName $DistroName
    $resolvedLinuxPath = Resolve-LinuxPath -LinuxPath $DestinationLinuxPath -LinuxUser $linuxUser
    $windowsTargetPath = Convert-ToWslSharePath -DistroName $DistroName -LinuxPath $resolvedLinuxPath

    Invoke-WslCapture -DistroName $DistroName -Command "mkdir -p '$resolvedLinuxPath'"
    New-Item -ItemType Directory -Force -Path $windowsTargetPath | Out-Null

    $robocopyArgs = @(
        $repoRoot,
        $windowsTargetPath,
        '/MIR',
        '/FFT',
        '/R:1',
        '/W:1',
        '/NP',
        '/XD',
        '.dart_tool',
        'build',
        'logs',
        'node_modules',
        'playwright-report',
        'test-results'
    )

    & robocopy @robocopyArgs | Out-Host
    $robocopyExitCode = $LASTEXITCODE
    if ($robocopyExitCode -gt 7) {
        throw "robocopy failed with exit code $robocopyExitCode"
    }

    return $resolvedLinuxPath
}

switch ($Action) {
    'Verify' {
        Assert-DockerDesktopInstalled

        Write-Host '==> Docker Desktop engine' -ForegroundColor Cyan
        & $dockerCliPath version
        if ($LASTEXITCODE -ne 0) {
            throw 'Docker Desktop is installed but the engine is not responding.'
        }

        Write-Host ''
        Write-Host '==> WSL distros' -ForegroundColor Cyan
        & wsl -l -v
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to query WSL distros.'
        }

        $distros = Get-WslDistros
        if ($distros -notcontains $Distro) {
            Write-Warning "Install Ubuntu with: wsl --install -d $Distro"
            return
        }

        if (Test-UbuntuDockerAccess -DistroName $Distro) {
            Write-Host ''
            Write-Host '==> Ubuntu Docker integration' -ForegroundColor Cyan
            & wsl -d $Distro bash -lc 'docker --version && docker compose version'
            if ($LASTEXITCODE -ne 0) {
                throw 'Docker integration check failed inside Ubuntu.'
            }
        }
        else {
            Write-Warning "Ubuntu is installed but Docker is not exposed inside it yet. In Docker Desktop enable Settings > Resources > WSL Integration > $Distro."
        }
    }
    'Sync' {
        Assert-WslDistro -Name $Distro
        $resolvedLinuxPath = Sync-RepoToWsl -DistroName $Distro -DestinationLinuxPath $TargetPath

        Write-Host ''
        Write-Host "Synced repo into WSL at $resolvedLinuxPath" -ForegroundColor Green
        Write-Host "Next step: run the VS Code task 'WSL: Open Repo In Ubuntu' or execute 'code $resolvedLinuxPath' inside $Distro."
    }
    'Open' {
        Assert-WslDistro -Name $Distro
        $resolvedLinuxPath = Sync-RepoToWsl -DistroName $Distro -DestinationLinuxPath $TargetPath
        $codeExecutablePath = Get-CodeExecutablePath
        $folderUri = "vscode-remote://wsl+$Distro$resolvedLinuxPath"

        Start-Process -FilePath $codeExecutablePath -ArgumentList @('--folder-uri', $folderUri) | Out-Null

        Write-Host ''
        Write-Host "Opened $resolvedLinuxPath in VS Code Remote WSL." -ForegroundColor Green
        Write-Host 'After the window opens, run Dev Containers: Reopen in Container for backend and Docker work.'
        Write-Host 'Keep the Windows workspace for Flutter web + Chrome debug when you need the fastest demo lane.'
    }
}
