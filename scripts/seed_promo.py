#!/usr/bin/env python3
import os
import uuid
from datetime import datetime, timedelta, timezone

from google.cloud import firestore


PROJECT_ID = os.getenv("GCP_PROJECT", "datafightcentral")
DEFAULT_REGION = os.getenv("DFC_PROMO_REGION", "AU")
DEFAULT_CHANNEL = os.getenv("DFC_PROMO_CHANNEL", "home_feed")


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def epoch_millis(value: datetime) -> int:
    return int(value.timestamp() * 1000)


def create_event(db: firestore.Client, title: str, start_offset_days: int = 7) -> str:
    event_id = str(uuid.uuid4())
    now = utc_now()
    start_at = now + timedelta(days=start_offset_days)
    end_at = start_at + timedelta(hours=4)

    event = {
        "id": event_id,
        "title": title,
        "slug": title.lower().replace(" ", "-"),
        "start_at": start_at,
        "end_at": end_at,
        "venue": {"name": "Main Arena", "city": "Brisbane", "country": DEFAULT_REGION},
        "fighters": [],
        "media": [],
        "status": "published",
        "created_by": "ops",
        "created_at": now,
        "updated_at": now,
    }
    db.collection("events").document(event_id).set(event)
    print(f"Created event {event_id}")
    return event_id


def create_promotion(
    db: firestore.Client,
    event_id: str,
    title: str = "Combat Night Featured",
    start_in_minutes: int = 0,
    duration_hours: int = 48,
    priority: int = 50,
) -> str:
    promotion_id = str(uuid.uuid4())
    now = utc_now()
    start_at = now + timedelta(minutes=start_in_minutes)
    end_at = now + timedelta(hours=duration_hours)

    promotion = {
        "id": promotion_id,
        "event_id": event_id,
        "title": title,
        "start_at": start_at,
        "end_at": end_at,
        "priority": priority,
        "channels": [DEFAULT_CHANNEL, "banner"],
        "targeting": {"regions": [DEFAULT_REGION], "tags": []},
        "status": "scheduled" if start_in_minutes > 0 else "active",
        "created_by": "ops",
        "created_at": now,
        "metrics": {"impressions": 0, "clicks": 0, "conversions": 0},
    }
    db.collection("promotions").document(promotion_id).set(promotion)
    print(f"Created promotion {promotion_id}")
    return promotion_id


def create_feed_item(
    db: firestore.Client,
    event_id: str,
    promotion_id: str,
    title: str,
    subtitle: str,
    image_url: str,
    priority: int,
) -> str:
    feed_item_id = str(uuid.uuid4())
    now = utc_now()
    feed_item = {
        "id": feed_item_id,
        "type": "promotion",
        "title": title,
        "subtitle": subtitle,
        "imageUrl": image_url,
        "createdAt": epoch_millis(now),
        "eventId": event_id,
        "promotionId": promotion_id,
        "priority": priority,
        "channel": DEFAULT_CHANNEL,
        "region": DEFAULT_REGION,
        "status": "active",
    }
    db.collection("feed").document(feed_item_id).set(feed_item)
    print(f"Created feed item {feed_item_id}")
    return feed_item_id


def seed() -> None:
    db = firestore.Client(project=PROJECT_ID)
    event_id = create_event(db, "Combat Night Promotional Event")
    promotion_id = create_promotion(db, event_id)
    feed_item_id = create_feed_item(
        db,
        event_id,
        promotion_id,
        title="Combat Night Featured",
        subtitle="Seeded promotional event for the DFC face",
        image_url="https://storage.googleapis.com/datafightcentral.firebasestorage.app/promotions/combat-night-featured.jpg",
        priority=50,
    )
    print(f"Seed complete: event={event_id} promotion={promotion_id} feed_item={feed_item_id}")


if __name__ == "__main__":
    seed()
