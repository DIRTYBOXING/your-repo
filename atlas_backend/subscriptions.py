import logging

try:
    from .event_bus import DfcEvent, get_event_bus, publish_event
    from .distribution.events import handle_distribution_caption_requested
    from .feed.events import (
        handle_feed_boost_requested,
        handle_feed_replay_drop_requested,
        handle_ppv_purchase_created,
        handle_ppv_replay_ready,
    )
except ImportError:
    from event_bus import DfcEvent, get_event_bus, publish_event
    from distribution.events import handle_distribution_caption_requested
    from feed.events import (
        handle_feed_boost_requested,
        handle_feed_replay_drop_requested,
        handle_ppv_purchase_created,
        handle_ppv_replay_ready,
    )


logger = logging.getLogger(__name__)

_registered = False
FEED_BOOST_REQUESTED = 'feed.boost_requested'
FEED_REPLAY_DROP_REQUESTED = 'feed.replay_drop_requested'
DISTRIBUTION_CAPTION_REQUESTED = 'distribution.caption_requested'


async def _on_sensor_alert_status_updated(event: DfcEvent) -> None:
    payload = event.payload
    if payload.get('status') == 'Escalated':
        await publish_event(
            'moderation.sensor_review_requested',
            source='moderation',
            stream='moderation',
            subject=payload.get('alert_id'),
            payload={
                'alert_id': payload.get('alert_id'),
                'status': payload.get('status'),
                'priority': 'high',
            },
        )


async def _on_tribe_prediction_generated(event: DfcEvent) -> None:
    payload = event.payload
    await publish_event(
        DISTRIBUTION_CAPTION_REQUESTED,
        source='distribution',
        stream='distribution',
        subject=payload.get('fighter_id') or payload.get('content_type'),
        payload={
            'content_type': payload.get('content_type'),
            'feed_priority': payload.get('feed_priority'),
            'viral_potential': payload.get('viral_potential'),
        },
    )


async def _on_identity_profile_created(event: DfcEvent) -> None:
    payload = event.payload
    await publish_event(
        'activation.kit_requested',
        source='activation',
        stream='activation',
        subject=payload.get('identity_id'),
        payload={
            'identity_id': payload.get('identity_id'),
            'role': payload.get('role'),
            'display_name': payload.get('display_name'),
        },
    )


def _log_feed_boost(event: DfcEvent) -> None:
    logger.info('Feed boost requested for %s', event.subject)


def _log_distribution_request(event: DfcEvent) -> None:
    logger.info('Distribution caption requested for %s', event.subject)


def _log_activation_request(event: DfcEvent) -> None:
    logger.info('Activation kit requested for %s', event.subject)


def _log_moderation_request(event: DfcEvent) -> None:
    logger.info('Moderation review requested for %s', event.subject)


def register_default_subscriptions() -> None:
    global _registered
    if _registered:
        return

    bus = get_event_bus()
    bus.subscribe('ppv.purchase.created', handle_ppv_purchase_created)
    bus.subscribe('ppv.replay.ready', handle_ppv_replay_ready)
    bus.subscribe('sensor.alert_status_updated', _on_sensor_alert_status_updated)
    bus.subscribe('tribe.prediction_generated', _on_tribe_prediction_generated)
    bus.subscribe('identity.profile.created', _on_identity_profile_created)
    bus.subscribe(FEED_BOOST_REQUESTED, handle_feed_boost_requested)
    bus.subscribe(FEED_REPLAY_DROP_REQUESTED, handle_feed_replay_drop_requested)
    bus.subscribe(DISTRIBUTION_CAPTION_REQUESTED, handle_distribution_caption_requested)

    bus.subscribe(FEED_BOOST_REQUESTED, _log_feed_boost)
    bus.subscribe(DISTRIBUTION_CAPTION_REQUESTED, _log_distribution_request)
    bus.subscribe('activation.kit_requested', _log_activation_request)
    bus.subscribe('moderation.sensor_review_requested', _log_moderation_request)

    _registered = True
