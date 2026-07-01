# DFC Face API Contract

## Purpose
Define the minimum data and endpoint contract the DFC face needs in order to render events, promotions, health state, and operator workflows.

## Current implementation reality
- The current Flutter face already reads a Firestore `feed` collection through [lib/feed_service.dart](c:/Data-Fight-Central-safe-bridge/lib/feed_service.dart).
- The current feed model already supports `promotion` items through [lib/feed_model.dart](c:/Data-Fight-Central-safe-bridge/lib/feed_model.dart).
- The backend has event-oriented router registration in [atlas_backend/main.py](c:/Data-Fight-Central-safe-bridge/atlas_backend/main.py), but the public home-feed endpoint described below is still a target contract rather than a fully implemented backend surface.

## Required public reads

### Health
- `GET /health`
- `GET /api/v1/health`
- Used by staging and operations screens to confirm backend readiness.

### Home feed target contract
- `GET /api/v1/feeds/home`
- Query params: `region`, `limit`, `cursor`, `include_promotions`
- Response shape:

```json
{
  "items": [
    {
      "id": "promo_123",
      "type": "promotion",
      "title": "Combat Night Featured",
      "subtitle": "Live this Friday in Brisbane",
      "imageUrl": "https://...",
      "createdAt": 1751328000000,
      "eventId": "event_123",
      "priority": 50,
      "channel": "home_feed"
    }
  ],
  "nextCursor": null
}
```

### Current Firestore-backed feed contract
- Collection: `feed`
- Minimum fields required by [lib/feed_model.dart](c:/Data-Fight-Central-safe-bridge/lib/feed_model.dart):
  - `type`
  - `title`
  - `subtitle`
  - `imageUrl`
  - `createdAt` as epoch milliseconds
- Additional recommended fields for promotions:
  - `eventId`
  - `promotionId`
  - `priority`
  - `channel`
  - `region`

### Event detail target contract
- `GET /api/v1/events/{eventId}`
- Response should include canonical event data plus any active promotion metadata relevant to the current viewer.

## Required admin writes

### Event creation target contract
- `POST /api/v1/admin/events`
- Purpose: create or update canonical event records.

### Promotion creation target contract
- `POST /api/v1/admin/promotions`
- Purpose: create a promotion bound to an event and targeting rules.

### Promotion state transition target contract
- `PUT /api/v1/admin/promotions/{promoId}`
- `POST /api/v1/admin/promotions/{promoId}/activate`
- `DELETE /api/v1/admin/promotions/{promoId}`

## Firestore canonical collections
- `events/{eventId}`
- `promotions/{promotionId}`
- `feed/{feedItemId}`

## Promotion feed behavior
- Active promotions should appear as `type = promotion` in the feed.
- Promotions should always reference a canonical event.
- Promotions should carry enough metadata for ranking, audit, and targeting.
- The UI should never hardcode promo cards; it should render them from feed data.

## Seed path for local and staging use
- Use [scripts/seed_promo.py](c:/Data-Fight-Central-safe-bridge/scripts/seed_promo.py) to create:
  - one canonical event
  - one promotion document
  - one feed item that the current Flutter face can render immediately
