# DFC Social + Messaging Stack 2026

Status: Canonical blueprint for social feed, friends graph, messaging, presence, and clips.

## Core decision summary

| Concern                | Canonical 2026 choice                                                   | Why                                                       |
| ---------------------- | ----------------------------------------------------------------------- | --------------------------------------------------------- |
| Realtime transport     | WebSockets + optional WebTransport (HTTP/3)                             | Lowest friction path now, QUIC-ready extension path later |
| Presence and signaling | Redis Pub/Sub + connection registry                                     | Fast user-to-connection lookup for horizontal scale       |
| Message persistence    | Append log (Kafka or Pulsar) + cold store (Cassandra or DynamoDB style) | Durable writes, ordered replay, offline delivery          |
| Feed generation        | Hybrid fanout (push heavy, pull long-tail)                              | Better latency/cost balance across audience distributions |
| Clips                  | Object store + CDN + moderation queue                                   | Isolates media serving from app/API and PPV manifests     |

## Canonical page contracts

### Social Home

- Backend truth: `GET /api/users/{id}/feed`
- Owner: Feed service
- Required fields: ranked items, clip thumbnails, cursors, moderation state
- Smoke: API contract + Playwright feed rendering check

### Messaging Inbox and Threads

- Backend truth: `GET /api/users/{id}/threads` and `GET /api/threads/{id}/messages`
- Realtime route: WebSocket gateway `wss://<host>/ws/social?userId=<id>`
- Owner: Messaging platform (ws-gateway + message-ingest)
- Smoke: connect + send + receive p95 less than 1 second in staging

### Presence, Typing, Receipts

- Presence store: Redis keys with TTL
- Emit model: throttled and debounced ephemeral events
- Owner: connection-registry
- Smoke: TTL expiry behavior and fanout suppression checks

### Clips and UGC

- Flow: upload -> scan -> transcode -> object store -> CDN -> moderation -> feed eligibility
- Owner: media-ingest + moderation-worker
- Smoke: clip URL returns 200 and appears in feed payload

## Services to include

- `ws-gateway`
- `connection-registry`
- `message-ingest`
- `feed-service`
- `media-ingest`
- `moderation-worker`

## API standards

- Single backend truth per page.
- Contract-first JSON schemas in `docs/api`.
- Idempotency keys required for mutable write endpoints.
- Short-lived entitlement and media tokens.

## Security and moderation baseline

- TLS everywhere.
- Optional E2EE only for DMs when key management is ready.
- ML + human moderation queue for clips and high-risk text.
- Rate limits, abuse scoring, and signaling storm controls.

## Ops and CI requirements

Required smoke checks in CI:

1. WebSocket connect and roundtrip send/receive.
2. Feed contract validation.
3. Clip CDN fetch 200.
4. Presence TTL expiry check.

Required operational hooks:

- Rollback: `docs/runbooks/DFC_PPV_ONE_CLICK_ROLLBACK.md`
- Weekly sweep: `ops/social_messaging_weekly_sweep.sh`
- Synthetic signaling load: `load/signaling_storm.js`

## Ownership model

| Domain               | Owner          | Fallback owner      |
| -------------------- | -------------- | ------------------- |
| Feed ranking and API | Feed service   | Platform API        |
| Realtime routing     | ws-gateway     | connection-registry |
| Message durability   | message-ingest | data platform       |
| Graph and friends    | social graph   | platform API        |
| Clips and moderation | media-ingest   | trust and safety    |
| Incident response    | SRE on-call    | feature owner       |
