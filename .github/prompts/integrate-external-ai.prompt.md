---
agent: agent
description: Evaluate and integrate an external AI technology into the DFC platform
---

# Integrate External AI Technology into DFC

When a new external AI model, framework, or research paper needs to be integrated into DataFightCentral, follow this workflow:

## 1. Research & Feasibility

- Identify the technology name, license, capabilities, and modalities (vision, audio, language, multimodal).
- Confirm the license is compatible with DFC (prefer Apache 2.0, MIT, or similar permissive).
- Check for existing overlap in `lib/shared/services/` — does DFC already have an equivalent?

## 2. Audit Current Infrastructure

- Read `lib/shared/services/samurai_swarm_coordinator.dart` to understand the boot phases and agent registry.
- Read `lib/shared/services/neural_mesh_engine.dart` for ML pipeline patterns (PSYCHE, SCALES, SHIELD, FUEL).
- Read `atlas_backend/main.py` for existing API endpoints and the multi-model router in `atlas_backend/ai_model_service.py`.
- Check `chuckya-radar/docker-compose.full.yml` if the integration requires a new containerized service.

## 3. Create the Service

- Create a new Dart service in `lib/shared/services/` following the `ChangeNotifier` singleton pattern.
- Include: data models (with Firestore serialization), initialization, local inference fallback, Atlas Backend integration.
- Bridge to existing ML pipelines (e.g., PSYCHE for neuro data, content ranking for feed).
- Add the export to `lib/shared/services/services.dart` barrel file.

## 4. Wire into DFC AI Pipeline

- Register the service in `samurai_swarm_coordinator.dart`:
  - Import + field + getter
  - Add boot phase (after existing phases)
  - Register as a `SwarmAgent` in `_registerAllAgents()`
- Add Atlas Backend endpoint(s) in `atlas_backend/main.py` (health check + inference).
- If the tech needs a Docker container, add it to `chuckya-radar/docker-compose.full.yml`.

## 5. Validate

- Run `get_errors` on the new service file to confirm zero compile errors.
- Verify `services.dart` barrel exports cleanly.
- Verify the swarm coordinator still boots all phases without error.

## Agent Guardrails

- Do NOT modify panel sizes, shared layout, router structure, or core widget architecture.
- Do NOT replace existing navigation patterns, IndexedStack tab wiring, or reusable shared widgets.
- Prefer service-layer changes over screen-level layout changes.
- Keep external links domain-validated and route high-risk content through trust/safety.
