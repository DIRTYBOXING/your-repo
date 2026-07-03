# DFC Stack Blueprint v1

## Objective

Run DFC on a tight Google-first control plane while using specialized providers only where they save time, reduce operational drag, and do not weaken DFC ownership of the business logic.

## Canonical Rule

DFC owns the business logic.
Third parties provide specialized infrastructure.
Firebase + GCP is the control plane.

## Keep

- Firebase Auth for identity and operator access.
- Firestore for workflow state, entitlements, social objects, approvals, and operator records.
- Firebase Functions for app-triggered business logic and light orchestration.
- Cloud Run for heavier services, media helpers, long-running APIs, and jobs that do not belong in Functions.
- Cloud Storage for posters, replays, upload staging, and generated assets.
- Cloud Scheduler plus Cloud Tasks or Pub/Sub for retries, queueing, and background automation.
- Gemini or Vertex AI only where AI adds leverage to content, intelligence, moderation, and operator tooling.
- Stripe for subscriptions, PPV checkout, and money movement.
- Mux for live ingest and playback.
- SendGrid for transactional email.

## Replace

- Replace any thought of Azure as a product dependency with Azure as an optional VS Code extension only.
- Replace a single all-in-one n8n workflow with two DFC workflows: Content Brain and Publisher.
- Replace direct social posting inside the brain workflow with a separate publisher lane.
- Replace provider-owned orchestration logic with DFC-owned workflow state in Firestore and Firebase Functions.
- Replace broad multi-cloud drift with one primary control plane: Firebase + GCP.

## Do Not Build

- Do not build live video infrastructure from scratch.
- Do not build DRM infrastructure from scratch.
- Do not build payment rails from scratch.
- Do not build email delivery infrastructure from scratch.
- Do not build LLM hosting and model ops from scratch.
- Do not build push infrastructure from scratch.
- Do not build search infrastructure from scratch unless scale forces it later.

## DFC Should Build

- Promoter Control Room.
- PPV entitlement and access logic.
- Replay and clip automation.
- Content Brain orchestration.
- Event lifecycle engine.
- Fight-specific ranking and intelligence surfaces.
- Trust, approvals, moderation, and audit surfaces.
- Conversion and monetization flows tailored to combat promotions.

## Operational Planes

- Control plane: Firebase + GCP.
- Money plane: Stripe.
- Media plane: Mux.
- AI assist lane: Gemini or Vertex AI.
- Automation glue: n8n only as optional automation glue, not the source of truth.

## Azure Position

- Allowed: VS Code extension, occasional reference tooling, temporary dashboard convenience.
- Not allowed: runtime identity layer, AI runtime foundation, PPV backend foundation, or orchestration backbone.

## Delivery Standard

- Firestore remains the durable workflow ledger.
- Firebase Functions and Cloud Run remain the canonical execution surfaces.
- n8n stays replaceable and subordinate to DFC state, doctrine, and operator controls.
