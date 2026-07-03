try:
    from ..event_bus import publish_event
except ImportError:
    from event_bus import publish_event


async def emit_purchase_created(ppv_id: str, user_id: str, price_cents: int) -> None:
    await publish_event(
        'ppv.purchase.created',
        source='ppv',
        stream='ppv',
        subject=ppv_id,
        payload={'ppv_id': ppv_id, 'user_id': user_id, 'price_cents': price_cents},
    )


async def emit_access_granted(ppv_id: str, user_id: str) -> None:
    await publish_event(
        'ppv.access.granted',
        source='ppv',
        stream='ppv',
        subject=ppv_id,
        payload={'ppv_id': ppv_id, 'user_id': user_id},
    )


async def emit_replay_ready(event_id: str, replay_url: str) -> None:
    await publish_event(
        'ppv.replay.ready',
        source='ppv',
        stream='ppv',
        subject=event_id,
        payload={'event_id': event_id, 'replay_url': replay_url},
    )


async def emit_settlement_generated(event_id: str, gross_cents: int, net_cents: int) -> None:
    await publish_event(
        'ppv.settlement.generated',
        source='ppv',
        stream='ppv',
        subject=event_id,
        payload={'event_id': event_id, 'gross_cents': gross_cents, 'net_cents': net_cents},
    )
