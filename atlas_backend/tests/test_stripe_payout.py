import asyncio
from pathlib import Path
import sys
from types import SimpleNamespace

from fastapi.testclient import TestClient

import atlas_backend.routers.stripe as stripe_router


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from atlas_backend.main import app


class FakeTransferService:
    def __init__(self, *, transfer=None, error=None):
        self.transfer = transfer or SimpleNamespace(id='tr_123', status='paid')
        self.error = error
        self.calls = []

    def create(self, **kwargs):
        self.calls.append(kwargs)
        if self.error is not None:
            raise self.error
        return self.transfer


def make_test_client():
    return TestClient(app)


async def fake_publish_event(*args, **kwargs):
    await asyncio.sleep(0)
    return None


def test_stripe_payout_requires_secret_key(monkeypatch):
    monkeypatch.delenv('STRIPE_SECRET_KEY', raising=False)
    monkeypatch.setattr(stripe_router, 'publish_event', fake_publish_event)

    client = make_test_client()
    response = client.post(
        '/stripe/payout',
        json={
            'creator_stripe_account_id': 'acct_valid123',
            'amount_usd_cents': 500,
        },
    )

    assert response.status_code == 503
    assert response.json()['detail'] == 'Stripe not configured (STRIPE_SECRET_KEY missing)'


def test_stripe_payout_validates_request_fields(monkeypatch):
    monkeypatch.setenv('STRIPE_SECRET_KEY', 'stripe_test_env_value')
    monkeypatch.setattr(stripe_router, 'publish_event', fake_publish_event)
    client = make_test_client()

    too_small = client.post(
        '/stripe/payout',
        json={
            'creator_stripe_account_id': 'acct_valid123',
            'amount_usd_cents': 99,
        },
    )
    assert too_small.status_code == 400
    assert too_small.json()['detail'] == 'Minimum payout is $1.00 (100 cents)'

    invalid_account = client.post(
        '/stripe/payout',
        json={
            'creator_stripe_account_id': 'not_a_connect_account',
            'amount_usd_cents': 500,
        },
    )
    assert invalid_account.status_code == 400
    assert invalid_account.json()['detail'] == 'Invalid Stripe connected account ID'

    negative_impact = client.post(
        '/stripe/payout',
        json={
            'creator_stripe_account_id': 'acct_valid123',
            'amount_usd_cents': 500,
            'impact_score': -0.1,
        },
    )
    assert negative_impact.status_code == 400
    assert negative_impact.json()['detail'] == 'impact_score must be >= 0'


def test_stripe_payout_creates_transfer(monkeypatch):
    monkeypatch.setenv('STRIPE_SECRET_KEY', 'stripe_test_env_value')
    monkeypatch.delenv('DATABASE_URL', raising=False)
    monkeypatch.setattr(stripe_router, 'publish_event', fake_publish_event)

    transfer_service = FakeTransferService(
        transfer=SimpleNamespace(id='tr_live_123', status='pending'),
    )
    fake_stripe_module = SimpleNamespace(api_key=None, Transfer=transfer_service)
    monkeypatch.setitem(sys.modules, 'stripe', fake_stripe_module)

    client = make_test_client()
    response = client.post(
        '/stripe/payout',
        json={
            'creator_stripe_account_id': 'acct_valid123',
            'amount_usd_cents': 2500,
            'alert_id': 'alert_123',
            'impact_score': 0.87,
            'description': 'Creator payout',
        },
    )

    assert response.status_code == 200
    assert fake_stripe_module.api_key == 'stripe_test_env_value'  # pragma: allowlist secret
    assert transfer_service.calls == [
        {
            'amount': 2500,
            'currency': 'usd',
            'destination': 'acct_valid123',
            'description': 'Creator payout',
            'metadata': {
                'alert_id': 'alert_123',
                'impact_score': '0.87',
                'platform': 'DataFightCentral',
            },
        },
    ]
    assert response.json() == {
        'transfer_id': 'tr_live_123',
        'amount_usd': 25.0,
        'destination': 'acct_valid123',
        'status': 'pending',
    }


def test_stripe_payout_surfaces_upstream_errors(monkeypatch):
    monkeypatch.setenv('STRIPE_SECRET_KEY', 'stripe_test_env_value')
    monkeypatch.setattr(stripe_router, 'publish_event', fake_publish_event)
    monkeypatch.setitem(
        sys.modules,
        'stripe',
        SimpleNamespace(api_key=None, Transfer=FakeTransferService(error=RuntimeError('stripe exploded'))),
    )

    client = make_test_client()
    response = client.post(
        '/stripe/payout',
        json={
            'creator_stripe_account_id': 'acct_valid123',
            'amount_usd_cents': 2500,
        },
    )

    assert response.status_code == 502
    assert response.json()['detail'] == 'Stripe error: stripe exploded'
