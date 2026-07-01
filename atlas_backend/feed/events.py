try:
    from ..event_bus import DfcEvent, publish_event
    from .service import build_boost_message, build_replay_drop_item, create_feed_item
except ImportError:
    from event_bus import DfcEvent, publish_event
    from feed.service import build_boost_message, build_replay_drop_item, create_feed_item


async def handle_ppv_purchase_created(event: DfcEvent) -> None:
    payload = event.payload
    boost = build_boost_message(payload['ppv_id'], payload.get('user_id'))
    await publish_event(
        'feed.boost_requested',
        source='feed',
        stream='feed',
        subject=payload['ppv_id'],
        payload={'ppv_id': payload['ppv_id'], 'boost': boost},
    )


async def handle_ppv_replay_ready(event: DfcEvent) -> None:
    payload = event.payload
    replay_drop = build_replay_drop_item(payload['event_id'], payload['replay_url'])
    await publish_event(
        'feed.replay_drop_requested',
        source='feed',
        stream='feed',
        subject=payload['event_id'],
        payload=replay_drop,
    )


async def handle_feed_boost_requested(event: DfcEvent) -> dict:
    payload = event.payload
    boost = payload.get('boost', {})
    text = ' - '.join(part for part in [boost.get('headline'), boost.get('context')] if part)
    feed_item = await create_feed_item(text or f"PPV boost for {payload.get('ppv_id')}", 'ppv_boost', payload)
    await publish_event(
        'feed.item.created',
        source='feed',
        stream='feed',
        subject=feed_item['feed_id'],
        payload={'feed_id': feed_item['feed_id'], 'source': feed_item['source'], 'ppv_id': payload.get('ppv_id')},
    )
    return feed_item


async def handle_feed_replay_drop_requested(event: DfcEvent) -> dict:
    payload = event.payload
    text = payload.get('headline') or f"Replay ready for {payload.get('event_id')}"
    feed_item = await create_feed_item(text, 'ppv_replay', payload)
    await publish_event(
        'feed.item.created',
        source='feed',
        stream='feed',
        subject=feed_item['feed_id'],
        payload={'feed_id': feed_item['feed_id'], 'source': feed_item['source'], 'event_id': payload.get('event_id')},
    )
    return feed_item
