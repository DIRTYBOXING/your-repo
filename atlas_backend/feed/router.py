from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

try:
    from .service import create_feed_item, fetch_feed_item, list_feed_items
except ImportError:
    from feed.service import create_feed_item, fetch_feed_item, list_feed_items


router = APIRouter(tags=['feed'])


def _require_non_empty(value: str, field_name: str) -> str:
    cleaned = value.strip()
    if not cleaned:
        raise HTTPException(status_code=400, detail=f'{field_name} must not be blank')
    return cleaned


class FeedCreateRequest(BaseModel):
    text: str = Field(min_length=1, max_length=2000)
    source: str = Field(default='manual', min_length=1, max_length=48)


@router.post('/feed/create')
async def create(req: FeedCreateRequest):
    text = _require_non_empty(req.text, 'text')
    source = _require_non_empty(req.source, 'source').lower()
    return await create_feed_item(text, source)


@router.get('/feed/{feed_id}')
async def get_feed_item(feed_id: str):
    item = await fetch_feed_item(_require_non_empty(feed_id, 'feed_id'))
    if item is None:
        raise HTTPException(status_code=404, detail='Feed item not found')
    return item


@router.get('/feed')
async def get_feed(limit: int = 20, source: Optional[str] = None):
    safe_limit = max(1, min(limit, 100))
    normalized_source = source.strip().lower() if source else None
    return {'items': await list_feed_items(limit=safe_limit, source=normalized_source)}
