from fastapi import APIRouter, HTTPException, status
from ..dataconnect_client import dc

router = APIRouter()

@router.get("/")
async def list_fighters():
    """List all fighters."""
    try:
        result = await dc.list_fighters.execute()
        return {"status": "success", "data": result.data.fighters}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
