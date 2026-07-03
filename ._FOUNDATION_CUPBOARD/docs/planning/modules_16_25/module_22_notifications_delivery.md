# Module 22 — Notifications Delivery with Channel Fallback

**Owner:** @notifications

**Files to add/modify**
- backend/notifications/delivery_service.dart
- backend/notifications/channel_adapters/{push,email,sms}.dart
- infra/notifications/retry_worker.dart

**APIs required**
- POST /notifications/send
- GET /notifications/status/{notificationId}

**DB collections**
- notifications (id, userId, payload, channels, status)
- delivery_logs (notificationId, channel, status, providerResponse)
- notification_preferences (userId, channels, dnd)

**Tests**
- Unit: channel selection and fallback logic
- Integration: end-to-end delivery simulation with mocked providers
- Resilience: retry and backoff tests

**Release gate**
- Delivery logs show expected channel attempts and fallbacks
- Preferences respected and DND honored
- No critical provider errors in staging
