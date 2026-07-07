import asyncio
from datetime import datetime, timezone
from typing import Annotated, Any

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

try:
    from ..firebase_support import ensure_firebase_app, get_firestore_client
except ImportError:
    from firebase_support import ensure_firebase_app, get_firestore_client

try:
    from firebase_admin import auth as firebase_auth
except Exception:  # pragma: no cover - runtime dependency guard
    firebase_auth = None


_bearer = HTTPBearer(auto_error=False)


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


async def _get_user_doc(uid: str) -> dict[str, Any] | None:
    client = get_firestore_client()
    if client is None:
        return None
    snapshot = await asyncio.to_thread(client.collection('users').document(uid).get)
    if not snapshot.exists:
        return None
    payload = snapshot.to_dict() or {}
    payload.setdefault('id', uid)
    return payload


async def _save_user_doc(uid: str, payload: dict[str, Any]) -> dict[str, Any]:
    client = get_firestore_client()
    if client is None:
        return payload
    await asyncio.to_thread(client.collection('users').document(uid).set, payload, True)
    return payload


def _default_profile(decoded: dict[str, Any]) -> dict[str, Any]:
    now = _utc_now()
    return {
        'id': decoded['uid'],
        'displayName': decoded.get('name') or '',
        'email': decoded.get('email') or '',
        'photoUrl': decoded.get('picture') or '',
        'roles': ['user'],
        'preferences': {'region': None, 'tags': [], 'feed_settings': {}},
        'created_at': now,
        'updated_at': now,
    }


def _normalize_roles(roles: Any) -> list[str]:
    if not isinstance(roles, list):
        return ['user']
    cleaned = [str(role).strip().lower() for role in roles if str(role).strip()]
    return cleaned or ['user']


async def ensure_user_profile(decoded: dict[str, Any]) -> dict[str, Any]:
    uid = decoded['uid']
    existing = await _get_user_doc(uid)
    if existing is None:
        profile = _default_profile(decoded)
        return await _save_user_doc(uid, profile)

    existing['id'] = uid
    existing['displayName'] = existing.get('displayName') or decoded.get('name') or ''
    existing['email'] = existing.get('email') or decoded.get('email') or ''
    existing['photoUrl'] = existing.get('photoUrl') or decoded.get('picture') or ''
    existing['roles'] = _normalize_roles(existing.get('roles'))
    if not isinstance(existing.get('preferences'), dict):
        existing['preferences'] = {'region': None, 'tags': [], 'feed_settings': {}}
    existing['updated_at'] = _utc_now()
    return await _save_user_doc(uid, existing)


async def update_user_profile_fields(uid: str, updates: dict[str, Any]) -> dict[str, Any]:
    existing = await _get_user_doc(uid)
    if existing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Profile not found')

    allowed_keys = {'displayName', 'photoUrl', 'preferences'}
    merged = dict(existing)
    for key, value in updates.items():
        if key in allowed_keys:
            merged[key] = value
    merged['updated_at'] = _utc_now()
    return await _save_user_doc(uid, merged)


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> dict[str, Any]:
    if credentials is None or not credentials.credentials:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='Missing bearer token')
    if firebase_auth is None:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail='Auth service unavailable')

    token = credentials.credentials
    try:
        ensure_firebase_app()
        decoded = await asyncio.to_thread(firebase_auth.verify_id_token, token)
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='Invalid auth token') from exc

    uid = decoded.get('uid')
    if not uid:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='Invalid auth token')
    return decoded


def require_any_role(*roles: str):
    required = {role.strip().lower() for role in roles if role.strip()}

    async def _dependency(current_user: dict[str, Any] = Depends(get_current_user)) -> dict[str, Any]:
        profile = await ensure_user_profile(current_user)
        assigned = set(_normalize_roles(profile.get('roles')))
        if required and assigned.isdisjoint(required):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='Forbidden')
        return profile

    return _dependency
