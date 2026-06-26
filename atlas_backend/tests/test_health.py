from pathlib import Path
import sys

from fastapi.testclient import TestClient


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from atlas_backend.main import app


def test_health_endpoint_returns_ok_status():
    client = TestClient(app)

    response = client.get('/health')

    assert response.status_code == 200
    payload = response.json()
    assert payload['status'] == 'ok'
    assert isinstance(payload['time'], int)
