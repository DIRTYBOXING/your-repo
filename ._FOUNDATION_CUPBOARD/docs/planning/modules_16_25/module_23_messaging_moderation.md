# Module 23 — Messaging Moderation Hooks & Rate Limits

**Owner:** @messaging

**Files to add/modify**
- backend/messaging/moderation_hooks.dart
- backend/messaging/rate_limit_middleware.dart
- infra/messaging/abuse_detector_worker.dart

**APIs required**
- POST /messages/send (with moderation pre-check)
- POST /messages/report
- GET /messages/rate_limit_status/{userId}

**DB collections**
- message_flags (messageId, reporterId, reason)
- rate_limits (userId, windowStart, count)
- abuse_signals (userId, signalType, score)

**Tests**
- Unit: moderation hook decision logic
- Integration: rate limit enforcement under concurrency
- Abuse: simulated spam and automated detection tests

**Release gate**
- Rate limits enforced and logged
- Moderation hooks flag messages and create moderation cases
- No false positives above threshold in staging tests
