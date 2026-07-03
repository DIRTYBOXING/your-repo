from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

try:
    from ..event_bus import publish_event
    from .service import build_identity_profile, fetch_identity_profile, save_identity_profile
except ImportError:
    from event_bus import publish_event
    from identity.service import build_identity_profile, fetch_identity_profile, save_identity_profile


router = APIRouter(tags=['identity'])


class RegisterIdentityRequest(BaseModel):
    identity_id: str = Field(min_length=1, max_length=128)
    role: str = Field(min_length=1, max_length=64)
    display_name: str = Field(min_length=1, max_length=128)


@router.post('/identity/register')
async def register_identity(req: RegisterIdentityRequest):
    try:
        profile = build_identity_profile(req.identity_id.strip(), req.role.strip(), req.display_name.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    profile = await save_identity_profile(profile)

    await publish_event(
        'identity.profile.created',
        source='identity',
        stream='identity',
        subject=profile.identity_id,
        payload=profile.to_dict(),
    )
    return profile.to_dict()


@router.get('/identity/{identity_id}')
async def get_identity(identity_id: str):
    profile = await fetch_identity_profile(identity_id.strip())
    if profile is None:
        raise HTTPException(status_code=404, detail='Identity profile not found')
    return profile.to_dict()
