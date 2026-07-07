# DFC Spine — Platform Logic and Operator Playbook

## Status
The technical spine and deployment surface already exist. This document formalizes the product spine in founder and operator language so engineering, operations, and outreach teams can execute without ambiguity.

## 1. Platform spine overview

### Source intake -> Normalize -> Rank -> Publish

- Source intake collects event feeds, partner uploads, live media, and user submissions. Ingestion is owned by service-layer logic that validates provenance and enforces trust rules before anything reaches downstream systems.
- Normalize converts heterogeneous inputs into canonical domain objects such as events, fighters, bouts, media evidence, and tickets. Normalization enforces schemas, canonical IDs, and the minimum metadata required for ranking and publishing.
- Rank applies deterministic rules and ML-assisted signals to prioritize items for feeds, moderation, and operational queues. Ranking is a service concern; UI consumes ranked outputs.
- Publish surfaces ranked items to consumers across feeds, promoter dashboards, and event pages, and writes authoritative state to Firestore and storage for evidence and audit.

## 2. Operational responsibilities and boundaries

- Services own business logic. Ingestion, normalization, ranking, trust, and amplification live in backend services. Frontend renders and enforces UX constraints but does not implement core platform rules.
- Firestore is the source of truth for canonical objects.
- Redis is ephemeral runtime state for queues, locks, and short-lived coordination.
- Cloud Storage holds media and evidence assets.
- Secret Manager holds runtime secrets.
- Artifact Registry and Cloud Run host containerized services.
- GitHub Actions manages build, deploy, smoke, and promote.
- Every deploy must include smoke checks, logs, and a clear rollback path through revision promotion or rollback.

## 3. Domain flow table

| Flow                    | Owner                                            | Inputs                                                | Outputs                                                        | Requirements                                        |
| ----------------------- | ------------------------------------------------ | ----------------------------------------------------- | -------------------------------------------------------------- | --------------------------------------------------- |
| Event ingestion         | Ingestion service                                | Partner feeds, manual uploads, live stream metadata   | Canonical event object in Firestore, media pointers in Storage | Idempotency, provenance metadata, schema validation |
| Media evidence handling | Media service plus storage adapters              | Uploads, Mux callbacks, storage URIs                  | Evidence records, thumbnails, transcodes                       | Signed URLs, retention policy, access controls      |
| Ranking and moderation  | Ranking service with rule engine plus ML signals | Canonical objects, engagement, recency, trust signals | Ranked feed slices, moderation queues                          | Explainable rules, audit logs, feature flags        |
| Commerce and ticketing  | Commerce service with Stripe integration         | Purchase requests, promoter configs                   | Payment records, ticket issuance, receipts                     | PCI-safe patterns, idempotent payment flows         |

## 4. Nonfunctional constraints and operational rules

- Production-safe startup: services must skip optional warmups when config is absent, and missing optional routers must not crash startup.
- Secrets-first deploy: all runtime credentials must be stored in Secret Manager and mapped at deploy time.
- Immutable deploys and smoke gating: build, push, no-traffic deploy, smoke tests, then manual promote.
- Resource planning: keep a CPU baseline for initial inference and define a GPU path for production inference services with measurable latency and cost baselines.
- Data governance: no PII in public artifacts, and evidence retention plus access logs are required.

## 5. 12-week roadmap and immediate priorities

### 0 to 2 weeks
- Finish secrets-backed deploy coverage for all runtime secrets, including database, Redis, Stripe, and AI keys.
- Validate candidate revision smoke tests and add GitHub Environment approval for production promotion.

### 2 to 6 weeks
- Isolate the AI inference path for benchmarking, and create a CPU baseline plus GPU plan.
- Harden observability with uptime checks, error-rate alerts, and request-latency SLOs.

### 6 to 12 weeks
- Publish the open-source subset: CI/CD workflow, Dockerfile, deployment guide, and minimal demo.
- Apply to NVIDIA Inception and Google Cloud credit programs with the one-pager, architecture diagram, and benchmark plan.

## 6. Operator checklist

- Confirm all production secrets exist in Secret Manager.
- Confirm candidate revisions pass `/health` and `/api/v1/health`.
- Confirm rollback commands are documented and tested.
- Confirm observability coverage for crash loops, latency, and error rate.
- Confirm public artifacts exclude secrets, customer data, and private partner logic.
- Confirm outreach materials match the current deployed stack and roadmap.

## 7. Next actions

- Use this document as the canonical founder and operator reference for product and infrastructure decisions.
- Pair it with [docs/ARCHITECTURE_ONE_PAGER.md](c:/Data-Fight-Central-safe-bridge/docs/ARCHITECTURE_ONE_PAGER.md) for external applications.
- Pair it with [docs/FUNDING_CHECKLIST.md](c:/Data-Fight-Central-safe-bridge/docs/FUNDING_CHECKLIST.md) and [docs/CAMPAIGNS_PLAN.md](c:/Data-Fight-Central-safe-bridge/docs/CAMPAIGNS_PLAN.md) for outreach execution.
