from fastapi import APIRouter, HTTPException, status
from ..dataconnect_client import dc
from ..services.discovery import DiscoveryService

router = APIRouter()
discovery_service = DiscoveryService()

@router.get("/")
async def list_gyms():
    """List all gyms."""
    try:
        result = await dc.list_gyms.execute()
        return {"status": "success", "data": result.data.gyms}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/search")
async def search_gyms(city: str = None, style: str = None):
    """Search and filter gyms dynamically via DiscoveryService."""
    try:
        gyms = await discovery_service.search(city=city, style=style)
        return {"status": "success", "data": gyms}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/{gym_id}")
async def get_gym(gym_id: str):
    """Get detailed gym information by ID."""
    try:
        result = await dc.get_gym.execute(id=gym_id)
        if not result.data.gym:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Gym with ID {gym_id} not found"
            )
        return {"status": "success", "data": result.data.gym}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
