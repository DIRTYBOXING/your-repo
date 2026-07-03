import asyncio
from pathlib import Path
import sys

from fastapi.testclient import TestClient

import atlas_backend.routers.tribe as tribe_router


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from atlas_backend.main import app


def make_test_client():
    return TestClient(app)


async def fake_publish_event(*args, **kwargs):
    await asyncio.sleep(0)
    return None


def test_tribe_health_returns_expected_shape():
    tribe_router.publish_event = fake_publish_event
    client = make_test_client()

    response = client.get('/tribe/v2/health')

    assert response.status_code == 200
    payload = response.json()
    assert payload['service'] == 'tribe_v2_brain_encoder'
    assert payload['status'] == 'operational'
    assert payload['regions_count'] == 12
    assert 'fight_clip' in payload['content_types']


def test_tribe_predict_returns_deterministic_payload(monkeypatch):
    monkeypatch.setattr(tribe_router, 'get_firestore_client', lambda: None)
    monkeypatch.setattr(tribe_router, 'publish_event', fake_publish_event)

    client = make_test_client()
    request_body = {
        'content_type': 'highlight',
        'modality': 'trimodal',
        'text': 'Flying knee knockout highlight',
        'fighter_id': 'fighter_123',
    }

    first_response = client.post('/tribe/v2/predict', json=request_body)
    second_response = client.post('/tribe/v2/predict', json=request_body)

    assert first_response.status_code == 200
    assert second_response.status_code == 200
    assert first_response.json() == second_response.json()
    assert first_response.json()['model_version'] == 'tribe_v2_local_0.1'
    assert len(first_response.json()['regions']) == 12


def test_tribe_batch_sorts_by_feed_priority_and_limits_batch_size(monkeypatch):
    monkeypatch.setattr(tribe_router, 'get_firestore_client', lambda: None)
    monkeypatch.setattr(tribe_router, 'publish_event', fake_publish_event)

    client = make_test_client()
    response = client.post(
        '/tribe/v2/batch',
        json={
            'items': [
                {'content_type': 'promo', 'text': 'Ticket drop now live'},
                {'content_type': 'fight_clip', 'text': 'Wild exchange in the pocket'},
                {'content_type': 'corner_audio', 'text': 'Listen to the coach call the finish'},
            ],
        },
    )

    assert response.status_code == 200
    payload = response.json()
    priorities = [item['feed_priority'] for item in payload['predictions']]
    assert priorities == sorted(priorities, reverse=True)

    too_many_items = [{'content_type': 'fight_clip', 'text': f'clip {index}'} for index in range(101)]
    too_many_response = client.post('/tribe/v2/batch', json={'items': too_many_items})
    assert too_many_response.status_code == 400
    assert too_many_response.json()['detail'] == 'Batch limited to 100 items'
