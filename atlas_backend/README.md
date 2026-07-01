# 🧠 DFC Superbeast | Global Combat Sports Intelligence Engine

**The planet-scale combat-sports brain.**

Superbeast is the event-driven, multi-model AI, and PostGIS sensor-fusion core of Data Fight Central (DFC). 
Designed to ingest, analyze, and predict combat sports data in real-time, this architecture shifts DFC from a standard platform into an autonomous, self-optimizing intelligence ecosystem.

Built by The Architect.

## What Exists

- Sensor fusion lane: `routers/chukya_sensor_fusion.py`
- TRIBE v2 lane: `routers/tribe.py`
- Stripe payout lane: `routers/stripe.py`
- Event spine: `event_bus.py`
- Outbox dispatcher worker: `outbox_dispatcher.py`
- Default subscriptions: `subscriptions.py`

## Seed Domains

- `ai_core/`: rewrite, summarize, poster-hook seeds
- `moderation/`: content and sensor alert scoring seeds
- `ppv/`: purchase, replay, settlement seeds with Firestore, Postgres, and memory fallbacks
- `feed/`: feed item generation with Firestore-backed persistence and event-created boost/replay items
- `identity/`: identity vault starter models with Firestore, Postgres, and memory fallback
- `evidence/`: evidence locker seed with Firestore persistence and optional GCS/Firebase Storage JSON manifests
- `distribution/`: caption and drop planning with Firestore-backed persistence
- `activation/`: fighter, gym, creator, promoter activation kits

## Event Flow

1. Routes enqueue events into `event_outbox` through `publish_event()`.
2. `outbox_dispatcher.py` claims pending rows and dispatches them to registered subscribers.
3. `subscriptions.py` connects core reactions such as:
   - `ppv.purchase.created -> feed.boost_requested`
   - `ppv.replay.ready -> feed.replay_drop_requested`
   - `sensor.alert_status_updated -> moderation.sensor_review_requested`
   - `tribe.prediction_generated -> distribution.caption_requested`
   - `identity.profile.created -> activation.kit_requested`

## Operational Muscle

- Stale outbox locks are automatically released back to `retry` when they exceed the configured lock timeout.
- Repeatedly failing events are moved to `dead_letter` once they hit the max-attempt threshold.
- `GET /ops/outbox` exposes queue depth, stale-processing count, dead-letter count, and worker limits for control-plane visibility.

## Local Development

### Run the API

```powershell
& ".venv\Scripts\python.exe" -m uvicorn atlas_backend.main:app --reload
```

### Run the Outbox Worker

```powershell
& ".venv\Scripts\python.exe" -m atlas_backend.outbox_dispatcher
```

### Run Backend Tests

```powershell
& ".venv\Scripts\python.exe" -m pytest atlas_backend\tests
```

### Compose Seed

```powershell
docker compose -f atlas_backend/docker-compose.superbeast.yml up --build
```

## Migrations

- `migrations/20260416_create_event_outbox.sql`
- `migrations/20260416_enhance_event_outbox_dispatcher.sql`
- `migrations/20260416_create_superbeast_persistence_tables.sql`

Apply all three before running the dispatcher against a real database.

## Persistence-Backed Routes

- `GET /ppv/purchases/{purchase_id}`
- `GET /ppv/access/{ppv_id}/{user_id}`
- `GET /ppv/replays/{event_id}`
- `GET /ppv/settlements/{event_id}`
- `GET /feed/{feed_id}`
- `GET /identity/{identity_id}`
- `GET /evidence/{item_id}`
- `GET /distribution/captions/{caption_id}`
- `GET /distribution/drops/{drop_id}`

When Firebase is configured, these routes read and write through Firestore first. When a PostgreSQL database URL is configured, PPV, identity, and evidence can also persist there. Without either, they fall back to an in-memory store so local tests and non-DB sessions still work.

## Why This Matters

This architecture moves DFC away from being just a platform and turns it into a globally scalable, self-healing intelligence network. By decoupling domains into an event-driven spine, Superbeast is built to absorb massive loads—handling PPV command, rights-safe AI moderation, creator distribution, and sub-second sensor workflows—without ever breaking a sweat.
