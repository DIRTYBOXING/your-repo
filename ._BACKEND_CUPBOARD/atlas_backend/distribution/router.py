from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

try:
    from ..event_bus import publish_event
    from .engine import create_caption_record, create_drop_plan, fetch_caption_record, fetch_drop_plan
except ImportError:
    from event_bus import publish_event
    from distribution.engine import create_caption_record, create_drop_plan, fetch_caption_record, fetch_drop_plan


router = APIRouter(tags=['distribution'])

SUPPORTED_CHANNELS = {
    'facebook',
    'instagram',
    'linkedin',
    'rednote',
    'threads',
    'tiktok',
    'whatsapp',
    'x',
    'youtube',
    'bluesky',
}


def _require_non_empty(value: str, field_name: str) -> str:
    cleaned = value.strip()
    if not cleaned:
        raise HTTPException(status_code=400, detail=f'{field_name} must not be blank')
    return cleaned


class CaptionRequest(BaseModel):
    text: str = Field(min_length=1, max_length=2000)


class DropRequest(BaseModel):
    channel: str = Field(min_length=1, max_length=32)
    text: str = Field(min_length=1, max_length=2000)


@router.post('/distribution/caption')
async def caption(req: CaptionRequest):
    text = _require_non_empty(req.text, 'text')
    return await create_caption_record(text)


@router.get('/distribution/captions/{caption_id}')
async def get_caption(caption_id: str):
    record = await fetch_caption_record(_require_non_empty(caption_id, 'caption_id'))
    if record is None:
        raise HTTPException(status_code=404, detail='Caption not found')
    return record


@router.post('/distribution/drop')
async def drop(req: DropRequest):
    channel = _require_non_empty(req.channel, 'channel').lower()
    text = _require_non_empty(req.text, 'text')
    if channel not in SUPPORTED_CHANNELS:
        raise HTTPException(status_code=400, detail=f'Unsupported distribution channel: {channel}')

    plan = await create_drop_plan(channel, text)
    await publish_event(
        'distribution.drop.scheduled',
        source='distribution',
        stream='distribution',
        subject=channel,
        payload=plan,
    )
    return plan


@router.get('/distribution/drops/{drop_id}')
async def get_drop(drop_id: str):
    record = await fetch_drop_plan(_require_non_empty(drop_id, 'drop_id'))
    if record is None:
        raise HTTPException(status_code=404, detail='Drop plan not found')
    return record
