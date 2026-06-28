from fastapi import APIRouter, HTTPException
from ..dataconnect_client import dc

router = APIRouter()

@router.get("/{weight_class}")
async def get_weight_class_rankings(weight_class: str):
    """
    Fetch the current rankings for a specific weight class.
    """
    result = await dc.get_rankings_by_weight_class.execute(weightClass=weight_class)
    
    if not result.data.rankings:
        raise HTTPException(
            status_code=404, 
            detail=f"No rankings found for weight class: {weight_class}"
        )
        
    return {"status": "success", "data": result.data.rankings}
