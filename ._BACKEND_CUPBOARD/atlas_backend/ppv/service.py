import asyncio
import logging
import os
from hashlib import sha1

try:
    from ..db import get_db_pool
    from ..firebase_support import firestore_timestamp_value, get_firestore_client
except ImportError:
    from db import get_db_pool
    from firebase_support import firestore_timestamp_value, get_firestore_client


logger = logging.getLogger(__name__)

_purchase_store: dict[str, dict] = {}
_access_store: dict[tuple[str, str], dict] = {}
_replay_store: dict[str, dict] = {}
_settlement_store: dict[str, dict] = {}


def _db_persistence_enabled() -> bool:
    return bool(os.getenv('CONTROLROOM_DATABASE_URL') or os.getenv('DATABASE_URL') or os.getenv('DFC_DATABASE_URL'))


async def _save_firestore_document(collection_name: str, document_id: str, payload: dict) -> bool:
    client = get_firestore_client()
    if client is None:
        return False

    doc_ref = client.collection(collection_name).document(document_id)
    document = {
        **payload,
        'updated_at': firestore_timestamp_value(),
        'created_at': payload.get('created_at', firestore_timestamp_value()),
    }
    try:
        await asyncio.to_thread(doc_ref.set, document, merge=True)
        return True
    except Exception as exc:
        logger.warning('Firestore persistence failed for %s/%s: %s', collection_name, document_id, exc)
        return False


async def _fetch_firestore_document(collection_name: str, document_id: str) -> dict | None:
    client = get_firestore_client()
    if client is None:
        return None

    doc_ref = client.collection(collection_name).document(document_id)
    try:
        snapshot = await asyncio.to_thread(doc_ref.get)
    except Exception as exc:
        logger.warning('Firestore lookup failed for %s/%s: %s', collection_name, document_id, exc)
        return None

    if not snapshot.exists:
        return None
    return snapshot.to_dict()


def create_purchase_record(ppv_id: str, user_id: str, price_cents: int) -> dict:
    purchase_id = sha1(f'{ppv_id}:{user_id}:{price_cents}'.encode()).hexdigest()[:12]
    return {
        'purchase_id': purchase_id,
        'ppv_id': ppv_id,
        'user_id': user_id,
        'price_cents': price_cents,
        'status': 'purchased',
    }


def build_access_grant(ppv_id: str, user_id: str) -> dict:
    return {
        'ppv_id': ppv_id,
        'user_id': user_id,
        'access_status': 'granted',
    }


def build_replay_ready(event_id: str, replay_url: str, expires_in_hours: int = 72) -> dict:
    return {
        'event_id': event_id,
        'replay_url': replay_url,
        'expires_in_hours': expires_in_hours,
        'status': 'ready',
    }


def build_settlement_snapshot(event_id: str, gross_cents: int, fee_bps: int = 1000) -> dict:
    fees = (gross_cents * fee_bps) // 10000
    return {
        'event_id': event_id,
        'gross_cents': gross_cents,
        'fees_cents': fees,
        'net_cents': gross_cents - fees,
        'fee_bps': fee_bps,
    }


async def save_purchase_record(record: dict) -> dict:
    _purchase_store[record['purchase_id']] = dict(record)
    if await _save_firestore_document('ppv_purchases', record['purchase_id'], record):
        return record

    if not _db_persistence_enabled():
        return record

    try:
        pool = await get_db_pool()
        async with pool.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO ppv_purchases (purchase_id, ppv_id, user_id, price_cents, status)
                VALUES ($1, $2, $3, $4, $5)
                ON CONFLICT (purchase_id) DO UPDATE
                SET ppv_id = EXCLUDED.ppv_id,
                    user_id = EXCLUDED.user_id,
                    price_cents = EXCLUDED.price_cents,
                    status = EXCLUDED.status
                """,
                record['purchase_id'],
                record['ppv_id'],
                record['user_id'],
                record['price_cents'],
                record['status'],
            )
    except Exception as exc:
        logger.warning('PPV purchase persistence failed, using fallback store: %s', exc)

    return record


async def save_access_grant(access: dict) -> dict:
    _access_store[(access['ppv_id'], access['user_id'])] = dict(access)
    doc_id = f"{access['ppv_id']}__{access['user_id']}"
    if await _save_firestore_document('ppv_access_grants', doc_id, access):
        return access

    if not _db_persistence_enabled():
        return access

    try:
        pool = await get_db_pool()
        async with pool.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO ppv_access_grants (ppv_id, user_id, access_status)
                VALUES ($1, $2, $3)
                ON CONFLICT (ppv_id, user_id) DO UPDATE
                SET access_status = EXCLUDED.access_status,
                    granted_at = NOW()
                """,
                access['ppv_id'],
                access['user_id'],
                access['access_status'],
            )
    except Exception as exc:
        logger.warning('PPV access persistence failed, using fallback store: %s', exc)

    return access


async def save_replay_ready_record(replay: dict) -> dict:
    _replay_store[replay['event_id']] = dict(replay)
    if await _save_firestore_document('ppv_replays', replay['event_id'], replay):
        return replay

    if not _db_persistence_enabled():
        return replay

    try:
        pool = await get_db_pool()
        async with pool.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO ppv_replays (event_id, replay_url, expires_in_hours, status)
                VALUES ($1, $2, $3, $4)
                ON CONFLICT (event_id) DO UPDATE
                SET replay_url = EXCLUDED.replay_url,
                    expires_in_hours = EXCLUDED.expires_in_hours,
                    status = EXCLUDED.status,
                    ready_at = NOW()
                """,
                replay['event_id'],
                replay['replay_url'],
                replay['expires_in_hours'],
                replay['status'],
            )
    except Exception as exc:
        logger.warning('PPV replay persistence failed, using fallback store: %s', exc)

    return replay


async def save_settlement_snapshot(snapshot: dict) -> dict:
    _settlement_store[snapshot['event_id']] = dict(snapshot)
    if await _save_firestore_document('ppv_settlements', snapshot['event_id'], snapshot):
        return snapshot

    if not _db_persistence_enabled():
        return snapshot

    try:
        pool = await get_db_pool()
        async with pool.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO ppv_settlements (event_id, gross_cents, fees_cents, net_cents, fee_bps)
                VALUES ($1, $2, $3, $4, $5)
                ON CONFLICT (event_id) DO UPDATE
                SET gross_cents = EXCLUDED.gross_cents,
                    fees_cents = EXCLUDED.fees_cents,
                    net_cents = EXCLUDED.net_cents,
                    fee_bps = EXCLUDED.fee_bps,
                    updated_at = NOW()
                """,
                snapshot['event_id'],
                snapshot['gross_cents'],
                snapshot['fees_cents'],
                snapshot['net_cents'],
                snapshot['fee_bps'],
            )
    except Exception as exc:
        logger.warning('PPV settlement persistence failed, using fallback store: %s', exc)

    return snapshot


async def record_purchase(ppv_id: str, user_id: str, price_cents: int) -> tuple[dict, dict]:
    purchase = create_purchase_record(ppv_id, user_id, price_cents)
    access = build_access_grant(ppv_id, user_id)
    await save_purchase_record(purchase)
    await save_access_grant(access)
    return purchase, access


async def record_replay_ready(event_id: str, replay_url: str, expires_in_hours: int = 72) -> dict:
    replay = build_replay_ready(event_id, replay_url, expires_in_hours)
    await save_replay_ready_record(replay)
    return replay


async def record_settlement(event_id: str, gross_cents: int, fee_bps: int = 1000) -> dict:
    snapshot = build_settlement_snapshot(event_id, gross_cents, fee_bps)
    await save_settlement_snapshot(snapshot)
    return snapshot


async def fetch_purchase_record(purchase_id: str) -> dict | None:
    firestore_record = await _fetch_firestore_document('ppv_purchases', purchase_id)
    if firestore_record is not None:
        return firestore_record

    if _db_persistence_enabled():
        try:
            pool = await get_db_pool()
            async with pool.acquire() as conn:
                row = await conn.fetchrow(
                    """
                    SELECT purchase_id, ppv_id, user_id, price_cents, status
                    FROM ppv_purchases
                    WHERE purchase_id = $1
                    """,
                    purchase_id,
                )
            if row:
                return dict(row)
        except Exception as exc:
            logger.warning('PPV purchase lookup failed, using fallback store: %s', exc)

    return _purchase_store.get(purchase_id)


async def fetch_access_grant(ppv_id: str, user_id: str) -> dict | None:
    firestore_record = await _fetch_firestore_document('ppv_access_grants', f'{ppv_id}__{user_id}')
    if firestore_record is not None:
        return firestore_record

    if _db_persistence_enabled():
        try:
            pool = await get_db_pool()
            async with pool.acquire() as conn:
                row = await conn.fetchrow(
                    """
                    SELECT ppv_id, user_id, access_status
                    FROM ppv_access_grants
                    WHERE ppv_id = $1 AND user_id = $2
                    """,
                    ppv_id,
                    user_id,
                )
            if row:
                return dict(row)
        except Exception as exc:
            logger.warning('PPV access lookup failed, using fallback store: %s', exc)

    return _access_store.get((ppv_id, user_id))


async def fetch_replay_ready(event_id: str) -> dict | None:
    firestore_record = await _fetch_firestore_document('ppv_replays', event_id)
    if firestore_record is not None:
        return firestore_record

    if _db_persistence_enabled():
        try:
            pool = await get_db_pool()
            async with pool.acquire() as conn:
                row = await conn.fetchrow(
                    """
                    SELECT event_id, replay_url, expires_in_hours, status
                    FROM ppv_replays
                    WHERE event_id = $1
                    """,
                    event_id,
                )
            if row:
                return dict(row)
        except Exception as exc:
            logger.warning('PPV replay lookup failed, using fallback store: %s', exc)

    return _replay_store.get(event_id)


async def fetch_settlement(event_id: str) -> dict | None:
    firestore_record = await _fetch_firestore_document('ppv_settlements', event_id)
    if firestore_record is not None:
        return firestore_record

    if _db_persistence_enabled():
        try:
            pool = await get_db_pool()
            async with pool.acquire() as conn:
                row = await conn.fetchrow(
                    """
                    SELECT event_id, gross_cents, fees_cents, net_cents, fee_bps
                    FROM ppv_settlements
                    WHERE event_id = $1
                    """,
                    event_id,
                )
            if row:
                return dict(row)
        except Exception as exc:
            logger.warning('PPV settlement lookup failed, using fallback store: %s', exc)

    return _settlement_store.get(event_id)
