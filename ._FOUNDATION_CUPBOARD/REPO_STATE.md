# Repo State

Last updated: 2026-04-12

## Current Status

Track 1 code-side stabilization is complete and pushed to `master`.

Latest milestone commit:

- `f4acc032` — `fix: unify ppv access contracts across app and pipeline`

## Verified In Repo

- PPV access contract alignment across app and pipeline.
- Canonical purchase records now support `ppvId` across access checks.
- Top-level `ppv_access` is now used consistently in the touched runtime paths.
- Mux playback and replay checks now reject expired access.
- Subscription screen header normalized to the shared intro-header pattern.
- Pre-commit hooks passed on the final milestone commit.
- `dart format` passed on commit.
- `flutter analyze` passed in pre-commit on the committed milestone.
- Targeted editor diagnostics showed no blocking errors in the touched PPV and Mux files.
- Windows-friendly staging smoke helper added alongside the bash version.

## Files Stabilized In The Milestone

- `dfc-content-pipeline/live-publisher/src/index.js`
- `functions/streaming/mux.js`
- `lib/features/ppv/services/ppv_access_service.dart`
- `lib/shared/services/ppv_service.dart`
- `lib/shared/models/ppv_model.dart`
- `lib/features/subscription/screens/subscription_screen.dart`
- `docs/PPV_UNIFICATION_AUDIT.md`

## Canonical Direction

- Checkout and purchase source of truth: `functions/stripe/ppv.js`
- Playback and replay source of truth: `functions/streaming/mux.js`
- Transitional compatibility retained for legacy subcollection access writes and reads where necessary.

## Remaining Manual Or Upstream Work

See `TODO_OUT_OF_SCOPE.md`.

## Release Readiness Summary

The repository is in a safer and more coherent state than before the Track 1 finish sweep, but it is not yet fully production-certified until upstream credential rotation and real staging verification are complete.
