# Docker Setup Guide

Complete Docker integration for DataFightCentral. This guide covers local development with all services running in containers.

## Prerequisites

- **Docker Desktop** (v29.4.0+) installed and running
- **Docker Compose** (v5.1.0+) included with Docker Desktop
- **GitHub Token** with `read:packages` scope (for pulling private images)
- **Local secrets file** (`.env`) for sensitive configuration

## Quick Start (3 Steps)

### 1. Create `.env` File

```bash
# Copy the example template
cp .env.example .env

# Edit .env and add your actual secrets:
# - STRIPE_SECRET (test or production key)
# - STRIPE_WEBHOOK_SECRET
# - JWT_PRIVATE_KEY and JWT_PUBLIC_KEY (PEM-encoded)
# - DRM_LICENSE_URL
```

**Never commit `.env` to git** — it's in `.gitignore`.

### 2. Start the Docker Stack

```bash
# Start all services (db, redis, ingest, predictor, entitlements, prometheus, grafana, vault)
docker compose -f docker-compose.minimal.yml up -d

# Verify all services are running
docker compose -f docker-compose.minimal.yml ps
```

### 3. Check Health Endpoints

```bash
# Ingest service (Python/FastAPI)
curl -sS http://localhost:8000/health

# Predictor service
curl -sS http://localhost:8090/health

# Entitlements service (Node.js)
curl -sS http://localhost:4010/health
```

All should return `{"status":"ok"}` (with additional fields).

---

## Service Details

| Service | Port | Language | Role |
|---------|------|----------|------|
| **db** | 5432 | PostgreSQL | Data persistence with PostGIS |
| **redis** | 6379 | Redis | Cache & session store |
| **ingest** | 8000 | Python/FastAPI | Event ingestion & feed processing |
| **predictor** | 8090 | Python/FastAPI | ML predictions & scoring |
| **entitlements** | 4010 | Node.js | PPV checkout & licensing |
| **prometheus** | 9090 | Prometheus | Metrics collection |
| **grafana** | 3001 | Grafana | Metrics dashboards |
| **secrets** | 8200 | Vault | Secrets management (dev-only) |

---

## Common Commands

### Start/Stop

```bash
# Start all services
docker compose -f docker-compose.minimal.yml up -d

# Stop all services (keeps data)
docker compose -f docker-compose.minimal.yml down

# Remove all services + volumes (destructive)
docker compose -f docker-compose.minimal.yml down -v

# Rebuild a single service
docker compose -f docker-compose.minimal.yml build --no-cache entitlements

# Restart a service with new environment variables
docker compose -f docker-compose.minimal.yml up -d --no-deps --force-recreate entitlements
```

### Logs & Debugging

```bash
# Tail logs for entitlements (last 300 lines)
docker compose -f docker-compose.minimal.yml logs --tail 300 -f entitlements

# Inspect container environment & mounts
docker inspect data-fight-central-entitlements-1

# Open shell inside running container
docker compose exec entitlements sh

# Copy file from container to host
docker cp data-fight-central-db-1:/tmp/backup.sql ./dfc_backup.sql
```

### Cleanup

```bash
# Remove stopped containers
docker compose -f docker-compose.minimal.yml down --remove-orphans

# Remove specific container (force)
docker rm -f data-fight-central-entitlements-1

# Prune all unused Docker resources
docker system prune -af
```

---

## Environment Variables

Required for `entitlements` service (Node.js):

| Variable | Source | Required | Example |
|----------|--------|----------|---------|
| `STRIPE_SECRET` | `.env` | Yes | `sk_test_xxx` |
| `STRIPE_WEBHOOK_SECRET` | `.env` | Yes | `whsec_xxx` |
| `JWT_PRIVATE_KEY` | `.env` | Yes | PEM-encoded private key |
| `JWT_PUBLIC_KEY` | `.env` | Yes | PEM-encoded public key |
| `DRM_LICENSE_URL` | `.env` | Yes | `https://license.example.com` |
| `TOKEN_TTL` | `.env` | No (default 3600) | `3600` (seconds) |

Load from `.env` automatically via `docker-compose`:

```yaml
environment:
  STRIPE_SECRET: ${STRIPE_SECRET:-}
  JWT_PRIVATE_KEY: ${JWT_PRIVATE_KEY:-}
  # ... etc
```

---

## GitHub Container Registry (GHCR) Integration

### Manual Trigger (Recommended for Dev)

Use the provided GitHub Actions workflow to build & push images:

1. Go to **Actions** → **GHCR Login & Build**
2. Click **Run workflow**
3. Enter image name (e.g., `entitlements:latest`)
4. Optionally check **Push image to GHCR**
5. Workflow authenticates with `${{ secrets.GHCR_TOKEN }}` and builds

### Local Build & Push

```bash
# Build locally
docker build -t ghcr.io/DIRTYBOXING/entitlements:latest ./entitlements-service

# Login to GHCR (uses your token)
echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Push
docker push ghcr.io/DIRTYBOXING/entitlements:latest
```

---

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker compose logs entitlements

# Inspect restart count & exit code
docker inspect --format '{{.Name}} Restarts={{.RestartCount}} ExitCode={{.State.ExitCode}}' \
  $(docker ps -aq --filter "name=entitlements")
```

### Health Check Failing

Entitlements checks for required secrets on startup:

```bash
curl -sS http://localhost:4010/health | jq '.missing'
# ["stripeSecret", "jwtPrivateKey", ...] means .env is missing values
```

**Fix:** Update `.env` with real values and restart:

```bash
docker compose -f docker-compose.minimal.yml up -d --force-recreate entitlements
```

### Database Connection Issues

```bash
# Test DB connectivity
docker compose exec ingest psql \
  -h db -U dfc_admin -d dfc -c "SELECT 1"

# Check DB logs
docker compose logs db
```

### Port Already in Use

```bash
# Find process using port 4010
lsof -i :4010  # macOS/Linux
netstat -ano | findstr :4010  # Windows

# Kill process or change port in docker-compose.minimal.yml
```

---

## Advanced: Docker Compose Overrides

Create `docker-compose.override.yml` to customize local dev without modifying the base file:

```yaml
# docker-compose.override.yml
version: '3.8'
services:
  ingest:
    # Use local source instead of rebuilding
    build:
      context: ./atlas_backend
      dockerfile: Dockerfile
      cache_from:
        - ingest:dev

  entitlements:
    # Increase Node heap size for heavy workloads
    environment:
      NODE_OPTIONS: --max-old-space-size=1024
```

---

## Next Steps

- [ ] Copy `.env.example` → `.env` and fill in secrets
- [ ] Run `docker compose -f docker-compose.minimal.yml up -d`
- [ ] Verify health endpoints respond
- [ ] Check Grafana dashboards at `http://localhost:3001`
- [ ] Review logs for any errors
- [ ] Commit `.env.example` (not `.env`)

---

## Resources

- [Docker Compose Docs](https://docs.docker.com/compose/)
- [GitHub GHCR Docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Local Development Setup Guide](docs/SETUP_GUIDE.md)

Notes
- Keep your token out of the repo. Use the `GHCR_TOKEN` Secret in GitHub Actions for CI.
- The repo already contains `.devcontainer/` — use `Dev Containers: Reopen in Container` in VS Code for a full dev environment.

Additional helpers and recipes

Build and push helpers

1. Build an image locally and tag it for GHCR
```bash
chmod +x scripts/build.sh
scripts/build.sh entitlements-service:latest
```

2. Push a built image to GHCR (script will prompt or use `GHCR_TOKEN`)
```bash
chmod +x scripts/push.sh
scripts/push.sh entitlements-service:latest
```

3. Cleanup docker resources
```bash
chmod +x scripts/cleanup-docker.sh
scripts/cleanup-docker.sh
```

Minimal compose (no `n8n`)
```bash
docker compose -f docker-compose.minimal.yml up -d
```

AI model compose (placeholders)
```bash
docker compose -f docker-compose.ai.yml up -d
```

NGINX proxy (requires certs in `docker/nginx/certs` or use only port 80)
```bash
docker compose -f docker-compose.proxy.yml up -d
```

Notes on TLS
- For local testing you can generate dev certs (mkcert) and place them in `docker/nginx/certs` as `fullchain.pem` and `privkey.pem` (or adapt the `nginx.conf`).
- For production use a proper certificate and update the nginx config accordingly.

If you want me to add more automation (CI builds, auto-tagging, or NGINX HTTPS automation), tell me which step to automate next.
