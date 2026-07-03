# tests/test_webhook.py
import json
import pytest
from backend.app import create_app
from backend.db import get_order_by_checkout_id, get_entitlement_by_order_id

@pytest.fixture
def client():
    app = create_app({'TESTING': True})
    with app.test_client() as client:
        yield client

def load_fixture(name):
    with open(f'test/fixtures/webhooks/{name}.json') as f:
        return json.load(f)

def test_checkout_session_completed_creates_entitlement(client):
    payload = load_fixture('checkout.session.completed')
    res = client.post('/payments/webhook', json=payload)
    assert res.status_code == 200

    order = get_order_by_checkout_id('cs_test_abc123')
    assert order is not None
    assert order['status'] == 'paid'

    ent = get_entitlement_by_order_id(order['order_id'])
    assert ent is not None

def test_idempotent_duplicate_event(client):
    payload = load_fixture('checkout.session.completed')
    client.post('/payments/webhook', json=payload)
    res = client.post('/payments/webhook', json=payload)
    assert res.status_code == 200
    orders = get_orders_by_checkout_id('cs_test_abc123')
    assert len(orders) == 1
