import asyncio
import logging
from datetime import datetime, timedelta, timezone
from typing import Any
from uuid import uuid4

try:
    from ..firebase_support import get_firestore_client
except ImportError:
    from firebase_support import get_firestore_client


logger = logging.getLogger(__name__)

_events_store: dict[str, dict[str, Any]] = {}
_promotions_store: dict[str, dict[str, Any]] = {}
_feed_store: dict[str, dict[str, Any]] = {}


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def epoch_millis(value: datetime) -> int:
    return int(value.timestamp() * 1000)


def build_event_document(
    title: str,
    slug: str | None,
    start_at: datetime,
    end_at: datetime,
    venue: dict[str, Any] | None = None,
    status: str = 'published',
) -> dict[str, Any]:
    now = utc_now()
    event_id = str(uuid4())
    clean_slug = (slug or title).strip().lower().replace(' ', '-')
    return {
        'id': event_id,
        'title': title.strip(),
        'slug': clean_slug,
        'start_at': start_at,
        'end_at': end_at,
        'venue': venue or {},
        'status': status,
        'fighters': [],
        'media': [],
        'created_by': 'admin',
        'created_at': now,
        'updated_at': now,
    }


def build_promotion_document(
    event_id: str,
    title: str | None,
    start_at: datetime | None,
    end_at: datetime | None,
    priority: int,
    channels: list[str],
    targeting: dict[str, Any] | None,
    status: str | None,
) -> dict[str, Any]:
    now = utc_now()
    actual_start = start_at or now
    actual_end = end_at or (actual_start + timedelta(hours=48))
    return {
        'id': str(uuid4()),
        'event_id': event_id,
        'title': title.strip() if title else None,
        'start_at': actual_start,
        'end_at': actual_end,
        'priority': priority,
        'channels': channels,
        'targeting': targeting or {},
        'status': status or ('active' if actual_start <= now else 'scheduled'),
        'created_by': 'admin',
        'created_at': now,
        'updated_at': now,
        'metrics': {'impressions': 0, 'clicks': 0, 'conversions': 0},
    }


def build_feed_item(
    promotion: dict[str, Any],
    event: dict[str, Any] | None = None,
    image_url: str | None = None,
) -> dict[str, Any]:
    now = utc_now()
    event_title = event.get('title') if event else promotion.get('event_id')
    return {
        'id': str(uuid4()),
        'type': 'promotion',
        'promotionId': promotion['id'],
        'promo_id': promotion['id'],
        'eventId': promotion['event_id'],
        'event_id': promotion['event_id'],
        'title': promotion.get('title') or event_title,
        'subtitle': f"Promoted event: {event_title}",
        'imageUrl': image_url or '',
        'createdAt': epoch_millis(now),
        'priority': promotion.get('priority', 0),
        'channels': promotion.get('channels', ['home_feed']),
        'channel': promotion.get('channels', ['home_feed'])[0],
        'region': (promotion.get('targeting') or {}).get('regions', ['global'])[0],
        'status': promotion.get('status', 'scheduled'),
        'start_at': promotion['start_at'],
        'end_at': promotion['end_at'],
        'created_at': now,
    }


async def _set_document(collection_name: str, document_id: str, payload: dict[str, Any]) -> None:
    client = get_firestore_client()
    if client is None:
        return
    await asyncio.to_thread(client.collection(collection_name).document(document_id).set, payload, merge=True)


async def _get_document(collection_name: str, document_id: str) -> dict[str, Any] | None:
    client = get_firestore_client()
    if client is None:
        return None
    snapshot = await asyncio.to_thread(client.collection(collection_name).document(document_id).get)
    if not snapshot.exists:
        return None
    return snapshot.to_dict()


async def _delete_document(collection_name: str, document_id: str) -> None:
    client = get_firestore_client()
    if client is None:
        return
    await asyncio.to_thread(client.collection(collection_name).document(document_id).delete)


async def create_event(payload: dict[str, Any]) -> dict[str, Any]:
    _events_store[payload['id']] = dict(payload)
    try:
        await _set_document('events', payload['id'], payload)
    except Exception as exc:
        logger.warning('Event persistence failed for %s: %s', payload['id'], exc)
    return payload


async def delete_event(event_id: str) -> None:
    _events_store.pop(event_id, None)
    try:
        await _delete_document('events', event_id)
    except Exception as exc:
        logger.warning('Event deletion failed for %s: %s', event_id, exc)


async def fetch_event(event_id: str) -> dict[str, Any] | None:
    doc = await _get_document('events', event_id)
    if doc is not None:
        return doc
    return _events_store.get(event_id)


async def create_promotion(payload: dict[str, Any], event: dict[str, Any] | None = None) -> tuple[dict[str, Any], dict[str, Any]]:
    feed_item = build_feed_item(payload, event=event)
    _promotions_store[payload['id']] = dict(payload)
    _feed_store[feed_item['id']] = dict(feed_item)
    try:
        await _set_document('promotions', payload['id'], payload)
        await _set_document('feed', feed_item['id'], feed_item)
    except Exception as exc:
        logger.warning('Promotion persistence failed for %s: %s', payload['id'], exc)
    return payload, feed_item


async def fetch_promotion(promotion_id: str) -> dict[str, Any] | None:
    doc = await _get_document('promotions', promotion_id)
    if doc is not None:
        return doc
    return _promotions_store.get(promotion_id)


async def update_promotion(promotion_id: str, update: dict[str, Any]) -> dict[str, Any] | None:
    current = await fetch_promotion(promotion_id)
    if current is None:
        return None
    merged = {**current, **update, 'updated_at': utc_now()}
    _promotions_store[promotion_id] = merged
    try:
        await _set_document('promotions', promotion_id, merged)
    except Exception as exc:
        logger.warning('Promotion update failed for %s: %s', promotion_id, exc)
    return merged


async def delete_promotion(promotion_id: str) -> None:
    _promotions_store.pop(promotion_id, None)
    try:
        await _delete_document('promotions', promotion_id)
    except Exception as exc:
        logger.warning('Promotion deletion failed for %s: %s', promotion_id, exc)

    matching_feed_ids = [
        feed_id
        for feed_id, item in _feed_store.items()
        if item.get('promotionId') == promotion_id or item.get('promo_id') == promotion_id
    ]
    for feed_id in matching_feed_ids:
        _feed_store.pop(feed_id, None)

    client = get_firestore_client()
    if client is None:
        return
    try:
        docs = await asyncio.to_thread(lambda: list(client.collection('feed').where('promotionId', '==', promotion_id).stream()))
        for doc in docs:
            await asyncio.to_thread(client.collection('feed').document(doc.id).delete)
    except Exception as exc:
        logger.warning('Feed cleanup failed for promotion %s: %s', promotion_id, exc)


def _is_active_feed_item(item: dict[str, Any], now: datetime) -> bool:
    if item.get('type') != 'promotion':
        return True

    status = item.get('status')
    if status not in (None, 'active', 'scheduled'):
        return False

    start_at = item.get('start_at')
    end_at = item.get('end_at')
    if isinstance(start_at, datetime) and start_at > now:
        return False
    if isinstance(end_at, datetime) and end_at < now:
        return False
    return True


async def _load_feed_documents(limit: int) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    client = get_firestore_client()
    if client is not None:
        try:
            docs = await asyncio.to_thread(lambda: list(client.collection('feed').limit(max(limit, 50)).stream()))
            items = [doc.to_dict() for doc in docs]
        except Exception as exc:
            logger.warning('Feed fetch failed: %s', exc)
    return items


async def list_home_feed(limit: int = 20, include_promotions: bool = True) -> list[dict[str, Any]]:
    items = await _load_feed_documents(limit)
    if not items:
        items = list(_feed_store.values())

    if not include_promotions:
        items = [item for item in items if item.get('type') != 'promotion']

    now = utc_now()
    visible_items = [item for item in items if _is_active_feed_item(item, now)]

    visible_items.sort(
        key=lambda item: (item.get('priority', 0), item.get('createdAt', 0)),
        reverse=True,
    )
    return visible_items[:limit]
