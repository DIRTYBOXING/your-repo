from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

try:
    from .events import emit_access_granted, emit_purchase_created, emit_replay_ready, emit_settlement_generated
    from .service import (
        fetch_access_grant,
        fetch_purchase_record,
        fetch_replay_ready,
        fetch_settlement,
        record_purchase,
        record_replay_ready,
        record_settlement,
    )
except ImportError:
    from ppv.events import emit_access_granted, emit_purchase_created, emit_replay_ready, emit_settlement_generated
    from ppv.service import (
        fetch_access_grant,
        fetch_purchase_record,
        fetch_replay_ready,
        fetch_settlement,
        record_purchase,
        record_replay_ready,
        record_settlement,
    )


router = APIRouter(tags=['ppv'])


def _require_non_empty(value: str, field_name: str) -> str:
    cleaned = value.strip()
    if not cleaned:
        raise HTTPException(status_code=400, detail=f'{field_name} must not be blank')
    return cleaned


class PurchaseRequest(BaseModel):
    ppv_id: str = Field(min_length=1, max_length=128)
    user_id: str = Field(min_length=1, max_length=128)
    price_cents: int = Field(gt=0, le=5000000)


class ReplayReadyRequest(BaseModel):
    event_id: str = Field(min_length=1, max_length=128)
    replay_url: str = Field(min_length=10, max_length=2048)
    expires_in_hours: int = Field(default=72, ge=1, le=720)


class SettlementRequest(BaseModel):
    gross_cents: int = Field(gt=0, le=500000000)
    fee_bps: int = Field(default=1000, ge=0, le=5000)


@router.post('/ppv/purchase')
async def purchase(req: PurchaseRequest):
    ppv_id = _require_non_empty(req.ppv_id, 'ppv_id')
    user_id = _require_non_empty(req.user_id, 'user_id')
    purchase_record, access = await record_purchase(ppv_id, user_id, req.price_cents)
    await emit_purchase_created(ppv_id, user_id, req.price_cents)
    await emit_access_granted(ppv_id, user_id)
    return {'purchase': purchase_record, 'access': access}


@router.get('/ppv/purchases/{purchase_id}')
async def get_purchase(purchase_id: str):
    record = await fetch_purchase_record(_require_non_empty(purchase_id, 'purchase_id'))
    if record is None:
        raise HTTPException(status_code=404, detail='Purchase not found')
    return record


@router.get('/ppv/access/{ppv_id}/{user_id}')
async def get_access(ppv_id: str, user_id: str):
    access = await fetch_access_grant(_require_non_empty(ppv_id, 'ppv_id'), _require_non_empty(user_id, 'user_id'))
    if access is None:
        raise HTTPException(status_code=404, detail='Access grant not found')
    return access


@router.post('/ppv/replay/ready')
async def replay_ready(req: ReplayReadyRequest):
    event_id = _require_non_empty(req.event_id, 'event_id')
    replay_url = _require_non_empty(req.replay_url, 'replay_url')
    if not replay_url.startswith(('http://', 'https://')):
        raise HTTPException(status_code=400, detail='replay_url must be an absolute http(s) URL')

    replay = await record_replay_ready(event_id, replay_url, req.expires_in_hours)
    await emit_replay_ready(event_id, replay_url)
    return replay


@router.get('/ppv/replays/{event_id}')
async def get_replay(event_id: str):
    replay = await fetch_replay_ready(_require_non_empty(event_id, 'event_id'))
    if replay is None:
        raise HTTPException(status_code=404, detail='Replay not found')
    return replay


@router.post('/ppv/settlement/{event_id}')
async def settlement(event_id: str, req: SettlementRequest):
    event_id = _require_non_empty(event_id, 'event_id')
    snapshot = await record_settlement(event_id, req.gross_cents, req.fee_bps)
    await emit_settlement_generated(event_id, snapshot['gross_cents'], snapshot['net_cents'])
    return snapshot


@router.get('/ppv/settlements/{event_id}')
async def get_settlement_snapshot(event_id: str):
    snapshot = await fetch_settlement(_require_non_empty(event_id, 'event_id'))
    if snapshot is None:
        raise HTTPException(status_code=404, detail='Settlement not found')
    return snapshot
