Summary
Adds Python CLI tools to extract a 24-hour feed sample and compute KPI metrics:
freshness distribution, duplicate rate, trust mix, top sources, and stale items.
Outputs JSON and a small HTML snapshot for quick review.

Changes

- tools/extract_feed_sample.py
- tools/compute_feed_metrics.py
- docs/feed-kpi-runbook.md: how to run and interpret outputs
- .github/workflows/ci-feed-audit.yml (optional): nightly audit job stub

Why

- Provides repeatable audit tooling for feed health and baseline metrics
- Enables quick verification after changes to dedupe, freshness, or trust logic

Verification

- Scripts run locally and produce JSON + HTML
- Example output included in PR artifacts
- Optional nightly CI job runs on staging and uploads metrics as artifacts

Checklist

- [ ] Scripts added and documented
- [ ] Example output included in PR
- [ ] CI job added (optional)
