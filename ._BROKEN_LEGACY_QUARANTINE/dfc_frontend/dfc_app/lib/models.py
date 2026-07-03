from pydantic import BaseModel
from typing import Optional, List

class EventBase(BaseModel):
    name: str
    venue: str
    date: str          # ISO string
    ppv_price: float
    promoter_id: Optional[str] = None
    poster_url: Optional[str] = None
    status: str = "draft"

class EventCreate(EventBase):
    pass

class EventUpdate(BaseModel):
    name: Optional[str] = None
    venue: Optional[str] = None
    date: Optional[str] = None
    ppv_price: Optional[float] = None
    promoter_id: Optional[str] = None
    poster_url: Optional[str] = None
    status: Optional[str] = None

class FightCreate(BaseModel):
    red_corner: str
    blue_corner: str
    weight_class: str
    rounds: int
    order: int