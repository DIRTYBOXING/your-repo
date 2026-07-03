try:
    from ..event_bus import DfcEvent, publish_event
    from .engine import create_caption_record
except ImportError:
    from event_bus import DfcEvent, publish_event
    from distribution.engine import create_caption_record


async def handle_distribution_caption_requested(event: DfcEvent) -> dict:
    payload = event.payload
    content_type = payload.get('content_type') or 'fight content'
    feed_priority = payload.get('feed_priority', 0)
    viral_potential = payload.get('viral_potential', 0)
    prompt = (
        f"{content_type} promo with feed priority {feed_priority} and viral potential {viral_potential}"
    )
    caption_record = await create_caption_record(prompt, {**payload, 'origin_subject': event.subject})
    await publish_event(
        'distribution.caption.generated',
        source='distribution',
        stream='distribution',
        subject=caption_record['caption_id'],
        payload={
            'caption_id': caption_record['caption_id'],
            'caption': caption_record['caption'],
            'origin_subject': event.subject,
        },
    )
    return caption_record
