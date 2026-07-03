from fastapi import APIRouter
from ..dataconnect_client import dc

router = APIRouter()

@router.get("/")
async def list_fighting_styles():
    """Fetch all supported fighting styles from the mesh."""
    result = await dc.list_styles.execute()
    return {"status": "success", "data": result.data.styles}
