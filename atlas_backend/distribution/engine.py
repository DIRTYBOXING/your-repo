import asyncio
import logging
from hashlib import sha1

try:
    from ..firebase_support import firestore_timestamp_value, get_firestore_client
except ImportError:
    from firebase_support import firestore_timestamp_value, get_firestore_client


logger = logging.getLogger(__name__)

_caption_store: dict[str, dict] = {}
_drop_store: dict[str, dict] = {}


def auto_caption(text: str, suffix: str = '#DFC') -> str:
    return f'{text.strip()} {suffix}'.strip()


def build_caption_record(text: str, metadata: dict | None = None) -> dict:
    caption_id = sha1(text.encode()).hexdigest()[:12]
    return {
        'caption_id': caption_id,
        'text': text,
        'caption': auto_caption(text),
        'status': 'generated_seed',
        'metadata': metadata or {},
    }


def build_drop_plan(channel: str, text: str, metadata: dict | None = None) -> dict:
    drop_id = sha1(f'{channel}:{text}'.encode()).hexdigest()[:12]
    return {
        'drop_id': drop_id,
        'channel': channel,
        'caption': auto_caption(text),
        'status': 'scheduled_seed',
        'metadata': metadata or {},
    }


async def save_caption_record(record: dict) -> dict:
    _caption_store[record['caption_id']] = dict(record)

    client = get_firestore_client()
    if client is None:
        return record

    doc_ref = client.collection('distribution_captions').document(record['caption_id'])
    document = {
        **record,
        'updated_at': firestore_timestamp_value(),
        'created_at': firestore_timestamp_value(),
    }
    try:
        await asyncio.to_thread(doc_ref.set, document, merge=True)
    except Exception as exc:
        logger.warning('Distribution caption Firestore persistence failed for %s: %s', record['caption_id'], exc)
    return record


async def create_caption_record(text: str, metadata: dict | None = None) -> dict:
    record = build_caption_record(text, metadata)
    await save_caption_record(record)
    return record


async def fetch_caption_record(caption_id: str) -> dict | None:
    client = get_firestore_client()
    if client is not None:
        doc_ref = client.collection('distribution_captions').document(caption_id)
        try:
            snapshot = await asyncio.to_thread(doc_ref.get)
            if snapshot.exists:
                return snapshot.to_dict()
        except Exception as exc:
            logger.warning('Distribution caption Firestore lookup failed for %s: %s', caption_id, exc)

    return _caption_store.get(caption_id)


async def save_drop_plan(plan: dict) -> dict:
    _drop_store[plan['drop_id']] = dict(plan)

    client = get_firestore_client()
    if client is None:
        return plan

    doc_ref = client.collection('distribution_drop_plans').document(plan['drop_id'])
    document = {
        **plan,
        'updated_at': firestore_timestamp_value(),
        'created_at': firestore_timestamp_value(),
    }
    try:
        await asyncio.to_thread(doc_ref.set, document, merge=True)
    except Exception as exc:
        logger.warning('Distribution drop Firestore persistence failed for %s: %s', plan['drop_id'], exc)
    return plan


async def create_drop_plan(channel: str, text: str, metadata: dict | None = None) -> dict:
    plan = build_drop_plan(channel, text, metadata)
    await save_drop_plan(plan)
    return plan


async def fetch_drop_plan(drop_id: str) -> dict | None:
    client = get_firestore_client()
    if client is not None:
        doc_ref = client.collection('distribution_drop_plans').document(drop_id)
        try:
            snapshot = await asyncio.to_thread(doc_ref.get)
            if snapshot.exists:
                return snapshot.to_dict()
        except Exception as exc:
            logger.warning('Distribution drop Firestore lookup failed for %s: %s', drop_id, exc)

    return _drop_store.get(drop_id)
