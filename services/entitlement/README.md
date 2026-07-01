# entitlement

Canonical owner for server-side entitlement checks and short-lived playback tokens.

Requirements:

- No client-side bypass authority
- Token TTL and audience checks
- Replay and entitlement compatibility rules

Smoke check:

- entitled token grants playback
- non-entitled token denied with explicit reason
