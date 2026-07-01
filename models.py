from pydantic import BaseModel
from typing import Dict, Any
from datetime import datetime

class EvidenceRequest(BaseModel):
    event_id: str
    evidence_type: str
    payload: Dict[str, Any]

class EvidenceResponse(BaseModel):
    item_id: str
    status: str
    hash_signature: str
    timestamp: datetime