from fastapi import APIRouter, HTTPException, status
from ..dataconnect_client import dc
from .schemas import UserProfileSchema

router = APIRouter()

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
