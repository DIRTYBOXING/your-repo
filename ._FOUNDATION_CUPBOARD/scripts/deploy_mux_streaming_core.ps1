param(
    [string]$ProjectId = 'datafightcentral',
    [int]$MaxAttempts = 4,
    [int]$InitialBackoffSeconds = 2,
    [string]$LockName = 'dfc-mux-deploy-lock',
    [string[]]$Functions = @(
        'testMuxAuth',
        'createMuxLiveStream',
        'resendMuxCredentialPack',
        'getMuxPlaybackUrl',
        'disableMuxStream',
        'getMuxStreamStatus',
        'getMuxVodReplay',
        'muxWebhook'
    )
)

$ErrorActionPreference = 'Stop'

function New-DeployLockPath {
    param(
        [string]$Name
    )

    return Join-Path ([System.IO.Path]::GetTempPath()) $Name
}

function New-DeployLock {
    param(
        [string]$Name
    )

    $lockPath = New-DeployLockPath -Name $Name
    if (Test-Path $lockPath) {
        throw "Another serialized Mux deploy is already running. Lock path: $lockPath"
    }

    New-Item -ItemType Directory -Path $lockPath | Out-Null
    return $lockPath
}

function Remove-DeployLock {
    param(
        [string]$Path
    )

    if ($Path -and (Test-Path $Path)) {
        Remove-Item -Path $Path -Recurse -Force
    }
}

function Test-TransientDeployConflict {
    param(
        [string[]]$OutputLines
    )

    $joinedOutput = ($OutputLines | Out-String)
    return $joinedOutput -match 'HTTP Error: 409' -or
    $joinedOutput -match 'unable to queue the operation' -or
    $joinedOutput -match 'resource is being created'
}

function Get-BackoffDelaySeconds {
    param(
        [int]$Attempt,
        [int]$InitialDelaySeconds
    )

    return [Math]::Min(30, $InitialDelaySeconds * [Math]::Pow(2, [Math]::Max(0, $Attempt - 1)))
}

$normalizedFunctions = @()
foreach ($functionEntry in $Functions) {
    if ([string]::IsNullOrWhiteSpace($functionEntry)) {
        continue
    }

    $normalizedFunctions += $functionEntry.Split(',') | ForEach-Object {
        $_.Trim()
    } | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    }
}

if ($normalizedFunctions.Count -eq 0) {
    throw 'At least one function name is required.'
}

if ($MaxAttempts -lt 1) {
    throw 'MaxAttempts must be at least 1.'
}

$lockPath = New-DeployLock -Name $LockName
try {
    foreach ($functionName in $normalizedFunctions) {
        if ([string]::IsNullOrWhiteSpace($functionName)) {
            continue
        }

        $normalizedName = $functionName.Trim()
        for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
            Write-Host "Deploying $normalizedName (attempt $attempt/$MaxAttempts)..." -ForegroundColor Cyan
            $output = &(Get-Command firebase).Source deploy --only "functions:$normalizedName" --project $ProjectId --non-interactive 2>&1
            $output | Out-Host

            if ($LASTEXITCODE -eq 0) {
                break
            }

            if ($attempt -lt $MaxAttempts -and (Test-TransientDeployConflict -OutputLines $output)) {
                $delaySeconds = [int](Get-BackoffDelaySeconds -Attempt $attempt -InitialDelaySeconds $InitialBackoffSeconds)
                Write-Warning "Transient deploy conflict for $normalizedName. Retrying after $delaySeconds seconds."
                Start-Sleep -Seconds $delaySeconds
                continue
            }

            throw "Failed to deploy $normalizedName."
        }
    }

    Write-Host 'Mux streaming core deploy completed.' -ForegroundColor Green
}
finally {
    Remove-DeployLock -Path $lockPath
}