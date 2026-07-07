from datetime import datetime
from typing import Annotated, Any, Optional

from fastapi import APIRouter, Depends, HTTPException, Response, status
from pydantic import BaseModel, Field

try:
    from ..auth.firebase_auth import require_any_role
    from .service import (
        build_event_document,
        build_promotion_document,
        create_event,
        create_promotion,
        delete_event,
        delete_promotion,
        fetch_event,
        fetch_promotion,
        update_promotion,
        utc_now,
    )
except ImportError:
    from auth.firebase_auth import require_any_role
    from promotions.service import (
        build_event_document,
        build_promotion_document,
        create_event,
        create_promotion,
        delete_event,
        delete_promotion,
        fetch_event,
        fetch_promotion,
        update_promotion,
        utc_now,
    )


router = APIRouter(prefix='/api/v1', tags=['promotions', 'feeds'])

BAD_REQUEST_RESPONSE = {400: {'description': 'Bad request'}}
NOT_FOUND_RESPONSE = {404: {'description': 'Resource not found'}}
PROMOTION_NOT_FOUND = 'Promotion not found'
EVENT_NOT_FOUND = 'Event not found'
OPS_PROFILE = Annotated[dict[str, Any], Depends(require_any_role('ops', 'promoter'))]


class EventIn(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    slug: Optional[str] = Field(default=None, max_length=200)
    start_at: datetime
    end_at: datetime
    venue: dict[str, Any] = Field(default_factory=dict)
    status: str = Field(default='published', min_length=1, max_length=32)


class PromotionIn(BaseModel):
    event_id: str = Field(min_length=1, max_length=128)
    title: Optional[str] = Field(default=None, max_length=200)
    start_at: Optional[datetime] = None
    end_at: Optional[datetime] = None
    priority: int = Field(default=10, ge=0, le=100000)
    channels: list[str] = Field(default_factory=lambda: ['home_feed'])
    targeting: dict[str, Any] = Field(default_factory=dict)
    status: Optional[str] = Field(default='scheduled', max_length=32)


def _normalize_identifier(value: str, field_name: str) -> str:
    cleaned = value.strip()
    if not cleaned:
        raise HTTPException(status_code=400, detail=f'{field_name} must not be blank')
    return cleaned


@router.post('/admin/events', status_code=status.HTTP_201_CREATED, responses=BAD_REQUEST_RESPONSE)
async def create_admin_event(payload: EventIn, _profile: OPS_PROFILE):
    event = build_event_document(
        title=payload.title,
        slug=payload.slug,
        start_at=payload.start_at,
        end_at=payload.end_at,
        venue=payload.venue,
        status=payload.status,
    )
    created = await create_event(event)
    return {'id': created['id'], 'event': created}


@router.delete('/admin/events/{event_id}', status_code=status.HTTP_204_NO_CONTENT, responses={**BAD_REQUEST_RESPONSE, **NOT_FOUND_RESPONSE})
async def delete_admin_event(event_id: str, _profile: OPS_PROFILE):
    normalized_event_id = _normalize_identifier(event_id, 'event_id')
    existing = await fetch_event(normalized_event_id)
    if existing is None:
        raise HTTPException(status_code=404, detail=EVENT_NOT_FOUND)
    await delete_event(normalized_event_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post('/admin/promotions', status_code=status.HTTP_201_CREATED, responses={**BAD_REQUEST_RESPONSE, **NOT_FOUND_RESPONSE})
async def create_admin_promotion(payload: PromotionIn, _profile: OPS_PROFILE):
    event_id = _normalize_identifier(payload.event_id, 'event_id')
    event = await fetch_event(event_id)
    if event is None:
        raise HTTPException(status_code=404, detail=EVENT_NOT_FOUND)

    promotion = build_promotion_document(
        event_id=event_id,
        title=payload.title,
        start_at=payload.start_at,
        end_at=payload.end_at,
        priority=payload.priority,
        channels=payload.channels,
        targeting=payload.targeting,
        status=payload.status,
    )
    created, feed_item = await create_promotion(promotion, event=event)
    return {'id': created['id'], 'promotion': created, 'feed_item': feed_item}


@router.put('/admin/promotions/{promotion_id}', responses={**BAD_REQUEST_RESPONSE, **NOT_FOUND_RESPONSE})
async def update_admin_promotion(
    promotion_id: str,
    payload: PromotionIn,
    _profile: OPS_PROFILE,
):
    normalized_promotion_id = _normalize_identifier(promotion_id, 'promotion_id')
    existing = await fetch_promotion(normalized_promotion_id)
    if existing is None:
        raise HTTPException(status_code=404, detail=PROMOTION_NOT_FOUND)

    update = payload.model_dump(exclude_unset=True)
    if 'event_id' in update:
        update['event_id'] = _normalize_identifier(update['event_id'], 'event_id')
    updated = await update_promotion(normalized_promotion_id, update)
    return {'id': normalized_promotion_id, 'promotion': updated}


@router.post('/admin/promotions/{promotion_id}/activate', responses={**BAD_REQUEST_RESPONSE, **NOT_FOUND_RESPONSE})
async def activate_admin_promotion(
    promotion_id: str,
    _profile: OPS_PROFILE,
):
    normalized_promotion_id = _normalize_identifier(promotion_id, 'promotion_id')
    existing = await fetch_promotion(normalized_promotion_id)
    if existing is None:
        raise HTTPException(status_code=404, detail=PROMOTION_NOT_FOUND)
    now = utc_now()
    updated = await update_promotion(
        normalized_promotion_id,
        {'status': 'active', 'start_at': now, 'updated_at': now},
    )
    return {'id': normalized_promotion_id, 'promotion': updated}


@router.delete('/admin/promotions/{promotion_id}', status_code=status.HTTP_204_NO_CONTENT, responses={**BAD_REQUEST_RESPONSE, **NOT_FOUND_RESPONSE})
async def delete_admin_promotion(
    promotion_id: str,
    _profile: OPS_PROFILE,
):
    normalized_promotion_id = _normalize_identifier(promotion_id, 'promotion_id')
    existing = await fetch_promotion(normalized_promotion_id)
    if existing is None:
        raise HTTPException(status_code=404, detail=PROMOTION_NOT_FOUND)
    await delete_promotion(normalized_promotion_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
