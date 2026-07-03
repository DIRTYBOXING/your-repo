from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

try:
    from ..auth.firebase_auth import ensure_user_profile, get_current_user, update_user_profile_fields
except ImportError:
    from auth.firebase_auth import ensure_user_profile, get_current_user, update_user_profile_fields

from ..dataconnect_client import dc
from .schemas import UserProfileSchema

router = APIRouter()


class UserProfileUpdateRequest(BaseModel):
    displayName: str | None = Field(default=None, max_length=128)
    photoUrl: str | None = Field(default=None, max_length=500)
    preferences: dict[str, Any] | None = None


@router.get('/me')
async def get_me(current_user: Annotated[dict[str, Any], Depends(get_current_user)]):
    return await ensure_user_profile(current_user)


@router.put('/me')
async def update_me(
    payload: UserProfileUpdateRequest,
    current_user: Annotated[dict[str, Any], Depends(get_current_user)],
):
    updates = payload.model_dump(exclude_none=True)
    return await update_user_profile_fields(current_user['uid'], updates)

@router.get("/{user_id}", response_model=UserProfileSchema)
async def get_user_profile(user_id: str):
    """
    Fetch the user profile.
    """
    try:
        result = await dc.get_user.execute(id=user_id)
        if not result.data.user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with ID {user_id} not found"
            )
        return UserProfileSchema(status="success", data=result.data.user)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
