<#
.SYNOPSIS
  DFC Bulk Staging/CI Blocker Issue Generator
.DESCRIPTION
  Automates the ingestion of the top verified linter, compile, and test blockers into Gitea/GitHub
  to clear the 1,822 diagnostic problems before production rollout.
#>

$ErrorActionPreference = 'Stop'

# Guard check: Ensure Github CLI is active and authenticated
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Warning "GitHub CLI 'gh' is not installed or available on PATH. Aborting execution."
  exit 1
}

$issues = @(
  @{
    title    = "[BLOCKER] Resolve compiler imports and package:test in region_block_middleware.dart"
    assignee = "legal-tech"
    labels   = "blocker,dart,backend"
    body     = @"
### Problem Description
Static analysis on staging throws compiler errors in regional blocking middleware.
- **Affected File**: `backend/rights/middleware/region_block_middleware.dart`
- **Error**: Target of URI doesn't exist: '../rights/enforcement_service.dart'.
- **Reproduction**: Run `flutter analyze backend/rights`
- **Remediation**: Correct absolute reference path imports and align linter exceptions.
"@
  },
  @{
    title    = "[BLOCKER] Fix test package compilation failures in webhook_test.dart"
    assignee = "legal-tech"
    labels   = "blocker,dart,test"
    body     = @"
### Problem Description
Compilation failure; imports non-existent package:test/test.dart.
- **Affected File**: `test/dart/webhook_test.dart`
- **Error**: Target of URI doesn't exist: 'package:test/test.dart'.
- **Reproduction**: Run `flutter test test/dart/webhook_test.dart`
- **Remediation**: Convert the script to use the core standard `package:flutter_test/flutter_test.dart` framework runner.
"@
  },
  @{
    title    = "[HIGH] Enhance verify_session payload schemas helper robustness"
    assignee = "payments-engineering"
    labels   = "high,payments,ledger"
    body     = @"
### Problem Description
Staging webhook processor logs deep structure nested payload parse errors on edge-cases completed sessions.
- **Affected File**: `backend/payments/verify_session.js`
- **Reproduction**: Send complex nested metadata payload to verify handler
- **Remediation**: Harden the nested object normaliser code to catch undefined deep properties safely in Node environment.
"@
  },
  @{
    title    = "[MEDIUM] Map inputs range slides with accessible ARIA labels in Reality Portal"
    assignee = "frontend-engineering"
    labels   = "medium,ui,accessibility"
    body     = @"
### Problem Description
Reality Portal input range controls (Gross revenue, Exposure count) and billing details boxes fail HTML accessibility criteria.
- **Affected File**: `docs/pages/dfc_reality_portal.html`
- **Reproduction**: Run axe-linter or basic html accessibility checks
- **Remediation**: Map unique descriptive aria-labels and coordinate exact element controls IDs.
"@
  }
)

Write-Host "DFC Staging Triage: Automating 4-Hour Blocker Issue Lifecycle Ingest..." -ForegroundColor Cyan

foreach ($issue in $issues) {
  Write-Host "Creating Issue: $($issue.title)" -ForegroundColor Yellow
  try {
    gh issue create --title $issue.title --body $issue.body --assignee $issue.assignee --label $issue.labels
    Write-Host "  -> Issue Created Successfully!" -ForegroundColor Green
  }
  catch {
    Write-Error "  -> Failed to register Issue: $_"
  }
}

Write-Host "Bulk Issue Generation Complete. Track status under GitHub Issues dashboard." -ForegroundColor Green
