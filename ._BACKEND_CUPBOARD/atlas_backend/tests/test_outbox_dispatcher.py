import asyncio
from datetime import datetime, timezone

import atlas_backend.outbox_dispatcher as outbox_dispatcher


def test_outbox_dispatcher_marks_events_delivered(monkeypatch):
    delivered = []
    retried = []
    dispatched = []
    released = []

    async def fake_claim_pending_events(batch_size=25):
        await asyncio.sleep(0)
        return [
            {
                'id': 1,
                'stream': 'ppv',
                'event_type': 'ppv.purchase.created',
                'source': 'ppv',
                'subject': 'ppv-01',
                'payload': {'ppv_id': 'ppv-01', 'user_id': 'user-1'},
                'metadata': {},
                'occurred_at': datetime.now(timezone.utc),
                'attempts': 0,
            }
        ]

    async def fake_dispatch_outbox_row(row):
        await asyncio.sleep(0)
        dispatched.append(row['id'])

    async def fake_mark_event_delivered(event_id):
        await asyncio.sleep(0)
        delivered.append(event_id)

    async def fake_mark_event_retry(event_id, error_message, delay_seconds=5):
        await asyncio.sleep(0)
        retried.append((event_id, error_message, delay_seconds))

    async def fake_release_stale_processing_events(lock_timeout_seconds=300):
        await asyncio.sleep(0)
        released.append(lock_timeout_seconds)
        return 0

    monkeypatch.setattr(outbox_dispatcher, 'claim_pending_events', fake_claim_pending_events)
    monkeypatch.setattr(outbox_dispatcher, 'dispatch_outbox_row', fake_dispatch_outbox_row)
    monkeypatch.setattr(outbox_dispatcher, 'mark_event_delivered', fake_mark_event_delivered)
    monkeypatch.setattr(outbox_dispatcher, 'mark_event_retry', fake_mark_event_retry)
    monkeypatch.setattr(outbox_dispatcher, 'release_stale_processing_events', fake_release_stale_processing_events)

    processed = asyncio.run(outbox_dispatcher.run_outbox_cycle())

    assert processed == 1
    assert dispatched == [1]
    assert delivered == [1]
    assert retried == []
    assert released == [outbox_dispatcher.LOCK_TIMEOUT_SECONDS]


def test_outbox_dispatcher_marks_events_for_retry(monkeypatch):
    delivered = []
    retried = []
    released = []

    async def fake_claim_pending_events(batch_size=25):
        await asyncio.sleep(0)
        return [
            {
                'id': 2,
                'stream': 'sensor',
                'event_type': 'sensor.alert_status_updated',
                'source': 'sensor',
                'subject': 'alert-1',
                'payload': {'alert_id': 'alert-1'},
                'metadata': {},
                'occurred_at': datetime.now(timezone.utc),
                'attempts': 2,
            }
        ]

    async def fake_dispatch_outbox_row(row):
        raise RuntimeError('boom')

    async def fake_mark_event_delivered(event_id):
        await asyncio.sleep(0)
        delivered.append(event_id)

    async def fake_mark_event_retry(event_id, error_message, delay_seconds=5):
        await asyncio.sleep(0)
        retried.append((event_id, error_message, delay_seconds))

    async def fake_release_stale_processing_events(lock_timeout_seconds=300):
        await asyncio.sleep(0)
        released.append(lock_timeout_seconds)
        return 0

    monkeypatch.setattr(outbox_dispatcher, 'claim_pending_events', fake_claim_pending_events)
    monkeypatch.setattr(outbox_dispatcher, 'dispatch_outbox_row', fake_dispatch_outbox_row)
    monkeypatch.setattr(outbox_dispatcher, 'mark_event_delivered', fake_mark_event_delivered)
    monkeypatch.setattr(outbox_dispatcher, 'mark_event_retry', fake_mark_event_retry)
    monkeypatch.setattr(outbox_dispatcher, 'release_stale_processing_events', fake_release_stale_processing_events)

    processed = asyncio.run(outbox_dispatcher.run_outbox_cycle())

    assert processed == 0
    assert delivered == []
    assert retried == [(2, 'boom', 4)]
    assert released == [outbox_dispatcher.LOCK_TIMEOUT_SECONDS]


def test_outbox_dispatcher_dead_letters_exhausted_events(monkeypatch):
    delivered = []
    retried = []
    dead_lettered = []

    async def fake_claim_pending_events(batch_size=25):
        await asyncio.sleep(0)
        return [
            {
                'id': 3,
                'stream': 'distribution',
                'event_type': 'distribution.drop.scheduled',
                'source': 'distribution',
                'subject': 'instagram',
                'payload': {'channel': 'instagram'},
                'metadata': {},
                'occurred_at': datetime.now(timezone.utc),
                'attempts': outbox_dispatcher.MAX_ATTEMPTS,
            }
        ]

    async def fake_dispatch_outbox_row(row):
        await asyncio.sleep(0)
        raise RuntimeError('permanent failure')

    async def fake_mark_event_delivered(event_id):
        await asyncio.sleep(0)
        delivered.append(event_id)

    async def fake_mark_event_retry(event_id, error_message, delay_seconds=5):
        await asyncio.sleep(0)
        retried.append((event_id, error_message, delay_seconds))

    async def fake_mark_event_dead_letter(event_id, error_message):
        await asyncio.sleep(0)
        dead_lettered.append((event_id, error_message))

    async def fake_release_stale_processing_events(lock_timeout_seconds=300):
        await asyncio.sleep(0)
        return 1

    monkeypatch.setattr(outbox_dispatcher, 'claim_pending_events', fake_claim_pending_events)
    monkeypatch.setattr(outbox_dispatcher, 'dispatch_outbox_row', fake_dispatch_outbox_row)
    monkeypatch.setattr(outbox_dispatcher, 'mark_event_delivered', fake_mark_event_delivered)
    monkeypatch.setattr(outbox_dispatcher, 'mark_event_retry', fake_mark_event_retry)
    monkeypatch.setattr(outbox_dispatcher, 'mark_event_dead_letter', fake_mark_event_dead_letter)
    monkeypatch.setattr(outbox_dispatcher, 'release_stale_processing_events', fake_release_stale_processing_events)

    processed = asyncio.run(outbox_dispatcher.run_outbox_cycle())

    assert processed == 0
    assert delivered == []
    assert retried == []
    assert dead_lettered == [(3, 'permanent failure')]
