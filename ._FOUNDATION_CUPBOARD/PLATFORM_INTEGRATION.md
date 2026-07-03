# Data-Fight-Central Full Platform Integration Guide

This document outlines complete integration with VSCode, GitHub, Firebase, Google Cloud, Mux, and Stripe.

## Quick Start

### 1. VSCode Dev Container

```bash
# Open in VSCode with dev container
code .
# Then press F1 → "Dev Containers: Reopen in Container"
```

The `.devcontainer/devcontainer.json` includes:
- **Docker**: Build and run containers from inside the container
- **Python 3.11**: For atlas_backend (FastAPI)
- **Dart & Flutter**: For mobile/web UI
- **Port forwarding**: All 14 services on localhost
- **Extensions**: ESLint, Prettier, Python, Docker, Google Cloud, Firebase, REST Client, GitLens, Copilot

### 2. Environment Setup

```bash
# Copy .env.example to .env
cp .env.example .env

# Fill in your credentials
vim .env
```

**Required credentials:**
- `STRIPE_SECRET` / `STRIPE_WEBHOOK_SECRET` — from Stripe Dashboard
- `JWT_PRIVATE_KEY` / `JWT_PUBLIC_KEY` — generate with openssl
- `MUX_TOKEN_ID` / `MUX_TOKEN_SECRET` — from Mux Dashboard
- `FIREBASE_API_KEY` / `FIREBASE_PROJECT_ID` — from Firebase Console
- `GOOGLE_APPLICATION_CREDENTIALS` — path to GCP service account JSON
- `OPENAI_API_KEY` — from OpenAI (if using GPT)
- `GOOGLE_MAPS_API_KEY` — from Google Cloud Console

### 3. Local Docker Compose (Minimal Stack)

```bash
# Start all services with health checks
docker compose -f docker-compose.minimal.yml up -d

# Check health of all services
docker compose -f docker-compose.minimal.yml ps

# View logs with filtering
docker compose -f docker-compose.minimal.yml logs -f ingest
```

**Local services:**
- **PostgreSQL (port 5432)**: `postgresql://dfc_admin:dfc-local-postgres-change-me@db:5432/dfc`
- **Redis (port 6379)**: `redis://redis:6379`
- **Ingest API (port 8000)**: http://localhost:8000
- **Predictor (port 8090)**: http://localhost:8090
- **Entitlements (port 4010)**: http://localhost:4010
- **Prometheus (port 9090)**: http://localhost:9090
- **Grafana (port 3001)**: http://localhost:3001 (admin/dfc-grafana-local)
- **Vault (port 8200)**: http://localhost:8200 (root token: root)

### 4. Firebase Integration

#### Setup

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Select project
firebase use datafightcentral

# Deploy Firestore rules and functions
firebase deploy --only firestore:rules
firebase deploy --only functions
```

#### In Code

```python
# atlas_backend/main.py uses Firebase for user profiles
import firebase_admin
from firebase_admin import credentials, firestore

# Auto-initialized if GOOGLE_APPLICATION_CREDENTIALS is set
# Or use Application Default Credentials on GCP
```

### 5. Google Cloud Integration

#### GCP Service Account

```bash
# Create service account in Google Cloud Console
# Download JSON key → save as dfc-sa.json

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/dfc-sa.json"

# Add to .env
GOOGLE_APPLICATION_CREDENTIALS=/path/to/dfc-sa.json
```

#### APIs to Enable

In Google Cloud Console, enable:
- **Cloud Firestore**
- **Cloud Functions**
- **Cloud Storage**
- **Maps API**
- **Vertex AI** (optional, for AI integrations)
- **Cloud Logging**

### 6. Stripe Integration

#### Test Mode Setup

```bash
# Get Stripe test keys from Dashboard → Developers → API Keys
STRIPE_SECRET=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...

# Create webhook endpoint in Stripe Dashboard
# URL: https://yourdomain.com/webhooks/stripe
# Events: payment_intent.succeeded, charge.refunded, etc.
STRIPE_WEBHOOK_SECRET=whsec_...
```

#### Webhook Testing Locally

```bash
# Using Stripe CLI
stripe listen --forward-to localhost:4010/webhooks/stripe
stripe trigger payment_intent.succeeded
```

### 7. Mux Integration (Video Streaming)

#### Setup

```bash
# Get credentials from Mux Dashboard → Access Tokens
MUX_TOKEN_ID=...
MUX_TOKEN_SECRET=...

# For signing URLs (thumbnail/player access)
MUX_SIGNING_KEY_ID=...
MUX_SIGNING_PRIVATE_KEY=...
```

#### Usage

```python
# Create live stream
mux.video.live_streams.create({
    "playback_policy": "public",
    "reconnect_window": 60
})

# Get playback URL
playback_url = stream.playback_url
```

### 8. GitHub Actions CI/CD

#### Key Workflows

**`.github/workflows/ci-docker-cloud.yml`** — Build & push to GitHub Container Registry (GHCR)

```yaml
# Automatically triggered on:
# - Push to main/develop
# - Pull requests
# Builds: entitlements, ingest, predictor
# Pushes to: ghcr.io/yourusername/dfc-*
```

**`.github/workflows/deploy.yml`** — Deploy to production

```bash
# Triggered by release tag (v1.0.0)
# 1. Build Docker images
# 2. Push to registry
# 3. Deploy to Cloud Run / GKE / App Engine
# 4. Run smoke tests
```

#### Deploy from Local

```bash
# Tag release
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions automatically deploys
# View progress in Actions tab
```

#### Secrets in GitHub

In repo → Settings → Secrets and variables → Actions, add:

```
DOCKER_REGISTRY_USERNAME
DOCKER_REGISTRY_PASSWORD
GCP_PROJECT_ID
GCP_SERVICE_ACCOUNT_KEY (JSON)
STRIPE_SECRET
MUX_TOKEN_ID
MUX_TOKEN_SECRET
FIREBASE_API_KEY
OPENAI_API_KEY
```

### 9. Docker Image Management

#### Build Locally

```bash
# Build all services
docker compose -f docker-compose.minimal.yml build

# Build specific service
docker compose -f docker-compose.minimal.yml build entitlements

# No-cache rebuild
docker compose -f docker-compose.minimal.yml build --no-cache ingest
```

#### Push to Registry

```bash
# Login to GitHub Container Registry
docker login ghcr.io -u USERNAME -p TOKEN

# Tag image
docker tag data-fight-central-entitlements:latest ghcr.io/USERNAME/dfc-entitlements:latest

# Push
docker push ghcr.io/USERNAME/dfc-entitlements:latest
```

#### Pull from Registry

```bash
# Update docker-compose to use registry image
# In production docker-compose.yml:
services:
  entitlements:
    image: ghcr.io/USERNAME/dfc-entitlements:latest
    pull_policy: always

# Pull and run
docker compose up -d
```

### 10. Database Migrations & Schema

#### Create Migration

```bash
# Using Alembic (atlas_backend)
docker compose -f docker-compose.minimal.yml exec ingest alembic revision --autogenerate -m "add_events_table"

# Run migrations
docker compose -f docker-compose.minimal.yml exec ingest alembic upgrade head
```

#### Backup Database

```bash
# Dump PostgreSQL
docker compose -f docker-compose.minimal.yml exec db pg_dump -U dfc_admin -d postgres > backup.sql

# Restore
docker compose -f docker-compose.minimal.yml exec -T db psql -U dfc_admin -d postgres < backup.sql
```

### 11. Monitoring & Logging

#### Prometheus

```bash
# Access at http://localhost:9090
# Query metrics:
# - http_requests_total
# - db_connection_pool_size
# - redis_commands_processed_total
```

#### Grafana

```bash
# Access at http://localhost:3001
# Default: admin / dfc-grafana-local
# Add Prometheus data source: http://prometheus:9090
# Import dashboards from Grafana community
```

#### Cloud Logging (GCP)

```bash
# View logs from containers running on GCP
gcloud logging read "resource.type=cloud_run_revision" --limit 50 --format json
```

### 12. Secrets Management

#### Local Development (Vault)

```bash
# Vault running at http://localhost:8200
# Root token: root (dev mode only)

# Write secret
curl -X POST http://localhost:8200/v1/secret/data/dfc/stripe \
  -H "X-Vault-Token: root" \
  -d '{"data": {"secret": "sk_test_..."}}'

# Read secret
curl http://localhost:8200/v1/secret/data/dfc/stripe \
  -H "X-Vault-Token: root"
```

#### Production (Google Secret Manager)

```bash
# Store in Google Secret Manager
gcloud secrets create dfc-stripe-secret --data-file=- <<< "sk_prod_..."

# Access from Cloud Run
gcloud run services update dfc-api \
  --update-env-vars STRIPE_SECRET=sm://dfc-stripe-secret
```

### 13. Testing

#### Run Smoke Tests

```bash
# Integration tests
docker compose -f docker-compose.minimal.yml exec ingest pytest tests/ -v

# REST API tests
curl http://localhost:8000/health
curl http://localhost:8090/health
curl http://localhost:4010/health
```

#### E2E Tests (Playwright)

```bash
# Run against local environment
npx playwright test --project=chromium
```

### 14. Deployment Checklist

Before pushing to production:

- [ ] All health checks passing (`docker compose ps`)
- [ ] Environment variables set in `.env`
- [ ] Database migrations applied (`alembic upgrade head`)
- [ ] Tests passing (GitHub Actions CI)
- [ ] Docker images built and pushed to registry
- [ ] Secrets stored in GitHub Actions / Google Secret Manager
- [ ] Fire base rules deployed
- [ ] Stripe webhooks configured for production keys
- [ ] Mux live streams tested
- [ ] SSL certificates in place (if needed)
- [ ] Monitoring/alerting configured

### 15. Troubleshooting

#### Service won't start

```bash
# Check logs
docker compose -f docker-compose.minimal.yml logs SERVICE_NAME

# Check health status
docker compose -f docker-compose.minimal.yml ps

# Inspect container
docker inspect data-fight-central-SERVICE-1
```

#### Database connection errors

```bash
# Verify database is running
docker compose -f docker-compose.minimal.yml exec db pg_isready

# Check DATABASE_URL in ingest container
docker compose -f docker-compose.minimal.yml exec ingest env | grep DATABASE
```

#### Stripe webhook not triggering

```bash
# Test with Stripe CLI
stripe trigger payment_intent.succeeded

# Check webhook endpoint is accessible
curl -X POST http://localhost:4010/webhooks/stripe \
  -H "Content-Type: application/json" \
  -d '{"type": "test"}'
```

---

**Need help?** Check the `.github/workflows` directory for example CI/CD pipelines and explore individual service READMEs.
