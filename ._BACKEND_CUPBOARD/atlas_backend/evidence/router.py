from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

try:
    from .locker import fetch_evidence_record, store_evidence_record
except ImportError:
    from locker import fetch_evidence_record, store_evidence_record


router = APIRouter(tags=['evidence'])


def _require_non_empty(value: str, field_name: str) -> str:
    cleaned = value.strip()
    if not cleaned:
        raise HTTPException(status_code=400, detail=f'{field_name} must not be blank')
    return cleaned


class EvidenceStoreRequest(BaseModel):
    item_id: str = Field(min_length=1, max_length=128)
    source: str = Field(min_length=1, max_length=64)
    content_type: str = Field(min_length=3, max_length=128)
    notes: str | None = Field(default=None, max_length=2000)


@router.post('/evidence/store')
async def store(req: EvidenceStoreRequest):
    item_id = _require_non_empty(req.item_id, 'item_id')
    source = _require_non_empty(req.source, 'source').lower()
    content_type = _require_non_empty(req.content_type, 'content_type').lower()
    if '/' not in content_type:
        raise HTTPException(status_code=400, detail='content_type must be a valid media type')

    notes = req.notes.strip() if req.notes else None
    return await store_evidence_record(item_id, source, content_type, notes)


@router.get('/evidence/{item_id}')
async def get_evidence(item_id: str):
    record = await fetch_evidence_record(_require_non_empty(item_id, 'item_id'))
    if record is None:
        raise HTTPException(status_code=404, detail='Evidence record not found')
    return record
