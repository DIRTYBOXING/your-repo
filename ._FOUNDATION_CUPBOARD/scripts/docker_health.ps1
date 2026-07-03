param(
    [string[]]$CriticalServices = @(
        'db',
        'redis',
        'n8n',
        'n8n-worker',
        'predictor',
        'auto-clip-worker',
        'entitlements'
    ),
    [string[]]$OptionalServices = @(
        'ingest',
        'secrets'
    )
)

$ErrorActionPreference = 'Stop'

function Invoke-DockerText {
    param(
        [string[]]$DockerArgs
    )

    $output = & docker @DockerArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($output | Out-String).Trim()
    }

    return @($output)
}

function Test-ComposeServiceRunning {
    param(
        [string]$Service
    )

    $names = & docker ps --filter "label=com.docker.compose.service=$Service" --format '{{.Names}}'
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to query running containers.'
    }

    return @($names | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

Write-Host '1) Docker version'
Invoke-DockerText -DockerArgs @('version') | Out-Host

Write-Host ''
Write-Host '2) Docker info (summary)'
Invoke-DockerText -DockerArgs @('info', '--format', 'Server={{.ServerVersion}} OS={{.OperatingSystem}} Arch={{.Architecture}} Cgroup={{.CgroupDriver}}') | Out-Host

Write-Host ''
Write-Host '3) Running containers'
$rawContainers = Invoke-DockerText -DockerArgs @('ps', '--format', '{{.Names}}|{{.Status}}|{{.Image}}')
if ($rawContainers.Count -eq 0) {
    Write-Warning 'No running containers detected.'
}
else {
    $table = foreach ($entry in $rawContainers) {
        $parts = $entry -split '\|', 3
        [PSCustomObject]@{
            Name   = $parts[0]
            Status = $parts[1]
            Image  = $parts[2]
        }
    }

    $table | Format-Table -AutoSize | Out-Host
}

Write-Host ''
Write-Host '4) Critical services'
$missingCritical = @()
foreach ($service in $CriticalServices) {
    $containers = Test-ComposeServiceRunning -Service $service
    if ($containers.Count -gt 0) {
        Write-Host "OK $service -> $($containers -join ', ')"
    }
    else {
        Write-Host "MISSING $service"
        $missingCritical += $service
    }
}

Write-Host ''
Write-Host '5) Optional services'
foreach ($service in $OptionalServices) {
    $containers = Test-ComposeServiceRunning -Service $service
    if ($containers.Count -gt 0) {
        Write-Host "OK $service -> $($containers -join ', ')"
    }
    else {
        Write-Host "SKIP $service"
    }
}

Write-Host ''
Write-Host '6) Disk usage'
Invoke-DockerText -DockerArgs @('system', 'df') | Out-Host

Write-Host ''
if ($missingCritical.Count -gt 0) {
    Write-Error ("Docker health completed with missing critical services: " + ($missingCritical -join ', '))
    exit 1
}

Write-Host 'Docker health check completed'