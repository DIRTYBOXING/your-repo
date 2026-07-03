# feed-service

Canonical owner for `GET /api/users/{id}/feed`.

Smoke checks:

- Contract shape (`userId`, `items`, `nextCursor`).
- Clip thumbnail pointer present for clip items.

For CI smoke, use `mock-server.js`.
