# Feed Sprint Day-0 Audit

Date: 2026-04-19
Scope: Auto feed pipeline hardening and ranking readiness

## Snapshot

- Primary feed orchestration runs through `lib/shared/services/auto_feed_orchestrator_service.dart`.
- Feed UI reads Firestore cache from `precomputed_feed/global` via `lib/features/feed/screens/feed_screen.dart`.
- Existing pipeline already has source intake, normalization, trust/safety classification, ranking, and publish stages.

## Key findings

1. Pre-rank hardening was missing before this sprint step.

- No consistent freshness TTL gate.
- No normalization-level schema guard for malformed items.
- No deterministic dedupe fingerprinting before trust/rank stages.

2. Ranking logic is rich but heavily keyword-lift based.

- Trust and strategic scoring are in place.
- No explicit recency decay function beyond final tie-break sort by `publishedAt`.

3. Audit tooling gap.

- Planned scripts were not present:
  - `tools/extract_feed_sample.py`
  - `tools/compute_feed_metrics.py`
  - `ci/run_feed_smoke.sh`
- Existing audit stream/persistence exists in `FeedPipelineAuditService`, so we can ship metrics extraction against Firestore audit + precomputed feed docs.

## Implemented in this sprint step

File changed:

- `lib/shared/services/auto_feed_orchestrator_service.dart`

Hardening added before trust/rank:

- Freshness TTL filtering (`72h`) on normalized items.
- Schema validation for required fields (`id`, `title`, `source`, sensible `publishedAt`).
- URL canonicalization:
  - lowercased host/scheme
  - stripped marketing trackers (`utm_*`, `fbclid`, `gclid`)
  - removed trailing slash path noise
- Deterministic dedupe fingerprinting:
  - canonical URL fingerprint when available
  - fallback fingerprint from source + normalized title/body
- Normalize-stage audit log summary of kept/stale/duplicate/malformed counts.

## Top 3 next fixes (priority)

1. Ranking recency tuning (next)

- Add explicit time-decay score contribution so high-trust stale content does not dominate too long.
- Introduce configurable weights for `trust`, `strategic`, and `recency` instead of hard-coded ordering.

2. Trust and quality filters

- Add soft-spam heuristic at normalize/trust boundary (keyword and link density checks, source repetition burst checks).
- Route borderline items into an audit queue instead of outright dropping only by trust threshold.

3. Audit and smoke tooling

- Add `tools/feed/extract_feed_sample.dart` (or Python equivalent) that reads `precomputed_feed/global` and audit collection.
- Add `tools/feed/compute_feed_metrics.dart` to produce freshness and duplicate KPIs.
- Add CI smoke command for feed pipeline health + cache persistence contract.

## Verification performed

- Static compile check on the changed orchestrator file passed (`No errors found` from IDE diagnostics).

## Risks

- TTL at 72h may be too strict for low-volume regions and too lenient for high-volume channels; should be environment-configurable.
- URL-only dedupe can merge distinct updates on same article URL; consider content version keys where available.

## Recommended immediate next task

Implement ranking recency decay with controlled weights and add unit tests for:

- canonicalization behavior
- dedupe replacement semantics (newer duplicate wins)
- TTL filtering boundaries
