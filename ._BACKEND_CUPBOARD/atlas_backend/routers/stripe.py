import logging
import os
from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel


try:
    from ..event_bus import publish_event
except ImportError:
    from event_bus import publish_event


logger = logging.getLogger(__name__)

router = APIRouter(tags=['stripe'])

_RESPONSE_DESCRIPTIONS = {
    400: 'Bad request',
    502: 'Upstream service error',
    503: 'Service unavailable',
}


def documented_responses(*codes: int) -> dict[int | str, dict[str, str]]:
    responses: dict[int | str, dict[str, str]] = {}
    for code in codes:
        responses[code] = {'description': _RESPONSE_DESCRIPTIONS[code]}
    return responses


class StripePayoutRequest(BaseModel):
    creator_stripe_account_id: str
    amount_usd_cents: int
    alert_id: Optional[str] = None
    impact_score: Optional[float] = None
    description: str = 'DFC creator payout'


@router.post('/stripe/payout', responses=documented_responses(400, 502, 503))
async def stripe_creator_payout(req: StripePayoutRequest):
    stripe_key = os.getenv('STRIPE_SECRET_KEY')
    if not stripe_key:
        raise HTTPException(status_code=503, detail='Stripe not configured (STRIPE_SECRET_KEY missing)')
    if req.amount_usd_cents < 100:
        raise HTTPException(status_code=400, detail='Minimum payout is $1.00 (100 cents)')
    if not req.creator_stripe_account_id.startswith('acct_'):
        raise HTTPException(status_code=400, detail='Invalid Stripe connected account ID')
    if req.impact_score is not None and req.impact_score < 0.0:
        raise HTTPException(status_code=400, detail='impact_score must be >= 0')

    try:
        import stripe as _stripe

        _stripe.api_key = stripe_key
        transfer = _stripe.Transfer.create(
            amount=req.amount_usd_cents,
            currency='usd',
            destination=req.creator_stripe_account_id,
            description=req.description,
            metadata={
                'alert_id': req.alert_id or '',
                'impact_score': str(req.impact_score or ''),
                'platform': 'DataFightCentral',
            },
        )
    except Exception as exc:
        logger.exception('Stripe payout error: %s', exc)
        raise HTTPException(status_code=502, detail=f'Stripe error: {exc}') from exc

    db_url = os.getenv('DATABASE_URL')
    if db_url and req.alert_id:
        try:
            import asyncpg

            conn = await asyncpg.connect(db_url)
            await conn.execute(
                """INSERT INTO audit_log (alert_id, action, actor, ts)
                   VALUES ($1, $2, 'stripe_payout', NOW())""",
                req.alert_id,
                f'payout:{transfer.id}:usd:{req.amount_usd_cents}',
            )
            await conn.close()
        except Exception as exc:
            logger.warning('Payout audit log failed (non-fatal): %s', exc)

    await publish_event(
        'payments.stripe_payout_sent',
        source='stripe',
        subject=transfer.id,
        stream='payments',
        payload={
            'transfer_id': transfer.id,
            'destination': req.creator_stripe_account_id,
            'amount_usd_cents': req.amount_usd_cents,
            'alert_id': req.alert_id,
            'impact_score': req.impact_score,
        },
    )

    return {
        'transfer_id': transfer.id,
        'amount_usd': req.amount_usd_cents / 100,
        'destination': req.creator_stripe_account_id,
        'status': getattr(transfer, 'status', 'pending'),
    }
