import asyncio
import logging
import os

try:
    from .event_bus import (
        claim_pending_events,
        dispatch_outbox_row,
        mark_event_dead_letter,
        mark_event_delivered,
        mark_event_retry,
        release_stale_processing_events,
    )
    from .subscriptions import register_default_subscriptions
except ImportError:
    from event_bus import (
        claim_pending_events,
        dispatch_outbox_row,
        mark_event_dead_letter,
        mark_event_delivered,
        mark_event_retry,
        release_stale_processing_events,
    )
    from subscriptions import register_default_subscriptions


logger = logging.getLogger(__name__)

POLL_INTERVAL_SECONDS = float(os.getenv('DFC_OUTBOX_POLL_INTERVAL', '1.0'))
BATCH_SIZE = int(os.getenv('DFC_OUTBOX_BATCH_SIZE', '25'))
MAX_RETRY_DELAY_SECONDS = int(os.getenv('DFC_OUTBOX_MAX_RETRY_DELAY', '60'))
MAX_ATTEMPTS = int(os.getenv('DFC_OUTBOX_MAX_ATTEMPTS', '5'))
LOCK_TIMEOUT_SECONDS = int(os.getenv('DFC_OUTBOX_LOCK_TIMEOUT', '300'))


async def run_outbox_cycle(batch_size: int = BATCH_SIZE) -> int:
    released = await release_stale_processing_events(lock_timeout_seconds=LOCK_TIMEOUT_SECONDS)
    if released:
        logger.warning('Released %s stale outbox events back to retry', released)

    rows = await claim_pending_events(batch_size=batch_size)
    processed = 0
    retried = 0
    dead_lettered = 0

    for row in rows:
        try:
            await dispatch_outbox_row(row)
            await mark_event_delivered(row['id'])
            processed += 1
        except Exception as exc:
            attempts = max(1, int(row.get('attempts', 1) or 1))
            if attempts >= MAX_ATTEMPTS:
                await mark_event_dead_letter(row['id'], str(exc))
                dead_lettered += 1
                logger.error('Outbox event %s moved to dead letter after %s attempts: %s', row['id'], attempts, exc)
                continue

            delay_seconds = min(2 ** attempts, MAX_RETRY_DELAY_SECONDS)
            await mark_event_retry(row['id'], str(exc), delay_seconds)
            retried += 1
            logger.warning('Outbox dispatch failed for %s: %s', row['id'], exc)

    if processed or retried or dead_lettered or released:
        logger.info(
            'Outbox cycle summary processed=%s retried=%s dead_lettered=%s released=%s',
            processed,
            retried,
            dead_lettered,
            released,
        )

    return processed


async def run_outbox_worker(poll_interval_seconds: float = POLL_INTERVAL_SECONDS) -> None:
    register_default_subscriptions()
    logger.info('Outbox dispatcher started')

    while True:
        processed = await run_outbox_cycle()
        if processed == 0:
            await asyncio.sleep(poll_interval_seconds)


def main() -> None:
    logging.basicConfig(level=logging.INFO)
    asyncio.run(run_outbox_worker())


if __name__ == '__main__':
    main()
