# DFC Triage & Bulk Issue Assignment Manifest

This handbook provides standard issue structures and batch-generation CLI command templates to populate issue trackers (Gitea/GitHub) with owners and prioritization states for the top categorized problems during our hardening sprinters.

---

## 1. Bulk Issue Templates (Top 5 Categories)

Use these templates to quickly spawn issues using CLI automation tools:

### Category A: Build Blockers (Dart / Flutter Compilation Errors)
```markdown
Title: [BLOCKER] Resolve compiler warnings and import paths — backend/rights
Labels: blocker, dart, backend
Assignee: legal-tech
Priority: Blocker (SLA: 4 Hours)

Description:
- **Source**: dart/flutter compiler output
- **Problem**: Invalided relative imports and deprecated package:test dependencies prevent rights enforcement compilation in staging.
- **Affected File**: `backend/rights/middleware/region_block_middleware.dart`
- **Steps to reproduce**:
  1. git checkout hardening/release-2026-07-02
  2. flutter analyze backend/rights
- **Expected Action**: Clean compile with zero fatal warnings or missing URI paths.
```

### Category B: Payments & Webhook Idempotency Health (High Priority)
```markdown
Title: [HIGH] Validate verify-session single-transaction and constraints
Labels: high, payments, ledger
Assignee: payments-engineering
Priority: High (SLA: 24 Hours)

Description:
- **Source**: payments-ci testing suite
- **Problem**: Missing unique constraint warning on orders.checkout_session_id under extreme concurrency.
- **Affected File**: `backend/payments/verify_session.js`
- **Steps to reproduce**:
  1. Start backend server against local container DB
  2. Run concurrently: `node scripts/synthetic_checkout.js --count=5`
- **Expected Action**: Concurrent checkout session requests return idempotent response rather than duplicate state rows.
```

### Category C: Interactive UX & Design Tokens Compliancy (Medium Priority)
```markdown
Title: [MEDIUM] Access labels and accessible inputs – dfc_reality_portal
Labels: medium, ui, accessibility
Assignee: frontend-engineering
Priority: Medium (SLA: 72 Hours)

Description:
- **Source**: html5 accessible standards scanner
- **Problem**: Range sliders (Gross revenue, Exposure count) and card checkout text boxes lack correct aria-labels or matching control IDs.
- **Affected File**: `docs/pages/dfc_reality_portal.html`
- **Expected Action**: Add correct elements and verify with accessibility checkers.
```

### Category D: CI Environment contexts & secrets (Medium Priority)
```markdown
Title: [MEDIUM] Context errors on ci-cd secrets resolution
Labels: medium, devops, gitlab
Assignee: sre-team
Priority: Medium (SLA: 72 Hours)

Description:
- **Source**: GHA pipeline linting
- **Problem**: Unknown variable syntax referenced for token parameters inside deploy-gke hooks.
- **Affected File**: `.github/workflows/ci-cd.yml`
- **Expected Action**: Reference valid secrets configuration bindings.
```

---

## 2. CLI Batch Issue Ingest script (PowerShell & Bash)

SRE leads can execute these quick loops to populate issues programmatically in one click:

### PowerShell Automation script
Save this block as `scripts/create_triage_issues.ps1` to batch-inject of blockers in Gitea or GitHub:

```powershell
# scripts/create_triage_issues.ps1
$Issues = @(
    @{
        title = "[BLOCKER] Fix compiler imports in region_block_middleware.dart"
        body  = "Path: backend/rights/middleware/region_block_middleware.dart`nError: Target of URI doesn't exist: '../rights/enforcement_service.dart'."
        label = "blocker,dart,backend"
        owner = "legal-tech"
    },
    @{
        title = "[BLOCKER] Fix webhook_test compilation errors"
        body  = "Path: test/dart/webhook_test.dart`nError: Target of URI doesn't exist: 'package:test/test.dart'. Convert to package:flutter_test."
        label = "blocker,dart,test"
        owner = "legal-tech"
    },
    @{
        title = "[HIGH] Add accessible form labels to Reality Portal inputs"
        body  = "Path: docs/pages/dfc_reality_portal.html`nProblems: Missing form labels for input-exposure, input-gross, and credit card fields."
        label = "high,ui,accessibility"
        owner = "frontend-engineering"
    }
)

foreach ($Issue in $Issues) {
    Write-Host "Creating issue: $($Issue.title)"
    gh issue create --title $Issue.title --body $Issue.body --label $Issue.label --assignee $Issue.owner
}
```

### Bash Automation script
```bash
#!/usr/bin/env bash
# scripts/create_triage_issues.sh

declare -a issues=(
  "[BLOCKER] Fix compiler imports in region_block_middleware.dart|Path: backend/rights/middleware/region_block_middleware.dart|blocker,dart,backend|legal-tech"
  "[BLOCKER] Fix webhook_test compilation errors|Path: test/dart/webhook_test.dart|blocker,dart,test|legal-tech"
  "[HIGH] Add accessible form labels to Reality Portal inputs|Path: docs/pages/dfc_reality_portal.html|high,ui,accessibility|frontend-engineering"
)

for item in "${issues[@]}"; do
  IFS='|' read -r title body label owner <<< "$item"
  echo "Creating: $title"
  gh issue create --title "$title" --body "$body" --label "$label" --assignee "$owner"
done
```
