from datetime import datetime
from pydantic import BaseModel, Field
from typing import Any, Optional, List

class UserSchema(BaseModel):
    """Schema representing user record fields from DataConnect."""
    id: str
    name: Optional[str] = None
    email: Optional[str] = None
    display_name: Optional[str] = Field(None, alias="displayName")
    avatar_url: Optional[str] = Field(None, alias="avatarUrl")

    class Config:
        populate_by_name = True
        allow_population_by_field_name = True

class UserProfileSchema(BaseModel):
    """Standardized response wrapper for user-related endpoints."""
    status: str
    data: UserSchema

class PaymentResponse(BaseModel):
    """Response model for flight checkout initialization."""
    status: str
    payment_id: str

class PayoutSchema(BaseModel):
    """Schema representing an athlete payout record from the mesh."""
    id: str
    amount: int
    status: str
    processedAt: datetime

class PayoutHistoryResponse(BaseModel):
    """Response model for fighter payout history."""
    status: str
    data: List[PayoutSchema]
