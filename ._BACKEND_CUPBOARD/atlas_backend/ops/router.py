from fastapi import APIRouter, HTTPException

try:
    from ..event_bus import get_outbox_snapshot
    from ..outbox_dispatcher import (
        BATCH_SIZE,
        LOCK_TIMEOUT_SECONDS,
        MAX_ATTEMPTS,
        MAX_RETRY_DELAY_SECONDS,
        POLL_INTERVAL_SECONDS,
    )
except ImportError:
    from event_bus import get_outbox_snapshot
    from outbox_dispatcher import (
        BATCH_SIZE,
        LOCK_TIMEOUT_SECONDS,
        MAX_ATTEMPTS,
        MAX_RETRY_DELAY_SECONDS,
        POLL_INTERVAL_SECONDS,
    )


router = APIRouter(tags=['ops'])


@router.get('/ops/runtime')
async def runtime_status():
    return {
        'status': 'ok',
        'worker': {
            'batch_size': BATCH_SIZE,
            'poll_interval_seconds': POLL_INTERVAL_SECONDS,
            'max_retry_delay_seconds': MAX_RETRY_DELAY_SECONDS,
            'max_attempts': MAX_ATTEMPTS,
            'lock_timeout_seconds': LOCK_TIMEOUT_SECONDS,
        },
    }


@router.get('/ops/outbox')
async def outbox_status():
    try:
        snapshot = await get_outbox_snapshot(lock_timeout_seconds=LOCK_TIMEOUT_SECONDS)
    except Exception as exc:
        raise HTTPException(status_code=503, detail='Outbox status unavailable') from exc

    return {
        'outbox': snapshot,
        'worker': {
            'batch_size': BATCH_SIZE,
            'poll_interval_seconds': POLL_INTERVAL_SECONDS,
            'max_retry_delay_seconds': MAX_RETRY_DELAY_SECONDS,
            'max_attempts': MAX_ATTEMPTS,
            'lock_timeout_seconds': LOCK_TIMEOUT_SECONDS,
        },
    }
