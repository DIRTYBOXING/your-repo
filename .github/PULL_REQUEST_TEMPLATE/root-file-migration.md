## Root File Migration PR

### Summary

- Migrates root-level Dart files into module-owned folders under `lib/`.
- Updates import paths and keeps file history using `git mv`.
- Quarantines non-code or stray files that do not belong to module structure.

### Why

- Remove architecture drift from repository root.
- Enforce feature boundaries and reduce build-time import breakage.
- Align codebase with DFC Combat OS module model.

### Scope

- [ ] Root-level Dart files moved into feature/domain/core folders.
- [ ] Import paths updated and analyzer-clean.
- [ ] Riverpod generation rerun if provider files moved.
- [ ] Stray files reviewed and quarantined.

### Validation Evidence

- [ ] `flutter pub get`
- [ ] `dart run build_runner build --delete-conflicting-outputs`
- [ ] `dart analyze`
- [ ] `flutter test`
- [ ] `./scripts/verify_dfc_architecture.ps1`

Paste command outputs or links here.

### Files Moved

List key moves here in `old -> new` format:

-
-
-

### Risk Review

- [ ] No route regressions in `lib/core/config/router_config.dart`
- [ ] No service path regressions in existing imports
- [ ] Generated `.g.dart` files tracked when required

### Rollback Plan

- Revert this PR commit range.
- Restore previous import graph and rerun codegen.
