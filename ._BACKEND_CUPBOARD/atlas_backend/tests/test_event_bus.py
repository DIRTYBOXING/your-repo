import asyncio
from datetime import datetime, timezone

import atlas_backend.event_bus as event_bus


class FakeAcquire:
    def __init__(self, conn):
        self.conn = conn

    async def __aenter__(self):
        return self.conn

    async def __aexit__(self, exc_type, exc, tb):
        return False


class FakePool:
    def __init__(self, conn):
        self.conn = conn

    def acquire(self):
        return FakeAcquire(self.conn)


class FakeConn:
    def __init__(self):
        self.execute_calls = []

    async def execute(self, query, *args):
        await asyncio.sleep(0)
        self.execute_calls.append((query, args))
        return 'INSERT 0 1'


async def noop_outbox_writer(event):
    await asyncio.sleep(0)
    return None


def test_event_bus_notifies_subscribers_and_preserves_metadata():
    received = []
    bus = event_bus.EventBus(outbox_writer=noop_outbox_writer)

    async def handler(event):
        await asyncio.sleep(0)
        received.append(event)

    bus.subscribe('sensor.track_ingested', handler)

    event = event_bus.DfcEvent(
        event_type='sensor.track_ingested',
        source='sensor-test',
        subject='track_123',
        stream='sensor',
        payload={'track_id': 'track_123'},
        metadata={'node_id': 'node_a'},
        occurred_at=datetime.now(timezone.utc),
    )

    asyncio.run(bus.publish(event))

    assert len(received) == 1
    assert received[0].event_type == 'sensor.track_ingested'
    assert received[0].subject == 'track_123'
    assert received[0].metadata == {'node_id': 'node_a'}


def test_outbox_writer_inserts_event_record(monkeypatch):
    conn = FakeConn()
    pool = FakePool(conn)

    async def fake_get_db_pool():
        await asyncio.sleep(0)
        return pool

    monkeypatch.setattr(event_bus, 'get_db_pool', fake_get_db_pool)

    event = event_bus.DfcEvent(
        event_type='payments.stripe_payout_sent',
        source='stripe',
        subject='tr_123',
        stream='payments',
        payload={'transfer_id': 'tr_123', 'amount_usd_cents': 2500},
    )

    asyncio.run(event_bus._write_event_to_outbox(event))

    assert len(conn.execute_calls) == 1
    assert 'INSERT INTO event_outbox' in conn.execute_calls[0][0]
    assert conn.execute_calls[0][1][0] == 'payments'
    assert conn.execute_calls[0][1][1] == 'payments.stripe_payout_sent'
    assert conn.execute_calls[0][1][2] == 'stripe'
    assert conn.execute_calls[0][1][3] == 'tr_123'
