# Legacy Root Migration Bucket

This folder temporarily contains Dart files migrated from repository root.

Purpose:
- Eliminate root-level code leakage.
- Preserve file history via git mv.
- Enable incremental migration into domain/feature-specific folders.

Next action:
- Move files from this bucket into screens, widgets, services, controllers, and models per feature.
