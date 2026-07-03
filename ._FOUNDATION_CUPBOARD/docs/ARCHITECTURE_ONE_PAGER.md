# Architecture — Data Fight Central

## Core components
- Frontend or event UI surface
- Backend: `atlas_backend` on Cloud Run with Python 3.11 and Uvicorn
- Data store: Firestore for event workflows and metadata
- Cache and ephemeral state: Redis
- Storage: Cloud Storage for media and evidence assets
- Container registry: Artifact Registry
- CI/CD: GitHub Actions using [.github/workflows/dfc-backend-deploy.yml](c:/Data-Fight-Central-safe-bridge/.github/workflows/dfc-backend-deploy.yml)
- Secrets: Secret Manager for `DATABASE_URL`, `REDIS_URL`, `STRIPE_SECRET_KEY`, and `GOOGLE_GENAI_API_KEY`
- Monitoring: Cloud Logging and Cloud Monitoring

## Deploy flow
1. GitHub Actions builds the backend image.
2. The workflow validates container startup.
3. The image is pushed to Artifact Registry.
4. Cloud Run receives either an initial deployment or a no-traffic candidate revision.
5. Health checks run against `/health` and `/api/v1/health`.
6. Approved revisions are promoted to production traffic.

## AI path
- Current baseline: CPU inference in Cloud Run.
- Near-term: benchmark dedicated inference paths for GPU-backed workloads.
- Goal: measure latency, throughput, and cost across moderation, ranking, and intelligence services.

## Current production-readiness notes
- Cloud Run backend is live.
- Secret Manager is already used for core production secrets.
- Deployment automation exists and supports staged promotion.
- Remaining ops gap: add `REDIS_URL` secret and finalize GitHub deployer credentials.
