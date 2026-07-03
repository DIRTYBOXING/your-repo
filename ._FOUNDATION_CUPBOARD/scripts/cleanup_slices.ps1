param(
  [switch]$NoFetch,
  [switch]$NoStash,
  [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'

function Run-Command {
  param([string]$Command)
  Write-Host "> $Command" -ForegroundColor Cyan
  Invoke-Expression $Command
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed: $Command"
  }
}

function Confirm-Step {
  param([string]$Prompt)
  $answer = Read-Host "$Prompt [y/N]"
  if ($answer -notin @('y', 'Y')) {
    throw "Aborted by user at step: $Prompt"
  }
}

function Add-ExistingPaths {
  param([string[]]$Paths)
  foreach ($path in $Paths) {
    if (Test-Path $path) {
      & git add -- $path
      if ($LASTEXITCODE -ne 0) {
        throw "Failed to stage: $path"
      }
    } else {
      Write-Host "- skip missing: $path" -ForegroundColor DarkYellow
    }
  }
}

function Commit-Slice {
  param(
    [string]$Name,
    [string[]]$Paths,
    [string]$Message,
    [string[]]$ValidationCommands
  )

  Write-Host "`n=== $Name ===" -ForegroundColor Green
  Add-ExistingPaths -Paths $Paths

  $staged = git diff --cached --name-only
  if ([string]::IsNullOrWhiteSpace($staged)) {
    Write-Host "No staged files for $Name. Skipping." -ForegroundColor DarkYellow
    return
  }

  Write-Host "Staged files:" -ForegroundColor Yellow
  Write-Host $staged

  Confirm-Step "Commit this slice"
  Run-Command "git commit -m \"$Message\""

  if (-not $SkipTests -and $ValidationCommands.Count -gt 0) {
    Confirm-Step "Run validation commands for this slice"
    foreach ($cmd in $ValidationCommands) {
      Run-Command $cmd
    }
  }
}

$repoRoot = git rev-parse --show-toplevel
Set-Location $repoRoot
Write-Host "Repo root: $repoRoot" -ForegroundColor Green

$currentBranch = git branch --show-current
if ($currentBranch -ne 'feat/module-18-experiments') {
  throw "Current branch is '$currentBranch'. Switch to 'feat/module-18-experiments' first."
}

if (-not $NoFetch) {
  Run-Command 'git fetch origin'
  Run-Command 'git pull origin feat/module-18-experiments'
}

$timestamp = Get-Date -Format 'yyyyMMddHHmm'
Run-Command "git branch backup/cleanup-pre-slice-$timestamp"

if (-not $NoStash) {
  Run-Command "git stash push -u -m \"cleanup snapshot $timestamp\""
  Confirm-Step 'Apply stash now to start slicing'
  Run-Command 'git stash pop'
}

Commit-Slice -Name 'Slice 1: Experiments core and tests' `
  -Paths @(
    'backend/experiments/assignment_service.dart',
    'backend/experiments/experiment_service.dart',
    'backend/experiments/exposure_logger.dart',
    'infra/experiments/assignment_worker.sh',
    'tests/experiments/assignment_test.dart',
    'test/experiments',
    'docs/experiments/README.md'
  ) `
  -Message 'feat(experiments): finalize deterministic assignment and test migration' `
  -ValidationCommands @(
    'flutter test test/experiments/assignment_test.dart'
  )

Commit-Slice -Name 'Slice 2: Analytics and reconciliation' `
  -Paths @(
    'functions/ads/meta_forward.js',
    'server/api/analytics_emit.js',
    'server/apiStubs.js',
    'server/jobs/reconciliation.js',
    'scripts/replay_webhooks.js',
    'scripts/synthetic_checkout.js',
    'scripts/verify_reconciliation_flow.js',
    'test/node',
    'test/payments.test.js',
    'package-lock.json'
  ) `
  -Message 'feat(analytics): finalize capi forwarding, replay, and reconciliation flow' `
  -ValidationCommands @(
    'npm test --silent'
  )

Commit-Slice -Name 'Slice 3: Flutter app and feature modules' `
  -Paths @(
    'dfc_frontend/dfc_app/pubspec.yaml',
    'dfc_frontend/dfc_app/pubspec.lock',
    'dfc_frontend/dfc_app/test/widget_test.dart',
    'pubspec.yaml',
    'pubspec.lock',
    'analysis_options.yaml',
    'lib/main.dart',
    'lib/shared/widgets/dfc_nav_drawer.dart',
    'lib/gym_profile_screen.dart',
    'lib/features/fempower/screens/faces_of_women_fighters.dart',
    'lib/features/fempower/services/only_fit_service.dart',
    'lib/features/genie/genie_api_service.dart',
    'lib/features/legacy_root/ppv_operator_dashboard_screen.dart',
    'lib/features/promoter/screens/promoter_dashboard_screen.dart',
    'lib/app_shell',
    'lib/core/config',
    'lib/domain',
    'lib/features/ai',
    'lib/features/devices',
    'lib/features/economy',
    'lib/features/gyms',
    'lib/features/health',
    'lib/features/maps',
    'lib/features/prediction',
    'lib/features/rankings',
    'lib/features/ppv/screens/ppv_event_list_screen.dart',
    'lib/features/legacy_root/README.md',
    'lib/features/fempower/services/only_fit_service.g.dart'
  ) `
  -Message 'feat(app): integrate modular feature surfaces and app shell wiring' `
  -ValidationCommands @(
    'flutter test test/experiments/assignment_test.dart',
    'flutter test dfc_frontend/dfc_app/test/widget_test.dart'
  )

Commit-Slice -Name 'Slice 4: Infra and monitoring' `
  -Paths @(
    'k8s/dfc-deployment.yaml',
    'k8s/health-monitor-rbac.yaml',
    'monitoring/health-monitor.py',
    'monitoring/prometheus.yml',
    'monitoring/alerts',
    'scripts/test'
  ) `
  -Message 'ops(monitoring): add deployment and alerting hardening updates' `
  -ValidationCommands @()

Commit-Slice -Name 'Slice 5: Docs and migration tooling' `
  -Paths @(
    'docs',
    'GLOBAL_COMBAT_OS_MASTER_CHECKLIST.md',
    'PRODUCTION_PROMOTION_ROADMAP.md',
    '0008_patch_C_ci_harness_migrations.patch',
    'scripts/list_root_dart_files.ps1',
    'scripts/migrate_root_files_to_modules.ps1',
    'scripts/scaffold_dfc_combat_os.ps1',
    'scripts/verify_dfc_architecture.ps1',
    '.github/PULL_REQUEST_TEMPLATE/root-file-migration.md',
    'docs/runbooks/DFC_RING0_TO_RING1_CANARY_RUNBOOK.md'
  ) `
  -Message 'docs(chore): add rollout runbooks, architecture notes, and migration utilities' `
  -ValidationCommands @()

Write-Host "`nAll slices processed. Review status before pushing:" -ForegroundColor Green
Run-Command 'git status --short'

Confirm-Step 'Push feat/module-18-experiments now'
Run-Command 'git push --set-upstream origin feat/module-18-experiments'

Write-Host "Cleanup slicing run complete." -ForegroundColor Green
