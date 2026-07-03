param(
    [string]$Repo = 'DIRTYBOXING/Data-Fight-Central',

    [string]$EnvFile = (Join-Path (Join-Path $PSScriptRoot '..') '.env'),

    [string]$GoogleMapsApiKeyWebProd = '',

    [string]$GoogleMapsApiKeyWebDev = '',

    [string]$GoogleMapsApiKeyWeb = '',

    [switch]$SkipGitHubSecrets,

    [switch]$SkipLocalEnv
)

$ErrorActionPreference = 'Stop'

function Resolve-KeyValue {
    param(
        [string]$ParameterValue,
        [string]$EnvironmentVariableName
    )

    if (-not [string]::IsNullOrWhiteSpace($ParameterValue)) {
        return $ParameterValue.Trim()
    }

    $environmentValue = [Environment]::GetEnvironmentVariable($EnvironmentVariableName)
    if (-not [string]::IsNullOrWhiteSpace($environmentValue)) {
        return $environmentValue.Trim()
    }

    return ''
}

function Set-OrReplaceEnvLine {
    param(
        [string]$FilePath,
        [string]$Key,
        [string]$Value
    )

    $lines = if (Test-Path $FilePath) {
        [System.Collections.Generic.List[string]]::new()
        foreach ($line in [System.IO.File]::ReadAllLines($FilePath)) {
            $lines.Add($line)
        }
        $lines
    }
    else {
        [System.Collections.Generic.List[string]]::new()
    }

    $replacement = "$Key=$Value"
    $matchedIndex = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match "^$([Regex]::Escape($Key))=") {
            $matchedIndex = $index
            break
        }
    }

    if ($matchedIndex -ge 0) {
        $lines[$matchedIndex] = $replacement
    }
    else {
        $lines.Add($replacement)
    }

    [System.IO.File]::WriteAllLines($FilePath, $lines)
}

function Sync-GitHubSecret {
    param(
        [string]$SecretName,
        [string]$SecretValue
    )

    if ([string]::IsNullOrWhiteSpace($SecretValue)) {
        return
    }

    & gh secret set $SecretName -b $SecretValue --repo $Repo
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to set GitHub secret $SecretName for $Repo."
    }
}

$productionKey = Resolve-KeyValue -ParameterValue $GoogleMapsApiKeyWebProd -EnvironmentVariableName 'GOOGLE_MAPS_API_KEY_WEB_PROD'
$developmentKey = Resolve-KeyValue -ParameterValue $GoogleMapsApiKeyWebDev -EnvironmentVariableName 'GOOGLE_MAPS_API_KEY_WEB_DEV'
$fallbackKey = Resolve-KeyValue -ParameterValue $GoogleMapsApiKeyWeb -EnvironmentVariableName 'GOOGLE_MAPS_API_KEY_WEB'

if ([string]::IsNullOrWhiteSpace($productionKey) -and [string]::IsNullOrWhiteSpace($fallbackKey)) {
    throw 'Provide GOOGLE_MAPS_API_KEY_WEB_PROD or GOOGLE_MAPS_API_KEY_WEB via parameters or environment variables before syncing secrets.'
}

if (-not $SkipLocalEnv) {
    Set-OrReplaceEnvLine -FilePath $EnvFile -Key 'GOOGLE_MAPS_API_KEY_WEB_PROD' -Value $productionKey
    if (-not [string]::IsNullOrWhiteSpace($developmentKey)) {
        Set-OrReplaceEnvLine -FilePath $EnvFile -Key 'GOOGLE_MAPS_API_KEY_WEB_DEV' -Value $developmentKey
    }
    if (-not [string]::IsNullOrWhiteSpace($fallbackKey)) {
        Set-OrReplaceEnvLine -FilePath $EnvFile -Key 'GOOGLE_MAPS_API_KEY_WEB' -Value $fallbackKey
    }

    Write-Host "Updated local Maps web keys in $EnvFile" -ForegroundColor Green
}

if (-not $SkipGitHubSecrets) {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw 'GitHub CLI (gh) is required to sync repository secrets. Install gh or rerun with -SkipGitHubSecrets.'
    }

    & gh auth status | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'GitHub CLI is not authenticated. Run gh auth login before syncing repository secrets.'
    }

    Sync-GitHubSecret -SecretName 'GOOGLE_MAPS_API_KEY_WEB_PROD' -SecretValue $productionKey
    Sync-GitHubSecret -SecretName 'GOOGLE_MAPS_API_KEY_WEB_DEV' -SecretValue $developmentKey
    Sync-GitHubSecret -SecretName 'GOOGLE_MAPS_API_KEY_WEB' -SecretValue $fallbackKey

    Write-Host "Updated GitHub Actions secrets for $Repo" -ForegroundColor Green
}

Write-Host 'Next step: validate the replacement key in local and deployed web lanes, then revoke the previously exposed Google Maps key in Google Cloud.' -ForegroundColor Yellow
