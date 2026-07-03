from typing import Annotated, Any

from fastapi import APIRouter, Depends

try:
    from ..auth.firebase_auth import ensure_user_profile, get_current_user
except ImportError:
    from auth.firebase_auth import ensure_user_profile, get_current_user


router = APIRouter()


@router.post('/verify')
async def verify_auth_token(current_user: Annotated[dict[str, Any], Depends(get_current_user)]):
    profile = await ensure_user_profile(current_user)
    return {
        'uid': current_user.get('uid'),
        'email': current_user.get('email'),
        'profile': profile,
    }
