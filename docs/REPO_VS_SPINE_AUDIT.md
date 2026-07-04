# Repo vs Spine Audit — Data Fight Central

## Purpose
This audit compares the declared DFC spine in [docs/DFC_SPINE.md](c:/Data-Fight-Central-safe-bridge/docs/DFC_SPINE.md) against the current repository and deployment state. It is intended to turn product doctrine into concrete engineering and operations tasks.

## Summary
- The deploy spine exists and is materially functional: Cloud Run, Artifact Registry, Secret Manager mapping, smoke tests, and manual promotion are present in [.github/workflows/dfc-backend-deploy.yml](c:/Data-Fight-Central-safe-bridge/.github/workflows/dfc-backend-deploy.yml).
- The service layer owns core runtime behavior in [atlas_backend/main.py](c:/Data-Fight-Central-safe-bridge/atlas_backend/main.py), which aligns with the spine principle that business logic lives in services rather than the UI.
- The main gaps are incomplete router coverage, one confirmed Secret Manager mismatch, inconsistent secret handling patterns across workflows, and a Pydantic compatibility hotspot.

## P0 — Immediate mismatches

### 1. Missing Cloud secret for Redis
- Spine expectation: secrets-first deploy with all runtime credentials backed by Secret Manager.
- Evidence: [.github/workflows/dfc-backend-deploy.yml](c:/Data-Fight-Central-safe-bridge/.github/workflows/dfc-backend-deploy.yml) maps `REDIS_URL` from Secret Manager.
- Evidence: current `gcloud secrets list` output includes `DATABASE_URL`, `STRIPE_SECRET_KEY`, and `GOOGLE_GENAI_API_KEY`, but not `REDIS_URL`.
- Risk: candidate or future revisions can fail or degrade at runtime when Redis-backed paths are expected.
- One-line fix: create `REDIS_URL` in Secret Manager and validate it before the next deploy.
- Owner: Ops

### 2. Spine-declared service domains are referenced but not fully implemented as routers
- Spine expectation: event ingestion, commerce, and operational services should have concrete backend surfaces.
- Evidence: [atlas_backend/main.py](c:/Data-Fight-Central-safe-bridge/atlas_backend/main.py) declares router specs for `ticketing`, `seat_hold`, `affiliate`, `checkout`, `webhooks`, and `promoters`.
- Evidence: [atlas_backend/routers](c:/Data-Fight-Central-safe-bridge/atlas_backend/routers) does not currently contain `ticketing.py`, `seat_hold.py`, `affiliate.py`, `checkout.py`, `webhooks.py`, or `promoters.py`.
- Current behavior: startup degrades gracefully by skipping missing routers, which is production-safe but still leaves declared service surfaces absent.
- Risk: founder/operator documentation overstates delivered backend coverage; route expectations can diverge from actual runtime.
- One-line fix: either implement those routers or remove them from `ROUTER_SPECS` until they exist.
- Owner: Backend

## P1 — Important mismatches

### 3. Pydantic v2 compatibility hotspot
- Spine expectation: production-safe startup and predictable schema behavior.
- Evidence: [atlas_backend/routers/schemas.py](c:/Data-Fight-Central-safe-bridge/atlas_backend/routers/schemas.py) includes both `populate_by_name = True` and `allow_population_by_field_name = True`.
- Risk: mixed compatibility settings create noisy warnings and can hide real validation drift during upgrades.
- One-line fix: normalize schema config to the current Pydantic version used by the backend and remove deprecated compatibility flags.
- Owner: Backend

### 4. Secret handling is not yet consistent across workflows
- Spine expectation: runtime credentials should be injected from Secret Manager at deploy time.
- Evidence: [.github/workflows/dfc-backend-deploy.yml](c:/Data-Fight-Central-safe-bridge/.github/workflows/dfc-backend-deploy.yml) uses Secret Manager mappings.
- Evidence: [.github/workflows/platform-integration.yml](c:/Data-Fight-Central-safe-bridge/.github/workflows/platform-integration.yml) still injects `DATABASE_URL`, `OPENAI_API_KEY`, `STRIPE_SECRET`, and `REDIS_URL` directly from GitHub secrets via `--set-env-vars`.
- Risk: operational posture is inconsistent, secrets governance is fragmented, and runtime configuration differs by pipeline.
- One-line fix: standardize deployment workflows on Secret Manager-backed secret injection for production services.
- Owner: DevOps

### 5. Repo discoverability lagged the new spine and funding docs
- Spine expectation: operators and reviewers should be able to find canonical strategy and ops docs quickly.
- Evidence: top-level [README.md](c:/Data-Fight-Central-safe-bridge/README.md) did not link the new spine, funding, open-source, or audit docs before this patch.
- Impact: reviewers, sponsors, and partners can miss the canonical product and deployment framing.
- One-line fix: keep the top-level README wired to the canonical spine and outreach docs.
- Owner: Docs

## P2 — Follow-up mismatches

### 6. Router coverage and service naming are broader than current public architecture docs
- Evidence: [atlas_backend/routers](c:/Data-Fight-Central-safe-bridge/atlas_backend/routers) contains additional modules such as `stripe.py`, `tribe.py`, `blackbird.py`, and `chukya_sensor_fusion.py` that are not surfaced in the current spine or one-pager.
- Risk: internal runtime capabilities are harder to explain externally, and public docs under-describe the actual service surface.
- One-line fix: expand the architecture and domain-flow docs when these modules are considered canonical product surfaces.
- Owner: Docs and Backend

### 7. Observability policy is described more strongly than it is documented in one place
- Evidence: the spine requires alerts for error rate, latency, and crash loops, but there is not yet one canonical dashboard or alerting doc linked from the main README.
- Risk: operational intent is clear, but reviewer confidence depends on traceable alert definitions.
- One-line fix: add a concise observability runbook link beside the deploy workflow and spine docs.
- Owner: Ops

## Prioritized action list

### P0
1. Create `REDIS_URL` in Secret Manager.
2. Decide whether the missing routers are real near-term scope or should be removed from `ROUTER_SPECS`.

### P1
1. Clean up Pydantic config in [atlas_backend/routers/schemas.py](c:/Data-Fight-Central-safe-bridge/atlas_backend/routers/schemas.py).
2. Standardize production workflows on Secret Manager-backed injection.
3. Keep the README and canonical docs cross-linked.

### P2
1. Document additional backend domains if they are product-canonical.
2. Publish a short observability doc that names dashboards, alerts, and owners.

## Suggested owners
- Backend: router coverage and Pydantic cleanup
- DevOps: secrets standardization and workflow alignment
- Ops: Secret Manager inventory and runtime validation
- Docs and Outreach: README discoverability and external-facing architecture clarity
