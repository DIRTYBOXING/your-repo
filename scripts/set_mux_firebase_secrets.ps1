param(
    [string]$ProjectId = 'datafightcentral',
    [string]$MuxTokenId = '',
    [string]$MuxTokenSecret = '',
    [string]$MuxSigningKeyId = '',
    [string]$MuxSigningPrivateKey = '',
    [string]$MuxWebhookSecret = '',
    [string]$PpvSmokeToken = '',
    [string]$EnvFilePath = '',
    [switch]$TokenPairOnly,
    [switch]$Interactive,
    [switch]$AllowPartialUpdate
)

$ErrorActionPreference = 'Stop'

function Assert-SecretValue {
    param(
        [string]$Name,
        [string]$Value,
        [switch]$Optional,
        [int]$MinimumLength = 1
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($Optional) {
            return
        }

        throw "$Name is required."
    }

    $trimmed = $Value.Trim()
    if ($trimmed.Length -lt $MinimumLength) {
        throw "$Name looks too short to be valid."
    }

    if ($trimmed -match '(?i)placeholder|changeme|example|your[_-]?|dummy|fake|sample') {
        throw "$Name still looks like a placeholder value."
    }
}

function Normalize-SigningPrivateKey {
    param(
        [string]$Value
    )

    $trimmed = $Value.Trim()
    if ($trimmed -match 'BEGIN (RSA )?PRIVATE KEY') {
        $normalizedPem = ($trimmed -replace "`r`n", "`n")
        return [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($normalizedPem))
    }

    return $trimmed
}

function Set-SecretValue {
    param(
        [string]$Name,
        [string]$Value
    )

    $tempFile = Join-Path $env:TEMP ("dfc-secret-{0}-{1}.txt" -f $Name.ToLowerInvariant(), [guid]::NewGuid().ToString('N'))
    try {
        [System.IO.File]::WriteAllText($tempFile, $Value)
        firebase functions:secrets:set $Name --project $ProjectId --data-file $tempFile --force | Out-Host
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
    }
}

function Set-SecretValueIfProvided {
    param(
        [string]$Name,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        Write-Host "Skipping $Name because no value was provided."
        return
    }

    Set-SecretValue -Name $Name -Value $Value
}

function Read-SecretInput {
    param(
        [string]$Prompt
    )

    $secureValue = Read-Host -Prompt $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureValue)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Get-EnvFileValues {
    param(
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return @{}
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Env file not found: $Path"
    }

    $result = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) {
            continue
        }

        $parts = $trimmed -split '=', 2
        if ($parts.Count -ne 2) {
            continue
        }

        $key = $parts[0].Trim()
        $value = $parts[1]
        if ($key) {
            $result[$key] = $value
        }
    }

    return $result
}

$envValues = Get-EnvFileValues -Path $EnvFilePath
if ([string]::IsNullOrWhiteSpace($MuxTokenId) -and $envValues.ContainsKey('MUX_TOKEN_ID')) {
    $MuxTokenId = $envValues['MUX_TOKEN_ID']
}
if ([string]::IsNullOrWhiteSpace($MuxTokenSecret) -and $envValues.ContainsKey('MUX_TOKEN_SECRET')) {
    $MuxTokenSecret = $envValues['MUX_TOKEN_SECRET']
}
if ([string]::IsNullOrWhiteSpace($MuxSigningKeyId) -and $envValues.ContainsKey('MUX_SIGNING_KEY_ID')) {
    $MuxSigningKeyId = $envValues['MUX_SIGNING_KEY_ID']
}
if ([string]::IsNullOrWhiteSpace($MuxSigningPrivateKey) -and $envValues.ContainsKey('MUX_SIGNING_PRIVATE_KEY')) {
    $MuxSigningPrivateKey = $envValues['MUX_SIGNING_PRIVATE_KEY']
}
if ([string]::IsNullOrWhiteSpace($MuxWebhookSecret) -and $envValues.ContainsKey('MUX_WEBHOOK_SECRET')) {
    $MuxWebhookSecret = $envValues['MUX_WEBHOOK_SECRET']
}
if ([string]::IsNullOrWhiteSpace($PpvSmokeToken) -and $envValues.ContainsKey('PPV_SMOKE_TOKEN')) {
    $PpvSmokeToken = $envValues['PPV_SMOKE_TOKEN']
}

if ($Interactive) {
    if ([string]::IsNullOrWhiteSpace($MuxTokenId)) {
        $MuxTokenId = Read-SecretInput -Prompt 'Enter MUX_TOKEN_ID'
    }

    if ([string]::IsNullOrWhiteSpace($MuxTokenSecret)) {
        $MuxTokenSecret = Read-SecretInput -Prompt 'Enter MUX_TOKEN_SECRET'
    }

    if (-not $TokenPairOnly) {
        if ([string]::IsNullOrWhiteSpace($MuxSigningKeyId)) {
            $MuxSigningKeyId = Read-SecretInput -Prompt 'Enter MUX_SIGNING_KEY_ID'
        }

        if ([string]::IsNullOrWhiteSpace($MuxSigningPrivateKey)) {
            $MuxSigningPrivateKey = Read-SecretInput -Prompt 'Enter MUX_SIGNING_PRIVATE_KEY'
        }
    }
}

$normalizedTokenId = $MuxTokenId.Trim()
$normalizedTokenSecret = $MuxTokenSecret.Trim()
$normalizedSigningKeyId = $MuxSigningKeyId.Trim()
$normalizedSigningPrivateKey = if ([string]::IsNullOrWhiteSpace($MuxSigningPrivateKey)) {
    ''
}
else {
    Normalize-SigningPrivateKey -Value $MuxSigningPrivateKey
}
$normalizedWebhookSecret = $MuxWebhookSecret.Trim()
$normalizedSmokeToken = $PpvSmokeToken.Trim()

if ($AllowPartialUpdate) {
    $providedSecrets = @()

    if (-not [string]::IsNullOrWhiteSpace($normalizedTokenId)) {
        Assert-SecretValue -Name 'MUX_TOKEN_ID' -Value $normalizedTokenId -MinimumLength 10
        $providedSecrets += 'MUX_TOKEN_ID'
    }

    if (-not [string]::IsNullOrWhiteSpace($normalizedTokenSecret)) {
        Assert-SecretValue -Name 'MUX_TOKEN_SECRET' -Value $normalizedTokenSecret -MinimumLength 20
        $providedSecrets += 'MUX_TOKEN_SECRET'
    }

    if (-not [string]::IsNullOrWhiteSpace($normalizedSigningKeyId)) {
        Assert-SecretValue -Name 'MUX_SIGNING_KEY_ID' -Value $normalizedSigningKeyId -MinimumLength 10
        $providedSecrets += 'MUX_SIGNING_KEY_ID'
    }

    if (-not [string]::IsNullOrWhiteSpace($normalizedSigningPrivateKey)) {
        Assert-SecretValue -Name 'MUX_SIGNING_PRIVATE_KEY' -Value $normalizedSigningPrivateKey -MinimumLength 100
        $providedSecrets += 'MUX_SIGNING_PRIVATE_KEY'
    }

    if (-not [string]::IsNullOrWhiteSpace($normalizedWebhookSecret)) {
        Assert-SecretValue -Name 'MUX_WEBHOOK_SECRET' -Value $normalizedWebhookSecret -MinimumLength 8
        $providedSecrets += 'MUX_WEBHOOK_SECRET'
    }

    if (-not [string]::IsNullOrWhiteSpace($normalizedSmokeToken)) {
        Assert-SecretValue -Name 'PPV_SMOKE_TOKEN' -Value $normalizedSmokeToken -MinimumLength 8
        $providedSecrets += 'PPV_SMOKE_TOKEN'
    }

    if ($providedSecrets.Count -eq 0) {
        throw 'No Mux or PPV secrets were provided to update.'
    }
}
else {
    Assert-SecretValue -Name 'MUX_TOKEN_ID' -Value $normalizedTokenId -MinimumLength 10
    Assert-SecretValue -Name 'MUX_TOKEN_SECRET' -Value $normalizedTokenSecret -MinimumLength 20
    if (-not $TokenPairOnly) {
        Assert-SecretValue -Name 'MUX_SIGNING_KEY_ID' -Value $normalizedSigningKeyId -MinimumLength 10
        Assert-SecretValue -Name 'MUX_SIGNING_PRIVATE_KEY' -Value $normalizedSigningPrivateKey -MinimumLength 100
    }
    Assert-SecretValue -Name 'MUX_WEBHOOK_SECRET' -Value $normalizedWebhookSecret -Optional -MinimumLength 8
    Assert-SecretValue -Name 'PPV_SMOKE_TOKEN' -Value $normalizedSmokeToken -Optional -MinimumLength 8
}

Write-Host ("Validated Mux inputs. tokenIdLength={0} tokenSecretLength={1} signingKeyIdLength={2} signingPrivateKeyLength={3} webhookSecretLength={4} tokenPairOnly={5} allowPartialUpdate={6}" -f $normalizedTokenId.Length, $normalizedTokenSecret.Length, $normalizedSigningKeyId.Length, $normalizedSigningPrivateKey.Length, $normalizedWebhookSecret.Length, $TokenPairOnly.IsPresent, $AllowPartialUpdate.IsPresent)

if ($AllowPartialUpdate) {
    Set-SecretValueIfProvided -Name 'MUX_TOKEN_ID' -Value $normalizedTokenId
    Set-SecretValueIfProvided -Name 'MUX_TOKEN_SECRET' -Value $normalizedTokenSecret
    Set-SecretValueIfProvided -Name 'MUX_SIGNING_KEY_ID' -Value $normalizedSigningKeyId
    Set-SecretValueIfProvided -Name 'MUX_SIGNING_PRIVATE_KEY' -Value $normalizedSigningPrivateKey
    Set-SecretValueIfProvided -Name 'MUX_WEBHOOK_SECRET' -Value $normalizedWebhookSecret
    Set-SecretValueIfProvided -Name 'PPV_SMOKE_TOKEN' -Value $normalizedSmokeToken
}
else {
    Set-SecretValue -Name 'MUX_TOKEN_ID' -Value $normalizedTokenId
    Set-SecretValue -Name 'MUX_TOKEN_SECRET' -Value $normalizedTokenSecret
    if ($TokenPairOnly) {
        Set-SecretValueIfProvided -Name 'MUX_WEBHOOK_SECRET' -Value $normalizedWebhookSecret
        Set-SecretValueIfProvided -Name 'PPV_SMOKE_TOKEN' -Value $normalizedSmokeToken
    }
    else {
        Set-SecretValue -Name 'MUX_SIGNING_KEY_ID' -Value $normalizedSigningKeyId
        Set-SecretValue -Name 'MUX_SIGNING_PRIVATE_KEY' -Value $normalizedSigningPrivateKey
        Set-SecretValue -Name 'MUX_WEBHOOK_SECRET' -Value $normalizedWebhookSecret
        Set-SecretValue -Name 'PPV_SMOKE_TOKEN' -Value $normalizedSmokeToken
    }
}

Write-Host 'Mux Firebase secrets updated.' -ForegroundColor Green