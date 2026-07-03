from fastapi import APIRouter, HTTPException, status
from ..dataconnect_client import dc
from .schemas import PaymentResponse, PayoutHistoryResponse

router = APIRouter()

@router.post("/checkout/{event_id}", response_model=PaymentResponse)
async def create_fight_checkout(event_id: str, user_id: str):
    """
    Initiates a decentralized payment for a specific fight event.
    Wired to the Stripe/Mux pipeline.
    """
    try:
        event_check = await dc.get_event.execute(id=event_id)
        if not event_check.data.event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cannot initiate checkout for non-existent event"
            )

        # Log the intent in our mesh
        result = await dc.create_payment.execute(
            eventId=event_id, 
            userId=user_id,
            status="pending",
            amount=event_check.data.event.price or 0
        )
        return PaymentResponse(status="success", payment_id=result.data.payment.id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/payouts/{fighter_id}", response_model=PayoutHistoryResponse)
async def get_fighter_payout_history(fighter_id: str):
    """
    Transparent payout history for athletes.
    """
    try:
        result = await dc.list_payouts_for_fighter.execute(fighterId=fighter_id)
        payouts_list = []
        for p in result.data.payouts:
            payouts_list.append({
                "id": p.id,
                "amount": int(p.amount),
                "status": p.status,
                "processedAt": p.processedAt
            })
        return PayoutHistoryResponse(status="success", data=payouts_list)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
