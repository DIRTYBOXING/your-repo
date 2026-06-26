# Social Messaging Service Skeleton

This folder contains the 2026 social + messaging service skeleton for DFC.

## Services

- `ws-gateway`: WebSocket transport and route fanout.
- `connection-registry`: user to connection mapping and presence TTL handling.
- `message-ingest`: append-only message ingest facade (Kafka or Pulsar producer boundary).
- `feed-service`: feed aggregation and ranking API boundary.
- `media-ingest`: upload validation and transcode job handoff.
- `moderation-worker`: moderation queue processing and verdict emission.

## Contracts

- API and realtime contracts: `docs/api/dfc-social-messaging.contracts.json`

## Required smoke checks

- WebSocket connect and roundtrip message.
- Feed contract response shape.
- Presence TTL expiry.
- Clip CDN 200 check.

## Ownership

- Product owner: Social and Messaging
- Platform owner: Realtime and feed infrastructure
- Safety owner: Moderation and abuse
