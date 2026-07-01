param(
    [string]$MuxBaseUrl = 'https://australia-southeast1-datafightcentral.cloudfunctions.net',
    [string]$EntitlementsBaseUrl = '',
    [switch]$RunPlaywright,
    [string]$PlaywrightSpec = 'test/visual/player-poster.spec.ts'
)

$ErrorActionPreference = 'Stop'

Write-Host 'DFC PPV Production Gate: starting checks...' -ForegroundColor Cyan

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Action
    )

    Write-Host "[STEP] $Name" -ForegroundColor Yellow
    & $Action
    Write-Host "[PASS] $Name" -ForegroundColor Green
}

Invoke-Step -Name 'Runtime readiness check' -Action {
    if (-not [string]::IsNullOrWhiteSpace($EntitlementsBaseUrl)) {
        $output = node scripts/ppv_runtime_readiness_check.mjs --base $EntitlementsBaseUrl | Out-String
    }
    else {
        $output = node scripts/ppv_runtime_readiness_check.mjs | Out-String
    }
    Write-Host $output
    if ($output -notmatch '"ready"\s*:\s*true') {
        throw 'Runtime readiness check failed: ready=false.'
    }
}

Invoke-Step -Name 'Mux auth smoke' -Action {
    $output = node scripts/smoke_mux_auth.mjs --base-url $MuxBaseUrl | Out-String
    Write-Host $output
    if ($output -notmatch '"ok"\s*:\s*true') {
        throw 'Mux auth smoke failed: ok=false.'
    }
}

if ($RunPlaywright) {
    Invoke-Step -Name 'Playwright poster/player smoke' -Action {
        npm run test:visual -- $PlaywrightSpec
    }
}
else {
    Write-Host '[SKIP] Playwright smoke not requested. Use -RunPlaywright to enable.' -ForegroundColor DarkYellow
}

Write-Host 'DFC PPV Production Gate: all requested checks passed.' -ForegroundColor Green
