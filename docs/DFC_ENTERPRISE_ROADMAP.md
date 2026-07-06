# DFC Enterprise Roadmap (2026 → 2030)

Official multi-phase roadmap for scaling DFC into a global combat-sports operating system.

## Strategic pillars

- **Google**: Backend, cloud runtime, data and AI platform
- **GitHub**: Source of truth, CI/CD, governance, release control
- **NVIDIA**: Compute acceleration, simulation, advanced AI performance

## Phase 1 — Foundation (Now → 3 months)

### Goal
Stabilize and enforce the core architecture.

### Deliverables
- Multi-module Flutter architecture stabilized
- Routing spine enforcement active
- Firebase backend/security baseline hardened
- PPV entitlement flows stabilized
- Admin/Promoter/Creator module consistency improved
- Sonar + CI + rule pack checks active as merge gates
- MCP baseline configured for local productivity (non-runtime)
- Operator/resilience docs published

### Exit criteria
- Required checks are merge-blocking and consistently green for release PRs
- No new literal routes introduced
- Firebase security checks pass for all policy-sensitive changes

## Phase 2 — Cloud Expansion (3 → 9 months)

### Goal
Scale into full cloud-native operations on Google Cloud.

### Deliverables
- Cloud Run microservices for selected backend domains
- Cloud Build deployment automation improvements
- BigQuery analytics foundation
- Vertex AI pilot integrations for intelligence features
- Secret Manager and IAM hardening
- Multi-region readiness planning

### Exit criteria
- Core services have reproducible deployment pipelines
- Analytics dashboards powered by production-grade data flows

## Phase 3 — AI Intelligence Layer (9 → 18 months)

### Goal
Establish DFC intelligence products for fighters, promoters, and creators.

### Deliverables
- Fighter intelligence and matchup-assist capabilities
- SmartCoach evolution with stronger personalization
- Promoter/creator AI assist workflows (forecasting, packaging, optimization)
- Region/talent discovery models

### Exit criteria
- Model-backed features validated by measurable product outcomes
- Safety and review controls documented and enforced

## Phase 4 — NVIDIA Acceleration (18 → 30 months)

### Goal
Adopt high-performance acceleration and simulation capabilities.

### Deliverables
- Omniverse-aligned simulation pilots
- CUDA/TensorRT acceleration for heavy inference paths
- GPU-oriented training/inference workflow maturation
- Video and motion analytics experiments

### Exit criteria
- At least one production-adjacent accelerated pipeline with measurable latency/throughput gains

## Phase 5 — Global Ecosystem (30 → 48 months)

### Goal
Scale DFC’s platform footprint across regions and partner ecosystems.

### Deliverables
- Multi-country onboarding and operations model
- Multi-currency monetization and payout maturity
- Expanded creator/promoter/fighter network tooling
- Rights, inventory, and distribution governance refinement

### Exit criteria
- Regional launches supported by repeatable operational playbooks

## Phase 6 — Meta-Apex (48 → 60 months)

### Goal
Reach global operating-system status for combat sports technology.

### Deliverables
- Major-organization-grade integrations
- Advanced AI-assisted matchmaking and analytics operations
- Global partner and broadcast integration standards
- Mature ecosystem economics and governance

### Exit criteria
- DFC recognized as a unified operating layer across competitive, media, and commercial workflows

## Governance alignment

Roadmap execution is bounded by repository-native controls:
- CI, Sonar, routing spine, Firebase security, and rule-pack checks
- Branch protection requirements
- PR template and module sweep discipline

## Related docs

- `docs/DFC_PLATFORM_MASTER_MAP.md`
- `docs/DFC_PLATFORM_GOVERNANCE.md`
- `docs/DFC_MCP_ARCHITECTURE_MAP.md`
- `docs/DFC_MCP_SERVER_COMPARISON_TABLE.md`
- `docs/QUALITY_GATE_SETUP.md`
- `docs/DFC_OPERATOR_QUICK_CARD.md`
