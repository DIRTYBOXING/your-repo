param(
    [ValidateSet('quick-health', 'flutter-quality', 'integration-smoke', 'staging-deploy', 'full-orchestra')]
    [string]$Lane = 'quick-health',

    [bool]$StrictMode = $true,

    [string]$DeployProject = 'datafightcentral',

    [string]$Ref = '',

    [switch]$Watch
)

$ErrorActionPreference = 'Stop'

function Invoke-GhCommand {
    param([string[]]$Args)
    & gh @Args
    if ($LASTEXITCODE -ne 0) {
        throw "gh command failed: gh $($Args -join ' ')"
    }
}

Write-Host "Dispatching DFC Pipeline Control Center..." -ForegroundColor Cyan

$runArgs = @(
    'workflow', 'run', 'pipeline-control-center.yml',
    '-f', "lane=$Lane",
    '-f', "strict_mode=$($StrictMode.ToString().ToLowerInvariant())",
    '-f', "deploy_project=$DeployProject"
)

if (-not [string]::IsNullOrWhiteSpace($Ref)) {
    $runArgs += @('--ref', $Ref)
}

Invoke-GhCommand -Args $runArgs

Write-Host "Workflow dispatched successfully." -ForegroundColor Green

if ($Watch) {
    Write-Host "Resolving latest run id..." -ForegroundColor Cyan
    $runId = gh run list --workflow pipeline-control-center.yml --limit 1 --json databaseId --jq '.[0].databaseId'
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($runId)) {
        throw 'Unable to resolve latest control-center run id.'
    }

    Write-Host "Watching run $runId..." -ForegroundColor Cyan
    Invoke-GhCommand -Args @('run', 'watch', $runId)
}
else {
    Write-Host "Tip: add -Watch to stream live progress in terminal." -ForegroundColor Yellow
}
