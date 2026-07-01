7--
mode: plan
description: Plan and prioritize the AI feature roadmap for DataFightCentral

---

# AI Feature Roadmap Planning

Review the current DFC codebase, services, and feature modules. Produce a prioritized AI feature roadmap considering:

1. **Current AI services** — Audit `lib/shared/services/` for existing AI/ML integrations (ESO Engine, Combat Intelligence, Samurai, etc.) and assess maturity.
2. **Feature gaps** — Compare implemented features in `lib/features/` against the platform vision in `docs/IMPLEMENTATION_SUMMARY.md` and `DFC_PLATFORM_OVERVIEW.md`.
3. **User value** — Rank features by fighter/fan/promoter impact: Shido AI coaching, fight prediction, smart matchmaking, real-time analytics, automated content curation.
4. **Technical readiness** — Flag features blocked by missing infrastructure (e.g., ML model hosting, real-time pipelines, wearable integrations).
5. **Output** — A phased roadmap (Phase 1: 0-30 days, Phase 2: 30-90 days, Phase 3: 90+ days) with dependencies and effort estimates.
