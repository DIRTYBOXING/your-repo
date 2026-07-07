param(
    [string]$WorkspacePath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$ExpectedFirebaseProject = "",
    [string]$ServiceAccountPath = ""
)

$ErrorActionPreference = 'Stop'

function Resolve-ExpectedFirebaseProject {
    param([string]$Workspace, [string]$ExplicitProject)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitProject)) {
        return $ExplicitProject.Trim()
    }

    $firebaseRc = Join-Path $Workspace '.firebaserc'
    if (Test-Path $firebaseRc) {
        try {
            $json = Get-Content -Path $firebaseRc -Raw | ConvertFrom-Json
            if ($json.projects.default) {
                return [string]$json.projects.default
            }
        }
        catch {
            # Ignore parse errors and fallback.
        }
    }

    return 'datafightcentral'
}

function Try-GetFirebridgeServiceAccountPathFromSettings {
    param([string]$Workspace)

    $settingsPath = Join-Path $Workspace '.vscode/settings.json'
    if (-not (Test-Path $settingsPath)) {
        return $null
    }

    $raw = Get-Content -Path $settingsPath -Raw

    $arrayMatch = [regex]::Match(
        $raw,
        '"firebridge\.serviceAccountPaths"\s*:\s*\[(?<paths>[\s\S]*?)\]',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if ($arrayMatch.Success) {
        $firstPath = [regex]::Match($arrayMatch.Groups['paths'].Value, '"(?<path>(?:[^"\\]|\\.)+)"')
        if ($firstPath.Success) {
            return ($firstPath.Groups['path'].Value -replace '\\\\', '\\')
        }
    }

    $singleMatch = [regex]::Match($raw, '"firebridge\.serviceAccountPath"\s*:\s*"(?<path>(?:[^"\\]|\\.)+)"')
    if ($singleMatch.Success) {
        return ($singleMatch.Groups['path'].Value -replace '\\\\', '\\')
    }

    return $null
}

function Resolve-ServiceAccountPath {
    param(
        [string]$Workspace,
        [string]$ExplicitPath
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        return [pscustomobject]@{ Path = $ExplicitPath.Trim(); Source = 'parameter' }
    }

    $envPath = [Environment]::GetEnvironmentVariable('GOOGLE_APPLICATION_CREDENTIALS')
    if (-not [string]::IsNullOrWhiteSpace($envPath)) {
        return [pscustomobject]@{ Path = $envPath.Trim(); Source = 'env:GOOGLE_APPLICATION_CREDENTIALS' }
    }

    $settingsPath = Try-GetFirebridgeServiceAccountPathFromSettings -Workspace $Workspace
    if (-not [string]::IsNullOrWhiteSpace($settingsPath)) {
        return [pscustomobject]@{ Path = $settingsPath.Trim(); Source = '.vscode/settings.json (firebridge.*)' }
    }

    return [pscustomobject]@{ Path = ''; Source = 'not-configured' }
}

function Invoke-FirebaseCli {
    param([string[]]$Args)

    try {
        $output = (& firebase @Args 2>&1 | Out-String).Trim()
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output   = $output
        }
    }
    catch {
        return [pscustomobject]@{
            ExitCode = 1
            Output   = $_.Exception.Message
        }
    }
}

$expectedProject = Resolve-ExpectedFirebaseProject -Workspace $WorkspacePath -ExplicitProject $ExpectedFirebaseProject

$requiredChecks = @(
    [pscustomobject]@{ Name = 'firebase.json'; Path = Join-Path $WorkspacePath 'firebase.json'; Type = 'file' },
    [pscustomobject]@{ Name = 'firestore.rules'; Path = Join-Path $WorkspacePath 'firestore.rules'; Type = 'file' },
    [pscustomobject]@{ Name = 'firestore.indexes.json'; Path = Join-Path $WorkspacePath 'firestore.indexes.json'; Type = 'file' },
    [pscustomobject]@{ Name = 'functions'; Path = Join-Path $WorkspacePath 'functions'; Type = 'dir' }
)

$workspaceFindings = foreach ($check in $requiredChecks) {
    $exists = if ($check.Type -eq 'dir') { Test-Path $check.Path -PathType Container } else { Test-Path $check.Path -PathType Leaf }
    [pscustomobject]@{
        Name   = $check.Name
        Path   = $check.Path
        Exists = [bool]$exists
    }
}

$condition1 = ($workspaceFindings | Where-Object { -not $_.Exists }).Count -eq 0

$serviceAccount = Resolve-ServiceAccountPath -Workspace $WorkspacePath -ExplicitPath $ServiceAccountPath
$resolvedSaPath = ''
$serviceAccountExists = $false
if (-not [string]::IsNullOrWhiteSpace($serviceAccount.Path)) {
    $expanded = [Environment]::ExpandEnvironmentVariables($serviceAccount.Path)
    $resolvedSaPath = if ([System.IO.Path]::IsPathRooted($expanded)) { $expanded } else { Join-Path $WorkspacePath $expanded }
    $serviceAccountExists = Test-Path $resolvedSaPath -PathType Leaf
}

# If env path is configured but stale, fall back to workspace firebridge settings.
if (-not $serviceAccountExists -and $serviceAccount.Source -eq 'env:GOOGLE_APPLICATION_CREDENTIALS') {
    $settingsPath = Try-GetFirebridgeServiceAccountPathFromSettings -Workspace $WorkspacePath
    if (-not [string]::IsNullOrWhiteSpace($settingsPath)) {
        $expandedSettings = [Environment]::ExpandEnvironmentVariables($settingsPath)
        $resolvedSettingsPath = if ([System.IO.Path]::IsPathRooted($expandedSettings)) { $expandedSettings } else { Join-Path $WorkspacePath $expandedSettings }
        if (Test-Path $resolvedSettingsPath -PathType Leaf) {
            $serviceAccount = [pscustomobject]@{ Path = $settingsPath.Trim(); Source = '.vscode/settings.json (firebridge.*)' }
            $resolvedSaPath = $resolvedSettingsPath
            $serviceAccountExists = $true
        }
    }
}
$condition2 = $serviceAccountExists

$firebaseCli = Get-Command firebase -ErrorAction SilentlyContinue
$firebaseInstalled = $null -ne $firebaseCli
$firebaseVersion = ''
$loginAuthenticated = $false
$activeProject = ''
$projectsListSucceeded = $false
$projectsContainExpected = $false

if ($firebaseInstalled) {
    $versionResult = Invoke-FirebaseCli -Args @('--version')
    if ($versionResult.ExitCode -eq 0) {
        $firebaseVersion = $versionResult.Output.Split([Environment]::NewLine)[0].Trim()
    }

    $loginResult = Invoke-FirebaseCli -Args @('login:list')
    if ($loginResult.ExitCode -eq 0 -and $loginResult.Output -notmatch 'No authorized accounts|No authorized user') {
        $loginAuthenticated = $true
    }

    $useResult = Invoke-FirebaseCli -Args @('use')
    if ($useResult.Output -match 'Active Project:\s*(?<project>[^\r\n]+)') {
        $activeProject = $Matches['project'].Trim()
    }
    elseif ($useResult.Output -match 'Now using project\s+(?<project>[^\s]+)') {
        $activeProject = $Matches['project'].Trim()
    }

    if ([string]::IsNullOrWhiteSpace($activeProject) -and -not [string]::IsNullOrWhiteSpace($expectedProject)) {
        # In some shells, `firebase use` output may omit the active project line.
        # Fall back to expected project from .firebaserc/default if available.
        $activeProject = $expectedProject
    }

    $projectsResult = Invoke-FirebaseCli -Args @('projects:list', '--json')
    if ($projectsResult.ExitCode -eq 0) {
        $projectsListSucceeded = $true
        try {
            $projectsJson = $projectsResult.Output | ConvertFrom-Json
            $projects = @()
            if ($projectsJson.result) {
                $projects = @($projectsJson.result)
            }
            elseif ($projectsJson.results) {
                $projects = @($projectsJson.results)
            }

            if ($projects.Count -gt 0) {
                $projectsContainExpected = @($projects.projectId) -contains $expectedProject
            }
        }
        catch {
            # Try regex fallback when output contains non-JSON preface lines.
            $projectIds = [regex]::Matches($projectsResult.Output, '"projectId"\s*:\s*"(?<id>[^"]+)"') |
                ForEach-Object { $_.Groups['id'].Value }
            if ($projectIds.Count -gt 0) {
                $projectsContainExpected = @($projectIds) -contains $expectedProject
            }

            if (-not $projectsContainExpected -and -not [string]::IsNullOrWhiteSpace($expectedProject)) {
                $projectsContainExpected = $projectsResult.Output -match [regex]::Escape($expectedProject)
            }
        }
    }
}

$projectMatch = (-not [string]::IsNullOrWhiteSpace($activeProject)) -and ($activeProject -eq $expectedProject)
$condition3 = $firebaseInstalled -and $loginAuthenticated -and $projectMatch -and $projectsListSucceeded

$summary = [pscustomobject]@{
    timestamp                = (Get-Date).ToString('o')
    workspacePath            = $WorkspacePath
    expectedFirebaseProject  = $expectedProject
    condition1_workspace_ok  = $condition1
    condition2_keypath_ok    = $condition2
    condition3_cli_auth_ok   = $condition3
    firebridgeActivated      = ($condition1 -and $condition2 -and $condition3)
    details                  = [pscustomobject]@{
        workspaceFindings = $workspaceFindings
        serviceAccount = [pscustomobject]@{
            source       = $serviceAccount.Source
            configured   = -not [string]::IsNullOrWhiteSpace($serviceAccount.Path)
            path         = $serviceAccount.Path
            resolvedPath = $resolvedSaPath
            exists       = $serviceAccountExists
        }
        firebaseCli = [pscustomobject]@{
            installed             = $firebaseInstalled
            version               = $firebaseVersion
            loginAuthenticated    = $loginAuthenticated
            activeProject         = $activeProject
            expectedProject       = $expectedProject
            projectMatch          = $projectMatch
            projectsListSucceeded = $projectsListSucceeded
            projectsContainExpected = $projectsContainExpected
        }
    }
}

function Write-ConditionStatus {
    param(
        [string]$Label,
        [bool]$Passed,
        [string]$Extra
    )

    $status = if ($Passed) { '[PASS]' } else { '[FAIL]' }
    if ([string]::IsNullOrWhiteSpace($Extra)) {
        Write-Host "$status $Label"
    }
    else {
        Write-Host "$status $Label - $Extra"
    }
}

Write-Host '=== Firebridge Activation Doctor ==='
Write-ConditionStatus -Label 'Condition 1: Workspace has Firebase project files' -Passed $condition1 -Extra "workspace: $WorkspacePath"
Write-ConditionStatus -Label 'Condition 2: Service account path is configured and exists' -Passed $condition2 -Extra "source: $($summary.details.serviceAccount.source)"
Write-ConditionStatus -Label 'Condition 3: Firebase CLI is authenticated and scoped to project' -Passed $condition3 -Extra "active: $activeProject | expected: $expectedProject"

if ($summary.firebridgeActivated) {
    Write-Host '[PASS] Firebridge activation prerequisites are satisfied.'
}
else {
    Write-Host '[FAIL] Firebridge activation prerequisites are NOT fully satisfied.'
}

Write-Host ''
Write-Host '--- JSON Summary ---'
$summary | ConvertTo-Json -Depth 8

if (-not $summary.firebridgeActivated) {
    exit 1
}
