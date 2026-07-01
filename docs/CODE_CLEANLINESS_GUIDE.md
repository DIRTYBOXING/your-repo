# DFC Code Cleanliness Guide

> **Scope**: `lib/` (Flutter/Dart), `functions/` (Node.js), `scripts/`, `test/`
> **Enforced by**: `bash scripts/cleanup_scan.sh` and the `code-health` CI job.

---

## 1. File size limits

| Layer | Soft limit | Hard limit |
|---|---|---|
| UI screens (`lib/features/**/screens/`) | 300 lines | 400 lines |
| Services (`lib/shared/services/`) | 200 lines | 400 lines |
| Models (`lib/shared/models/`) | 150 lines | 250 lines |
| Cloud Functions (`functions/`) | 200 lines | 400 lines |
| Test files | no limit | 600 lines |

**Files approaching the soft limit** should add a header comment explaining why size is justified or what refactor is planned.

**Files exceeding the hard limit** must be split before the PR can merge.

---

## 2. Single-responsibility rule

Each file must do exactly one thing:

- One screen widget per file
- One model class per file
- One service (one Firebase collection or one external API) per file

If a file starts with `// TODO: split into ...` that split must be tracked in a GitHub issue and linked in the comment.

---

## 3. Naming conventions

| Artifact | Convention | Example |
|---|---|---|
| Dart files | `snake_case.dart` | `ppv_live_watch_screen.dart` |
| Dart classes | `PascalCase` | `PpvLiveWatchScreen` |
| Test files | `<source>_test.dart` | `ppv_live_watch_screen_test.dart` |
| Cloud Function files | `camelCase.ts` | `muxWebhook.ts` |
| Script files | `snake_case.sh` / `camelCase.ps1` | `cleanup_scan.sh` |

---

## 4. Every screen needs a test

Any new screen in `lib/features/**/screens/` must have a corresponding widget test or Playwright spec. Add:

```dart
// In lib/core/utils/web_route_test_hook_web.dart
// Call setWebRouteTestHook('<route-name>') inside initState
```

This enables the visual audit gate to verify the screen is mounted.

---

## 5. Header comment for large files

Files with more than 200 lines must include a top-of-file header block:

```dart
/// [FileName] — single-line summary of what this file does.
///
/// Domain: <Social | PPV | Maps | Auth | Shared>
/// Owner: @<github-handle>
/// Last refactor review: YYYY-MM-DD
/// Known tech-debt: <brief description or "none">
```

---

## 6. Marking deprecated code

When code is no longer the primary path but cannot be deleted immediately:

```dart
@Deprecated('Use NewWidget instead. Remove by YYYY-MM-DD. Issue: #NNN')
class OldWidget extends StatelessWidget { ... }
```

The removal date must be within 90 days. After the date the code must be deleted or the date must be updated with a linked issue explaining the delay.

---

## 7. Dead code policy

Code is considered dead if:

- No import / reference exists anywhere in the repo (`cleanup_scan.sh` section 8)
- It has not been touched in 2+ years (`cleanup_scan.sh` section 7)
- It is commented out with no explanatory note

Dead code must be removed or explicitly kept with a justified comment and a tracking issue.

---

## 8. TODOs and FIXMEs

Every `TODO` and `FIXME` must include a GitHub issue number:

```dart
// TODO(#123): refactor to use StreamBuilder
// FIXME(#456): handle edge case when list is empty
```

Bare `TODO:` or `FIXME:` without an issue number will be flagged by the cleanup scan.

---

## 9. Running the scan locally

```bash
# Quick local scan (bash / Git Bash / WSL)
bash scripts/cleanup_scan.sh

# Or via VS Code task:
# Ctrl+Shift+P → "Tasks: Run Task" → "DFC: Cleanup Scan"
```

Reports are written to `devops/reports/cleanup_scan.log`.

---

## 10. CI enforcement

The `code-health` workflow runs on every PR that touches `lib/**`. It will:

1. Run `flutter analyze` — **blocks merge on errors**
2. Run `bash scripts/cleanup_scan.sh --ci` — **blocks merge on analyze errors**
3. Upload the scan log as an artifact for review

Warnings (large files, stale files, TODO count) are visible in the log but do not block merge. They become blocking if the count regresses from the previous run (future ratchet — not yet implemented).

---

## 11. Deletion approval

Any PR that removes files must use the **Deletion Review** template:

```
.github/PULL_REQUEST_TEMPLATE/deletion_review.md
```

Select it when creating the PR via GitHub's template picker. Deletion PRs require at least one domain-owner approval before merge.

---

*Last updated: 2025-05-01*
