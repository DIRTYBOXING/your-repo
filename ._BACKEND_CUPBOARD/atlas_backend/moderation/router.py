from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

try:
    from ..event_bus import publish_event
    from .service import build_flags, recommend_action, score_content, score_sensor_alert
except ImportError:
    from event_bus import publish_event
    from moderation.service import build_flags, recommend_action, score_content, score_sensor_alert


router = APIRouter(tags=['moderation'])


def _require_non_empty(value: str, field_name: str) -> str:
    cleaned = value.strip()
    if not cleaned:
        raise HTTPException(status_code=400, detail=f'{field_name} must not be blank')
    return cleaned


class ScoreRequest(BaseModel):
    text: str = Field(min_length=1, max_length=4000)


class SensorAlertModerationRequest(BaseModel):
    alert_id: str = Field(min_length=1, max_length=128)
    status: str = Field(min_length=1, max_length=64)
    priority: str = Field(default='normal', min_length=1, max_length=32)


@router.post('/moderation/score')
async def score(req: ScoreRequest):
    text = _require_non_empty(req.text, 'text')
    score_value = score_content(text)
    flags = build_flags(text)
    action = recommend_action(score_value)
    await publish_event(
        'moderation.score.completed',
        source='moderation',
        stream='moderation',
        payload={'score': score_value, 'flags': flags, 'action': action},
    )
    return {'score': score_value, 'flags': flags, 'action': action}


@router.post('/moderation/sensor-alert')
async def sensor_alert(req: SensorAlertModerationRequest):
    alert_id = _require_non_empty(req.alert_id, 'alert_id')
    status = _require_non_empty(req.status, 'status')
    priority = _require_non_empty(req.priority, 'priority')
    score_value = score_sensor_alert(priority, status)
    action = recommend_action(score_value)
    await publish_event(
        'moderation.sensor.scored',
        source='moderation',
        stream='moderation',
        subject=alert_id,
        payload={'alert_id': alert_id, 'score': score_value, 'action': action},
    )
    return {'alert_id': alert_id, 'score': score_value, 'action': action}
