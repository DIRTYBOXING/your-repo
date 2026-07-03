import inspect
import json
import logging
import os
import socket
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Awaitable, Callable

try:
    from .db import get_db_pool
except ImportError:
    from db import get_db_pool


logger = logging.getLogger(__name__)

EventHandler = Callable[['DfcEvent'], Any]


def _parse_execute_count(result: str) -> int:
    try:
        return int(result.rsplit(' ', 1)[-1])
    except (ValueError, IndexError):
        return 0


@dataclass(slots=True)
class DfcEvent:
    event_type: str
    source: str
    payload: dict[str, Any]
    subject: str | None = None
    stream: str = 'core'
    metadata: dict[str, Any] = field(default_factory=dict)
    occurred_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))


class EventBus:
    def __init__(self, outbox_writer: Callable[[DfcEvent], Awaitable[None]] | None = None):
        self._handlers: dict[str, list[EventHandler]] = {}
        self._outbox_writer = outbox_writer

    def subscribe(self, event_type: str, handler: EventHandler) -> None:
        self._handlers.setdefault(event_type, []).append(handler)

    async def publish(self, event: DfcEvent) -> None:
        if self._outbox_writer is not None:
            await self._outbox_writer(event)

        await self.dispatch(event)

    async def dispatch(self, event: DfcEvent) -> None:
        for handler in [*self._handlers.get(event.event_type, []), *self._handlers.get('*', [])]:
            try:
                result = handler(event)
                if inspect.isawaitable(result):
                    await result
            except Exception as exc:
                logger.warning('Event handler failed for %s: %s', event.event_type, exc)


def _coerce_datetime(value: Any) -> datetime:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if isinstance(value, str):
        return datetime.fromisoformat(value.replace('Z', '+00:00'))
    return datetime.now(timezone.utc)


def row_to_event(row: dict[str, Any]) -> DfcEvent:
    payload = row.get('payload', {})
    metadata = row.get('metadata', {})
    if isinstance(payload, str):
        payload = json.loads(payload)
    if isinstance(metadata, str):
        metadata = json.loads(metadata)

    return DfcEvent(
        event_type=row['event_type'],
        source=row['source'],
        subject=row.get('subject'),
        stream=row.get('stream', 'core'),
        payload=payload,
        metadata=metadata,
        occurred_at=_coerce_datetime(row.get('occurred_at')),
    )


async def _write_event_to_outbox(event: DfcEvent) -> None:
    try:
        pool = await get_db_pool()
        async with pool.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO event_outbox (
                    stream,
                    event_type,
                    source,
                    subject,
                    payload,
                    metadata,
                    status,
                    occurred_at,
                    available_at,
                    attempts
                )
                VALUES ($1, $2, $3, $4, $5::jsonb, $6::jsonb, 'pending', $7, NOW(), 0)
                """,
                event.stream,
                event.event_type,
                event.source,
                event.subject,
                json.dumps(event.payload),
                json.dumps(event.metadata),
                event.occurred_at,
            )
    except Exception as exc:
        logger.warning('Event outbox write failed (non-fatal): %s', exc)


_event_bus = EventBus(outbox_writer=_write_event_to_outbox)


def get_event_bus() -> EventBus:
    return _event_bus


def get_worker_id() -> str:
    return os.getenv('DFC_OUTBOX_WORKER_ID') or f'{socket.gethostname()}-dispatcher'


async def claim_pending_events(batch_size: int = 25, worker_id: str | None = None) -> list[dict[str, Any]]:
    claimant = worker_id or get_worker_id()
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            WITH claimed AS (
                SELECT id
                FROM event_outbox
                WHERE status IN ('pending', 'retry')
                  AND available_at <= NOW()
                ORDER BY created_at
                LIMIT $1
                FOR UPDATE SKIP LOCKED
            )
            UPDATE event_outbox AS outbox
            SET status = 'processing',
                attempts = outbox.attempts + 1,
                locked_at = NOW(),
                locked_by = $2
            FROM claimed
            WHERE outbox.id = claimed.id
            RETURNING outbox.id, outbox.stream, outbox.event_type, outbox.source, outbox.subject,
                      outbox.payload, outbox.metadata, outbox.occurred_at, outbox.attempts
            """,
            batch_size,
            claimant,
        )
    return [dict(row) for row in rows]


async def mark_event_delivered(event_id: int) -> None:
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            """
            UPDATE event_outbox
            SET status = 'delivered',
                delivered_at = NOW(),
                locked_at = NULL,
                locked_by = NULL,
                last_error = NULL
            WHERE id = $1
            """,
            event_id,
        )


async def mark_event_retry(event_id: int, error_message: str, delay_seconds: int = 5) -> None:
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            """
            UPDATE event_outbox
            SET status = 'retry',
                available_at = NOW() + make_interval(secs => $2),
                last_error = $3,
                locked_at = NULL,
                locked_by = NULL
            WHERE id = $1
            """,
            event_id,
            delay_seconds,
            error_message[:2000],
        )


async def mark_event_dead_letter(event_id: int, error_message: str) -> None:
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            """
            UPDATE event_outbox
            SET status = 'dead_letter',
                dead_lettered_at = NOW(),
                available_at = NOW(),
                last_error = $2,
                locked_at = NULL,
                locked_by = NULL
            WHERE id = $1
            """,
            event_id,
            error_message[:2000],
        )


async def release_stale_processing_events(lock_timeout_seconds: int = 300) -> int:
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        result = await conn.execute(
            """
            UPDATE event_outbox
            SET status = 'retry',
                available_at = NOW(),
                last_error = COALESCE(last_error, 'Worker lock expired; event returned to retry queue.'),
                locked_at = NULL,
                locked_by = NULL
            WHERE status = 'processing'
              AND locked_at IS NOT NULL
              AND locked_at <= NOW() - make_interval(secs => $1)
            """,
            lock_timeout_seconds,
        )
    return _parse_execute_count(result)


async def get_outbox_snapshot(lock_timeout_seconds: int = 300) -> dict[str, Any]:
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            SELECT
                COUNT(*) FILTER (WHERE status = 'pending') AS pending_count,
                COUNT(*) FILTER (WHERE status = 'retry') AS retry_count,
                COUNT(*) FILTER (WHERE status = 'processing') AS processing_count,
                COUNT(*) FILTER (WHERE status = 'delivered') AS delivered_count,
                COUNT(*) FILTER (WHERE status = 'dead_letter') AS dead_letter_count,
                COUNT(*) FILTER (
                    WHERE status = 'processing'
                      AND locked_at IS NOT NULL
                      AND locked_at <= NOW() - make_interval(secs => $1)
                ) AS stale_processing_count,
                MIN(created_at) FILTER (WHERE status IN ('pending', 'retry')) AS oldest_ready_created_at
            FROM event_outbox
            """,
            lock_timeout_seconds,
        )

    snapshot = dict(row or {})
    oldest_ready_created_at = snapshot.pop('oldest_ready_created_at', None)
    oldest_ready_age_seconds = 0
    if oldest_ready_created_at is not None:
        oldest_ready_age_seconds = max(
            0,
            int((datetime.now(timezone.utc) - _coerce_datetime(oldest_ready_created_at)).total_seconds()),
        )

    pending_count = int(snapshot.get('pending_count', 0) or 0)
    retry_count = int(snapshot.get('retry_count', 0) or 0)

    return {
        'pending_count': pending_count,
        'retry_count': retry_count,
        'ready_count': pending_count + retry_count,
        'processing_count': int(snapshot.get('processing_count', 0) or 0),
        'delivered_count': int(snapshot.get('delivered_count', 0) or 0),
        'dead_letter_count': int(snapshot.get('dead_letter_count', 0) or 0),
        'stale_processing_count': int(snapshot.get('stale_processing_count', 0) or 0),
        'oldest_ready_age_seconds': oldest_ready_age_seconds,
    }


async def dispatch_outbox_row(row: dict[str, Any]) -> DfcEvent:
    event = row_to_event(row)
    await _event_bus.dispatch(event)
    return event


async def publish_event(
    event_type: str,
    *,
    source: str,
    payload: dict[str, Any],
    subject: str | None = None,
    stream: str = 'core',
    metadata: dict[str, Any] | None = None,
) -> DfcEvent:
    event = DfcEvent(
        event_type=event_type,
        source=source,
        subject=subject,
        payload=payload,
        stream=stream,
        metadata=metadata or {},
    )
    await _write_event_to_outbox(event)
    return event
