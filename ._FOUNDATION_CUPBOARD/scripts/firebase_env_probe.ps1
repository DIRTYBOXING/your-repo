$ErrorActionPreference = 'Stop'

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
    if ($value.Length -ge 2) {
        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
    }

    return $value
}

function Get-ConfiguredValue {
    param(
        [string[]]$Keys,
        [string]$DotEnvPath
    )

    foreach ($key in $Keys) {
        $envValue = [Environment]::GetEnvironmentVariable($key)
        if (-not [string]::IsNullOrWhiteSpace($envValue)) {
            return [pscustomobject]@{
                Key    = $key
                Value  = $envValue
                Source = 'shell'
            }
        }

        $dotEnvValue = Get-DotEnvValue -FilePath $DotEnvPath -Key $key
        if (-not [string]::IsNullOrWhiteSpace($dotEnvValue)) {
            return [pscustomobject]@{
                Key    = $key
                Value  = $dotEnvValue
                Source = '.env'
            }
        }
    }

    return $null
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$dotEnvPath = Join-Path $repoRoot '.env'

$credential = Get-ConfiguredValue -Keys @('GOOGLE_APPLICATION_CREDENTIALS') -DotEnvPath $dotEnvPath
$firebaseConfig = Get-ConfiguredValue -Keys @('FIREBASE_CONFIG') -DotEnvPath $dotEnvPath
$storageBucket = Get-ConfiguredValue -Keys @('EVIDENCE_BUCKET', 'FIREBASE_STORAGE_BUCKET') -DotEnvPath $dotEnvPath

$credentialState = if ($credential) {
    if (Test-Path $credential.Value) {
        'present:file-exists'
    }
    else {
        'present:file-missing'
    }
}
else {
    'absent'
}

$firebaseConfigState = if ($firebaseConfig) { 'present' } else { 'absent' }
$storageBucketState = if ($storageBucket) { 'present' } else { 'absent' }

$credentialValue = if ($credential) { $credential.Value } else { '' }
$storageBucketValue = if ($storageBucket) { $storageBucket.Value } else { '' }
$firebaseConfigSource = if ($firebaseConfig) { $firebaseConfig.Source } else { '' }
$credentialSource = if ($credential) { $credential.Source } else { '' }
$storageBucketSource = if ($storageBucket) { $storageBucket.Source } else { '' }

Write-Output @(
    ('GOOGLE_APPLICATION_CREDENTIALS={0}' -f $credentialState),
    ('GOOGLE_APPLICATION_CREDENTIALS_SOURCE={0}' -f $credentialSource),
    ('GOOGLE_APPLICATION_CREDENTIALS_VALUE={0}' -f $credentialValue),
    ('FIREBASE_CONFIG={0}' -f $firebaseConfigState),
    ('FIREBASE_CONFIG_SOURCE={0}' -f $firebaseConfigSource),
    ('STORAGE_BUCKET={0}' -f $storageBucketState),
    ('STORAGE_BUCKET_SOURCE={0}' -f $storageBucketSource),
    ('STORAGE_BUCKET_VALUE={0}' -f $storageBucketValue)
)
