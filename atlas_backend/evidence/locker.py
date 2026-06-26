import asyncio
import hashlib
import json
import logging
import os
from typing import Any

try:
    from ..db import get_db_pool
    from ..firebase_support import firestore_timestamp_value, get_firestore_client, upload_json_blob
except ImportError:
    from db import get_db_pool
    from firebase_support import firestore_timestamp_value, get_firestore_client, upload_json_blob


logger = logging.getLogger(__name__)

_evidence_store: dict[str, dict] = {}


def _db_persistence_enabled() -> bool:
    return bool(os.getenv('CONTROLROOM_DATABASE_URL') or os.getenv('DATABASE_URL') or os.getenv('DFC_DATABASE_URL'))


async def _save_firestore_record(record: dict) -> bool:
    client = get_firestore_client()
    if client is None:
        return False

    doc_ref = client.collection('evidence_records').document(record['item_id'])
    document = {
        **record,
        'updated_at': firestore_timestamp_value(),
        'stored_at': firestore_timestamp_value(),
    }
    try:
        await asyncio.to_thread(doc_ref.set, document, merge=True)
        return True
    except Exception as exc:
        logger.warning('Evidence Firestore persistence failed for %s: %s', record['item_id'], exc)
        return False


async def _fetch_firestore_record(item_id: str) -> dict | None:
    client = get_firestore_client()
    if client is None:
        return None

    doc_ref = client.collection('evidence_records').document(item_id)
    try:
        snapshot: Any = await asyncio.to_thread(doc_ref.get)
    except Exception as exc:
        logger.warning('Evidence Firestore lookup failed for %s: %s', item_id, exc)
        return None

    if not snapshot.exists:
        return None
    return snapshot.to_dict()


def build_evidence_record(item_id: str, source: str, content_type: str, notes: str | None = None) -> dict:
    payload = {'item_id': item_id, 'source': source, 'content_type': content_type, 'notes': notes or ''}
    digest = hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()
    return {**payload, 'digest': digest, 'status': 'stored'}


async def store_evidence_record(item_id: str, source: str, content_type: str, notes: str | None = None) -> dict:
    record = build_evidence_record(item_id, source, content_type, notes)
    storage_info = await asyncio.to_thread(upload_json_blob, f'evidence/records/{item_id}.json', record)
    if storage_info is not None:
        record.update(storage_info)

    _evidence_store[item_id] = dict(record)
    if await _save_firestore_record(record):
        return record

    if not _db_persistence_enabled():
        return record

    try:
        pool = await get_db_pool()
        async with pool.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO evidence_records (item_id, source, content_type, notes, digest, status)
                VALUES ($1, $2, $3, $4, $5, $6)
                ON CONFLICT (item_id) DO UPDATE
                SET source = EXCLUDED.source,
                    content_type = EXCLUDED.content_type,
                    notes = EXCLUDED.notes,
                    digest = EXCLUDED.digest,
                    status = EXCLUDED.status,
                    stored_at = NOW()
                """,
                record['item_id'],
                record['source'],
                record['content_type'],
                record['notes'],
                record['digest'],
                record['status'],
            )
    except Exception as exc:
        logger.warning('Evidence persistence failed, using fallback store: %s', exc)

    return record


async def fetch_evidence_record(item_id: str) -> dict | None:
    firestore_record = await _fetch_firestore_record(item_id)
    if firestore_record is not None:
        return firestore_record

    if _db_persistence_enabled():
        try:
            pool = await get_db_pool()
            async with pool.acquire() as conn:
                row = await conn.fetchrow(
                    """
                    SELECT item_id, source, content_type, notes, digest, status
                    FROM evidence_records
                    WHERE item_id = $1
                    """,
                    item_id,
                )
            if row:
                return dict(row)
        except Exception as exc:
            logger.warning('Evidence lookup failed, using fallback store: %s', exc)

    return _evidence_store.get(item_id)
