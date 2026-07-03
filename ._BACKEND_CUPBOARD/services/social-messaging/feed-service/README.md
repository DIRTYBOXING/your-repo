# feed-service

Responsibilities:

- Serve canonical `GET /api/users/{id}/feed`.
- Merge social graph edges, ranking signals, moderation state, and media availability.
- Support cursor pagination and deterministic ordering.

Required response shape:

- `userId`
- `items[]`
- `nextCursor`

Each item should include:

- identity (`id`, `type`, `authorId`)
- content pointers (`body`, `clipUrl`, `thumbnailUrl`)
- policy state (`visibility`, `moderationState`)
- timestamp (`createdAt`)
