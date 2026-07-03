param()

$ErrorActionPreference = 'Stop'

function Invoke-Step {
    param(
        [string]$Title,
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host "==> $Title" -ForegroundColor Cyan
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "$Title failed with exit code $LASTEXITCODE"
    }
}

function Remove-StaleFlutterTestArtifacts {
    param(
        [string]$RepoRoot
    )

    $stalePaths = @(
        (Join-Path $RepoRoot 'build\unit_test_assets\NativeAssetsManifest.json'),
        (Join-Path $RepoRoot 'build\unit_test_assets')
    )

    foreach ($stalePath in $stalePaths) {
        if (-not (Test-Path $stalePath)) {
            continue
        }

        Remove-Item -LiteralPath $stalePath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
Set-Location $repoRoot

Invoke-Step -Title 'Flutter analyze' -Action {
    flutter analyze
}

Invoke-Step -Title 'Targeted Flutter test' -Action {
    Remove-StaleFlutterTestArtifacts -RepoRoot $repoRoot
    flutter test test/fight_news_service_test.dart
}

Invoke-Step -Title 'Local callable smoke suite (Firebase JS SDK)' -Action {
    node scripts/callable_smoke.mjs
}

Invoke-Step -Title 'Emulator-backed demo web build' -Action {
    pwsh -ExecutionPolicy Bypass -File scripts/run_with_env.ps1 -Action build -Mode demo -UseEmulator
}

Write-Host ""
Write-Host 'Emulator verification lane passed.' -ForegroundColor Green
