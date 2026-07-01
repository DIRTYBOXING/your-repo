import asyncio
from pathlib import Path
import sys

from fastapi.testclient import TestClient

import atlas_backend.routers.chukya_sensor_fusion as sensor_fusion_router


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from atlas_backend.main import app


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
    def __init__(self, *, rows=None):
        self.rows = rows or []
        self.fetch_calls = []
        self.execute_calls = []

    async def fetch(self, query, *args):
        await asyncio.sleep(0)
        self.fetch_calls.append((query, args))
        return self.rows

    async def execute(self, query, *args):
        await asyncio.sleep(0)
        self.execute_calls.append((query, args))
        return 'OK'


def make_test_client():
    return TestClient(app)


async def fake_publish_event(*args, **kwargs):
    await asyncio.sleep(0)
    return None


def test_sensor_fusion_alerts_use_shared_pool(monkeypatch):
    conn = FakeConn(rows=[{'id': 'alert_1', 'level': 'Verify'}])
    pool = FakePool(conn)

    async def fake_get_db_pool():
        await asyncio.sleep(0)
        return pool

    monkeypatch.setattr(sensor_fusion_router, 'get_db_pool', fake_get_db_pool)
    monkeypatch.setattr(sensor_fusion_router, 'publish_event', fake_publish_event)

    client = make_test_client()
    response = client.get('/sensor-fusion/alerts', params={'level': 'Verify', 'limit': 5})

    assert response.status_code == 200
    assert response.json() == [{'id': 'alert_1', 'level': 'Verify'}]
    assert len(conn.fetch_calls) == 1
    assert 'WHERE level=$1' in conn.fetch_calls[0][0]
    assert conn.fetch_calls[0][1] == ('Verify', 5)


def test_legacy_blackbird_alerts_alias_still_works(monkeypatch):
    conn = FakeConn(rows=[{'id': 'alert_legacy', 'level': 'Action'}])
    pool = FakePool(conn)

    async def fake_get_db_pool():
        await asyncio.sleep(0)
        return pool

    monkeypatch.setattr(sensor_fusion_router, 'get_db_pool', fake_get_db_pool)
    monkeypatch.setattr(sensor_fusion_router, 'publish_event', fake_publish_event)

    client = make_test_client()
    response = client.get('/blackbird/alerts', params={'limit': 1})

    assert response.status_code == 200
    assert response.json() == [{'id': 'alert_legacy', 'level': 'Action'}]
    assert len(conn.fetch_calls) == 1
    assert 'ORDER BY ts DESC LIMIT $1' in conn.fetch_calls[0][0]
    assert conn.fetch_calls[0][1] == (1,)


def test_sensor_fusion_patch_alert_updates_status_and_audit(monkeypatch):
    conn = FakeConn()
    pool = FakePool(conn)

    async def fake_get_db_pool():
        await asyncio.sleep(0)
        return pool

    monkeypatch.setattr(sensor_fusion_router, 'get_db_pool', fake_get_db_pool)
    monkeypatch.setattr(sensor_fusion_router, 'publish_event', fake_publish_event)

    client = make_test_client()
    response = client.post('/sensor-fusion/alerts/alert_1/resolved')

    assert response.status_code == 200
    assert response.json() == {'alert_id': 'alert_1', 'status': 'Resolved'}
    assert len(conn.execute_calls) == 2
    assert conn.execute_calls[0][1] == ('Resolved', 'alert_1')
    assert conn.execute_calls[1][1] == ('alert_1', 'resolved')
