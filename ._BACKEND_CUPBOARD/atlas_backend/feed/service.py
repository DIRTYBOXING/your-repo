import asyncio
import logging
from hashlib import sha1

from google.cloud.firestore_v1.base_query import FieldFilter

try:
    from ..firebase_support import firestore_timestamp_value, get_firestore_client
except ImportError:
    from firebase_support import firestore_timestamp_value, get_firestore_client


logger = logging.getLogger(__name__)

_feed_store: dict[str, dict] = {}


def build_feed_item(text: str, source: str = 'manual', metadata: dict | None = None) -> dict:
    feed_id = sha1(f'{source}:{text}'.encode()).hexdigest()[:12]
    return {
        'feed_id': feed_id,
        'source': source,
        'text': text,
        'status': 'published',
        'metadata': metadata or {},
    }


async def save_feed_item(item: dict) -> dict:
    _feed_store[item['feed_id']] = dict(item)

    client = get_firestore_client()
    if client is None:
        return item

    doc_ref = client.collection('feed_items').document(item['feed_id'])
    document = {
        **item,
        'updated_at': firestore_timestamp_value(),
        'created_at': firestore_timestamp_value(),
    }
    try:
        await asyncio.to_thread(doc_ref.set, document, merge=True)
    except Exception as exc:
        logger.warning('Feed Firestore persistence failed for %s: %s', item['feed_id'], exc)

    return item


async def create_feed_item(text: str, source: str = 'manual', metadata: dict | None = None) -> dict:
    item = build_feed_item(text, source, metadata)
    await save_feed_item(item)
    return item


async def fetch_feed_item(feed_id: str) -> dict | None:
    client = get_firestore_client()
    if client is not None:
        doc_ref = client.collection('feed_items').document(feed_id)
        try:
            snapshot = await asyncio.to_thread(doc_ref.get)
            if snapshot.exists:
                return snapshot.to_dict()
        except Exception as exc:
            logger.warning('Feed Firestore lookup failed for %s: %s', feed_id, exc)

    return _feed_store.get(feed_id)


async def list_feed_items(limit: int = 20, source: str | None = None) -> list[dict]:
    client = get_firestore_client()
    if client is not None:
        query = client.collection('feed_items')
        if source:
            query = query.where(filter=FieldFilter('source', '==', source))
        try:
            docs = await asyncio.to_thread(lambda: list(query.limit(limit).stream()))
            if docs:
                return [doc.to_dict() for doc in docs]
        except Exception as exc:
            logger.warning('Feed Firestore list failed: %s', exc)

    values = list(_feed_store.values())
    if source is not None:
        values = [item for item in values if item.get('source') == source]
    return list(reversed(values[-limit:]))


def generate_feed_item(text: str, source: str = 'manual') -> dict:
    return build_feed_item(text, source)


def build_boost_message(ppv_id: str, user_id: str | None = None) -> dict:
    return {
        'headline': f'PPV momentum building for {ppv_id}',
        'context': f'Latest purchase came from {user_id}' if user_id else 'Purchase pulse rising',
    }


def build_replay_drop_item(event_id: str, replay_url: str) -> dict:
    return {
        'event_id': event_id,
        'replay_url': replay_url,
        'headline': f'Replay ready for {event_id}',
    }
