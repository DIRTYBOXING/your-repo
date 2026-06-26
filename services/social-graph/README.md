# social-graph

Canonical owner for follow/friend graph edges.

Model:

- `user_id`, `target_id`, `relation`, `created_at`

Acceptance target:

- Follow/unfollow eventual consistency within 5 seconds.

Smoke check:

- Create edge -> read edge -> remove edge lifecycle.
