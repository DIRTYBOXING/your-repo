from fastapi import APIRouter, HTTPException, status
from ..dataconnect_client import dc

router = APIRouter()

@router.get("/")
async def list_events():
    """List all upcoming scheduled events."""
    try:
        result = await dc.list_events.execute()
        return {"status": "success", "data": result.data.events}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/{event_id}")
async def get_event(event_id: str):
    """Get detailed event information by ID."""
    try:
        result = await dc.get_event.execute(id=event_id)
        if not result.data.event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Event with ID {event_id} not found"
            )
        return {"status": "success", "data": result.data.event}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
