import asyncio
import importlib
from pathlib import Path
import sys

from fastapi.testclient import TestClient

ai_core_router_module = importlib.import_module('atlas_backend.ai_core.router')
distribution_router_module = importlib.import_module('atlas_backend.distribution.router')
evidence_locker_module = importlib.import_module('atlas_backend.evidence.locker')
feed_events_module = importlib.import_module('atlas_backend.feed.events')
feed_service_module = importlib.import_module('atlas_backend.feed.service')
feed_router_module = importlib.import_module('atlas_backend.feed.router')
identity_router_module = importlib.import_module('atlas_backend.identity.router')
identity_service_module = importlib.import_module('atlas_backend.identity.service')
moderation_router_module = importlib.import_module('atlas_backend.moderation.router')
ops_router_module = importlib.import_module('atlas_backend.ops.router')
ppv_events = importlib.import_module('atlas_backend.ppv.events')
ppv_service_module = importlib.import_module('atlas_backend.ppv.service')
distribution_events_module = importlib.import_module('atlas_backend.distribution.events')
distribution_engine_module = importlib.import_module('atlas_backend.distribution.engine')


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from atlas_backend.main import app


async def fake_publish_event(*args, **kwargs):
    await asyncio.sleep(0)
    return None


def make_test_client():
    return TestClient(app)


def disable_external_persistence(monkeypatch):
    monkeypatch.setattr(ppv_service_module, 'get_firestore_client', lambda: None)
    monkeypatch.setattr(identity_service_module, 'get_firestore_client', lambda: None)
    monkeypatch.setattr(evidence_locker_module, 'get_firestore_client', lambda: None)
    monkeypatch.setattr(feed_service_module, 'get_firestore_client', lambda: None)
    monkeypatch.setattr(distribution_engine_module, 'get_firestore_client', lambda: None)
    monkeypatch.setattr(evidence_locker_module, 'upload_json_blob', lambda *args, **kwargs: None)


def test_superbeast_ai_and_moderation_routes(monkeypatch):
    disable_external_persistence(monkeypatch)
    monkeypatch.setattr(ai_core_router_module, 'publish_event', fake_publish_event)
    monkeypatch.setattr(moderation_router_module, 'publish_event', fake_publish_event)

    client = make_test_client()
    rewrite_response = client.post('/ai/rewrite', json={'text': 'Crowd is building for tonight', 'style': 'hype'})
    summarize_response = client.post('/ai/summarize', json={'text': 'One two three four five six seven eight nine ten eleven twelve'})
    moderation_response = client.post('/moderation/score', json={'text': 'pirate stream leak threat'})

    assert rewrite_response.status_code == 200
    assert rewrite_response.json()['style'] == 'hype'
    assert rewrite_response.json()['rewritten'].endswith('Tap in now.')

    assert summarize_response.status_code == 200
    assert 'summary' in summarize_response.json()

    assert moderation_response.status_code == 200
    assert moderation_response.json()['action'] in {'review', 'quarantine'}
    assert 'piracy' in moderation_response.json()['flags']


def test_superbeast_ppv_feed_and_distribution_routes(monkeypatch):
    disable_external_persistence(monkeypatch)
    monkeypatch.setattr(ppv_events, 'publish_event', fake_publish_event)
    monkeypatch.setattr(distribution_router_module, 'publish_event', fake_publish_event)

    client = make_test_client()
    purchase_response = client.post('/ppv/purchase', json={'ppv_id': 'ppv-main', 'user_id': 'user-1', 'price_cents': 1499})
    purchase_payload = purchase_response.json()
    purchase_lookup = client.get(f"/ppv/purchases/{purchase_payload['purchase']['purchase_id']}")
    access_lookup = client.get('/ppv/access/ppv-main/user-1')
    replay_response = client.post('/ppv/replay/ready', json={'event_id': 'ppv-main', 'replay_url': 'https://example.com/replay.mp4'})
    replay_lookup = client.get('/ppv/replays/ppv-main')
    feed_response = client.post('/feed/create', json={'text': 'Main event goes live now', 'source': 'ppv'})
    feed_lookup = client.get(f"/feed/{feed_response.json()['feed_id']}")
    feed_list = client.get('/feed?limit=10&source=ppv')
    caption_response = client.post('/distribution/caption', json={'text': 'Replay is live'})
    caption_lookup = client.get(f"/distribution/captions/{caption_response.json()['caption_id']}")
    drop_response = client.post('/distribution/drop', json={'channel': 'instagram', 'text': 'Replay is live'})
    drop_lookup = client.get(f"/distribution/drops/{drop_response.json()['drop_id']}")
    settlement_response = client.post('/ppv/settlement/ppv-main', json={'gross_cents': 250000, 'fee_bps': 1000})
    settlement_lookup = client.get('/ppv/settlements/ppv-main')

    assert purchase_response.status_code == 200
    assert purchase_payload['purchase']['status'] == 'purchased'
    assert purchase_payload['access']['access_status'] == 'granted'
    assert purchase_lookup.status_code == 200
    assert purchase_lookup.json()['purchase_id'] == purchase_payload['purchase']['purchase_id']
    assert access_lookup.status_code == 200
    assert access_lookup.json()['access_status'] == 'granted'

    assert replay_response.status_code == 200
    assert replay_response.json()['status'] == 'ready'
    assert replay_lookup.status_code == 200
    assert replay_lookup.json()['event_id'] == 'ppv-main'

    assert feed_response.status_code == 200
    assert feed_response.json()['source'] == 'ppv'
    assert feed_lookup.status_code == 200
    assert feed_lookup.json()['feed_id'] == feed_response.json()['feed_id']
    assert feed_list.status_code == 200
    assert any(item['feed_id'] == feed_response.json()['feed_id'] for item in feed_list.json()['items'])

    assert caption_response.status_code == 200
    assert caption_lookup.status_code == 200
    assert caption_lookup.json()['caption_id'] == caption_response.json()['caption_id']

    assert drop_response.status_code == 200
    assert drop_response.json()['channel'] == 'instagram'
    assert drop_lookup.status_code == 200
    assert drop_lookup.json()['drop_id'] == drop_response.json()['drop_id']
    assert settlement_response.status_code == 200
    assert settlement_lookup.status_code == 200
    assert settlement_lookup.json()['net_cents'] == settlement_response.json()['net_cents']


def test_superbeast_identity_evidence_and_activation_routes(monkeypatch):
    disable_external_persistence(monkeypatch)
    monkeypatch.setattr(identity_router_module, 'publish_event', fake_publish_event)

    def fake_upload_json_blob(object_path, payload, bucket_name=None):
        return {'storage_bucket': 'dfc-evidence', 'storage_object_path': object_path}

    monkeypatch.setattr(evidence_locker_module, 'upload_json_blob', fake_upload_json_blob)

    client = make_test_client()
    identity_response = client.post(
        '/identity/register',
        json={'identity_id': 'fighter-77', 'role': 'fighter', 'display_name': 'Heath Beast'},
    )
    evidence_response = client.post(
        '/evidence/store',
        json={'item_id': 'evidence-1', 'source': 'sensor', 'content_type': 'image/jpeg', 'notes': 'ringside capture'},
    )
    identity_lookup = client.get('/identity/fighter-77')
    evidence_lookup = client.get('/evidence/evidence-1')
    activation_response = client.get('/activation/fighters/Heath')

    assert identity_response.status_code == 200
    assert identity_response.json()['role'] == 'fighter'
    assert identity_lookup.status_code == 200
    assert identity_lookup.json()['display_name'] == 'Heath Beast'

    assert evidence_response.status_code == 200
    assert evidence_response.json()['status'] == 'stored'
    assert 'digest' in evidence_response.json()
    assert evidence_response.json()['storage_bucket'] == 'dfc-evidence'
    assert evidence_lookup.status_code == 200
    assert evidence_lookup.json()['item_id'] == 'evidence-1'

    assert activation_response.status_code == 200
    assert activation_response.json()['role'] == 'fighter'


def test_superbeast_rejects_invalid_seed_inputs(monkeypatch):
    disable_external_persistence(monkeypatch)
    monkeypatch.setattr(ai_core_router_module, 'publish_event', fake_publish_event)
    monkeypatch.setattr(distribution_router_module, 'publish_event', fake_publish_event)
    monkeypatch.setattr(identity_router_module, 'publish_event', fake_publish_event)

    client = make_test_client()

    blank_rewrite = client.post('/ai/rewrite', json={'text': '   ', 'style': 'hype'})
    invalid_purchase = client.post('/ppv/purchase', json={'ppv_id': 'ppv-main', 'user_id': 'user-1', 'price_cents': 0})
    invalid_channel = client.post('/distribution/drop', json={'channel': 'myspace', 'text': 'Replay is live'})
    invalid_identity = client.post(
        '/identity/register',
        json={'identity_id': 'fighter-77', 'role': 'alien', 'display_name': 'Heath Beast'},
    )
    invalid_evidence = client.post(
        '/evidence/store',
        json={'item_id': 'evidence-1', 'source': 'sensor', 'content_type': 'jpeg', 'notes': 'ringside'},
    )

    assert blank_rewrite.status_code == 400
    assert invalid_purchase.status_code == 422
    assert invalid_channel.status_code == 400
    assert invalid_identity.status_code == 400
    assert invalid_evidence.status_code == 400


def test_superbeast_ops_outbox_route(monkeypatch):
    disable_external_persistence(monkeypatch)
    async def fake_get_outbox_snapshot(lock_timeout_seconds=300):
        await asyncio.sleep(0)
        return {
            'pending_count': 2,
            'retry_count': 1,
            'ready_count': 3,
            'processing_count': 1,
            'delivered_count': 8,
            'dead_letter_count': 0,
            'stale_processing_count': 0,
            'oldest_ready_age_seconds': 12,
        }

    monkeypatch.setattr(ops_router_module, 'get_outbox_snapshot', fake_get_outbox_snapshot)

    client = make_test_client()
    response = client.get('/ops/outbox')

    assert response.status_code == 200
    assert response.json()['outbox']['ready_count'] == 3
    assert response.json()['worker']['max_attempts'] >= 1


def test_superbeast_event_reactions_create_feed_and_caption(monkeypatch):
    disable_external_persistence(monkeypatch)
    monkeypatch.setattr(feed_events_module, 'publish_event', fake_publish_event)
    monkeypatch.setattr(distribution_events_module, 'publish_event', fake_publish_event)

    from atlas_backend.event_bus import DfcEvent

    boost_event = DfcEvent(
        event_type='feed.boost_requested',
        source='feed',
        stream='feed',
        subject='ppv-main',
        payload={
            'ppv_id': 'ppv-main',
            'boost': {'headline': 'PPV momentum building', 'context': 'Purchase pulse rising'},
        },
    )
    caption_event = DfcEvent(
        event_type='distribution.caption_requested',
        source='distribution',
        stream='distribution',
        subject='fighter-77',
        payload={'content_type': 'fight_clip', 'feed_priority': 0.91, 'viral_potential': 0.84},
    )

    feed_item = asyncio.run(feed_events_module.handle_feed_boost_requested(boost_event))
    caption_record = asyncio.run(distribution_events_module.handle_distribution_caption_requested(caption_event))

    client = make_test_client()
    feed_lookup = client.get(f"/feed/{feed_item['feed_id']}")
    caption_lookup = client.get(f"/distribution/captions/{caption_record['caption_id']}")

    assert feed_lookup.status_code == 200
    assert feed_lookup.json()['source'] == 'ppv_boost'
    assert caption_lookup.status_code == 200
    assert 'fight_clip promo' in caption_lookup.json()['text']
