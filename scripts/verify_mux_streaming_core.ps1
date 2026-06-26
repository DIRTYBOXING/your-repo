param(
    [string]$ProjectId = 'datafightcentral',
    [string]$Region = 'australia-southeast1',
    [string]$MuxBaseUrl = 'https://australia-southeast1-datafightcentral.cloudfunctions.net',
    [int]$PollIntervalSeconds = 10,
    [int]$MaxPolls = 18,
    [switch]$SkipSmoke,
    [string]$ExpectedMuxTokenIdVersion = '',
    [string]$ExpectedMuxTokenSecretVersion = '',
    [string]$ExpectedMuxSigningKeyIdVersion = '',
    [string]$ExpectedMuxSigningPrivateKeyVersion = '',
    [string]$ExpectedMuxWebhookSecretVersion = ''
)

$ErrorActionPreference = 'Stop'

$FunctionSecretMap = @{
    testMuxAuth = @('MUX_TOKEN_ID', 'MUX_TOKEN_SECRET')
    createMuxLiveStream = @('MUX_TOKEN_ID', 'MUX_TOKEN_SECRET', 'MUX_SIGNING_KEY_ID', 'MUX_SIGNING_PRIVATE_KEY', 'MUX_WEBHOOK_SECRET')
    resendMuxCredentialPack = @('MUX_TOKEN_ID', 'MUX_TOKEN_SECRET', 'MUX_SIGNING_KEY_ID', 'MUX_SIGNING_PRIVATE_KEY', 'MUX_WEBHOOK_SECRET')
    getMuxPlaybackUrl = @('MUX_TOKEN_ID', 'MUX_TOKEN_SECRET', 'MUX_SIGNING_KEY_ID', 'MUX_SIGNING_PRIVATE_KEY', 'MUX_WEBHOOK_SECRET')
    disableMuxStream = @('MUX_TOKEN_ID', 'MUX_TOKEN_SECRET', 'MUX_SIGNING_KEY_ID', 'MUX_SIGNING_PRIVATE_KEY', 'MUX_WEBHOOK_SECRET')
    getMuxStreamStatus = @('MUX_TOKEN_ID', 'MUX_TOKEN_SECRET', 'MUX_SIGNING_KEY_ID', 'MUX_SIGNING_PRIVATE_KEY', 'MUX_WEBHOOK_SECRET')
    getMuxVodReplay = @('MUX_TOKEN_ID', 'MUX_TOKEN_SECRET', 'MUX_SIGNING_KEY_ID', 'MUX_SIGNING_PRIVATE_KEY', 'MUX_WEBHOOK_SECRET')
    muxWebhook = @('MUX_TOKEN_ID', 'MUX_TOKEN_SECRET', 'MUX_SIGNING_KEY_ID', 'MUX_SIGNING_PRIVATE_KEY', 'MUX_WEBHOOK_SECRET')
}

function Get-ExpectedSecretVersions {
    $versions = @{
        MUX_TOKEN_ID = $ExpectedMuxTokenIdVersion
        MUX_TOKEN_SECRET = $ExpectedMuxTokenSecretVersion
        MUX_SIGNING_KEY_ID = $ExpectedMuxSigningKeyIdVersion
        MUX_SIGNING_PRIVATE_KEY = $ExpectedMuxSigningPrivateKeyVersion
        MUX_WEBHOOK_SECRET = $ExpectedMuxWebhookSecretVersion
    }

    foreach ($secretName in @($versions.Keys)) {
        if (-not [string]::IsNullOrWhiteSpace($versions[$secretName])) {
            continue
        }

        $resolvedVersion = gcloud secrets versions list $secretName --project $ProjectId --limit=1 --sort-by=~createTime --format='value(name.basename())'
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($resolvedVersion)) {
            throw "Unable to resolve latest version for $secretName."
        }

        $versions[$secretName] = $resolvedVersion.Trim()
    }

    return $versions
}

function Get-FunctionDescription {
    param(
        [string]$FunctionName
    )

    $json = gcloud functions describe $FunctionName --gen2 --region $Region --project $ProjectId --format='json(name,state,updateTime,serviceConfig.secretEnvironmentVariables)'
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($json)) {
        throw "Unable to describe function $FunctionName."
    }

    return $json | ConvertFrom-Json
}

function Test-FunctionState {
    param(
        [string]$FunctionName,
        [hashtable]$ExpectedVersions,
        [pscustomobject]$Description
    )

    if ($Description.state -ne 'ACTIVE') {
        return $false
    }

    $requiredSecrets = $FunctionSecretMap[$FunctionName]
    $actualBindings = @{}
    foreach ($binding in @($Description.serviceConfig.secretEnvironmentVariables)) {
        $actualBindings[$binding.key] = [string]$binding.version
    }

    foreach ($secretName in $requiredSecrets) {
        if (-not $actualBindings.ContainsKey($secretName)) {
            return $false
        }

        if ([string]$actualBindings[$secretName] -ne [string]$ExpectedVersions[$secretName]) {
            return $false
        }
    }

    return $true
}

function Wait-ForFunctionsReady {
    param(
        [hashtable]$ExpectedVersions
    )

    $latestDescriptions = @{}

    for ($poll = 1; $poll -le $MaxPolls; $poll++) {
        $pendingFunctions = @()
        foreach ($functionName in $FunctionSecretMap.Keys) {
            $description = Get-FunctionDescription -FunctionName $functionName
            $latestDescriptions[$functionName] = $description

            if (-not (Test-FunctionState -FunctionName $functionName -ExpectedVersions $ExpectedVersions -Description $description)) {
                $pendingFunctions += $functionName
            }
        }

        if ($pendingFunctions.Count -eq 0) {
            return $latestDescriptions
        }

        if ($poll -lt $MaxPolls) {
            Write-Host ("Waiting for functions to become ACTIVE with expected secret bindings: {0}" -f ($pendingFunctions -join ', ')) -ForegroundColor Yellow
            Start-Sleep -Seconds $PollIntervalSeconds
        }
    }

    $details = foreach ($functionName in $FunctionSecretMap.Keys) {
        $description = $latestDescriptions[$functionName]
        $bindings = @($description.serviceConfig.secretEnvironmentVariables | ForEach-Object {
            "{0}=v{1}" -f $_.key, $_.version
        }) -join ', '
        "{0}: state={1}; bindings=[{2}]" -f $functionName, $description.state, $bindings
    }
    throw ("Function verification timed out.`n{0}" -f ($details -join [Environment]::NewLine))
}

$expectedVersions = Get-ExpectedSecretVersions
$descriptions = Wait-ForFunctionsReady -ExpectedVersions $expectedVersions

Write-Host 'Verified secret bindings:' -ForegroundColor Cyan
foreach ($secretName in $expectedVersions.Keys) {
    Write-Host ("  {0}=v{1}" -f $secretName, $expectedVersions[$secretName])
}

if (-not $SkipSmoke) {
    Write-Host 'Running Mux auth smoke...' -ForegroundColor Cyan
    node scripts/smoke_mux_auth.mjs --base-url $MuxBaseUrl
    if ($LASTEXITCODE -ne 0) {
        throw 'Mux auth smoke failed.'
    }
}

$summary = foreach ($functionName in $FunctionSecretMap.Keys) {
    $description = $descriptions[$functionName]
    [pscustomobject]@{
        function = $functionName
        state = $description.state
        updated = $description.updateTime
    }
}

$summary | Format-Table -AutoSize | Out-Host
Write-Host 'Mux streaming core verification completed.' -ForegroundColor Green