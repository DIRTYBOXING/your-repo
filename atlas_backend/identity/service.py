import asyncio
import logging
import os
from typing import Any

try:
    from ..db import get_db_pool
    from ..firebase_support import firestore_timestamp_value, get_firestore_client
    from .models import IdentityProfile, VALID_ROLES
except ImportError:
    from db import get_db_pool
    from firebase_support import firestore_timestamp_value, get_firestore_client
    from identity.models import IdentityProfile, VALID_ROLES


logger = logging.getLogger(__name__)

_identity_store: dict[str, dict] = {}


def _db_persistence_enabled() -> bool:
    return bool(os.getenv('CONTROLROOM_DATABASE_URL') or os.getenv('DATABASE_URL') or os.getenv('DFC_DATABASE_URL'))


async def _save_firestore_profile(profile: IdentityProfile) -> bool:
    client = get_firestore_client()
    if client is None:
        return False

    doc_ref = client.collection('identity_profiles').document(profile.identity_id)
    document = {
        **profile.to_dict(),
        'updated_at': firestore_timestamp_value(),
        'created_at': firestore_timestamp_value(),
    }
    try:
        await asyncio.to_thread(doc_ref.set, document, merge=True)
        return True
    except Exception as exc:
        logger.warning('Identity Firestore persistence failed for %s: %s', profile.identity_id, exc)
        return False


async def _fetch_firestore_profile(identity_id: str) -> IdentityProfile | None:
    client = get_firestore_client()
    if client is None:
        return None

    doc_ref = client.collection('identity_profiles').document(identity_id)
    try:
        snapshot: Any = await asyncio.to_thread(doc_ref.get)
    except Exception as exc:
        logger.warning('Identity Firestore lookup failed for %s: %s', identity_id, exc)
        return None

    if not snapshot.exists:
        return None

    payload = snapshot.to_dict()
    if payload is None:
        return None

    return IdentityProfile(
        identity_id=payload['identity_id'],
        role=payload['role'],
        display_name=payload['display_name'],
    )


def build_identity_profile(identity_id: str, role: str, display_name: str) -> IdentityProfile:
    normalized_role = role.lower()
    if normalized_role not in VALID_ROLES:
        raise ValueError(f'Unsupported identity role: {role}')
    return IdentityProfile(identity_id=identity_id, role=normalized_role, display_name=display_name)


async def save_identity_profile(profile: IdentityProfile) -> IdentityProfile:
    _identity_store[profile.identity_id] = profile.to_dict()
    if await _save_firestore_profile(profile):
        return profile

    if not _db_persistence_enabled():
        return profile

    try:
        pool = await get_db_pool()
        async with pool.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO identity_profiles (identity_id, role, display_name)
                VALUES ($1, $2, $3)
                ON CONFLICT (identity_id) DO UPDATE
                SET role = EXCLUDED.role,
                    display_name = EXCLUDED.display_name,
                    updated_at = NOW()
                """,
                profile.identity_id,
                profile.role,
                profile.display_name,
            )
    except Exception as exc:
        logger.warning('Identity persistence failed, using fallback store: %s', exc)

    return profile


async def fetch_identity_profile(identity_id: str) -> IdentityProfile | None:
    firestore_profile = await _fetch_firestore_profile(identity_id)
    if firestore_profile is not None:
        return firestore_profile

    if _db_persistence_enabled():
        try:
            pool = await get_db_pool()
            async with pool.acquire() as conn:
                row = await conn.fetchrow(
                    """
                    SELECT identity_id, role, display_name
                    FROM identity_profiles
                    WHERE identity_id = $1
                    """,
                    identity_id,
                )
            if row:
                return IdentityProfile(**dict(row))
        except Exception as exc:
            logger.warning('Identity lookup failed, using fallback store: %s', exc)

    cached = _identity_store.get(identity_id)
    if cached:
        return IdentityProfile(**cached)
    return None
