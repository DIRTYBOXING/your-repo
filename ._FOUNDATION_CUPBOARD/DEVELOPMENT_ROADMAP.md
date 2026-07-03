# Data-Fight-Central Development Roadmap (2026)

**Last Updated:** 2026-05-06  
**Project Status:** MVP → Production-Ready

---

## Executive Summary

Data-Fight-Central is evolving from a monolithic fight event platform into a scalable, AI-driven combat sports ecosystem. This roadmap outlines the autonomous, cloud-native architecture with self-healing services, intelligent predictions, and real-time monetization.

---

## Q2 2026: Foundation & Autonomy

### 1. Autonomous Health & Recovery ✅ IN PROGRESS

**Goal:** Zero manual intervention for service health management

- [x] Health monitoring service with TCP/HTTP checks
- [x] Docker Compose auto-restart policies (on-failure:5)
- [x] Prometheus + Grafana observability stack
- [x] Logging aggregation (JSON file driver, 50MB max)
- [ ] Kubernetes integration (auto-recovery, auto-scaling)
- [ ] Alert routing (Slack, PagerDuty, Sentry)
- [ ] Self-healing database (automatic failover)

**Deliverables:**
- `monitoring/health-monitor.py` — Autonomous health checker
- `docker-compose.minimal.yml` — Production-ready with health checks
- Auto-alert webhook integration

---

### 2. Database Schema & Migrations

**Goal:** Complete schema for events, users, fights, predictions

- [x] PostgreSQL with PostGIS (geolocation support)
- [x] events table (core domain)
- [ ] users table (authentication, profiles)
- [ ] fights table (fight details, participants)
- [ ] predictions table (AI predictor outputs)
- [ ] transactions table (Stripe, PPV billing)
- [ ] streams table (Mux video integrations)
- [ ] Auto-migration on container startup

**Deliverables:**
- Migration scripts (Alembic for atlas_backend)
- Database ER diagram
- Backup/restore procedures

---

### 3. API Contracts & Documentation

**Goal:** OpenAPI 3.0 spec for all services

- [ ] Ingest API (events, users, authentication)
- [ ] Predictor API (fight predictions, odds)
- [ ] Entitlements API (Stripe checkout, JWT tokens, DRM)
- [ ] Admin API (n8n automation control)
- [ ] Postman collection for testing

**Example Endpoints:**
```
POST /events — Create fight event
GET /events/{id}/predictions — Get AI predictions
POST /checkout/session — Stripe PPV checkout
POST /tokens/issue — Issue JWT entitlement token
```

---

### 4. CI/CD Enhancement

**Goal:** Automated testing, building, deploying

- [x] GitHub Actions platform integration workflow
- [ ] Automated security scanning (SAST/DAST)
- [ ] Performance benchmarking on PRs
- [ ] Automated canary deployments
- [ ] Blue-green deployments to Cloud Run
- [ ] Rollback triggers on health check failure

**Workflows:**
- `platform-integration.yml` — Build + test all services
- New: `security-scan.yml` — SAST/dependency checks
- New: `performance-bench.yml` — Load testing
- New: `canary-deploy.yml` — Staged rollout (5% → 25% → 100%)

---

### 5. Infrastructure as Code (IaC)

**Goal:** Reproducible, scalable cloud deployment

- [ ] Terraform for GCP resources
- [ ] Kubernetes manifests (GKE)
- [ ] Cloud Run configuration
- [ ] Network policies, firewalls, load balancers
- [ ] Database snapshots, backups

**Resources:**
```
- Cloud Run (ingest, predictor, entitlements)
- Cloud SQL (PostgreSQL managed)
- Cloud Storage (video uploads, clips)
- Firestore (real-time user data)
- Pub/Sub (event streaming)
- Cloud Scheduler (scheduled jobs)
```

---

## Q3 2026: AI & Intelligence

### 6. Enhanced Fight Predictions

**Goal:** Multi-model predictions with confidence scores

**Current:** Heuristic fallback (no ML models loaded)

**Target:**
- [ ] Load LightGBM models for: win probability, method, rounds, live scoring
- [ ] Confidence scoring (0-100%)
- [ ] Real-time model updates (retrain weekly)
- [ ] A/B testing framework (control vs. variant predictions)
- [ ] Prediction accuracy tracking (Calibration)

**Integration:**
```python
POST /predict
{
  "fighter_a": {"name": "Alex", "stats": {...}},
  "fighter_b": {"name": "Jordan", "stats": {...}}
}

Response:
{
  "winner": "Alex",
  "win_probability": 67.5,
  "method": "KO/TKO",
  "method_probability": 45.2,
  "rounds_to_finish": 2.3,
  "confidence": 78,
  "live_scoring": {...}
}
```

---

### 7. Live Scoring & Commentary

**Goal:** Real-time fight updates with AI commentary

- [ ] Live round scoring (judges, crowd, AI)
- [ ] Stat tracking (strikes, takedowns, submissions)
- [ ] Multi-model commentary generation (Claude, Gemini, GPT-4)
- [ ] Sentiment analysis (crowd engagement)
- [ ] Push notifications to mobile app

**Data Flow:**
```
1. Ingest API ← Live data from event
2. Predictor ← Processes round stats
3. AI Core (atlas_backend) ← Generates commentary
4. n8n ← Routes to social media
5. Mobile App ← Push notifications
```

---

### 8. Content Brain (AI Auto-Generation)

**Goal:** Automated clip generation, highlights, social posts

- [ ] Auto-clip detection (knockdowns, submissions, highlights)
- [ ] Mux API integration (create clips, thumbnails)
- [ ] Multi-platform poster generation (Instagram, TikTok, YouTube)
- [ ] SEO-optimized descriptions (Vertex AI)
- [ ] Auto-publishing to social (n8n workflows)

**Pipeline:**
```
Video Stream (Mux) → Object Detection (Vision AI)
  → Highlight Detection → Clip Generation
  → Poster Design (Gemini) → Social Publishing (n8n)
```

---

### 9. Personalized Recommendations

**Goal:** Tailored fight suggestions & betting odds

- [ ] User behavior tracking (views, bets, engagement)
- [ ] Collaborative filtering (user-user, item-item)
- [ ] Content-based filtering (fighter stats, style matchups)
- [ ] Real-time recommendation API
- [ ] A/B testing (control vs. ML-based rec)

---

## Q4 2026: Monetization & Scaling

### 10. Advanced PPV & Entitlements

**Goal:** Flexible, tiered pay-per-view model

**Current:** Basic Stripe checkout + DRM proxy

**Enhancements:**
- [ ] Subscription tiers (Basic, Premium, VIP)
- [ ] Bundle deals (5 fights, season pass)
- [ ] Regional pricing (USD, AUD, EUR, etc.)
- [ ] Promo codes & affiliate commissions
- [ ] JWT token expiry, revocation, device limits
- [ ] DRM license enforcement (watermarking)
- [ ] Revenue analytics dashboard

**Stripe Integration:**
```python
# Subscription management
POST /subscriptions
{
  "user_id": "...",
  "plan": "premium",
  "billing_cycle": "monthly"
}

# PPV events
POST /events/{id}/checkout
{
  "user_id": "...",
  "price_tier": "standard"
}
```

---

### 11. Real-Time Analytics Dashboard

**Goal:** Executive visibility into platform health & revenue

- [ ] Prometheus metrics exporting
- [ ] Grafana dashboards for:
  - User engagement (DAU, MAU, retention)
  - Revenue (PPV sales, subscriptions, affiliate)
  - Fight metrics (predictions accuracy, live scoring)
  - System health (latency, error rates, uptime)
  - CDN performance (Mux video delivery)
- [ ] BigQuery data warehouse for historical analysis
- [ ] Custom alerting (revenue drop, prediction drift)

---

### 12. Mobile App Integration

**Goal:** Seamless mobile experience (Flutter)

- [ ] OAuth integration (Firebase Auth)
- [ ] In-app PPV checkout (Stripe)
- [ ] Live fight notifications
- [ ] Push notifications (predictions, highlights)
- [ ] Video streaming integration (Mux player)
- [ ] Offline content sync

---

### 13. Third-Party Integrations

**Goal:** Expand ecosystem partnerships

- [ ] Betting exchange APIs (DraftKings, FanDuel)
- [ ] Sports data providers (ESPN, Sherdog)
- [ ] Video platforms (YouTube, TikTok auto-publish)
- [ ] Sponsorship management (logo overlays, product placement)
- [ ] Affiliate networks (commission tracking)

---

## 2027: Enterprise & Scale

### 14. Multi-Region Deployment

**Goal:** Global presence with CDN optimization

- [ ] US, EU, APAC regions
- [ ] Multi-region database replication (Cloud SQL)
- [ ] CDN with regional edge caching (Cloudflare/Cloud CDN)
- [ ] Latency-based routing
- [ ] Regional compliance (GDPR, CCPA)

---

### 15. Kubernetes & Advanced Orchestration

**Goal:** Auto-scaling, resilience, GitOps

- [ ] GKE cluster with node auto-scaling
- [ ] Pod Disruption Budgets (PDB) for high availability
- [ ] Service mesh (Istio) for traffic management
- [ ] ArgoCD for GitOps deployments
- [ ] Karpenter for cost optimization

---

### 16. Machine Learning Operations (MLOps)

**Goal:** Continuous model improvement

- [ ] Model versioning (MLflow, Weights & Biases)
- [ ] Automated retraining pipeline (weekly/monthly)
- [ ] A/B testing framework for model comparisons
- [ ] Feature store (Tecton) for consistent feature engineering
- [ ] Model monitoring (drift detection, performance tracking)
- [ ] Automated rollback on model degradation

---

### 17. Advanced Security

**Goal:** Zero-trust architecture, compliance

- [ ] OAuth 2.0 / OpenID Connect
- [ ] Role-based access control (RBAC)
- [ ] API key rotation
- [ ] Rate limiting & DDoS protection (Google Cloud Armor)
- [ ] Secrets rotation (Google Secret Manager)
- [ ] Audit logging (CloudTrail)
- [ ] SOC 2 Type II compliance
- [ ] Penetration testing (quarterly)

---

## Technology Stack (Current & Target)

| Layer | Current | Target |
|-------|---------|--------|
| **Frontend** | Flutter (mobile), React (web) | Next.js, Flutter Web |
| **Backend Services** | FastAPI, Node.js, Python | FastAPI, gRPC, Node.js |
| **Database** | PostgreSQL + PostGIS | Cloud SQL, Firestore, BigQuery |
| **Cache/Queue** | Redis | Redis, Pub/Sub |
| **AI/ML** | LLMs (OpenAI, Claude, Gemini) | Vertex AI, LLMs, Custom Models |
| **Video** | Mux | Mux + HLS/DASH streaming |
| **Payments** | Stripe | Stripe + Regional gateways |
| **Observability** | Prometheus, Grafana | Prometheus, GCP Cloud Monitoring |
| **Deployment** | Docker Compose, Cloud Run | Kubernetes (GKE), Terraform |
| **CI/CD** | GitHub Actions | GitHub Actions + ArgoCD |
| **Secrets** | Vault (dev), Google Secret Manager (prod) | Google Secret Manager |

---

## Key Metrics & KPIs

### Platform Health
- **Uptime:** 99.9% (target)
- **API Latency:** p95 < 500ms
- **Error Rate:** < 0.1%
- **Database replication lag:** < 100ms

### Business
- **DAU (Daily Active Users):** Goal 10K by Q4 2026
- **PPV Revenue:** Goal $50K/month by Q4 2026
- **Prediction Accuracy:** > 75% (win/loss)
- **Customer Retention:** > 70% MoM

### Development
- **Deployment Frequency:** Daily
- **Lead Time:** < 24 hours (commit → prod)
- **Change Failure Rate:** < 5%
- **MTTR (Mean Time to Recovery):** < 30 min

---

## Dependencies & Risks

### Critical Dependencies
- **Mux API** (video delivery) — SLA: 99.95%
- **Stripe API** (payments) — SLA: 99.9%
- **Google Cloud** (infrastructure) — SLA: 99.95%
- **Firebase** (auth) — SLA: 99.9%

### Risk Mitigations
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Video delivery outage | Critical | Fallback to HLS backup, multi-CDN |
| Payment processing down | Critical | Queue transactions, retry with exponential backoff |
| Database failure | Critical | Cross-region replication, point-in-time recovery |
| AI model degradation | High | A/B testing, fallback to heuristics, auto-rollback |
| DDoS attack | High | Cloud Armor, rate limiting, WAF |

---

## Success Criteria (End of 2026)

- [ ] Platform supports 10K+ concurrent users
- [ ] 99.9% uptime SLA met
- [ ] $50K+ monthly recurring revenue
- [ ] 75%+ prediction accuracy
- [ ] Zero-downtime deployments (blue-green)
- [ ] Global presence (3+ regions)
- [ ] SOC 2 Type II certified
- [ ] Mobile app with 100K+ downloads

---

## Next Immediate Actions (Next 30 Days)

1. **Week 1-2:** Deploy autonomous health monitor, configure alerts
2. **Week 2-3:** Complete database schema, run migrations
3. **Week 3-4:** Set up Kubernetes manifest, deploy to GKE
4. **Week 4:** Configure GitHub Actions secrets, enable auto-deployment

---

**Contact:** Engineering Lead | Last Sync: 2026-05-06

