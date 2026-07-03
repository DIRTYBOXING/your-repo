# connection-registry

Responsibilities:

- Maintain userId -> connectionId mappings.
- Publish presence events to Redis Pub/Sub.
- Enforce presence TTL expiry.

Suggested storage keys:

- `presence:user:{userId}` with TTL
- `connections:user:{userId}` set of connection ids

Input events:

- `presence.online`
- `presence.typing`
- `presence.offline`

Output events:

- `presence.updated`
- `presence.expired`
